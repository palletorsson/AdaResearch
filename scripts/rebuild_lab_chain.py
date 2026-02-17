"""
Rebuild Lab progression chain.
Each stage = previous stage + new additions. Never subtract content.
Smart teleporter handling: each stage's existing map is authoritative
for WHERE a teleporter sits. If a teleporter destination appears in
the current stage's map, use that position (clearing old positions for
that destination).
"""
import json, re, os, copy, shutil
from datetime import datetime

LAB_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "commons", "maps", "Lab")

def load_map(filename):
    path = os.path.join(LAB_DIR, filename)
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    text = re.sub(r',(\s*[}\]])', r'\1', text)
    return json.loads(text)

def parse_grid(layer_rows):
    grid = {}
    if not layer_rows:
        return grid
    for r, row in enumerate(layer_rows):
        cells = row if isinstance(row, list) else row.split(",")
        for c, cell in enumerate(cells):
            val = cell.strip() if isinstance(cell, str) else str(cell)
            if val and val != "0" and val != "":
                grid[(r, c)] = val
    return grid

def grid_dims(layer_rows):
    if not layer_rows:
        return (0, 0)
    rows = len(layer_rows)
    cols = max(len(row) if isinstance(row, list) else len(row.split(",")) for row in layer_rows)
    return (rows, cols)

def grid_to_layers(grid, rows, cols, empty=" "):
    result = []
    for r in range(rows):
        row = []
        for c in range(cols):
            row.append(grid.get((r, c), empty))
        result.append(row)
    return result

def fix_utility(val):
    """Fix m:t:something:0.1 -> m:0.1"""
    if not val:
        return val
    match = re.match(r'^m:t:[^:]+:([0-9.]+)$', val)
    if match:
        return f"m:{match.group(1)}"
    return val

def get_tp_dest(val):
    """Extract teleporter destination: t:foo -> foo, t:foo:1:2:3 -> foo"""
    if not val or not isinstance(val, str) or not val.startswith("t:"):
        return None
    parts = val.split(":")
    return parts[1] if len(parts) >= 2 else None

def is_teleporter(val):
    return get_tp_dest(val) is not None

# ============================================================
CHAIN = [
    ("initial",           "map_data.json"),
    ("primitives",        "map_data_post_primitives.json"),
    ("transformation",    "map_data_post_transformation.json"),
    ("color",             "map_data_post_color.json"),
    ("wavefunctions",     "map_data_post_wavefunctions.json"),
    ("forces",            "map_data_post_forces.json"),
    ("noise",             "map_data_post_noise.json"),
    ("cellularautomata",  "map_data_post_cellularautomata.json"),
    ("fractals",          "map_data_post_fractals.json"),
    ("softbodies",        "map_data_post_softbodies.json"),
    ("morphogenesis",     "map_data_post_morphogenesis.json"),
    ("machinelearning",   "map_data_post_machinelearning.json"),
    ("foundationscrisis", "map_data_post_foundationscrisis.json"),
    ("qfeplaboratory",    "map_data_post_qfeplaboratory.json"),
]


