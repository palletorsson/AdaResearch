The last hall's forces bent a path and let it go. These give it back.

A hall of clocks and balances. Every force in it pulls toward a rest and overshoots, or holds a beam level, or hands a motion on without losing any of it, and the reason they keep time is one sign in one line of code. Walk it south to north, the way the room's own beats run.

```gdscript
func restoring_force(displacement: float, k: float) -> float:
    return -k * displacement
```

The minus sign is the entire law. Take a thing from where it rests and the force points *back*, in exact proportion to how far you took it. Everything in this hall that keeps a rhythm keeps it because of that sign.

## Momentum

```gdscript
func total_momentum(masses: Array[float], velocities: Array[Vector3]) -> Vector3:
    var total := Vector3.ZERO
    for i in masses.size():
        total += masses[i] * velocities[i]
    return total
```

<!-- @momentum_cradle -->

Five steel balls on strings. Lift the end one and let it go. The blow travels through the three in the middle, which do not move, and kicks the far ball out to the same height the first one fell from. One in, one out. Sum mass times velocity before and after and the number has not changed; the middle of the cradle is where the momentum is owed but not spent. Motion refuses to be destroyed. It can only be handed on.

<!-- @ -->

## Restitution

```gdscript
func apex_after(bounces: int, drop_height: float, e: float) -> float:
    return drop_height * pow(e, bounces)
```

<!-- @bounce_well -->

A ball dropped into a well, frozen stroboscopically, so that every arc stands beside the last. Each rises to a fixed fraction of the one before it. Set the fraction with the slider: at one the ball never stops, at zero it lands with a dead thud, and everything between is a geometric series. Every bounce is a tax on a fall.

And here is the thing about a geometric series that the well lets you watch: there are infinitely many bounces, and they take a finite time. The four-hundredth adds nothing you could measure. The ball is still, and it got there through an infinity of ever-smaller arrivals, which the portal room said the finite could not do, and which it does here by shrinking faster than it repeats.

<!-- @ -->

## Lever

```gdscript
func balances(f_left: float, d_left: float, f_right: float, d_right: float) -> bool:
    return absf(f_right * d_right - f_left * d_left) < 0.06
```

<!-- @lever_balance -->

A beam on a fulcrum and a slider that moves the right-hand weight along the arm. It does not change the weight. It changes the *torque*, force times distance, and the beam tips toward the bigger product and sits level only when the two agree. A small load far out holds a big one near in. That is the same trade the orbit made in the last hall, with weight for mass and arm for radius, and the room says it plainly: a lever trades force for distance and never gets something for nothing.

```gdscript
func place_pivot(arm: float, w_left: float, w_right: float) -> Vector2:
    var total := w_left + w_right
    return Vector2(arm * w_right / total, arm * w_left / total)
```

<!-- @calder_mobile -->

Calder's mobile, and it is actually balanced. Every rod obeys the lever law: its two children are weighed, the pivot is placed so the heavier rides the shorter arm, and the whole thing hangs level from one point at the ceiling. Read the function: weigh both subtrees before you cut the rod, then recurse. The drift you are watching is not decoration. Every arm is answered by a real weight, and the mobile is the lever law four levels deep, moving.

<!-- @calder_object_mobile -->

The same law, hung with the museum's own objects: a point, a sphere, a pyramid, an arch, each with a plausible mass, drifting in equilibrium. The first chapter's shapes, balanced by the fifth chapter's rule. The foundational things do not float here. They are weighed.

<!-- @ -->

## Wind

```gdscript
func wind_drag(speed: float, rho: float, c_d: float, area: float) -> float:
    return 0.5 * rho * speed * speed * c_d * area
```

<!-- @weather_vane -->

A vane, a flag, and a slider for the wind. The vane swings to point downwind, the flag streams, and the drag arrow grows, and watch how it grows: with the square of the speed. Double the wind and the push quadruples, and the flag goes from a lazy ripple to horizontal. This is not the linear rent of the drag corridor. Squared, the force stops being polite, and it is a force you can only see in the bend of what it pushes.

