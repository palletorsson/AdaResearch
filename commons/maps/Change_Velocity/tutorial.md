# Velocity Is a Derivative

Position over time draws a curve. The arrow on the particle is that curve's slope, live.

```gdscript
var prev_pos: Vector3
var velocity: Vector3

func _physics_process(delta: float) -> void:
    velocity = (global_position - prev_pos) / delta
    prev_pos = global_position
```

Where you are, minus where you were, divided by how long it took. That is the whole definition — velocity is the derivative of position, computed the only way a running program ever can: one small `delta` at a time.

Grow the arrow from the particle.

```gdscript
func update_arrow(arrow: Node3D) -> void:
    var speed := velocity.length()
    if speed > 0.01:
        arrow.look_at(global_position + velocity)
        arrow.scale.z = speed * 0.3   # length encodes magnitude
```

Direction is where the motion points; length is how fast. When the particle slows toward a turning point the arrow shrinks to nothing, then grows again pointing the other way — the derivative crossing zero, visible.

The trace behind the walker is the same idea accumulated:

```gdscript
var trail: Array[Vector3] = []

func record(pos: Vector3) -> void:
    trail.append(pos)
    if trail.size() > 600:
        trail.pop_front()
```

Every stored point is a position; every gap between neighbors is a velocity. Walk fast and the samples spread; stop and they pile up. Your own path through the room is a function of time, and your body is differentiating it.

Try: sprint, stop dead, walk backward. Watch the arrow do zero-crossing in front of you.
