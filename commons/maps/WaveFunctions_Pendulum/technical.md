# A laboratory of swinging weights where glass apparatus lines the benches and a Foucault pendulum traces rosettes on the floor

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

## Euler Integration of a Pendulum

The analytical solution tells you what the pendulum does. Numerical integration shows you how to simulate it — and where simulation breaks. The state of a simple pendulum is two numbers: angular position theta and angular velocity omega. Each frame, compute the angular acceleration from the restoring force, update velocity, update position:

```gdscript
# simple_pendulum.gd — Euler integration of a simple pendulum
extends Node3D

@export var length: float = 3.0          # rod length in meters
@export var gravity: float = 9.8         # gravitational acceleration
@export var initial_angle: float = 0.25  # radians (~14 degrees)
@export var damping: float = 0.0         # energy loss per second

var theta: float
var omega: float = 0.0  # angular velocity

func _ready() -> void:
    theta = initial_angle

func _process(delta: float) -> void:
    # Restoring acceleration: -g/L * sin(theta)
    var alpha := -(gravity / length) * sin(theta)

    # Euler integration
    omega += alpha * delta
    omega *= (1.0 - damping * delta)  # optional damping
    theta += omega * delta

    # Map angular position to visual: bob position
    position.x = length * sin(theta)
    position.y = -length * cos(theta)
```

Three lines of physics. `alpha` is angular acceleration — restoring torque divided by moment of inertia, which for a point mass on a massless rod simplifies to `-g/L * sin(theta)`. Omega accumulates acceleration. Theta accumulates velocity. The result is oscillation — not because oscillation was requested but because the mathematics of restoring force demand it.

This code uses `sin(theta)`, not the small-angle approximation `theta`. The simulation handles arbitrarily large swings. Launch a pendulum at 170 degrees and it still works — the motion is no longer sinusoidal, the period depends on amplitude, but the integration is valid. The small-angle approximation is needed only for the analytical solution. Simulation is free to use the exact force.

The damping term bleeds energy each frame. At `damping = 0.0`, the pendulum swings forever. At `damping = 0.02`, amplitude decays exponentially — air resistance. At high damping the pendulum crawls back to vertical and stops. Damping is the dial between perpetual oscillation and overdamped collapse.

Euler integration drifts. Over thousands of frames the amplitude grows slightly — the integrator injects energy the physics did not supply. The `draw_dot_time_domain` artifact records the pendulum's trace over time, writing position onto a scrolling canvas. Run it long enough and the drift becomes visible as slow amplitude creep. A symplectic integrator (Verlet, leapfrog) conserves energy better — but Euler is transparent, and transparency is the priority here.

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

## The PendulumWave: Phase From Length

Three PendulumWave installations line the east wall of this map. Each is a row of pendulums with incrementally different lengths. The shortest swings fastest. The longest swings slowest. Release them simultaneously and the phase relationships evolve — the bobs drift apart, form patterns, converge, and drift again.

```gdscript
# pendulum_wave.gd — N pendulums with graduated lengths
extends Node3D

@export var num_pendulums: int = 15
@export var min_length: float = 0.8
@export var max_length: float = 3.0
@export var base_cycles: float = 10.0   # shortest pendulum cycles in window
@export var window_time: float = 30.0   # seconds for one full pattern cycle

var pendulums: Array[Dictionary] = []

func _ready() -> void:
    for i in range(num_pendulums):
        var t := float(i) / float(num_pendulums - 1)
        # Each pendulum completes a different number of cycles in window_time
        var cycles := base_cycles + float(i)
        var T := window_time / cycles
        var L := gravity_length_from_period(T)

        pendulums.append({
            "length": L,
            "theta": 0.3,  # same initial angle
            "omega": 0.0,
            "period": T
        })

func gravity_length_from_period(T: float) -> float:
    # Invert T = 2π√(L/g) → L = g·(T/2π)²
    return 9.8 * pow(T / TAU, 2)

func _process(delta: float) -> void:
    for p in pendulums:
        var alpha := -(9.8 / p["length"]) * sin(p["theta"])
        p["omega"] += alpha * delta
        p["theta"] += p["omega"] * delta
```

