<<<ADA_BUNDLE>>>
sequence: proceduralgeneration
file: technical.md
maps: 7
skipped_passing: 0
created: 2026-04-24T00:20:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: PG_Genetic_Evolution>>>
# PG Genetic Evolution — Technical

The map runs a genetic programming system on creature body plans. Each creature has a genome encoding limb count, joint positions, and behavioural weights. The fitness function rewards distance travelled in the arena within a time budget. The selection loop produces offspring whose fitness is expected to improve across generations.

```gdscript
class_name GeneticProgrammer extends Node

@export var population_size: int = 32
@export var mutation_rate: float = 0.1
@export var elitism: int = 4

var genomes: Array = []
var fitnesses: Array = []

func _ready() -> void:
    for i in range(population_size):
        genomes.append(random_genome())

func evaluate() -> void:
    fitnesses.clear()
    for g in genomes:
        var creature = spawn_creature(g)
        var start := creature.global_position
        await get_tree().create_timer(trial_duration).timeout
        fitnesses.append(start.distance_to(creature.global_position))
        creature.queue_free()

func next_generation() -> void:
    var sorted := zip(genomes, fitnesses)
    sorted.sort_custom(func(a, b): return a[1] > b[1])
    var new_pop: Array = []
    for i in range(elitism):
        new_pop.append(sorted[i][0])
    while new_pop.size() < population_size:
        var parents := tournament_select(sorted, 3)
        var child := crossover(parents[0], parents[1])
        mutate(child)
        new_pop.append(child)
    genomes = new_pop
```

## Tournament Selection

Tournament selection picks K random genomes and returns the best. Larger tournaments produce stronger selection pressure; smaller tournaments preserve diversity. The map uses K=3, a common default.

```gdscript
func tournament_select(sorted: Array, k: int) -> Array:
    var contestants: Array = []
    for _i in range(k):
        contestants.append(sorted[randi() % sorted.size()])
    contestants.sort_custom(func(a, b): return a[1] > b[1])
    return [contestants[0][0], contestants[1][0]]
```

## Complexity

Each generation requires running the whole population through the arena. Population size P times trial duration T gives O(P·T) physics ticks per generation. For P=32 and T=600 ticks (10 seconds at 60Hz), that is 19,200 ticks per generation — about five seconds at real time, or much faster if the simulation runs headless at accelerated rates.

The map runs in real time for pedagogy: the learner watches the population improve generation by generation. Production applications run the simulation as fast as the CPU allows.

## Convergence and Local Optima

Genetic algorithms can converge prematurely to a local optimum when the population's diversity drops below a critical threshold. Once every genome looks alike, crossover produces offspring that are indistinguishable from their parents, and mutation is the only source of variation. Mutation alone is slow. The remedy is to preserve diversity — via tournament selection with smaller K, higher mutation rates, or explicit diversity bonuses.

Within the sequence, Genetic_Evolution opens Procedural Generation with evolution as the first generative strategy. PG_Space_Colonization will next use spatial hunger as a different generative principle.

<<<MAP: PG_Space_Colonization>>>
# PG Space Colonization — Technical

The space colonisation algorithm grows a branching structure by letting branch tips reach toward scattered attractor points. Each tip consumes attractors within a kill radius, and new tips sprout from the growing branches.

```gdscript
class_name SpaceColonizer extends Node3D

@export var attractor_count: int = 200
@export var attraction_radius: float = 3.0
@export var kill_radius: float = 0.5
@export var step_length: float = 0.2

var attractors: Array = []
var nodes: Array = []  # list of {position, parent_index}

func _ready() -> void:
    for i in range(attractor_count):
        attractors.append(random_point_in_bounds())
    nodes.append({"position": Vector3.ZERO, "parent_index": -1})

func grow_step() -> bool:
    var tip_influences: Dictionary = {}
    var nodes_to_kill_attractors: Array = []
    for i in range(attractors.size() - 1, -1, -1):
        var a: Vector3 = attractors[i]
        var best_tip: int = -1
        var best_dist: float = attraction_radius
        for j in range(nodes.size()):
            var d := a.distance_to(nodes[j].position)
            if d < best_dist:
                best_dist = d; best_tip = j
            if d < kill_radius:
                attractors.remove_at(i); break
        if best_tip != -1:
            tip_influences.get_or_add(best_tip, Vector3.ZERO)
            tip_influences[best_tip] += (a - nodes[best_tip].position).normalized()
    if tip_influences.is_empty():
        return false  # terminated
    for tip_index in tip_influences:
        var direction = tip_influences[tip_index].normalized()
        var new_pos: Vector3 = nodes[tip_index].position + direction * step_length
        nodes.append({"position": new_pos, "parent_index": tip_index})
    return true
```

