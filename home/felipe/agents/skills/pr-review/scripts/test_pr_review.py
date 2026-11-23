#!/usr/bin/env python3
"""Tests for pr-review and agent-usage. Run: python3 test_pr_review.py"""

from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
import json
from pathlib import Path
import sys
import unittest

HERE = Path(__file__).resolve().parent
sys.dont_write_bytecode = True  # keep the skill directory free of __pycache__


def load(name, filename):
    loader = SourceFileLoader(name, str(HERE / filename))
    module = module_from_spec(spec_from_loader(name, loader))
    loader.exec_module(module)
    return module


review = load("pr_review", "pr-review")
usage = load("agent_usage", "agent-usage")


def readings(anthropic=None, google=None):
    return {"anthropic": {"weekly_used_percent": anthropic},
            "google": {"weekly_used_percent": google}}


def classes(candidates):
    return [item[0] for item in candidates]


DIFF = """diff --git a/src/app.py b/src/app.py
index 1111111..2222222 100644
--- a/src/app.py
+++ b/src/app.py
@@ -10,3 +10,4 @@ def handler():
 context
-removed
+added one
+added two
 trailing
@@ -40,2 +41,2 @@
---- looks like a header
+++- also looks like one
 end
diff --git a/old.txt b/old.txt
deleted file mode 100644
--- a/old.txt
+++ /dev/null
@@ -1,2 +0,0 @@
-gone
-also gone
diff --git a/ui/Button.tsx b/ui/Button.tsx
new file mode 100644
--- /dev/null
+++ b/ui/Button.tsx
@@ -0,0 +1,2 @@
+export const Button = 1
+export default Button
"""


class ChoosingTheReviewer(unittest.TestCase):
    def test_fable_reviews_while_allowance_is_healthy(self):
        self.assertEqual(classes(review.order_candidates(readings(28, 17))),
                         ["fable", "neon"])

    def test_unknown_usage_follows_preference(self):
        self.assertEqual(classes(review.order_candidates(readings())), ["fable", "neon"])
        self.assertEqual(classes(review.order_candidates({})), ["fable", "neon"])

    def test_threshold_is_thirty_percent_remaining(self):
        self.assertEqual(classes(review.order_candidates(readings(69, 10)))[0], "fable")
        self.assertEqual(classes(review.order_candidates(readings(70, 10)))[0], "neon")

    def test_low_google_allowance_changes_nothing_for_fable(self):
        self.assertEqual(classes(review.order_candidates(readings(40, 95))),
                         ["fable", "neon"])

    def test_both_low_takes_the_fuller_allowance(self):
        self.assertEqual(classes(review.order_candidates(readings(80, 95)))[0], "fable")
        self.assertEqual(classes(review.order_candidates(readings(95, 80)))[0], "neon")

    def test_spent_allowance_goes_last(self):
        self.assertEqual(classes(review.order_candidates(readings(100, 90))),
                         ["neon", "fable"])

    def test_explanation_names_the_reason(self):
        usage_now = readings(75, 40)
        chosen = review.order_candidates(usage_now)[0]
        text = review.explain_choice(chosen, usage_now)
        self.assertIn("Neon reviews because the Anthropic weekly allowance is at or below 30%",
                      text)
        self.assertIn("Google 60% of the week left", text)
        preferred = review.explain_choice(("fable", "anthropic", "high"), readings(17, None))
        self.assertIn("Fable is the review preference", preferred)
        self.assertIn("Google weekly allowance unknown", preferred)

    def test_neon_review_settings_are_read_only_and_unmetered(self):
        settings = review.AGY_SETTINGS
        for rule in ("write_file(*)", "command(*)", "read_url(*)", "mcp(*)"):
            self.assertIn(rule, settings["permissions"]["deny"])
        self.assertFalse(settings["useG1Credits"])
        self.assertFalse(settings["allowNonWorkspaceAccess"])
        self.assertEqual(settings["modelProvider"], "")


class ReadingTheDiff(unittest.TestCase):
    def setUp(self):
        self.files = review.parse_diff(DIFF)

    def test_right_side_lines(self):
        self.assertEqual(self.files["src/app.py"]["lines"], {10, 11, 12, 13, 41, 42})
        self.assertEqual(self.files["ui/Button.tsx"]["lines"], {1, 2})

    def test_hunk_content_is_not_mistaken_for_headers(self):
        self.assertEqual(set(self.files), {"src/app.py", "old.txt", "ui/Button.tsx"})
        self.assertEqual(self.files["src/app.py"]["changed"], 5)

    def test_deleted_file_counts_but_takes_no_comments(self):
        self.assertEqual(self.files["old.txt"], {"lines": set(), "changed": 2})

    def test_form_feed_inside_a_line_does_not_split_it(self):
        files = review.parse_diff("--- a/f.py\n+++ b/f.py\n@@ -1,2 +1,3 @@\n a\n+b\x0cc\n d\n")
        self.assertEqual(files["f.py"]["lines"], {1, 2, 3})

    def test_classify(self):
        self.assertEqual(review.classify(self.files), "reasoning")
        self.assertEqual(review.classify({"a.tsx": {"changed": 9}, "b.py": {"changed": 2}}),
                         "product")
        self.assertEqual(review.classify({}), "reasoning")


