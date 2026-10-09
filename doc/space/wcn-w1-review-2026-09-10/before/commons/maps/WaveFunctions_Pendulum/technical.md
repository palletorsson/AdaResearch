# A laboratory of swinging weights where glass apparatus lines the benches and a Foucault pendulum traces rosettes on the floor

> Sourcing note (2026-09-10): the code in "Integrating the Pendulum on the Fixed Step" and "The PendulumWave: A Record With Two Limits" is quoted from the live script, `algorithms/wavefunctions/oscillation_driver/PendulumWave.gd`. The blocks under the seismograph, Foucault and double-pendulum headings are illustrative sketches written for this chapter, not the scripts that run in the hall (`commons/artifacts/seismograph/seismograph.gd`, `algorithms/wavefunctions/oscillation_driver/DoublePendulum.gd` and the Foucault scene are the live ones); read them as explanations of the idea, not as source.

The Intro gave us the equation x = A·sin(wt + phi). A cube on a rail, driven by three parameters — amplitude, frequency, phase. The motion was pure mathematics: a function of time producing displacement. But the equation came from nowhere. It was handed down and parametrized. The question this map answers is: where does that equation come from physically?

The answer hangs from the ceiling. A weight on a string, displaced and released. Gravity pulls it back toward center. It accelerates, arrives at equilibrium, but carries momentum — so it overshoots.

Now displaced on the other side, gravity pulls it back again. No sine function was invoked. No omega was specified. The pendulum oscillates because the restoring force is proportional to displacement. That proportionality — that single structural fact — is the origin of every sine wave in the physical world.

## The Restoring Force

A simple pendulum is a mass m suspended from a pivot by a rigid, massless rod of length L. Displace the mass to angle theta from vertical. Gravity acts downward with force mg. The component of gravity along the arc — the only component that matters, since tension handles the radial part — is:

```
F_tangential = -mg · sin(theta)
```

The negative sign encodes restoration: displace right, force acts left. Displace left, force pushes right. Always toward center. This is the pendulum's Hooke's Law — but nonlinear. The spring's restoring force is `-kx`, linear in displacement. The pendulum's is `-mg·sin(theta)`. Sine is not a straight line.

For small angles — theta less than about 15 degrees — sin(theta) approximates theta when measured in radians:

```
sin(theta) ≈ theta    (for small theta, in radians)
```

At 10 degrees (0.174 rad), sin(0.174) = 0.1736 — error less than 0.3%. At 15 degrees, less than 1%. The approximation holds well across the range where demonstration pendulums operate.

Under this approximation the restoring force becomes:

```
F ≈ -mg · theta
```

Linear in theta. Proportional to displacement. Structurally identical to Hooke's Law. The pendulum, for small swings, is a harmonic oscillator — and harmonic oscillators produce sine waves. That is the link from Intro to this map. The abstract equation `x = A·sin(wt + phi)` is not a mathematical convenience. It is the exact solution to any system where the restoring force is proportional to displacement.

## Integrating the Pendulum on the Fixed Step

The analytical solution tells you what a small swing does. The installation does not use it. `PendulumWave.gd` advances two numbers, the angle and the angular velocity, once per physics step, and everything the room shows follows from that:

```gdscript
func _physics_process(delta: float) -> void:
	# --- PHYSICS SIMULATION (The Driver), on the fixed step ---
	# Simple Pendulum Equation: alpha = -(g/L) * sin(theta)
	angular_acceleration = -(gravity / length) * sin(angle)
	angular_velocity += angular_acceleration * delta
	angular_velocity *= (1.0 - damping * delta) # Apply damping
	angle += angular_velocity * delta
	time += delta
```

`alpha` is the restoring acceleration, the exact `sin(theta)` rather than the small-angle `theta`, so the 45-degree release the room uses is handled without approximation. The velocity is updated first and the angle is then advanced with the new velocity. That order makes the scheme symplectic Euler: it does not pump energy into the swing the way position-first Euler does, and with `damping` at zero the amplitude and the period hold for as long as the room runs. The measured period at 45 degrees is about four percent longer than the small-angle formula gives; the readout prints both, and the difference is the `sin`.

`delta` is the physics step, one sixtieth of a second, independent of the headset's frame rate. `time` is the experiment's own clock and advances only here. The record described below is sampled from this clock, so its counts and spans are the same at 72, 90 or 120 frames per second.

## Period and Length: The Square-Root Law

The period of a simple pendulum under the small-angle approximation is:

```
T = 2π · √(L / g)
```

Period depends on length and gravity. Not on mass. Not on amplitude (within the small-angle regime). A heavy bob and a light bob on identical strings swing in unison. This was Galileo's observation, and it still startles.

