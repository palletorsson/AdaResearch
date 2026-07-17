"""biome_compile_in.py — biome-4: the sequence's smeared biome default becomes
explicit, inspectable layers.biome rows (doc/plans/biome_grid_redesign.md step 5).

What was a render-time side effect (BiomeAccrualManager populators scattering
trees / moss / creatures from soft_stages.json) is compiled into the map file
as declared cells in the P-8 grammar. A compiled map owns its organisms: the
flagged accrual populators (ca_surface / lsystem_trees / dna_creatures) stand
down (skip on declared seeds) and the grid-native dispatcher path renders the
rows instead — same substrates, same honesty guard, now versioned as data.

  python tools/biome_compile_in.py --map LSystems_Growth            # dry-run report
  python tools/biome_compile_in.py --map LSystems_Growth --apply    # sibling <Map>_BiomeCompiled
  python tools/biome_compile_in.py --map LSystems_Growth --apply --in-place

Sibling-first (like everything). Deterministic: seeded by map name. Barren
sequences (density < 0.05) compile to nothing and the map is left untouched.
The sibling also pins settings.biome_overrides.stage_order to its sequence's
order so the remaining accrual layers render at the right stage even though
the sibling itself is not a sequence member.
"""
import argparse
import copy
import glob
import hashlib
import json
import os
import random

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
SOFT_STAGES = os.path.join(MAPS_DIR, "soft_stages.json")
SEQ_DIR = os.path.join(MAPS_DIR, "sequences")

# soft_stages kingdom -> grammar (kingdom, algo). Mirrors
# BiomeGridTokens.dispatch_kingdom_of in reverse.
KINGDOM_GRAMMAR = {
    "tree": ("flora", "lsystem"),
    "flower": ("flora", "scatter"),
    "fungus": ("fungus", "ca"),
    "creature": ("fauna", "dna"),
}
# Interior seeds per kingdom = interior_free_cells * SEED_RATE * density,
# clamped — stated heuristic sized to the accrual layers' old counts
# (lsystem_trees spawn_density 0.08, dna_creatures 8..20 on big maps).
SEED_RATE = 0.05
SEED_CAP = 8


def find_sequence(map_name):
    for path in glob.glob(os.path.join(SEQ_DIR, "*.json")):
        data = json.load(open(path, encoding="utf-8"))
        for seq_id, seq in data.get("sequences", {}).items():
            if map_name in seq.get("maps", []):
                return seq_id
    return None


def stage_of(seq_id):
    stages = json.load(open(SOFT_STAGES, encoding="utf-8"))["stages"]
    s = stages.get(seq_id)
    if not s:
        return None
    eco = s.get("ecosystem", {})
    return {
        "order": int(s.get("order", 0)),
        "density": float(eco.get("vegetation_density", 0.0)),
        "kingdoms": list(eco.get("nature_kingdoms", [])),
    }


