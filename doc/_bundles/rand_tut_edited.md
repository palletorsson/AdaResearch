<<<ADA_BUNDLE>>>
sequence: randomness
file: tutorial.md
maps: 14
<<</ADA_BUNDLE>>>

<<<MAP: Random_Definition>>>
# Random Definition

Randomness is irreducibility. Build the crank machine that separates pseudo-random from true random.

Declare the PRNG.

```gdscript
class_name PRNGCrank
extends Node

@export var seed: int = 42
var state: int = 0

func _ready() -> void:
    state = seed
```

A PRNG keeps state. The seed is the only hidden input. Same seed, same sequence.

Step the state.

```gdscript
func next() -> int:
    state = (state * 1103515245 + 12345) & 0x7fffffff
    return state
```

A linear congruential step. The numbers look random but are fully determined by the previous state.

Produce a uniform float.

```gdscript
func uniform() -> float:
    return float(next()) / float(0x7fffffff)
```

Dividing by the maximum yields a value in [0, 1). The function is reproducible across runs with the same seed.

Expose a crank handle.

```gdscript
func _on_crank_turned(turns: float) -> void:
    for i in int(turns):
        var v := uniform()
        history.append(v)
        readout_label.text = "%.4f" % v
```

Each quarter turn emits one sample. The readout updates. The learner watches the sequence appear.

Compare to a TRNG source.

```gdscript
func true_random_sample() -> float:
    var t := Time.get_ticks_usec()
    var hardware: int = (t ^ (t >> 13)) & 0xfffff
    return float(hardware) / float(0xfffff)
```

Hardware entropy from the clock is not cryptographic, but it is not reproducible. The same program on the same seed yields different values every run.

Log the seed and sample.

```gdscript
func log_sample(v: float, kind: String) -> void:
    log_entries.append({"kind": kind, "value": v, "seed": seed})
```

Entries tag which source produced the value. The log becomes evidence for the distinction.

Plot the histogram.

```gdscript
func update_histogram(values: Array) -> void:
    var bins := PackedInt32Array()
    bins.resize(10)
    for v in values:
        bins[int(clamp(v * 10.0, 0, 9))] += 1
    histogram.update(bins)
```

Ten bins show the distribution. Uniform means equal heights, roughly. Deviations shrink as the sample grows.

You have named the vocabulary. The next map, Random Remove, turns randomness into subtraction.
<<</MAP>>>

<<<MAP: Random_Remove>>>
# Random Remove

Randomness deletes. Build the 8x8 arena where stochastic selection removes cubes and exposes the distribution.

Declare the remover.

```gdscript
class_name RemoveRandom
extends Node3D

enum Mode { RANGE, COLUMN, ROW, ALL }

@export var mode: Mode = Mode.RANGE
@export var size: Vector2i = Vector2i(8, 8)
```

Four modes, one rectangular grid. The mode selects how the random pick happens.

Populate the grid.

```gdscript
func populate() -> void:
    for x in size.x:
        for y in size.y:
            var cube := preload("res://commons/artifacts/randomness/grid_cube.tscn").instantiate()
            cube.position = Vector3(x, 0, y)
            add_child(cube)
            cubes[Vector2i(x, y)] = cube
```

64 cubes arranged in the 8x8. Each cube is indexed by its grid position. Removal targets the index.

Remove by range.

```gdscript
func remove_range(count: int) -> void:
    var keys := cubes.keys()
    keys.shuffle()
    for i in min(count, keys.size()):
        _drop_cube(keys[i])
```

Shuffled keys produce uniform selection without replacement. Drop lowers the cube through the floor and frees it.

Remove by column.

```gdscript
func remove_column() -> void:
    var x := randi() % size.x
    for y in size.y:
        _drop_cube(Vector2i(x, y))
```

A random column disappears wholesale. The strip is always size.y cubes. The learner sees a single axis as a unit.

Remove by row.

```gdscript
func remove_row() -> void:
    var y := randi() % size.y
    for x in size.x:
        _drop_cube(Vector2i(x, y))
```

Same mechanic, different axis. Rows and columns together demonstrate that random choice can select either coordinate.

Remove all at once.

```gdscript
func remove_all() -> void:
    for key in cubes.keys():
        _drop_cube(key)
```

Every cube drops simultaneously. The arena empties. The moment is a demonstration of what total removal looks like.

Animate the drop.

```gdscript
func _drop_cube(key: Vector2i) -> void:
    if not cubes.has(key): return
    var cube: Node3D = cubes[key]
    var tween := create_tween()
    tween.tween_property(cube, "position:y", -3.0, 0.6)
    tween.tween_callback(cube.queue_free)
    cubes.erase(key)
```

Each cube falls for 0.6 seconds and frees. The sequence becomes a readable cascade rather than a silent delete.

Log the distribution.

```gdscript
func log_removed(key: Vector2i) -> void:
    removal_log.append({"x": key.x, "y": key.y, "mode": mode})
```

