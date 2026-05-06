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

Colour older segments faintly.

```gdscript
func fade_old_segments(mesh: ImmediateMesh) -> void:
    for i in path.size():
        var age: float = float(path.size() - i) / float(path.size())
        mesh.surface_set_color(Color(1.0, 0.9, 0.6, 1.0 - age))
```

Old portions of the path fade. Recent steps are bright. Memory visibly decays.
