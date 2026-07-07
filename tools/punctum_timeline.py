"""tools/punctum_timeline.py — find the punctum across the curriculum spine.

A "punctum" (after Barthes) is a piercing moment: where something arrives or
changes character. The curriculum has many such moments encoded as data:

  - first nature kingdom unlocking (flower, creature, mushroom, …)
  - vegetation density jumps
  - terrain mode shifts (flat → undulating → fractal …)
  - capability rising (capacity_level, new hand_verbs)
  - hazard types unlocking
  - foe → wary → curious → friend personality transitions
  - catalyst modes

Each of these surfaces as a punctum: a specific spine position where the
character of the curriculum changes.

This tool reads:
  - commons/maps/curriculum_spine.json  (canonical spine order)
  - commons/maps/soft_stages.json       (per-sequence ecology/hazards/capability)

…and produces a horizontal timeline at doc/placement_research/punctum.json
listing every detected inflection.

Run:
  python tools/punctum_timeline.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
SPINE_PATH = ROOT / "commons" / "maps" / "curriculum_spine.json"
STAGES_PATH = ROOT / "commons" / "maps" / "soft_stages.json"
OUT = ROOT / "doc" / "placement_research" / "punctum.json"


def load_spine() -> list[str]:
    d = json.loads(SPINE_PATH.read_text(encoding="utf-8"))
    return [s.get("name", "") for s in d.get("spine", {}).get("sequences", [])]


def load_stages() -> dict:
    d = json.loads(STAGES_PATH.read_text(encoding="utf-8"))
    return d.get("stages", {})


def compute_creature_arcs(spine: list[str], stages: dict) -> dict:
    """For each creature DNA introduced as a hazard, compute its 5-stage arc
    across the spine: at every spine position, what state is the creature in?

    Returns:
      { creature_name: {
          first_appearance: int,
          transitions: [{pos, from, to}, ...],
          state_at_pos: ["absent", "foe", "foe", "wary", ...],   # length = len(spine)
          final_state: str,
      }}
    """
    creatures: dict[str, dict] = {}

    for pos, seq_id in enumerate(spine):
        stage = stages.get(seq_id, {})
        haz = stage.get("hazards", {})
        # 1. First appearance — gets state "foe"
        for h in haz.get("unlock_types", []) or []:
            if h not in creatures:
                creatures[h] = {
                    "first_appearance": pos,
                    "transitions": [{"pos": pos, "from": None, "to": "foe"}],
                    "state_at_pos": ["absent"] * len(spine),
                    "final_state": "foe",
                }
                creatures[h]["state_at_pos"][pos] = "foe"
        # 2. Personality transitions
        for foe, new_state in (haz.get("personality_shift") or {}).items():
            if foe not in creatures:
                # Edge case: a personality shift fires before a hazard unlock; treat as introduction.
                creatures[foe] = {
                    "first_appearance": pos,
                    "transitions": [{"pos": pos, "from": None, "to": "foe"}],
                    "state_at_pos": ["absent"] * len(spine),
                    "final_state": "foe",
                }
                creatures[foe]["state_at_pos"][pos] = "foe"
            old = creatures[foe]["final_state"]
            if new_state != old:
                creatures[foe]["transitions"].append({
                    "pos": pos, "from": old, "to": new_state
                })
                creatures[foe]["final_state"] = new_state
            creatures[foe]["state_at_pos"][pos] = new_state

    # Propagate state forward: each creature stays in its last known state
    # at every later spine position (until/unless transitioned again)
    for name, c in creatures.items():
        cur = "absent"
        for i in range(len(spine)):
            if c["state_at_pos"][i] != "absent":
                cur = c["state_at_pos"][i]
            elif cur != "absent":
                c["state_at_pos"][i] = cur

    return creatures


def find_punctum(spine: list[str], stages: dict) -> dict:
    """Walk the spine and detect inflection points."""
    punctum: dict[str, list[dict]] = {
        "biome_kingdom_first":      [],  # first appearance of each kingdom
        "vegetation_density_jumps": [],  # density step changes
        "terrain_shifts":           [],  # terrain mode changes
        "ambient_shifts":           [],  # ambient preset changes
        "capacity_jumps":           [],  # capacity_level changes
        "verbs_added":              [],  # new hand_verb unlocked
        "hazard_unlocks":           [],  # each hazard type's first unlock
        "personality_shifts":       [],  # foe → wary/curious/friend
        "catalyst_mode_shifts":     [],  # catalyst_mode changes
        "spawner_behavior_shifts":  [],  # dormant → active → swarming
    }

    seen_kingdoms: set[str] = set()
    seen_hazards: set[str] = set()
    seen_verbs: set[str] = set()
    last_density = 0.0
    last_terrain = None
    last_ambient = None
    last_capacity = 0
    last_catalyst = None
    last_spawner = None
    foe_personalities: dict[str, str] = {}

    for pos, seq_id in enumerate(spine):
        stage = stages.get(seq_id)
        if not stage:
            continue
        eco = stage.get("ecosystem", {})
        haz = stage.get("hazards", {})
        cap = stage.get("capability", {})

        # 1. New kingdoms
        for k in eco.get("nature_kingdoms", []) or []:
            if k not in seen_kingdoms:
                seen_kingdoms.add(k)
                punctum["biome_kingdom_first"].append({
                    "spine_pos": pos, "sequence": seq_id, "kingdom": k,
                })

        # 2. Vegetation density jumps
        density = float(eco.get("vegetation_density", 0.0))
        if pos > 0 and abs(density - last_density) >= 0.1:
            punctum["vegetation_density_jumps"].append({
                "spine_pos": pos, "sequence": seq_id,
                "from": round(last_density, 2), "to": round(density, 2),
            })
        last_density = density

        # 3. Terrain shifts
        terrain = eco.get("terrain_mode")
        if terrain and terrain != last_terrain:
            punctum["terrain_shifts"].append({
                "spine_pos": pos, "sequence": seq_id,
                "from": last_terrain, "to": terrain,
            })
            last_terrain = terrain

        # 4. Ambient preset shifts
        ambient = eco.get("ambient_preset")
        if ambient and ambient != last_ambient:
            punctum["ambient_shifts"].append({
                "spine_pos": pos, "sequence": seq_id,
                "from": last_ambient, "to": ambient,
            })
            last_ambient = ambient

        # 5. Capacity_level jumps
        capacity = int(cap.get("capacity_level", 0))
        if capacity > last_capacity:
            punctum["capacity_jumps"].append({
                "spine_pos": pos, "sequence": seq_id,
                "from": last_capacity, "to": capacity,
            })
            last_capacity = capacity

        # 6. New hand verbs
        for v in cap.get("hand_verbs", []) or []:
            if v not in seen_verbs:
                seen_verbs.add(v)
                punctum["verbs_added"].append({
                    "spine_pos": pos, "sequence": seq_id, "verb": v,
                })

        # 7. New hazard types
        for h in haz.get("unlock_types", []) or []:
            if h not in seen_hazards:
                seen_hazards.add(h)
                punctum["hazard_unlocks"].append({
                    "spine_pos": pos, "sequence": seq_id, "hazard": h,
                })

        # 8. Personality shifts (foe → wary → curious → friend)
        for foe, new_state in (haz.get("personality_shift") or {}).items():
            old_state = foe_personalities.get(foe, "foe")
            if new_state != old_state:
                punctum["personality_shifts"].append({
                    "spine_pos": pos, "sequence": seq_id,
                    "foe": foe, "from": old_state, "to": new_state,
                })
                foe_personalities[foe] = new_state

        # 9. Catalyst mode shifts
        catalyst_mode = cap.get("catalyst_mode")
        if catalyst_mode and catalyst_mode != last_catalyst:
            punctum["catalyst_mode_shifts"].append({
                "spine_pos": pos, "sequence": seq_id,
                "from": last_catalyst, "to": catalyst_mode,
            })
            last_catalyst = catalyst_mode

        # 10. Spawner behavior shifts
        spawner = haz.get("spawner_behavior")
        if spawner and spawner != last_spawner:
            punctum["spawner_behavior_shifts"].append({
                "spine_pos": pos, "sequence": seq_id,
                "from": last_spawner, "to": spawner,
            })
            last_spawner = spawner

    return punctum


def print_report(spine: list[str], punctum: dict) -> None:
    """Human-readable report — every punctum in chronological order."""
    # Flatten all into a single chronological stream
    events = []
    for kind, entries in punctum.items():
        for e in entries:
            events.append((e["spine_pos"], kind, e))
    events.sort(key=lambda x: x[0])

    print(f"PUNCTUM TIMELINE — {len(events)} inflection points across {len(spine)} spine sequences\n")

    last_pos = -1
    for pos, kind, e in events:
        if pos != last_pos:
            print(f"  ──── [{pos:2d}] {e['sequence']} ────")
            last_pos = pos
        if kind == "biome_kingdom_first":
            print(f"        BIOME UNLOCK   kingdom: {e['kingdom']}")
        elif kind == "vegetation_density_jumps":
            print(f"        DENSITY        {e['from']} → {e['to']}")
        elif kind == "terrain_shifts":
            print(f"        TERRAIN        {e['from']} → {e['to']}")
        elif kind == "ambient_shifts":
            print(f"        AMBIENT        {e['from']} → {e['to']}")
        elif kind == "capacity_jumps":
            print(f"        CAPACITY       L{e['from']} → L{e['to']}")
        elif kind == "verbs_added":
            print(f"        VERB           +{e['verb']}")
        elif kind == "hazard_unlocks":
            print(f"        HAZARD UNLOCK  {e['hazard']}")
        elif kind == "personality_shifts":
            print(f"        PERSONALITY    {e['foe']}: {e['from']} → {e['to']}")
        elif kind == "catalyst_mode_shifts":
            print(f"        CATALYST       {e['from']} → {e['to']}")
        elif kind == "spawner_behavior_shifts":
            print(f"        SPAWNER        {e['from']} → {e['to']}")

    print()
    print("counts by kind:")
    for k, v in punctum.items():
        print(f"  {k:30} {len(v):3d}")


def main():
    spine = load_spine()
    stages = load_stages()
    punctum = find_punctum(spine, stages)
    creatures = compute_creature_arcs(spine, stages)

    print_report(spine, punctum)

    # Creature roster summary
    print(f"\nCREATURE EVOLUTION ROSTER ({len(creatures)} unique genomes):")
    for name, c in sorted(creatures.items(), key=lambda kv: kv[1]["first_appearance"]):
        print(f"  [{c['first_appearance']:2d}] {name:<25}  appears={c['first_appearance']}  "
              f"transitions={len(c['transitions'])}  final={c['final_state']}")

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps({
        "spine":     spine,
        "punctum":   punctum,
        "creatures": creatures,
    }, indent=2), encoding="utf-8")
    print(f"\nwrote {OUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
