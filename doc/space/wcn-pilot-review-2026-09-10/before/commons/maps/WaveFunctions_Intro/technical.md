# A control room lined with oscilloscopes and four cubes on rails

In Forces we watched springs oscillate and pendulums swing. Those were side effects — objects under force happened to repeat. A spring compressed, overshot equilibrium, compressed again. A pendulum traced an arc because gravity and tension conspired. The oscillation was real, but it was downstream of something else. This map treats oscillation as the primary event. Not a consequence of force — the phenomenon itself, isolated and controllable.

The room is small and deliberately closed. Oscilloscopes line the walls, green traces sweeping left to right — sine, square, sawtooth, triangle. Each one a different signature of the same principle: periodic motion between extremes. Four cubes sit on vertical rails at the center.

The first is still. The second oscillates. The third rotates. The fourth transforms under external control. Together they build the grammar of oscillation from rest to parametric expression.

## The Sine Function as Universal Oscillator

Every oscillation starts with sine. The function `sin(t)` takes an angle — measured in radians — and returns a value between -1 and 1. Feed it a steadily increasing angle and the output traces a wave: rising to 1, falling through 0 to -1, rising back. One complete cycle every 2π radians. The output is smooth, continuous, and perfectly periodic.

```gdscript
# The simplest oscillation: position driven by time
extends Node3D

var time: float = 0.0

func _process(delta: float) -> void:
    time += delta
    position.y = sin(time)
```

That's it. A node whose y-position follows `sin(time)`. At t = 0, position is 0. At t = π/2, position is 1. At t = π, back to 0.

At t = 3π/2, down to -1. At t = 2π, the cycle completes and begins again. The object never leaves. It never arrives. It oscillates.

Why sine and not some other repeating function? Because sine is the projection of uniform circular motion onto a line. Imagine a point moving at constant speed around a circle. Its shadow on the wall traces a sine wave. This is not a metaphor — it is the geometric definition. The `rotating_cube_demo` artifact in this map makes this connection visible: a cube spinning at constant angular velocity, its vertical shadow tracing the same curve as the `y_oscillation_cube` below it.

```gdscript
# rotating_cube_demo.gd — constant angular velocity
extends Node3D

@export var angular_velocity: float = 2.0  # radians per second
var angle: float = 0.0

func _process(delta: float) -> void:
    angle += angular_velocity * delta
    rotation.y = angle
```

Rotation is the parent of oscillation. The cube spins — its angle increases without bound. But project that rotation onto a single axis and the unbounded becomes bounded. The spin becomes a wave.

## The Governing Equation

The raw `sin(time)` oscillation has amplitude 1, completes one cycle every 2π seconds, and starts at zero. Those are defaults. The governing equation introduces three parameters that control everything:

```
x = A · sin(ωt + φ)
```

**A** is amplitude — the height of oscillation, the maximum displacement from center. **ω** (omega) is angular frequency — how fast the cycle completes. **φ** (phi) is phase — where in the cycle the motion begins. Three numbers. Complete control over any sinusoidal oscillation.

```gdscript
# oscillation_controlled_cube.gd — full parametric control
extends Node3D

@export var amplitude: float = 2.0     # A: max displacement
@export var omega: float = 3.0         # ω: angular frequency
@export var phase: float = 0.0         # φ: phase offset
var time: float = 0.0

func _process(delta: float) -> void:
    time += delta
    position.y = amplitude * sin(omega * time + phase)
```

The `oscillation_controlled_cube` artifact exposes these three parameters as sliders. Drag amplitude — the cube rides higher and lower on its rail. Drag omega — the cube speeds up or slows down. Drag phase — the entire motion shifts in time, as if rewinding or fast-forwarding the cycle. The equation is the same. The experience changes completely.

## Amplitude: The Range of Motion

Amplitude scales the sine output. `sin(t)` lives in [-1, 1]. Multiply by A and the range becomes [-A, A]. An amplitude of 3 means the cube travels 3 units above center and 3 units below. An amplitude of 0.1 means the cube barely moves — a tremor. An amplitude of 0 means stillness.

```gdscript
# The first cube: amplitude = 0, pure rest
# This is the baseline — no oscillation, no motion
@export var amplitude: float = 0.0

func _process(delta: float) -> void:
    time += delta
    position.y = amplitude * sin(omega * time + phase)
    # amplitude is 0, so position.y is always 0
```

