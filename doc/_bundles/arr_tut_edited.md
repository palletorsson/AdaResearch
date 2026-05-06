<<<ADA_BUNDLE>>>
sequence: array_tutorial
file: tutorial.md
maps: 7
skipped_passing: 1
created: 2026-04-24T02:30:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Tutorial_Pattern>>>
# Patterns

Rules turn arrays into rhyming data. A small grid tiles into a surface.

Define a rule as a function.

```gdscript
func checkerboard(x: int, y: int) -> int:
    return (x + y) % 2
```

Returns 0 or 1 based on cell coordinates. The classic two-colour pattern.

Populate a grid from a rule.

```gdscript
func populate_grid(size: Vector2i, rule: Callable) -> Array:
    var grid: Array = []
    for y in size.y:
        var row: Array = []
        for x in size.x:
            row.append(rule.call(x, y))
        grid.append(row)
    return grid
```

The rule runs at every cell. The result is a 2D array of palette indices.

Render the grid as a texture.

```gdscript
func grid_to_texture(grid: Array, palette: Array) -> ImageTexture:
    var h := grid.size()
    var w := grid[0].size()
    var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
    for y in h:
        for x in w:
            image.set_pixel(x, y, palette[grid[y][x]])
    return ImageTexture.create_from_image(image)
```

Each cell becomes one pixel. The image can then be applied as a material.

Define a wave rule.

```gdscript
func wave_rule(x: int, y: int) -> int:
    var v: float = sin(x * 0.3) + cos(y * 0.3)
    return int((v + 2.0) * 2) % 4  # maps to palette index 0-3
```

Two sinusoids combine. The result reads as a flowing pattern rather than a discrete grid.

Make a spiral.

```gdscript
func spiral_rule(x: int, y: int, size: Vector2i) -> int:
    var cx = size.x / 2.0; var cy = size.y / 2.0
    var angle: float = atan2(y - cy, x - cx)
    return int((angle + PI) / TAU * 4) % 4
```

The angle from the centre determines the palette index. Four sectors, four colours.

Let the user edit cells directly.

```gdscript
func paint_cell(grid: Array, x: int, y: int, palette_index: int) -> void:
    grid[y][x] = palette_index
```

Direct write. The user's edits override the rule's output.

Tile the grid across a larger surface.

```gdscript
func tiled_color(grid: Array, px: int, py: int, palette: Array) -> Color:
    var h := grid.size()
    var w := grid[0].size()
    return palette[grid[py % h][px % w]]
```

Modulo wraps the coordinate back into the tile. The same 8×8 grid fills an arbitrarily large surface.

You can now write a rule, populate a grid from it, render it as a texture, accept user edits, and tile it across any surface. Array_Patterns extends this with full wallpaper-group symmetries.

<<<MAP: Tutorial_Single>>>
# Single

One cube. One platform. One grab. The VR baseline.

Spawn the cube.

```gdscript
func spawn_cube() -> RigidBody3D:
    var cube := RigidBody3D.new()
    var mesh := MeshInstance3D.new()
    mesh.mesh = BoxMesh.new()
    cube.add_child(mesh)
    cube.global_position = Vector3(0, 1, 0)
    add_child(cube)
    return cube
```

RigidBody3D for physics; MeshInstance3D for rendering. Godot composes them as a parent-child pair.

Add a collision shape.

```gdscript
func add_collision(cube: RigidBody3D) -> void:
    var shape := CollisionShape3D.new()
    shape.shape = BoxShape3D.new()
    cube.add_child(shape)
```

Without the shape, the body does not interact with anything. The shape matches the mesh.

Make it grabbable.

```gdscript
func make_grabbable(cube: RigidBody3D) -> void:
    cube.add_to_group("grabbable")
    var grab_area := Area3D.new()
    var area_shape := CollisionShape3D.new()
    area_shape.shape = BoxShape3D.new()
    grab_area.add_child(area_shape)
    cube.add_child(grab_area)
```

The Area3D detects the controller's grab collision. The separate area prevents collision interference with the body.

Handle grab events.

```gdscript
class_name GrabbableCube extends RigidBody3D

var held_by: XRController3D = null

func _on_controller_grip_pressed(controller: XRController3D) -> void:
    var distance: float = controller.global_position.distance_to(global_position)
    if distance < 0.3:
        held_by = controller
        freeze = true

func _on_controller_grip_released() -> void:
    held_by = null
    freeze = false
```