The log captures where and how. Later the learner can plot the removals and see the spread their mode produced.

You have seen randomness as subtraction. The next map, 10 PRINT, turns it generative.
<<</MAP>>>

<<<MAP: Randomness_10_PRINT_Algorithm>>>
# 10 PRINT Algorithm

One coin flip per cell, infinite visual structure. Build the maze from the simplest random choice.

Declare the maze grid.

```gdscript
class_name TenPrintMaze
extends Node3D

@export var rows: int = 20
@export var cols: int = 20
@export var cell_size: float = 0.4
```

Three numbers. Two for extent, one for cell size. The algorithm needs nothing else.

Flip a cell.

```gdscript
func flip_cell() -> String:
    if randi() % 2 == 0:
        return "/"
    return "\\"
```

A single coin flip returns one of two slashes. The entire maze grammar is this function.

Spawn the slash.

```gdscript
func spawn_slash(x: int, y: int, kind: String) -> void:
    var scene := preload("res://commons/artifacts/randomness/maze_slash.tscn")
    var slash := scene.instantiate()
    slash.position = Vector3(x * cell_size, 0.0, y * cell_size)
    slash.rotation.y = deg_to_rad(45.0 if kind == "/" else -45.0)
    add_child(slash)
```

Each cell gets a diagonal bar. The two rotations produce the two slashes. The mesh is one plank used twice.

Build the full maze.

```gdscript
func build_maze() -> void:
    for x in cols:
        for y in rows:
            spawn_slash(x, y, flip_cell())
```

400 cells, 400 flips, 400 bars. The maze completes in one frame.

Animate the build.

```gdscript
func animate_build() -> void:
    var i := 0
    while i < cols * rows:
        var x := i % cols
        var y := i / cols
        spawn_slash(x, y, flip_cell())
        i += 1
        await get_tree().create_timer(0.01).timeout
```

A coroutine paces the build. The learner watches the maze emerge one cell at a time. Emergence is performed.

Reseed to replay.

```gdscript
func reseed(new_seed: int) -> void:
    seed(new_seed)
    _clear()
    build_maze()
```

A new seed gives a new maze. The learner can compare two mazes drawn from two seeds.

Measure path length.

```gdscript
func count_paths_hint() -> int:
    return cols * rows
```

The maze always has as many segments as cells. Path lengths and connections vary by seed. Counting is left as a small exercise.

Overlay a grid for reference.

```gdscript
func draw_grid() -> void:
    for x in cols + 1:
        grid_lines.add_line(Vector3(x * cell_size, 0, 0), Vector3(x * cell_size, 0, rows * cell_size))
    for y in rows + 1:
        grid_lines.add_line(Vector3(0, 0, y * cell_size), Vector3(cols * cell_size, 0, y * cell_size))
```

A faint grid underlies the slashes. The coin flip becomes visible as choice over structure.

You have generated infinite pattern from one flip. The next map, Random Cubes, turns randomness onto objects.
<<</MAP>>>

<<<MAP: Random_Cubes>>>
# Random Cubes

Each cube remembers its coin flips. Build the arena where form encodes chance.

Declare the random cube.

```gdscript
class_name RandomEdgeCube
extends Node3D

@export var edge_chance: float = 0.5
var edge_profile: PackedInt32Array = PackedInt32Array()
```

A cube has 12 edges. Each edge is flipped on or off by a chance. The profile records the result.

Flip the edges.

```gdscript
func flip_edges() -> void:
    edge_profile.clear()
    for i in 12:
        edge_profile.append(1 if randf() < edge_chance else 0)
```

Twelve flips per cube. Each flip decides whether that edge is beveled, hollowed, or plain. The profile is the cube's signature.

Build the cube mesh from the profile.

```gdscript
func build_mesh() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in 12:
        if edge_profile[i] == 1:
            _add_beveled_edge(st, i)
        else:
            _add_plain_edge(st, i)
    mesh_instance.mesh = st.commit()
```

The mesh assembles from per-edge rules. Beveled edges get a small chamfer; plain edges stay sharp. The visual is the profile made stone.

Place a field of cubes.

```gdscript
func populate_field() -> void:
    for x in 6:
        for y in 6:
            var cube := preload("res://commons/artifacts/randomness/random_edge_cube.tscn").instantiate()
            cube.position = Vector3(x * 1.5, 0.0, y * 1.5)
            cube.flip_edges()
            cube.build_mesh()
            add_child(cube)
```

36 cubes, 36 unique profiles. No two cubes match. The grid makes differences legible side by side.

Highlight the current cube on inspection.

```gdscript
func highlight(cube: Node3D, active: bool) -> void:
    cube.material_override.emission = Color.WHITE if active else Color.BLACK
    cube.material_override.emission_energy_multiplier = 0.3 if active else 0.0
```

Inspection tints the cube. The learner can see which one they are reading.

Readout the profile.

```gdscript
func readout(cube: RandomEdgeCube, label: Label3D) -> void:
    label.text = "profile: " + str(cube.edge_profile)
```

