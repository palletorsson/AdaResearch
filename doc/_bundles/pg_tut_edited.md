<<<ADA_BUNDLE>>>
sequence: proceduralgeneration
file: tutorial.md
maps: 8
skipped_passing: 0
created: 2026-04-24T04:00:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: PG_Genetic_Evolution>>>
# PG Genetic Evolution

Creatures evolve by selection. Body plans as genomes.

Encode a body plan.

```gdscript
class_name BodyPlan

var limb_count: int = 4
var limb_positions: Array = []  # Vector3 per limb
var behavior_weights: Array = []  # float per behaviour
```

The plan is the genome. Its fields determine the creature's morphology and behaviour.

Random body plan.

```gdscript
func random_body() -> BodyPlan:
    var body := BodyPlan.new()
    body.limb_count = randi_range(2, 6)
    for _i in body.limb_count:
        body.limb_positions.append(Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)))
    for _i in 8:
        body.behavior_weights.append(randf_range(-1, 1))
    return body
```

Random within bounds. The population starts with diverse configurations.

Spawn the creature.

```gdscript
func spawn_creature(body: BodyPlan) -> CharacterBody3D:
    var creature := CREATURE_SCENE.instantiate()
    for pos in body.limb_positions:
        var limb := LIMB_SCENE.instantiate()
        limb.position = pos
        creature.add_child(limb)
    creature.set_behavior_weights(body.behavior_weights)
    add_child(creature)
    return creature
```

Assemble the creature from its body plan. Each limb is a child; the weights drive the behaviour script.

Evaluate fitness.

```gdscript
func evaluate(body: BodyPlan) -> float:
    var creature := spawn_creature(body)
    var start := creature.global_position
    await get_tree().create_timer(10.0).timeout
    var fitness: float = start.distance_to(creature.global_position)
    creature.queue_free()
    return fitness
```

Run for 10 seconds. Fitness is total distance from starting position.

Tournament selection.

```gdscript
func tournament(population: Array, k: int = 3) -> BodyPlan:
    var contestants: Array = []
    for _i in k:
        contestants.append(population[randi() % population.size()])
    contestants.sort_custom(func(a, b): return a.fitness > b.fitness)
    return contestants[0]
```

K random candidates; best wins. Returns the plan, not its fitness.

Crossover two body plans.

```gdscript
func crossover(a: BodyPlan, b: BodyPlan) -> BodyPlan:
    var child := BodyPlan.new()
    child.limb_count = a.limb_count if randf() < 0.5 else b.limb_count
    for i in child.limb_count:
        var parent := a if randf() < 0.5 else b
        child.limb_positions.append(parent.limb_positions[i % parent.limb_positions.size()])
    for i in a.behavior_weights.size():
        child.behavior_weights.append(a.behavior_weights[i] if randf() < 0.5 else b.behavior_weights[i])
    return child
```

Mix-and-match fields between parents. The child inherits a combination.

Mutate a body plan.

```gdscript
func mutate(body: BodyPlan, rate: float = 0.15) -> void:
    for i in body.limb_positions.size():
        if randf() < rate:
            body.limb_positions[i] += Vector3(randfn(0, 0.1), randfn(0, 0.1), randfn(0, 0.1))
    for i in body.behavior_weights.size():
        if randf() < rate:
            body.behavior_weights[i] += randfn(0, 0.1)
            body.behavior_weights[i] = clamp(body.behavior_weights[i], -1, 1)
```

Each field may mutate by Gaussian noise. Rate controls how many mutations per offspring.

You can now encode body plans as genomes, spawn creatures, evaluate fitness, and run a selection-crossover-mutation loop. PG_Space_Colonization extends into tree growth toward attractors.

<<<MAP: PG_Space_Colonization>>>
# PG Space Colonization

Trees reach for attractors. Branches extend where sunlight is.

Scatter attractors.

```gdscript
func scatter_attractors(count: int, bounds: AABB) -> Array:
    var attractors: Array = []
    for _i in count:
        var p := Vector3(
            randf_range(bounds.position.x, bounds.end.x),
            randf_range(bounds.position.y, bounds.end.y),
            randf_range(bounds.position.z, bounds.end.z)
        )
        attractors.append(p)
    return attractors
```

Points in a volume. Each attractor is a consumable target.

Seed a tree.

```gdscript
class_name SpaceColonizationTree extends Node3D

var nodes: Array = [Vector3.ZERO]  # node positions
var parents: Array = [-1]  # index of parent node, -1 for root
var attractors: Array = []
```

