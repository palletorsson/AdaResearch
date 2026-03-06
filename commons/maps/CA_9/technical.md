# Cells stack into a cubic lattice where 26 neighbors govern birth and survival across a volume that cannot be seen all at once

CA_8 dissolved the grid. Discrete states became floats, step functions became sigmoids, and the automaton flowed like a continuous field wrapped onto a sphere. The boundary vanished. The topology became uniform. But the dimensionality stayed flat — a 2D surface, however curved. CA_9 goes the other direction. States return to discrete. The grid returns to hard edges. What changes is depth. Cells no longer tile a plane. They fill a volume. Each cell sits inside a cube of 26 neighbors — the 3D Moore neighborhood — and local rules generate solid structures, cavities, tunnels, and shells that can only be understood by moving through them.

Two dimensions to three is not an incremental step. It is a qualitative rupture. A 2D pattern can be apprehended in a single glance. A 3D structure has an interior. It occludes itself. Navigation becomes part of comprehension. The learner walks around the result, peers through gaps, looks up from beneath. The automaton is no longer a picture. It is architecture.

## The 26-Neighbor Cube

In 2D, the Moore neighborhood at radius 1 contains 8 cells: a 3x3 square minus the center. In 3D, the Moore neighborhood at radius 1 contains 26 cells: a 3x3x3 cube minus the center. The formula generalizes cleanly:

```
neighbors_2D = (2r + 1)^2 - 1  ->  8  at r=1
neighbors_3D = (2r + 1)^3 - 1  ->  26 at r=1
```

The jump from 8 to 26 is not merely arithmetic. It reorganizes the geometry of adjacency. In 2D, the 8 neighbors decompose into two classes: 4 edge-adjacent (sharing a face in the grid), 4 corner-adjacent (sharing only a vertex). In 3D, the 26 decompose into three:

- 6 face-adjacent — distance 1.0
- 12 edge-adjacent — distance sqrt(2)
- 8 corner-adjacent — distance sqrt(3)

Whether the rule weights these classes equally or treats them differently determines the isotropy of the resulting structures. Equal weighting produces rounder forms. Face-only counting produces orthogonal, crystalline growth. The choice is geometric, not arbitrary.

```gdscript
func count_neighbors_3d(cx: int, cy: int, cz: int) -> int:
    var count: int = 0
    for dx in range(-1, 2):
        for dy in range(-1, 2):
            for dz in range(-1, 2):
                if dx == 0 and dy == 0 and dz == 0:
                    continue
                var nx := posmod(cx + dx, grid_width)
                var ny := posmod(cy + dy, grid_height)
                var nz := posmod(cz + dz, grid_depth)
                if grid[nx][ny][nz] == 1:
                    count += 1
    return count
```

Three nested loops. Three axes of wrapping. The triply-nested iteration makes the cubic symmetry explicit — every direction is treated identically. The `posmod` wrapping turns the volume into a 3D torus, eliminating boundary effects the same way CA_4's 2D wrapping did. Every cell is interior. No cell has fewer than 26 neighbors.

The cost is cubic. An NxNxN grid contains N^3 cells, each scanning 26 neighbors per generation. For N=50, that is 125,000 cells and 3,250,000 neighbor lookups per step. For N=100, one million cells, 26 million lookups. The 2D grid at N=100 required only 80,000 lookups per step. The dimensional leap multiplies computation by a factor proportional to N — the third dimension is not free.

At radius 2, the 3D neighborhood balloons to 124 cells. Radius 3: 342. The cubic scaling that CA_6 flagged in theory becomes visceral in practice. Most 3D CA lock the radius at 1 and compensate with richer state spaces or asymmetric weighting. The 26-cell shell is expensive enough.

## Birth/Survival in Three Dimensions

The B/S notation from CA_1 extends directly. B5-7/S4-6 means: a dead cell with 5, 6, or 7 live neighbors becomes alive; a live cell with 4, 5, or 6 live neighbors survives; all other cells die. The notation is identical. The dynamics are not.

```gdscript
@export var birth_min: int = 5
@export var birth_max: int = 7
@export var survival_min: int = 4
@export var survival_max: int = 6

func apply_rule_3d(cx: int, cy: int, cz: int) -> int:
    var neighbors := count_neighbors_3d(cx, cy, cz)
    var current := grid[cx][cy][cz]
    if current == 0:
        if neighbors >= birth_min and neighbors <= birth_max:
            return 1
        return 0
    else:
        if neighbors >= survival_min and neighbors <= survival_max:
            return 1
        return 0
```