The square root matters. Double the length and the period increases by sqrt(2) ≈ 1.414 — not by 2. Quadruple the length to double the period. Short pendulums are fast. Long pendulums are slower than short ones but not as slow as intuition expects.

```gdscript
# period_calculator.gd — compute and display T for a given length
extends Node3D

@export var pendulum_length: float = 1.0
@export var gravity: float = 9.8

func get_period() -> float:
    return TAU * sqrt(pendulum_length / gravity)

func _ready() -> void:
    var T := get_period()
    # L = 1.0m → T ≈ 2.006s
    # L = 0.25m → T ≈ 1.003s (half the period at quarter length)
    # L = 4.0m → T ≈ 4.013s (double the period at quadruple length)
```

`TAU` in Godot is 2*PI. At sea level (g = 9.8 m/s^2), a one-meter pendulum has a period of about two seconds. This is not a coincidence — the original definition of the meter was proposed as the length of a seconds pendulum (half-period of exactly one second). The unit and the physics are entangled.

## The PendulumWave: A Record With Two Limits

One pendulum stands under a gallows frame at the head of the open south half, rotated so that its record recedes down the hall toward the exit. The record is a list of samples. Each sample is the bob's position in the installation's frame and the experiment time it was taken at, and a fixed-time sampler decides when one is taken:

```gdscript
	_sample_clock += delta
	if _sample_clock >= sample_interval:
		_sample_clock -= sample_interval
		var bob_local := Vector3(length * sin(angle), pivot_height - length * cos(angle), 0.0)
		trail_points.push_front(Vector3(bob_local.x, bob_local.y, time))
	while trail_points.size() > max_trail_length:
		trail_points.pop_back()
	while not trail_points.is_empty() and time - trail_points.back().z > max_history_seconds:
		trail_points.pop_back()
```

Two rules end a record. `max_trail_length` is 300 and `max_history_seconds` is 10. Under the FINE policy (`sample_interval` 0.025 s) the count binds first: three hundred marks are 7.5 seconds, and the oldest mark leaves before it is ten seconds old. Under COARSE (0.2 s) the age binds: fifty marks fill ten seconds and the count never reaches its limit. Memory is bounded in both cases, and the readout beside the trail prints the count, the span kept and the interval in force, so a visitor can see which rule is doing the cutting.

The marks are drawn at a depth proportional to age:

```gdscript
		var depth: float = (time - p.z) * time_speed
		var at := Vector3(p.x, p.y, -depth)
```

`time_speed` is 0.6 metres per second of history. A mark 7.5 seconds old stands 4.5 metres behind the bob; a mark 10 seconds old, 6 metres. The line joining the marks is a list laid out along the hall's long axis. It is not a path the bob travelled and not a wave in any medium; a wave-shaped drawing is what a sampled oscillation looks like once one axis is time.

The pendulum times itself. Each upward crossing of the centre is kept, and the interval between two successive ones is the measured period:

```gdscript
	if _prev_angle < 0.0 and angle >= 0.0 and angular_velocity > 0.0:
		if _last_upward_crossing >= 0.0:
			_period_measured = time - _last_upward_crossing
```

The STROBE policy sets `sample_interval` to that period. Sampled once per cycle, every mark lands at the same phase and the record of a moving bob reads as a bob at rest. This is aliasing made bodily: the sampler has been given the rhythm of the thing it samples. Switching policies clears the list and leaves the swing untouched, so the comparison is of records, not of motions. RESET sets the angle back to `initial_angle`, the angular velocity and `time` to zero and empties the list; it is a reset of this experiment and nothing in the museum's clock.

The installation is housed by the script: two posts outside the widest swing, a beam and a short drop to the pivot at 2.9 metres, so the bob hangs at 0.9 metres and the swing reaches 1.5; a four-button panel (`RackTemplates.create_panel`, buttons FINE, COARSE, STROBE, RESET) on the walk-side post at 1.15 metres; and a cased readout on a stem three metres down the trail at 1.45 metres. The panel is marked `em_local_instrument` so its touch areas do not count as the installation's footprint in the museum. The scene's own camera, light, environment and floor are freed when the scene is not the root, so the room's lighting is the room's.

## The Seismograph: Oscillation as Trace

The seismograph artifact sits near the south wall. A drum rotates at constant speed. A stylus, coupled to a pendulum, scratches a trace on paper wrapped around the drum. As the drum turns and the ground oscillates, the stylus writes a sine wave — displacement on one axis, time on the other.