class PostingTheReview(unittest.TestCase):
    def setUp(self):
        self.files = review.parse_diff(DIFF)
        self.review = review.clean_review({"summary": "Adds a thing.", "findings": [
            {"path": "repo/src/app.py", "line": 11, "severity": "nit", "title": "A", "body": "a"},
            {"path": "src/app.py", "line": 999, "severity": "major", "title": "B", "body": "b"},
            {"path": "x", "line": "bad", "severity": "weird", "title": "C", "body": "c"},
        ]})

    def test_clean_review_sorts_and_repairs(self):
        self.assertEqual([f["title"] for f in self.review["findings"]], ["B", "C", "A"])
        self.assertEqual(self.review["findings"][1]["severity"], "minor")
        self.assertEqual(self.review["findings"][2]["path"], "src/app.py")

    def test_only_lines_in_the_diff_become_inline_comments(self):
        payload = review.build_review(self.review, self.files, "Gemini 4 Neon", "felipe",
                                      "abc1234def", "reasoning", "why")
        self.assertEqual([(c["path"], c["line"]) for c in payload["comments"]],
                         [("src/app.py", 11)])
        self.assertIn("`src/app.py:999`", payload["body"])
        self.assertIn("<!-- pr-review:abc1234def findings=3 -->", payload["body"])
        self.assertTrue(payload["body"].startswith(
            "> [!NOTE]\n> 🤖 **Gemini 4 Neon responding on behalf of felipe**\n\n"))
        self.assertEqual(payload["event"], "COMMENT")

    def test_fallback_keeps_every_finding_in_the_body(self):
        payload = review.build_review(self.review, self.files, "Gemini 4 Neon", "felipe",
                                      "abc1234def", "reasoning", "why", inline=False)
        self.assertEqual(payload["comments"], [])
        self.assertIn("`src/app.py:11`", payload["body"])

    def test_no_findings(self):
        empty = review.clean_review({"summary": "Fine.", "findings": []})
        payload = review.build_review(empty, self.files, "Claude Fable 5.2", "felipe",
                                      "abc1234def", "product", "why")
        self.assertIn("No findings.", payload["body"])

    def test_incomplete_output_is_rejected(self):
        untitled = {"summary": "s", "findings": [
            {"path": "x", "line": 1, "severity": "major", "body": "no title"}]}
        for bad in ({}, {"summary": "", "findings": []}, {"summary": "s"}, "text", untitled):
            with self.assertRaises(review.ReviewError):
                review.clean_review(bad)

    def test_marker_round_trip(self):
        sha = "a" * 40
        match = review.MARKER_PATTERN.search(review.MARKER.format(sha=sha, count=4))
        self.assertEqual((match[1], match[2]), (sha, "4"))

    def test_failed_reviewer_is_the_stated_reason(self):
        text = review.explain_choice(("neon", "google", "xhigh"),
                                     readings(28, 20), failed=["fable"])
        self.assertIn("Neon reviews because Fable did not finish", text)
        self.assertNotIn("at or below", text)

    def test_display_names(self):
        self.assertEqual(review.claude_display("claude-fable-5-2"), "Claude Fable 5.2")
        self.assertEqual(review.claude_display("claude-opus-5-5-20261001"), "Claude Opus 5.5")

    def test_agy_envelope(self):
        good = {"summary": "s", "findings": []}
        self.assertEqual(review.agy_review(json.dumps(
            {"status": "SUCCESS", "structured_output": good}), "", 0), good)
        fallback = json.dumps({"status": "SUCCESS", "response": json.dumps(good)})
        self.assertEqual(review.agy_review(fallback, "", 0), good)
        for stdout, code in (('{"status": "ERROR", "error": "weekly quota"}', 1),
                             (json.dumps({"status": "SUCCESS", "structured_output": good}), 1),
                             ('{"status": "SUCCESS", "response": ""}', 0),
                             ("Error: Please sign in", 1), ("[]", 0), ("", 0)):
            with self.assertRaises(review.ReviewError):
                review.agy_review(stdout, "stderr text", code)

    def test_extract_json(self):
        self.assertEqual(review.extract_json('Here {not json} ```json\n{"summary": "s"}\n```'),
                         {"summary": "s"})
        with self.assertRaises(review.ReviewError):
            review.extract_json("nothing here")

    def test_resolve_pr_from_url(self):
        self.assertEqual(review.resolve_pr("https://github.com/o/r/pull/12", None),
                         ("o/r", 12))

    def test_json_stream(self):
        self.assertEqual(review.json_stream('{"a": 1}\n{"a": 2}\n'), [{"a": 1}, {"a": 2}])


