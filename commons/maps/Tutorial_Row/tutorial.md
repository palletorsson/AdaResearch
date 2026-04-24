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

Smooth the pitch change.

```gdscript
var current_pitch: float = 1.0

func smooth_pitch_to(target: float, delta: float) -> void:
    current_pitch = lerp(current_pitch, target, delta * 8.0)
    sound_player.pitch_scale = current_pitch
```

Linear interpolation with factor 8 produces a quick but not instantaneous pitch shift. Crisp without being jarring.

Highlight the cell the learner is standing on.

```gdscript
func highlight_current_cell() -> void:
    var i := current_index()
    for c in get_children():
        if c.has_meta("index"):
            c.modulate = Color.YELLOW if c.get_meta("index") == i else Color.WHITE
```

The highlight moves with the learner. Colour is the visual parallel to the label's index text.