Grip press while near the cube grabs it. Release drops it back into physics.

Follow the controller while held.

```gdscript
func _physics_process(_delta: float) -> void:
    if held_by:
        global_position = held_by.global_position
        global_rotation = held_by.global_rotation
```

Direct teleport each frame. A more sophisticated implementation would add velocity smoothing.

Add a teleporter at the end.

```gdscript
func add_teleporter(position: Vector3, target_map: String) -> void:
    var teleporter := Area3D.new()
    teleporter.global_position = position
    teleporter.body_entered.connect(func(body):
        if body.is_in_group("learner"):
            get_tree().change_scene_to_file(target_map)
    )
    add_child(teleporter)
```

The teleporter triggers a scene change when the learner's body enters. No confirmation needed — the learner opted in by walking onto the pad.

You can now spawn a grabbable cube, handle grab and release, and place a teleporter. Tutorial_Row extends into a single-dimension corridor.

<<<MAP: Tutorial_Row>>>
# Row

The 1D array becomes a walkable corridor. Each cell is an index.

Build the corridor floor.

```gdscript
const ROW_SIZE := 9

func build_corridor() -> void:
    for i in ROW_SIZE:
        var cell := CELL_SCENE.instantiate()
        cell.position = Vector3(0, 0, i)
        cell.set_meta("index", i)
        add_child(cell)
```

Nine cells in a line. Each carries its index as metadata.

Read the learner's current index.

```gdscript
func current_index() -> int:
    var learner = get_tree().get_first_node_in_group("learner")
    return clamp(int(round(learner.global_position.z)), 0, ROW_SIZE - 1)
```

The Z coordinate maps directly to the array index. Clamp so walking past the ends returns the boundary values.

Display the index as code.

```gdscript
var code_label: Label3D

func _process(_delta: float) -> void:
    var i := current_index()
    code_label.text = "row[%d]" % i
```

The label updates as the learner walks. Each cell crossing increments the displayed index.

Trigger a sound on cell crossing.

```gdscript
var last_index: int = -1

func check_cell_crossing() -> void:
    var i := current_index()
    if i != last_index:
        play_index_sound(i)
        last_index = i

func play_index_sound(i: int) -> void:
    var pitch: float = 1.0 + i * 0.05
    sound_player.pitch_scale = pitch
    sound_player.play()
```

Rising pitch as the index grows. The sound cues the crossing without requiring eye contact with the label.

Constrain movement to the centre lane.

```gdscript
const LANE_X: float = 0.0

func _physics_process(_delta: float) -> void:
    var learner = get_tree().get_first_node_in_group("learner")
    learner.global_position.x = lerp(learner.global_position.x, LANE_X, 0.1)
```

Soft constraint via lerp. The learner can drift slightly but is gently pulled back to the lane.

Display the array contents.

```gdscript
var row: Array = [0, 1, 2, 3, 4, 5, 6, 7, 8]

func show_row_contents() -> void:
    for i in ROW_SIZE:
        var cell_label := Label3D.new()
        cell_label.text = str(row[i])
        cell_label.position = Vector3(0.5, 0.5, i)
        add_child(cell_label)
```

Each cell shows its stored value. The learner reads both the index (their position) and the content (the label).

You can now build a 1D corridor, constrain movement to its central lane, read and display the current array index, and show each cell's contents. Tutorial_2D_Build extends into two dimensions.

<<<MAP: Tutorial_2D_Build>>>
# 2D Build

Two indices, one grid. Row-major traversal made physical.

Build the 4×4 grid.

```gdscript
const GRID_SIZE := Vector2i(4, 4)

func build_grid() -> void:
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            var cell := CELL_SCENE.instantiate()
            cell.position = Vector3(x, 0, y)
            cell.set_meta("coords", Vector2i(x, y))
            cell.get_node("Label").text = "(%d, %d)" % [y, x]
            add_child(cell)
```

Each cell shows its (row, column) coordinates. Note the label order: row first, column second.

Highlight a row.

```gdscript
func highlight_row(row: int) -> void:
    for child in get_children():
        if child.has_meta("coords"):
            var c: Vector2i = child.get_meta("coords")
            child.modulate = Color.YELLOW if c.y == row else Color.WHITE
```

Metadata lookup finds each cell's row; colour changes accordingly.

Highlight a column.

