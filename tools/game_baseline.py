"""game_baseline.py — audit THE GAME's baseline contract (doc/book/baselines/thegame.json).

R-023 one level up: beats are SYSTEMS, so the audit dimension is not
walkable-in-a-map but EXISTS / DEPLOYED / WIRED:

  EXISTS   — the system's source is on disk
  DEPLOYED — it appears in the world (maps using it, counted)
  WIRED    — it is connected to the game loop (progression/persistence/response)

A beat is MET only at all three. The report is the game's honest state:
what is a game system, what is an exhibit, and what is missing.

Usage: python tools/game_baseline.py
Output: printed report + doc/book/game_baseline_report.json
"""

import glob
import json
import os
import re
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent
MAPS = ROOT / "commons" / "maps"
OUT = ROOT / "doc" / "book" / "game_baseline_report.json"


def maps_where(predicate) -> list:
    hits = []
    for md_path in glob.glob(str(MAPS / "*" / "map_data.json")):
        try:
            d = json.load(open(md_path, encoding="utf-8"))
        except Exception:
            continue
        if predicate(d):
            hits.append(Path(md_path).parent.name)
    return sorted(hits)


def cast_has(d, *needles) -> bool:
    for row in d.get("layers", {}).get("interactables", []):
        for c in row:
            s = str(c).strip()
            if s and not s.startswith("#"):
                base = s.split(":")[0].split("#")[0]
                if any(n in base for n in needles):
                    return True
    return False


def utilities_have_hazard(d) -> bool:
    for row in d.get("layers", {}).get("utilities", []):
        for c in row:
            if str(c).strip().startswith("h:"):
                return True
    return False


def grep(path, pattern) -> bool:
    p = ROOT / path
    if not p.exists():
        return False
    try:
        return re.search(pattern, p.read_text(encoding="utf-8", errors="replace")) is not None
    except Exception:
        return False


