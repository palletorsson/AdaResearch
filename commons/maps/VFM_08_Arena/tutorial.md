# Vector Arena

The exam, disguised as a shooting range. Every station re-asks a question this sequence already answered — at speed.

Conserve momentum in the cradle.

```gdscript
# before == after, always:
var p := a.mass * a.velocity + b.mass * b.velocity
```

The cradle's click is conservation you can hear. Mass times velocity in, mass times velocity out.

Crash the carts.

```gdscript
func elastic_1d(m1: float, v1: float, m2: float, v2: float) -> Array:
    var u1 := ((m1 - m2) * v1 + 2 * m2 * v2) / (m1 + m2)
    var u2 := ((m2 - m1) * v2 + 2 * m1 * v1) / (m1 + m2)
    return [u1, u2]
```

The collision carts run this equation at floor scale. Heavy hitting light, light hitting heavy — predict, then watch.

Bounce a shot down the reflection hall.

```gdscript
var bounced := v - 2.0 * v.dot(wall_normal) * wall_normal
```

The preview shelf showed this once; the hall makes you aim with it. Hit the target around the corner using the wall as the second half of your throw.

Lead the moving target.

```gdscript
func lead(target_pos: Vector3, target_vel: Vector3,
          shot_speed: float, from: Vector3) -> Vector3:
    var t := (target_pos - from).length() / shot_speed
    return (target_pos + target_vel * t - from).normalized()
```

The sentry turret solves interception: aim not where the target is, but where it will be. Position plus velocity times time — Motion 101, weaponized.

Survive the turret's logic.

```gdscript
# the turret leads YOU. Change velocity, not position —
# its prediction is only as good as your consistency.
```

Walking a straight line makes you solvable. The dodge is acceleration: be a worse equation.

> Try: in the reflection hall, score a two-bounce hit. Each bounce is one subtraction — chain them in your head before you throw.

> Try: against the sentry turret, walk a circle. Why does it keep missing in the same direction?

This closes the loop that opened in the sandbox: pushes you couldn't name are now equations you can aim. The chamber — ForcesArena — waits with the catalyst, the creatures, and everything this hall taught, alive at once.
