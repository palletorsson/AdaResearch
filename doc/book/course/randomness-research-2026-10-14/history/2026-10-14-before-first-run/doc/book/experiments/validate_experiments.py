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
    require(record.get("status") == "proposed", "Pilot status needs review against actual evidence")
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
    require(initiation.get("allowed_text_roles") == ["tutorial", "final"] and initiation.get("status") == "proposed" and bool(initiation.get("reconsider_if")), "Initiation roles or reconsideration conditions missing")
    require({q.get("text_role") for q in questions} == {"tutorial", "final"} and all(q.get("question") and q.get("passage_id") in roles and roles[q["passage_id"]] == q.get("text_role") for q in questions), "Initiating questions must resolve to both source roles")
    reviews = record.get("text_reviews", {})
    require(set(reviews) == {"tutorial", "final"}, "Both texts need independent reviews")
    for role, review in reviews.items():
        refs = review.get("source_passage_ids", [])
        require(bool(refs) and all(p in roles and roles[p] == role for p in refs), "Review source does not match text role")
        require(local_file(review.get("source_path")) is not None and all(any(s["passage_id"] == p and s["source_path"] == review["source_path"] for s in sources) for p in refs), "Review path differs from its source")
        require(review.get("status") == "pending_evidence" and review.get("decision") is None and review.get("reason") is None and review.get("observation_ids") == [] and review.get("successor_source") is None, "Review claims a result before experiment evidence")
    review_contract = record.get("review_contract", {})
    require(review_contract.get("targets") == ["tutorial", "final"] and review_contract.get("allowed_decisions") == ["revise", "retain_with_reason", "open_question"] and review_contract.get("both_rewrites_required") is False and review_contract.get("pending_is_complete") is False, "Review contract must allow retention without skipping a text")
    next_experiment = record.get("next_experiment", {})
    require(next_experiment.get("selection_status") == "awaiting_observations" and next_experiment.get("source_observation_ids") == [] and all(next_experiment.get(k) is None for k in ("question", "decision", "proposition")) and next_experiment.get("allowed_decisions") == ["continue", "redirect", "defer", "stop"], "Next experiment must await actual evidence")
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
    require(godot.get("scene") is None and godot.get("build") is None and godot.get("execution_status") == "not_run" and godot.get("runs") == [], "Proposed pilot contains unsupported execution")
    require(record.get("runtime_verified") is False and record.get("observations") == [] and record.get("revisions") == [], "Unrun pilot contains observed results or revisions")
    contract = record.get("record_contract", {})
    require(contract.get("raw_values") is None, "No captured baseline exists yet")
    require(contract.get("sample_count") == 48 and contract.get("cells") == 16 and contract.get("values_per_cell") == 3 and contract.get("grid") == [4, 4], "Pilot must retain 16 ordered triples")
    fixture = record.get("reference_fixture", {})
    require(fixture.get("kind") == "invented_arithmetic_fixture_not_rng_output" and fixture.get("evidence_status") == "calculated_expectation_not_executed", "Fixture presented as observed RNG output")
    require(len(fixture.get("values", [])) == 48 and len(fixture.get("expected_heights_m", [])) == 16, "Reference fixture shape differs")
    debt = record.get("learning_debt", [])
    require(bool(debt) and all(d.get("question") and d.get("next_test") and d.get("status") == "open" for d in debt), "Open learning debt missing")
    evidence = record.get("evidence_status", {})
    require(evidence == {**{k: "not_tested" for k in ("artifact", "experiment_cycle", "scene_loading", "runtime_stability", "performance", "physical_VR", "independent_learner")}, "specified_cross_hall": "not_applicable_local_pilot"}, "Evidence status overstates the proposed pilot")
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
            "runtime": "not run", "physical_VR": "not tested", "independent_learner": "not tested"}


if __name__ == "__main__":
    result = validate_all()
    print(json.dumps(result, ensure_ascii=False))
    raise SystemExit(bool(result["errors"]))
