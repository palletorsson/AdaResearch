<<<ADA_BUNDLE>>>
sequence: array_tutorial
file: technical.md
maps: 7
skipped_passing: 1
created: 2026-04-24T01:20:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Tutorial_Pattern>>>
# Tutorial Pattern — Technical

Four tile stations compute colours from cell coordinates. Each station exposes a rule, and the rule's output populates a small 2D array that is rendered as a texture.

```gdscript
class_name PatternTile extends Node3D

@export var size: Vector2i = Vector2i(8, 8)
@export var rule: String = "checkerboard"
@export var palette: Array = [Color.BLACK, Color.WHITE, Color(0.9, 0.5, 0.2), Color(0.2, 0.5, 0.9)]

var grid: Array = []  # 2D array of palette indices

func regenerate() -> void:
    grid.clear()
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            row.append(rule_value(x, y))
        grid.append(row)
    update_texture()

func rule_value(x: int, y: int) -> int:
    match rule:
        "checkerboard": return (x + y) % 2
        "stripes": return y % 2
        "wave": return int(sin(x * 0.3) * 2 + 2) % palette.size()
        "radial": return int(Vector2(x - size.x/2, y - size.y/2).length()) % palette.size()
    return 0
```

## Texture Update

The grid is written to an Image, which is pushed to an ImageTexture for rendering. Updating the texture is O(W·H); at 8×8 the cost is negligible.

```gdscript
func update_texture() -> void:
    var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
    for y in range(size.y):
        for x in range(size.x):
            image.set_pixel(x, y, palette[grid[y][x]])
    texture = ImageTexture.create_from_image(image)
```

## Tiling Preview

A large preview board tiles the 8×8 pattern across a much bigger surface. The tiling uses UV coordinates with wrapping enabled.

```gdscript
# Shader UV wrapping
uniform sampler2D tile_texture : repeat_enable;

void fragment() {
    vec2 tiled_uv = UV * vec2(TILE_REPEAT_X, TILE_REPEAT_Y);
    ALBEDO = texture(tile_texture, tiled_uv).rgb;
}
```

## Symmetry Modes

A toggle switches between direct tiling and mirrored tiling. Mirror mode flips alternate tiles horizontally and/or vertically.

```gdscript
// Shader mirror mode
void fragment() {
    vec2 tile_uv = fract(UV * TILE_REPEAT);
    vec2 tile_idx = floor(UV * TILE_REPEAT);
    if (mod(tile_idx.x, 2.0) == 1.0) tile_uv.x = 1.0 - tile_uv.x;
    if (mod(tile_idx.y, 2.0) == 1.0) tile_uv.y = 1.0 - tile_uv.y;
    ALBEDO = texture(tile_texture, tile_uv).rgb;
}
```

## Custom Rule Parser

The fourth station exposes the rule as an editable expression. A small parser converts the expression string into a function the grid can evaluate.

```gdscript
class_name RuleExpression

var expression: String = "(x + y) % 2"

func evaluate(x: int, y: int) -> int:
    var expr := Expression.new()
    var error := expr.parse(expression, ["x", "y"])
    if error != OK: return 0
    var result = expr.execute([x, y])
    if expr.has_execute_failed(): return 0
    return int(result)
```

Godot's built-in Expression class handles parsing and evaluation for simple arithmetic expressions, which is adequate for teaching rule composition.

## Complexity

Rule evaluation is O(1) per cell; full regeneration is O(W·H). At typical tile sizes (up to 16×16) the regeneration is imperceptible even when driven by slider movement.

Within the sequence, Tutorial_Pattern is the pivot from addressing to rhyming. Array_Patterns will next push the technique into wallpaper-group symmetries.

<<<MAP: Tutorial_Single>>>
# Tutorial Single — Technical

The map's only artifact is a single grabbable cube. The grab mechanism follows Godot's standard XRController3D input pattern.

```gdscript
class_name GrabbableCube extends RigidBody3D

@export var grab_distance: float = 0.3

var grabbing_controller: XRController3D = null

func _physics_process(_delta: float) -> void:
    if grabbing_controller != null:
        freeze = true
        global_position = grabbing_controller.global_position
    else:
        freeze = false

func _on_controller_button_pressed(button: String, controller: XRController3D) -> void:
    if button != "grip" and button != "trigger": return
    if grabbing_controller == null:
        var distance: float = controller.global_position.distance_to(global_position)
        if distance < grab_distance:
            grabbing_controller = controller

func _on_controller_button_released(button: String, controller: XRController3D) -> void:
    if controller == grabbing_controller:
        grabbing_controller = null
```

