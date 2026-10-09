# Form-Finding: Descent

A marble comes to rest at the bottom of a bowl. Before it, a landscape must exist — a function that gives every position a cost.

Write the bowl.

```gdscript
@export var bowl_radius: float = 0.18
@export var bowl_depth: float = 0.12

func _bowl_height(r: float) -> float:
    var u: float = clampf(r / bowl_radius, 0.0, 1.0)
    return u * u * bowl_depth
```

Height is energy. The bowl is not scenery — it is the cost function, drawn.

Read the slope by sampling either side.

```gdscript
func _gradient_at(pos: Vector2) -> Vector2:
    var eps: float = gradient_sample_distance
    var gx: float = (_sample_height(pos.x + eps, pos.y) - _sample_height(pos.x - eps, pos.y)) / (2.0 * eps)
    var gz: float = (_sample_height(pos.x, pos.y + eps) - _sample_height(pos.x, pos.y - eps)) / (2.0 * eps)
    return Vector2(gx, gz)
```

The marble never sees the bowl. It samples two points and subtracts. Four evaluations is all the view it gets.

Step against the gradient.

```gdscript
_current_position -= gradient * learning_rate
```

Downhill is the negative gradient. The learning rate is how far you are willing to trust one reading of the slope.

Let the slope be a force instead of a step.

```gdscript
var accel: Vector2 = -_pos * (bowl_depth / maxf(bowl_radius * bowl_radius, 1e-4)) * 9.0
_vel = (_vel + accel * delta) * 0.985
_pos += _vel * delta
```

The 0.985 is damping. Without it the marble orbits the minimum forever. Energy has to leave before a shape can arrive.

Give the walker a memory of its own motion.

```gdscript
var g: Vector2 = _loss_grad(_m_pos[i])
_m_vel[i] = _m_vel[i] * _m_momentum[i] - g * lr
_m_pos[i] += _m_vel[i]
```

Momentum at 0.86 carries a marble across a shallow dip to the deep well. Its low-momentum sibling stops in the first dip it meets. One parameter, two fates.

Cut real wells into the surface.

```gdscript
func _loss(p: Vector2) -> float:
    var v: float = 0.55 * p.length_squared()
    for i in _well_centers.size():
        var d2: float = (p - _well_centers[i]).length_squared()
        v -= _well_depths[i] * exp(-d2 / _well_widths[i])
    return v
```

A slight bowl with Gaussians subtracted out of it. One deep, two shallow. The landscape is now something you can get stuck in.

Stop when the slope stops saying anything.

```gdscript
if magnitude < stop_gradient_magnitude:
    _finalize_descent()
    return
```

Convergence is not arrival at the bottom of the map. It is the local slope going flat.

Detect rest with two conditions and a clock.

```gdscript
if g.length() < SETTLE_GRAD and _m_vel[i].length() < SETTLE_VEL:
    _m_settle_clock[i] += STEP_DT
    if _m_settle_clock[i] >= SETTLE_TIME:
        _m_settled[i] = true
else:
    _m_settle_clock[i] = 0.0
```

Flat underfoot and nearly still, held for 0.9 seconds. A momentary pause is not a resting place.

You can now write a landscape, read its gradient without ever seeing it whole, step downhill with and without momentum, and know when a body has come to rest. Nothing placed the marble at the bottom. FormFinding_Catenary hands the same problem to a chain and a soap film, which solve it without any of this.
