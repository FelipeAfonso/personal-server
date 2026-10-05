import copy
import datetime as dt
import importlib.util
import pathlib
import tempfile
import threading
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("runner", pathlib.Path(__file__).with_name("runner.py"))
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class PolicyTests(unittest.TestCase):
    def test_only_sunday_night_is_allowed(self):
        for weekday in range(7):
            for hour in range(24):
                moment = dt.datetime(2026, 10, 5 + weekday, hour, tzinfo=runner.ZONE)
                self.assertEqual(runner.in_window(moment), weekday == 6 and 2 <= hour < 6)

    def test_public_update_preserves_private_and_root_nodes(self):
        original = {"nodes": {"secrets": {"rev": "private-pin"}, "root": {"inputs": {"secrets": "secrets"}}}}
        for name in runner.PUBLIC_INPUTS:
            source = {"type": "github", "owner": "trusted", "repo": name}
            original["nodes"][name] = {"original": source, "locked": {**source, "rev": "old"}}
        changed = copy.deepcopy(original)
        changed["nodes"]["nixpkgs"]["locked"]["rev"] = "new"
        runner.check_scope(original, changed, ["flake.lock"])
        for name in ("secrets", "root"):
            bad = copy.deepcopy(changed)
            bad["nodes"][name] = {"tampered": True}
            with self.assertRaises(runner.MaintenanceError):
                runner.check_scope(original, bad, ["flake.lock"])
        with self.assertRaises(runner.MaintenanceError):
            runner.check_scope(original, changed, ["modules/agents.nix"])
        for part in ("original", "locked"):
            bad = copy.deepcopy(changed)
            bad["nodes"]["nixpkgs"][part]["owner"] = "unexpected-source"
            with self.assertRaises(runner.MaintenanceError):
                runner.check_scope(original, bad, ["flake.lock"])

    def test_protected_activation_is_deferred(self):
        with tempfile.TemporaryDirectory() as directory:
            before = pathlib.Path(directory) / "before"
            after = pathlib.Path(directory) / "after"
            before.mkdir()
            after.mkdir()
            for path in (before, after):
                (path / "systemd").symlink_to("/nix/store/same-systemd")
            for unit in ["tailscaled.service", "sshd.service",
                         "user@1000.service", "t3code.service", "systemd-logind.service"]:
                with self.assertRaises(runner.MaintenanceError, msg=unit):
                    runner.check_activation(f"would restart the following units: {unit}", before, after)
            runner.check_activation("would restart the following units: nix-daemon.service", before, after)
            runner.check_activation("would reload the following units: dbus-broker.service", before, after)
            with self.assertRaises(runner.MaintenanceError):
                runner.check_activation("would reload the following units: dbus-broker.service, tailscaled.service", before, after)
            (after / "systemd").unlink()
            (after / "systemd").symlink_to("/nix/store/new-systemd")
            for action in ("restart", "stop"):
                runner.check_activation(f"would NOT {action} the following units: user@1000.service", before, after)
            runner.check_activation("would restart the following units: home-manager-felipe.service", before, after)

    def test_home_manager_cannot_manage_t3_files(self):
        with tempfile.TemporaryDirectory() as directory:
            system = pathlib.Path(directory) / "system"
            unit = system / "etc/systemd/system/home-manager-felipe.service"
            unit.parent.mkdir(parents=True)
            unit.write_text("ExecStart=/nix/store/" + "a" * 32 + "-hm-setup-env /nix/store/" + "b" * 32 + "-home-manager-generation\n")
            generation = pathlib.Path(directory) / "generation"
            generation.mkdir()
            (generation / "activate").touch()
            (generation / "home-files").mkdir()
            with patch.object(runner, "Path", return_value=generation):
                runner.check_home_manager(system)
                (generation / "home-files/.t3").mkdir()
                with self.assertRaises(runner.MaintenanceError):
                    runner.check_home_manager(system)
            unit.write_text("ExecStart=/unexpected/activation\n")
            with self.assertRaises(runner.MaintenanceError):
                runner.check_home_manager(system)

    def test_rejected_review_cannot_be_treated_as_passed(self):
        with tempfile.TemporaryDirectory() as directory:
            instance = object.__new__(runner.Runner)
            instance.checkout = pathlib.Path(directory)
            instance.run_dir = pathlib.Path(directory)
            instance.base = "base"
            instance.agent = lambda *args: '{"approved": false, "issues": ["Unsafe change"]}'
            with self.assertRaises(runner.MaintenanceError):
                instance.review("candidate")

    def test_agent_failure_does_not_become_a_successful_review(self):
        with tempfile.TemporaryDirectory() as directory:
            instance = object.__new__(runner.Runner)
            instance.checkout = pathlib.Path(directory)
            instance.run_dir = pathlib.Path(directory)
            instance.base = "base"
            instance.agent = lambda *args: "Not JSON"
            with self.assertRaises(ValueError):
                instance.review("candidate")

    def test_expired_window_refuses_merge_and_activation(self):
        with patch.object(runner, "in_window", return_value=False):
            with self.assertRaises(runner.MaintenanceError):
                object.__new__(runner.Runner).window()