## Complexity

Each step is O(A·N) where A is the attractor count and N is the branch node count. A grows shorter as attractors are consumed; N grows longer as branches extend. The product tends toward a peak in the middle of the growth and decreases as the algorithm terminates.

Spatial indexing accelerates the inner loop. A KD-tree reduces the nearest-tip query from O(N) to O(log N), which matters when N reaches hundreds of nodes. The map's tree scales use 200 attractors and produce a few hundred nodes; naive O(A·N) runs at interactive rates.

## Termination

The algorithm terminates when no attractor is within attraction_radius of any tip. Bounded attractor regions produce bounded trees; unbounded regions produce trees that keep growing. The map uses a bounded region so the tree finishes in a predictable number of steps.

## Mesh Generation

Converting the branch skeleton to a mesh is a separate step. Generalised cylinders — a tube whose radius varies along the branch — are the standard approach. Radius can be a function of child-branch count (thicker at the trunk, thinner at the leaves) or a function of accumulated flow from the root.

Within the sequence, Space_Colonization grows a tree without an L-system grammar. The environment's geometry — where the attractors happen to be — determines the tree's shape. PG_Percolation_Network will next turn to connectivity as a different generative phenomenon.

<<<MAP: PG_Percolation_Network>>>
# PG Percolation Network — Technical

Percolation stages the phase transition at which a random grid suddenly becomes connected. Each cell is occupied with probability p, and the algorithm finds the largest connected cluster.

```gdscript
class_name PercolationGrid extends Node3D

@export var grid_size: Vector2i = Vector2i(64, 64)
@export var probability: float = 0.5

var cells: Array = []  # 2D array of bool
var cluster_ids: Array = []  # 2D array of int

func _ready() -> void:
    regenerate()

func regenerate() -> void:
    cells.clear()
    for y in range(grid_size.y):
        var row: Array = []
        for x in range(grid_size.x):
            row.append(randf() < probability)
        cells.append(row)
    find_clusters()

func find_clusters() -> void:
    cluster_ids = []
    for y in range(grid_size.y):
        cluster_ids.append([])
        for x in range(grid_size.x):
            cluster_ids[y].append(-1)
    var next_id := 0
    for y in range(grid_size.y):
        for x in range(grid_size.x):
            if cells[y][x] and cluster_ids[y][x] == -1:
                flood_fill(x, y, next_id)
                next_id += 1
```

## Flood Fill

The cluster-finding routine uses iterative flood fill with a queue. Each cell is visited at most once; the total cost is O(W·H) per regeneration.

```gdscript
func flood_fill(x0: int, y0: int, id: int) -> void:
    var queue: Array = [Vector2i(x0, y0)]
    while not queue.is_empty():
        var p = queue.pop_back()
        if p.x < 0 or p.x >= grid_size.x or p.y < 0 or p.y >= grid_size.y:
            continue
        if not cells[p.y][p.x] or cluster_ids[p.y][p.x] != -1:
            continue
        cluster_ids[p.y][p.x] = id
        queue.append(p + Vector2i(1, 0))
        queue.append(p + Vector2i(-1, 0))
        queue.append(p + Vector2i(0, 1))
        queue.append(p + Vector2i(0, -1))
```

## The Critical Threshold

For site percolation on a 2D square lattice, the critical probability p_c is approximately 0.5927. Below this value, only small clusters form. Above, a spanning cluster almost surely exists. The transition is sharp: at p = p_c − 0.05, clusters are all small; at p = p_c + 0.05, one cluster spans the grid.

