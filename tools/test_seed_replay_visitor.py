"""Independent tests for the visitor's evidence boundaries and pass criteria.

No Godot process, TypeSafe request, environment credential, or museum content is
used by these tests. Fixtures model observed colours; they are not an RNG oracle.
"""
from __future__ import annotations

import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import Mock, patch


SPEC = importlib.util.spec_from_file_location(
    "seed_replay_visitor", Path(__file__).with_name("seed_replay_visitor.py")
)
visitor = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(visitor)


def panel(offset=0.0):
    return [[0.1 + offset + i / 1000, 0.2, 0.3] for i in range(64)]


def observation(index, columns, seed=42, action="ARRIVAL"):
    return {
        "id": index,
        "labels": ["SAME SEED TWICE", f"SEED: {seed}", f"SEED: {seed}", f"{action} / seed {seed}"],
        "actions": copy.deepcopy(visitor.ACTIONS),
        "columns": copy.deepcopy(columns),
        "dispatch": {"ok": True, "action": action},
        "diagnostics": {"private_rng_state": "DO_NOT_SEND_RNG_STATE"},
        "expected_result": "DO_NOT_SEND_ORACLE",
        "source": "DO_NOT_SEND_SOURCE",
    }


def completed_trace():
    actions = ["replay", "random", "replay", "extra_draw", "replay", "extra_draw", "replay", "finish"]
    a, b, shifted = panel(), panel(0.2), panel(0.4)
    pairs = [[a, a], [a, a], [b, b], [b, b], [b, shifted], [b, shifted], [b, b], [b, b], [b, b]]
    states = [observation(i, pair, 42 if i < 2 else 137, "ARRIVAL" if i == 0 else actions[i - 1])
              for i, pair in enumerate(pairs)]
    return states, actions


def valid_response(choice="replay"):
    return {"answers": {"next_action": {
        "type": "choice", "choice": choice, "confidence": 0.7,
        "probabilities": {key: 0.7 if key == choice else 0.1 for key in visitor.ACTIONS},
    }}}


class EvidenceBoundaryTests(unittest.TestCase):
    def test_public_payload_excludes_private_source_oracle_and_dispatch(self):
        original = observation(0, [panel(), panel()])
        public = visitor.public_observation(original)
        payload = visitor.payload_for([{"observation": public}], "unit-test-model")
        encoded = json.dumps(payload)
        for forbidden in ["DO_NOT_SEND_RNG_STATE", "DO_NOT_SEND_ORACLE", "DO_NOT_SEND_SOURCE", "diagnostics", "dispatch"]:
            self.assertNotIn(forbidden, encoded)
        self.assertEqual(public["labels"], original["labels"])
        self.assertEqual(public["panels"][0]["cell_count"], 64)
        self.assertEqual(public["panels"][0]["first_six_rgb_cells"], panel()[:6])
        self.assertEqual(public["panels"][0]["colour_signature"], public["panels"][1]["colour_signature"])

    def test_colour_signature_includes_cells_beyond_preview(self):
        changed = panel()
        changed[-1][2] = 0.8
        public = visitor.public_observation(observation(0, [panel(), changed]))
        self.assertEqual(public["panels"][0]["first_six_rgb_cells"], public["panels"][1]["first_six_rgb_cells"])
        self.assertNotEqual(public["panels"][0]["colour_signature"], public["panels"][1]["colour_signature"])

    def test_final_request_asks_for_observed_results_and_no_action(self):
        payload = visitor.payload_for([], "unit-test-model", final=True)
        self.assertNotIn("next_action", payload["questions"])
        self.assertEqual(set(payload["questions"]), {"replay_observation", "seed_alone"})
        for spec in payload["questions"].values():
            self.assertIn("insufficient_evidence", spec["criteria"])


class CoverageTaskTests(unittest.TestCase):
    def test_exploration_remains_default(self):
        default = visitor.payload_for([], "test-model")
        explicit = visitor.payload_for([], "test-model", task="exploration")
        self.assertEqual(default, explicit)
        self.assertEqual(default["state"]["task"],
                         "Investigate how to reproduce the displayed colour arrangement using the available controls.")

    def test_coverage_changes_task_not_observations_or_allowed_actions(self):
        history = [{"observation": visitor.public_observation(observation(0, [panel(), panel()]))}]
        original = copy.deepcopy(history)
        payload = visitor.payload_for(history, "test-model", task="coverage", max_actions=9)
        self.assertEqual(history, original)
        self.assertEqual(payload["state"]["observations_and_actions"], original)
        self.assertEqual(payload["questions"]["next_action"]["criteria"], visitor.ACTIONS)
        for quota in ["two REPLAY", "one RANDOM", "two +1 DRAW", "9 action choices"]:
            self.assertIn(quota, payload["state"]["task"])
        for forbidden in ["DO_NOT_SEND", "expected_result", "private_rng_state", "dispatch"]:
            self.assertNotIn(forbidden, json.dumps(payload))

    def test_final_interpretation_questions_are_identical_between_tasks(self):
        original = visitor.payload_for([], "test-model", final=True)
        coverage = visitor.payload_for([], "test-model", final=True, task="coverage")
        self.assertEqual(original["questions"], coverage["questions"])

    def test_unknown_task_rejected(self):
        with self.assertRaises(ValueError):
            visitor.payload_for([], "test-model", task="invented")