The first cube in the room sits still. Not because it lacks a sine function — it has one. Its amplitude is zero. Stillness is not the absence of oscillation. It is oscillation with zero amplitude.

The equation still runs. The output is just a flatline. This matters because the oscilloscope beside it shows exactly that: a horizontal green trace at y = 0. The equation and the trace agree. Zero is a valid amplitude, and the system handles it without special cases.

Amplitude is always positive by convention. A negative amplitude flips the wave — but that is equivalent to a phase shift of π. The system has redundancy: `A · sin(ωt)` and `-A · sin(ωt)` produce the same motion, just started from opposite sides. Phase absorbs the sign.

## Angular Frequency: The Speed of Cycling

Angular frequency ω determines how many radians the argument of sine advances per second. Since one full cycle is 2π radians, the period T — the time for one complete oscillation — is:

```
T = 2π / ω
```

And the ordinary frequency f — cycles per second, measured in Hertz — is:

```
f = ω / 2π = 1 / T
```

Higher ω means faster oscillation. Double ω, halve the period. The `oscillation_controlled_cube` demonstrates this directly — slide the omega parameter up and the cube races through its cycles. Slide it toward zero and the motion slows to a crawl, approaching the static cube's flatline.

```gdscript
# Frequency comparison: two cubes side by side
# Cube A: omega = 1.0 → period ≈ 6.28 seconds
# Cube B: omega = 4.0 → period ≈ 1.57 seconds
# Cube B completes four cycles in the time Cube A completes one

var omega_slow: float = 1.0
var omega_fast: float = 4.0

# In _process:
cube_a.position.y = amplitude * sin(omega_slow * time)
cube_b.position.y = amplitude * sin(omega_fast * time)
```

Angular frequency connects to angular velocity from the `rotating_cube_demo`. A cube spinning at ω radians per second and a cube oscillating at ω radians per second are doing the same thing — one in the full circular plane, the other projected onto a line. The number is identical. The domain is different.

## Phase: Where the Cycle Begins

Phase φ shifts the starting point. At t = 0, the position is `A · sin(φ)` instead of `A · sin(0) = 0`. A phase of π/2 starts the oscillation at maximum displacement — the top of the wave. A phase of π starts it at zero but moving in the opposite direction. A phase of 2π is the same as a phase of 0 — the wave is periodic, so the shift wraps around.

```gdscript
# Three cubes with different phase offsets
# Same amplitude, same frequency, different starting points
var phase_a: float = 0.0           # starts at center, moving up
var phase_b: float = PI / 2.0     # starts at maximum
var phase_c: float = PI           # starts at center, moving down

func _process(delta: float) -> void:
    time += delta
    cube_a.position.y = amplitude * sin(omega * time + phase_a)
    cube_b.position.y = amplitude * sin(omega * time + phase_b)
    cube_c.position.y = amplitude * sin(omega * time + phase_c)
```

Phase is the hardest parameter to grasp because it does not change what the motion looks like — only when it happens. All three cubes above trace the same path. They just occupy different positions along that path at any given instant. The oscilloscope reveals this: three identical waveforms, shifted left and right in time. The shape is invariant. The alignment is not.

Phase becomes critical when oscillations interact. Two waves of equal amplitude and frequency but opposite phase (φ differs by π) cancel completely — destructive interference. Same phase, they reinforce — constructive interference. But interference is a later map. Here, phase is simply the third control on the parametric oscillator.

## Combined Transformations: One Signal, Three Outputs

The `control_pendulum` artifact is the room's primary encounter, and its angle is not a sine function of time. The earlier version of this document printed an invented script here in which the pendulum evaluated `sin(pendulum_omega * time)`; that script never existed. The real one integrates. Each physics step (`control_pendulum.gd`, `_physics_process`):

```gdscript
var angular_acceleration: float = -(gravity / pendulum_length) * sin(_angle)
_angular_velocity += angular_acceleration * delta
_angular_velocity *= _damping_multiplier(delta)
_angle += _angular_velocity * delta
```

The sine is in the acceleration, not the position. Gravity supplies an angular acceleration proportional to `sin(θ)` toward the hanging position; it changes the velocity; the velocity changes the angle; the new angle sets the next acceleration. Under the shipped `free` regime the damping multiplier is a constant 0.995 per physics frame (the other regimes express it as a damping ratio against ω₀ = √(g/L)). The angle is clamped to ±0.45π so a violent release cannot flip the bob over the pivot. Nothing here consults a clock.