class LifecycleRunner(runner.Runner):
    """Model GitHub/build boundaries without touching a machine or remote."""

    def __init__(self, directory, changes=True, dirty=False, moved_base=False, approved=False):
        self.checkout = pathlib.Path(directory)
        (self.checkout / "flake.lock").write_text("{}")
        self.config = {"user": "felipe", "base": "main", "branch": "maintenance/weekend-updates"}
        self.base = "base"
        self.previous = pathlib.Path("/nix/store/previous")
        self.candidate = pathlib.Path("/nix/store/candidate")
        self.changes = changes
        self.dirty = dirty
        self.moved_base = moved_base
        self.approved = approved
        self.events = []

    def prepare(self):
        pass

    def window(self):
        pass

    def command(self, *args, **kwargs):
        return ""

    def scope(self):
        return {"flake.lock"} if self.changes else set()

    def validate(self):
        self.events.append("validate")

    def status(self, *args, **kwargs):
        pass

    def git(self, *args):
        if args[0] == "status":
            return " M flake.lock" if self.dirty else ""
        if args[0] == "commit":
            self.events.append("commit")
            self.dirty = False
        if args[0] == "rev-parse":
            return "tree" if args[1].endswith("^{tree}") else "commit"
        if args[0] == "ls-remote":
            if args[-1].endswith("maintenance/weekend-updates"):
                return "commit\trefs/heads/maintenance/weekend-updates"
            return ("different-base" if self.moved_base else "base") + "\trefs/heads/main"
        if args[0] == "push" and args[1].startswith("--force-with-lease="):
            self.events.append("merge" if "refs/heads/main:" in args[1] else "retire-branch")
        return ""

    def review(self, commit):
        self.events.append("review")

    def activation_plan(self):
        self.events.append("dry-activate")

    def attest(self, commit):
        self.events.append("attest")

    def previously_approved(self):
        return self.approved

    def publish(self, failed=False):
        self.events.append("publish")

    def deploy(self):
        self.events.append("deploy")