class ChoiceValidationTests(unittest.TestCase):
    def test_valid_known_choice(self):
        self.assertEqual(visitor.validate_choice(valid_response(), "next_action", visitor.ACTIONS), "replay")

    def test_rejects_unknown_action(self):
        response = valid_response()
        response["answers"]["next_action"]["choice"] = "delete_all_artifacts"
        with self.assertRaises(ValueError):
            visitor.validate_choice(response, "next_action", visitor.ACTIONS)

    def test_rejects_bad_probabilities(self):
        replacements = [True, -0.1, 1.1, float("nan"), float("inf"), "0.7", None]
        for value in replacements:
            with self.subTest(value=value):
                response = valid_response()
                response["answers"]["next_action"]["probabilities"]["replay"] = value
                with self.assertRaises(ValueError):
                    visitor.validate_choice(response, "next_action", visitor.ACTIONS)

    def test_rejects_missing_options_wrong_sum_and_nonwinning_choice(self):
        cases = []
        response = valid_response()
        del response["answers"]["next_action"]["probabilities"]["finish"]
        cases.append(response)
        response = valid_response()
        response["answers"]["next_action"]["probabilities"]["finish"] = 0.6
        cases.append(response)
        response = valid_response()
        response["answers"]["next_action"]["choice"] = "random"
        cases.append(response)
        for response in cases:
            with self.subTest(response=response), self.assertRaises(ValueError):
                visitor.validate_choice(response, "next_action", visitor.ACTIONS)

    def test_rejects_malformed_json_shapes_with_controlled_validation_error(self):
        cases = [None, [], {"answers": None}, {"answers": []},
                 {"answers": {"next_action": None}}, {"answers": {"next_action": []}}]
        for field, value in [("choice", []), ("probabilities", None), ("probabilities", []), ("confidence", {})]:
            response = valid_response()
            response["answers"]["next_action"][field] = value
            cases.append(response)
        for response in cases:
            with self.subTest(response=response), self.assertRaises(ValueError):
                visitor.validate_choice(response, "next_action", visitor.ACTIONS)


class TraceOracleTests(unittest.TestCase):
    def test_complete_supported_trace_passes(self):
        states, actions = completed_trace()
        self.assertTrue(visitor.evaluate(states, actions)["passed"])

    def test_early_finish_is_not_success(self):
        states, _ = completed_trace()
        result = visitor.evaluate(states[:2], ["finish"])
        self.assertFalse(result["passed"])
        self.assertFalse(result["coverage_complete"])

    def test_failed_dispatch_cannot_pass_even_with_correct_colours(self):
        states, actions = completed_trace()
        states[1]["dispatch"]["ok"] = False
        self.assertFalse(visitor.evaluate(states, actions)["passed"])

    def test_replay_changing_last_cell_fails(self):
        states, actions = completed_trace()
        states[1]["columns"][1][-1][2] = 0.91
        self.assertFalse(visitor.evaluate(states, actions)["passed"])

    def test_extra_draw_changing_left_panel_fails(self):
        states, actions = completed_trace()
        states[4]["columns"][0][-1][2] = 0.91
        self.assertFalse(visitor.evaluate(states, actions)["passed"])

    def test_truncated_observations_cannot_silently_drop_an_action(self):
        states, actions = completed_trace()
        self.assertFalse(visitor.evaluate(states[:-1], actions)["passed"])

    def test_extra_unobserved_action_cannot_pass(self):
        states, actions = completed_trace()
        self.assertFalse(visitor.evaluate(states, actions + ["random"])["passed"])

    def test_unknown_action_cannot_pass(self):
        states, actions = completed_trace()
        actions[0] = "unavailable_action"
        self.assertFalse(visitor.evaluate(states, actions)["passed"])

    def test_failed_finish_dispatch_cannot_pass(self):
        states, actions = completed_trace()
        states[-1]["dispatch"]["ok"] = False
        self.assertFalse(visitor.evaluate(states, actions)["passed"])

    def test_duplicate_observation_ids_cannot_pass(self):
        states, actions = completed_trace()
        states[-1]["id"] = states[-2]["id"]
        self.assertFalse(visitor.evaluate(states, actions)["passed"])

    def test_malformed_colour_samples_cannot_pass(self):
        for cell in [None, [0.1, 0.2], [0.1, 0.2, float("nan")], [0.1, 0.2, "blue"], [0.1, 0.2, True]]:
            with self.subTest(cell=cell):
                states, actions = completed_trace()
                # Alter every snapshot consistently, so temporal equality alone cannot catch it.
                for state in states:
                    for column in state["columns"]:
                        column[-1] = copy.deepcopy(cell)
                self.assertFalse(visitor.evaluate(states, actions)["passed"])

    def test_repeated_random_seed_is_legal(self):
        states, actions = completed_trace()
        # Insert a RANDOM trial that returns its input seed/colours. Existing later
        # RANDOM still supplies a changed-seed observation for coverage.
        states.insert(1, copy.deepcopy(states[0]))
        actions.insert(0, "random")
        for index, state in enumerate(states):
            state["id"] = index
        self.assertTrue(visitor.evaluate(states, actions)["passed"])


