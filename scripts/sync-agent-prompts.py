#!/usr/bin/env python3
"""Check or copy shared agent instructions into another fleet config repo."""

import argparse
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("target", type=Path, help="personal-desktop or personal-laptop checkout")
    parser.add_argument("--write", action="store_true", help="update clean files on a task branch")
    args = parser.parse_args()
    source = Path(__file__).resolve().parents[1] / "home/felipe/agents"
    target = args.target.expanduser().resolve()
    if not (target / "agents").is_dir():
        parser.error("target must contain an agents directory")
    files = [Path(name) for name in (
        "claude-global.md", "codex-global.md", "opencode-global.md",
        "models.md", "workflow.md", "skills/plan-html-workflow/SKILL.md",
    )]
    changed = []
    for name in files:
        dest = target / "agents" / name
        if dest.is_symlink():
            parser.error(f"refusing symlink target: {dest}")
        if not dest.exists() or dest.read_bytes() != (source / name).read_bytes():
            changed.append(name)
    if not changed:
        print("Shared agent files match.")
        return 0
    if args.write:
        def git(*command):
            return subprocess.check_output(["git", "-C", str(target), *command], text=True).strip()

        if Path(git("rev-parse", "--show-toplevel")).resolve() != target:
            parser.error("target must be the repository root")
        branch = git("branch", "--show-current")
        if not branch or branch in {"main", "master", "dev"}:
            parser.error("switch the target repository to a task branch before writing")
        paths = [str(Path("agents") / name) for name in changed]
        if git("status", "--porcelain", "--", *paths):
            parser.error("target files have uncommitted changes; inspect them before syncing")
        for name in changed:
            dest = target / "agents" / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes((source / name).read_bytes())
            print(f"Updated agents/{name}")
        return 0
    for name in changed:
        print(f"Different or missing: agents/{name}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