A label shows the 12-bit profile beside the cube. The number is the cube; the cube is the number.

Offer a dice throw.

```gdscript
func _on_dice_thrown(face: int) -> void:
    edge_chance = float(face) / 6.0
    for cube in cubes:
        cube.flip_edges()
        cube.build_mesh()
```

Throwing a die changes the edge chance for the whole field. The population responds to a single roll. Randomness scales.

You have seen form encoding chance. The next map, Random Rotate, moves randomness into three axes.
<<</MAP>>>

<<<MAP: Random_Rotate_Random_XYZ>>>
# Random Rotate Random XYZ

Three axes, three independent rolls. Build the orientation generator that proves 3D randomness is qualitatively different.

Declare the triple roll.

```gdscript
class_name TripleRoll
extends Node3D

var x_angle: float = 0.0
var y_angle: float = 0.0
var z_angle: float = 0.0
```

Three angles, three floats. Each is rolled independently.

Roll all three.

```gdscript
func roll() -> void:
    x_angle = randf() * TAU
    y_angle = randf() * TAU
    z_angle = randf() * TAU
    rotation = Vector3(x_angle, y_angle, z_angle)
```

Three calls to randf, three assignments. The resulting orientation is almost never anything the learner would predict.

Animate a continuous roll.

```gdscript
func _process(dt: float) -> void:
    if auto_roll:
        x_angle += randf_range(-1.0, 1.0) * dt
        y_angle += randf_range(-1.0, 1.0) * dt
        z_angle += randf_range(-1.0, 1.0) * dt
        rotation = Vector3(x_angle, y_angle, z_angle)
```

Auto-roll adds noise to the angles each frame. The object tumbles irregularly. No two frames share an orientation.

Expose axis buttons.

```gdscript
func _on_axis_button_pressed(axis: String) -> void:
    match axis:
        "x": x_angle = randf() * TAU
        "y": y_angle = randf() * TAU
        "z": z_angle = randf() * TAU
    rotation = Vector3(x_angle, y_angle, z_angle)
```

Three buttons let the learner reroll one axis at a time. The other two stay put. The interaction isolates each axis.

Sample from hardware entropy.

```gdscript
func hardware_roll() -> float:
    var t := Time.get_ticks_usec()
    return float((t ^ (t >> 7)) & 0xffff) / float(0xffff) * TAU
```

Hardware entropy replaces the PRNG. Same shape, different source. The method swaps cleanly.

Record the roll history.

```gdscript
func log_roll() -> void:
    rolls.append(Vector3(x_angle, y_angle, z_angle))
```

The log stores each orientation. A small panel plots the history as a scatter of rotated arrows.

Show the Euler angles.

```gdscript
func readout_euler(label: Label3D) -> void:
    label.text = "X: %5.1f°\nY: %5.1f°\nZ: %5.1f°" % [
        rad_to_deg(x_angle), rad_to_deg(y_angle), rad_to_deg(z_angle)
    ]
```

The readout shows degrees. Three independent numbers describe the orientation. The tutorial refuses to collapse them into one.

You have seen randomness expand into three dimensions. The next map, Random Walk, turns randomness into a path.
<<</MAP>>>

<<<MAP: Random_Walk>>>
# Random Walk

Each step is chosen, none remembered. Build the walker that drifts through space without a plan.

Declare the walker.

```gdscript
class_name RandomWalker
extends Node3D

@export var step_size: float = 0.2
@export var step_delay: float = 0.1
var path: PackedVector3Array = PackedVector3Array()
```

Size and delay. The path records every step for visualisation.

Pick a direction.

```gdscript
func pick_direction() -> Vector3:
    return Vector3(
        randf_range(-1.0, 1.0),
        0.0,
        randf_range(-1.0, 1.0)
    ).normalized()
```

A uniform direction in the xz plane. The walker stays on the floor. The method is unbiased in heading.

Take a step.

```gdscript
func step() -> void:
    var dir := pick_direction()
    position += dir * step_size
    path.append(position)
```

Position accumulates; path grows. The walker has no memory of where it came from; the path records it for us.

Animate the step rate.

```gdscript
func _process(dt: float) -> void:
    step_timer += dt
    if step_timer > step_delay:
        step_timer = 0.0
        step()
        render_path()
```

A timer paces the steps. The delay controls visibility. Slower makes the walk readable.

Render the path.

```gdscript
func render_path() -> void:
    var line := path_mesh.mesh as ImmediateMesh
    line.clear_surfaces()
    line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
    for p in path:
        line.surface_add_vertex(p)
    line.surface_end()
```

A single polyline traces the history. The shape is a scribble with probability in its curves. Brownian motion on the floor.

Measure the end-to-end displacement.

```gdscript
func displacement() -> float:
    if path.is_empty(): return 0.0
    return path[0].distance_to(path[-1])
```

Displacement grows as the square root of step count. The tutorial does not derive this; it lets the learner see the slowness.