Starts with one node (the root). Grows by adding nodes influenced by attractors.

Find the closest node to each attractor.

```gdscript
func closest_node(attractor: Vector3) -> int:
    var best: int = -1
    var best_dist: float = INF
    for i in nodes.size():
        var d: float = nodes[i].distance_to(attractor)
        if d < best_dist:
            best_dist = d; best = i
    return best
```

Each attractor influences one node — the nearest. Per-attractor cost is O(N).

Grow one step.

```gdscript
@export var influence_radius: float = 2.0
@export var kill_radius: float = 0.3
@export var step_length: float = 0.3

func grow_step() -> bool:
    var influences: Dictionary = {}  # node_index -> average direction
    var kept_attractors: Array = []
    for a in attractors:
        var closest := closest_node(a)
        if closest < 0 or nodes[closest].distance_to(a) > influence_radius:
            kept_attractors.append(a)
            continue
        if nodes[closest].distance_to(a) < kill_radius:
            continue  # consumed
        influences.get_or_add(closest, Vector3.ZERO)
        influences[closest] += (a - nodes[closest]).normalized()
        kept_attractors.append(a)
    attractors = kept_attractors
    if influences.is_empty(): return false
    for node_index in influences:
        var direction: Vector3 = influences[node_index].normalized()
        nodes.append(nodes[node_index] + direction * step_length)
        parents.append(node_index)
    return true
```

Sum influences per node; add a child in the averaged direction. Attractors within kill_radius are consumed.

Render the tree.

```gdscript
func render_tree() -> void:
    for i in nodes.size():
        if parents[i] < 0: continue
        spawn_cylinder_between(nodes[parents[i]], nodes[i])
```

One cylinder per edge. Cheap to render; tree-like structure emerges.

Render with tapered radius.

```gdscript
func node_subtree_size(i: int) -> int:
    var count: int = 1
    for j in parents.size():
        if parents[j] == i:
            count += node_subtree_size(j)
    return count
```

Larger subtree means thicker trunk. Used as an input to the cylinder's radius.

You can now scatter attractors, grow a tree toward them, consume reached attractors, and render the result with tapered branches. PG_Percolation_Network extends into random connectivity.

<<<MAP: PG_Percolation_Network>>>
# PG Percolation Network

Random grid. At the threshold, a spanning cluster forms.

Generate a random grid.

```gdscript
const GRID_SIZE := Vector2i(64, 64)

func generate_grid(probability: float) -> Array:
    var grid: Array = []
    for y in GRID_SIZE.y:
        var row: Array = []
        for x in GRID_SIZE.x:
            row.append(randf() < probability)
        grid.append(row)
    return grid
```

Each cell occupied with the given probability. The grid is 2D boolean.

Find clusters via flood fill.

```gdscript
func find_clusters(grid: Array) -> Array:
    var cluster_id: Array = []
    for y in GRID_SIZE.y:
        cluster_id.append([])
        for x in GRID_SIZE.x:
            cluster_id[y].append(-1)
    var next_id: int = 0
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            if grid[y][x] and cluster_id[y][x] < 0:
                flood_fill(grid, cluster_id, x, y, next_id)
                next_id += 1
    return cluster_id
```

Each cluster gets a unique ID. Unoccupied cells stay at -1.

Flood-fill one cluster.

```gdscript
func flood_fill(grid: Array, cluster_id: Array, x0: int, y0: int, id: int) -> void:
    var stack: Array = [[x0, y0]]
    while not stack.is_empty():
        var p = stack.pop_back()
        if p[0] < 0 or p[0] >= GRID_SIZE.x: continue
        if p[1] < 0 or p[1] >= GRID_SIZE.y: continue
        if not grid[p[1]][p[0]] or cluster_id[p[1]][p[0]] >= 0: continue
        cluster_id[p[1]][p[0]] = id
        stack.append([p[0] + 1, p[1]])
        stack.append([p[0] - 1, p[1]])
        stack.append([p[0], p[1] + 1])
        stack.append([p[0], p[1] - 1])
    # Iterative to avoid stack overflow on large clusters
```

Iterative flood fill. Each cell is visited at most once.

Test for spanning cluster.

```gdscript
func has_spanning_cluster(cluster_id: Array) -> bool:
    var top_clusters: Dictionary = {}
    for x in GRID_SIZE.x:
        if cluster_id[0][x] >= 0:
            top_clusters[cluster_id[0][x]] = true
    for x in GRID_SIZE.x:
        if cluster_id[GRID_SIZE.y - 1][x] in top_clusters:
            return true
    return false
```

