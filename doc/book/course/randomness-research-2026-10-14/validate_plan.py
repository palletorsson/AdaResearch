"""Check proposal coverage, dependency graph, links and freshness without changing the museum."""
from pathlib import Path
import hashlib
import json
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]


def load(p):
    return json.loads(p.read_text(encoding="utf-8-sig"))


def main():
    inventory = load(HERE/"inventory.json")
    route = load(HERE/"route.json")
    issue = load(ROOT/"doc/tasks/randomness_research.json")
    checks = []

    def check(name, condition, detail=None):
        checks.append({"check": name, "pass": bool(condition), "detail": detail})

    core, new, sides = set(route["core_order"]), set(route["new_maps"]), set(route["side_visits"])
    current = set(inventory["orders"]["randomness"]+inventory["orders"]["noise"])
    check("All 25 current sequence halls assigned", current <= core|sides, sorted(current-(core|sides)))
    check("Core and side visits do not overlap", not core&sides)
    check("All 5 particle halls retained", set(inventory["orders"]["particles"]) <= set(route["particle_order"]))
    check("Museum-only Biome Cage accounted for", "Biome_Cage" in sides)
    check("18 unique core stops, 8 movements", len(core)==len(route["core_order"])==18 and len(route["movements"])==8)
    check("7 unique particle stops", len(set(route["particle_order"]))==len(route["particle_order"])==7)
    check("15 existing core hosts and 3 new proposals", len(core-new)==15 and len(core&new)==3)
    check("4 new halls total and shared workshop", len(new)==4 and "Random_Rule_Workshop" in core&set(route["particle_order"]))
    missing = sorted(m for m in (core|sides|set(route["particle_order"]))-new if not (ROOT/"commons/maps"/m/"map_data.json").exists())
    check("Every reused map exists", not missing, missing)
    check("New halls not mislabelled as existing", not any((ROOT/"commons/maps"/m/"map_data.json").exists() for m in new))
    check("Seven transfers declared", route["transfer_ids"]==[f"X{i}" for i in range(1,8)])
    check("Manifest explicitly proposed", route["status"]=="proposed" and route["runtime_installed"] is False)
    check("Inventory covers 31 selected maps", len(inventory["halls"])==31)
    check("Selected names and scenes resolve at snapshot", not inventory["coverage"]["missing_registry_keys"] and not inventory["coverage"]["missing_selected_scenes"])
    tasks = issue["tasks"]
    ids = {t["id"] for t in tasks}
    by_id = {t["id"]:t for t in tasks}
    check("20 unique tracker tasks", len(ids)==len(tasks)==20)
    check("Required repository task fields", all({"id","title","spec","effort","skill","status"}<=set(t) for t in tasks))
    check("Repository status vocabulary", all(t["status"] in {"open","claimed","blocked","done","cancelled"} for t in tasks))
    check("Dependencies exist", all(set(t["depends_on"])<=ids for t in tasks))
    visited, stack = set(), set()

    def visit(tid):
        if tid in stack:
            return False
        if tid in visited:
            return True
        stack.add(tid)
        for dep in by_id[tid]["depends_on"]:
            if dep not in by_id or not visit(dep):
                return False
        stack.remove(tid)
        visited.add(tid)
        return True

    check("Task graph acyclic", all(visit(t) for t in ids))
    check("Only static audit is done", [t["id"] for t in tasks if t["status"]=="done"]==["randomness_research.001"])
    check("Implementation awaits review/evidence", tasks[1]["status"]=="open" and all(t["status"]=="blocked" for t in tasks[2:]))
    check("All three verification levels recorded", all(t["verification_levels"]==["artifact","experiment_cycle","specified_cross_hall"] for t in tasks))
    broken = []
    docs = ["README.md","SPEC.md","HALLS.md","PARTICLE_PATH.md","FINAL.md","FINDINGS.md","TASKS.md","DECISIONS.md","INVENTORY.md"]
    for name in docs:
        p = HERE/name
        if not p.exists():
            broken.append(name)
            continue
        for target in re.findall(r"\[[^\]]*\]\(([^)]+)\)", p.read_text(encoding="utf-8")):
            target = target.strip("<>").split("#",1)[0]
            if (p.parent/target).resolve() == HERE/"validation.json":
                continue  # This invocation writes the linked report after completing the checks.
            if target and not re.match(r"^[A-Za-z]+://",target) and not (p.parent/target).resolve().exists():
                broken.append(f"{name}: {target}")
    check("Authored local links resolve", not broken, broken)
    spec = (HERE/"SPEC.md").read_text(encoding="utf-8")
    check("to-spec sections present", all("## "+h in spec for h in ["Problem Statement","Solution","User Stories","Implementation Decisions","Testing Decisions","Out of Scope","Further Notes"]))
    source = Path("C:/Users/palle/.codex/attachments/809c158d-9fa4-413e-b307-0c60434ce852/Pasted text.txt")
    check("User text preserved byte for byte", source.read_bytes()==(HERE/"SOURCE.md").read_bytes())
    stale = [p for p,h in inventory["source_sha256"].items() if not (ROOT/p).exists() or hashlib.sha256((ROOT/p).read_bytes()).hexdigest()!=h]
    errors = [c["check"] for c in checks if not c["pass"]]
    report = {"date":"2026-10-14","scope":"Static specification/reference validation only","passed":len(checks)-len(errors),
              "total":len(checks),"errors":errors,"checks":checks,"stale_source_receipts":stale,
              "runtime":"not run","physical_VR":"not tested","independent_learner":"not tested"}
    (HERE/"validation.json").write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({k:report[k] for k in ["scope","passed","total","errors","stale_source_receipts"]},ensure_ascii=False))
    if errors:
        raise SystemExit(1)


if __name__=="__main__":
    main()
