# Form-Finding: Forge

Shape your own — by arranging the landscape, not the form. Before it, everything this chapter has built: a cost, a slope, a body willing to fall.

Write the cost you want matter to fall down.

```gdscript
@export var amp: float = 0.13

func _energy(x: float, z: float) -> float:
    var bowl: float = (x * x + z * z) * 0.5
    var wrinkle: float = sin(x * 7.0) * 0.18 + cos(z * 6.0) * 0.16
    return amp * (bowl + wrinkle)
```

A clear global basin with local minima cut into its walls. This is the only authorship left to you: set the landscape, then stop.

Take the gradient and step.

```gdscript
@export var learning_rate: float = 0.06

func _grad(x: float, z: float) -> Vector2:
    var e: float = 0.012
    var gx: float = (_energy(x + e, z) - _energy(x - e, z)) / (2.0 * e)
    var gz: float = (_energy(x, z + e) - _energy(x, z - e)) / (2.0 * e)
    return Vector2(gx, gz)

_p -= _grad(_p.x, _p.y) * learning_rate
```

The same three lines as the first map's marble: two samples, a subtraction, a step against the result. The readout beside it prints the step count and the energy falling — settling a soft body and training a model are one algorithm on two landscapes.

Restart once the slope dies.

```gdscript
if _grad(_p.x, _p.y).length() < 0.002 and _step > 30:
    _p = Vector2(_rng.randf_range(-span * 0.4, span * 0.4), _rng.randf_range(-span * 0.4, span * 0.4))
    _step = 0
    _trail.clear()
```

Converged is not solved. A fresh start on a different slope is the cheapest way to find out whether the basin you reached was the only one.

Name the form you are descending toward.

```gdscript
var parts := [
    { "c": Vector3(0.0, 0.0, 0.0), "r": 0.16, "w": 80 },     # torso
    { "c": Vector3(0.0, 0.20, 0.04), "r": 0.10, "w": 45 },   # head
    { "c": Vector3(-0.18, -0.06, 0.0), "r": 0.07, "w": 28 }, # limbs
    { "c": Vector3(0.18, -0.06, 0.0), "r": 0.07, "w": 27 },
]
```

180 particles across four blobs, and a readout that says only "settling" or "MAX Q". The forge does not press this shape onto the matter. It is where the matter ends up.

Carry the cloud toward it, and freeze the jitter as you go.

```gdscript
var jit := Vector3(
    sin(_t * 2.0 + float(i) * 0.9),
    cos(_t * 1.6 + float(i) * 0.6),
    sin(_t * 2.3 + float(i) * 1.4),
) * 0.035 * (1.0 - q)
var p: Vector3 = raw.lerp(target, q) + jit
```

The jitter is the last map's temperature, scaled by `1.0 - q` — loud while Q is low, gone by the time Q is high. Annealing and arrival are one motion seen from two ends.

Prove it with your hands: stack until nothing moves.

```gdscript
var all_stable: bool = true
for piece in _pieces:
    if piece is RigidBody3D:
        if piece.linear_velocity.length() > stability_velocity_threshold \
                or piece.angular_velocity.length() > stability_velocity_threshold * 2:
            all_stable = false
            break
```

Threshold 0.05 m/s, twice that in radians. The win condition is not a shape matched against a template. It is a configuration that has stopped arguing.

Make the stillness cost something to hold.

```gdscript
if all_stable:
    _stability_timer += delta
    if _stability_timer >= stability_time:
        _trigger_transformation()
else:
    _stability_timer = maxf(0, _stability_timer - delta * 2)  # Decay faster than gain
```

One wobble costs two. Rest has to be held for 1.5 seconds, not touched once.

You can now write a landscape, descend it, watch a cloud fall into a coherent body as its temperature drains away, and win by making a system stop rather than making it obey. You carved none of these forms. You arranged the conditions and let them fall. The next sequence, wavefunctions, takes the same minimisation into a space where the resting state is a standing wave.