class ReadingUsage(unittest.TestCase):
    def test_claude_stream(self):
        event = {"type": "rate_limit_event", "rate_limit_info": {
            "status": "allowed", "rateLimitType": "seven_day",
            "unifiedWindows": {"five_hour": {"utilization": 0.9},
                               "seven_day": {"utilization": 0.28, "resetsAt": 5},
                               "seven_day_opus": {"utilization": 0.41, "resetsAt": 6}}}}
        reading = usage.parse_claude_stream(["noise", json.dumps(event)], 100)
        self.assertEqual(reading["weekly_used_percent"], 41.0)
        self.assertEqual(reading["resets_at"], 6)
        self.assertIsNone(usage.parse_claude_stream(['{"type": "result"}'], 100))

    def test_claude_rejected_window_counts_as_spent(self):
        event = {"type": "rate_limit_event", "rate_limit_info": {
            "status": "rejected",
            "unifiedWindows": {"seven_day": {"utilization": 0.97, "status": "rejected"}}}}
        self.assertEqual(usage.parse_claude_stream([json.dumps(event)], 1)
                         ["weekly_used_percent"], 100.0)

    def test_short_window_rejection_leaves_the_week_alone(self):
        event = {"type": "rate_limit_event", "rate_limit_info": {
            "status": "rejected", "rateLimitType": "five_hour",
            "unifiedWindows": {"five_hour": {"utilization": 1.0, "status": "rejected"},
                               "seven_day": {"utilization": 0.2, "status": "allowed"}}}}
        self.assertEqual(usage.parse_claude_stream([json.dumps(event)], 1)
                         ["weekly_used_percent"], 20.0)

    def test_readings_expire(self):
        reading = {"weekly_used_percent": 100.0, "resets_at": 1000, "observed_at": 900}
        self.assertTrue(usage.still_valid(reading, now=950))
        self.assertFalse(usage.still_valid(reading, now=1001))
        old = {"weekly_used_percent": 10.0, "resets_at": 10**9, "observed_at": 0}
        self.assertFalse(usage.still_valid(old, now=usage.MAX_READING_AGE + 1))
        self.assertFalse(usage.still_valid({"weekly_used_percent": None}, now=1))

    def test_agy_usage(self):
        def report(*groups):
            return json.dumps({"status": "SUCCESS", "command": {"name": "usage",
                                                                "data": {"groups": groups}}})
        gemini = {"name": "Gemini Models", "buckets": [
            {"id": "gemini-5h", "window": "5h", "remaining_fraction": 0.1},
            {"id": "gemini-weekly", "window": "weekly", "remaining_fraction": 0.83,
             "reset_time": "2026-11-30T16:24:12Z"}]}
        other = {"name": "Claude and GPT models", "buckets": [
            {"id": "3p-weekly", "window": "weekly", "remaining_fraction": 0.2}]}
        reading = usage.parse_agy_usage(report(other, gemini), 50)
        self.assertEqual(reading["weekly_used_percent"], 17.0)
        self.assertEqual(reading["resets_at"], 1796055852)
        self.assertEqual(reading["observed_at"], 50)
        self.assertTrue(usage.still_valid(reading, now=60))
        self.assertIsNone(usage.parse_agy_usage(report(other), 50))
        self.assertIsNone(usage.parse_agy_usage(report("junk", {"name": "Gemini Models",
                                                                "buckets": ["junk"]}), 50))
        self.assertIsNone(usage.parse_agy_usage("Please sign in", 50))
        spent = {"name": "Gemini Models", "buckets": [
            {"window": "weekly", "remaining_fraction": 0, "reset_time": "soon"}]}
        self.assertEqual(usage.parse_agy_usage(report(spent), 50)["weekly_used_percent"], 100.0)
        self.assertIsNone(usage.parse_agy_usage(report(spent), 50)["resets_at"])

    def test_newest_agy_model(self):
        listing = ("Fetching available models...\n"
                   "gemini-4-neon-high\tGemini 4 Neon (High)\n"
                   "gemini-4-neon-xhigh\tGemini 4 Neon (XHigh)\n"
                   "gemini-4.5-neon-xhigh\tGemini 4.5 Neon (XHigh)\n"
                   "gemini-4-carbon-high\tGemini 4 Carbon (High)\n"
                   "gemini-pro-orchestrator-neon\tOrchestrator (Neon)\n")
        self.assertEqual(usage.newest_agy_model(listing, "neon", "xhigh"),
                         ("gemini-4.5-neon-xhigh", "Gemini 4.5 Neon"))
        self.assertEqual(usage.newest_agy_model(listing, "neon", "high"),
                         ("gemini-4-neon-high", "Gemini 4 Neon"))
        self.assertIsNone(usage.newest_agy_model(listing, "neon", "max"))
        self.assertIsNone(usage.newest_agy_model("Error: Please sign in", "neon", "high"))


if __name__ == "__main__":
    unittest.main()