```gdscript
# seismograph_trace.gd — record pendulum motion as a scrolling line
extends Node3D

@export var scroll_speed: float = 0.5    # meters per second
@export var trace_amplitude: float = 1.0
@export var trace_length: int = 300       # sample buffer

var samples: PackedVector3Array = PackedVector3Array()
var write_head: float = 0.0

func record_sample(displacement: float, delta: float) -> void:
    write_head += scroll_speed * delta
    var point := Vector3(write_head, displacement * trace_amplitude, 0.0)
    samples.append(point)
    if samples.size() > trace_length:
        samples.remove_at(0)
```

The seismograph performs the same operation as the oscilloscope from the Intro — converting temporal oscillation into a spatial trace. The oscilloscope drew an electron beam on phosphor. The seismograph drags a physical stylus across paper. The medium changes. The mathematics does not.

The `draw_dot_time_domain` artifact near the north wall does this in reverse — plotting the pendulum's position as a dot moving along a time axis, building the sine curve in real time. Between the seismograph and the dot plotter, the map shows oscillation twice: once as physical motion (the swinging bob), once as recorded history (the trace). The bob lives in the present. The trace preserves the past. A waveform is a pendulum's autobiography written in space.

## The Foucault Pendulum: Rotation Beneath the Swing

The center of the map holds a Foucault pendulum — a heavy bob on a long cable, swinging freely. The pendulum does nothing unusual. It swings in a plane. What changes is the floor. Over hours, the plane of oscillation appears to rotate, tracing a rosette on the ground — overlapping arcs, each shifted slightly from the last.

The pendulum's plane does not rotate. The Earth rotates beneath it. At the poles, one full rotation every 24 hours. At the equator, none — the swing plane stays fixed. At intermediate latitudes, the rotation rate is 360 degrees times the sine of the latitude per day.

```gdscript
# foucault_pendulum.gd — pendulum with Earth-rotation coupling
extends Node3D

@export var cable_length: float = 5.0
@export var latitude_degrees: float = 48.8  # Paris
@export var time_scale: float = 3600.0      # accelerate for visibility

var theta: float = 0.3
var omega: float = 0.0
var precession_angle: float = 0.0

func _process(delta: float) -> void:
    var scaled_delta := delta * time_scale

    # Pendulum physics — unchanged
    var alpha := -(9.8 / cable_length) * sin(theta)
    omega += alpha * scaled_delta
    theta += omega * scaled_delta

    # Earth rotation precession
    var lat_rad := deg_to_rad(latitude_degrees)
    var precession_rate := TAU * sin(lat_rad) / 86400.0  # rad/s
    precession_angle += precession_rate * scaled_delta

    # Position: swing in a rotating plane
    var bob_x := cable_length * sin(theta) * cos(precession_angle)
    var bob_z := cable_length * sin(theta) * sin(precession_angle)
    var bob_y := -cable_length * cos(theta)
    position = Vector3(bob_x, bob_y, bob_z)
```

The `time_scale` compresses one hour into one second. Without acceleration, the precession takes hours to become visible. Compressed, the rosette builds in real time. The pendulum is a compass — not for magnetic north but for inertial space. It points where it was set swinging. Everything else moves.

No new physics is required. The restoring force is unchanged. The only addition is a frame rotation — the platform turns beneath the swing. This separation between oscillator and reference frame recurs throughout wave mechanics: the wave does not change, but the coordinate system might.

## The Double Pendulum: Chaos From Simplicity

Attach a second pendulum to the bob of the first. Two masses, two rods, two angles. The equations of motion are coupled second-order differential equations — but the system is still deterministic. Given exact initial conditions, the trajectory is exactly determined.

And yet the motion appears random. Two runs with initial angles differing by 0.001 radians diverge exponentially. Within seconds the trajectories bear no resemblance to each other. The double pendulum is the canonical example of deterministic chaos — predictable in principle, unpredictable in practice.