The scaling laws near p_c are universal: the largest cluster's mass scales as a power law in (p − p_c) with a critical exponent that depends only on the lattice dimension, not on the specific lattice. This is the source of percolation theory's broad applicability — the same universal exponents appear in fluid flow through porous media, epidemic spread, and network reliability.

## Bond vs Site

The map uses site percolation. Bond percolation occupies edges rather than vertices, producing a slightly different critical threshold (0.5 on 2D square lattices) and the same universal scaling exponents. The choice depends on the phenomenon being modelled — rock porosity is a site problem; electrical network reliability is a bond problem.

Within the sequence, Percolation is the connectivity chapter. PG_Branching_Growth will next compare rule-based and noise-driven growth as alternative generative strategies.

<<<MAP: PG_Branching_Growth>>>
# PG Branching Growth — Technical

The map stages two branching strategies side by side. On the rule side, a deterministic recursion grows a tree by repeated bifurcation. On the noise side, growth follows 3D Perlin field lines through a volumetric noise function.

```gdscript
class_name RuleBasedBranch extends Node3D

@export var branch_angle: float = 25.0  # degrees
@export var length_scale: float = 0.7
@export var max_depth: int = 6

func grow(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth >= max_depth:
        return
    var end := start + direction * length
    draw_segment(start, end)
    var axis := direction.cross(Vector3.UP).normalized()
    var left := direction.rotated(axis, deg_to_rad(branch_angle))
    var right := direction.rotated(axis, deg_to_rad(-branch_angle))
    grow(end, left, length * length_scale, depth + 1)
    grow(end, right, length * length_scale, depth + 1)
```

## Noise-Driven Growth

```gdscript
class_name NoiseFieldGrowth extends Node3D

@export var noise_scale: float = 0.3
@export var step_size: float = 0.1

var noise := FastNoiseLite.new()

func grow_step(start: Vector3) -> Vector3:
    # Compute gradient of the noise field numerically
    var h := 0.01
    var dx := noise.get_noise_3dv(start + Vector3(h, 0, 0)) - noise.get_noise_3dv(start - Vector3(h, 0, 0))
    var dy := noise.get_noise_3dv(start + Vector3(0, h, 0)) - noise.get_noise_3dv(start - Vector3(0, h, 0))
    var dz := noise.get_noise_3dv(start + Vector3(0, 0, h)) - noise.get_noise_3dv(start - Vector3(0, 0, h))
    var gradient := Vector3(dx, dy, dz).normalized()
    return start + gradient * step_size
```

## Complexity

The rule-based branch at depth D produces 2^D leaf segments; the total segment count is 2^(D+1) − 1. For D=6 that is 127 segments. Time and space are both O(2^D). Beyond D=15 the structure becomes unrenderable.

Noise-driven growth is O(N·S) for N paths and S steps per path. The noise lookup dominates; a good noise implementation (hashed or precomputed lookup table) runs at nanoseconds per sample.

## Comparison

Rule-based branching is repeatable and controllable: given the same parameters, the tree is identical. Noise-driven growth is reproducible with a fixed seed but looks organic because the field's irregularities propagate into the path. The map displays both side by side and exposes their parameter knobs so the learner can see how each strategy reaches a similar final shape through different means.

## Self-Avoidance

Neither algorithm above avoids self-intersection. Real botanical growth has mechanisms to prevent branches from overlapping — apical dominance, growth hormones, physical contact. Procedural implementations add self-avoidance through repulsion from existing branches, which makes the output more realistic but also more expensive to compute.

Within the sequence, Branching_Growth is the comparison chapter. PG_Caves_Mazes will next pivot from additive to subtractive generation.

<<<MAP: PG_Caves_Mazes>>>
# PG Caves Mazes — Technical

The map stages two subtractive strategies side by side. A cellular automaton carves caves; a spanning-tree algorithm builds mazes. Both hollow space from a solid block, but the character of each is opposite.

