"""Derive the isolated museum plan from the test map; never edit the spine."""
import json
import argparse
from pathlib import Path
from em_map_halls import derive_row

ROOT = Path(__file__).resolve().parents[1]

def main():
    # Keep the earlier connected route and the direct-entry arena independently runnable.
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--arena", action="store_true")
    mode.add_argument("--progression", action="store_true")
    args = parser.parse_args()
    map_id = "Catalyst_Test_Arena" if args.arena else "Catalyst_First_Abilities"
    basename = "catalyst_test_arena_plan.json" if args.arena else "catalyst_first_abilities_plan.json"
    if args.progression:
        map_id, basename = "Catalyst_Opening_Progression", "catalyst_opening_progression_plan.json"
    source = json.loads((ROOT / "commons/data/museum/em_plan.json").read_text(encoding="utf-8"))
    row = derive_row("opening progression" if args.progression else "test arena" if args.arena else "first abilities", map_id, "uffizi-spine-enfilade", 0, 1, "transformation")
    source = {"schema": source["schema"], "plans": [row], "museums": {"uffizi-spine-enfilade": row},
              "_readme": "Isolated catalyst playtest, using the actual museum shell. Not a curriculum change."}
    target = ROOT / "commons/testing" / basename
    target.write_text(json.dumps(source, indent=2) + "\n", encoding="utf-8")
    if args.arena:
        # The game menu/export cannot depend on the excluded commons/testing tree.
        shipped = ROOT / "commons/maps/Catalyst_Test_Arena/museum_plan.json"
        shipped.write_text(target.read_text(encoding="utf-8"), encoding="utf-8")
    print(f"Derived {row['room']['w']} x {row['h']} m test hall: {target}")

if __name__ == "__main__":
    main()