def compile_rows(map_data, stage, seed_key):
    """Build the biome grid: halo perimeter + interior seeds + claimable fields."""
    layers = map_data["layers"]
    structure = layers["structure"]
    utilities = layers.get("utilities", [])
    interactables = layers.get("interactables", [])
    rows = len(structure)
    cols = max(len(r) for r in structure)
    density = stage["density"]
    kingdoms = [k for k in stage["kingdoms"] if k in KINGDOM_GRAMMAR]
    if density < 0.05 or not kingdoms:
        return None, "barren (density=%.2f kingdoms=%s) — nothing to compile" % (
            density, stage["kingdoms"])

    def cell_at(layer, r, c):
        if r < len(layer) and c < len(layer[r]):
            return str(layer[r][c]).strip()
        return ""

    def free(r, c):
        return (cell_at(structure, r, c) not in ("", "0")
                and cell_at(utilities, r, c) == ""
                and cell_at(interactables, r, c) == "")

    biome = [["" for _ in range(len(structure[r]))] for r in range(rows)]
    rng = random.Random(int(hashlib.sha1(seed_key.encode()).hexdigest(), 16))
    d_tok = "d=%.2g" % round(density, 2)

    # halo perimeter: the old ring, cell by cell, kingdom cycling
    halo_kingdoms = kingdoms
    n_halo = 0
    idx = 0
    for r in range(rows):
        for c in range(len(structure[r])):
            if r not in (0, rows - 1) and c not in (0, len(structure[r]) - 1):
                continue
            if cell_at(structure, r, c) in ("", "0"):
                continue  # no halo off a void edge — the dark stays dark
            gk, algo = KINGDOM_GRAMMAR[halo_kingdoms[idx % len(halo_kingdoms)]]
            biome[r][c] = "%s:%s:halo:%s" % (gk, algo, d_tok)
            idx += 1
            n_halo += 1

    # interior seeds per kingdom + claimable fields around them
    interior = [(r, c) for r in range(1, rows - 1)
                for c in range(1, len(structure[r]) - 1) if free(r, c)]
    rng.shuffle(interior)
    tier = max(1, min(5, 1 + round(density * 3)))
    taken = set()
    n_seed = n_field = 0
    per_kingdom = max(1, min(SEED_CAP, round(len(interior) * SEED_RATE * density)))
    cursor = 0
    for k in kingdoms:
        gk, algo = KINGDOM_GRAMMAR[k]
        placed = 0
        while placed < per_kingdom and cursor < len(interior):
            r, c = interior[cursor]
            cursor += 1
            if (r, c) in taken:
                continue
            biome[r][c] = "%s:%s:seed:%s:t=%d" % (gk, algo, d_tok, tier)
            taken.add((r, c))
            n_seed += 1
            placed += 1
            for dr, dc in ((0, 1), (0, -1), (1, 0), (-1, 0)):
                nr, nc = r + dr, c + dc
                if (nr, nc) in taken or not (0 < nr < rows - 1):
                    continue
                if not (0 < nc < len(structure[nr]) - 1) or not free(nr, nc):
                    continue
                biome[nr][nc] = "%s:%s:field" % (gk, algo)
                taken.add((nr, nc))
                n_field += 1
    report = "%d halo, %d seeds (%d kingdoms x %d), %d fields, tier %d, %s" % (
        n_halo, n_seed, len(kingdoms), per_kingdom, n_field, tier, d_tok)
    return biome, report


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", required=True)
    ap.add_argument("--apply", action="store_true", help="write the result (default: dry-run)")
    ap.add_argument("--in-place", action="store_true", help="write into the map itself, not a sibling")
    args = ap.parse_args()

    src = os.path.join(MAPS_DIR, args.map, "map_data.json")
    if not os.path.isfile(src):
        raise SystemExit("no such map: %s" % args.map)
    map_data = json.load(open(src, encoding="utf-8"))
    if map_data.get("layers", {}).get("biome"):
        raise SystemExit("%s already declares layers.biome — compile-in only fills the absent default" % args.map)

    seq_id = find_sequence(args.map)
    if not seq_id:
        raise SystemExit("%s is in no sequence — no accrual default to compile" % args.map)
    stage = stage_of(seq_id)
    if not stage:
        raise SystemExit("sequence %s has no soft_stages entry" % seq_id)
    print("%s  seq=%s order=%d density=%.2f kingdoms=%s" % (
        args.map, seq_id, stage["order"], stage["density"], stage["kingdoms"]))

    biome, report = compile_rows(map_data, stage, args.map)
    print("compiled: %s" % report)
    if biome is None or not args.apply:
        if biome is not None:
            print("(dry-run — pass --apply to write)")
        return

    out = copy.deepcopy(map_data)
    out["layers"]["biome"] = biome
    doc = out.setdefault("documentation", {})
    doc["biome_compiled"] = (
        "biome-4: sequence '%s' accrual default (density %.2f) compiled into explicit "
        "layers.biome rows by tools/biome_compile_in.py — the flagged accrual populators "
        "stand down; the dispatcher renders these cells instead" % (seq_id, stage["density"]))
    if args.in_place:
        dst_dir, name = os.path.join(MAPS_DIR, args.map), args.map
    else:
        name = args.map + "_BiomeCompiled"
        dst_dir = os.path.join(MAPS_DIR, name)
        os.makedirs(dst_dir, exist_ok=True)
        out.setdefault("map_info", {})["lookup_name"] = name
        out["map_info"]["name"] = name
        # pin the remaining accrual layers to the sequence's stage — the
        # sibling is not a sequence member so the ecosystem sync can't find it
        overrides = out.setdefault("settings", {}).setdefault("biome_overrides", {})
        overrides["stage_order"] = stage["order"]
    with open(os.path.join(dst_dir, "map_data.json"), "w", encoding="utf-8") as f:
        json.dump(out, f, indent=1)
    print("wrote %s" % os.path.join(dst_dir, "map_data.json"))


if __name__ == "__main__":
    main()