Spanning means a cluster touches both the top row and the bottom row. Probabilities around 0.59 are the threshold for 2D square site percolation.

Colour cells by cluster.

```gdscript
func colour_clusters(cluster_id: Array) -> void:
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            if cluster_id[y][x] >= 0:
                var hue: float = float(cluster_id[y][x] * 31 % 100) / 100.0
                paint_cell(x, y, Color.from_hsv(hue, 0.8, 0.9))
```

Each cluster a different hue. Spanning clusters are visible because they reach across the grid.

Animate the threshold sweep.

```gdscript
func animate_threshold(start_p: float, end_p: float, steps: int) -> void:
    for i in steps:
        var p: float = lerp(start_p, end_p, float(i) / steps)
        var grid: Array = generate_grid(p)
        var cluster_id: Array = find_clusters(grid)
        colour_clusters(cluster_id)
        await get_tree().create_timer(0.2).timeout
```

Sweep p from start to end. The spanning threshold appears as a visible phase transition.

You can now generate a random grid, find clusters via flood fill, detect spanning clusters, colour them, and animate the threshold sweep. PG_Branching_Growth extends into rule-based vs noise-driven branching.

<<<MAP: PG_Branching_Growth>>>
# PG Branching Growth

Two branching strategies. Rules versus noise.

Rule-based recursive branching.

```gdscript
func recursive_branch(start: Vector3, direction: Vector3, length: float, depth: int) -> void:
    if depth <= 0: return
    var end := start + direction * length
    spawn_cylinder_between(start, end)
    var axis: Vector3 = direction.cross(Vector3.UP).normalized()
    var left: Vector3 = direction.rotated(axis, deg_to_rad(25))
    var right: Vector3 = direction.rotated(axis, deg_to_rad(-25))
    recursive_branch(end, left, length * 0.7, depth - 1)
    recursive_branch(end, right, length * 0.7, depth - 1)
```

Classic binary branching. Each call spawns two children at fixed angles.

Noise-driven growth.

```gdscript
var noise := FastNoiseLite.new()

func noise_grow_step(position: Vector3, step: float = 0.1) -> Vector3:
    var h: float = 0.01
    var dx: float = noise.get_noise_3dv(position + Vector3(h, 0, 0)) - noise.get_noise_3dv(position - Vector3(h, 0, 0))
    var dy: float = noise.get_noise_3dv(position + Vector3(0, h, 0)) - noise.get_noise_3dv(position - Vector3(0, h, 0))
    var dz: float = noise.get_noise_3dv(position + Vector3(0, 0, h)) - noise.get_noise_3dv(position - Vector3(0, 0, h))
    return position + Vector3(dx, dy, dz).normalized() * step
```

Gradient of a noise field. The path follows the local gradient direction.

Grow a noise path.

```gdscript
func grow_noise_path(start: Vector3, steps: int) -> Array:
    var path: Array = [start]
    var current := start
    for _i in steps:
        current = noise_grow_step(current)
        path.append(current)
    return path
```

Each step advances along the gradient. The path is organic-looking.

Render a path as cylinders.

```gdscript
func render_path(path: Array) -> void:
    for i in range(path.size() - 1):
        spawn_cylinder_between(path[i], path[i + 1])
```

One cylinder per segment. The path becomes a single connected curve.

Branch from a path.

```gdscript
func branch_from_path(path: Array, branches_per_node: int = 2, branch_length: int = 20) -> void:
    for i in range(0, path.size(), 4):  # every 4 nodes
        for _b in branches_per_node:
            var branch_direction := Vector3(randfn(0, 1), randfn(0, 1), randfn(0, 1)).normalized()
            var branch := grow_noise_path(path[i], branch_length)
            render_path(branch)
```

Every four nodes spawn additional branches. Creates a tree-like structure from noise-driven growth.

Compare side by side.

```gdscript
func compare_methods() -> void:
    recursive_branch(Vector3(-3, 0, 0), Vector3.UP, 1.0, 6)
    var noise_path := grow_noise_path(Vector3(3, 0, 0), 100)
    render_path(noise_path)
    branch_from_path(noise_path)
```

Rule-based on the left, noise-driven on the right. The visual difference is striking.

You can now recursive-branch, noise-gradient-step, grow organic paths, branch from a path, and compare the two strategies side by side. PG_Caves_Mazes extends into subtractive generation.

