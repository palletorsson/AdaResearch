# Returning differently

When a body returns to the same place, what has changed?

<!-- @control_pendulum -->

A thin line hangs from the pivot to a ring. That line does not move; it is where the rod would rest. Take the bob, draw it to one side, and let it go. Watch it pass through the ring. Wait, and watch it pass through the ring again.

The two passes look alike and are not. On the first the bob is travelling one way; on the second, back the other way. The ring brightens for a moment at each crossing, and the small label above the pivot keeps a count. Read the two numbers it shows while the bob swings: the angle, and the angular velocity with its sign. At the ring the angle reads near zero both times. The sign of the velocity is what tells the two visits apart.

Now release from the other side and compare. The first crossing after a release from the left travels rightward; from the right, leftward. The place is the same. The state is not.

Follow the bob to an end of its swing instead. The velocity reading shrinks toward zero, changes sign, and grows again. The bob is briefly still there, and yet it is not at rest: the next moment is already decided by where it is. Between a turning point and the ring the bob speeds up; between the ring and the far turning point it slows. The route repeats, and every point on it carries a direction and a speed as well as a position.

Nothing here reads a clock to decide where the bob should be. Each physics step the pendulum takes its own state and pushes it forward:

```gdscript
var angular_acceleration: float = -(gravity / pendulum_length) * sin(_angle)
_angular_velocity += angular_acceleration * delta
_angular_velocity *= _damping_multiplier(delta)
_angle += _angular_velocity * delta
```

Gravity supplies a pull back toward the hanging position, in proportion to the sine of the angle. That pull changes the velocity; the velocity changes the angle; the new angle sets the next pull. This is the force work from the previous rooms turned into a return. The pendulum is never told where to go. It is told how to change, and the returning comes out of that.

When you let go, your hand is part of the same rule. The last few positions of the bob in your grip are averaged into a velocity, and only the part of it along the swing is kept:

```gdscript
var tangent_velocity = avg_velocity.dot(tangent_direction)
_angular_velocity = tangent_velocity / pendulum_length
```

A fast release starts the swing fast. A release from stillness starts it from the angle alone.

Try a small release, then a much larger one, and count crossings for each rather than deciding by eye which is quicker. Behind the swing a curve is drawn: the angle over the next six seconds, predicted with the same update rule, from the pendulum's standard starting angle. Your large release does not follow that curve. The familiar rule that the length alone sets the period holds for small swings; the sine in the acceleration makes a wide swing take longer, and the damping steals a little from every pass. A larger movement is not a request for a proportionally quicker rhythm.

<!-- @ -->

Around the pendulum stand cubes that also repeat. One bobs up and down along a rail; it is moved by a sine of the time and holds no velocity of its own. One spins at a steady rate and never returns. One is driven by this pendulum's signal, so its height, tilt and size all follow a swing it did not compute. Stand where you can see the bob and the bobbing cube together and ask which of them would notice if you took hold of it.

The pendulum keeps nothing of its past crossings except a count. The next room gives the returning movement somewhere to leave its history: a single recurring position becomes a series of distinct marks once time is given its own axis.