## Platform Dimensions

The platform is deliberately small: 4 cells × 3 cells at 1 metre per cell. Godot's CharacterBody3D with a collision layer restricts the learner to the platform surface.

## Teleporter Exit

The teleporter is an Area3D that triggers a scene transition when the learner enters.

```gdscript
class_name Teleporter extends Area3D

@export var target_map: String = ""

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("learner"):
        get_tree().change_scene_to_file("res://commons/maps/" + target_map + "/map.tscn")
```

## VR Input Contract

Godot 4's XR system exposes controller inputs as signals. The relevant signals for the tutorial are `button_pressed`, `button_released`, and `axis_changed`. Grip and trigger produce button events; joystick and trackpad produce axis events.

```gdscript
# Signal connections in _ready
var controllers := get_tree().get_nodes_in_group("xr_controllers")
for controller in controllers:
    controller.button_pressed.connect(_on_controller_button_pressed.bind(controller))
    controller.button_released.connect(_on_controller_button_released.bind(controller))
```

## Haptic Feedback

When the cube is grabbed, a brief haptic pulse confirms the action. The pulse uses the controller's built-in rumble.

```gdscript
func trigger_haptic_pulse(controller: XRController3D, intensity: float = 0.5, duration: float = 0.1) -> void:
    controller.trigger_haptic_pulse("haptic", 0.0, intensity, duration, 0.0)
```

## Accessibility

Some learners cannot close their hand around the cube (hand-tracking limitation or physical constraint). The map accepts grip-button press as a substitute for the grab gesture, and the tutorial diagram shows both.

## Complexity

The grab-and-release logic is O(1) per frame. The scene is minimal — one cube, one platform, one teleporter, one reference diagram. The whole map loads in under 200 milliseconds on typical hardware.

Within the sequence, Tutorial_Single is the VR baseline. Tutorial_Row will next add the first dimension and convert the grip into directed traversal.

<<<MAP: Tutorial_Row>>>
# Tutorial Row — Technical

The corridor is a 7-column × 9-row grid, but only the central column is walkable. A rig along the central lane constrains movement to the Z axis.

```gdscript
class_name LaneRig extends Node3D

@export var allowed_lane_x: int = 3  # central column index
@export var cell_size: float = 1.0

func _physics_process(_delta: float) -> void:
    var learner = get_tree().get_first_node_in_group("learner")
    if learner == null: return
    # Clamp X to the allowed lane
    var target_x: float = allowed_lane_x * cell_size
    learner.global_position.x = lerp(learner.global_position.x, target_x, 0.1)
```

## Index Counter

The counter on the wall reads the learner's current lane position as an array index.

```gdscript
class_name IndexCounter extends Node3D

@export var cell_size: float = 1.0
@export var row_count: int = 9

var label: Label3D

func _process(_delta: float) -> void:
    var learner = get_tree().get_first_node_in_group("learner")
    var index: int = clamp(int(learner.global_position.z / cell_size), 0, row_count - 1)
    label.text = "row[%d]" % index
```

## Code Highlighting

The code panel displays the corresponding GDScript and highlights the currently-indexed line. A syntax highlighter adds colour; the highlight overlay is a simple ColorRect anchored to the active line.

```gdscript
class_name CodePanel extends Control

var code_lines: Array = [
    "var row = [0, 1, 2, 3, 4, 5, 6, 7, 8]",
    "var i = 0",
    "print(row[i])"
]

func update_highlight(i: int) -> void:
    for line_index in range(code_lines.size()):
        var line_control := get_node("Line%d" % line_index)
        line_control.modulate = Color.YELLOW if line_index == 2 else Color.WHITE
```

## Movement Smoothing

The Z-axis movement uses a small smoothing factor (lerp at 0.1 per frame) so the constraint feels gentle rather than hard. Hard constraints can trigger VR motion sickness if they produce sudden position changes.

## Complexity

Everything in the map is O(1) per frame. The corridor's meshes are static and cost nothing after load.

## Accessibility Variant

Learners who prefer not to walk can use a teleport-to-cell control that jumps the learner directly to a chosen cell. The variant preserves the array-indexing pedagogy without requiring physical movement.

Within the sequence, Tutorial_Row is the first dimensional leap. Tutorial_2D_Build will next add the second dimension.

<<<MAP: Tutorial_2D_Build>>>
# Tutorial 2D Build — Technical

The grid is a flat 4×4 plane; each cell is labelled with its (row, column) indices. Two helpers expose row and column operations, and a grid agent performs programmatic traversal.

