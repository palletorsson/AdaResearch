# Pendulum

A swing that keeps returning, and a record of it that keeps receding. Build the pendulum on the fixed step, then decide what its record is allowed to keep. All code below is from `algorithms/wavefunctions/oscillation_driver/PendulumWave.gd`.

Integrate the swing on the physics step.

```gdscript
angular_acceleration = -(gravity / length) * sin(angle)
angular_velocity += angular_acceleration * delta
angular_velocity *= (1.0 - damping * delta) # Apply damping
angle += angular_velocity * delta
time += delta
```

Gravity over length, times the sine of the angle, pulls the bob back toward hanging. Velocity accumulates the pull; the angle accumulates the velocity. `delta` is one sixtieth of a second at this project’s current physics setting, and `time` is this experiment's own clock. With `damping` at zero there is no deliberate energy loss; numerical integration still approximates the motion.

Keep a sample with the time it was taken.

```gdscript
_sample_clock += delta
if _sample_clock >= sample_interval:
	_sample_clock -= sample_interval
	if _sample_clock >= sample_interval:
		_sample_clock = fmod(_sample_clock, sample_interval)
	var bob_local := Vector3(length * sin(angle), pivot_height - length * cos(angle), 0.0)
	trail_points.push_front(Vector3(bob_local.x, bob_local.y, time))
```

A sample is where the bob is and when. The third component is not a position; it is the clock reading. Nothing is kept between samples. A 25 ms target at 60 physics ticks per second is serviced on alternating one/two-tick gaps, about 16.7/33.3 ms. The display reports those actual gaps alongside the target.

Give the record two limits.

```gdscript
while trail_points.size() > max_trail_length:
	trail_points.pop_back()
while not trail_points.is_empty() and time - trail_points.back().z > max_history_seconds:
	trail_points.pop_back()
```

Three hundred marks, or ten seconds, whichever runs out first. At the 25 ms target the count binds near 7.5 seconds. At 200 ms the age binds around fifty marks; entry count and time span are different quantities.

Draw depth from age.

```gdscript
var depth: float = (time - p.z) * time_speed
var at := Vector3(p.x, p.y, -depth)
```

Age times 0.6 metres per second. The newest mark sits at the bob; the oldest retained mark is the farthest. The line joining them is a list laid out along the hall, not a path anything travelled.

Let the pendulum time itself.

```gdscript
if _prev_angle < 0.0 and angle >= 0.0 and angular_velocity > 0.0:
	if _last_upward_crossing >= 0.0:
		_period_measured = time - _last_upward_crossing
```

Two successive upward crossings of the centre give a period. STROBE sets the sampling interval to that period, and marks nearly align. The period and the sampling instants are both quantized to ticks.

Reset this experiment only.

```gdscript
angle = deg_to_rad(initial_angle)
angular_velocity = 0.0
time = 0.0
trail_points.clear()
```

The swing back to its starting angle, the clock to zero, the list to empty. The hall's clock, and everything else swinging in it, is untouched.

## The walk

Enter from the north and pass the raised stage on either side. At the head of the open south half the pendulum swings under its frame; the record recedes away from you toward the exit. Stand at the east post and pick one mark to follow. Walk south beside the record and find two crossings a whole swing apart; count the marks between them. Read the plate: count, span, interval, rate, period, step. Divide the period by the interval. Return to the post and press COARSE; read the plate again. Walk to the far end and wait for a mark to leave. Press STROBE and watch the record stand still while the bob swings. Press RESET. On the way to the south door, ask the seismograph on the west walkway the same questions.

You have seen a record made from a motion, and the rules that end it. The next map, Sine Space, lays the rising and falling along a passage you walk.
<<</MAP>>>

Change the depth rate.

```gdscript
@export var time_speed: float = 0.6
```

A faster rate stretches the same ten seconds over more of the hall; the marks do not change, only their spacing. Any placement can set it, and the readout prints whatever value is in force.
