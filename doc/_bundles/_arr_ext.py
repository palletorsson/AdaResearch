import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

adds = {
'Tutorial_Pattern': """

## Palette Storage

Palettes are stored as arrays of Color. The array's length is the palette size; indices into the array reference specific colours. This indirection — cell value is an index, not a colour — allows the palette to be retoned without touching cell data.

```gdscript
var palette: Array[Color] = [Color.BLACK, Color.WHITE, Color(0.9, 0.3, 0.3), Color(0.3, 0.5, 0.9)]

func retone_palette(new_palette: Array[Color]) -> void:
    palette = new_palette
    regenerate()  # re-draw the grid with the new palette
```

## Common Rule Library

A library of built-in rules gives the learner starting points. Each rule takes (x, y) cell coordinates and returns a palette index.

```gdscript
const RULE_LIBRARY := {
    "checkerboard": func(x, y): return (x + y) % 2,
    "diagonal_stripes": func(x, y): return (x + y) % 4 / 2,
    "grid_intersection": func(x, y): return 1 if (x % 3 == 0 or y % 3 == 0) else 0,
    "spiral": func(x, y):
        var cx = size.x / 2
        var cy = size.y / 2
        var angle = atan2(y - cy, x - cx)
        return int((angle + PI) / TAU * palette.size()) % palette.size(),
}
```

## Shader-Based Version

For large tiles or complex rules, a shader-based version runs the rule per-pixel on the GPU. The shader's fragment function takes UV coordinates and returns a colour.

```glsl
void fragment() {
    vec2 cell = floor(UV * tile_size);
    float rule_value = mod(cell.x + cell.y, 2.0);
    ALBEDO = mix(palette[0].rgb, palette[1].rgb, rule_value);
}
```

The shader can evaluate the rule at sub-pixel resolution, producing anti-aliased edges for free.

## Interactive Tile Editing

A fourth mode lets the learner paint cells manually. Each cell is clickable; clicking cycles through palette indices.

```gdscript
func _on_cell_clicked(x: int, y: int) -> void:
    grid[y][x] = (grid[y][x] + 1) % palette.size()
    update_texture()
```

The painted pattern is also tiled across the preview board — the learner's hand-made patterns enter the same compositional frame as the rule-generated ones.
""",

'Tutorial_Single': """

## Physics Mode

When not grabbed, the cube is a RigidBody3D subject to gravity. Dropping it from a height produces realistic bouncing. The cube's mass (1 kg) and friction (0.5) are tuned for satisfying physical behaviour.

```gdscript
@export var mass_kg: float = 1.0
@export var friction: float = 0.5
@export var restitution: float = 0.3

func _ready() -> void:
    mass = mass_kg
    physics_material_override = PhysicsMaterial.new()
    physics_material_override.friction = friction
    physics_material_override.bounce = restitution
```

## Grab Stability

When the cube is grabbed, it is frozen (kinematic) and parented to the controller transform. This prevents it from being pushed around by collision with the hand.

```gdscript
func on_grabbed(controller: XRController3D) -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    reparent(controller)

func on_released() -> void:
    reparent(get_tree().root.get_node("World"))
    freeze = false
    # Inherit the controller's velocity at release
    linear_velocity = last_controller_velocity
    angular_velocity = last_controller_angular_velocity
```

The inherited velocity produces satisfying throw behaviour — releasing the cube while moving the controller launches it in the direction of motion.

## Collision Layer

The cube's collision layer is configured so it interacts with the platform but not with the teleporter Area3D. Collision layer masks in Godot are bit flags; the cube is on layer 2 and collides with layers 1 (world) and 2 (other grabbables) but not layer 3 (triggers).

## Tutorial Diagram

The reference diagram shows three states: open hand approaching, closed hand grabbing, open hand releasing. Each state has an arrow and a caption.

```gdscript
class_name TutorialDiagram extends Node3D

func _ready() -> void:
    $OpenApproachingLabel.text = "Open hand approaches"
    $ClosedGrabLabel.text = "Close hand: object attaches"
    $OpenReleaseLabel.text = "Open hand: object releases"
```

## Accessibility

The map supports three interaction modes: VR hand-tracking, VR controller grip, and desktop mouse click. The scene detects the active input method and shows the matching diagram.
""",

'Tutorial_Row': """

## Lane Visualisation

The central lane is marked with a subtle coloured strip on the floor. The buffer columns on either side use darker tones so the eye naturally follows the lane.

```gdscript
func _ready() -> void:
    for y in range(row_count):
        var cell := FLOOR_CELL_SCENE.instantiate()
        cell.position = Vector3(allowed_lane_x, 0, y) * cell_size
        cell.modulate = Color(0.9, 0.8, 0.3)  # highlighted lane
        add_child(cell)
        for x in [0, 1, 2, 4, 5, 6]:
            var buffer := FLOOR_CELL_SCENE.instantiate()
            buffer.position = Vector3(x, 0, y) * cell_size
            buffer.modulate = Color(0.4, 0.4, 0.4)
            add_child(buffer)
```

## Index Increment Feedback

Each time the learner crosses a cell boundary, a small audio cue plays. The cue's pitch ramps up as the index grows, giving audible feedback of progress.

```gdscript
var last_index: int = -1

func _process(_delta: float) -> void:
    var current_index: int = int(learner.global_position.z / cell_size)
    if current_index != last_index:
        play_index_sound(current_index)
        last_index = current_index

func play_index_sound(index: int) -> void:
    var base_freq: float = 330.0
    var freq: float = base_freq * pow(1.1, index)  # rising pitch
    tone_player.pitch_scale = freq / base_freq
    tone_player.play()
```

## Syntax Highlighting

The code panel highlights the current array-access expression with a yellow tint. A second highlight shows the variable `i` being updated as the learner moves.

```gdscript
var code_lines := [
    "var row = [0, 1, 2, 3, 4, 5, 6, 7, 8]",
    "var i: int",
    "i = %d  # your position",
    "print(row[i])  # %d",
]

func update_code_display(index: int) -> void:
    code_label.text = "\\n".join([
        code_lines[0],
        code_lines[1],
        code_lines[2] % index,
        code_lines[3] % index,
    ])
```

## Backward Movement

Walking backward decrements the index. The audio cue's pitch drops, and the code display reflects the new value. The index is clamped to [0, row_count - 1] so the learner cannot step past either end of the array.
""",

'Tutorial_2D_Build': """

## Cell Identity

Each cell is a small Area3D with its coordinates stored as metadata. The Area3D's `body_entered` signal connects to a handler that updates the currently-highlighted cell.

```gdscript
class_name GridCell extends Area3D

@export var coordinates: Vector2i

signal learner_entered(coords: Vector2i)

func _on_body_entered(body: Node) -> void:
    if body.is_in_group("learner"):
        learner_entered.emit(coordinates)
```

## Helper Cycling

Each helper has a button that advances through row or column indices. Holding the button triggers auto-advance at a fixed rate.

```gdscript
class_name IndexHelper extends Node3D

@export var max_index: int = 4
@export var auto_advance_rate: float = 2.0  # indices per second

var current_index: int = 0
var button_held: bool = false
var time_since_advance: float = 0.0

func _process(delta: float) -> void:
    if not button_held: return
    time_since_advance += delta
    if time_since_advance >= 1.0 / auto_advance_rate:
        time_since_advance = 0.0
        advance()

func advance() -> void:
    current_index = (current_index + 1) % max_index
    emit_signal("index_changed", current_index)
```

## Highlight Rendering

Highlighted cells render with an emission-on shader material. The highlight fades in and out smoothly rather than snapping on.

```glsl
shader_type spatial;
uniform float highlight_strength : hint_range(0.0, 1.0);
uniform vec3 base_color;
uniform vec3 highlight_color;

void fragment() {
    vec3 final_color = mix(base_color, highlight_color, highlight_strength);
    ALBEDO = final_color;
    EMISSION = highlight_color * highlight_strength * 0.3;
}
```

## Agent Movement Smoothing

The grid agent's movement uses ease-in-out interpolation between cells rather than linear movement. The smoothing makes the traversal feel deliberate rather than robotic.

```gdscript
func _process(delta: float) -> void:
    time_since_step += delta
    var t: float = clamp(time_since_step / step_interval, 0.0, 1.0)
    var eased_t: float = ease(t, 0.5)  # ease-in-out
    global_position = last_cell_position.lerp(next_cell_position, eased_t)
```

## Accessibility

The map supports keyboard-only navigation for learners who cannot use VR. Arrow keys move the highlighted selection, Enter invokes the helper, and Tab switches between helpers and agent.
""",

'Tutorial_3D': """

## Volume Rendering

The transparent volume is rendered with order-independent transparency (OIT) to avoid the sorting artefacts that back-to-front rendering produces. OIT accumulates all transparent fragments into a shared buffer with per-fragment weights, then composites them in a single pass.

```glsl
// OIT accumulation
uniform vec4 src_color;
out vec4 fragAccum;
out float fragRevealage;

void fragment() {
    float weight = clamp(src_color.a * 10.0, 0.01, 3.0);
    fragAccum = vec4(src_color.rgb * src_color.a * weight, src_color.a);
    fragRevealage = src_color.a * weight;
}
```

Godot 4 does not provide OIT out of the box; the map falls back to standard back-to-front sorting, which is adequate at the 4×4×4 volume size but would need OIT at larger scales.

## Slider Mapping

The three sliders are integer-valued — dragging continuously snaps to the nearest integer. The snap provides tactile feedback in VR; the slider feels like it "clicks" into each index.

```gdscript
func _on_slider_changed(slider: Slider, axis: String) -> void:
    var snapped: int = int(round(slider.value))
    if snapped != current_indices[axis]:
        current_indices[axis] = snapped
        update_highlight()
        play_click_sound()
```

## Code Display

The code label shows `grid[x][y][z]` with the current indices substituted in. A second line shows the flat-array equivalent: `grid[x + y * size_x + z * size_x * size_y]`.

```gdscript
func update_code_display(indices: Vector3i) -> void:
    code_label.text = "grid[%d][%d][%d]\\n# or equivalently:\\ngrid[%d]" % [
        indices.x, indices.y, indices.z,
        indices.x + indices.y * size.x + indices.z * size.x * size.y
    ]
```

## Row-Major vs Column-Major

Different languages and libraries use different storage orders. GDScript's nested arrays are effectively row-major (x varies fastest). NumPy defaults to row-major but can use column-major. Fortran uses column-major. The map notes this on a side panel — the physical volume is order-agnostic but the flat-index formula depends on the convention.

## Platform Ascent

The stepped platforms on two sides let the learner walk up through the layers. Each step is 0.5 metres high, which is a comfortable VR step size. Lifts provide faster vertical travel for learners who prefer not to climb.

## Transparency Limitations

Transparent rendering costs more than opaque rendering per pixel. For large volumes or many overlapping transparents, performance can drop noticeably. The map caps volume size at 4×4×4 and uses conservative transparency alpha (0.3) to keep the cost manageable.
""",

'Tutorial_Disco': """

## Audio Mixing

With 17×17 = 289 possible tone sources, naive per-tile AudioStreamPlayers would exhaust Godot's audio polyphony limits. The map uses a shared audio bus with an oscillator pool: a fixed number of oscillators (say 16) are dynamically assigned to currently-active tiles.

```gdscript
class_name OscillatorPool extends Node

var oscillators: Array = []
const POOL_SIZE := 16

func _ready() -> void:
    for _i in range(POOL_SIZE):
        var osc := AudioStreamPlayer.new()
        osc.stream = preload("res://audio/base_tone.tres")
        add_child(osc)
        oscillators.append(osc)

func play_pitch(pitch: float) -> void:
    for osc in oscillators:
        if not osc.playing:
            osc.pitch_scale = pitch
            osc.play()
            return
    # All oscillators in use — steal the oldest
    var oldest := find_oldest_playing()
    oldest.stop()
    oldest.pitch_scale = pitch
    oldest.play()
```

## Sequencer Persistence

The sequencer's state can be saved and loaded. Each save is a list of (step_index, [tile_coords]) pairs.

```gdscript
func save_pattern(name: String) -> void:
    var save_data := {
        "bpm": bpm,
        "steps": step_contents,
        "mode": mode,
    }
    var file := FileAccess.open("user://disco_%s.json" % name, FileAccess.WRITE)
    file.store_string(JSON.stringify(save_data))
```

## Metronome

A visual metronome marks the current step. It can be a row of lights at the floor's edge that pulse in sync with the beat, or a digital readout showing step/beat numbers.

```gdscript
class_name Metronome extends Node3D

@export var indicator_lights: Array[Node3D]

func update_step(step_index: int, total_steps: int) -> void:
    for i in range(indicator_lights.size()):
        var light := indicator_lights[i]
        var active: bool = (i == step_index * indicator_lights.size() / total_steps)
        light.get_node("MeshInstance3D").material_override.emission_energy_multiplier = 2.0 if active else 0.2
```

## Record vs Playback

A record toggle distinguishes modes. In record mode, stepping on tiles captures them into the sequencer's current step. In playback mode, the tiles only light up when the sequencer plays them back — stepping on a tile does not modify the recorded pattern.

## Scales and Modes

The default pentatonic scale can be swapped for other modes: diatonic (7-note), chromatic (12-note), octatonic (8-note), or custom scales. The scale selection affects the tone-mode pitch mapping but nothing else.

```gdscript
const SCALES := {
    "pentatonic": [0, 2, 4, 7, 9],
    "major": [0, 2, 4, 5, 7, 9, 11],
    "minor": [0, 2, 3, 5, 7, 8, 10],
    "chromatic": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
}
```

## Floor Layout

The floor uses a raised border around the 17×17 active area to prevent the learner from walking off the edge. The border also houses the sequencer, metronome, and mode controls.
""",

'Chamber_Arrays': """

## Obstacle Placement Interaction

The learner carries a small block in their non-dominant hand. Clicking the trigger places the block on the nearest grid cell; clicking again removes it. The placement is discrete — the block snaps to the cell's centre.

```gdscript
class_name ObstaclePlacer extends Node3D

@export var chamber: ChamberGrid
var preview_block: Node3D

func _physics_process(_delta: float) -> void:
    var controller := get_parent() as XRController3D
    var hit_cell := raycast_to_cell(controller)
    if hit_cell != null:
        preview_block.global_position = hit_cell.global_position
        preview_block.visible = true
    else:
        preview_block.visible = false

func _on_trigger_pressed() -> void:
    var hit_cell := raycast_to_cell(self)
    if hit_cell == null: return
    var coords: Vector2i = hit_cell.coordinates
    if chamber.is_blocked(coords):
        chamber.clear_obstacle(coords)
    else:
        chamber.place_obstacle(coords)
```

## Agent Replanning

Each obstacle change triggers the agent to recompute its plan. Replanning is cheap because the grid is small; even at 12×12 = 144 cells, the BFS completes in microseconds.

```gdscript
func _on_obstacles_changed() -> void:
    compute_plan()
    reset_progress()

func reset_progress() -> void:
    visited.clear()
    current_index = 0
    current_cell = starting_cell
```

## Pathfinding Alternatives

BFS is the simplest choice; A* would be faster for larger grids. On a small grid the difference is negligible, and BFS's simpler code is better for the chamber's pedagogical aim.

```gdscript
func astar_path(start: Vector2i, goal: Vector2i) -> Array:
    var open := PriorityQueue.new()
    open.push(start, 0.0)
    var came_from := {start: null}
    var g_score := {start: 0.0}
    while not open.is_empty():
        var current: Vector2i = open.pop()
        if current == goal: return reconstruct_path(came_from, current)
        for nbr in neighbours(current):
            if chamber.is_blocked(nbr): continue
            var tentative: float = g_score[current] + 1.0
            if tentative < g_score.get(nbr, INF):
                g_score[nbr] = tentative
                came_from[nbr] = current
                var f: float = tentative + manhattan_distance(nbr, goal)
                open.push(nbr, f)
    return []
```

## Unreachable Cells

If the learner encloses a region of the grid so the agent cannot reach some unvisited cells, the agent will report the unreachable cells separately on the science screen. The report is pedagogical — it shows the consequence of the placement rather than hiding it.

## Step Cost Readout

The second display tracks the incremental step cost of each new obstacle. This is computed by comparing the path length before and after the placement.

```gdscript
func record_step_cost(obstacle: Vector2i) -> void:
    var before_path := shortest_unobstructed_tour()
    chamber.place_obstacle(obstacle)
    var after_path := shortest_unobstructed_tour_excluding(obstacle)
    var extra_steps: int = after_path.size() - before_path.size()
    step_cost_display.log_obstacle(obstacle, extra_steps)
    chamber.clear_obstacle(obstacle)  # placement happens via interaction, not this function
```

## Complexity

Pathfinding is O(V + E) = O(W·H) per replan. Replanning happens on every obstacle change, typically a few per second during active placement. The total cost is well within the map's budget.
""",
}

for m, add in adds.items():
    p = Path(f'commons/maps/{m}/technical.md')
    t = p.read_text(encoding='utf-8')
    p.write_text(t.rstrip() + add, encoding='utf-8')

print('done', len(adds))
