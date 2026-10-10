# The cube comes back

When a body returns to the same place, what has changed?

The cube rises. It slows near the top, turns and passes the place where we first saw it. Then it goes lower.

<!-- @y_oscillation_cube -->

Wait for another return. The same faces are still there. In Transformation we changed where the cube was, how it faced us and how much space it occupied. Here a movement has acquired a rhythm. We can begin to expect its next arrival.

Find the middle of the movement. The cube passes it on the way up and again on the way down. A photograph taken there could conceal the difference. Stay a little longer and the direction becomes apparent. Returning to a place need not mean returning to the same moment in a movement. The place is the same. The state is not.

The cube does not remember the height it just left. Its rule reads the clock and assigns another height. Nothing needs to push it back at the top. The return was already available in the function.

We might recognise a breath or a bounce in this movement. That resemblance arrives before we inspect what made it. There is no lung here, and no floor collision has reversed its direction. A familiar rhythm can lend a body an explanation the program does not contain.

Watch a few more cycles. How soon does the next one begin to feel inevitable? Repetition gives us a foothold: enough regularity to notice a different height, a faster return, a body that starts just out of step. A small change becomes legible because something else has been kept.

<!-- @ -->

The nearby cubes turn or combine several changes. From the doorway their movements may seem to belong together. Standing beside one, we can separate a change of place from a change of orientation, and the size of a movement from how often it returns. The same cube allows these differences to remain the subject. Similar repetitions can be made by different arrangements of state and time.

<!-- @control_pendulum -->

Further in, take the pendulum bob aside and release it. Your hand enters this movement. Its angle and angular velocity help determine what happens next. The cube keeps reading its clock.

A thin line hangs from the pivot to a ring. That line does not move; it is where the rod would rest. Take the bob, draw it to one side, and let it go. Watch it pass through the ring. Wait, and watch it pass through the ring again.

The two passes look alike and are not. On the first the bob is travelling one way; on the second, back the other way. The ring brightens for a moment at each crossing, and the small label above the pivot keeps a count. Read the two numbers it shows while the bob swings: the angle, and the angular velocity with its sign. At the ring the angle reads near zero both times. The sign of the velocity is what tells the two visits apart.

Now release from the other side and compare. The first crossing after a release from the left travels rightward; from the right, leftward.

Follow the bob to an end of its swing instead. The velocity reading shrinks toward zero, changes sign, and grows again. The bob is briefly still there, and yet it is not at rest: the next moment is already decided by where it is. Between a turning point and the ring the bob speeds up; between the ring and the far turning point it slows. The route repeats, and every point on it carries a direction and a speed as well as a position.

This setting does not look up a position from the clock. Each physics step takes the pendulum's state and advances it through a small interval of time. These are the integration lines; the optional driving force is omitted:

```gdscript
var angular_acceleration: float = -(gravity / pendulum_length) * sin(_angle)
_angular_velocity += angular_acceleration * delta
_angular_velocity *= _damping_multiplier(delta)
_angle += _angular_velocity * delta
```

Gravity supplies a pull back toward the hanging position, in proportion to the sine of the angle. That pull changes the velocity; the velocity changes the angle; the new angle sets the next pull. This is the force work from the previous rooms turned into a return.

When you let go, your hand is part of the same rule. The last few positions of the bob in your grip are averaged into a velocity, and only the part of it along the swing is kept:

```gdscript
var tangent_velocity = avg_velocity.dot(tangent_direction)
_angular_velocity = tangent_velocity / pendulum_length
```

A fast release starts the swing fast. A release from stillness starts it from the angle alone.

Try a small release, then a much larger one. Behind the swing a curve is drawn: the angle over six seconds, predicted with the same update rule, from the pendulum's standard starting angle. It is a prediction for that starting condition, not a recording of your hand. Your large release need not follow it.

One is driven by this pendulum's signal, so its height, tilt and size all follow a swing it did not compute. Compare how these repetitions are made: an elapsed time, an accumulated angle, or the state sent by another body.

Both bodies return. One repeats a prescribed relation; the other responds to the state your gesture leaves behind. The pendulum is never told where to go. It is told how to change, and the returning comes out of that. We can watch them together without asking them to be the same kind of thing.

<!-- @ -->

For now, the return disappears as it happens. We have to wait again to compare it. In the next hall, a movement will leave a record we can walk beside.
