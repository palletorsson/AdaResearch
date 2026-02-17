"""
Apply a patch to the Lab chain that propagates forward.
A patch is: at position (r,c) in layer X, set value to Y,
starting from a given stage and propagating through all subsequent stages.

Usage:
  python scripts/patch_lab_chain.py --layer structure --row 7 --col 1 --value 0 --from color
  python scripts/patch_lab_chain.py --layer structure --row 7 --col 1 --value 0 --from color --dry-run
"""
import json, re, os, argparse

LAB_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "commons", "maps", "Lab")

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

def load_map(path):
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    text = re.sub(r',(\s*[}\]])', r'\1', text)
    return json.loads(text)

def get_cell(layer_rows, r, c):
    if r < len(layer_rows):
        row = layer_rows[r]
        cells = row if isinstance(row, list) else row.split(",")
        if c < len(cells):
            v = cells[c]
            return v.strip() if isinstance(v, str) else str(v)
    return None

def set_cell(layer_rows, r, c, value):
    if r < len(layer_rows):
        row = layer_rows[r]
        if isinstance(row, list):
            if c < len(row):
                row[c] = value
                return True
    return False

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


def main():
    parser = argparse.ArgumentParser(description="Patch Lab chain with propagation")
    parser.add_argument("--layer", required=True, choices=["structure", "utilities", "interactables"])
    parser.add_argument("--row", required=True, type=int)
    parser.add_argument("--col", required=True, type=int)
    parser.add_argument("--value", required=True, help="New value to set")
    parser.add_argument("--from", dest="from_stage", required=True, help="Stage name to start from")
    parser.add_argument("--dry-run", action="store_true", help="Show what would change without writing")
    args = parser.parse_args()

    # Find starting index
    stage_names = [name for name, _ in CHAIN]
    if args.from_stage not in stage_names:
        print(f"ERROR: Unknown stage '{args.from_stage}'. Valid: {stage_names}")
        return
    start_idx = stage_names.index(args.from_stage)

    print(f"Patch: {args.layer}[{args.row},{args.col}] = '{args.value}' from '{args.from_stage}' onward")
    print(f"{'DRY RUN' if args.dry_run else 'APPLYING'}")
    print()

    changed = 0
    skipped = 0

    for i in range(start_idx, len(CHAIN)):
        name, fname = CHAIN[i]
        path = os.path.join(LAB_DIR, fname)
        
        if not os.path.exists(path):
            print(f"  {fname}: MISSING")
            continue

        data = load_map(path)
        layer = data["layers"].get(args.layer, [])
        
        current = get_cell(layer, args.row, args.col)
        
        if current == args.value:
            print(f"  {fname}: already '{args.value}' -- skip")
            skipped += 1
            continue
        
        print(f"  {fname}: '{current}' -> '{args.value}'")
        
        if not args.dry_run:
            set_cell(layer, args.row, args.col, args.value)
            output = format_map_json(data)
            with open(path, "w", encoding="utf-8") as f:
                f.write(output)
            changed += 1

    print(f"\n{'Would change' if args.dry_run else 'Changed'}: {changed}, Skipped: {skipped}")


if __name__ == "__main__":
    main()