<<<MAP: PG_Caves_Mazes>>>
# PG Caves Mazes

Carve spaces. Two methods. Cave via CA; maze via spanning tree.

Generate a CA-based cave.

```gdscript
func generate_cave(size: Vector2i, fill_prob: float = 0.45, iterations: int = 5) -> Array:
    var grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            row.append(randf() < fill_prob)
        grid.append(row)
    for _i in iterations:
        grid = smooth_step(grid, size)
    return grid
```

Start with random fill; smooth via cellular automaton rules.

Smooth one step.

```gdscript
func smooth_step(grid: Array, size: Vector2i) -> Array:
    var new_grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            var neighbour_count: int = count_wall_neighbours(grid, x, y, size)
            if neighbour_count >= 5:
                row.append(true)
            elif neighbour_count <= 3:
                row.append(false)
            else:
                row.append(grid[y][x])
        new_grid.append(row)
    return new_grid
```

Classic 5-4 rule. Cells with 5+ wall neighbours become walls; cells with 3 or fewer become open.

Count neighbours.

```gdscript
func count_wall_neighbours(grid: Array, x: int, y: int, size: Vector2i) -> int:
    var count: int = 0
    for dy in [-1, 0, 1]:
        for dx in [-1, 0, 1]:
            if dx == 0 and dy == 0: continue
            var nx: int = x + dx
            var ny: int = y + dy
            if nx < 0 or nx >= size.x or ny < 0 or ny >= size.y:
                count += 1  # treat out-of-bounds as wall
            elif grid[ny][nx]:
                count += 1
    return count
```

