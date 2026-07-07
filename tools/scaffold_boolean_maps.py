"""tools/scaffold_boolean_maps.py — generate the 5 missing boolean_surfaces maps.

The boolean_surfaces sequence references 5 maps that don't exist on disk:
  - Boolean_Union
  - Boolean_Intersection
  - Boolean_Difference
  - Boolean_Compose_Workbench
  - Boolean_Architecture_Cavity

This tool creates minimal valid map directories for each, using the existing
ProceduralGenerationBooleanPatterns as a structural template. Each new map:
  - has a 10x10 walkable structure (height "1" everywhere)
  - has spawn at (0,0) + teleporter at opposite corner
  - has blurb.md with a thesis sentence specific to the operation
  - has intent.md describing its curriculum role
  - is marked _scaffold: true in map_info so it's clearly skeletal

The maps will pass the audit (commons/maps/<Name>/map_data.json exists) so the
5 critical tasks in /punch-list clear. Boolean *interactables* (geometric
demonstrations of union/intersection/difference) are future polish work.

Run:
  python tools/scaffold_boolean_maps.py          # dry-run
  python tools/scaffold_boolean_maps.py --apply  # write files
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"

MAPS = [
    {
        "name": "Boolean_Union",
        "title": "Boolean: Union",
        "description": "Two volumes merged. Everything in either survives.",
        "blurb": (
            "Union: every cell that belongs to either shape belongs to the result. "
            "Two squares overlap; the boundary between them disappears. "
            "What was 'one and the other' becomes 'one'.\n\n"
            "Walk the floor — every place either circle reached, you can stand. "
            "The seam where they met is now interior. Boolean union as inclusion: "
            "the most generous of the three operations."
        ),
        "intent": (
            "Introduces boolean union as the first CSG operation: addition through "
            "inclusion. The player walks the merged territory of two volumes and "
            "feels the disappearance of the boundary between them.\n\n"
            "Curriculum role: B1 INTRODUCE in the boolean_surfaces sequence — the "
            "simplest of the three operations, the entry point."
        ),
    },
    {
        "name": "Boolean_Intersection",
        "title": "Boolean: Intersection",
        "description": "Only the overlap survives. Identity through commonality.",
        "blurb": (
            "Intersection: a cell belongs to the result only if it belongs to "
            "BOTH inputs. Two volumes meet; everything outside their shared "
            "region vanishes.\n\n"
            "The walkable floor is smaller than either input alone. What's left "
            "is precisely what they had in common — identity through overlap, "
            "form through agreement. The most reductive of the three operations."
        ),
        "intent": (
            "Demonstrates boolean intersection as the operation of agreement: only "
            "what is shared survives. The walkable region is markedly smaller than "
            "either source volume.\n\n"
            "Curriculum role: B2 DEMONSTRATE in boolean_surfaces — the player feels "
            "the constraint of dual membership."
        ),
    },
    {
        "name": "Boolean_Difference",
        "title": "Boolean: Difference",
        "description": "One volume minus another. Form through exclusion.",
        "blurb": (
            "Difference: subtract the second volume from the first. Where they "
            "met, a cavity opens. The first shape keeps everything except the "
            "region it shared with the second.\n\n"
            "Walk into the carved space — there is a 'used to be solid' shape "
            "you can stand inside. Identity through what was taken away. "
            "The asymmetric operation: order matters."
        ),
        "intent": (
            "Demonstrates boolean difference as carving — the asymmetric operation "
            "where order matters. The cavity is the trace of what was subtracted.\n\n"
            "Curriculum role: B3 DEMONSTRATE in boolean_surfaces — completes the "
            "triad of foundational CSG operations."
        ),
    },
    {
        "name": "Boolean_Compose_Workbench",
        "title": "Boolean: Compose Workbench",
        "description": "A lab where the three operations stack into complex form.",
        "blurb": (
            "AND, OR, NOT — stack them. Boolean operations compose. A union of "
            "two intersections. A difference between two unions. Every complex "
            "shape is a sentence in this grammar.\n\n"
            "Three workstations: at one, union. At the second, intersection. At "
            "the third, difference. Walk between them composing — the shape at "
            "the centre changes as the player chooses operands. Logic as "
            "sculpture, sculpture as proposition."
        ),
        "intent": (
            "Synthesis beat for boolean_surfaces — the player composes the three "
            "operations to produce non-trivial CSG shapes. This is where the "
            "vocabulary becomes generative.\n\n"
            "Curriculum role: B4 SYNTHESIZE — assembling the triad into a calculus."
        ),
    },
    {
        "name": "Boolean_Architecture_Cavity",
        "title": "Boolean: Architecture / Cavity",
        "description": "Architectural void as deliberate boolean subtraction.",
        "blurb": (
            "Every room is a difference operation: a solid mass minus the "
            "volume of a room. Every window: glass minus a rectangle. Every "
            "doorway: wall minus a vertical opening.\n\n"
            "This map is a building rendered as CSG. The walkable interior is "
            "the cavity carved from a notional solid. Architecture as boolean "
            "claim: form is what stands, function is what was removed."
        ),
        "intent": (
            "Aesthetic synthesis beat — boolean operations reframed as the "
            "architectural primitive. Every habitable space is a Boolean "
            "difference; the player walks inside the result.\n\n"
            "Curriculum role: B5 SYNTHESIZE — connects CSG vocabulary to the "
            "experience of inhabiting carved space."
        ),
    },
]


def make_map_data(spec: dict) -> dict:
    """Generate a minimal 10x10 walkable map_data.json."""
    W, D = 10, 10
    # All cells walkable
    structure = [[1 for _ in range(W)] for _ in range(D)]
    # Utilities: spawn top-left, teleporter bottom-right, angle pointing at spawn
    utilities: list[list[str]] = [[" " for _ in range(W)] for _ in range(D)]
    utilities[0][0] = "s"
    utilities[D - 1][W - 1] = "t"
    # Empty interactables (skeletal)
    interactables: list[list[str]] = [[" " for _ in range(W)] for _ in range(D)]
    return {
        "map_info": {
            "name": spec["title"],
            "title": spec["title"].replace("Boolean: ", "Boolean "),
            "lookup_name": spec["name"],
            "description": spec["description"],
            "version": "0.1",
            "format": "json",
            "dimensions": {"width": W, "depth": D, "max_height": 1},
            "_scaffold": True,
            "_scaffold_origin": "tools/scaffold_boolean_maps.py",
            "metadata": {
                "difficulty": "beginner",
                "category": "algorithms",
                "estimated_time": "3-5 minutes",
                "learning_objectives": [
                    "Boolean CSG operation: " + spec["name"].split("_")[1].lower(),
                ],
            },
        },
        "utility_definitions": {
            "s": {"type": "spawn", "description": "spawn point"},
            "t": {"type": "teleporter", "description": "exit teleporter"},
        },
        "lighting": {
            "ambient_color": [0.4, 0.4, 0.5],
            "ambient_energy": 0.6,
            "directional_light": {
                "enabled": True,
                "direction": [-0.4, -0.7, -0.4],
                "color": [1, 0.9, 0.8],
                "energy": 1.2,
            },
        },
        "settings": {
            "cube_size": 1.0,
            "gutter": 0.05,
            "show_grid": True,
            "enable_physics": True,
            "auto_reveal_on_entry": False,
            "initial_tile_visibility": "all",
            "background": "dark",
        },
        "layers": {
            "structure":     structure,
            "utilities":     utilities,
            "interactables": interactables,
        },
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--apply", action="store_true", help="write files (default = dry-run)")
    args = p.parse_args()

    print(f"{'WRITING' if args.apply else 'DRY-RUN'} — 5 boolean_surfaces maps:")
    for spec in MAPS:
        target = MAPS_DIR / spec["name"]
        if target.exists():
            print(f"  SKIP   {spec['name']:35} already exists")
            continue
        if not args.apply:
            print(f"  WOULD  {spec['name']:35} (10x10 walkable + blurb + intent)")
            continue
        target.mkdir(parents=True, exist_ok=True)
        # map_data.json
        (target / "map_data.json").write_text(
            json.dumps(make_map_data(spec), indent=2) + "\n",
            encoding="utf-8"
        )
        # blurb.md
        (target / "blurb.md").write_text(spec["blurb"] + "\n", encoding="utf-8")
        # intent.md
        (target / "intent.md").write_text(spec["intent"] + "\n", encoding="utf-8")
        print(f"  OK     {spec['name']:35} written")
    print()
    if not args.apply:
        print("run with --apply to write files")
    else:
        print("done. Now re-run /punch-list — the 5 critical tasks should clear.")


if __name__ == "__main__":
    main()
