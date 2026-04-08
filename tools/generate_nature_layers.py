"""Generate nature_layer.json for all spine maps based on soft_stages.json.

Reads sequence definitions and soft_stages to determine:
- Which kingdoms are available at each stage
- What density of flora to paint
- What terrain_mode applies

Generates nature_layer.json per map with appropriate ground types.

Run: python tools/generate_nature_layers.py
     python tools/generate_nature_layers.py --sequence forces
     python tools/generate_nature_layers.py --dry-run
"""

import json, os, random, sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEQUENCES_DIR = os.path.join(REPO_ROOT, "commons", "maps", "sequences")
MAPS_DIR = os.path.join(REPO_ROOT, "commons", "maps")
SOFT_STAGES_PATH = os.path.join(REPO_ROOT, "commons", "maps", "soft_stages.json")
SPINE_PATH = os.path.join(REPO_ROOT, "commons", "maps", "curriculum_spine.json")

# Kingdom → flora types for nature_layer
KINGDOM_FLORA = {
    "flower": ["flowers", "grass"],
    "tree": ["tree", "bush", "moss"],
    "fungus": ["mushrooms", "moss"],
    "creature": ["walker", "crawler"],
}

# Ground types for bare areas
GROUND_TYPES = ["soil", "grass", "moss", "sand", "stone"]


def load_soft_stages():
    with open(SOFT_STAGES_PATH) as f:
        return json.load(f)["stages"]


def load_spine():
    with open(SPINE_PATH) as f:
        return json.load(f)


def load_sequence(seq_id):
    path = os.path.join(SEQUENCES_DIR, f"{seq_id}.json")
    if not os.path.exists(path):
        return None
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return data.get("sequences", {}).get(seq_id, data)


def get_map_dimensions(map_name):
    """Read map_data.json to get actual dimensions."""
    md_path = os.path.join(MAPS_DIR, map_name, "map_data.json")
    if not os.path.exists(md_path):
        return 10, 10  # default
    with open(md_path, encoding="utf-8") as f:
        md = json.load(f)
    info = md.get("map_info", {})
    dims = info.get("dimensions", {})
    return int(dims.get("width", 10)), int(dims.get("depth", 10))


def get_structure_layer(map_name):
    """Read structure layer to know where floors are (avoid painting in void/walls)."""
    md_path = os.path.join(MAPS_DIR, map_name, "map_data.json")
    if not os.path.exists(md_path):
        return None
    with open(md_path, encoding="utf-8") as f:
        md = json.load(f)
    return md.get("layers", {}).get("structure", None)


def generate_nature_layer(map_name, density, kingdoms, terrain_mode, seed=None):
    """Generate a nature_layer.json for a map."""
    width, depth = get_map_dimensions(map_name)
    structure = get_structure_layer(map_name)

    if seed is None:
        seed = hash(map_name) & 0xFFFFFFFF
    rng = random.Random(seed)

    # Determine available flora types from unlocked kingdoms
    available_flora = []
    for kingdom in kingdoms:
        available_flora.extend(KINGDOM_FLORA.get(kingdom, []))
    if not available_flora:
        available_flora = ["soil"]  # Bare ground if no kingdoms

    # Build ground layer
    ground = []
    for y in range(depth):
        row = []
        for x in range(width):
            # Check if this cell has a floor (structure == "1" or similar)
            is_floor = True
            if structure:
                if y < len(structure) and x < len(structure[y]):
                    cell = str(structure[y][x]).strip()
                    is_floor = cell in ["1", "1:1", "1:2", "1:3", "1:4", "1:5"]

            if not is_floor:
                row.append({"type": "none", "intensity": 0.0})
                continue

            # Roll for flora placement
            roll = rng.random()
            if roll > density:
                # Bare ground
                ground_type = rng.choice(["soil", "soil", "grass", "none"])
                intensity = rng.uniform(0.0, 0.3) if ground_type != "none" else 0.0
                row.append({"type": ground_type, "intensity": round(intensity, 2)})
            else:
                # Place flora
                flora_type = rng.choice(available_flora)
                intensity = rng.uniform(0.3, min(density + 0.3, 1.0))

                # Edge cells get lower intensity (natural boundary)
                if x == 0 or x == width - 1 or y == 0 or y == depth - 1:
                    intensity *= 0.3

                row.append({"type": flora_type, "intensity": round(intensity, 2)})
        ground.append(row)

    return {
        "_meta": {
            "description": "Nature layer auto-generated from soft_stages.json",
            "version": "1.0",
            "generator": "generate_nature_layers.py",
            "terrain_mode": terrain_mode,
            "density": density,
            "kingdoms": kingdoms,
        },
        "map_name": map_name,
        "dimensions": {"width": width, "depth": depth},
        "layers": {
            "ground": ground,
        },
    }


def main():
    dry_run = "--dry-run" in sys.argv
    filter_seq = None
    for arg in sys.argv[1:]:
        if arg.startswith("--sequence="):
            filter_seq = arg.split("=")[1]

    stages = load_soft_stages()
    spine = load_spine()

    # Build sequence → stage mapping
    seq_stage_map = {}
    for stage_name, stage_data in stages.items():
        seq_stage_map[stage_name] = stage_data

    # Collect all spine sequence IDs
    spine_sequences = []
    if "sequences" in spine:
        for entry in spine["sequences"]:
            sid = entry.get("id", entry.get("sequence_id", ""))
            if sid:
                spine_sequences.append(sid)

    if not spine_sequences:
        # Fallback: use soft_stages keys
        spine_sequences = [k for k in stages.keys()]

    generated = 0
    skipped = 0
    already_exists = 0

    for seq_id in spine_sequences:
        if filter_seq and seq_id != filter_seq:
            continue

        stage = seq_stage_map.get(seq_id)
        if not stage:
            continue

        eco = stage.get("ecosystem", {})
        density = eco.get("vegetation_density", 0.0)
        kingdoms = eco.get("nature_kingdoms", [])
        terrain_mode = eco.get("terrain_mode", "flat")

        if density <= 0.0 and not kingdoms:
            skipped += 1
            continue

        # Load sequence to find maps
        seq_data = load_sequence(seq_id)
        if not seq_data:
            continue

        maps = seq_data.get("maps", [])
        if not maps:
            continue

        for map_name in maps:
            map_dir = os.path.join(MAPS_DIR, map_name)
            if not os.path.isdir(map_dir):
                continue

            nature_path = os.path.join(map_dir, "nature_layer.json")

            # Don't overwrite manually painted layers
            if os.path.exists(nature_path):
                # Check if it's auto-generated
                try:
                    with open(nature_path, encoding="utf-8") as f:
                        existing = json.load(f)
                    if existing.get("_meta", {}).get("generator") != "generate_nature_layers.py":
                        already_exists += 1
                        continue
                except:
                    pass

            layer = generate_nature_layer(map_name, density, kingdoms, terrain_mode)

            if dry_run:
                print(f"  [DRY RUN] {map_name}: d={density:.2f} k={kingdoms} t={terrain_mode}")
            else:
                with open(nature_path, "w") as f:
                    json.dump(layer, f, indent=2)
                print(f"  {map_name}: d={density:.2f} k={kingdoms} t={terrain_mode}")

            generated += 1

    print(f"\nGenerated: {generated} | Skipped (no nature): {skipped} | Manual (preserved): {already_exists}")


if __name__ == "__main__":
    main()
