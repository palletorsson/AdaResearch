# Vector Fields Lab

A vector at every point in space. The room stops being a place and becomes a weather.

Sample the field where the point stands.

```gdscript
func field_at(pos: Vector3) -> Vector3:
    var cell := field_grid.world_to_cell(pos)
    return field_grid.vectors[cell]
```

The interactive point carries its origin with it. Wherever you drag it, the field answers with an arrow — one point, asking the room a question.

Let a mover obey the field.

```gdscript
func follow_field(mover: Mover, delta: float) -> void:
    var desired := field_at(mover.position)
    mover.acceleration += desired - mover.velocity
```

NoC example 5.4, pulled forward: steering toward the field's suggestion. The flow field painter lets you paint the suggestion by hand.

Spin a vortex.

```gdscript
func vortex_at(pos: Vector3, center: Vector3) -> Vector3:
    var arm := pos - center
    return Vector3.UP.cross(arm).normalized() / max(arm.length(), 0.5)
```

Cross the up-axis with the arm and you get rotation. Closer to the center, stronger the spin — the division does that.

Read the weather.

```gdscript
func weather(pos: Vector3, t: float) -> Vector3:
    return weather_field.sample(pos) * gust(t)
```

The weather vane field changes over time. A field of vectors, itself moving — a function of place and moment.

Trace the magnetic lines.

```gdscript
func magnetic_step(pos: Vector3) -> Vector3:
    return (field_at(pos)).normalized() * trace_step
```

Field lines are what you get when a point walks the field obediently: step, sample, step.

> Try: with the flow field painter, paint a field that brings every wandering mover home to the center. What do all your arrows have in common?

> Try: drag the interactive point through the vortex slowly. Feel where the field is strongest before the math told you.

Next: Launch — one big force at one moment, then gravity does the rest.