```gdscript
func highlight_column(col: int) -> void:
    for child in get_children():
        if child.has_meta("coords"):
            var c: Vector2i = child.get_meta("coords")
            child.modulate = Color.CYAN if c.x == col else Color.WHITE
```

Same pattern, different index. Row and column helpers are symmetric operations.

Spawn a grid agent.

```gdscript
class_name GridAgent extends CharacterBody3D

var visit_sequence: Array = []
var current_index: int = 0
var step_interval: float = 0.4

func _ready() -> void:
    for y in GRID_SIZE.y:
        for x in GRID_SIZE.x:
            visit_sequence.append(Vector2i(x, y))
```

Row-major order. The agent visits (0,0), (1,0), (2,0), (3,0), (0,1), ... in sequence.

Step the agent.

```gdscript
var time_since_step: float = 0.0

func _process(delta: float) -> void:
    time_since_step += delta
    if time_since_step >= step_interval:
        time_since_step = 0.0
        current_index = (current_index + 1) % visit_sequence.size()
        var coords = visit_sequence[current_index]
        global_position = Vector3(coords.x, 0.5, coords.y)
```

Discrete movement between cells every 0.4 seconds. The learner watches the agent thread through the grid.

Switch traversal order.

```gdscript
enum Order { ROW_MAJOR, COLUMN_MAJOR, DIAGONAL }

func rebuild_sequence(order: Order) -> void:
    visit_sequence.clear()
    match order:
        Order.ROW_MAJOR:
            for y in GRID_SIZE.y:
                for x in GRID_SIZE.x:
                    visit_sequence.append(Vector2i(x, y))
        Order.COLUMN_MAJOR:
            for x in GRID_SIZE.x:
                for y in GRID_SIZE.y:
                    visit_sequence.append(Vector2i(x, y))
        Order.DIAGONAL:
            for d in range(GRID_SIZE.x + GRID_SIZE.y - 1):
                for x in range(max(0, d - GRID_SIZE.y + 1), min(d + 1, GRID_SIZE.x)):
                    visit_sequence.append(Vector2i(x, d - x))
```

Each order produces a different traversal pattern. The learner sees which pattern each order traces.

Convert coordinates to a flat array index.

```gdscript
func flat_index(coords: Vector2i) -> int:
    return coords.y * GRID_SIZE.x + coords.x
```

Row-major flattening. Coord (2, 1) in a 4×4 grid maps to flat index 6.

You can now build a 2D grid, highlight rows and columns, run a grid agent through programmatic traversal, and convert between 2D coordinates and a 1D flat index. Tutorial_3D extends into three dimensions.

<<<MAP: Tutorial_3D>>>
# 3D

Three indices address a volume. Stepped platforms lift the learner to each layer.

Build the 4×4×4 volume.

```gdscript
const VOLUME_SIZE := Vector3i(4, 4, 4)

func build_volume() -> void:
    for x in VOLUME_SIZE.x:
        for y in VOLUME_SIZE.y:
            for z in VOLUME_SIZE.z:
                var cell := CELL_SCENE.instantiate()
                cell.position = Vector3(x, y, z)
                cell.set_meta("coords", Vector3i(x, y, z))
                add_child(cell)
```

Sixty-four cells. Each addressed by three indices.

Read the volume by three indices.

```gdscript
func cell_at(coords: Vector3i) -> Node3D:
    for child in get_children():
        if child.has_meta("coords") and child.get_meta("coords") == coords:
            return child
    return null
```

Metadata lookup. For larger volumes, a direct array indexing scheme would be faster.

Make cells transparent.

```gdscript
func apply_transparency() -> void:
    for child in get_children():
        if child.has_meta("coords"):
            var mat := StandardMaterial3D.new()
            mat.albedo_color = Color(0.5, 0.7, 1.0, 0.4)
            mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
            child.get_node("Mesh").material_override = mat
```

Transparent cells let the learner see through the volume to layers beyond. Alpha of 0.4 is legible without occluding.

Three sliders for highlighting.

```gdscript
var highlight_coords: Vector3i = Vector3i.ZERO

func _on_slider_changed(axis: String, value: float) -> void:
    match axis:
        "x": highlight_coords.x = int(round(value))
        "y": highlight_coords.y = int(round(value))
        "z": highlight_coords.z = int(round(value))
    refresh_highlight()
```

Each slider drives one axis. Together they select a single cell.

Refresh the highlighted cell.

