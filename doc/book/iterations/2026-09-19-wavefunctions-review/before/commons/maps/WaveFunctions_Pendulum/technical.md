# PendulumWave: motion, recording and the clocks between them

This chapter describes the placed primary, `algorithms/wavefunctions/oscillation_driver/PendulumWave.gd`, in WaveFunctions_Pendulum. The map places it at (6,11), rotated 180 degrees, so its local negative-Z record recedes south. Its current controls are FINE, COARSE, STROBE and RESET. Length and damping are exports for the scene author; this panel does not offer those adjustments.

## Advance a state

```gdscript
angular_acceleration = -(gravity / length) * sin(angle)
angular_velocity += angular_acceleration * delta
angular_velocity *= (1.0 - damping * delta) # Apply damping
angle += angular_velocity * delta
time += delta
```

The script runs this symplectic-Euler update in `_physics_process`. The project currently supplies sixty physics ticks per second. This separates integration from rendering; it does not make the numerical solution exact or guarantee a wall-clock performance rate under load.

Length is 2 m, gravity 9.8 m/s², initial angle 45 degrees and damping zero. The small-angle period estimate is `TAU * sqrt(length / gravity)`, approximately 2.84 seconds here. At 45 degrees the acceleration is nonlinear in angle, so that estimate and the measured period differ. The script measures between successive negative-to-positive centre crossings; those detections are also resolved on physics ticks.

## Keep a different state: the record

```gdscript
_sample_clock += delta
if _sample_clock >= sample_interval:
	_sample_clock -= sample_interval
	if _sample_clock >= sample_interval:
		_sample_clock = fmod(_sample_clock, sample_interval)
	var bob_local := Vector3(length * sin(angle), pivot_height - length * cos(angle), 0.0)
	trail_points.push_front(Vector3(bob_local.x, bob_local.y, time))
while trail_points.size() > max_trail_length:
	trail_points.pop_back()
while not trail_points.is_empty() and time - trail_points.back().z > max_history_seconds:
	trail_points.pop_back()
```

A sample stores two coordinates and the experiment timestamp. FINE targets 0.025 s; COARSE targets 0.2 s. Samples are taken at the first servicing physics tick, without interpolating an intermediate bob position. At 60 Hz, FINE alternates approximately 16.7 and 33.3 ms gaps. `recorded_interval_range()` measures the differences between retained timestamps and the readout reports them alongside the target.

The count limit is 300 and the age limit 10 s. FINE fills the count budget with about 7.5 s of history. A collection of 300 positions spans 299 inter-sample gaps; the oldest sample's age also includes the time since the newest sample. COARSE retains around fifty marks under the age limit. Count, age and target interval are related quantities, not interchangeable ones.

## Lay the record into space

```gdscript
var depth: float = (time - p.z) * time_speed
var at := Vector3(p.x, p.y, -depth)
```

Depth is age times 0.6 m/s. The longest permitted history reaches about 6 m; the FINE count limit reaches about 4.5 m. The bob swings in one plane. The trail's depth is an encoding of time, not a direction the bob travelled. An ImmediateMesh joins the samples, and a MultiMesh places a small sphere at each retained sample.

Changing sampler clears the record and retains the swing state. STROBE targets the measured period, with a small-angle estimate until a measurement exists. Samples then nearly align; quantized timing and numerical integration can leave a spread. RESET preserves the selected policy while returning this experiment's angle, velocity, time and list to their starting state. It does not reset the museum clock.

The gallows frame, side panel and cased readout make these choices available in the room. Standalone camera, environment, light and floor are removed when embedded. The panel carries `em_local_instrument` so its touch targets do not become the installation's planning footprint.

The Foucault pendulum, WavePaintings and seismograph remain secondary comparisons. Their independent implementations must be read before attributing this recorder's timing policy to them. The earlier broad explanatory sketches are preserved in the W1 review archive; they are not the code running in this primary.

Source and arithmetic checks support this account. Placement, label legibility, physical controls, unloading and headset access still require the museum probe and a walk.


## Measured on 2026-09-13

The claim that integration is separated from rendering is now a measurement. The same FINE record was taken for three seconds of experiment time at two render rates:

| render cap | frames drawn | physics steps | marks | span kept | actual gaps |
|---|---|---|---|---|---|
| 30 | 91 | 180 | 120 | 2.983 s | 16.7–33.3 ms |
| 120 (vsync held it at 60) | 180 | 180 | 120 | 2.983 s | 16.7–33.3 ms |

Twice the frames drawn, and the record did not change by a mark. The gaps belong to the physics step: FINE asks for 25 ms and a 16.7 ms step can only meet it by alternating one step and two.

Eviction, past the 300-mark cap, sampled at 9, 14 and 19 s: the count held at 300 each time while the oldest retained timestamp moved on from 1.73 s to 6.92 s to 11.57 s. The marks' instance count and the trail's vertex count stayed at 300, and the engine's static memory did not move (+0.00 MB over those ten seconds).

**A step longer than the interval.** The sampler fires at most once per physics step. At 30 ticks a step is 33.3 ms, longer than FINE's 25 ms, so every gap is 33.3 ms and the request is simply not met. The readout shows it in its actual gaps. The shipped code also carried the unmet remainder forward, and it grew by 8.3 ms every step: measured on HEAD, 491.7 ms after two seconds, a backlog the record would then have over-sampled to drain. The carried remainder is now kept under one interval (25.0 ms at most, same run). At the shipped 60 ticks the new branch never runs, so the record is unchanged there.