<!-- @example_6_4_windmill_vr -->

The older windmill beside it is the demonstration the vane replaced, kept because it turns.

<!-- @ -->

## Pendulum

```gdscript
func swing(t: float, amplitude: float, arm_length: float) -> float:
    var omega := sqrt(9.8 / arm_length)
    return amplitude * cos(t * omega)
```

<!-- @pendulum_hall -->

A real pendulum, four and a half metres of string from a six-metre gantry, swinging at its true period, a little over four seconds, with a glowing arc on the floor recording the sweep. Look at what is in the period and what is not. The length is in it. Gravity is in it. The mass is not: a heavy bob and a light one on the same string keep the same time, and the amplitude is not either, which is why a pendulum can be a clock.

```gdscript
func restoring_torque(theta: float, mass: float = 1.0) -> float:
    return -mass * 9.8 * sin(theta)
```

Except that it is only honest for small swings. The true pull back is mg sin θ, not mg θ, and the pendulum is a spring only while those two are close. At this hall's swing of twenty-four degrees they differ by three percent. Pull it far enough and the period stops being a constant. The clock keeps time on the condition that you do not push it too hard, which is a condition every clock has.

<!-- @ -->

## Spring

```gdscript
func spring_period(mass: float, k: float) -> float:
    var omega := sqrt(k / mass)
    return TAU / omega
```

<!-- @spring_tower -->

A heavy mass bobbing on a giant coil, and a slider for the stiffness. Stiffen it and two things happen at once: it gives less, and it ticks faster. The period has the mass in it and the stiffness in it and nothing else. A spring is honest; it returns exactly what it is given, and a big bounce and a small one take the same time, which is the second reason a thing can be a clock.

<!-- @ -->

## The bench

Along the north wall, thirteen more, folded in from a room that used to stand between this hall and the last. They are the same sign at every scale and in every costume, and they are worth a walk.

<!-- @mass_spring_damper -->

The canonical second-order system: a mass, a spring, and a damper that charges rent on speed the way the corridor did. Stiffness pulls back, damping bleeds energy, and between them every vibration that has ever been engineered: the ring that dies away, the door that closes without slamming, the suspension that neither bounces nor jars. Underdamped, critical, overdamped, and the third is the one every engineer is paid to find.

<!-- @coupled_pendulums -->

Two pendulums joined by a spring. Start one and watch the energy cross to the other and come back, sloshing between them at a beat you can count. This is resonance in its smallest form, and everything from a tuning fork to a bridge that shook itself down is this with more parts.

<!-- @spring_system -->

Twenty masses in a chain. A complex vibration is not complex. It is a sum of simple ones, each with its own frequency, and when two of them nearly agree the energy beats between them. That decomposition is the whole of how a sound is analysed, and it is two chapters away.

<!-- @slingshot_pull -->

Draw the pouch back and the band stores energy as the square of the pull: twice as far, four times as much. Release, and the stored square becomes launch speed. This is the spring's law read as a bank account, and it is the one machine in this hall that hands its rhythm to the last hall's arc.

<!-- @vector_joint_playground -->

Six stations of joints, each paired with a vector you can drag: a crane, pistons, a door, a seesaw, a waterwheel, a spring tower. A joint is a subtraction: it takes degrees of freedom away from a thing until only the motion you wanted is left, a hinge leaving one turn, a slider leaving one slide, a cone leaving a wobble inside a limit. The swings and the crank and the press beside it are each one such subtraction made large.

<!-- @surreal_kinetic_sculpture -->

And one that is not a lesson. Gears drive pendulums that scatter particles through fields while banners ripple in a simulated wind, every system in the chapter woven into one perpetually moving thing. It is here as a celebration, and it is allowed to be.

<!-- @ -->

## These keep a rhythm

Spring, pendulum, cradle, bounce, lever, wind. Forces that repeat, conserve and balance, and every one of them keeps faith for the same reason: the pull back is proportional to how far you have been pulled, and the sign on it points home.

The last hall asked what a force does to a body. The next one stops asking that, and asks what a force does to a room.
