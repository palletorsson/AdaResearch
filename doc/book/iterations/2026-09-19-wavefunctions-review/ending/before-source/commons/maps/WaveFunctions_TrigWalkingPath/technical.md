# WaveFunctions TrigWalkingPath — Technical

Two parallel walkways generate themselves a few steps ahead of the learner. The left lane follows sin; the right lane follows cos.

```gdscript
class_name TrigPath extends Node3D

@export var function_type: String = "sin"
@export var frequency: float = 0.2   # cycles per unit distance
@export var amplitude: float = 0.5   # vertical amplitude
@export var step_spacing: float = 0.4
@export var lookahead: int = 10

var steps: Array = []  # spawned step nodes

func update_path(walker_position: Vector3) -> void:
    var walker_step_index: int = int(walker_position.x / step_spacing)
    while steps.size() < walker_step_index + lookahead:
        spawn_step_at_index(steps.size())
    # Clean up old steps behind walker
    while not steps.is_empty() and steps[0].position.x < walker_position.x - step_spacing * 3:
        steps[0].queue_free()
        steps.pop_front()

func spawn_step_at_index(index: int) -> void:
    var x: float = index * step_spacing
    var y: float = height_for(x)
    var step := STEP_SCENE.instantiate()
    step.position = Vector3(x, y, lane_z_offset())
    add_child(step)
    steps.append(step)

func height_for(x: float) -> float:
    var angle: float = frequency * x * TAU
    match function_type:
        "sin": return amplitude * sin(angle)
        "cos": return amplitude * cos(angle)
    return 0.0
```

## Cross-Bridge

The cross-bridge at the midpoint connects the two lanes. It is a single step whose height is the average of sin and cos at its position — a 45° phase midpoint.

```gdscript
class_name CrossBridge extends StaticBody3D

@export var midpoint_x: float = 20.0
@export var frequency: float = 0.2
@export var amplitude: float = 0.5

func _ready() -> void:
    var sin_y := amplitude * sin(frequency * midpoint_x * TAU)
    var cos_y := amplitude * cos(frequency * midpoint_x * TAU)
    var avg_y := (sin_y + cos_y) / 2.0
    position.y = avg_y
```

## Reference Panel

The panel shows both functions on a shared chart, with a marker indicating the walker's current horizontal position.

```gdscript
class_name TrigChart extends Control

func draw_chart(walker_x: float, frequency: float, amplitude: float) -> void:
    var w: float = size.x
    var h: float = size.y
    for px in range(int(w)):
        var world_x: float = (px / w) * total_range
        var sin_y: float = amplitude * sin(frequency * world_x * TAU)
        var cos_y: float = amplitude * cos(frequency * world_x * TAU)
        draw_line(Vector2(px, h / 2 - sin_y * h / 4), Vector2(px + 1, h / 2 - sin_y * h / 4), Color.BLUE)
        draw_line(Vector2(px, h / 2 - cos_y * h / 4), Vector2(px + 1, h / 2 - cos_y * h / 4), Color.RED)
    var marker_px: float = (walker_x / total_range) * w
    draw_line(Vector2(marker_px, 0), Vector2(marker_px, h), Color.WHITE, 2)
```

## Complexity

Path generation is O(lookahead) per frame. Cleanup removes steps behind the walker to keep memory bounded. The reference chart redraws once per frame at O(w) where w is the chart width in pixels.

Within the sequence, TrigWalkingPath is the penultimate map. Synthesis Lab will next decompose everything into Fourier components.

## Lane Separation

The two lanes are separated by 2 units horizontally — close enough for the learner to step between them, far enough that the two functions' offset is visible as a spatial relationship rather than merely on a chart.

## Dynamic Path Generation

Generating the path procedurally as the learner approaches means the map has effectively infinite length. Old steps are removed when they fall behind the walker by a fixed distance, bounding memory use.

```gdscript
class_name PathGenerator extends Node3D

@export var lookahead_distance: float = 8.0
@export var behind_cleanup_distance: float = 4.0

func _process(_delta: float) -> void:
    var walker_x: float = walker.global_position.x
    ensure_steps_up_to(walker_x + lookahead_distance)
    remove_steps_before(walker_x - behind_cleanup_distance)
```

## Phase Offset Demonstration

At any horizontal position x, the vertical difference between the sin lane's step height and the cos lane's step height is |sin(x) - cos(x)|, which equals √2·|sin(x - π/4)|. This reaches its maximum of √2 at x = 3π/4 + kπ for integer k.

```gdscript
func maximum_offset_positions(frequency: float, total_range: float) -> Array:
    var positions: Array = []
    var k: int = 0
    while true:
        var x: float = (3.0 * PI / 4.0 + k * PI) / (frequency * TAU)
        if x > total_range: break
        positions.append(x)
        k += 1
    return positions
```

## Pitch Mapping

A variant of the map maps lane height to pitch — the learner's altitude determines the tone that plays as they walk. Climbing the sin lane produces a sine-like pitch profile; the cos lane produces the same profile offset by 90°.

## Chart Rendering

The reference panel redraws the chart once per frame. Drawing two sinusoids at panel resolution (say 300 pixels wide) is 600 line segments per frame — trivial on modern hardware.

## Interactive Parameters

The entrance sliders adjust frequency and amplitude for both lanes simultaneously. Independent adjustment would be possible but would break the "sin and cos are the same function offset" pedagogy the map is built around.
