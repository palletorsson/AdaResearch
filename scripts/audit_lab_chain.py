"""
Audit Lab progression chain.
For each consecutive pair, checks:
1. Dimensions match
2. Structure is superset (no cells removed)
3. Teleporters are superset (no teleporters removed)
4. Artifacts/utilities preserved
"""
import json, os, sys

LAB_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "commons", "maps", "Lab")

# Progression order from curriculum_spine.json lab_evolution
PROGRESSION = [
    ("Initial",           "map_data.json"),
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

def load_map(filename):
    path = os.path.join(LAB_DIR, filename)
    if not os.path.exists(path):
        return None
    with open(path, "r", encoding="utf-8") as f:
        text = f.read()
    # Strip trailing commas before ] or }
    import re
    text = re.sub(r',(\s*[}\]])', r'\1', text)
    return json.loads(text)

def parse_grid(layer_rows):
    """Parse a layer into a dict of (row, col) -> cell_value, skipping empty cells."""
    grid = {}
    if not layer_rows:
        return grid
    for r, row in enumerate(layer_rows):
        # Rows can be lists (already parsed) or strings (comma-separated)
        if isinstance(row, str):
            cells = row.split(",")
        elif isinstance(row, list):
            cells = row
        else:
            continue
        for c, cell in enumerate(cells):
            if isinstance(cell, str):
                cell = cell.strip()
            else:
                cell = str(cell)
            if cell and cell != "0" and cell != "":
                grid[(r, c)] = cell
    return grid

def summarize_map(data):
    dims = data.get("dimensions", {})
    w, h = dims.get("width", 0), dims.get("height", 0)
    layers = data.get("layers", {})
    
    structure = parse_grid(layers.get("structure", []))
    utilities = parse_grid(layers.get("utilities", []))
    interactables = parse_grid(layers.get("interactables", []))
    artifacts = parse_grid(layers.get("artifacts", []))
    
    # Extract teleporters from interactables
    teleporters = {k: v for k, v in interactables.items() if v.startswith("tp:")}
    
    return {
        "dims": (w, h),
        "structure": structure,
        "utilities": utilities,
        "interactables": interactables,
        "artifacts": artifacts,
        "teleporters": teleporters,
    }

def compare_stages(name_a, summary_a, name_b, summary_b):
    """Compare two stages. B should be a superset of A."""
    issues = []
    
    # Dimension check
    if summary_a["dims"] != summary_b["dims"]:
        issues.append(f"  DIMS: {name_a} is {summary_a['dims']}, {name_b} is {summary_b['dims']}")
    
    # For each layer, check what A had that B lost
    for layer_name in ["structure", "utilities", "artifacts"]:
        a_grid = summary_a[layer_name]
        b_grid = summary_b[layer_name]
        lost = set(a_grid.keys()) - set(b_grid.keys())
        changed = {k for k in set(a_grid.keys()) & set(b_grid.keys()) if a_grid[k] != b_grid[k]}
        
        if lost:
            issues.append(f"  {layer_name.upper()} LOST ({len(lost)} cells): e.g. {list(lost)[:5]}")
        if changed:
            examples = [(k, a_grid[k], b_grid[k]) for k in list(changed)[:3]]
            issues.append(f"  {layer_name.upper()} CHANGED ({len(changed)} cells): e.g. {examples}")
    
    # Teleporters specifically
    a_tp = summary_a["teleporters"]
    b_tp = summary_b["teleporters"]
    lost_tp = set(a_tp.keys()) - set(b_tp.keys())
    if lost_tp:
        lost_details = [(k, a_tp[k]) for k in lost_tp]
        issues.append(f"  TELEPORTERS LOST: {lost_details}")
    
    # Interactables (non-teleporter)
    a_inter = {k: v for k, v in summary_a["interactables"].items() if not v.startswith("tp:")}
    b_inter = {k: v for k, v in summary_b["interactables"].items() if not v.startswith("tp:")}
    lost_inter = set(a_inter.keys()) - set(b_inter.keys())
    if lost_inter:
        lost_details = [(k, a_inter[k]) for k in list(lost_inter)[:5]]
        issues.append(f"  INTERACTABLES LOST ({len(lost_inter)}): e.g. {lost_details}")
    
    return issues

def main():
    print("=" * 70)
    print("LAB PROGRESSION CHAIN AUDIT")
    print("=" * 70)
    
    summaries = []
    for name, filename in PROGRESSION:
        data = load_map(filename)
        if data is None:
            print(f"\n⚠ {name}: {filename} NOT FOUND")
            summaries.append((name, filename, None))
            continue
        s = summarize_map(data)
        print(f"\n{'─'*50}")
        print(f"Stage: {name} ({filename})")
        print(f"  Dimensions: {s['dims'][0]}x{s['dims'][1]}")
        print(f"  Structure cells: {len(s['structure'])}")
        print(f"  Utilities: {len(s['utilities'])}")
        print(f"  Artifacts: {len(s['artifacts'])}")
        print(f"  Interactables: {len(s['interactables'])}")
        print(f"  Teleporters: {len(s['teleporters'])}")
        # List teleporter destinations
        for pos, val in sorted(s["teleporters"].items()):
            print(f"    tp@{pos}: {val}")
        summaries.append((name, filename, s))
    
    print(f"\n{'=' * 70}")
    print("CONTINUITY CHECK (each stage vs previous)")
    print("=" * 70)
    
    total_issues = 0
    for i in range(1, len(summaries)):
        name_a, _, s_a = summaries[i-1]
        name_b, _, s_b = summaries[i]
        if s_a is None or s_b is None:
            print(f"\n⚠ Skipping {name_a} → {name_b} (missing file)")
            continue
        
        issues = compare_stages(name_a, s_a, name_b, s_b)
        if issues:
            print(f"\n❌ {name_a} → {name_b}: {len(issues)} issues")
            for iss in issues:
                print(iss)
            total_issues += len(issues)
        else:
            print(f"\n✅ {name_a} → {name_b}: OK (superset)")
    
    print(f"\n{'=' * 70}")
    print(f"TOTAL ISSUES: {total_issues}")
    
    # Also check: what NEW content was added at each stage
    print(f"\n{'=' * 70}")
    print("NEW CONTENT PER STAGE")
    print("=" * 70)
    for i in range(1, len(summaries)):
        name_a, _, s_a = summaries[i-1]
        name_b, _, s_b = summaries[i]
        if s_a is None or s_b is None:
            continue
        
        new_tp = set(s_b["teleporters"].keys()) - set(s_a["teleporters"].keys())
        new_struct = len(s_b["structure"]) - len(s_a["structure"])
        new_art = set(s_b["artifacts"].keys()) - set(s_a["artifacts"].keys())
        
        print(f"\n{name_b}:")
        print(f"  New structure cells: {new_struct}")
        print(f"  New artifact positions: {len(new_art)}")
        if new_tp:
            for pos in sorted(new_tp):
                print(f"  New teleporter: {pos} → {s_b['teleporters'][pos]}")

if __name__ == "__main__":
    main()
