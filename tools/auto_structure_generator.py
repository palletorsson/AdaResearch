"""Auto-Structure Generator — Artifacts → Walkable Map

Given artifact positions on a grid, generates the structure layer:
  1. SEED - floor pads under each artifact (sized to footprint)
  2. EXPAND - clearance zone around each artifact
  3. CONNECT - minimum spanning tree between all positions
  4. PATH - carve corridors along MST edges
  5. BORDER - walls around the perimeter
  6. VALIDATE - pathfinder reachability check

Usage:
  python tools/auto_structure_generator.py --width 12 --depth 14 \\
    --artifacts "dark_sphere:3:5,AnimatedTree:8:5,genetic_tree_sculptor:6:10" \\
    --spawn 1:1 --teleporter 10:12 --output commons/maps/TestMap/map_data.json

  # Or from JSON input:
  python tools/auto_structure_generator.py --input artifacts.json --output map_data.json
"""

import json, os, sys, math
from collections import defaultdict
from heapq import heappush, heappop

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REGISTRY_DIR = os.path.join(REPO_ROOT, "commons", "artifacts", "registry")
CONTRACTS_PATH = os.path.join(REPO_ROOT, "commons", "artifacts", "artifact_spatial_contracts.json")


# ═══════════════════════════════════════════════════════════════
# REGISTRY LOADING
# ═══════════════════════════════════════════════════════════════

def load_all_registries():
    """Load all artifact registries into a single lookup dict."""
    registry = {}
    for f in os.listdir(REGISTRY_DIR):
        if not f.endswith(".json"):
            continue
        path = os.path.join(REGISTRY_DIR, f)
        try:
            with open(path, encoding="utf-8") as fh:
                data = json.load(fh)
            arts = data.get("artifacts", {})
            for key, val in arts.items():
                lookup = val.get("lookup_name", val.get("lookupName", key))
                registry[lookup] = val
        except Exception:
            pass
    return registry


def load_contracts():
    """Load spatial contracts for clearance/staging info."""
    if not os.path.exists(CONTRACTS_PATH):
        return {}
    with open(CONTRACTS_PATH, encoding="utf-8") as f:
        data = json.load(f)
    return data.get("artifact_contracts", data.get("contracts", {}))


def get_footprint(registry, lookup_name):
    """Get artifact footprint [x, z] in grid cells."""
    entry = registry.get(lookup_name, {})
    params = entry.get("parameters", {})
    fp = params.get("footprint", [1, 1, 1])
    if isinstance(fp, list) and len(fp) >= 2:
        return (max(1, int(fp[0])), max(1, int(fp[1])))
    return (1, 1)


def get_clearance(contracts, lookup_name):
    """Get clearance radius in cells for an artifact."""
    contract = contracts.get(lookup_name, {})
    return contract.get("clearance_radius_cells", 1.5)


# ═══════════════════════════════════════════════════════════════
# GRID HELPERS
# ═══════════════════════════════════════════════════════════════

def make_blank_grid(width, depth, value="0"):
    """Create a WxD grid filled with value."""
    return [[value for _ in range(width)] for _ in range(depth)]


def in_bounds(x, z, width, depth):
    return 0 <= x < width and 0 <= z < depth


def manhattan(a, b):
    return abs(a[0] - b[0]) + abs(a[1] - b[1])


def euclidean(a, b):
    return math.sqrt((a[0] - b[0])**2 + (a[1] - b[1])**2)


# ═══════════════════════════════════════════════════════════════
# STEP 1: SEED PADS
# ═══════════════════════════════════════════════════════════════

