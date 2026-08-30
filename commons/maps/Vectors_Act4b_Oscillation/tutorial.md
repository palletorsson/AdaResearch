# Oscillation

The forces that return what they are given. Before them, a force must already be something that edits motion, and a push must already split along and across.

Make the answer proportional to the offence.

```gdscript
func restoring_force(displacement: float, k: float) -> float:
    return -k * displacement
```

The minus sign is the entire law. F = −kx points back at where you started and grows in exact proportion to how far you took it. A spring gives back exactly what it is given.

Ask how long that takes.

```gdscript
func spring_period(mass: float, k: float) -> float:
    var omega := sqrt(k / mass)
    return TAU / omega
```

Stiffen the coil and ω rises, so the period falls — it gives less and ticks faster. Amplitude appears nowhere in T = 2π√(m/k). A big swing and a small one take the same time.

Hang the same honesty from a string.

```gdscript
func swing(t: float, amplitude: float, arm_length: float) -> float:
    var omega := sqrt(9.8 / arm_length)
    return amplitude * cos(t * omega)
```

Only the length is in it. Mass cancels, so a heavy bob and a light one on the same string keep the same time. Lengthen the arm and T = 2π√(L/g) slows.

Draw the force that is really acting.

```gdscript
func restoring_torque(theta: float, mass: float = 1.0) -> float:
    return -mass * 9.8 * sin(theta)
```

The true restoring term is mg sin θ, not mg θ. A pendulum is only a spring for small angles, where sin θ ≈ θ. Pull it far enough and the period stops being a constant.

Hand momentum through a line of still balls.

```gdscript
func total_momentum(masses: Array[float], velocities: Array[Vector3]) -> Vector3:
    var total := Vector3.ZERO
    for i in masses.size():
        total += masses[i] * velocities[i]
    return total
```

Sum p = mv before the collision and after: the number does not move. Lift two balls and two leave. The middle of the cradle is where the momentum is owed but not spent.

Tax every fall by the same fraction.

```gdscript
func apex_after(bounces: int, drop_height: float, e: float) -> float:
    return drop_height * pow(e, bounces)
```

h' = e·h, compounding. e = 1 never stops, e = 0 is a dead thud, and everything between is a geometric series — infinitely many bounces inside a finite time.

Balance a beam by the product, not the weight.

```gdscript
func balances(f_left: float, d_left: float, f_right: float, d_right: float) -> bool:
    return absf(f_right * d_right - f_left * d_left) < 0.06
```

τ = F·d, and the beam is level when the two torques agree. A small load far out holds a big one near in — the same trade the barycenter made, with weight for mass and arm for orbital radius.

Weigh the children before placing the pivot.

```gdscript
func place_pivot(arm: float, w_left: float, w_right: float) -> Vector2:
    var total := w_left + w_right
    return Vector2(arm * w_right / total, arm * w_left / total)
```

The heavier child rides the shorter arm. Build both subtrees first, weigh them, then cut the rod — recurse, and the whole mobile hangs balanced from one point at the ceiling.

Square the speed and the force stops being polite.

```gdscript
func wind_drag(speed: float, rho: float, c_d: float, area: float) -> float:
    return 0.5 * rho * speed * speed * c_d * area
```

Not the linear drag of a corridor. Double the wind and the vane feels four times the push. A force seen only in the bend of what it pushes.

You can now write a restoring force, predict the period of a spring and a pendulum, sum momentum across a collision, decay a bounce series, test a beam for balance, and place a mobile's pivots by recursion. These forces keep time and keep faith, because the pull back is always proportional to how far you have been pulled. Vectors_Act5_ForceAsPlace stops asking what a force does to a body and asks what it does to a room.