```gdscript
class_name Grid2D extends Node3D

@export var size: Vector2i = Vector2i(4, 4)
@export var cell_size: float = 1.0

var cell_nodes: Array = []  # 2D array of cell Node3Ds

func _ready() -> void:
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            var cell := create_cell(x, y)
            row.append(cell)
        cell_nodes.append(row)

func create_cell(x: int, y: int) -> Node3D:
    var cell := GRID_CELL_SCENE.instantiate()
    cell.position = Vector3(x, 0, y) * cell_size
    cell.get_node("Label").text = "(%d, %d)" % [y, x]
    add_child(cell)
    return cell
```

## Row Helper

Pressing the row helper highlights every cell in a selected row.

```gdscript
class_name RowHelper extends Node3D

@export var grid: Grid2D
var selected_row: int = 0

func highlight_row(row_index: int) -> void:
    for y in range(grid.size.y):
        for x in range(grid.size.x):
            var highlight: bool = (y == row_index)
            grid.cell_nodes[y][x].set_highlight(highlight)
    selected_row = row_index

func _on_cycle_button_pressed() -> void:
    selected_row = (selected_row + 1) % grid.size.y
    highlight_row(selected_row)
```

## Column Helper

Analogous to the row helper but operates on the x axis.

## Grid Agent

The grid agent follows a traversal order and visits every cell. Three modes are available: row-major, column-major, and diagonal.

```gdscript
class_name GridAgent extends CharacterBody3D

@export var grid: Grid2D
@export var step_interval: float = 0.5
@export var order: String = "row_major"

var visit_sequence: Array = []
var current_index: int = 0
var time_since_step: float = 0.0

func _ready() -> void:
    build_sequence()

func build_sequence() -> void:
    visit_sequence.clear()
    match order:
        "row_major":
            for y in range(grid.size.y):
                for x in range(grid.size.x):
                    visit_sequence.append(Vector2i(x, y))
        "column_major":
            for x in range(grid.size.x):
                for y in range(grid.size.y):
                    visit_sequence.append(Vector2i(x, y))
        "diagonal":
            for d in range(grid.size.x + grid.size.y - 1):
                for x in range(max(0, d - grid.size.y + 1), min(d + 1, grid.size.x)):
                    visit_sequence.append(Vector2i(x, d - x))

func _process(delta: float) -> void:
    time_since_step += delta
    if time_since_step >= step_interval:
        time_since_step = 0.0
        current_index = (current_index + 1) % visit_sequence.size()
        move_to_cell(visit_sequence[current_index])
```

## Complexity

Grid setup is O(W·H). Helpers are O(W·H) per highlight update. Agent traversal is O(1) per step with a precomputed sequence of length W·H.

Within the sequence, Tutorial_2D_Build introduces the coordinate pair. Tutorial_3D will next add the third dimension.

<<<MAP: Tutorial_3D>>>
# Tutorial 3D — Technical

A 4×4×4 volume of cells, addressed by three indices. Stepped platforms and lifts provide physical access to upper layers.

```gdscript
class_name Volume3D extends Node3D

@export var size: Vector3i = Vector3i(4, 4, 4)
@export var cell_size: float = 1.0

var cells: Array = []  # 3D array of Node3D

func _ready() -> void:
    for x in range(size.x):
        cells.append([])
        for y in range(size.y):
            cells[x].append([])
            for z in range(size.z):
                var cell := create_cell(x, y, z)
                cells[x][y].append(cell)
```

## Layer Transparency

The volume is rendered with transparent cells so layers above and below are visible. Transparency uses a shader that writes to the alpha channel.

```glsl
void fragment() {
    ALPHA = 0.3;
    ALBEDO = base_color.rgb;
}
```

Transparent geometry in Godot requires careful render-ordering to avoid sorting artefacts. The engine sorts transparent objects back-to-front per frame; scenes with hundreds of transparent cells can show visible sorting errors when cells overlap.

## Three-Slider Highlight

Three sliders — one per axis — select row, column, and layer independently. The highlight cube's position updates as the sliders move.

```gdscript
class_name HighlightController extends Node3D

@export var volume: Volume3D
var highlight_node: Node3D

func _process(_delta: float) -> void:
    var x: int = int(slider_x.value)
    var y: int = int(slider_y.value)
    var z: int = int(slider_z.value)
    highlight_node.position = Vector3(x, y, z) * volume.cell_size
    code_label.text = "grid[%d][%d][%d]" % [x, y, z]
```

## Platform Generation

Stepped platforms are generated procedurally to match the volume's size. Each platform is a flat plane with a bordering railing.