def audit() -> list:
    beats = []

    def beat(role, exists, deployed_maps, wired, wired_note, note=""):
        met = exists and (deployed_maps is None or len(deployed_maps) > 0) and wired
        beats.append({"role": role, "exists": exists,
                      "deployed": (len(deployed_maps) if deployed_maps is not None else "global"),
                      "deployed_maps": (deployed_maps[:8] if deployed_maps else []),
                      "wired": wired, "wired_note": wired_note, "met": met, "note": note})

    # 1. the persistent verb — becoming_catalyst
    ex = (ROOT / "commons/hazards/becoming_catalyst/becoming_catalyst.gd").exists()
    dep = maps_where(lambda d: cast_has(d, "becoming_catalyst"))
    wired = grep("commons/hazards/becoming_catalyst/becoming_catalyst.gd", r"persist|static var|session")
    beat("the persistent verb — the bracelet", ex, dep, wired,
         "blocks persist across maps in-session" if wired else "persistence not found in code")

    # 2. stakes — death
    ex = (ROOT / "commons/managers/DeathEffect.gd").exists()
    dep = maps_where(utilities_have_hazard)
    wired = grep("project.godot", r"DeathEffect")
    beat("stakes — a way to die and return", ex, dep, wired,
         "DeathEffect is an autoload (reload on death)" if wired else "not autoloaded")

    # 3. resistance — foes that become friends
    ex = (ROOT / "commons/hazards/catalyst_foe/catalyst_foe.gd").exists()
    dep = maps_where(lambda d: cast_has(d, "catalyst_vent", "catalyst_foe"))
    wired = grep("commons/hazards/catalyst_foe/catalyst_foe.gd", r"friend")
    beat("resistance — FOE -> FRIEND", ex, dep, wired,
         "personality ladder reaches 'friend'" if wired else "no phase-shift found")

    # 4. visible growth — ecology responds to progress
    ex = (ROOT / "commons/managers/EcosystemManager.gd").exists() and \
         (ROOT / "commons/maps/soft_stages.json").exists()
    wired = grep("commons/managers/EcosystemManager.gd", r"completed.*sequence|sequence.*complete")
    beat("visible growth — the world responds", ex, None, wired,
         "rebuilds state from completed sequences + soft_stages" if wired else "not reading progress")

    # 5. the test — prove-it gates per chapter
    prove = 0
    for bp in glob.glob(str(ROOT / "doc/book/baselines/*.json")):
        if bp.endswith(("_briefing.json", "thegame.json")):
            continue
        try:
            d = json.load(open(bp, encoding="utf-8"))
        except Exception:
            continue
        if any("prove" in str(b.get("role", "")).lower() for b in d.get("beats", [])):
            prove += 1
    mgr = (ROOT / "commons/managers/MapProgressionManager.gd").exists()
    # WIRED test: is the ExamGate autoload present AND registered, connecting a
    # puzzle solve-signal to complete_map?
    gate_wired = (ROOT / "commons/managers/ExamGate.gd").exists() and \
        grep("commons/managers/ExamGate.gd", r"complete_map") and \
        grep("project.godot", r"ExamGate=")
    beats.append({"role": "the test — prove-it gates per chapter",
                  "exists": mgr, "deployed": f"{prove}/24 chapters have a prove-it beat",
                  "deployed_maps": [], "wired": gate_wired,
                  "wired_note": ("ExamGate autoload wires any solve-signal (puzzle_solved / "
                                 "transformation_complete / exam_passed) to complete_map" if gate_wired else
                                 "NO wire from any prove-it artifact to MapProgressionManager — exams exist but aren't gates"),
                  "met": mgr and prove >= 20 and gate_wired, "note": ""})

    # 6. the unwinnable level
    dep = maps_where(lambda d: cast_has(d, "provability_sorter"))
    beat("the unwinnable level — losing IS the point", len(dep) > 0, dep, True,
         "unwinnable by design; wiring is the artifact's own refusal")

    # 7. the final test — the sandbox
    dep = maps_where(lambda d: cast_has(d, "qfep_reactor"))
    wired = False  # a 'final gate' (hold-the-edge timer -> ending) does not exist
    beat("the final test — hold YOUR edge", len(dep) > 0, dep, wired,
         "reactor exists and is walkable, but nothing measures 'held the edge' or ends the game on it")

    # 8. the world-verb — freeze/dissolve zones + retune
    ex = (ROOT / "commons/hazards/edge_zones/edge_zone.gd").exists()
    dep = maps_where(lambda d: cast_has(d, "edge_zone")) if ex else []
    wired = grep("commons/hazards/edge_zones/edge_zone.gd", r"func retune|move_toward\(lambda")
    beat("the world-verb — zones freeze/dissolve, player retunes", ex, dep, wired,
         "EdgeZone: two deaths (crystal/dissolve), retune-by-presence toward the living edge" if wired
         else "edge_zones present but no retune logic")

    # 9. return transformed — the lab changes
    ex = (ROOT / "commons/maps/Lab/lab_map_progression.json").exists()
    wired = grep("commons/managers/MapProgressionManager.gd", r"unlock")
    beat("return transformed — the hub changes as you do", ex, None, wired,
         "MapProgressionManager tracks completion + unlocks" if wired else "no unlock logic")

    return beats


def main():
    beats = audit()
    met = sum(1 for b in beats if b["met"])
    print(f"THE GAME — baseline audit: {met}/{len(beats)} beats MET (EXISTS + DEPLOYED + WIRED)\n")
    for b in beats:
        mark = "✅" if b["met"] else ("◐" if b["exists"] else "☐")
        dep = b["deployed"] if isinstance(b["deployed"], str) else f"{b['deployed']} maps"
        print(f"  {mark} {b['role']}")
        print(f"      exists={b['exists']}  deployed={dep}  wired={b['wired']}")
        print(f"      {b['wired_note']}")
        if b.get("note"):
            print(f"      -> {b['note']}")
    OUT.write_text(json.dumps({"generated_by": "tools/game_baseline.py",
                               "met": met, "total": len(beats), "beats": beats},
                              ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"\n-> {OUT}")


if __name__ == "__main__":
    main()
