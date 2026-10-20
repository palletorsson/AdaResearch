"""Record this first scoped run; later experiments get their own revision and run IDs."""
from pathlib import Path
import hashlib
import json
import shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[5]
PLAN = HERE.parents[1]
PILOT = ROOT / "doc/book/experiments/random-definition/seed-bench-001"


def load(path): return json.loads(path.read_text(encoding="utf-8-sig"))
def rel(path): return path.relative_to(ROOT).as_posix()
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    record = load(PILOT / "experiment.json")
    assert record["status"] == "proposed", "First-run receipt already recorded; do not overwrite"
    run = HERE / "runs/complete-printed"
    museum = ROOT / "ada_run/encounter_pilot/Random_Definition/seed-bench-001-exact"
    visit = ROOT / "ada_run/encounter_pilot/Random_Definition/seed-bench-001-visit"
    assert load(run / "summary.json")["passed"] and load(museum / "report.json")["passed"]
    assert load(visit / "visit-smoke.json")["camera_is_museum_camera"]
    evidence = HERE / "evidence"
    evidence.mkdir(exist_ok=True)
    for source, name in [(museum / "report.json", "museum.json"), (museum / "stdout.log", "museum.log"),
                         (museum / "source_manifest.json", "museum-sources.json"),
                         (visit / "visit-smoke.json", "visit-smoke.json"), (visit / "smoke.log", "visit-smoke.log")]:
        shutil.copyfile(source, evidence / name)
    # Recoverable pilot implementation and exact printed source, separate from mutable hall text.
    sources = list((PILOT / "runtime").glob("*.gd")) + [PILOT / "runtime/seed_study.tscn",
        PILOT / "tutorial.md", PILOT / "launch.py", HERE / "probe.gd", HERE / "museum_probe.gd", HERE / "run_checks.py"]
    manifest = {"scope": "Final pilot source bytes; museum host dependencies separately hashed in museum-sources.json", "files": {}}
    for source in sources:
        target = evidence / "sources" / rel(source)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        manifest["files"][rel(source)] = {"snapshot_path": rel(target), "sha256": sha(target)}
    write(evidence / "sources.json", manifest)
    run_defs = [("seed-bench.native.001", "scripted_native", run / "native.json"),
        ("seed-bench.replay.001", "fresh_process_replay", run / "fresh-process.json"),
        ("seed-bench.printed.001", "automated_printed_reconstruction", run / "printed-reconstruction.json"),
        ("seed-bench.museum.001", "rendered_scripted_museum", evidence / "museum.json"),
        ("seed-bench.launcher.001", "launcher_smoke", evidence / "visit-smoke.json")]
    runs = [{"id": rid, "kind": kind, "path": rel(path), "sha256": sha(path), "passed": True,
             "source_manifest": rel(evidence / "sources.json")} for rid, kind, path in run_defs]
    observation_specs = [
        ("O1", "executed_geometry", [runs[0]["id"], runs[3]["id"]],
         "Seed 42 produces sixteen unchanged RGB triples in both modes. B changes only height. The invented red/green fixture has distinct colours and identical 0.20 m heights.",
         "Expected arithmetic confirmed; no novelty or human preference inferred."),
        ("O2", "implementation_failure_and_repair", [runs[0]["id"], runs[1]["id"]],
         "The first importer rejected JSON-converted parameter types. After that repair, decimal round-trip changed five values by at most 1.111e-16. Exact float bytes plus validated readable values now preserve all 48 values and the mapping across a fresh process.",
         "Failed reports are preserved; early failing source files were not snapshotted. Final repair source is snapshotted. No claim about new unpredictable randomness."),
        ("O3", "automated_reconstruction", [runs[2]["id"]],
         "All three printed scripts extract byte-equivalent source text. The extracted model passes the cycle, and the extracted study constructs the arrays and renders the measured heights. Four deliberate faults are detected.",
         "Mechanical extraction by the authoring agent is not an independent human reconstruction or proof of understanding."),
        ("O4", "ai_image_review", [runs[3]["id"]],
         "Two museum captures show the fixed left reference and the right-hand height change. The carried point initially covered controls; parking it to the left makes those labels visible in the final capture.",
         "Codex image inspection only. VR reach, human legibility, interest, comfort and sustained performance remain untested.")]
    record["observations"] = [{"id": "seed-bench." + oid, "kind": kind, "observer": "Codex; native probes and image inspection",
        "run_ids": refs, "interpretation_ids": [v["id"] for v in record["interpretations"]], "result": result, "limits": limits}
        for oid, kind, refs, result, limits in observation_specs]
    native = load(run / "native.json")
    record.update(status="in_progress", runtime_verified=True)
    record["initiation"]["status"] = "selected_and_executed_scoped"
    record["simulation"]["godot"] = {"scene": rel(PILOT / "runtime/seed_study.tscn"),
        "build": native["observations"]["build"]["string"], "execution_status": "scripted_pass_human_pending", "runs": runs}
    record["record_contract"]["raw_values"] = native["observations"]["baseline"]["raw_values"]
    record["record_contract"]["captured_record"] = {"path": rel(run / "kept.json"), "sha256": sha(run / "kept.json")}
    record["record_contract"]["exact_value_encoding"] = "raw_values_f64_hex: Godot PackedByteArray encode_double/decode_double; readable JSON values checked within 1e-15; seed/state signed decimal strings"
    record["reference_fixture"]["evidence_status"] = "native_checked_invented_fixture"
    record["learning_debt"][0].update(status="resolved_scoped", responsible_reviewer="Codex native probe",
        resolution="Exact byte replay, deep copy, bounds/version validation, atomic import and four fault probes pass on Godot 4.6.")
    record["learning_debt"][1]["next_test"] = "Human trial: record whether the visible difference yields a useful question; use HUMAN_TRIAL.md."
    record["learning_debt"][2]["next_test"] = "Independent reader reconstructs tutorial.md and records borrowed code and assistance in HUMAN_TRIAL.md."
    record["evidence_status"].update(artifact="passed_native_scoped", experiment_cycle="scripted_pass_human_pending",
        scene_loading="passed_isolated_museum", runtime_stability="short_scripted_run_only")
    record["text_reviews"]["tutorial"].update(status="reviewed_scoped", decision="revise",
        reason="Preserving a result needs explicit types, exact values and an atomic importer; arithmetic alone did not secure replay. Print the complete continuation, declare borrowed support, and ask what the mean omits.",
        observation_ids=["seed-bench.O1", "seed-bench.O2", "seed-bench.O3"],
        successor_source={"path": rel(PILOT / "tutorial.md"), "sha256": sha(PILOT / "tutorial.md"),
                          "status": "companion_continuation_not_installed_in_live_hall"})
    record["text_reviews"]["final"].update(status="reviewed_scoped", decision="retain_with_reason",
        reason="The one-more-agreement passage already leaves assignment open. Correct heights do not establish a more useful encounter. Retain this source passage and ask whether the extra geometry helps a person notice anything; do not retrofit an imagined visitor into the final.",
        observation_ids=["seed-bench.O1", "seed-bench.O4"], successor_source=None)
    record["revisions"] = [{"id": "seed-bench.review.001", "observation_ids": [o["id"] for o in record["observations"]],
        "tutorial": "companion continuation authored; original source preserved", "final": "original retained with reasons",
        "apparatus": "atomic import, exact float bytes, point parking; final sources snapshotted",
        "reviewer": "Codex; provisional technical/editorial review, not human acceptance"}]
    record["next_experiment"].update(selection_status="selected_provisionally", decision="defer",
        source_observation_ids=["seed-bench.O1", "seed-bench.O2", "seed-bench.O3", "seed-bench.O4"],
        question="Can a person reconstruct this continuation and explain the equal-height red/green pair, and does that prompt a useful different mapping?",
        proposition="Run the human encounter and independent reconstruction before expanding the apparatus. A first-channel mapping is a candidate only if that encounter motivates it; do not automatically build a sleeve or Source Lab.")
    record["contributions"].append({"role": "implementation, scripted runs, image review and provisional writing/plan return",
        "contributor": "Codex in this conversation", "date": "2026-10-14", "human_trial": "not performed"})
    write(PILOT / "experiment.json", record)
    summary = {"scope": "First scripted cycle and provisional writing return; human cycle incomplete", "runs": runs,
        "record": rel(PILOT / "experiment.json"), "observations": [o["id"] for o in record["observations"]],
        "fault_reports": [rel(p) for p in (run).glob("*/fault.json")],
        "retained_failed_runs": [rel(HERE / "native.json"), rel(HERE / "import-diagnostic.json"), rel(HERE / "runs/import-fixed/native.json"), rel(HERE / "runs/import-fixed/fresh-process.json")],
        "captures": [{"path": rel(museum / name), "sha256": sha(museum / name), "storage": "local image; ignored by repository policy"} for name in ["A-flat.png", "B-mean-height.png"]],
        "physical_VR": "not_tested", "independent_learner": "not_tested", "performance": "not_tested"}
    write(HERE / "evidence.json", summary)
    # Preserve stable IDs and dependencies. Only close the bounded selection and bindings.
    for name in ("randomness_research", "randomness_research_writing"):
        path = ROOT / f"doc/tasks/{name}.json"; tracker = load(path)
        for task in tracker["tasks"]:
            tid = task["id"]
            if tid in ["randomness_research.002", "randomness_research_writing.001"]:
                task.update(status="done", done_at="2026-10-14", claimed_by=None, blocked_reason=None,
                    evidence=[rel(PILOT / "experiment.json"), rel(PLAN / "DECISIONS.md")],
                    notes="User authorized the first experiment loop. Bounded seed bench selected; both exact source questions bound. Broader route/Source Lab/sleeve deployment not selected.")
            elif tid in ["randomness_research.003", "randomness_research_writing.002", "randomness_research_writing.005"]:
                task.update(status="blocked", claimed_by=None, done_at=None,
                    blocked_reason="Awaiting actual human encounter / independent reconstruction. W002 also retains the separate opening-order trial; W005's defer-expansion decision is provisional.",
                    progress="Native 46/46, fresh-process 3/3, printed reconstruction 46/46, museum 10/10; four injected faults detected. Tutorial revised in companion; final retained with reasons. Human/headset evidence absent.",
                    evidence=[rel(PILOT / "experiment.json"), rel(HERE / "evidence.json"), rel(PILOT / "HUMAN_TRIAL.md")])
        write(path, tracker)
    for number in (1, 2, 5):
        path = PLAN / f"implementation/writing/{number:03}/ledger.json"
        write(path, {"record": rel(PILOT / "experiment.json"), "evidence": rel(HERE / "evidence.json"),
            "status": "source_binding_complete" if number == 1 else "scoped_return_complete_human_gates_open",
            "decision": "defer_expansion_pending_human_trial" if number == 5 else None})
    print("Recorded scoped execution; human gates remain open")


if __name__ == "__main__": main()