In 2D Life (B3/S23), a cell is born with exactly 3 neighbors out of 8. That is 37.5% density — a precise threshold. In 3D with 26 neighbors, B5-7/S4-6 spans a range from 15% to 27% — a broader, lower band. The rules must be retuned for the expanded neighborhood. Too-restrictive birth ranges produce nothing — the probability of exactly N neighbors out of 26 in a random field is low for any single N. Too-permissive ranges produce solid blocks — everything is born, nothing dies. The viable rules cluster in narrow bands where birth and survival thresholds balance growth against overpopulation in 26 dimensions of adjacency.

The search space for rules is vast but not intractable. Totalistic rules on 26 neighbors have 27 possible neighbor counts (0 through 26), and each count is either in the birth set, the survival set, or neither. The total number of totalistic B/S rules is 3^27 — approximately 7.6 trillion. Most produce trivial dynamics: instant death, solid fill, or random static. The interesting rules — those that generate structured, persistent, evolving forms — occupy a thin region of this space, analogous to the edge-of-chaos rules in Wolfram's 2D classification.

## Volumetric Structures and Occlusion

A 2D automaton produces a flat image. Every cell is visible simultaneously. Patterns are immediately legible — gliders, oscillators, still lifes announce themselves through their shapes. A 3D automaton produces a solid volume. The exterior surface is visible. Everything inside is hidden.

This transforms the relationship between the automaton and its observer. In 2D, observation is passive. In 3D, observation requires navigation. A spherical shell of live cells might contain a hollow interior, a second concentric shell, a tunnel connecting inside to outside. None of this is apparent from any single vantage point. The learner must orbit the structure, slice through it mentally, infer the topology from partial views.

```gdscript
func is_surface_cell(cx: int, cy: int, cz: int) -> bool:
    # A cell is on the surface if at least one face-neighbor is dead
    var face_offsets := [
        Vector3i(1, 0, 0), Vector3i(-1, 0, 0),
        Vector3i(0, 1, 0), Vector3i(0, -1, 0),
        Vector3i(0, 0, 1), Vector3i(0, 0, -1)
    ]
    for offset in face_offsets:
        var nx := posmod(cx + offset.x, grid_width)
        var ny := posmod(cy + offset.y, grid_height)
        var nz := posmod(cz + offset.z, grid_depth)
        if grid[nx][ny][nz] == 0:
            return true
    return false
```

Surface detection reduces the rendering load. Interior cells — surrounded on all six faces by live cells — contribute nothing to the visual. Only surface cells need geometry. For a solid 50x50x50 block, that reduces 125,000 cells to roughly 14,700 surface cells. For a sponge-like structure with many internal cavities, the surface fraction is higher but still far below the total cell count.

The distinction between surface and interior is itself a 3D phenomenon. In 2D, every live cell is visible. There is no interior to hide. The concept of occlusion — one cell blocking the view of another — does not exist on a flat grid. In 3D, occlusion is the default. Most cells are hidden. The automaton is an iceberg, and the learner sees only the tip.

## The ca_chair_test Artifact

The `ca_chair_test` evaluates whether 3D cellular automata rules can generate stable, furniture-scale geometries from local interactions alone. The question is architectural: can a volumetric CA, seeded appropriately and run under specific B/S parameters, produce a form that reads as a chair — four legs, a seat, a back? Not by design, but by emergence.

```gdscript
@export var grid_size: int = 16
@export var birth_range: Vector2i = Vector2i(5, 7)
@export var survival_range: Vector2i = Vector2i(4, 6)
@export var seed_density: float = 0.4
@export var generations: int = 8

func initialize_seed():
    for x in range(grid_size):
        for y in range(grid_size):
            for z in range(grid_size):
                if randf() < seed_density:
                    grid[x][y][z] = 1
                else:
                    grid[x][y][z] = 0
```

The seed is a random fill at 40% density. No chair shape is encoded in the initial condition. The automaton runs for a fixed number of generations — not until equilibrium but until a specific moment in its trajectory, where the structure has consolidated enough to hold form but not so much that it has collapsed into a featureless blob or dissolved into dust.

The generation count matters. At generation 1, the random noise has barely organized. By generation 4, clusters have formed and begun interacting. By generation 8, the dynamics have settled into a quasi-stable configuration — still changing, but slowly. The artifact captures the structure at this moment. Different generation counts produce different forms from the same seed, the same rules. The temporal parameter is a design tool as much as the spatial ones.

