"""Validate reconciled design/task contracts without changing the museum."""
from pathlib import Path
import ast
import hashlib
import importlib.util
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def load(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def main():
    inventory, route, comparison = [load(HERE / n) for n in ("inventory.json", "route.json", "comparison.json")]
    issues = [load(ROOT / f"doc/tasks/{n}.json") for n in ("randomness_research", "randomness_research_writing")]
    checks = []

    def check(name, condition, detail=None):
        checks.append({"check":name,"pass":bool(condition),"detail":detail})

    check("All randomness identities retained once", len(route["randomness_order"]) == len(set(route["randomness_order"])) == 14 and set(route["randomness_order"]) == set(inventory["orders"]["randomness"]))
    check("Eleven noise identities retain current order", route["noise_order"] == inventory["orders"]["noise"] and len(route["noise_order"]) == 11)
    check("Five particle identities retain current order", route["particle_order"] == inventory["orders"]["particles"] and len(route["particle_order"]) == 5)
    check("No required new halls; four earlier names deferred", not route["required_new_maps"] and len(set(route["deferred_new_maps"])) == 4)
    check("Optional coda and museum interlude retained", route["optional_stops"] == ["Lab_Path"] and route["museum_interludes"] == ["Biome_Cage"])
    check("Noise handover is Shaders", route["preserved_exit"] == {"map":"Noise_Perlin_Simplex","destination_sequence":"shaders"})
    check("Local baselines and optional imports explicit", route["imports_optional"] and route["destinations_have_local_baselines"])
    check("Seven contracts; local pilot before cross-hall", route["transfer_ids"] == [f"X{i}" for i in range(1,8)] and route["first_local_transfer"] == "X1" and route["first_cross_hall_transfer"] == "X2")
    check("Manifest proposed and not installed", route["status"] == "proposed" and route["runtime_installed"] is False)
    maps = set(route["randomness_order"] + route["noise_order"] + route["particle_order"] + route["later_returns"] + route["museum_interludes"])
    for hosts in route["research_extensions"].values():
        maps.update(hosts)
    missing = sorted(m for m in maps if not (ROOT / f"commons/maps/{m}/map_data.json").exists())
    check("All proposed reused hosts exist", not missing, missing)
    check("Inventory covers 31 spaces", len(inventory["halls"]) == 31)
    check("Selected names/scenes resolve at snapshot", not inventory["coverage"]["missing_registry_keys"] and not inventory["coverage"]["missing_selected_scenes"])
    tasks = [t for issue in issues for t in issue["tasks"]]
    by_id = {t["id"]:t for t in tasks}
    ids = set(by_id)
    check("Twenty stable main IDs and five writing IDs", {t["id"] for t in issues[0]["tasks"]} == {f"randomness_research.{i:03}" for i in range(1,21)} and {t["id"] for t in issues[1]["tasks"]} == {f"randomness_research_writing.{i:03}" for i in range(1,6)} and len(ids) == len(tasks))
    check("Required repository task fields", all({"id","title","spec","effort","skill","status"} <= set(t) for t in tasks))
    check("Repository status vocabulary", all(t["status"] in {"open","claimed","blocked","done","cancelled"} for t in tasks))
    check("Cross-goal dependencies exist", all(set(t["depends_on"]) <= ids for t in tasks))
    visited, stack = set(), set()

    def visit(tid):
        if tid in stack or tid not in by_id:
            return False
        if tid in visited:
            return True
        stack.add(tid)
        for dep in by_id[tid]["depends_on"]:
            if not visit(dep):
                return False
        stack.remove(tid)
        visited.add(tid)
        return True

    check("Combined task graph acyclic", all(visit(tid) for tid in ids))

    def ancestors(tid, seen=None):
        seen = set() if seen is None else seen
        for dep in by_id.get(tid,{}).get("depends_on",[]):
            if dep not in seen:
                seen.add(dep)
                ancestors(dep,seen)
        return seen

    optional = {t["id"] for t in tasks if t.get("optional_extension")}
    check("Five lessons and integration do not wait for optional research", not (ancestors("randomness_research.013") | ancestors("randomness_research.020")) & optional)
    check("Emitter lesson does not require distribution import", "randomness_research.005" not in ancestors("randomness_research.009"))
    check("Particle continuation order is P1 P2 P3 P4 P5", all(f"randomness_research.{a:03}" in ancestors(f"randomness_research.{b:03}") for a,b in [(8,9),(9,11),(11,10),(10,13)]))
    check("Only static audit marked done in this specification", [t["id"] for t in tasks if t["status"] == "done"] == ["randomness_research.001"])
    check("All three verification levels retained", all(t["verification_levels"] == ["artifact","experiment_cycle","specified_cross_hall"] for t in tasks))
    check("Runtime headset and learner evidence separate", all(set(t["separate_evidence"]) == {"scene_loading","runtime_stability","performance","physical_VR","independent_learner"} for t in tasks))
    missing = [(t["id"],m) for t in tasks for m in t.get("map_refs",[]) if not (ROOT / f"commons/maps/{m}/map_data.json").exists()]
    check("Task map references resolve", not missing, missing)
    imported = HERE / "imports/2026-10-14"
    manifest = load(imported / "manifest.json")
    bad = [p for p,h in manifest["files"].items() if digest(imported / p) != h]
    check("Eight imported sources preserved byte for byte", len(manifest["files"]) == 8 and not bad, bad)
    original_ids = {t["id"] for p in (imported / "doc/tasks").glob("*.json") for t in load(p)["tasks"]}
    mappings = comparison["imported_task_mapping"]
    check("All 34 imported tasks mapped once", len(mappings) == len(original_ids) == 34 and {t["imported_id"] for t in mappings} == original_ids)
    check("Imported mappings resolve", all(t["incorporated_into"] and set(t["incorporated_into"]) <= ids for t in mappings))
    check("Canonical tasks link back to imported sources", all(t["imported_id"] in by_id[tid]["imported_task_refs"] for t in mappings for tid in t["incorporated_into"]))
    check("No imported goal duplicated in live tracker", not any((ROOT / "doc/tasks" / p.name).exists() for p in (imported / "doc/tasks").glob("*.json")))
    existing = {t["id"] for name in ("book_randomness","book_noise") for t in load(ROOT / f"doc/tasks/{name}.json")["tasks"]}
    check("Existing book-ticket references resolve", all(set(t.get("existing_task_refs",[])) <= existing for t in tasks))
    stale = [p for p,h in inventory["source_sha256"].items() if digest(ROOT / p) != h]
    stale_comparison = [p for p,v in comparison["evidence"].items() if digest(ROOT / p) != v["working_sha256"]]
    check("Inventory evidence remains current", not stale, stale)
    check("Comparison evidence remains current", not stale_comparison, stale_comparison)
    broken = []
    for p in HERE.glob("*.md"):
        if p.name == "SOURCE.md":
            continue
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)",p.read_text(encoding="utf-8")):
            target = target.strip("<>").split("#",1)[0]
            if target and not re.match(r"^[A-Za-z]+://",target) and not (p.parent / target).resolve().exists():
                broken.append(f"{p.name}: {target}")
    check("Authored local links resolve", not broken, broken)
    spec = (HERE / "SPEC.md").read_text(encoding="utf-8")
    check("to-spec structure retained", all("## "+h in spec for h in ["Problem Statement","Solution","User Stories","Implementation Decisions","Testing Decisions","Out of Scope","Further Notes"]))
    source = Path("C:/Users/palle/.codex/attachments/809c158d-9fa4-413e-b307-0c60434ce852/Pasted text.txt")
    check("Original user text byte-identical", source.read_bytes() == (HERE / "SOURCE.md").read_bytes())
    text = (HERE / "PARTICLE_PATH.md").read_text(encoding="utf-8")
    check("Written particle order matches manifest", re.findall(r"^## P[1-5] · .* — (\w+)$",text,re.MULTILINE) == route["particle_order"])
    text = (HERE / "HALLS.md").read_text(encoding="utf-8")
    check("Written hall orders match manifest", re.findall(r"^\| R\d+ \| `(\w+)`",text,re.MULTILINE) == route["randomness_order"] and re.findall(r"^\| N\d+(?:, optional)? \| `(\w+)`",text,re.MULTILINE) == route["noise_order"])
    check("Written transfers match manifest", re.findall(r"^\| (X\d+) \|",text,re.MULTILINE) == route["transfer_ids"])
    method_sources = HERE / "imports/2026-10-14-recursive-writing"
    method_manifest = load(method_sources / "manifest.json")
    check("Three supplied method texts preserved", len(method_manifest["files"]) == 3 and all(digest(method_sources / name) == item["sha256"] for name,item in method_manifest["files"].items()))
    history = HERE / "history/2026-10-14-before-recursive-writing"
    before = load(history / "manifest.json")
    check("Predecessor prose and task graph preserved", all(digest(history / name) == item["sha256"] for name,item in before["files"].items()))
    revisions = load(HERE / "plan_revisions.json")["revisions"]
    current = revisions[-1]
    check("Current plan revision is clarification rather than invented observation", current["basis_kind"] == "user_supplied_method_clarification" and current["status"] == "applied_to_spec_only" and not current["observations"] and current["runtime_changes"] is False)
    check("Plan revision matches current generated documents", all(digest(ROOT / path) == sha for path,sha in current["after_sha256"].items()))
    check("Revision preserves task IDs and names a real review", current["followup_task"] in ids and all(t["task_id"] in ids for t in current["task_changes"]))
    examples = load(HERE / "text_experiments.json")
    records = examples["records"]
    check("Text examples explicitly unbuilt and unobserved", examples["status"] == "design_examples_only" and examples["runtime_installed"] is False and all(r["runtime_verified"] is False and all(v["apparatus"] is None and v["execution_status"] == "not_run" and not v["observations"] for v in r["interpretations"]) for r in records))
    passage_ids = [r["passage_id"] for r in records]
    interpretation_ids = [v["interpretation_id"] for r in records for v in r["interpretations"]]
    check("Passage and interpretation IDs distinct and unique", len(set(passage_ids + interpretation_ids)) == len(passage_ids + interpretation_ids) and all(len(r["interpretations"]) >= 2 for r in records))
    check("Passage sources resolve by excerpt and snapshot hash", all(digest(HERE / r["source_snapshot"]) == r["source_sha256"] and r["excerpt"] in (HERE / r["source_snapshot"]).read_text(encoding="utf-8") for r in records))
    check("Reciprocal pilot starts before noise and final particle delivery", "randomness_research.003" in ancestors("randomness_research_writing.002") and not {"randomness_research.007","randomness_research.013"} & ancestors("randomness_research_writing.002"))
    check("Pilot review can redirect source/distribution expansion", all("randomness_research_writing.005" in ancestors(f"randomness_research.{n:03}") for n in [4,5]))
    check("Five particle lessons do not wait for the plan review", "randomness_research_writing.005" not in ancestors("randomness_research.013"))
    check("Writing cycle and two opening trials explicit", route["text_simulation_loop"]["writing_cycle"] == ["generate","read","question","test","revise","rediscover"] and route["text_simulation_loop"]["many_to_many"] and route["text_simulation_loop"]["observations_can_revise_plan"] and route["opening_trials"]["status"] == "proposed_not_run" and route["opening_trials"]["requires_new_hall"] is False)
    architecture_sources = HERE / "imports/2026-10-14-book-architecture"
    architecture_manifest = load(architecture_sources / "manifest.json")
    check("Supplied book architecture preserved", all(digest(architecture_sources / name) == item["sha256"] for name,item in architecture_manifest["files"].items()))
    architecture_history = HERE / "history/2026-10-14-before-book-architecture"
    architecture_before = load(architecture_history / "manifest.json")
    check("Pre-architecture documents and source anchors preserved", all(digest(architecture_history / name) == item["sha256"] for name,item in architecture_before["files"].items()))
    previous_revision = load(architecture_history / "plan_revisions.json")["revisions"][-1]
    archived_by_path = {item["source_path"]: architecture_history / name for name,item in architecture_before["files"].items()}
    check("Earlier plan revision remains recoverable", revisions[:-1] == load(architecture_history / "plan_revisions.json")["revisions"] and all(path in archived_by_path and digest(archived_by_path[path]) == sha for path,sha in previous_revision["after_sha256"].items()))
    book = route["book_architecture"]
    check("Book entry modes and proposed pilot linked", book["reader_modes"] == ["read","reconstruct","investigate"] and book["pilot_status"] == "proposed_not_run" and book["edition_status"] == "not_frozen" and (ROOT / book["contract"]).exists() and (ROOT / book["pilot_record"]).exists() and book["pilot_record"] in examples["companion_records"])
    module_spec = importlib.util.spec_from_file_location("ada_book_companions", ROOT / "doc/book/experiments/validate_experiments.py")
    module = importlib.util.module_from_spec(module_spec)
    module_spec.loader.exec_module(module)
    companion_report = module.validate_all()
    check("Companion provenance, links and evidence boundaries valid", not companion_report["errors"], companion_report["errors"])
    progress_fields = ("status","claimed_by","done_at","blocked_reason","progress","evidence","notes")
    old_tasks = {t["id"]:t for name in ("randomness_research.json","randomness_research_writing.json") for t in load(architecture_history / name)["tasks"]}
    check("Architecture retains task identities dependencies and progress", ids == set(old_tasks) and all(t["depends_on"] == old_tasks[t["id"]]["depends_on"] and all(t.get(k) == old_tasks[t["id"]].get(k) for k in progress_fields) for t in tasks))
    for p in HERE.glob("*.py"):
        ast.parse(p.read_text(encoding="utf-8"),filename=str(p))
    check("Proposal Python sources parse", True)
    errors = [c["check"] for c in checks if not c["pass"]]
    report = {"date":"2026-10-14","scope":"Static specification/comparison validation only",
              "passed":len(checks)-len(errors),"total":len(checks),"errors":errors,"checks":checks,
              "stale_source_receipts":stale,"stale_comparison_receipts":stale_comparison,
              "runtime":"not run","physical_VR":"not tested","independent_learner":"not tested"}
    (HERE / "validation.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({k:report[k] for k in ["scope","passed","total","errors","stale_source_receipts","stale_comparison_receipts"]},ensure_ascii=False))
    if errors:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