Compare multiple walkers.

```gdscript
func spawn_cohort(count: int) -> void:
    for i in count:
        var walker := preload("res://commons/artifacts/randomness/random_walker.tscn").instantiate()
        walker.global_position = Vector3.ZERO
        add_child(walker)
```

Many walkers start from the same origin. Over time they spread. The cloud of endpoints is the distribution.

Cap the path length.

```gdscript
func cap_path() -> void:
    while path.size() > 500:
        path.remove_at(0)
```

Old steps drop so memory stays bounded. The walk is infinite; the visualisation is not.

You have drawn a stochastic path. The next map, Random Gaussian, accumulates steps into a bell curve.
<<</MAP>>>

<<<MAP: Random_Gaussian>>>
# Random Gaussian

The bell curve emerges from accumulation. Build the Galton board where balls fall through pegs and settle into a Gaussian.

Declare the board.

```gdscript
class_name GaltonBoard
extends Node3D

@export var rows: int = 12
@export var peg_spacing: float = 0.3
```

Rows stack down; each row has one more peg than the one above. The triangle widens with depth.

Place the pegs.

```gdscript
func place_pegs() -> void:
    for r in rows:
        for p in r + 1:
            var peg := preload("res://commons/artifacts/randomness/peg.tscn").instantiate()
            var x: float = (p - r * 0.5) * peg_spacing
            var y: float = -r * peg_spacing
            peg.position = Vector3(x, y, 0.0)
            add_child(peg)
```

A triangle of pegs. Each ball that lands on a peg has a 50/50 chance of going left or right. Over many balls, positions converge.

Drop a ball.

```gdscript
func drop_ball() -> void:
    var ball := preload("res://commons/artifacts/randomness/ball.tscn").instantiate()
    ball.position = Vector3(0.0, 0.3, 0.0)
    ball.linear_velocity = Vector3(0, -0.5, 0)
    add_child(ball)
    balls.append(ball)
```

The ball starts at the top centre with a small downward push. Physics handles the bouncing. The end position depends on which side of each peg the ball took.

Collect the landing position.

```gdscript
func record_landing(ball: Node3D) -> void:
    var bucket_index: int = int(round(ball.position.x / peg_spacing))
    histogram[bucket_index] = histogram.get(bucket_index, 0) + 1
```

Each landing slot increments a bucket. The histogram updates.

Render the histogram.

```gdscript
func update_histogram_mesh(mesh: ArrayMesh) -> void:
    for key in histogram:
        var bar := get_bar_for(key)
        bar.scale.y = float(histogram[key]) * 0.05
        bar.position.y = bar.scale.y * 0.5
```

Bars rise behind the slots. The curve reveals itself as more balls land. The peak sits at the centre; tails spread outward.

Compare to an analytic bell curve.

```gdscript
func analytic_gaussian(x: float) -> float:
    var sigma: float = sqrt(float(rows) / 4.0)
    return exp(-(x * x) / (2.0 * sigma * sigma))
```

The formula predicts the shape from the row count. The prediction is overlaid on the histogram. The measured bars approach the line.

Drop many balls.

```gdscript
func drop_cohort(count: int) -> void:
    for i in count:
        drop_ball()
        await get_tree().create_timer(0.04).timeout
```

A coroutine drops a ball every 40 milliseconds. A few hundred balls fill the histogram. The Central Limit Theorem becomes a scene.

You have watched the bell curve emerge. The next map, Random Mushrooms, grounds Gaussian sampling in biological form.
<<</MAP>>>

<<<MAP: Random_Mushrooms>>>
# Random Mushrooms

Fungi grow where the distribution allows. Build the forest floor where substrate, moisture, and temperature decide placement.

Declare the substrate sampler.

```gdscript
class_name SubstrateSampler
extends Node3D

@export var moisture_map: Texture2D
@export var temperature_map: Texture2D
@export var substrate_map: Texture2D
```

Three maps describe the ground. Each stores a float per pixel. A sampler reads the combined likelihood at a position.

Compute the likelihood at a point.

```gdscript
func likelihood(pos: Vector3) -> float:
    var uv := _world_to_uv(pos)
    var m: float = moisture_map.get_image().get_pixelv(uv).r
    var t: float = temperature_map.get_image().get_pixelv(uv).r
    var s: float = substrate_map.get_image().get_pixelv(uv).r
    return m * t * s
```

Three values multiplied. If any is zero, the spot is unsuitable. If all are high, the spot invites growth.

Accept or reject a candidate.

```gdscript
func accept_candidate(pos: Vector3) -> bool:
    return randf() < likelihood(pos)
```

The rejection sampler maps the probability to a boolean. Over many candidates, accepted points cluster where likelihood is high.

Spawn a mushroom at an accepted point.

```gdscript
func spawn_mushroom(pos: Vector3) -> void:
    var m := preload("res://commons/artifacts/randomness/mushroom.tscn").instantiate()
    m.position = pos
    m.scale = Vector3.ONE * randf_range(0.6, 1.2)
    add_child(m)
```