```gdscript
func build_stepped_platform_north(height: int) -> void:
    for h in range(height):
        var platform := PLATFORM_SCENE.instantiate()
        platform.position = Vector3(-1, h * cell_size, h * cell_size)
        add_child(platform)
```

## Lift Mechanism

Two corner lifts provide faster vertical access. A lift is an Area3D that smoothly translates the learner up or down.

```gdscript
class_name Lift extends Area3D

@export var target_height: float = 4.0
@export var lift_speed: float = 2.0

var active_bodies: Array = []

func _physics_process(delta: float) -> void:
    for body in active_bodies:
        var target_y: float = global_position.y + target_height
        body.global_position.y = move_toward(body.global_position.y, target_y, lift_speed * delta)
```

## Accessibility

Vertical navigation can be challenging in VR. The map provides a direct teleport control as an alternative to the platforms and lifts — click a cell on a 2D selector to teleport directly to it.

## Complexity

Volume generation is O(W·H·D). At 4×4×4 that is 64 cells; rendering cost is dominated by the transparency rather than by cell count.

Within the sequence, Tutorial_3D completes the dimensional ladder. Tutorial_Pattern will next pivot from addressing to generation.

<<<MAP: Tutorial_Disco>>>
# Tutorial Disco — Technical

A 17×17 dance floor of Area3D tiles, each triggering an audio and visual response when stepped on. A step sequencer captures activations into a loop that plays back at a configurable tempo.

```gdscript
class_name DanceFloor extends Node3D

@export var size: Vector2i = Vector2i(17, 17)
@export var tile_size: float = 0.8

var tiles: Array = []  # 2D array

func _ready() -> void:
    for y in range(size.y):
        var row: Array = []
        for x in range(size.x):
            var tile := DanceTile.new()
            tile.position = Vector3(x, 0, y) * tile_size
            tile.coordinates = Vector2i(x, y)
            tile.body_entered.connect(_on_tile_activated.bind(tile))
            add_child(tile)
            row.append(tile)
        tiles.append(row)
```

## Step Sequencer

The sequencer divides a short loop into steps and advances one step per tick. Each step's contents are the set of tiles that were active during that step.

```gdscript
class_name StepSequencer extends Node

@export var steps: int = 16
@export var bpm: float = 120.0

var step_contents: Array = []  # array of arrays of Vector2i
var current_step: int = 0
var time_since_step: float = 0.0

func _ready() -> void:
    for _i in range(steps):
        step_contents.append([])

func _process(delta: float) -> void:
    time_since_step += delta
    var step_interval: float = 60.0 / bpm / 4.0  # 16th notes
    if time_since_step >= step_interval:
        time_since_step = 0.0
        current_step = (current_step + 1) % steps
        play_step(step_contents[current_step])

func record_tile(coords: Vector2i) -> void:
    if not coords in step_contents[current_step]:
        step_contents[current_step].append(coords)
```

## Mode Switch

Mode buttons change what `play_step` does with the active tiles.

```gdscript
enum Mode { TONE, LIGHT, PROPAGATE }

@export var mode: Mode = Mode.TONE

func play_step(active_tiles: Array) -> void:
    for coords in active_tiles:
        match mode:
            Mode.TONE:
                play_tone_at(coords)
            Mode.LIGHT:
                light_tile(coords, 0.25)  # one beat
            Mode.PROPAGATE:
                propagate_to_neighbours(coords)
```

## Tone Mapping

Each tile's x-coordinate maps to a scale degree and its y-coordinate maps to an octave. A pentatonic scale (C, D, E, G, A) avoids dissonance regardless of which tiles are active simultaneously.

```gdscript
const PENTATONIC := [0, 2, 4, 7, 9]  # semitones from C

func pitch_for_tile(coords: Vector2i) -> float:
    var scale_degree: int = coords.x % PENTATONIC.size()
    var octave: int = coords.y / PENTATONIC.size() - 1
    var semitones: int = octave * 12 + PENTATONIC[scale_degree]
    return 440.0 * pow(2.0, (semitones - 9) / 12.0)  # A4 = 440 Hz
```

## Propagation Mode

In propagate mode, an active tile lights its neighbours briefly. Over successive steps the activation spreads across the floor.

```gdscript
func propagate_to_neighbours(coords: Vector2i) -> void:
    for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
        var neighbour_coords := coords + offset
        if neighbour_coords.x < 0 or neighbour_coords.x >= tiles.size(): continue
        if neighbour_coords.y < 0 or neighbour_coords.y >= tiles[0].size(): continue
        tiles[neighbour_coords.x][neighbour_coords.y].flash()
```

## Complexity