```gdscript
func run_generations():
    for gen in range(generations):
        var next_grid := create_empty_grid()
        for x in range(grid_size):
            for y in range(grid_size):
                for z in range(grid_size):
                    next_grid[x][y][z] = apply_rule_3d(x, y, z)
        grid = next_grid
    build_mesh_from_grid()
```

Each generation allocates a fresh grid, applies the rule to every cell, then swaps. The double-buffering — reading from `grid`, writing to `next_grid` — ensures synchronous update. All cells see the same generation's state when computing their next value. Without double-buffering, cells updated early in the loop would influence cells updated later, breaking the parallel semantics that define CA.

The mesh construction converts live surface cells into visible geometry:

```gdscript
func build_mesh_from_grid():
    for x in range(grid_size):
        for y in range(grid_size):
            for z in range(grid_size):
                if grid[x][y][z] == 1 and is_surface_cell(x, y, z):
                    place_cube(x, y, z)
```

Each surviving surface cell becomes a unit cube. The result is a voxelized solid — blocky, discrete, legible. The blockiness is not a limitation. It is the point. The structure is made of cells. The cells are the ontological unit. Smoothing the surface would obscure the cellular nature of the form.

Performance scales with the surface cell count, not the total. A 16x16x16 grid contains 4,096 cells. A typical B5-7/S4-6 run at 40% seed density stabilizes around 800-1,200 live cells, of which 60-70% are surface. Under 1,000 cubes to render — trivial for a modern GPU. The bottleneck is simulation, not rendering. The triple-nested generation loop dominates.

## Cross-Section Slicing

The intent identifies a gap: a cross-section slicer that cuts through the volume at adjustable planes, revealing internal structure layer by layer. This connects the 3D bulk behavior to the 2D slice dynamics the learner already understands from eight previous maps.

```gdscript
@export var slice_axis: int = 1  # 0=X, 1=Y, 2=Z
@export var slice_position: int = 0

func get_slice(axis: int, pos: int) -> Array:
    var slice: Array = []
    match axis:
        0:  # X slice: shows YZ plane
            for y in range(grid_size):
                var row: Array[int] = []
                for z in range(grid_size):
                    row.append(grid[pos][y][z])
                slice.append(row)
        1:  # Y slice: shows XZ plane
            for x in range(grid_size):
                var row: Array[int] = []
                for z in range(grid_size):
                    row.append(grid[x][pos][z])
                slice.append(row)
        2:  # Z slice: shows XY plane
            for x in range(grid_size):
                var row: Array[int] = []
                for y in range(grid_size):
                    row.append(grid[x][y][pos])
                slice.append(row)
    return slice
```

Each slice is a 2D grid — familiar territory. Sweeping the slice position from 0 to `grid_size - 1` is like scanning through an MRI. Each frame is a flat pattern. The sequence of frames reconstructs the volume. The learner sees which 2D patterns correspond to legs (four disconnected clusters), which correspond to the seat (a connected slab), which correspond to the back (a single wall). The 3D form decomposes into a stack of 2D maps. The maps the learner already knows how to read.

The slice also reveals internal voids. A solid exterior can hide hollow chambers, tunnels, or sponge-like networks. The surface rendering shows none of this. The slice shows all of it. This dual view — exterior surface plus interior cross-section — provides the complete picture that neither representation achieves alone.

The connection to earlier maps is precise. CA_1 through CA_5 operated on flat grids where every cell was simultaneously visible. CA_6's 3D tree stacked 2D layers but remained legible from the outside — a branching form with no hidden interior. CA_8's sphere was a surface, not a solid. CA_9 is the first map where the automaton has genuine volumetric depth, where cells exist that no camera angle can see without cutting the structure open. The slicer is the tool that restores the legibility that three dimensions took away.

## Combinatorial Explosion and Totalistic Compression

The rule table for a 3D binary automaton with 26 neighbors has 2^26 entries — over 67 million configurations. Enumerating or storing the complete table is impractical. Even at one bit per entry, the table consumes 8 megabytes. At two states, the total number of possible rules is 2^(2^26) — a number with over 20 million digits. The space is not explorable.

Totalistic rules compress this. Instead of distinguishing which neighbors are alive, the rule counts how many. The possible counts range from 0 to 26 — twenty-seven values. A totalistic B/S rule assigns each count to one of three outcomes: birth (if dead), survival (if alive), or death. The rule is fully specified by two sets of integers drawn from {0, 1, ..., 26}.