Each mushroom has a slightly different size. The forest floor reads as varied because it is.

Scatter candidates across the floor.

```gdscript
func scatter_candidates(count: int) -> void:
    for i in count:
        var pos := Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
        if accept_candidate(pos):
            spawn_mushroom(pos)
```

A hundred candidates might yield thirty mushrooms. The accepted set is the sample from the distribution.

Render the 1955 RAND tables on a wall.

```gdscript
func place_rand_plaque() -> void:
    var plaque := preload("res://commons/artifacts/randomness/rand_book_plaque.tscn").instantiate()
    plaque.position = Vector3(0, 1.5, -6)
    add_child(plaque)
```

Before computers generated randomness, RAND Corporation published a million-digit book. The plaque names the history.

Allow weather to shift.

```gdscript
func shift_moisture(amount: float) -> void:
    var img: Image = moisture_map.get_image()
    img.adjust_bcs(1.0, 1.0, 1.0 + amount)
    moisture_map = ImageTexture.create_from_image(img)
```

A lever adjusts the moisture. New spawns cluster in the wetter half. The distribution is not static.

Log every spawn.

```gdscript
func log_spawn(pos: Vector3) -> void:
    spawn_log.append({"pos": pos, "time": Time.get_ticks_msec()})
```

The log becomes a spore record. The learner can plot the spread over time.

You have sampled life from a distribution. The next map, Random Space Geometry, randomises the space itself.
<<</MAP>>>

<<<MAP: Random_Space_Geometry>>>
# Random Space Geometry

Space itself becomes stochastic. Build two chambers where random transformations sculpt the arena.

Declare the chamber pair.

```gdscript
class_name ChamberPair
extends Node3D

@export var north_seed: int = 1
@export var south_seed: int = 2
```

Two seeds, two chambers. Each seed determines every random transform applied to its chamber's geometry.

Generate a chamber mesh.

```gdscript
func generate_chamber(seed_value: int) -> ArrayMesh:
    seed(seed_value)
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in 120:
        var pos := Vector3(randf_range(-3, 3), randf_range(0, 3), randf_range(-3, 3))
        _add_random_panel(st, pos)
    return st.commit()
```

120 panels placed randomly. The seed ensures reproducibility. A given seed always builds the same chamber.

Add a panel.

```gdscript
func _add_random_panel(st: SurfaceTool, centre: Vector3) -> void:
    var rot := Basis.from_euler(Vector3(randf(), randf(), randf()) * TAU)
    var size := Vector3(randf_range(0.3, 1.2), 0.05, randf_range(0.3, 1.2))
    st.add_triangle_fan([
        centre + rot * Vector3(-size.x * 0.5, 0, -size.z * 0.5),
        centre + rot * Vector3(size.x * 0.5, 0, -size.z * 0.5),
        centre + rot * Vector3(size.x * 0.5, 0, size.z * 0.5),
        centre + rot * Vector3(-size.x * 0.5, 0, size.z * 0.5),
    ])
```

Each panel has a random centre, rotation, and size. The chamber becomes an array of irregular plates.

Connect the chambers by a spine.

```gdscript
func build_spine(from: Vector3, to: Vector3) -> void:
    var segments := 12
    for i in segments:
        var t: float = float(i) / float(segments - 1)
        var pos: Vector3 = from.lerp(to, t)
        pos.y += sin(t * PI) * 0.5
        var seg := preload("res://commons/artifacts/randomness/spine_segment.tscn").instantiate()
        seg.position = pos
        add_child(seg)
```

A gentle arch connects north and south. Walking from one chamber to the other crosses from one random geometry to another.

Render the chamber ceilings.

```gdscript
func place_ceilings() -> void:
    var mesh := generate_chamber(north_seed)
    north_ceiling.mesh = mesh
    south_ceiling.mesh = generate_chamber(south_seed)
```

Each ceiling is the random panel array mounted overhead. The learner looks up and sees a different randomness in each chamber.

Reroll on demand.

```gdscript
func _on_reroll_button_pressed(side: String) -> void:
    if side == "north":
        north_seed = randi()
    else:
        south_seed = randi()
    place_ceilings()
```

A button rerolls one side. The other stays. Comparison becomes live.

Label the seeds.

```gdscript
func label_seeds() -> void:
    north_label.text = "N: seed %d" % north_seed
    south_label.text = "S: seed %d" % south_seed
```

The seeds are visible. Reproducibility is shown, not assumed. Two learners with the same seeds build the same chambers.

You have made space itself stochastic. The next map, Examples of Randomness, surveys randomness across domains.
<<</MAP>>>

<<<MAP: Randomness_Examples_of_Randomness>>>
# Examples of Randomness

A gallery of chance. Build four rooms, each showing randomness in a different register.

Declare the gallery registry.