```gdscript
# double_pendulum.gd — chaos from two coupled oscillators
extends Node3D

@export var L1: float = 2.0
@export var L2: float = 2.0
@export var m1: float = 1.0
@export var m2: float = 1.0
@export var g: float = 9.8

var theta1: float = PI / 2.0
var theta2: float = PI / 2.0
var omega1: float = 0.0
var omega2: float = 0.0

func _process(delta: float) -> void:
    # Compute accelerations from Lagrangian mechanics
    var dt := delta * 0.5  # substep for stability
    for i in range(2):
        var d_theta := theta1 - theta2
        var denom := 2.0 * m1 + m2 - m2 * cos(2.0 * d_theta)

        var alpha1 := (-g * (2.0 * m1 + m2) * sin(theta1)
            - m2 * g * sin(theta1 - 2.0 * theta2)
            - 2.0 * sin(d_theta) * m2 * (
                omega2 * omega2 * L2
                + omega1 * omega1 * L1 * cos(d_theta)))
        alpha1 /= L1 * denom

        var alpha2 := (2.0 * sin(d_theta) * (
            omega1 * omega1 * L1 * (m1 + m2)
            + g * (m1 + m2) * cos(theta1)
            + omega2 * omega2 * L2 * m2 * cos(d_theta)))
        alpha2 /= L2 * denom

        omega1 += alpha1 * dt
        omega2 += alpha2 * dt
        theta1 += omega1 * dt
        theta2 += omega2 * dt

    # Position the two bobs
    var x1 := L1 * sin(theta1)
    var y1 := -L1 * cos(theta1)
    var x2 := x1 + L2 * sin(theta2)
    var y2 := y1 - L2 * cos(theta2)

    $Bob1.position = Vector3(x1, y1, 0)
    $Bob2.position = Vector3(x2, y2, 0)
```

The accelerations derive from the Lagrangian — total kinetic energy minus potential energy — differentiated with respect to each angle. Each angle's acceleration depends on both angles and both velocities. The coupling produces chaos. A single pendulum has one degree of freedom and periodic motion. Two coupled degrees of freedom produce aperiodic trajectories that never exactly repeat.

The substepping (2 iterations at half delta) mitigates the worst of Euler's drift. At high energies the system is violently unstable — a fourth-order Runge-Kutta integrator would handle this better. But the Euler version makes the chaos visible. The second bob whips unpredictably while the first maintains something closer to periodic motion. Order and chaos coexisting in a single system.

## From Oscillation to Wave

The laboratory holds the full arc of oscillatory ideas in physical form. Simple pendulum — restoring force proportional to displacement producing periodic motion. Period formula — geometry determining rhythm. PendulumWave — one swing sampled into a bounded record, with the rules that end it printed beside the trail. Seismograph and draw_dot_time_domain — temporal oscillation converted into spatial trace.

The Foucault pendulum extends the frame: oscillation unchanged, reference frame rotating, the pendulum connecting to the planet's own periodic motion. The double pendulum marks the boundary where deterministic oscillation produces trajectories complex enough to appear random.

The phi*Delta_E(S,t) dynamics in QFEP gain concrete grounding here. The pendulum is the simplest system where energy oscillates between kinetic and potential forms — the state variable S cycles through a periodic trajectory in phase space, and Delta_E shapes that trajectory through the restoring force. The period formula encodes how geometry (length) and field strength (gravity) determine the timescale of state evolution. The PendulumWave separates the state that carries the motion forward (an angle and a velocity) from the record that keeps a finite list of it, and lets the sampler that fills the list be changed while the state is not.

The BigPipeSystem along the south corridor and the GlassRack apparatus on the lab tables establish the aesthetic: a laboratory where oscillation is measured and recorded, not merely observed. The dark_sphere pulses in the central chamber — the same sine-driven emission from the Intro, now contextualized among physical oscillators. The lab_table benches anchor the experimental frame. What swings in this room is not abstract. It is weight and string and gravity.

The next map — WaveFunctions_Sine_Space — takes the oscillation that the pendulum produces in time and extends it into space. The pendulum swings. The wave travels. The mathematics are the same. The domain expands.

## Possible Artifacts

**period_vs_length_demonstrator** — A row of pendulums with a slider controlling length. As the learner drags, all rods update simultaneously and period changes according to T = 2*pi*sqrt(L/g). A readout displays L, T, and the ratio T/sqrt(L) — which remains constant. Small length changes at the short end produce large frequency shifts; the same change at the long end barely registers. Bridges the formula and the felt experience of how period depends on length.

**chaos_sensitivity_comparator** — Two double pendulums side by side, initialized with angles differing by a configurable epsilon (default 0.001 radians). Both run identical physics. A trace records each second bob's trajectory. The learner watches trajectories overlap then diverge exponentially. A divergence graph shows Euclidean distance between the two second bobs over time — exponential separation made quantitative. Connects to Forces_8's N-body sensitivity.

**energy_exchange_visualizer** — A simple pendulum with two stacked bar graphs: kinetic energy (0.5 * m * v^2) and potential energy (m * g * h). Kinetic peaks at the bottom, potential at the extremes. The total — a third bar — remains constant within Euler drift. Energy as a conserved quantity sloshing between two forms, grounding the QFEP energy landscape in direct observation. Optional damping slider shows the total bar shrinking when friction is introduced.