```gdscript
func refresh_highlight() -> void:
    for child in get_children():
        if child.has_meta("coords"):
            var c: Vector3i = child.get_meta("coords")
            var is_selected: bool = c == highlight_coords
            child.scale = Vector3.ONE * (1.1 if is_selected else 1.0)
            child.modulate = Color.YELLOW if is_selected else Color.WHITE
```

Selected cell scales up slightly and changes colour. The rest dim back to base state.

Build stepped platforms.

```gdscript
func build_platforms() -> void:
    for layer in VOLUME_SIZE.y:
        var platform := PLATFORM_SCENE.instantiate()
        platform.position = Vector3(-1, layer, layer)
        platform.scale = Vector3(1, 0.1, 1)
        add_child(platform)
```

Each platform sits one unit to the side and one unit deeper. The staircase rises as the learner climbs.

Show the code for the current cell.

```gdscript
func update_code_display() -> void:
    code_label.text = "grid[%d][%d][%d]" % [highlight_coords.x, highlight_coords.y, highlight_coords.z]
```

The code runs in parallel with the spatial highlight. Three bracket indices match the three slider positions.

You can now build a 4×4×4 volume, render it with transparency, drive highlighting via three sliders, climb stepped platforms to reach each layer, and see the three-index code for each selected cell. Tutorial_Disco extends the array into a temporal dance floor.

<<<MAP: Tutorial_Disco>>>
# Disco

A 17×17 dance floor. Each tile triggers when stepped on. A step sequencer loops the pattern.

Build the floor.

```gdscript
const FLOOR_SIZE := Vector2i(17, 17)

func build_dance_floor() -> void:
    for y in FLOOR_SIZE.y:
        for x in FLOOR_SIZE.x:
            var tile := DANCE_TILE_SCENE.instantiate()
            tile.position = Vector3(x, 0, y)
            tile.set_meta("coords", Vector2i(x, y))
            tile.body_entered.connect(_on_tile_entered.bind(tile))
            add_child(tile)
```

289 tiles. Each is an Area3D that detects body entry.

Handle tile activation.

```gdscript
func _on_tile_entered(tile: Area3D) -> void:
    var coords: Vector2i = tile.get_meta("coords")
    play_tone_for(coords)
    light_tile(tile, 0.5)
    if recording:
        record_in_step(coords)
```

Playback plus recording, depending on current mode.

Map a tile to a pitch.

```gdscript
const PENTATONIC := [0, 2, 4, 7, 9]  # semitones from root

func pitch_for(coords: Vector2i) -> float:
    var scale_index: int = coords.x % PENTATONIC.size()
    var octave: int = coords.y / PENTATONIC.size()
    var semitones: int = octave * 12 + PENTATONIC[scale_index]
    return 440.0 * pow(2.0, (semitones - 9) / 12.0)  # A4 = 440 Hz
```

Pentatonic scale avoids dissonance. The floor's columns map to scale degrees; rows map to octaves.

Light a tile briefly.

```gdscript
func light_tile(tile: Area3D, duration: float) -> void:
    var mesh := tile.get_node("Mesh")
    var original: Color = mesh.material_override.albedo_color
    mesh.material_override.emission_enabled = true
    mesh.material_override.emission = Color(1, 1, 0)
    var tween := create_tween()
    tween.tween_property(mesh.material_override, "emission_energy_multiplier", 0.0, duration)
```

Bright yellow emission that fades over the duration. The visual cue lasts long enough to register but not long enough to overlap with the next beat.

Record into the step sequencer.

```gdscript
var steps: Array = []  # array of arrays of Vector2i
const STEP_COUNT := 16
var current_step: int = 0

func _ready() -> void:
    for _i in STEP_COUNT:
        steps.append([])

func record_in_step(coords: Vector2i) -> void:
    if not coords in steps[current_step]:
        steps[current_step].append(coords)
```

Each step holds the set of tiles active during that beat. Multiple activations at the same beat stack into one step.

Advance the sequencer.

```gdscript
@export var bpm: float = 120.0
var time_since_step: float = 0.0

func _process(delta: float) -> void:
    time_since_step += delta
    var step_duration: float = 60.0 / bpm / 4.0  # 16th notes
    if time_since_step >= step_duration:
        time_since_step = 0.0
        current_step = (current_step + 1) % STEP_COUNT
        play_step(steps[current_step])
```

Tempo-based advancement. At 120 BPM with 16th notes, the sequencer advances every 0.125 seconds.

Play a step.