```gdscript
class_name GalleryRegistry
extends Resource

@export var rooms: Dictionary = {
    "pollock": "action painting",
    "pipes": "combinatorial play",
    "butterfly": "biological flight",
    "extremes": "tail distributions",
}
```

Four rooms, four names, four subtitles. The registry is the floor plan.

Place the rooms.

```gdscript
func place_rooms() -> void:
    var angle := 0.0
    for key in registry.rooms:
        var room := preload("res://commons/artifacts/randomness/gallery_room.tscn").instantiate()
        room.name = key
        room.position = Vector3(cos(angle) * 5.0, 0, sin(angle) * 5.0)
        add_child(room)
        angle += TAU / registry.rooms.size()
```

Rooms circle a central rotunda. The learner walks the survey.

Drip Pollock.

```gdscript
func pollock_drip(canvas: Node3D) -> void:
    for i in 80:
        var pos := Vector3(randf_range(-1.5, 1.5), 1.0, randf_range(-1.5, 1.5))
        var dir := Vector3(0, -1, 0) + Vector3(randf() - 0.5, 0, randf() - 0.5) * 0.2
        var drop := preload("res://commons/artifacts/randomness/paint_drop.tscn").instantiate()
        drop.position = pos
        drop.linear_velocity = dir * 5.0
        canvas.add_child(drop)
```

Drops fall from above the canvas, slightly randomised. Each drop leaves a splat where it lands. Action painting as spawn loop.

Generate pipe dreams.

```gdscript
func generate_pipes(grid_size: Vector2i) -> void:
    for x in grid_size.x:
        for y in grid_size.y:
            var piece_kind: int = randi() % 4
            spawn_pipe_piece(Vector2i(x, y), piece_kind)
```

Four piece kinds (straight, bent, tee, cross). Random per cell. The assembly becomes a plumbing puzzle with no designer.

Fly a butterfly.

```gdscript
func fly_butterfly(butterfly: Node3D, dt: float) -> void:
    var noise := FastNoiseLite.new()
    var t := Time.get_ticks_msec() / 1000.0
    butterfly.position += Vector3(
        noise.get_noise_2d(t, 0) * 1.5,
        noise.get_noise_2d(t, 100) * 0.5,
        noise.get_noise_2d(t, 200) * 1.5
    ) * dt
```

Noise drives the butterfly's heading. Each dimension samples noise with a different offset. The path becomes characteristic rather than chaotic.

Visualise extreme tails.

```gdscript
func extreme_sample() -> float:
    return randfn(0.0, 1.0) + randfn(0.0, 4.0) * 0.1
```

A Gaussian mixed with a wider Gaussian produces heavy tails. The values sometimes spike far from zero. The spike drawer shows the far edge.

Plot samples against time.

```gdscript
func plot_sample(value: float) -> void:
    sample_chart.push(value)
```

The chart scrolls. Most values cluster near zero. Occasional outliers punctuate. Tail distributions become readable.

You have surveyed randomness across domains. The next map, Random Pheromone, turns random agents into collective order.
<<</MAP>>>

<<<MAP: Random_Pheromone>>>
# Random Pheromone

Each ant walks randomly; the trail it leaves biases the next. Build stigmergy from a floor-grid of pheromone values.

Declare the pheromone grid.

```gdscript
class_name PheromoneGrid
extends Node3D

@export var size: Vector2i = Vector2i(40, 40)
var field: PackedFloat32Array = PackedFloat32Array()
```

A flat grid of floats, one per cell. The values decay over time and grow with deposits.

Deposit pheromone at a position.

```gdscript
func deposit(pos: Vector3, amount: float) -> void:
    var cell := _world_to_cell(pos)
    var idx := cell.y * size.x + cell.x
    if idx >= 0 and idx < field.size():
        field[idx] = min(field[idx] + amount, 1.0)
```

Deposits cap at 1.0. The field stays bounded. Every ant step thickens the floor under it.

Decay the field.

```gdscript
func decay(dt: float, rate: float) -> void:
    for i in field.size():
        field[i] = max(0.0, field[i] - rate * dt)
```

All cells lose a little each frame. Without fresh deposits, trails fade. Memory is finite.

Spawn ants.

```gdscript
func spawn_ants(count: int) -> void:
    for i in count:
        var ant := preload("res://commons/artifacts/randomness/ant.tscn").instantiate()
        ant.position = Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
        add_child(ant)
```

Ants start scattered. Each carries its own position and heading.

Bias each step by local pheromone.

```gdscript
func step_ant(ant: Node3D, dt: float) -> void:
    var dir := _pick_direction_with_bias(ant.global_position)
    ant.position += dir * ant_speed * dt
    deposit(ant.global_position, 0.05)
```

Direction is chosen by sampling neighbouring cells and weighting toward higher pheromone. The ant tends to follow a trail without committing to it.

Sample the bias.

