"""Check the pilot companion's provenance and evidence boundaries; never run Godot."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def validate_record(record, root=ROOT):
    errors = []

    def require(condition, message):
        if not condition:
            errors.append(message)

    def local_file(value):
        if not isinstance(value, str):
            return None
        path = (root / value).resolve()
        return path if path.is_relative_to(root.resolve()) and path.is_file() else None

    require(record.get("schema") == "ada.book-experiment.v1", "Unknown record schema")
    executed = record.get("status") == "in_progress"
    require(record.get("status") in {"proposed", "in_progress"}, "Pilot completion requires human review")
    require(record.get("disposition") == "experimental", "Pilot editorial disposition changed without review")
    sources = record.get("sources", [])
    require(bool(sources), "A passage source is required")
    for source in sources:
        require(local_file(source.get("source_path")) is not None, "Source path missing")
        snapshot = local_file(source.get("snapshot_path"))
        require(snapshot is not None, "Recoverable source snapshot missing")
        if snapshot:
            require(hashlib.sha256(snapshot.read_bytes()).hexdigest() == source.get("sha256"), "Source snapshot hash differs")
            require(bool(source.get("excerpt")) and source["excerpt"] in snapshot.read_text(encoding="utf-8"), "Source excerpt not found")
    passages = [s.get("passage_id") for s in sources]
    roles = {s.get("passage_id"): s.get("text_role") for s in sources}
    require(set(roles.values()) == {"tutorial", "final"}, "Pilot must bind tutorial and final sources")
    initiation = record.get("initiation", {})
    questions = initiation.get("questions", [])
    require(initiation.get("allowed_text_roles") == ["tutorial", "final"] and initiation.get("status") == ("selected_and_executed_scoped" if executed else "proposed") and bool(initiation.get("reconsider_if")), "Initiation roles or reconsideration conditions missing")
    require({q.get("text_role") for q in questions} == {"tutorial", "final"} and all(q.get("question") and q.get("passage_id") in roles and roles[q["passage_id"]] == q.get("text_role") for q in questions), "Initiating questions must resolve to both source roles")
    reviews = record.get("text_reviews", {})
    require(set(reviews) == {"tutorial", "final"}, "Both texts need independent reviews")
    for role, review in reviews.items():
        refs = review.get("source_passage_ids", [])
        require(bool(refs) and all(p in roles and roles[p] == role for p in refs), "Review source does not match text role")
        require(local_file(review.get("source_path")) is not None and all(any(s["passage_id"] == p and s["source_path"] == review["source_path"] for s in sources) for p in refs), "Review path differs from its source")
        if executed:
            observation_ids = {o.get("id") for o in record.get("observations", [])}
            require(review.get("status") == "reviewed_scoped" and review.get("decision") in {"revise", "retain_with_reason", "open_question"} and bool(review.get("reason")) and bool(review.get("observation_ids")) and set(review["observation_ids"]) <= observation_ids, "Review lacks scoped evidence or reason")
            successor = review.get("successor_source")
            if review.get("decision") == "revise":
                path = local_file((successor or {}).get("path"))
                require(path is not None and hashlib.sha256(path.read_bytes()).hexdigest() == successor.get("sha256"), "Revised text is not recoverable")
        else:
            require(review.get("status") == "pending_evidence" and review.get("decision") is None and review.get("reason") is None and review.get("observation_ids") == [] and review.get("successor_source") is None, "Review claims a result before experiment evidence")
    review_contract = record.get("review_contract", {})
    require(review_contract.get("targets") == ["tutorial", "final"] and review_contract.get("allowed_decisions") == ["revise", "retain_with_reason", "open_question"] and review_contract.get("both_rewrites_required") is False and review_contract.get("pending_is_complete") is False, "Review contract must allow retention without skipping a text")
    next_experiment = record.get("next_experiment", {})
    require(next_experiment.get("allowed_decisions") == ["continue", "redirect", "defer", "stop"], "Next decision vocabulary differs")
    if executed:
        require(next_experiment.get("selection_status") == "selected_provisionally" and next_experiment.get("decision") in next_experiment["allowed_decisions"] and all(next_experiment.get(k) for k in ("question", "proposition", "source_observation_ids")) and set(next_experiment["source_observation_ids"]) <= {o.get("id") for o in record.get("observations", [])}, "Next-work decision lacks observations or provisional scope")
    else:
        require(next_experiment.get("selection_status") == "awaiting_observations" and next_experiment.get("source_observation_ids") == [] and all(next_experiment.get(k) is None for k in ("question", "decision", "proposition")), "Next experiment must await actual evidence")
    variants = record.get("interpretations", [])
    ids = [record.get("id")] + passages + [v.get("id") for v in variants]
    require(all(isinstance(i, str) and i for i in ids) and len(ids) == len(set(ids)), "Identities missing or overlapping")
    require(len(variants) >= 2, "Competing interpretations required")
    for variant in variants:
        require(bool(variant.get("passage_ids")) and set(variant["passage_ids"]) <= set(passages), "Interpretation has unresolved passage")
        require(all(variant.get(k) for k in ("mapping", "assumptions", "exclusions")), "Interpretation decisions missing")
    docs = record.get("documents", {})
    require(set(docs) == {"proposition", "text_simulation", "observations", "revision"}, "Companion documents incomplete")
    require(all(local_file(p) for p in docs.values()), "Companion document missing")
    simulation = record.get("simulation", {})
    text = simulation.get("text", {})
    require(text.get("kind") == "text_thought_experiment" and text.get("status") == "authored_hypothesis", "Prediction mislabelled as evidence")
    require(text.get("path") == docs.get("text_simulation"), "Text simulation reference differs")
    godot = simulation.get("godot", {})
    require(set(godot) == {"scene", "build", "execution_status", "runs"}, "Execution fields incomplete")
    if executed:
        require(local_file(godot.get("scene")) is not None and bool(godot.get("build")) and godot.get("execution_status") == "scripted_pass_human_pending" and bool(godot.get("runs")), "Execution needs scene, build and scoped runs")
        run_ids = [r.get("id") for r in godot.get("runs", [])]
        require(len(run_ids) == len(set(run_ids)), "Duplicate run IDs")
        require(any(r.get("current", True) for r in godot.get("runs", [])), "Current implementation needs a tested run")
        for run in godot.get("runs", []):
            if not run.get("current", True):
                require(run.get("superseded_by") in run_ids, "Historical run has no current successor")
            path = local_file(run.get("path"))
            require(path is not None and hashlib.sha256(path.read_bytes()).hexdigest() == run.get("sha256"), "Run receipt missing or altered")
            if path:
                result = json.loads(path.read_text(encoding="utf-8"))
                require(run.get("passed") is True and result.get("passed") is True and not result.get("failures"), "Run does not establish a pass")
            manifest = local_file(run.get("source_manifest"))
            require(manifest is not None, "Run source manifest missing")
            if manifest:
                for original, receipt in json.loads(manifest.read_text(encoding="utf-8"))["files"].items():
                    snapshot = local_file(receipt.get("snapshot_path"))
                    require(snapshot is not None and hashlib.sha256(snapshot.read_bytes()).hexdigest() == receipt.get("sha256"), "Runtime source snapshot differs")
                    current = local_file(original)
                    if run.get("current", True):
                        require(current is not None and hashlib.sha256(current.read_bytes()).hexdigest() == receipt.get("sha256"), "Current pilot differs from tested source")
        observed_ids = [o.get("id") for o in record.get("observations", [])]
        require(bool(observed_ids) and len(observed_ids) == len(set(observed_ids)), "Observations missing or duplicated")
        for observation in record.get("observations", []):
            require(all(observation.get(k) for k in ("id", "kind", "observer", "method", "result", "limits", "run_ids", "interpretation_ids")), "Observation lacks method or scope")
            require(set(observation.get("run_ids", [])) <= set(run_ids) and set(observation.get("interpretation_ids", [])) <= {v["id"] for v in variants}, "Observation references missing run or interpretation")
            if observation.get("kind") == "human_interface_feedback":
                source = observation.get("source", {})
                path = local_file(source.get("path"))
                require(path is not None and hashlib.sha256(path.read_bytes()).hexdigest() == source.get("sha256"), "Human feedback source missing or altered")
        require(record.get("runtime_verified") is True and bool(record.get("revisions")), "Executed record lacks writing return")
    else:
        require(godot.get("scene") is None and godot.get("build") is None and godot.get("execution_status") == "not_run" and godot.get("runs") == [], "Proposed pilot contains unsupported execution")
        require(record.get("runtime_verified") is False and record.get("observations") == [] and record.get("revisions") == [], "Unrun pilot contains observed results or revisions")
    contract = record.get("record_contract", {})
    if executed:
        values = contract.get("raw_values")
        require(isinstance(values, list) and len(values) == 48 and all(type(v) in {int, float} and 0 <= v <= 1 for v in values), "Invalid captured baseline")
        receipt = contract.get("captured_record", {})
        path = local_file(receipt.get("path"))
        require(path is not None and hashlib.sha256(path.read_bytes()).hexdigest() == receipt.get("sha256"), "Captured record missing or altered")
        if path:
            kept = json.loads(path.read_text(encoding="utf-8"))
            require(kept.get("raw_values") == values and kept.get("seed") == "42", "Captured result differs from baseline")
    else:
        require(contract.get("raw_values") is None, "No captured baseline exists yet")
    require(contract.get("sample_count") == 48 and contract.get("cells") == 16 and contract.get("values_per_cell") == 3 and contract.get("grid") == [4, 4], "Pilot must retain 16 ordered triples")
    fixture = record.get("reference_fixture", {})
    require(fixture.get("kind") == "invented_arithmetic_fixture_not_rng_output" and fixture.get("evidence_status") == ("native_checked_invented_fixture" if executed else "calculated_expectation_not_executed"), "Fixture presented as observed RNG output")
    require(len(fixture.get("values", [])) == 48 and len(fixture.get("expected_heights_m", [])) == 16, "Reference fixture shape differs")
    debt = record.get("learning_debt", [])
    require(bool(debt) and all(d.get("question") and d.get("next_test") and d.get("status") in ({"open", "resolved_scoped"} if executed else {"open"}) for d in debt), "Learning debt missing")
    evidence = record.get("evidence_status", {})
    expected = {**{k: "not_tested" for k in ("artifact", "experiment_cycle", "scene_loading", "runtime_stability", "performance", "physical_VR", "independent_learner")}, "specified_cross_hall": "not_applicable_local_pilot"}
    if executed:
        expected.update(artifact="passed_native_scoped", experiment_cycle="scripted_pass_human_pending", scene_loading="passed_isolated_museum", runtime_stability="short_scripted_run_only")
        if any(o.get("kind") == "human_interface_feedback" for o in record.get("observations", [])):
            expected["human_feedback"] = "received"
    require(evidence == expected, "Evidence status overstates available scope")
    tasks = {t["id"] for name in ("randomness_research", "randomness_research_writing") for t in json.loads((root / f"doc/tasks/{name}.json").read_text(encoding="utf-8-sig"))["tasks"]}
    require(bool(record.get("related_tasks")) and set(record["related_tasks"]) <= tasks, "Task reference missing")
    require(record.get("edition") == {"id": None, "status": "not_selected", "publication_status": "not_published"}, "No edition has been frozen or published")
    return errors


def validate_all():
    errors = []
    records = sorted(HERE.glob("*/*/experiment.json"))
    if not records:
        errors.append("No companion records found")
    for path in records:
        errors.extend(f"{path.relative_to(ROOT)}: {e}" for e in validate_record(json.loads(path.read_text(encoding="utf-8"))))
    documents = list(HERE.rglob("*.md")) + [HERE.parent / n for n in ("RECURSIVE_ARCHITECTURE.md", "RECURSIVE_BOOK_BLOG.md")]
    for path in documents:
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", path.read_text(encoding="utf-8")):
            target = target.strip("<>").split("#", 1)[0]
            if target and not re.match(r"^[A-Za-z]+://", target) and not (path.parent / target).resolve().exists():
                errors.append(f"{path.relative_to(ROOT)}: broken link {target}")
    return {"scope": "Pilot companion static provenance and status checks only", "records": len(records), "errors": errors,
            "runtime": "not executed by this static validator; consult run receipts", "physical_VR": "not tested", "independent_learner": "not tested"}


if __name__ == "__main__":
    result = validate_all()
    print(json.dumps(result, ensure_ascii=False))
    raise SystemExit(bool(result["errors"]))