All pendulums start at the same angle. Same amplitude. Same initial phase. The only difference is length — which determines period. Over time, each accumulates phase at a different rate. The visual result is a wave propagating along the row of bobs, even though no energy passes between them. Each pendulum is independent. The wave is an illusion of coordinated phase — a spatial pattern emerging from temporal differences.

This is the same principle behind the phase parameter phi from the Intro. There, phase was a slider. Here, phase is a consequence of geometry — different lengths produce different frequencies, which produce evolving phase offsets. The PendulumWave makes phase visible without naming it.

After exactly `window_time` seconds, all pendulums return to their starting configuration. The shortest has completed `base_cycles` oscillations. Each subsequent pendulum has completed one fewer. The pattern repeats — a wave whose constituents are themselves waves. This is the first hint of what the later maps call superposition.

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

The laboratory holds the full arc of oscillatory ideas in physical form. Simple pendulum — restoring force proportional to displacement producing periodic motion. Period formula — geometry determining rhythm. PendulumWave — phase relationships made visible across multiple oscillators. Seismograph and draw_dot_time_domain — temporal oscillation converted into spatial trace.

The Foucault pendulum extends the frame: oscillation unchanged, reference frame rotating, the pendulum connecting to the planet's own periodic motion. The double pendulum marks the boundary where deterministic oscillation produces trajectories complex enough to appear random.

The phi*Delta_E(S,t) dynamics in QFEP gain concrete grounding here. The pendulum is the simplest system where energy oscillates between kinetic and potential forms — the state variable S cycles through a periodic trajectory in phase space, and Delta_E shapes that trajectory through the restoring force. The period formula encodes how geometry (length) and field strength (gravity) determine the timescale of state evolution. The PendulumWave demonstrates that small parameter differences produce evolving phase relationships — the spatial unfolding of temporal dynamics that the framework's field interactions describe.

The BigPipeSystem along the south corridor and the GlassRack apparatus on the lab tables establish the aesthetic: a laboratory where oscillation is measured and recorded, not merely observed. The dark_sphere pulses in the central chamber — the same sine-driven emission from the Intro, now contextualized among physical oscillators. The lab_table benches anchor the experimental frame. What swings in this room is not abstract. It is weight and string and gravity.

The next map — WaveFunctions_Sine_Space — takes the oscillation that the pendulum produces in time and extends it into space. The pendulum swings. The wave travels. The mathematics are the same. The domain expands.

## Possible Artifacts

**period_vs_length_demonstrator** — A row of pendulums with a slider controlling length. As the learner drags, all rods update simultaneously and period changes according to T = 2*pi*sqrt(L/g). A readout displays L, T, and the ratio T/sqrt(L) — which remains constant. Small length changes at the short end produce large frequency shifts; the same change at the long end barely registers. Bridges the formula and the felt experience of how period depends on length.

**chaos_sensitivity_comparator** — Two double pendulums side by side, initialized with angles differing by a configurable epsilon (default 0.001 radians). Both run identical physics. A trace records each second bob's trajectory. The learner watches trajectories overlap then diverge exponentially. A divergence graph shows Euclidean distance between the two second bobs over time — exponential separation made quantitative. Connects to Forces_8's N-body sensitivity.

**energy_exchange_visualizer** — A simple pendulum with two stacked bar graphs: kinetic energy (0.5 * m * v^2) and potential energy (m * g * h). Kinetic peaks at the bottom, potential at the extremes. The total — a third bar — remains constant within Euler drift. Energy as a conserved quantity sloshing between two forms, grounding the QFEP energy landscape in direct observation. Optional damping slider shows the total bar shrinking when friction is introduced.