```gdscript
class_name CaveGenerator extends Node3D

@export var size: Vector2i = Vector2i(64, 64)
@export var fill_probability: float = 0.45
@export var smooth_iterations: int = 5

var cells: Array = []  # true = wall, false = floor

func generate() -> void:
    cells = []
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            row.append(randf() < fill_probability)
        cells.append(row)
    for _i in range(smooth_iterations):
        smooth_step()

func smooth_step() -> void:
    var new_cells: Array = []
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            var neighbours := count_wall_neighbours(x, y)
            if neighbours >= 5:
                row.append(true)
            elif neighbours <= 3:
                row.append(false)
            else:
                row.append(cells[y][x])
        new_cells.append(row)
    cells = new_cells
```

## The Cellular Automaton Rule

The "5-4 rule" — become a wall if 5 or more neighbours are walls, become floor if 4 or fewer — is a common choice for cave generation. It produces organic-looking cavities with connected passages. Different rules produce different cave characters: the "4-5 rule" makes more open spaces; the "6-3 rule" produces claustrophobic tunnels.

## Maze Generation

Mazes use a different approach: partition the space into a grid, then carve walls to form a spanning tree. Recursive backtracking is the simplest algorithm.

```gdscript
class_name RecursiveBacktracker extends Node

var visited: Dictionary = {}
var walls_carved: Array = []

func generate(start: Vector2i) -> void:
    var stack: Array = [start]
    visited[start] = true
    while not stack.is_empty():
        var current = stack[-1]
        var unvisited_neighbours := get_unvisited_neighbours(current)
        if unvisited_neighbours.is_empty():
            stack.pop_back()
        else:
            var next = unvisited_neighbours[randi() % unvisited_neighbours.size()]
            walls_carved.append([current, next])
            visited[next] = true
            stack.append(next)
```

The output is always a connected maze with exactly one path between any two cells, because a spanning tree has this property by definition.

## Kruskal's Maze

Kruskal's algorithm produces different maze textures — more uniform, less snake-like. It shuffles all walls, then removes walls whose two sides belong to different connected components, merging the components in the process. The algorithm is O((WH) · α(WH)) where α is the inverse Ackermann function (effectively constant).

## Comparison

Caves feel natural because the generator has no plan — the walker staggers and the cave forms around the walker's path. Mazes feel engineered because the generator has exactly one plan — connect everything once and no more. The map displays both outcomes on either side of a central wall and lets the learner walk through each to feel the difference.

Within the sequence, Caves_Mazes is the subtractive chapter. PG_Sculpted_Forms will next return to additive strategies through stacking rather than branching.

<<<MAP: PG_Sculpted_Forms>>>
# PG Sculpted Forms — Technical

The map stages accumulation as a generative strategy. Three stations demonstrate piling, arcing, and laminating — additive operations that produce architectural form.

The mound station drops cubes and lets them settle. Each cube is a RigidBody3D subject to gravity. Collisions with the existing pile determine the final resting position.

```gdscript
class_name Mound extends Node3D

@export var drop_height: float = 10.0
@export var drop_radius: float = 0.5
@export var drop_rate: float = 5.0  # cubes per second

var time_since_drop: float = 0.0

func _process(delta: float) -> void:
    time_since_drop += delta
    if time_since_drop > 1.0 / drop_rate:
        time_since_drop = 0.0
        drop_cube()

func drop_cube() -> void:
    var cube: RigidBody3D = CUBE_SCENE.instantiate()
    cube.position = Vector3(randf_range(-drop_radius, drop_radius), drop_height, randf_range(-drop_radius, drop_radius))
    add_child(cube)
```

## Dome Construction

The dome station places segments along a parametric arc. Each segment is an angular step from the last; the cumulative angular steps sweep out the dome's profile.

```gdscript
class_name Dome extends Node3D

@export var radius: float = 3.0
@export var angular_step: float = 15.0  # degrees
@export var ring_count: int = 8

func _ready() -> void:
    for ring in range(ring_count):
        var ring_angle: float = ring * (180.0 / ring_count)  # latitude
        var ring_radius: float = radius * sin(deg_to_rad(ring_angle))
        var ring_height: float = radius * cos(deg_to_rad(ring_angle))
        var steps_in_ring: int = max(1, int(360.0 / angular_step))
        for step in range(steps_in_ring):
            var longitude: float = step * angular_step
            var pos := Vector3(
                ring_radius * cos(deg_to_rad(longitude)),
                ring_height,
                ring_radius * sin(deg_to_rad(longitude))
            )
            place_segment(pos)
```