```gdscript
func play_step(active_tiles: Array) -> void:
    for coords in active_tiles:
        var tile := find_tile(coords)
        if tile:
            play_tone_for(coords)
            light_tile(tile, 0.1)
```

Every tile in the step fires simultaneously. A strummed chord or a polyrhythmic pulse.

You can now build a dance floor, map tiles to pitches via a pentatonic scale, record into a step sequencer, and play the sequence back at any tempo. Chamber_Arrays closes the sequence with arrangement-as-catalyst.

<<<MAP: Chamber_Arrays>>>
# Chamber Arrays

The only chamber without a catalyst. The learner places blocks; the agent adapts.

Set up the chamber grid.

```gdscript
class_name ChamberGrid extends Node3D

const GRID_SIZE := Vector2i(12, 12)
var obstacles: Dictionary = {}  # Vector2i -> bool

func is_blocked(coords: Vector2i) -> bool:
    return obstacles.get(coords, false)

func place_obstacle(coords: Vector2i) -> void:
    obstacles[coords] = true
    emit_signal("obstacles_changed")

func clear_obstacle(coords: Vector2i) -> void:
    obstacles.erase(coords)
    emit_signal("obstacles_changed")
```

A dictionary stores which cells are blocked. A signal lets listeners react to changes.

Let the learner place blocks.

```gdscript
func _on_trigger_pressed() -> void:
    var aim_direction: Vector3 = -controller.global_transform.basis.z
    var hit: Dictionary = raycast_for_cell(controller.global_position, aim_direction)
    if hit.is_empty(): return
    var coords: Vector2i = hit.coords
    if chamber.is_blocked(coords):
        chamber.clear_obstacle(coords)
    else:
        chamber.place_obstacle(coords)
```

Aim at a cell, pull the trigger. Toggle between placed and clear.

Build the grid agent.

```gdscript
class_name GridAgent extends CharacterBody3D

var plan: Array = []  # visit order
var current_cell: Vector2i
var path: Array = []  # current path being walked

func compute_plan() -> void:
    plan.clear()
    for y in chamber.GRID_SIZE.y:
        for x in chamber.GRID_SIZE.x:
            var c := Vector2i(x, y)
            if not chamber.is_blocked(c):
                plan.append(c)
```

Row-major visit order, skipping blocked cells.

Pathfind around obstacles with BFS.

```gdscript
func bfs_path(start: Vector2i, goal: Vector2i) -> Array:
    var came_from := {start: null}
    var queue: Array = [start]
    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        if current == goal: break
        for neighbour in [current + Vector2i(1, 0), current + Vector2i(-1, 0), current + Vector2i(0, 1), current + Vector2i(0, -1)]:
            if chamber.is_blocked(neighbour): continue
            if neighbour in came_from: continue
            came_from[neighbour] = current
            queue.append(neighbour)
    var result: Array = []
    var c: Vector2i = goal
    while c != null:
        result.push_front(c)
        c = came_from.get(c)
    return result
```

BFS guarantees the shortest path on an unweighted grid. The came_from dictionary lets the path be reconstructed after the search.

Walk the path.

```gdscript
func _process(delta: float) -> void:
    if path.is_empty():
        var next: Vector2i = next_unvisited_cell()
        if next == Vector2i(-1, -1): return
        path = bfs_path(current_cell, next)
    time_since_step += delta
    if time_since_step > 0.2:
        time_since_step = 0.0
        current_cell = path.pop_front()
        global_position = Vector3(current_cell.x, 0.3, current_cell.y)
```

One step every 0.2 seconds. The agent moves deliberately so the learner can watch its path choice.

Respond to obstacle changes.

```gdscript
func _on_obstacles_changed() -> void:
    compute_plan()
    path.clear()  # re-plan from current position
```

Every placement or removal triggers a replan. The agent adapts immediately.

Display the plan on the science screen.

```gdscript
func update_plan_display() -> void:
    var label_text: String = ""
    for i in plan.size():
        var c: Vector2i = plan[i]
        label_text += "(%d,%d) " % [c.x, c.y]
        if i % 6 == 5: label_text += "\n"
    plan_display.text = label_text
```

The plan is a linear list of cell indices. The display wraps every six cells for readability.

You can now build a chamber grid, place and clear obstacles, pathfind around them with BFS, and render the agent's plan as a sequence of indices. The Array Tutorial sequence hands you back to the Lab with array arrangement as a new mode of catalyst practice.