The release converts the hand into an initial condition. While the bob is held, the pendulum reads the angle back from the bob's position each frame and keeps the last five frame-to-frame velocities. On `dropped` it averages them and keeps only the component along the swing (`_on_bob_dropped`):

```gdscript
var tangent_direction = Vector3(-cos(_angle), -sin(_angle), 0)
var tangent_velocity = avg_velocity.dot(tangent_direction)
_angular_velocity = tangent_velocity / pendulum_length
```

Two things were added for the 2026-09-10 pilot and are declared in the placement `control_pendulum:0:1.5:1#reference:plumb#evidence:trace`. `reference=plumb` builds a hairline from the pivot to the rest point and a ring at the rest point that brightens for a moment at each centre crossing; a crossing is a sign change of `_angle` while |ω| exceeds a small threshold, and each one emits `centre_crossed(direction, angular_velocity)` and increments a count the label shows. The label itself now prints the angle and the **signed** angular velocity — the shipped version printed `abs(_angular_velocity)`, which discards the one number that tells two visits to the centre apart. `evidence=trace` draws θ(t) for the next six seconds, integrated at build time with the same update rule from the standard starting angle of 0.3 rad, on a fixed vertical scale.

The `oscillation_controlled_cube` beside it is the "one signal, three outputs" demonstration, and it is driven by this pendulum rather than by a sine of its own: at `_ready` it looks for a `ControlPendulum` sibling and connects to its `oscillation_updated(y_offset, angular_velocity, amplitude)` signal, mapping the three values to height, tilt and size. Take the bob and the cube stops with it. The cubes that set their height from `sin(time)` — `y_oscillation_cube`, `transformation_cube` — do not, and that difference is the room's comparison.

The `mario_cube_time_trace` artifact extends this idea by drawing the signal's history as a visible trail — a ribbon of past positions tracing the sine wave in space. Time made spatial. The oscilloscope does the same thing on its screen: amplitude on the vertical axis, time on the horizontal. The trace is the oscillation's autobiography.

## The Oscilloscope: Time Made Visible

An oscilloscope plots amplitude against time. The green traces on the walls of this room are doing exactly what `_process` does — sampling a signal every frame and plotting the result:

```gdscript
# oscilloscope_trace.gd — draw a waveform as a polyline
extends Node3D

@export var trace_length: int = 200
@export var time_scale: float = 0.05
@export var amplitude_scale: float = 1.0
@export var waveform: String = "sine"

var samples: PackedVector2Array = PackedVector2Array()

func _process(delta: float) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    var value := _sample_waveform(t)
    samples.append(Vector2(samples.size() * time_scale, value * amplitude_scale))
    if samples.size() > trace_length:
        samples.remove_at(0)

func _sample_waveform(t: float) -> float:
    match waveform:
        "sine":
            return sin(t * omega)
        "square":
            return sign(sin(t * omega))
        "sawtooth":
            return 2.0 * fmod(t * omega / TAU, 1.0) - 1.0
        "triangle":
            return 2.0 * abs(2.0 * fmod(t * omega / TAU, 1.0) - 1.0) - 1.0
    return 0.0
```

Four waveforms. All periodic. All oscillating between -1 and 1. The sine is smooth — continuous in value and in slope. The square wave snaps between extremes — maximum or minimum, nothing between. The sawtooth ramps linearly then drops. The triangle ramps up and ramps down — continuous in value but with sharp corners in slope.

Each waveform has the same period. Each has the same amplitude. They differ in shape — in how the signal traverses the space between -1 and 1. Sine takes its time at the extremes (the derivative is zero at peaks) and rushes through the center (maximum derivative at zero crossings). Square spends all its time at the extremes. Sawtooth moves at constant speed in one direction, then teleports back. These are different answers to the same question: how do you fill the space between -1 and 1 periodically?

## Springs: The Physical Oscillator

Hooke's Law states that the restoring force of a spring is proportional to displacement:

```
F = -kx
```

**k** is the spring constant — stiffness. **x** is displacement from equilibrium. The negative sign means the force opposes the displacement: stretch the spring right, the force pulls left. Compress it left, the force pushes right. Always toward center. Always proportional.

