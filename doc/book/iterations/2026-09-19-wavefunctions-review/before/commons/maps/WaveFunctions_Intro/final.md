# Returning differently

The ring marks a place the bob keeps leaving.

<!-- @control_pendulum -->

A thin line hangs from the pivot towards it. Take the bob to one side and release it. Watch the first crossing of the ring, then the next. Something has returned. Before looking at the numbers, try to say what has not.

The counter may already be above zero. Taking hold of the bob gives us a beginning inside a swing that began earlier. Those crossings remain in the count.

At the ring the angle is close to zero on both passes. The velocity reading carries a different sign. One zero is on the way out; the other is on the way back. A position that looked sufficient a moment ago needs another number before we can say what happens next.

Follow the bob towards an end of its swing. It slows, seems to wait, and turns. The speed has reached zero there too, but the angle has not. The body can be still for an instant without having finished moving.

We have met position, velocity and force in earlier rooms. Here they take turns making the return. These are the state updates in the pendulum's physics step, with the optional driving force omitted:

```gdscript
var angular_acceleration: float = -(gravity / pendulum_length) * sin(_angle)
_angular_velocity += angular_acceleration * delta
_angular_velocity *= _damping_multiplier(delta)
_angle += _angular_velocity * delta
```

The angle supplies a restoring acceleration. Acceleration changes velocity; damping reduces it; velocity changes the angle. At the next step, the new angle enters the first line. Read down, then return to the top. The repetition in the code makes a return in the room without listing the positions the bob must visit.

Now release it from the other side. Try giving it a small movement as you let go, then releasing it as nearly still as you can. The hand can supply speed as well as a starting position. But how much of the hand gets through?

The release code takes a velocity averaged from recent positions and projects it onto the direction of the swing:

```gdscript
var tangent_velocity = avg_velocity.dot(tangent_direction)
_angular_velocity = tangent_velocity / pendulum_length
```

The dot product keeps the part along that tangent. A sideways flourish can occupy your hand and contribute little to this number. The constraint makes the pendulum manageable: one angle, one angular velocity. It also gives you something to play against. Try two different gestures that leave a similar swing. Their resemblance belongs to what this body accepts from them.

Behind the bob, a curve predicts six seconds from a standard starting angle. Make a larger release and compare it with that curve. The prediction did not watch your hand. It began with another condition. A wide swing also presses against the small-angle approximation in which length, with gravity fixed, sets the period. The actual restoring rule still contains `sin(_angle)`. Give several complete swings time to pass before deciding how their rhythm differs.

There are several beginnings here: the engine's, the counter's, the prediction's, the moment you let go. They do not have to coincide for the experiment to work.

<!-- @ -->

The nearby cubes return by other means. A clock prescribes one cube's bobbing; a steady rotation brings another back to its orientation; a third listens to this pendulum's signal. Similar repetitions can be made by different arrangements of state and time.

Our counter can tell us that the bob crossed the middle. It cannot show the gesture that started this particular swing. We leave with a number that has kept something, and a reason to want more than a number. In the next room the past takes up space.
