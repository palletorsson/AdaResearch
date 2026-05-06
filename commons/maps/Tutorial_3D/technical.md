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
    code_label.text = "grid[%d][%d][%d]\n# or equivalently:\ngrid[%d]" % [
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