class LifecycleTests(unittest.TestCase):
    def test_pending_branch_with_clean_worktree_can_be_reviewed_and_merged(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(runner.os, "chown"):
            instance = LifecycleRunner(directory)
            instance.execute()
            self.assertEqual(instance.events, ["validate", "review", "attest", "dry-activate", "publish", "merge",
                                                "retire-branch", "deploy"])

    def test_new_changes_are_committed_before_review(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(runner.os, "chown"):
            instance = LifecycleRunner(directory, dirty=True)
            instance.execute()
            self.assertLess(instance.events.index("commit"), instance.events.index("review"))
            self.assertEqual(instance.events.count("commit"), 1)

    def test_no_input_changes_defers_an_unapproved_changed_system(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(runner.os, "chown"):
            instance = LifecycleRunner(directory, changes=False)
            with self.assertRaises(runner.MaintenanceError):
                instance.execute()
            self.assertEqual(instance.events, ["validate"])

    def test_no_input_changes_can_retry_an_exact_previously_approved_system(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(runner.os, "chown"):
            instance = LifecycleRunner(directory, changes=False, approved=True)
            instance.execute()
            self.assertEqual(instance.events, ["validate", "deploy"])

    def test_changed_base_blocks_merge_and_deployment(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(runner.os, "chown"):
            instance = LifecycleRunner(directory, moved_base=True)
            with self.assertRaises(runner.MaintenanceError):
                instance.execute()
            self.assertNotIn("merge", instance.events)
            self.assertNotIn("deploy", instance.events)

    def test_rejected_review_blocks_delivery(self):
        with tempfile.TemporaryDirectory() as directory, patch.object(runner.os, "chown"):
            instance = LifecycleRunner(directory)
            with patch.object(instance, "review", side_effect=runner.MaintenanceError("rejected")):
                with self.assertRaises(runner.MaintenanceError):
                    instance.execute()
            self.assertNotIn("merge", instance.events)
            self.assertNotIn("deploy", instance.events)

    def test_oserror_after_switch_triggers_immediate_rollback(self):
        with tempfile.TemporaryDirectory() as directory:
            instance = LifecycleRunner(directory)
            instance.run_dir = instance.state = pathlib.Path(directory)
            instance.stamp = "test"
            instance.config_path = "/immutable-config"
            original_resolve = pathlib.Path.resolve
            switched = False

            def command(args, **kwargs):
                nonlocal switched
                if str(args[0]).endswith("switch-to-configuration"):
                    switched = True
                return ""

            def resolve(path, *args, **kwargs):
                if str(path) in ("/run/current-system", "/nix/var/nix/profiles/system"):
                    return instance.candidate if switched else instance.previous
                return original_resolve(path, *args, **kwargs)

            with patch.object(instance, "command", side_effect=command), \
                    patch.object(instance, "t3_state", side_effect=["100", OSError("socket failed")]), \
                    patch.object(runner.Path, "resolve", resolve), \
                    patch.object(runner, "rollback_system") as rollback:
                with self.assertRaises(OSError):
                    runner.Runner.deploy(instance)
                rollback.assert_called_once_with(instance.run_dir / "rollback.json")

    def test_profile_only_activation_failure_restores_profile_and_activation(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "rollback.json"
            previous = pathlib.Path("/nix/store/previous")
            candidate = pathlib.Path("/nix/store/candidate")
            path.write_text(runner.json.dumps({"previous": str(previous), "candidate": str(candidate), "status": "armed"}))
            original_resolve = pathlib.Path.resolve

            def resolve(instance, *args, **kwargs):
                if str(instance) == "/nix/var/nix/profiles/system":
                    return candidate
                if str(instance) == "/run/current-system":
                    return previous
                return original_resolve(instance, *args, **kwargs)

            with patch.object(runner.Path, "resolve", resolve), patch.object(runner.Path, "is_file", return_value=True), \
                    patch.object(runner, "run_process", return_value=runner.subprocess.CompletedProcess([], 0, "", "")) as commands:
                runner.rollback_system(path)
                self.assertEqual(commands.call_count, 2)
            self.assertEqual(runner.json.loads(path.read_text())["status"], "rolled-back")

    def test_watchdog_fired_during_success_acknowledgement_does_not_undo_it(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "rollback.json"
            path.write_text(runner.json.dumps({"previous": "/nix/store/previous", "candidate": "/nix/store/candidate", "status": "armed"}))
            started = threading.Event()

            def watchdog():
                started.set()
                runner.rollback_system(path)

            with patch.object(runner, "run_process") as commands:
                with runner.deployment_record(path) as record:
                    thread = threading.Thread(target=watchdog)
                    thread.start()
                    self.assertTrue(started.wait(1))
                    record["status"] = "completed"
                thread.join(2)
                self.assertFalse(thread.is_alive())
                commands.assert_not_called()

    def test_stale_generation_is_not_overwritten_or_rolled_back(self):
        with tempfile.TemporaryDirectory() as directory:
            instance = LifecycleRunner(directory)
            instance.run_dir = pathlib.Path(directory)
            instance.state = pathlib.Path(directory)
            instance.stamp = "test"
            instance.config_path = "/immutable-config"
            instance.t3_state = lambda: "100"
            original_resolve = pathlib.Path.resolve

            def resolve(path, *args, **kwargs):
                if str(path) in ("/run/current-system", "/nix/var/nix/profiles/system"):
                    return pathlib.Path("/nix/store/human-deployment")
                return original_resolve(path, *args, **kwargs)

            with patch.object(runner.Path, "resolve", resolve), patch.object(instance, "command") as commands:
                with self.assertRaises(runner.MaintenanceError):
                    runner.Runner.deploy(instance)
            self.assertFalse(any(call.args[0][0] == "nix-env" for call in commands.call_args_list))
            self.assertEqual(runner.json.loads((instance.run_dir / "rollback.json").read_text())["status"], "cancelled")

    def test_branch_retirement_preserves_a_new_head_and_accepts_auto_deletion(self):
        instance = object.__new__(runner.Runner)
        instance.config = {"branch": "maintenance/weekend-updates"}
        with patch.object(instance, "git", return_value="") as git:
            instance.retire_branch("reviewed")
            self.assertEqual(git.call_count, 1)
        with patch.object(instance, "git", return_value="newer-head\tref") as git:
            with self.assertRaises(runner.MaintenanceError):
                instance.retire_branch("reviewed")
            self.assertEqual(git.call_count, 1)
        with patch.object(instance, "git", side_effect=["reviewed\tref", ""]) as git:
            instance.retire_branch("reviewed")
            self.assertIn("--force-with-lease=refs/heads/maintenance/weekend-updates:reviewed", git.call_args.args)

    def test_failed_rollback_activation_is_retried_even_after_profile_restoration(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "rollback.json"
            previous = pathlib.Path("/nix/store/previous")
            path.write_text(runner.json.dumps({"previous": str(previous), "candidate": "/nix/store/candidate", "status": "rolling-back"}))
            with patch.object(runner.Path, "resolve", return_value=previous), \
                    patch.object(runner.Path, "is_file", return_value=True), \
                    patch.object(runner, "run_process", side_effect=[
                        runner.subprocess.CompletedProcess([], 0, "", ""),
                        runner.subprocess.CompletedProcess([], 1, "", "activation failed"),
                        runner.subprocess.CompletedProcess([], 0, "", ""),
                        runner.subprocess.CompletedProcess([], 0, "", ""),
                    ]) as commands:
                with self.assertRaises(runner.MaintenanceError):
                    runner.rollback_system(path)
                self.assertEqual(runner.json.loads(path.read_text())["status"], "rolling-back")
                runner.rollback_system(path)
                self.assertEqual(commands.call_count, 4)
            self.assertEqual(runner.json.loads(path.read_text())["status"], "rolled-back")

    def test_command_timeout_terminates_activation_descendants(self):
        with tempfile.TemporaryDirectory() as directory:
            pid_file = pathlib.Path(directory) / "child.pid"
            script = ("import subprocess,time,pathlib,sys; "
                      "child=subprocess.Popen([sys.executable,'-c','import time; time.sleep(20)']); "
                      "pathlib.Path(sys.argv[1]).write_text(str(child.pid)); time.sleep(20)")
            with self.assertRaises(runner.subprocess.TimeoutExpired):
                runner.run_process([runner.sys.executable, "-c", script, str(pid_file)], timeout=1)
            process = pathlib.Path("/proc") / pid_file.read_text() / "stat"
            try:
                self.assertEqual(process.read_text().split()[2], "Z")
            except FileNotFoundError:
                pass

    def test_rollback_retry_preserves_a_later_human_deployment(self):
        with tempfile.TemporaryDirectory() as directory:
            path = pathlib.Path(directory) / "rollback.json"
            path.write_text(runner.json.dumps({"previous": "/nix/store/previous", "candidate": "/nix/store/candidate", "status": "rolling-back"}))
            with patch.object(runner.Path, "resolve", return_value=pathlib.Path("/nix/store/human")), \
                    patch.object(runner.Path, "is_file", return_value=True), \
                    patch.object(runner, "run_process") as commands:
                runner.rollback_system(path)
                commands.assert_not_called()
            self.assertEqual(runner.json.loads(path.read_text())["status"], "cancelled")


if __name__ == "__main__":
    unittest.main()