## Membrane Lamination

The membrane station layers thin curved surfaces. Each layer is an offset surface whose offset distance is a small fraction of the base layer's feature size. Stacking layers produces a thick, curved volume whose internal structure can be revealed by cross-sectioning.

```gdscript
func laminate(base_mesh: ArrayMesh, layer_count: int, offset: float) -> ArrayMesh:
    var result := ArrayMesh.new()
    for i in range(layer_count):
        var vertices = base_mesh.surface_get_arrays(0)[0]
        var normals = base_mesh.surface_get_arrays(0)[1]
        var offset_vertices: PackedVector3Array = []
        for j in range(vertices.size()):
            offset_vertices.append(vertices[j] + normals[j] * offset * i)
        # Add layer to result mesh
    return result
```

## Complexity

Mound simulation is O(C·F) for C cubes and F physics frames. At a drop rate of 5 cubes/second and 60 Hz physics, that is 12 cube additions per second and about 60 physics ticks per second over all existing cubes. Performance degrades as the mound grows; at ~200 cubes the simulation becomes noticeably sluggish.

Dome construction is O(ring_count · steps_per_ring) — a pure geometric operation with no simulation. The map uses 8 rings and ~24 segments per ring, giving about 192 segments per dome.

Within the sequence, Sculpted_Forms is the architectural chapter. PG_Mirrored_Patterns will next close the sequence with symmetry-amplified patterns and rhizomatic mazes.

<<<MAP: PG_Mirrored_Patterns>>>
# PG Mirrored Patterns — Technical

The map combines cellular automata with mirror symmetry to produce kaleidoscopic textures. A base CA runs on the left half of the grid; the right half mirrors the left after each generation.

```gdscript
class_name MirroredCA extends Node3D

@export var size: Vector2i = Vector2i(64, 64)
var cells: Array = []

func _ready() -> void:
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            row.append(randi() % 2)
        cells.append(row)

func step() -> void:
    var half_width := size.x / 2
    var new_cells: Array = []
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            if x < half_width:
                row.append(ca_rule(x, y))
            else:
                # Mirror from the left half
                row.append(0)  # placeholder, filled in second pass
        new_cells.append(row)
    for y in range(size.y):
        for x in range(half_width, size.x):
            new_cells[y][x] = new_cells[y][size.x - 1 - x]
    cells = new_cells
```

## Symmetry Groups

The wallpaper groups — 17 distinct 2D symmetry groups — classify every possible periodic 2D pattern. The map stages a subset: p1 (translation only), p2 (translation plus 180° rotation), p4m (4-fold rotation plus mirror), p6m (6-fold rotation plus mirror). The CA output is transformed by the chosen group to produce the final pattern.

```gdscript
func apply_p4m(cells: Array) -> Array:
    var size = cells.size()
    var out: Array = []
    for y in range(size):
        out.append([])
        for x in range(size):
            out[y].append(0)
    for y in range(size / 2):
        for x in range(size / 2):
            var v = cells[y][x]
            out[y][x] = v
            out[y][size - 1 - x] = v  # horizontal mirror
            out[size - 1 - y][x] = v  # vertical mirror
            out[size - 1 - y][size - 1 - x] = v  # 180° rotation
    return out
```

## Rhizomatic Mazes

The second station generates a rhizomatic maze — a maze without a canonical root, with multiple paths between cells, and with no privileged direction. The algorithm drops random seed cells and grows passages from each seed independently; where passages meet, they merge.

```gdscript
class_name RhizomaticMaze extends Node

@export var seed_count: int = 8
@export var max_growth: int = 500

var passages: Dictionary = {}  # cell -> set of adjacent open cells

func generate() -> void:
    var seeds: Array = []
    for _i in range(seed_count):
        seeds.append(random_cell())
        passages[seeds[-1]] = {}
    var active := seeds.duplicate()
    var growth_count := 0
    while not active.is_empty() and growth_count < max_growth:
        var cell = active[randi() % active.size()]
        var neighbours := random_unclaimed_neighbours(cell)
        if neighbours.is_empty():
            active.erase(cell)
            continue
        var next = neighbours[randi() % neighbours.size()]
        connect_cells(cell, next)
        active.append(next)
        growth_count += 1
```