class InterpretationOracleTests(unittest.TestCase):
    def test_same_seed_different_procedure_is_observed_counterexample(self):
        states, actions = completed_trace()
        self.assertEqual(visitor.observed_conclusions(states, actions), {
            "replay_observation": "reproduced", "seed_alone": "counterexample_observed",
        })

    def test_changed_replay_is_not_reproduction(self):
        states, actions = completed_trace()
        states[1]["columns"][1][-1][2] = 0.91
        self.assertEqual(visitor.observed_conclusions(states, actions)["replay_observation"], "changed")

    def test_no_replay_trial_is_insufficient_evidence(self):
        state = observation(0, [panel(), panel()])
        self.assertEqual(visitor.observed_conclusions([state], [])["replay_observation"], "insufficient_evidence")

    def test_missing_seed_labels_do_not_fabricate_counterexample(self):
        states, actions = completed_trace()
        for state in states:
            state["labels"] = ["SEED REPLAY", "REPLAY", "RANDOM", "+1 DRAW"]
        self.assertEqual(visitor.observed_conclusions(states, actions)["seed_alone"], "insufficient_evidence")

    def test_ambiguous_different_panel_seeds_do_not_count_as_same_seed(self):
        states, actions = completed_trace()
        for state in states:
            state["labels"] = ["SEED: 42", "SEED: 137"]
        self.assertEqual(visitor.observed_conclusions(states, actions)["seed_alone"], "insufficient_evidence")

    def test_distinct_seeds_with_distinct_colours_do_not_refute_seed_alone(self):
        states = [observation(0, [panel(), panel()], 42),
                  observation(1, [panel(0.2), panel(0.2)], 137, "random")]
        self.assertEqual(visitor.observed_conclusions(states, ["random"])["seed_alone"], "not_observed")

    def test_one_visible_pair_with_same_seed_and_different_colours_is_counterexample(self):
        state = observation(0, [panel(), panel(0.2)], 42)
        self.assertEqual(visitor.observed_conclusions([state], [])["seed_alone"], "counterexample_observed")


class RunnerOutcomeTests(unittest.TestCase):
    def test_nonzero_engine_exit_does_not_leave_passed_true(self):
        states, _ = completed_trace()
        process = Mock()
        process.wait.return_value = 3
        process.poll.return_value = 3
        with tempfile.TemporaryDirectory(prefix="ada-seed-visitor-test-") as directory:
            out = Path(directory) / "run"
            with patch.object(visitor.sys, "argv", ["seed_replay_visitor.py", "--mode", "scripted", "--out", str(out)]), \
                 patch.object(visitor.subprocess, "Popen", return_value=process), \
                 patch.object(visitor, "wait_observation", side_effect=states), \
                 patch.object(visitor, "fingerprints", return_value={"fixture": "unchanged"}), \
                 patch.object(visitor, "get_key") as credentials, \
                 patch.object(visitor, "ask_jev") as network:
                status = visitor.main()
            report = json.loads((out / "report.json").read_text(encoding="utf-8"))
            self.assertNotEqual(status, 0)
            self.assertNotEqual(report["outcome"], "passed")
            self.assertFalse(report.get("passed", False))
            credentials.assert_not_called()
            network.assert_not_called()


if __name__ == "__main__":
    unittest.main()