```gdscript
func _pick_direction_with_bias(pos: Vector3) -> Vector3:
    var weights := []
    var dirs := [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]
    for d in dirs:
        var sample_pos: Vector3 = pos + d * cell_size
        weights.append(field[_index(sample_pos)] + 0.05)
    return dirs[_weighted_pick(weights)]
```

Four cardinal directions sampled. Weights are the local pheromone plus a small constant so ants still explore empty cells.

Render the pheromone as a heatmap.

```gdscript
func update_heatmap(image: Image) -> void:
    for i in field.size():
        var v: float = field[i]
        var x: int = i % size.x
        var y: int = i / size.x
        image.set_pixel(x, y, Color(v, v * 0.3, 0.0))
```

Orange trails glow over a dark floor. The learner watches paths consolidate from noise.

Log the trail shape.

```gdscript
func trail_entropy() -> float:
    var mean: float = 0.0
    for v in field: mean += v
    mean /= field.size()
    return mean
```

A scalar describes how much of the grid is active. As ants converge on a trail, the scalar drops.

You have built emergence from individual chance. The next map, Random Space, saturates space with randomness.
<<</MAP>>>

<<<MAP: Random_Space>>>
# Random Space

The sequence finale. Build the arena where every thread of the randomness curriculum converges.

Declare the finale environment.

```gdscript
class_name RandomSpaceArena
extends Node3D

@export var gaussian_sources: int = 4
@export var butterfly_count: int = 16
@export var pollock_drippers: int = 3
```

Four Gaussians, sixteen butterflies, three drip sources. The numbers are small enough to read and large enough to layer.

Place Gaussian field markers.

```gdscript
func place_gaussians() -> void:
    for i in gaussian_sources:
        var marker := preload("res://commons/artifacts/randomness/gaussian_marker.tscn").instantiate()
        marker.position = Vector3(randfn(0, 4), 0.1, randfn(0, 4))
        add_child(marker)
```

Gaussian random positions. Markers cluster near the origin with rare outliers. The distribution shape is felt through placement.

Scatter butterflies.

```gdscript
func scatter_butterflies() -> void:
    for i in butterfly_count:
        var b := preload("res://commons/artifacts/randomness/butterfly.tscn").instantiate()
        b.position = Vector3(randf_range(-5, 5), randf_range(0.5, 2.5), randf_range(-5, 5))
        add_child(b)
```

Butterflies occupy the air at random heights and floor positions. Each has its own noise-driven path.

Start the drippers.

```gdscript
func start_drippers() -> void:
    for i in pollock_drippers:
        var dripper := preload("res://commons/artifacts/randomness/dripper.tscn").instantiate()
        dripper.position = Vector3(randf_range(-3, 3), 3.0, randf_range(-3, 3))
        add_child(dripper)
```

Drippers hover above the floor, releasing drops at random intervals. The floor collects the splatter over time.

Blend the three into one reading.

```gdscript
func compose_reading() -> Dictionary:
    return {
        "gaussian_count": gaussian_sources,
        "butterfly_count": butterflies.size(),
        "pollock_drops": drop_log.size(),
    }
```

The reading summarises the three modes in one dictionary. A panel displays the numbers.

Fade audio in layers.

```gdscript
func layer_audio(dt: float) -> void:
    gaussian_bus.volume_db = lerp(gaussian_bus.volume_db, -6.0, dt)
    butterfly_bus.volume_db = lerp(butterfly_bus.volume_db, -9.0, dt)
    drip_bus.volume_db = lerp(drip_bus.volume_db, -12.0, dt)
```

Three audio buses ride the three modes. The room sounds like layered randomness rather than one noise.

Write the closing sign.

```gdscript
func write_closing(label: Label3D) -> void:
    label.text = "randomness saturates space"
    label.modulate = Color(0.9, 0.8, 0.7)
```

The sign names the finale. The arena is not about any one example; it is about saturation.

You have walked the finale. The next map, Random Game, makes randomness playable.
<<</MAP>>>

<<<MAP: Random_Game>>>
# Random Game

The floor itself is probabilistic. Build the 8x8 arena where falling cubes and origami enemies make randomness gameplay.

Declare the game grid.

```gdscript
class_name RandomGameGrid
extends Node3D

@export var size: Vector2i = Vector2i(8, 8)
@export var sink_period_range: Vector2 = Vector2(2.0, 8.0)
```

Eight by eight floor. Each tile has its own sink period in the given range. No tile shares a cycle.

Populate the tiles.

```gdscript
func populate_tiles() -> void:
    for x in size.x:
        for y in size.y:
            var tile := preload("res://commons/artifacts/randomness/game_tile.tscn").instantiate()
            tile.position = Vector3(x, 0, y)
            tile.sink_period = randf_range(sink_period_range.x, sink_period_range.y)
            tile.phase_offset = randf() * TAU
            add_child(tile)
```

Each tile gets a period and a phase. The grid becomes an incoherent field of independent oscillators.

Sink the tiles on schedule.

```gdscript
func update_tile(tile: Node3D, t: float) -> void:
    var value := sin(TAU * t / tile.sink_period + tile.phase_offset)
    tile.position.y = -0.5 if value < 0.0 else 0.0
```