Tile setup is O(W·H) — 289 tiles at 17×17. Sequencer playback is O(active tiles per step), typically under 10. The visual effects dominate CPU cost, but the rendering is batched via MultiMeshInstance3D so the frame rate stays high.

Within the sequence, Tutorial_Disco is the playful capstone. The array-as-authoring-surface interpretation sets up the compositional concerns of the Wavefunctions sequence.

<<<MAP: Chamber_Arrays>>>
# Chamber Arrays — Technical

The chamber has no catalyst mode. The learner places obstacle blocks on a grid floor; a grid agent adapts its traversal path to avoid the obstacles.

```gdscript
class_name ChamberGrid extends Node3D

@export var size: Vector2i = Vector2i(12, 12)
@export var cell_size: float = 1.0

var obstacles: Dictionary = {}  # Vector2i -> bool

func place_obstacle(coords: Vector2i) -> void:
    obstacles[coords] = true
    emit_signal("obstacles_changed")

func clear_obstacle(coords: Vector2i) -> void:
    obstacles.erase(coords)
    emit_signal("obstacles_changed")

func is_blocked(coords: Vector2i) -> bool:
    return obstacles.get(coords, false)
```

## Grid Agent

The agent performs row-major scanning with detours around obstacles. When a blocked cell is encountered, the agent executes a breadth-first search to find the nearest reachable unvisited cell.

```gdscript
class_name GridAgent extends CharacterBody3D

var visit_order: Array = []
var visited: Dictionary = {}
var current_target: Vector2i

func compute_plan() -> void:
    visit_order.clear()
    for y in range(chamber.size.y):
        for x in range(chamber.size.x):
            var c := Vector2i(x, y)
            if not chamber.is_blocked(c):
                visit_order.append(c)

func next_target() -> Vector2i:
    for c in visit_order:
        if not c in visited and not chamber.is_blocked(c):
            return c
    return Vector2i(-1, -1)

func step_along_path() -> void:
    if path.is_empty():
        var target := next_target()
        path = bfs_path(current_cell, target)
    if path.is_empty(): return
    current_cell = path.pop_front()
    visited[current_cell] = true
    global_position = Vector3(current_cell.x, 0, current_cell.y) * chamber.cell_size
```

## BFS Pathfinding

The agent's pathfinding uses breadth-first search on the unblocked cells.

```gdscript
func bfs_path(start: Vector2i, goal: Vector2i) -> Array:
    var came_from := {start: null}
    var queue := [start]
    while not queue.is_empty():
        var current: Vector2i = queue.pop_front()
        if current == goal: break
        for neighbour in neighbours(current):
            if chamber.is_blocked(neighbour): continue
            if neighbour in came_from: continue
            came_from[neighbour] = current
            queue.append(neighbour)
    # Reconstruct path
    if not goal in came_from: return []
    var path: Array = []
    var c: Vector2i = goal
    while c != null:
        path.push_front(c)
        c = came_from[c]
    path.pop_front()  # remove start
    return path
```

## Science Screen

The wall display renders the agent's current plan as a sequence of cell indices. When obstacles are added or removed, the plan updates and the affected indices are highlighted.

```gdscript
class_name PlanDisplay extends Node3D

@export var agent: GridAgent

var last_plan: Array = []

func _process(_delta: float) -> void:
    var plan := agent.visit_order
    var diff_indices := compute_diff(last_plan, plan)
    render_plan(plan, diff_indices)
    last_plan = plan.duplicate()

func compute_diff(old_plan: Array, new_plan: Array) -> Array:
    var diffs: Array = []
    for i in range(min(old_plan.size(), new_plan.size())):
        if old_plan[i] != new_plan[i]:
            diffs.append(i)
    return diffs
```

## Step Counter

A second display tracks how many extra steps each new obstacle costs. The baseline is the step count for an unobstructed plan; each obstacle adds the detour length.

```gdscript
func extra_steps_from_obstacle(obstacle: Vector2i) -> int:
    var original_distance: int = chebyshev_distance_through_grid(start, goal)
    var detoured_distance: int = bfs_path(start, goal).size()
    return detoured_distance - original_distance
```

## Complexity

BFS is O(V + E) = O(W·H) for the chamber's grid. Plan recomputation happens on every obstacle change — in the worst case several times per second of the learner's placement rate. The plan display update is O(plan size) per frame; the plan holds at most W·H cells.

Within the sequence, Chamber_Arrays closes Array Tutorial with arrangement-as-catalyst. The chamber hands the learner back to the Lab with a body-level sense that arrays hold state and state responds to what is placed in it.
