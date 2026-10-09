# Wavefunctions Intro

One pendulum you release by hand, a line that does not move, and cubes that were only told where to be. The order below is the order of the room.

Find the still reference first. From the pivot a hairline hangs to a ring. Nothing about it changes while the bob swings.

Take the bob and release it from one side. It is an XR Tools pickable; the pendulum listens to its `picked_up` and `dropped` signals.

```gdscript
func _on_bob_picked_up(_pickable):
	_is_grabbed = true
	_grab_velocity_samples.clear()
```

While the bob is held, the pendulum only follows your hand and computes the angle from the bob's position. No swing is integrated and no crossing is counted.

Watch the ring. It brightens once as the bob passes through, and once again on the way back. Read the label: the angle, and the angular velocity with its sign. The sign differs between the two crossings.

```gdscript
if signf(_angle) != signf(_prev_angle) and signf(_angle) != 0.0 \
		and absf(_angular_velocity) > CROSSING_MIN_OMEGA:
	_crossings += 1
	_last_crossing_dir = 1 if _angular_velocity > 0.0 else -1
	centre_crossed.emit(_last_crossing_dir, _angular_velocity)
```

A crossing is a sign change of the angle while the bob is moving. The room counts them and says which way the last one went.

Release from the other side and compare the direction of the first crossing.

Follow the swing to a turning point. The velocity reading passes through zero and changes sign; the angle is at its extreme.

Read the update that makes all of this happen. Each physics step:

```gdscript
var angular_acceleration: float = -(gravity / pendulum_length) * sin(_angle)
_angular_velocity += angular_acceleration * delta
_angular_velocity *= _damping_multiplier(delta)
_angle += _angular_velocity * delta
```

Gravity pulls toward the hanging position in proportion to sin(θ); the pull changes the velocity; the velocity changes the angle. Under the shipped `free` regime the damping multiplier is a constant 0.995 per physics frame.

Release again, faster. On release the pendulum averages the bob's last positions into a velocity and keeps only the part along the swing:

```gdscript
var tangent_velocity = avg_velocity.dot(tangent_direction)
_angular_velocity = tangent_velocity / pendulum_length
```

At a desk, the hand is the pointer. Right-click the bob, turn the view to carry it out, hold still and right-click again. The pointer does not know what a pendulum is, so the bob tells it who to tell:

```gdscript
_bob_sphere.set_meta("desktop_hook_target", self)
```

and the two hooks go to the same handlers a headset's grab reaches:

```gdscript
func on_desktop_grab(_pointer: Node) -> void:
	if _bob_sphere != null and not _is_grabbed:
		_on_bob_picked_up(_bob_sphere)
```

```gdscript
func on_desktop_drop(_pointer: Node) -> void:
	if _bob_sphere != null and _is_grabbed:
		_on_bob_dropped(_bob_sphere)
```

Held still before letting go, the release is from rest: the hand's last samples are zero, so the tangent velocity is zero too.

Try a small release and a large one and count crossings for each. Behind the swing the predicted θ(t) is drawn for the standard starting angle of 0.3 rad. A large release does not follow it: the sine in the acceleration lengthens a wide swing and the damping shortens each pass.

Then look at the cubes. `y_oscillation_cube` and `transformation_cube` set their height from a sine of the clock; `rotating_cube` spins at a constant rate; `oscillation_controlled_cube` listens to this pendulum's `oscillation_updated` signal and maps one swing to height, tilt and size. Take the bob and the driven cube stops with it; the clock-driven cubes do not notice.

The next room, Pendulum, records the swing along a depth axis. Carry the centre crossing with you.