Sine drives the sink state. When the sine is negative, the tile drops. The player must read each tile's rhythm separately.

Detect falls.

```gdscript
func check_player_footing(player: Node3D) -> bool:
    var cell := _world_to_cell(player.position)
    var tile: Node3D = tiles.get(cell)
    if tile and tile.position.y < -0.1:
        return false
    return true
```

If the tile under the player is sunk, footing fails. The game triggers a reset or a life loss.

Spawn origami enemies.

```gdscript
func spawn_origami(count: int) -> void:
    for i in count:
        var fold := preload("res://commons/artifacts/randomness/origami_fold.tscn").instantiate()
        fold.position = Vector3(randf_range(0, size.x - 1), 0, randf_range(0, size.y - 1))
        fold.next_move_delay = randf_range(0.5, 2.0)
        add_child(fold)
```

Origami enemies unfold across cells with random delays. Movement is discrete; timing is stochastic.

Move an origami.

```gdscript
func step_origami(fold: Node3D, dt: float) -> void:
    fold.timer += dt
    if fold.timer < fold.next_move_delay: return
    fold.timer = 0.0
    fold.next_move_delay = randf_range(0.5, 2.0)
    fold.position += Vector3(randi_range(-1, 1), 0, randi_range(-1, 1))
```

Random direction, random delay. The enemy is never where the player predicts.

Score survival in ticks.

```gdscript
func on_tick(dt: float) -> void:
    if check_player_footing(player):
        score += dt
    score_label.text = "%.1f s" % score
```

The longer the player survives, the higher the score. The game rewards randomness-reading over route-memorising.

Reset on defeat.

```gdscript
func reset_game() -> void:
    score = 0.0
    for tile in tiles.values():
        tile.phase_offset = randf() * TAU
    for fold in folds:
        fold.position = Vector3(randf_range(0, 8), 0, randf_range(0, 8))
```

A reset reseeds phases and positions. No run is ever the same.

You have played inside randomness. The next map, Chamber Random, closes the sequence as a catalyst encounter.
<<</MAP>>>

<<<MAP: Chamber_Random>>>
# Chamber Random

Chaos shots scatter. The octapod cannot predict you. Build the chamber where entropy is the shared condition.

Declare the chaos shooter.

```gdscript
class_name ChaosShot
extends RigidBody3D

@export var base_speed: float = 6.0
@export var spread: float = 0.7
```

A projectile with base speed and scatter. The scatter is how unpredictable each shot is.

Fire with scatter.

```gdscript
func fire(origin: Vector3, dir: Vector3) -> void:
    var scatter := Vector3(
        randf_range(-spread, spread),
        randf_range(-spread * 0.3, spread * 0.3),
        randf_range(-spread, spread)
    )
    linear_velocity = (dir + scatter).normalized() * base_speed
    position = origin
```

Each shot gets its own scatter vector. Two consecutive shots never travel the same path.

Spawn the octapod enemy.

```gdscript
func spawn_octapod() -> void:
    var oct := preload("res://commons/artifacts/randomness/octapod.tscn").instantiate()
    oct.position = Vector3(0, 0.5, -5)
    add_child(oct)
    octapod = oct
```

The octapod sits at the arena's far end. It has its own chaos AI.

Move the octapod by drawing from noise.

```gdscript
func move_octapod(dt: float) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    octapod.position += Vector3(
        noise.get_noise_2d(t, 0.0),
        0.0,
        noise.get_noise_2d(t, 7.3)
    ) * dt * 3.0
```

Noise replaces targeting. The octapod drifts rather than chases. Neither side has a plan.

Detect hits.

```gdscript
func _on_shot_hit(shot: Node3D, target: Node3D) -> void:
    if target == octapod:
        octapod.chaos_health -= 10
        if octapod.chaos_health <= 0:
            octapod.befriend()
```

Hits accumulate. After enough, the octapod flips from adversary to friend. The win condition is persistence with chance.

Befriend the octapod.

```gdscript
func befriend() -> void:
    chaos_health = 0
    modulate = Color(0.7, 0.9, 0.7)
    friendly = true
    emit_signal("befriended")
```

Befriending colours the octapod green. The signal tells the chamber to open the exit.

Dispense the catalyst mode.

```gdscript
func dispense_catalyst() -> void:
    CatalystBracelet.enable_mode("chaos")
    bracelet_label.text = "chaos: accept the spread"
```

The catalyst mode is "chaos." It introduces scatter into every other bracelet interaction going forward.

Open the exit.

```gdscript
func _on_befriended() -> void:
    exit_door.unlock()
    CatalystBracelet.register_friend("octapod")
```

The exit unlocks on befriending. The octapod is recorded for later chambers. Randomness has become a friend.

You have closed the Randomness sequence. The remaining arc asks what randomness enables once it is a tool rather than a surprise.
<<</MAP>>>