```gdscript
func parse_bs_rule(rule_string: String) -> Dictionary:
    # Parses "B5-7/S4-6" into birth and survival sets
    var parts := rule_string.split("/")
    var birth_set: Array[int] = parse_range(parts[0].substr(1))
    var survival_set: Array[int] = parse_range(parts[1].substr(1))
    return {"birth": birth_set, "survival": survival_set}

func parse_range(range_str: String) -> Array[int]:
    var result: Array[int] = []
    var tokens := range_str.split(",")
    for token in tokens:
        if "-" in token:
            var bounds := token.split("-")
            for i in range(int(bounds[0]), int(bounds[1]) + 1):
                result.append(i)
        else:
            result.append(int(token))
    return result
```

The string "B5-7/S4-6" encodes: cells are born at neighbor counts 5, 6, or 7; cells survive at counts 4, 5, or 6. Six integers summarize the entire rule. This compression — from 67 million table entries to a handful of threshold values — is what makes 3D CA tractable. It is also what CA_4's totalistic framework anticipated: the larger the neighborhood, the more essential the compression.

Nature uses a parallel strategy. Biological cells do not distinguish which of their thousands of molecular neighbors are active. They respond to concentrations — totals, densities, gradients. The totalistic rule is not a simplification imposed by computational limits. It is the rule form that scales.

For k states and 26 neighbors, the full rule space scales as k^(k^26). At k=2, that is the 2^(2^26) cited above. At k=3, it is 3^(3^26) — a quantity whose digit count itself requires scientific notation. Discrete 3D grids are expensive not because the grid is large but because the combinatorial space of possible rules is effectively infinite. Every tractable 3D CA uses some form of compression — totalistic counting, threshold bands, density functions — to collapse the space into something a designer can navigate.

## Why Three Dimensions Transform Automata

The dimensional leap changes four things simultaneously.

First, the neighborhood size jumps from 8 to 26, widening the information each cell receives per step.

Second, the volume grows as the cube of the side length, multiplying computational cost.

Third, occlusion makes the automaton spatially illegible from any single viewpoint, demanding navigation.

Fourth, structures gain interiors — they can be hollow, chambered, tunneled, load-bearing.

The fourth point is the deepest. A 2D CA pattern is a drawing. It has no thickness, no structural integrity, no concept of "inside." A 3D CA structure is a solid. It can support weight (if physics is applied). It can contain space (rooms, cavities). It can channel flow (tunnels, pipes). These are architectural properties. They exist because the automaton occupies volume, and volume is where architecture lives.

The `ca_chair_test` asks whether local rules can produce architecture. The answer is conditional. Random seeds under totalistic B/S rules produce organic masses — blobby, asymmetric, vaguely biological. They do not produce chairs. But they produce structural candidates: forms with projections that touch the ground plane, horizontal slabs that could serve as surfaces, vertical walls that could serve as backs. The gap between "structural candidate" and "recognizable furniture" is the gap between emergence and design. CA_9 sits on that boundary — the point where cellular automata meet spatial computing, where procedurally grown volumes might replace manually designed environments.

CA_10 shifts the paradigm entirely. Where CA_1 through CA_9 update every cell in parallel — the field approach — CA_10 introduces Langton's ant: a single agent walking the grid, flipping cells one at a time. The transition from volumetric field dynamics to sequential agent behavior is the transition from physics to biology, from weather to organisms, from everything-at-once to one-step-at-a-time.

## Possible Artifacts

**cross_section_slicer** -- An interactive plane that the learner drags through the 3D volume along any axis. Each position renders the corresponding 2D slice as a flat grid overlaid on the volume, color-coded to match the surface cells it intersects. Sweeping the plane reveals internal cavities, tunnels, and density gradients invisible from the outside. Connects 3D bulk structure to the 2D slice patterns familiar from CA_1 through CA_8.

**rule_explorer_3d** -- A parameter panel exposing birth range, survival range, seed density, and generation count. The learner adjusts values and watches the volume regenerate in real time. Narrow birth ranges produce sparse crystals. Wide survival ranges produce dense blobs. Specific combinations produce sponge-like networks with high surface-to-volume ratios. The explorer maps the viable region of the 3D B/S rule space and builds intuition for which thresholds produce structure versus noise.

**neighbor_class_visualizer** -- Highlights the 26 neighbors of a selected cell, color-coded by adjacency class: 6 face-neighbors in one color, 12 edge-neighbors in another, 8 corner-neighbors in a third. Toggling each class on and off shows how the neighbor count changes, and running the CA with only face-neighbors versus all 26 demonstrates how adjacency geometry shapes the emergent forms. Face-only neighborhoods produce orthogonal, crystalline structures. Full Moore neighborhoods produce rounder, more organic masses.