def main():
    # ---- Backup ----
    backup_dir = os.path.join(LAB_DIR, f"backup_{datetime.now().strftime('%Y-%m-%d_%H%M')}")
    os.makedirs(backup_dir, exist_ok=True)
    for _, fname in CHAIN:
        src = os.path.join(LAB_DIR, fname)
        if os.path.exists(src):
            shutil.copy2(src, os.path.join(backup_dir, fname))
    print(f"Backed up to {backup_dir}")

    # ---- Load ORIGINAL maps (from the FIRST backup, not the rebuilt ones) ----
    # Find the first backup dir
    backup_dirs = sorted([d for d in os.listdir(LAB_DIR) if d.startswith("backup_")])
    original_dir = os.path.join(LAB_DIR, backup_dirs[0]) if backup_dirs else LAB_DIR
    print(f"Using originals from: {original_dir}")

    originals = {}
    for name, fname in CHAIN:
        # For the base map, always read from LAB_DIR
        if name == "initial":
            path = os.path.join(LAB_DIR, fname)
        else:
            path = os.path.join(original_dir, fname)
            if not os.path.exists(path):
                path = os.path.join(LAB_DIR, fname)
        
        if not os.path.exists(path):
            originals[name] = None
            continue
        
        with open(path, "r", encoding="utf-8") as f:
            text = f.read()
        text = re.sub(r',(\s*[}\]])', r'\1', text)
        data = json.loads(text)
        layers = data.get("layers", {})
        originals[name] = {
            "data": data,
            "structure": parse_grid(layers.get("structure", [])),
            "utilities": parse_grid(layers.get("utilities", [])),
            "interactables": parse_grid(layers.get("interactables", [])),
            "dims": grid_dims(layers.get("structure", [])),
        }

    # ---- Build chain ----
    base = originals["initial"]
    if base is None:
        print("ERROR: Base map not found!")
        return

    acc_structure = dict(base["structure"])
    acc_utilities = dict(base["utilities"])
    acc_interactables = dict(base["interactables"])
    acc_rows, acc_cols = base["dims"]

    print(f"\nBase: {acc_rows}x{acc_cols}")

    results = []

    for i in range(1, len(CHAIN)):
        name, fname = CHAIN[i]
        orig = originals[name]
        
        if orig is None:
            print(f"\nWARNING: {fname} not found, skipping")
            continue

        curr_struct = orig["structure"]
        curr_utils = orig["utilities"]
        curr_inter = orig["interactables"]

        # ---- Structure: apply all new/changed cells ----
        for pos, val in curr_struct.items():
            if pos not in acc_structure or acc_structure[pos] != val:
                acc_structure[pos] = val

        # ---- Utilities: smart teleporter handling ----
        # 1. Find which teleporter destinations exist in this stage's map
        curr_tp_dests = {}  # dest -> [(pos, val), ...]
        for pos, val in curr_utils.items():
            dest = get_tp_dest(val)
            if dest:
                curr_tp_dests.setdefault(dest, []).append((pos, val))

        # 2. For each destination that appears in this stage:
        #    Remove ALL accumulated positions for that destination,
        #    then add the positions from this stage's map.
        for dest, positions in curr_tp_dests.items():
            # Remove old positions for this destination from accumulated
            to_remove = [pos for pos, val in acc_utilities.items() if get_tp_dest(val) == dest]
            for pos in to_remove:
                del acc_utilities[pos]
            # Add positions from this stage
            for pos, val in positions:
                acc_utilities[pos] = fix_utility(val)

        # 3. Add non-teleporter utilities (always accumulate, never remove)
        for pos, val in curr_utils.items():
            if is_teleporter(val):
                continue  # Already handled
            val = fix_utility(val)
            # Add if new position, or update if changed
            if pos not in acc_utilities or not is_teleporter(acc_utilities.get(pos, "")):
                # Don't overwrite a teleporter with a non-teleporter
                # (unless the teleporter was already moved elsewhere)
                if pos not in acc_utilities:
                    acc_utilities[pos] = val
                elif not is_teleporter(acc_utilities[pos]):
                    acc_utilities[pos] = val

        # ---- Interactables: accumulate all ----
        for pos, val in curr_inter.items():
            acc_interactables[pos] = val

        # ---- Dimensions ----
        all_positions = set(acc_structure.keys()) | set(acc_utilities.keys()) | set(acc_interactables.keys())
        if all_positions:
            max_row = max(r for r, c in all_positions) + 1
            max_col = max(c for r, c in all_positions) + 1
        else:
            max_row, max_col = acc_rows, acc_cols
        acc_rows = max(acc_rows, max_row)
        acc_cols = max(acc_cols, max_col)

        # ---- Build output ----
        struct_layers = grid_to_layers(acc_structure, acc_rows, acc_cols, empty="0")
        util_layers = grid_to_layers(acc_utilities, acc_rows, acc_cols, empty=" ")
        inter_layers = grid_to_layers(acc_interactables, acc_rows, acc_cols, empty=" ")

        out = copy.deepcopy(orig["data"])
        out["layers"]["structure"] = struct_layers
        out["layers"]["utilities"] = util_layers
        out["layers"]["interactables"] = inter_layers
        out["map_info"]["dimensions"]["width"] = acc_cols
        out["map_info"]["dimensions"]["depth"] = acc_rows

        # Report
        tp_dests = sorted(set(get_tp_dest(v) for v in acc_utilities.values() if get_tp_dest(v)))
        tp_count = sum(1 for v in acc_utilities.values() if is_teleporter(v))
        
        # Check for duplicate destinations
        dest_counts = {}
        for v in acc_utilities.values():
            d = get_tp_dest(v)
            if d:
                dest_counts[d] = dest_counts.get(d, 0) + 1
        duplicates = {d: c for d, c in dest_counts.items() if c > 1}

        print(f"\n{name} ({fname}): {acc_rows}x{acc_cols}")
        print(f"  Structure: {len(acc_structure)}, Utilities: {len(acc_utilities)}, Interactables: {len(acc_interactables)}")
        print(f"  Teleporters: {tp_count} pointing to {len(tp_dests)} destinations")
        if duplicates:
            print(f"  !! Duplicate destinations: {duplicates}")

        results.append((name, fname, out))

    # ---- Write ----
    print(f"\n{'='*60}")
    print("WRITING")
    print(f"{'='*60}")

    for name, fname, data in results:
        path = os.path.join(LAB_DIR, fname)
        output = format_map_json(data)
        with open(path, "w", encoding="utf-8") as f:
            f.write(output)
        print(f"  {fname}")

    print(f"\nDone! {len(results)} files rebuilt.")


def format_map_json(data):
    raw = json.dumps(data, indent="\t", ensure_ascii=False)
    lines = raw.split("\n")
    output_lines = []
    in_layer_array = False
    layer_depth = 0
    row_buffer = []

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()

        if re.match(r'^"(structure|utilities|interactables|artifacts)":\s*\[', stripped):
            output_lines.append(line)
            in_layer_array = True
            layer_depth = 0
            i += 1
            continue

        if in_layer_array:
            if stripped == "[":
                row_buffer = []
                layer_depth += 1
                i += 1
                continue
            elif stripped in ("],", "]"):
                if layer_depth > 0:
                    indent = "\t\t\t"
                    compact = indent + json.dumps(row_buffer, ensure_ascii=False)
                    if stripped == "],":
                        compact += ","
                    output_lines.append(compact)
                    layer_depth -= 1
                    row_buffer = []
                else:
                    output_lines.append(line)
                    in_layer_array = False
                i += 1
                continue
            elif layer_depth > 0:
                val = stripped.rstrip(",").strip('"')
                row_buffer.append(val)
                i += 1
                continue

        output_lines.append(line)
        i += 1

    return "\n".join(output_lines)


if __name__ == "__main__":
    main()
