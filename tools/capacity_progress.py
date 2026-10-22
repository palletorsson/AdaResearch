#!/usr/bin/env python3
"""Measure the capacity work from the files that carry it. Never edit curriculum or prose.

The capacity tree (localhost:3003/capacity-tree) draws one picture over five data
layers that were written on different days with different words for "done":

    layer                      file                                             words for done
    capability ladder          doc/book/tutorial-lineage/curriculum.json         proposed | desktop-tested | implemented_unverified_learner
    hall cards / lineage       doc/book/course/hall-cards/lineage-*.json         aligned | needs_revision | missing
    saved author focus         doc/book/course/hall-cards/state.json             (present = chosen)
    execution plan             doc/book/course/execution-plan/plan.json          draft | accepted | revise | deferred; checks empty or not
    project memory             doc/book/memory/state.json (+ history/)           proposed | accepted | dismissed
    native evidence            doc/book/iterations/*/verification.json           ghost_states[].evidence == current

This tool reads all of them against the LIVE spine and writes one record per hall
with every flag kept separate, plus a single evidence rung that is the HIGHEST rung
any file supports:

    none        no tutorial.md
    written     tutorial.md exists; lineage says the focus still needs revision
    focused     lineage says aligned, or the author saved a focus on the card
    contracted  plan.json lesson carries a non-empty behaviour-check list
    runs        a current native ghost state exists for the hall
    learner     observed learner work (no file records this yet; always 0)

The rung is a floor, not a grade. A hall can be `runs` with an empty contract; the
raw flags say so. No percentage is printed: the ladder is not additive.

Drift is reported, not resolved: halls in the live spine that no data layer knows,
halls the data knows that the spine no longer carries, tutorials whose bytes changed
since the lineage read them, and authoritative files the docs name that are absent
from this checkout (they live on one machine only).

Usage:
    python tools/capacity_progress.py                 # write doc/reports/capacity_progress.json, print summary
    python tools/capacity_progress.py --markdown      # also print the per-sequence table
    python tools/capacity_progress.py --check         # exit 1 on drift or missing authoritative files
    python tools/capacity_progress.py --seq=forces    # one sequence, per hall
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "doc" / "reports" / "capacity_progress.json"

SPINE = "commons/maps/curriculum_spine.json"
CURRICULUM = "doc/book/tutorial-lineage/curriculum.json"
LINEAGE = ["doc/book/course/hall-cards/lineage-opening.json",
           "doc/book/course/hall-cards/lineage-middle.json",
           "doc/book/course/hall-cards/lineage-later.json"]
CARDS_STATE = "doc/book/course/hall-cards/state.json"
PLAN = "doc/book/course/execution-plan/plan.json"
PLAN_VALIDATION = "doc/book/course/execution-plan/validation.json"
PROTECTED = "doc/book/course/execution-plan/protected-sources.json"
AUTHORIZED = "doc/book/course/execution-plan/authorized-revisions.json"
MEMORY_STATE = "doc/book/memory/state.json"
MEMORY_HISTORY = "doc/book/memory/history"
STUDIES = "doc/book/recent-studies.json"
STORYBOARDS = ["doc/book/course/storyboards/preparation.json", "doc/book/course/storyboards/opening.json",
               "doc/book/course/storyboards/early.json", "doc/book/course/storyboards/growth.json",
               "doc/book/course/storyboards/later.json"]
#: Files the course docs name as authoritative. Absent here means they were never committed.
AUTHORITATIVE = [PLAN, MEMORY_STATE, CARDS_STATE, CURRICULUM] + STORYBOARDS + LINEAGE
#: The one machine-readable index of native lesson evidence (ghost states), 6 October 2026.
GHOST_EVIDENCE = "doc/book/iterations/2026-10-06-trace-saved-to-grid/verification.json"
#: ghost-state ids are slugs of the lesson, not always of the hall.
GHOST_ALIASES = {"point-grid": "Point_Line_Grid"}

RUNGS = ["none", "written", "focused", "contracted", "runs", "learner"]


def read(rel: str, default=None):
    p = ROOT / rel
    if not p.exists():
        return default
    return json.loads(p.read_text(encoding="utf-8-sig"))


def sha(p: Path) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()


def fingerprint_match(p: Path, wanted: set[str]) -> str:
    """Which byte variant of the file matches a recorded hash: raw, crlf, lf or none.

    The lineage, plan and memory records were fingerprinted on a Windows checkout
    (CRLF); this clone is LF. Measured 2026-10-19: 103 of 197 lineage records match
    only after LF -> CRLF. A raw comparison therefore reports drift that is not there.
    """
    raw = p.read_bytes()
    lf = raw.replace(b"\r\n", b"\n")
    crlf = lf.replace(b"\n", b"\r\n")
    for label, data in (("raw", raw), ("crlf", crlf), ("lf", lf)):
        if hashlib.sha256(data).hexdigest() in wanted:
            return label
    return "none"


def live_spine() -> list[dict]:
    seqs = sorted(read(SPINE)["spine"]["sequences"], key=lambda s: s["order"])
    out = []
    for s in seqs:
        data = read(f"commons/maps/sequences/{s['name']}.json")["sequences"][s["name"]]
        out.append({"id": s["name"], "order": s["order"], "title": data.get("name", s["name"]), "maps": data["maps"]})
    return out


def latest_memory() -> tuple[dict | None, str | None]:
    state = read(MEMORY_STATE)
    if state is not None:
        return state, MEMORY_STATE
    hist = sorted((ROOT / MEMORY_HISTORY).glob("*.json")) if (ROOT / MEMORY_HISTORY).exists() else []
    if not hist:
        return None, None
    return json.loads(hist[-1].read_text(encoding="utf-8-sig")), hist[-1].relative_to(ROOT).as_posix()


def ghost_states() -> dict[str, dict]:
    data = read(GHOST_EVIDENCE, {})
    out = {}
    for g in data.get("ghost_states", []):
        slug = g["id"]
        name = GHOST_ALIASES.get(slug) or "_".join(part.capitalize() for part in slug.split("-"))
        out[name] = {"id": slug, "evidence": g.get("evidence"), "checks": g.get("checks")}
    return out


def build() -> dict:
    seqs = live_spine()
    live = [m for s in seqs for m in s["maps"]]
    live_set = set(live)

    curriculum = read(CURRICULUM, {"nodes": [], "issues": [], "priority": []})
    node_by_hall: dict[str, list] = {}
    for n in curriculum["nodes"]:
        for m in n["halls"]:
            node_by_hall.setdefault(m, []).append({"id": n["id"], "status": n["status"], "kind": n["kind"]})

    lineage = {}
    for rel in LINEAGE:
        for row in (read(rel, {"halls": []}))["halls"]:
            lineage[row["map"]] = row

    cards = (read(CARDS_STATE, {}) or {}).get("cards", {})
    plan = read(PLAN)
    plan_lessons = {l["id"]: l for l in plan["lessons"]} if plan else {}
    plan_validation = read(PLAN_VALIDATION, {})
    memory, memory_source = latest_memory()
    findings_by_scope: dict[str, Counter] = {}
    if memory:
        for f in memory.get("findings", []):
            findings_by_scope.setdefault(f["scope"], Counter())[f["status"]] += 1
    studies = read(STUDIES, {"studies": []})["studies"]
    studies_by_map: dict[str, list] = {}
    for st in studies:
        studies_by_map.setdefault(st["map"], []).append(st["id"])
    ghosts = ghost_states()

    halls = []
    for s in seqs:
        for index, m in enumerate(s["maps"], 1):
            tutorial = ROOT / "commons" / "maps" / m / "tutorial.md"
            row = lineage.get(m)
            match = None
            if row and tutorial.exists() and row.get("tutorial_sha256_after"):
                match = fingerprint_match(tutorial, {row["tutorial_sha256_after"]})
            drifted = match == "none"
            lesson = plan_lessons.get(m)
            contracted = None if plan is None else bool(lesson and lesson.get("checks"))
            ghost = ghosts.get(m)
            runs = bool(ghost and ghost.get("evidence") == "current")
            lineage_status = row["status"] if row else None
            focused = lineage_status == "aligned" or m in cards
            if not tutorial.exists():
                rung = "none"
            elif runs:
                rung = "runs"
            elif contracted:
                rung = "contracted"
            elif focused:
                rung = "focused"
            else:
                rung = "written"
            halls.append({
                "map": m, "sequence": s["id"], "index": index,
                "tutorial_present": tutorial.exists(),
                "lineage_status": lineage_status,
                "lineage_drifted": drifted,
                "lineage_fingerprint": match,
                "saved_focus": m in cards,
                "plan_choice": (lesson or {}).get("status") if lesson else None,
                "contracted": contracted,
                "ghost_state": ghost,
                "curriculum_nodes": node_by_hall.get(m, []),
                "installed_studies": studies_by_map.get(m, []),
                "memory_findings": dict(findings_by_scope.get(f"map:{m}", {})),
                "rung": rung,
            })

    by_hall = {h["map"]: h for h in halls}
    sequences = []
    for s in seqs:
        rows = [by_hall[m] for m in s["maps"]]
        sequences.append({
            "id": s["id"], "order": s["order"], "title": s["title"], "halls": len(rows),
            "rungs": dict(Counter(r["rung"] for r in rows)),
            "lineage": dict(Counter(r["lineage_status"] or "unrecorded" for r in rows)),
            "curriculum_nodes": sum(1 for n in curriculum["nodes"] if n["sequence"] == s["id"]),
            "memory_findings": dict(findings_by_scope.get(f"sequence:{s['id']}", {})),
            "drifted_tutorials": [r["map"] for r in rows if r["lineage_drifted"]],
        })

    protected = read(PROTECTED, {})
    authorized = read(AUTHORIZED, {})
    protected_changed, protected_absent, protected_by_variant = [], [], Counter()
    for rel, expected in protected.items():
        p = ROOT / rel
        if not p.exists():
            protected_absent.append(rel)
            continue
        allowed = {expected, (authorized.get(rel) or {}).get("after")} - {None}
        variant = fingerprint_match(p, allowed)
        protected_by_variant[variant] += 1
        if variant == "none":
            protected_changed.append(rel)

    drift = {
        "live_not_in_lineage": sorted(live_set - set(lineage)),
        "lineage_not_live": sorted(set(lineage) - live_set),
        "live_not_in_curriculum": sorted(live_set - set(node_by_hall)),
        "curriculum_not_live": sorted(set(node_by_hall) - live_set),
        "tutorial_changed_since_lineage": [h["map"] for h in halls if h["lineage_drifted"]],
        "lineage_fingerprint_variants": dict(Counter(h["lineage_fingerprint"] for h in halls if h["lineage_fingerprint"])),
        "protected_sources_changed": protected_changed,
        "protected_sources_absent": protected_absent,
        "protected_fingerprint_variants": dict(protected_by_variant),
        "plan_validation_errors_as_recorded": plan_validation.get("errors", []),
    }
    missing_authoritative = [rel for rel in AUTHORITATIVE if not (ROOT / rel).exists()]

    return {
        "scope": "Evidence flags per hall, read from the files in this checkout against the live spine. "
                 "A rung is the highest rung any file supports; it is not a grade, not a percentage and "
                 "not a learner result. `learner` has no recording file yet and is always 0.",
        "rungs": RUNGS,
        "live": {"sequences": len(seqs), "halls": len(live)},
        "totals": {
            "rungs": dict(Counter(h["rung"] for h in halls)),
            "lineage": dict(Counter(h["lineage_status"] or "unrecorded" for h in halls)),
            "curriculum_nodes": dict(Counter(n["status"] for n in curriculum["nodes"])),
            "curriculum_issues": dict(Counter(i["severity"] for i in curriculum.get("issues", []))),
            "saved_focus": len(cards),
            "plan": {"present": plan is not None,
                     "concrete_contracts": plan_validation.get("concrete_contracts"),
                     "unresolved_contracts": plan_validation.get("unresolved_contracts")},
            "memory": {"source": memory_source, "revision": (memory or {}).get("revision"),
                       "updated_at": (memory or {}).get("updated_at"),
                       "findings": dict(Counter(f["status"] for f in (memory or {}).get("findings", [])))},
            "installed_studies": len(studies),
            "ghost_states_current": sum(1 for g in ghosts.values() if g.get("evidence") == "current"),
        },
        "drift": drift,
        "missing_authoritative_files": missing_authoritative,
        "sequences": sequences,
        "halls": halls,
    }


def markdown(report: dict, only: str = "") -> str:
    lines = []
    if only:
        seq = next((s for s in report["sequences"] if s["id"] == only), None)
        if not seq:
            return f"unknown sequence {only}"
        lines.append(f"| hall | rung | lineage | focus saved | contract | ghost | nodes | studies |")
        lines.append("|---|---|---|---|---|---|---|---|")
        for h in report["halls"]:
            if h["sequence"] != only:
                continue
            contract = {None: "plan.json absent", True: "yes", False: "no"}[h["contracted"]]
            ghost = f"{h['ghost_state']['checks']} checks" if h["ghost_state"] else ""
            nodes = ", ".join(n["id"] for n in h["curriculum_nodes"])
            lines.append(f"| {h['map']} | {h['rung']} | {h['lineage_status'] or 'unrecorded'}"
                         f"{' (drifted)' if h['lineage_drifted'] else ''} | {'yes' if h['saved_focus'] else ''} | "
                         f"{contract} | {ghost} | {nodes} | {len(h['installed_studies']) or ''} |")
        return "\n".join(lines)
    lines.append("| # | sequence | halls | none | written | focused | contracted | runs | ladder nodes | drifted |")
    lines.append("|---|---|---|---|---|---|---|---|---|---|")
    for s in report["sequences"]:
        r = s["rungs"]
        lines.append(f"| {s['order']} | {s['id']} | {s['halls']} | {r.get('none', 0)} | {r.get('written', 0)} | "
                     f"{r.get('focused', 0)} | {r.get('contracted', 0)} | {r.get('runs', 0)} | {s['curriculum_nodes']} | "
                     f"{len(s['drifted_tutorials']) or ''} |")
    t = report["totals"]["rungs"]
    lines.append(f"| | **all** | {report['live']['halls']} | {t.get('none', 0)} | {t.get('written', 0)} | "
                 f"{t.get('focused', 0)} | {t.get('contracted', 0)} | {t.get('runs', 0)} | "
                 f"{sum(s['curriculum_nodes'] for s in report['sequences'])} | "
                 f"{len(report['drift']['tutorial_changed_since_lineage'])} |")
    return "\n".join(lines)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("--markdown", action="store_true", help="print the per-sequence table")
    ap.add_argument("--seq", default="", help="print one sequence, per hall")
    ap.add_argument("--check", action="store_true", help="exit 1 on drift or missing authoritative files")
    ap.add_argument("--no-write", action="store_true", help="do not write doc/reports/capacity_progress.json")
    args = ap.parse_args()

    report = build()
    if not args.no_write:
        OUT.parent.mkdir(parents=True, exist_ok=True)
        OUT.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    t = report["totals"]
    print(f"live spine: {report['live']['sequences']} sequences, {report['live']['halls']} halls")
    print(f"rungs: {t['rungs']}")
    print(f"lineage: {t['lineage']}   ladder nodes: {t['curriculum_nodes']}   saved focus: {t['saved_focus']}")
    print(f"plan.json present: {t['plan']['present']}   contracts (validation.json): "
          f"{t['plan']['concrete_contracts']} concrete / {t['plan']['unresolved_contracts']} unresolved")
    print(f"memory: {t['memory']['source']} rev {t['memory']['revision']} ({t['memory']['updated_at']}) "
          f"findings {t['memory']['findings']}")
    print(f"ghost states current: {t['ghost_states_current']}   installed studies: {t['installed_studies']}")
    for key, value in report["drift"].items():
        if not value:
            continue
        if isinstance(value, list) and len(value) > 12:
            print(f"drift.{key}: {len(value)} files, first {value[:6]}")
        else:
            print(f"drift.{key}: {value}")
    if report["missing_authoritative_files"]:
        print("missing authoritative files (named by the docs, absent from this checkout):")
        for rel in report["missing_authoritative_files"]:
            print(f"  - {rel}")
    if args.markdown or args.seq:
        print()
        print(markdown(report, args.seq))
    if not args.no_write:
        print(f"\nwrote {OUT.relative_to(ROOT).as_posix()}")

    if args.check:
        informational = {"lineage_fingerprint_variants", "protected_fingerprint_variants",
                         "plan_validation_errors_as_recorded"}
        bad = any(v for k, v in report["drift"].items() if k not in informational) \
            or bool(report["missing_authoritative_files"])
        return 1 if bad else 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