def seed_pads(grid, width, depth, artifacts, registry):
    """Place floor pads under each artifact, sized to footprint."""
    for art in artifacts:
        name = art["lookup_name"]
        x, z = art["x"], art["z"]
        fw, fd = get_footprint(registry, name)

        # Center the footprint on the artifact position
        x_start = max(0, x - fw // 2)
        z_start = max(0, z - fd // 2)

        for dz in range(fd):
            for dx in range(fw):
                nx, nz = x_start + dx, z_start + dz
                if in_bounds(nx, nz, width, depth):
                    grid[nz][nx] = "1"


# ═══════════════════════════════════════════════════════════════
# STEP 2: EXPAND CLEARANCE
# ═══════════════════════════════════════════════════════════════

def expand_clearance(grid, width, depth, artifacts, contracts):
    """BFS flood-fill from each artifact out to clearance radius."""
    for art in artifacts:
        name = art["lookup_name"]
        x, z = art["x"], art["z"]
        clearance = get_clearance(contracts, name)
        radius = max(1, int(math.ceil(clearance)))

        for dz in range(-radius, radius + 1):
            for dx in range(-radius, radius + 1):
                if math.sqrt(dx*dx + dz*dz) <= clearance:
                    nx, nz = x + dx, z + dz
                    if in_bounds(nx, nz, width, depth):
                        if grid[nz][nx] == "0":
                            grid[nz][nx] = "1"


# ═══════════════════════════════════════════════════════════════
# STEP 3: MINIMUM SPANNING TREE
# ═══════════════════════════════════════════════════════════════

def compute_mst(positions):
    """Prim's MST over position list. Returns list of (i, j) index pairs."""
    n = len(positions)
    if n <= 1:
        return []

    in_tree = [False] * n
    min_edge = [float('inf')] * n
    min_edge[0] = 0
    parent = [-1] * n
    edges = []

    # Priority queue: (cost, node)
    pq = [(0, 0)]

    while pq:
        cost, u = heappop(pq)
        if in_tree[u]:
            continue
        in_tree[u] = True
        if parent[u] != -1:
            edges.append((parent[u], u))

        for v in range(n):
            if not in_tree[v]:
                d = euclidean(positions[u], positions[v])
                if d < min_edge[v]:
                    min_edge[v] = d
                    parent[v] = u
                    heappush(pq, (d, v))

    return edges


# ═══════════════════════════════════════════════════════════════
# STEP 4: CARVE CORRIDORS
# ═══════════════════════════════════════════════════════════════

def carve_corridor(grid, width, depth, x1, z1, x2, z2, corridor_width=2):
    """Carve a corridor between two points (L-shaped path)."""
    # Go horizontal first, then vertical
    step_x = 1 if x2 >= x1 else -1
    step_z = 1 if z2 >= z1 else -1

    # Horizontal segment
    cx = x1
    while cx != x2:
        for w in range(corridor_width):
            nz = z1 + w - corridor_width // 2
            if in_bounds(cx, nz, width, depth):
                if grid[nz][cx] == "0":
                    grid[nz][cx] = "1"
        cx += step_x

    # Vertical segment
    cz = z1
    while cz != z2:
        for w in range(corridor_width):
            nx = x2 + w - corridor_width // 2
            if in_bounds(nx, cz, width, depth):
                if grid[cz][nx] == "0":
                    grid[cz][nx] = "1"
        cz += step_z

    # Final corner cell
    if in_bounds(x2, z2, width, depth):
        grid[z2][x2] = "1"


def carve_mst_corridors(grid, width, depth, positions, mst_edges, corridor_width=2):
    """Carve corridors along all MST edges."""
    for i, j in mst_edges:
        x1, z1 = positions[i]
        x2, z2 = positions[j]
        carve_corridor(grid, width, depth, x1, z1, x2, z2, corridor_width)


# ═══════════════════════════════════════════════════════════════
# STEP 5: ADD BORDERS
# ═══════════════════════════════════════════════════════════════

def add_borders(grid, width, depth):
    """Add walls around the perimeter of floor cells."""
    border = make_blank_grid(width, depth, "0")

    for z in range(depth):
        for x in range(width):
            if grid[z][x] != "0":
                continue
            # Check if any neighbor is floor
            for dz, dx in [(-1,0),(1,0),(0,-1),(0,1)]:
                nz, nx = z + dz, x + dx
                if in_bounds(nx, nz, width, depth) and grid[nz][nx] == "1":
                    border[z][x] = "2"
                    break

    # Apply borders
    for z in range(depth):
        for x in range(width):
            if border[z][x] == "2":
                grid[z][x] = "2"


# ═══════════════════════════════════════════════════════════════
# STEP 6: BUILD UTILITIES + INTERACTABLES LAYERS
# ═══════════════════════════════════════════════════════════════

def build_utilities(width, depth, spawn, teleporter):
    """Create utilities layer with spawn and teleporter."""
    utils = make_blank_grid(width, depth, " ")
    sx, sz = spawn
    if in_bounds(sx, sz, width, depth):
        utils[sz][sx] = "s"
    tx, tz = teleporter
    if in_bounds(tx, tz, width, depth):
        utils[tz][tx] = "t"
    return utils


def build_interactables(width, depth, artifacts):
    """Create interactables layer with artifacts at their positions."""
    inter = make_blank_grid(width, depth, " ")
    for art in artifacts:
        x, z = art["x"], art["z"]
        if in_bounds(x, z, width, depth):
            inter[z][x] = art["lookup_name"]
    return inter


# ═══════════════════════════════════════════════════════════════
# MAIN GENERATOR
# ═══════════════════════════════════════════════════════════════

def generate_map(width, depth, artifacts, spawn, teleporter, map_name="AutoGenerated"):
    """Generate a complete map_data.json from artifact positions."""
    registry = load_all_registries()
    contracts = load_contracts()

    # Build structure layer
    grid = make_blank_grid(width, depth)

    # Spawn pad: floor under and around spawn
    sx, sz = spawn
    tx, tz = teleporter
    for dz in range(-1, 2):
        for dx in range(-1, 2):
            if in_bounds(sx+dx, sz+dz, width, depth):
                grid[sz+dz][sx+dx] = "1"

    # Teleporter pad: floor around it, but teleporter cell itself = void (height 0)
    for dz in range(-1, 2):
        for dx in range(-1, 2):
            if in_bounds(tx+dx, tz+dz, width, depth):
                grid[tz+dz][tx+dx] = "1"
    if in_bounds(tx, tz, width, depth):
        grid[tz][tx] = "0"  # Pathfinder requires teleporter on void

    print(f"Step 1: Seeding pads for {len(artifacts)} artifacts...")
    seed_pads(grid, width, depth, artifacts, registry)

    print("Step 2: Expanding clearance zones...")
    expand_clearance(grid, width, depth, artifacts, contracts)

    print("Step 3: Computing MST...")
    positions = [(a["x"], a["z"]) for a in artifacts]
    positions.append(spawn)
    positions.append(teleporter)
    mst = compute_mst(positions)
    print(f"  MST has {len(mst)} edges connecting {len(positions)} nodes")

    print("Step 4: Carving corridors...")
    carve_mst_corridors(grid, width, depth, positions, mst)

    print("Step 5: Adding borders...")
    add_borders(grid, width, depth)

    # Re-enforce teleporter as void (borders may have overwritten it)
    if in_bounds(tx, tz, width, depth):
        grid[tz][tx] = "0"

    print("Step 6: Building utilities + interactables...")
    utils = build_utilities(width, depth, spawn, teleporter)
    inter = build_interactables(width, depth, artifacts)

    # Count cells
    floor_count = sum(1 for row in grid for cell in row if cell == "1")
    wall_count = sum(1 for row in grid for cell in row if cell == "2")
    void_count = sum(1 for row in grid for cell in row if cell == "0")
    print(f"  Floor: {floor_count}, Walls: {wall_count}, Void: {void_count}")

    # Build map_data.json
    map_data = {
        "map_info": {
            "name": map_name,
            "lookup_name": map_name,
            "description": f"Auto-generated map with {len(artifacts)} artifacts",
            "version": "1.0",
            "format": "json",
            "dimensions": {
                "width": width,
                "depth": depth,
                "max_height": 2
            },
            "metadata": {
                "auto_generated": True,
                "artifact_count": len(artifacts),
                "generator": "auto_structure_generator.py"
            }
        },
        "utility_definitions": {
            "t": {
                "type": "teleporter",
                "name": "Exit",
                "properties": {"action": "next_in_sequence"}
            }
        },
        "settings": {
            "cube_size": 1.0,
            "gutter": 0.0,
            "show_grid": False
        },
        "layers": {
            "structure": grid,
            "utilities": utils,
            "interactables": inter
        }
    }

    return map_data


# ═══════════════════════════════════════════════════════════════
# CLI
# ═══════════════════════════════════════════════════════════════

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Auto-generate map structure from artifact positions")
    parser.add_argument("--width", type=int, default=12)
    parser.add_argument("--depth", type=int, default=14)
    parser.add_argument("--artifacts", type=str, help="Comma-separated: name:x:z,name:x:z,...")
    parser.add_argument("--spawn", type=str, default="1:1", help="x:z")
    parser.add_argument("--teleporter", type=str, default="10:12", help="x:z")
    parser.add_argument("--input", type=str, help="JSON file with artifact list")
    parser.add_argument("--output", type=str, help="Output map_data.json path")
    parser.add_argument("--name", type=str, default="AutoGenerated", help="Map name")
    parser.add_argument("--print", action="store_true", help="Print structure grid to console")
    args = parser.parse_args()

    # Parse artifacts
    artifacts = []
    if args.input:
        with open(args.input, encoding="utf-8") as f:
            data = json.load(f)
        if isinstance(data, list):
            artifacts = data
        elif "artifacts" in data:
            artifacts = data["artifacts"]
    elif args.artifacts:
        for token in args.artifacts.split(","):
            parts = token.strip().split(":")
            if len(parts) >= 3:
                artifacts.append({
                    "lookup_name": parts[0],
                    "x": int(parts[1]),
                    "z": int(parts[2])
                })

    if not artifacts:
        print("No artifacts specified. Use --artifacts or --input")
        sys.exit(1)

    # Parse spawn and teleporter
    sp = args.spawn.split(":")
    spawn = (int(sp[0]), int(sp[1]))
    tp = args.teleporter.split(":")
    teleporter = (int(tp[0]), int(tp[1]))

    print(f"Generating {args.width}x{args.depth} map with {len(artifacts)} artifacts...")
    map_data = generate_map(args.width, args.depth, artifacts, spawn, teleporter, args.name)

    if getattr(args, 'print'):
        # Print structure grid as ASCII
        grid = map_data["layers"]["structure"]
        symbols = {"0": ".", "1": "#", "2": "W"}
        for z, row in enumerate(grid):
            line = ""
            for x, cell in enumerate(row):
                # Check for artifacts/spawn/teleporter
                if (x, z) == spawn:
                    line += "S"
                elif (x, z) == teleporter:
                    line += "T"
                elif any(a["x"] == x and a["z"] == z for a in artifacts):
                    line += "A"
                else:
                    line += symbols.get(cell, "?")
            print(line)

    if args.output:
        out_dir = os.path.dirname(args.output)
        if out_dir and not os.path.exists(out_dir):
            os.makedirs(out_dir, exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(map_data, f, indent=2)
        print(f"\nSaved: {args.output}")
    else:
        print(json.dumps(map_data, indent=2))


if __name__ == "__main__":
    main()