```gdscript
# spring_oscillator.gd — Hooke's Law producing oscillation
extends Node3D

@export var spring_k: float = 4.0
@export var mass: float = 1.0
@export var initial_displacement: float = 2.0
var displacement: float
var velocity: float = 0.0

func _ready() -> void:
    displacement = initial_displacement

func _process(delta: float) -> void:
    var force := -spring_k * displacement  # Hooke's Law
    var acceleration := force / mass       # Newton's second law
    velocity += acceleration * delta       # Euler integration
    displacement += velocity * delta
    position.y = displacement
```

Force from displacement. Acceleration from force. Velocity from acceleration. Position from velocity. Four links in the chain — and the result is oscillation. The block bounces. Not because anyone told it to follow a sine wave — because the physics produces one. The analytical solution of F = -kx under Newton's second law is:

```
x(t) = A · sin(√(k/m) · t + φ)
```

The governing equation again. Angular frequency ω = √(k/m). Higher stiffness k means faster oscillation. Higher mass m means slower. Amplitude A and phase φ come from initial conditions — how far you pulled the spring and how fast it was moving when you let go.

This is the bridge from Forces. The `control_pendulum` in this map connects backward to the spring systems and pendulums of the previous sequence. There, the oscillation emerged from physical simulation — forces integrated over time. Here, the same oscillation is described analytically. Two paths to the same curve. The simulation is general but approximate (Euler integration accumulates error). The equation is exact but specific (only works for simple harmonic motion). Both are needed.

## Oscillation as Non-Trivial Time

Constant motion is trivial — the same thing forever. Random motion is unpredictable — no structure to exploit. Oscillation sits between these extremes. It changes — but predictably. It repeats — but not monotonically. It has structure in time the way geometry has structure in space.

The `dark_sphere` artifact in this map pulses with a sine-driven emission:

```gdscript
# dark_sphere.gd — emission energy oscillation
var pulse_t := (sin(time * pulse_speed) + 1.0) * 0.5
sphere_material.emission_energy_multiplier = lerpf(pulse_min, pulse_max, pulse_t)
```

The `(sin(...) + 1.0) * 0.5` pattern maps [-1, 1] to [0, 1] — a normalized oscillation. The `lerpf` then maps [0, 1] to [pulse_min, pulse_max]. Two remappings: shift-and-scale to normalize, linear interpolation to target. The sphere breathes. Not because it is alive — because its emission follows a periodic function of time. Oscillation animates.

This is the first non-trivial temporal pattern in the sequence. Constants describe equilibrium. Linear functions describe uniform change. Oscillation describes return — the system that moves away from center and comes back, endlessly. The QFEP framework treats oscillatory dynamics as the foundation of wave mechanics — the φ·ΔE(S,t) term acquires periodic structure here, before the sequence extends it to pendulums, coupled oscillators, and eventually standing waves. The four cubes are not demonstrations. They are the grammar. Rest, oscillation, rotation, combined transformation — from these four primitives, everything that waves is built.

## Possible Artifacts

**waveform_composer** — An interactive artifact with four oscilloscope-style traces (sine, square, sawtooth, triangle) and a fifth trace showing their weighted sum. Sliders control the amplitude of each component waveform. Demonstrates that complex periodic signals decompose into simpler periodic components — the intuition behind Fourier analysis without naming it. The learner sees how adjusting one waveform's contribution reshapes the composite. Connects the four wall-mounted oscilloscopes in the room to the idea that waveforms combine.

**parameter_space_explorer** — A three-dimensional control surface where the x-axis maps to amplitude, the y-axis to frequency, and the z-axis to phase. A point in this space defines a unique oscillation. The learner drags the point and watches the resulting waveform update on an oscilloscope display beside it. Collapses the three separate slider experiences of the `oscillation_controlled_cube` into a single spatial interaction. Makes visible that the space of all sinusoidal oscillations is itself three-dimensional.

**spring_vs_sine_comparator** — Two cubes side by side: one driven by the analytical equation `A · sin(ωt + φ)`, the other by Euler-integrated Hooke's Law simulation. Both start with identical initial conditions. Over time the simulated version drifts — Euler error accumulates, the amplitude grows or decays, the phase slips. The analytical version is exact. A residual trace shows the growing difference. Teaches why closed-form solutions matter and where numerical simulation breaks down — the bridge between Forces' simulation approach and this map's analytical one.