Eight neighbours. Boundary conditions treat off-grid as wall (so caves don't open at the edges).

Recursive backtracker maze.

```gdscript
func generate_maze(size: Vector2i) -> Array:
    var visited: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x: row.append(false)
        visited.append(row)
    var walls_carved: Array = []
    var stack: Array = [Vector2i(0, 0)]
    visited[0][0] = true
    while not stack.is_empty():
        var current: Vector2i = stack[-1]
        var neighbours := unvisited_neighbours(current, visited, size)
        if neighbours.is_empty():
            stack.pop_back()
        else:
            var next: Vector2i = neighbours[randi() % neighbours.size()]
            walls_carved.append([current, next])
            visited[next.y][next.x] = true
            stack.append(next)
    return walls_carved
```

Stack-based DFS. Carves a spanning tree; result is always a perfectly connected maze.

Render walls.

```gdscript
func render_walls(walls_carved: Array, size: Vector2i, scale: float = 1.0) -> void:
    for y in size.y:
        for x in size.x:
            for direction in [Vector2i(1, 0), Vector2i(0, 1)]:
                var neighbour := Vector2i(x, y) + direction
                if neighbour.x >= size.x or neighbour.y >= size.y: continue
                if not [Vector2i(x, y), neighbour] in walls_carved and not [neighbour, Vector2i(x, y)] in walls_carved:
                    spawn_wall_between(Vector2i(x, y), neighbour, scale)
```

Walls are edges not carved. Each uncarved edge becomes a visual wall.

Braid a maze.

```gdscript
func braid(walls_carved: Array, cells_with_few_connections: Array, probability: float = 0.3) -> void:
    for cell in cells_with_few_connections:
        if randf() < probability:
            var new_carve := pick_random_uncarved_neighbour(cell)
            if new_carve: walls_carved.append([cell, new_carve])
```

Removes some dead ends. Creates loops. Less punishing navigation.

You can now generate a CA-based cave, a spanning-tree maze, render walls, and braid the maze for loops. PG_Sculpted_Forms extends into additive architectural generation.

<<<MAP: PG_Sculpted_Forms>>>
# PG Sculpted Forms

Accumulation. Cubes pile; domes arc; membranes laminate.

Drop cubes to form a mound.

```gdscript
func drop_cube(drop_position: Vector3) -> RigidBody3D:
    var cube := RigidBody3D.new()
    var mesh := MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    cube.add_child(mesh)
    var shape := CollisionShape3D.new()
    shape.shape = BoxShape3D.new()
    cube.add_child(shape)
    cube.global_position = drop_position
    add_child(cube)
    return cube
```

RigidBody3D for physics. Gravity and collision handle the settling.

Rain cubes over time.

```gdscript
@export var drop_rate: float = 2.0

var time_since_drop: float = 0.0

func _process(delta: float) -> void:
    time_since_drop += delta
    if time_since_drop >= 1.0 / drop_rate:
        time_since_drop = 0.0
        drop_cube(Vector3(randf_range(-0.5, 0.5), 8.0, randf_range(-0.5, 0.5)))
```

Two cubes per second. The mound grows unevenly as cubes land on each other.

Build a dome segment.

```gdscript
func build_dome_segment(latitude: float, longitude: float, radius: float) -> MeshInstance3D:
    var segment := MeshInstance3D.new()
    segment.mesh = BoxMesh.new()
    segment.mesh.size = Vector3(0.2, 0.2, 0.2)
    var x: float = radius * sin(latitude) * cos(longitude)
    var y: float = radius * cos(latitude)
    var z: float = radius * sin(latitude) * sin(longitude)
    segment.position = Vector3(x, y, z)
    add_child(segment)
    return segment
```

Spherical coordinates. Each segment sits on the dome's surface.

Populate the dome.

```gdscript
@export var dome_ring_count: int = 8
@export var dome_radius: float = 3.0

func build_dome() -> void:
    for ring in dome_ring_count:
        var latitude: float = ring * PI / 2 / dome_ring_count  # 0 to PI/2
        var segments_in_ring: int = max(8, int(16 * sin(latitude)))
        for seg in segments_in_ring:
            var longitude: float = seg * TAU / segments_in_ring
            build_dome_segment(latitude, longitude, dome_radius)
```

Fewer segments near the top, more near the equator. Density adapts to the dome's curvature.

Build a membrane.

```gdscript
func build_membrane(width: float, height: float, layer_count: int, offset_per_layer: float) -> void:
    for layer in layer_count:
        var membrane := MeshInstance3D.new()
        membrane.mesh = QuadMesh.new()
        membrane.mesh.size = Vector2(width, height)
        membrane.position = Vector3(0, layer * offset_per_layer, 0)
        add_child(membrane)
```

Thin layers stacked. Each offset slightly; together they form a thick surface.

Curve the membranes.

```gdscript
func curve_membrane(membrane: MeshInstance3D, amplitude: float) -> void:
    var mesh: ArrayMesh = membrane.mesh
    var st := SurfaceTool.new()
    st.create_from(mesh, 0)
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # Displace vertices according to a sin curve
    # Full implementation omitted for brevity
```

Vertex displacement by a sinusoid. The flat quad becomes a curved sheet.

You can now drop cubes to form a mound, build a dome with spherical-coordinate segments, layer membranes with offsets, and curve them into sheets. PG_Mirrored_Patterns extends into symmetry-amplified generation.

<<<MAP: PG_Mirrored_Patterns>>>
# PG Mirrored Patterns

Mirror a cellular automaton. Symmetry amplifies pattern.

Run a 2D CA.

```gdscript
@export var size: Vector2i = Vector2i(64, 64)
var grid: Array = []

func initialise() -> void:
    grid.clear()
    for y in size.y:
        var row: Array = []
        for x in size.x:
            row.append(randi_range(0, 1))
        grid.append(row)
```

Start with random binary values. Subsequent updates depend on the CA rule.

Apply a simple rule.

```gdscript
func ca_step() -> void:
    var new_grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            var count: int = neighbour_count(x, y)
            var alive: bool = grid[y][x] == 1
            var new_state: int = 0
            if alive and (count == 2 or count == 3): new_state = 1
            elif not alive and count == 3: new_state = 1
            row.append(new_state)
        new_grid.append(row)
    grid = new_grid
```

Conway's Game of Life rules. Could be replaced by any CA.

Mirror horizontally.

```gdscript
func mirror_horizontal() -> void:
    var half: int = size.x / 2
    for y in size.y:
        for x in range(half):
            grid[y][size.x - 1 - x] = grid[y][x]
```

Copy the left half onto the right in reverse. The right half becomes the mirror of the left.

Mirror in both axes.

```gdscript
func mirror_both() -> void:
    mirror_horizontal()
    var half: int = size.y / 2
    for y in range(half):
        for x in size.x:
            grid[size.y - 1 - y][x] = grid[y][x]
```

Horizontal and vertical. The full grid becomes a 4-fold symmetric kaleidoscope.

Apply rotational symmetry.

```gdscript
func apply_rotational(steps: int = 4) -> void:
    var base: Array = []
    for y in size.y: base.append(grid[y].duplicate())
    for step in range(1, steps):
        var angle: float = step * TAU / steps
        for y in size.y:
            for x in size.x:
                var cx: float = size.x / 2.0; var cy: float = size.y / 2.0
                var rx: int = int(cx + cos(-angle) * (x - cx) - sin(-angle) * (y - cy))
                var ry: int = int(cy + sin(-angle) * (x - cx) + cos(-angle) * (y - cy))
                if rx >= 0 and rx < size.x and ry >= 0 and ry < size.y:
                    grid[y][x] = grid[y][x] or base[ry][rx]
```

Rotate the base grid; OR it onto itself. Four-fold rotation produces kaleidoscopic symmetry.

Grow a rhizomatic maze.

```gdscript
class_name RhizomaticMaze

var passages: Dictionary = {}  # cell -> set of adjacent open cells

func grow_from_seed(seed: Vector2i, max_cells: int) -> void:
    var active: Array = [seed]
    passages[seed] = {}
    var count: int = 0
    while not active.is_empty() and count < max_cells:
        var cell: Vector2i = active[randi() % active.size()]
        var next: Vector2i = random_unclaimed_neighbour(cell)
        if next == Vector2i(-1, -1):
            active.erase(cell)
            continue
        passages[cell][next] = true
        passages[next] = {cell: true}
        active.append(next)
        count += 1
```

Multiple seeds produce a non-hierarchical maze. Passages merge where seed territories meet.

You can now run a 2D CA, mirror horizontally, rotate for 4-fold symmetry, and grow a rhizomatic maze from multiple seeds. Chamber_ProcGen extends into the bricoleur encounter.

<<<MAP: Chamber_ProcGen>>>
# Chamber ProcGen

The bricoleur golem rebuilds from scattered parts.

Build the golem.

```gdscript
class_name BricoleurGolem extends CharacterBody3D

var body_parts: Array = []
var detached_fragments: Array = []
@export var reassemble_interval: float = 2.0

var time_since_reassemble: float = 0.0

func _physics_process(delta: float) -> void:
    time_since_reassemble += delta
    if time_since_reassemble >= reassemble_interval:
        time_since_reassemble = 0.0
        reassemble()
```

Periodic reassembly. Every two seconds the golem picks up nearby fragments.

Detach a part.

```gdscript
func on_struck(part: Node3D, force: Vector3) -> void:
    body_parts.erase(part)
    part.reparent(get_tree().root)
    part.freeze = false
    part.apply_impulse(force)
    detached_fragments.append(part)
```

The part becomes a free-flying rigid body. It will settle somewhere nearby.

Find a nearby fragment.

```gdscript
@export var pickup_radius: float = 3.0

func find_nearby_fragment() -> Node3D:
    var best: Node3D = null
    var best_dist: float = pickup_radius
    for frag in detached_fragments:
        var d: float = frag.global_position.distance_to(global_position)
        if d < best_dist:
            best_dist = d; best = frag
    return best
```

Linear search. Pickup_radius is a soft limit on how far the golem can reach.

Attach a fragment.

```gdscript
func attach_fragment(fragment: Node3D) -> void:
    detached_fragments.erase(fragment)
    fragment.reparent(self)
    var attachment_point := compute_attachment_point()
    fragment.position = attachment_point
    fragment.freeze = true
    body_parts.append(fragment)
```

The fragment re-parents to the golem; its position is updated to a chosen attachment point.

Choose an attachment point.

```gdscript
func compute_attachment_point() -> Vector3:
    if body_parts.is_empty():
        return Vector3.ZERO
    var centroid := Vector3.ZERO
    for p in body_parts:
        centroid += p.position
    centroid /= body_parts.size()
    var offset := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
    return centroid + offset * 0.6
```

Nearby the body's centroid. Random offset means the golem's morphology drifts over time.

Reassemble.

```gdscript
func reassemble() -> void:
    var fragment := find_nearby_fragment()
    if fragment:
        attach_fragment(fragment)
```

One fragment per reassembly tick. Over many ticks the golem restores itself.

Track morphology drift.

```gdscript
var strike_counts: Dictionary = {}

func on_struck_with_tracking(part: Node3D, force: Vector3) -> void:
    var part_type: String = part.get_meta("type", "generic")
    strike_counts[part_type] = strike_counts.get(part_type, 0) + 1
    on_struck(part, force)
```

Record what the learner has hit. Later reassembly can prioritise heavily-struck types.

You can now build the bricoleur_golem, detach parts under impact, find nearby fragments, attach them at a drifting centroid, and track morphology over time. The Procedural Generation sequence closes with ongoing composition as catalyst practice.
