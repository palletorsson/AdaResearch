"""
Fix Lab chain:
1. Set structure to 0 at every teleporter position
2. Keep only ONE m: per map — the one nearest the own-name teleporter
   (the teleporter matching the map's stage name)
3. Propagate structure=0 changes through the chain

For the initial map (no own-name teleporter), keep the existing single m:.
"""
import json, re, os, copy

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
                    compact = "\t\t\t" + json.dumps(row_buffer, ensure_ascii=False)
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


import sys
DRY_RUN = "--dry-run" in sys.argv

def main():
    print(f"{'DRY RUN' if DRY_RUN else 'APPLYING FIXES'}")
    print()

    for name, fname in CHAIN:
        path = os.path.join(LAB_DIR, fname)
        data = load_map(path)
        struct = data["layers"]["structure"]
        utils = data["layers"]["utilities"]
        
        changes = []
        
        # --- Fix 1: Set structure=0 at every teleporter position ---
        for r, row in enumerate(utils):
            cells = row if isinstance(row, list) else row.split(",")
            for c, cell in enumerate(cells):
                v = cell.strip() if isinstance(cell, str) else str(cell)
                if v.startswith("t:"):
                    # Check structure at this position
                    if r < len(struct) and c < len(struct[r]):
                        s_val = struct[r][c]
                        s_val = s_val.strip() if isinstance(s_val, str) else str(s_val)
                        if s_val != "0":
                            changes.append(f"  struct ({r},{c}): {s_val} -> 0 (under {v})")
                            struct[r][c] = "0"
        
        # --- Fix 2: Keep only ONE m: per map ---
        # Find all m: positions
        m_positions = []
        for r, row in enumerate(utils):
            cells = row if isinstance(row, list) else row.split(",")
            for c, cell in enumerate(cells):
                v = cell.strip() if isinstance(cell, str) else str(cell)
                if v.startswith("m:") or v == "m":
                    m_positions.append((r, c, v))
        
        if len(m_positions) > 1:
            # Find own-name teleporter
            own_tp = None
            for r, row in enumerate(utils):
                cells = row if isinstance(row, list) else row.split(",")
                for c, cell in enumerate(cells):
                    v = cell.strip() if isinstance(cell, str) else str(cell)
                    if v.startswith("t:"):
                        dest = v.split(":")[1]
                        if dest == name:
                            own_tp = (r, c)
                            break
                if own_tp:
                    break
            
            if own_tp:
                # Keep only the m: closest to own-name teleporter
                best = None
                best_dist = 999
                for r, c, v in m_positions:
                    dist = abs(r - own_tp[0]) + abs(c - own_tp[1])
                    # Also require structure=1 at this position
                    s_val = struct[r][c] if r < len(struct) and c < len(struct[r]) else "?"
                    s_val = s_val.strip() if isinstance(s_val, str) else str(s_val)
                    if dist < best_dist and s_val == "1":
                        best = (r, c, v)
                        best_dist = dist
                    elif dist < best_dist and best is None:
                        # Fallback if no struct=1 nearby
                        best = (r, c, v)
                        best_dist = dist
                
                if best is None:
                    best = m_positions[0]  # Shouldn't happen
                
                # Remove all m: except best
                for r, c, v in m_positions:
                    if (r, c) != (best[0], best[1]):
                        changes.append(f"  remove m: at ({r},{c}) '{v}'")
                        utils[r][c] = " "
                
                changes.append(f"  keep m: at ({best[0]},{best[1]}) '{best[2]}' (dist={best_dist} from t:{name})")
            else:
                # No own-name teleporter (initial map) — keep first m: only
                for r, c, v in m_positions[1:]:
                    changes.append(f"  remove extra m: at ({r},{c}) '{v}'")
                    utils[r][c] = " "
                changes.append(f"  keep m: at ({m_positions[0][0]},{m_positions[0][1]}) '{m_positions[0][2]}'")
        
        if changes:
            print(f"{name} ({fname}):")
            for ch in changes:
                print(ch)
            
            if not DRY_RUN:
                output = format_map_json(data)
                with open(path, "w", encoding="utf-8") as f:
                    f.write(output)
                print(f"  -> WRITTEN")
        else:
            print(f"{name} ({fname}): OK")
        print()

if __name__ == "__main__":
    main()
