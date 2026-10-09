# Unit Circle

A point travels a circle; its shadow traces a wave. Build the amphitheater where rotation becomes oscillation.

Declare the rotating point.

```gdscript
class_name CircleRunner
extends Node3D

@export var radius: float = 1.0
@export var omega: float = 1.0
var angle: float = 0.0
```

Radius and angular velocity. The runner travels the unit circle at rate omega.

Step the angle.

```gdscript
func _process(dt: float) -> void:
    angle += omega * dt
    position = Vector3(cos(angle) * radius, sin(angle) * radius, 0.0)
```

Position follows cosine and sine of angle. The runner traces a circle in the xy plane.

Project the shadow.

```gdscript
func project_shadow(screen_x: float, time: float) -> Vector3:
    return Vector3(screen_x, sin(omega * time) * radius, 0.0)
```

The shadow is sine against time. It strips away the x-component and leaves the sine trace scrolling along a screen.

Draw the projection line.

```gdscript
func draw_projection(line: ImmediateMesh, runner_pos: Vector3, shadow_pos: Vector3) -> void:
    line.clear_surfaces()
    line.surface_begin(Mesh.PRIMITIVE_LINES)
    line.surface_add_vertex(runner_pos)
    line.surface_add_vertex(shadow_pos)
    line.surface_end()
```

A faint line connects the runner to its shadow. The line lengthens and shortens; the learner sees where the sine comes from.

Build the oscillating bridge.

```gdscript
func update_bridge(plank: Node3D, offset: float) -> void:
    plank.position.y = sin(omega * Time.get_ticks_msec() / 1000.0 + offset) * 0.3
```

Planks rise and fall with staggered phase. The bridge becomes a travelling wave the learner walks across.

Label the angle readout.

```gdscript
func update_angle_label(label: Label3D) -> void:
    label.text = "θ = %.2f rad\nsin(θ) = %+0.2f\ncos(θ) = %+0.2f" % [angle, sin(angle), cos(angle)]
```

Three numbers update each frame. The label makes the mapping between angle and projection explicit.

Offer a second runner for cosine.

```gdscript
func spawn_cosine_runner() -> void:
    cos_runner = preload("res://commons/artifacts/wavefunctions/runner.tscn").instantiate()
    cos_runner.phase_offset = PI / 2.0
    add_child(cos_runner)
```

A second runner lags by 90 degrees. Its shadow traces cosine. Two shadows on one screen show the fundamental phase relationship.

You have seen the origin of trigonometry. The next map, 3D Wave Propagation, releases the wave to travel.
<<</MAP>>>

Draw the chord from cosine to sine runners.

```gdscript
func draw_chord(mesh: ImmediateMesh, a: Vector3, b: Vector3) -> void:
    mesh.clear_surfaces()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    mesh.surface_add_vertex(a)
    mesh.surface_add_vertex(b)
    mesh.surface_end()
```

The chord length visualises the phase difference as distance. When phase equals a quarter turn, chord length equals the radius.

Label the two runners.

```gdscript
func label_runners() -> void:
    sin_runner.label = "sin"
    cos_runner.label = "cos"
```

Each runner wears its function name. The amphitheater becomes legible to a first-time visitor.