## Complexity

The symmetric CA is O(N²) per generation for an N×N grid. The rhizomatic maze is O(growth_count) per generation — essentially linear in the number of cells carved. Both are interactive at the grid sizes the map uses (typically 64×64).

Within the sequence, Mirrored_Patterns closes Procedural Generation with the argument that symmetry and rhizomatic growth are two tools that produce structure without authored design. The sequence hands the learner forward with a generative vocabulary that spans evolution, connectivity, growth, subtraction, accumulation, and symmetry.

<<<MAP: Chamber_ProcGen>>>
# Chamber ProcGen — Technical

The chamber hosts a bricoleur_golem whose body is assembled from nearby debris fragments. Each strike knocks pieces off; the golem retrieves them and reassembles into a new configuration.

```gdscript
class_name BricoleurGolem extends CharacterBody3D

var body_parts: Array = []  # list of part nodes currently attached
var detached: Array = []  # list of fragments lying on the floor
@export var reassemble_interval: float = 2.0

var time_since_reassemble: float = 0.0

func _physics_process(delta: float) -> void:
    time_since_reassemble += delta
    if time_since_reassemble > reassemble_interval and not detached.is_empty():
        reassemble()
        time_since_reassemble = 0.0

func on_struck(part: Node3D, force: Vector3) -> void:
    body_parts.erase(part)
    part.freeze = false
    part.apply_impulse(force, Vector3.ZERO)
    detached.append(part)

func reassemble() -> void:
    # Find a fragment nearby to pick up
    var candidates: Array = detached.filter(func(p): return global_position.distance_to(p.global_position) < 3.0)
    if candidates.is_empty():
        return
    var fragment = candidates[randi() % candidates.size()]
    detached.erase(fragment)
    attach_fragment(fragment)

func attach_fragment(fragment: Node3D) -> void:
    fragment.freeze = true
    fragment.reparent(self)
    var attachment_point: Vector3 = choose_attachment_point()
    fragment.position = attachment_point
    body_parts.append(fragment)
```

## Attachment Logic

The attachment-point selection determines the golem's evolving morphology. A naive random attachment produces incoherent body plans. A biased attachment — preferring positions that preserve locomotion — produces bodies that keep working.

```gdscript
func choose_attachment_point() -> Vector3:
    var existing_positions: Array = body_parts.map(func(p): return p.position)
    if existing_positions.is_empty():
        return Vector3.ZERO
    var centroid: Vector3 = Vector3.ZERO
    for p in existing_positions:
        centroid += p
    centroid /= existing_positions.size()
    var candidate: Vector3 = centroid + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
    return candidate
```

## Targeting Influence

The learner's strikes shape which body parts the golem rebuilds. Tracking which parts are struck most often biases the reassembly toward replacing those parts with variants. Over time, the golem adapts to the learner's attack patterns.

```gdscript
var part_strike_count: Dictionary = {}  # part_type -> strike count

func on_struck(part: Node3D, force: Vector3) -> void:
    super(part, force)
    var type = part.get_meta("part_type")
    part_strike_count[type] = part_strike_count.get(type, 0) + 1

func priority_for_type(type: String) -> float:
    return 1.0 + part_strike_count.get(type, 0) * 0.1
```

## Science Screen

The wall display renders the golem's current body as a graph of connected parts. Nodes are parts; edges are attachment relationships. The graph mutates with each strike and reassembly, and the screen shows the mutation as an animated topology.

## Complexity

Body reassembly is O(D) per cycle, where D is the number of detached fragments. Attachment-point selection is O(B) for B currently attached parts. Neither is a bottleneck at the small scales the chamber operates on (typically ~12 parts and ~6 detached fragments at any time).

Within the sequence, Chamber_ProcGen closes Procedural Generation by converting the sequence's generative thesis into a creaturely practice. Destruction feeds reconstruction; the golem is always in process; the assembly never reaches a finished form.
