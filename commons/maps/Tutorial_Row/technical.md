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
    code_label.text = "\n".join([
        code_lines[0],
        code_lines[1],
        code_lines[2] % index,
        code_lines[3] % index,
    ])
```

## Backward Movement

Walking backward decrements the index. The audio cue's pitch drops, and the code display reflects the new value. The index is clamped to [0, row_count - 1] so the learner cannot step past either end of the array.
## Save State

The corridor does not record progress. Re-entering starts at the beginning; the index counter resets. This is deliberate — the map is a motor-skill calibration for traversal, not a puzzle with persistent state.

## Alternative Representations

The same 1D array could be rendered as a vertical tower, a spiral, or a circular ring. Each representation teaches a different intuition about linear indexing. The corridor is the simplest to traverse in VR and is what the map uses.