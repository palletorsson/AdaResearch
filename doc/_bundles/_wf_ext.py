import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

adds = {
'WaveFunctions_3D_Wave_Propagation': """

## Wave Equation Derivation

The scalar wave equation for propagation is ∂²u/∂t² = c²∇²u, where c is the propagation speed. Finite-difference discretisation produces a stable update rule: u(x, t+dt) = 2u(x,t) - u(x,t-dt) + (c·dt/dx)²(u(x+dx,t) + u(x-dx,t) + ... - 6u(x,t)) in 3D. The Courant-Friedrichs-Lewy (CFL) condition requires c·dt/dx ≤ 1/sqrt(3) in 3D for stability.

```gdscript
class_name WaveSim extends Node3D

@export var grid_size: Vector3i = Vector3i(32, 32, 32)
@export var dx: float = 0.25
@export var dt: float = 0.05
@export var c: float = 1.0

var u_now: PackedFloat32Array
var u_past: PackedFloat32Array

func step() -> void:
    var u_next := PackedFloat32Array()
    u_next.resize(u_now.size())
    var coef: float = pow(c * dt / dx, 2)
    # Inner cells only; boundary cells are zero-damped
    for x in range(1, grid_size.x - 1):
        for y in range(1, grid_size.y - 1):
            for z in range(1, grid_size.z - 1):
                var i: int = idx(x, y, z)
                var laplacian: float = u_now[idx(x+1,y,z)] + u_now[idx(x-1,y,z)] + u_now[idx(x,y+1,z)] + u_now[idx(x,y-1,z)] + u_now[idx(x,y,z+1)] + u_now[idx(x,y,z-1)] - 6.0 * u_now[i]
                u_next[i] = 2.0 * u_now[i] - u_past[i] + coef * laplacian
    u_past = u_now
    u_now = u_next
```

The field lattice renderer samples u_now at each marker position. Grid-based wave simulation is O(N³) per step for an N×N×N grid.

## Absorbing Boundaries

Simulating infinite space in a finite grid requires boundary conditions that absorb outgoing waves without reflection. The simplest is a damping zone near the grid edges where amplitudes are multiplied by a factor less than 1 each step. More sophisticated approaches use Perfectly Matched Layers (PML) that absorb at all angles.
""",
'WaveFunctions_Effect_Sound': """

## Additive Synthesis

Any periodic waveform can be built by adding sinusoids. The Fourier series expansion of a square wave is Σ (1/n) sin(nωt) for odd n. A sawtooth is Σ (1/n) sin(nωt) for all n. Truncating the series to a finite number of harmonics produces band-limited waveforms that avoid aliasing at high pitches.

```gdscript
func band_limited_square(phase: float, harmonics: int) -> float:
    var result: float = 0.0
    for k in range(1, harmonics + 1, 2):  # odd harmonics only
        result += sin(phase * k) / k
    return result * 4.0 / PI
```

## Sample Rate and Aliasing

Generating audio at 44100 Hz restricts the signal's frequency content to half that rate — the Nyquist frequency at 22050 Hz. Any signal component above Nyquist folds back into the audible range as aliased frequencies. Band-limited synthesis techniques (windowed sinc interpolation, polyBLEP correction) prevent aliasing at the cost of additional computation.

## Subtractive Synthesis

The complementary technique filters a harmonically rich source through lowpass, highpass, or bandpass filters. An analog-style lowpass filter is a resonant biquad section:

```gdscript
func biquad_lowpass(input: float, state: Array, cutoff: float, q: float, sr: float) -> float:
    var omega: float = 2.0 * PI * cutoff / sr
    var sin_w: float = sin(omega)
    var cos_w: float = cos(omega)
    var alpha: float = sin_w / (2.0 * q)
    var b0: float = (1.0 - cos_w) / 2.0
    var b1: float = 1.0 - cos_w
    var b2: float = (1.0 - cos_w) / 2.0
    var a0: float = 1.0 + alpha
    var a1: float = -2.0 * cos_w
    var a2: float = 1.0 - alpha
    var output: float = (b0 / a0) * input + (b1 / a0) * state[0] + (b2 / a0) * state[1] - (a1 / a0) * state[2] - (a2 / a0) * state[3]
    state[1] = state[0]; state[0] = input
    state[3] = state[2]; state[2] = output
    return output
```

## Envelope Generators

An amplitude envelope shapes each note's volume over time. The classical ADSR model has four phases: Attack (rise to peak), Decay (drop to sustain), Sustain (held level), Release (drop to zero).
""",
'Wavefunctions_Bernini': """

## Solomonic Spiral Parameters

Bernini's Baldachin columns have specific proportions. Each column is about 20 metres tall, twisted through approximately 1.5 full revolutions. The map's twist_rate parameter defaults to 2.0 for visual clarity at room scale, but settings around 1.5 produce the historically accurate profile.

## Surface Normal Computation

Smooth shading on procedural geometry requires per-vertex normals. For a surface parameterised by (u, v), the normal is the cross product of the two partial derivatives:

```gdscript
func compute_normal_at(ring: int, side: int, rings: int, sides: int) -> Vector3:
    var t_current := float(ring) / rings
    var t_next := float(ring + 1) / rings
    var angle_current := float(side) / sides * TAU + twist_rate * TAU * t_current
    var angle_next := float(side + 1) / sides * TAU + twist_rate * TAU * t_current
    var p0 := vertex_at(t_current, angle_current)
    var p1 := vertex_at(t_next, angle_current)
    var p2 := vertex_at(t_current, angle_next)
    var du := p1 - p0
    var dv := p2 - p0
    return du.cross(dv).normalized()
```

## Tessellation-Free Approach

For extreme close-ups, mesh tessellation produces visible polygonal facets. A displacement shader can perform the column deformation on the GPU at rendering time, preserving smooth curvature at any zoom level.

```glsl
// Shader vertex displacement
vec3 displaced_vertex(vec3 base_vertex, float twist_rate) {
    float t = (base_vertex.y + HEIGHT * 0.5) / HEIGHT;
    float angle = base_vertex.x * TAU + twist_rate * TAU * t;
    float radius = BASE_RADIUS + SWIRL_AMPLITUDE * sin(SWIRL_FREQUENCY * base_vertex.y);
    return vec3(cos(angle) * radius, base_vertex.y, sin(angle) * radius);
}
```

## Material Properties

Bernini's bronze Baldachin is reflective and moderately rough — a physically-based material with metallic = 1.0 and roughness = 0.4. The map uses this exact material on the procedural columns for visual continuity with the historical reference.

## Reference Photograph Panel

A photograph of the Baldachin in Saint Peter's Basilica is displayed alongside the procedural column. The comparison makes the procedural reinterpretation visible as a decomposition of the baroque form into tunable parameters.
""",
'WaveFunctions_John_Cage': """

## Compositional Context

Cage composed 4'33" in 1952. The piece instructs the performer to sit at the piano for the specified duration without playing any notes. The published score divides the duration into three movements (30 seconds, 2 minutes 23 seconds, 1 minute 40 seconds) and instructs "tacet" (silence) for each.

The piece has been performed thousands of times since its premiere. Different performances vary substantially in what is audible, which is the composition's thesis: the performance is whatever the audience is attending to during the specified duration.

## Aleatoric Composition Tools

Cage's later aleatoric works used the I Ching, star charts, and random number tables to generate compositional material. The map's three chance devices are simplified equivalents.

```gdscript
class_name IChing

func hexagram() -> Array:
    var lines: Array = []
    for _i in range(6):
        # Three coin flips per line
        var sum: int = 0
        for _j in range(3):
            sum += 2 if randf() < 0.5 else 3
        lines.append(sum)
    return lines
```

An I Ching hexagram has 64 possible outcomes corresponding to 64 hexagram names and interpretations. Cage mapped these to musical parameters in his *Music of Changes* (1951).

## Dynamic Noise Floor

The ambient noise floor has structure at multiple time scales: fast components (HVAC cycling, ventilation) and slow components (building settling, diurnal temperature variation). The map's simulated noise floor uses layered noise to produce realistic variation over several time scales.

```gdscript
func simulated_noise_floor(time: float) -> float:
    var slow := 0.3 * sin(time * 0.01)  # very slow drift
    var medium := 0.2 * noise.get_noise_1d(time * 0.5)
    var fast := 0.1 * noise.get_noise_1d(time * 5.0)
    return -45.0 + slow + medium + fast  # dB
```

## Silence as Signal

The noise floor meter demonstrates that silence in a recorded environment is never actually zero. The meter's minimum value is set by the recording equipment's inherent noise — typically -60 dB below full scale for consumer microphones, -80 dB for professional equipment.

## Piece Duration Counter

A countdown timer displays the remaining time for the piece. When the timer reaches zero, the piece ends automatically and the station reopens for a new performance.
""",
'WaveFunctions_AirMusic': """

## Phasing Relationships

Steve Reich's *Piano Phase* (1967) uses two pianists playing the same 12-beat pattern at slightly different tempos. Over ~20 minutes, the second pianist moves from in-phase to 1-beat out-of-phase and back, creating shifting harmonic relationships.

The map's loops use simpler phasing: two-voice relationships where one voice is at frequency f and the other at f·(1 + ε). The beat period is 1/ε, so ε = 0.05 produces a 20-second phase cycle.

## Reverb

Spatial audio includes reverberation — multiple reflections off room surfaces producing a tail after the direct sound. Godot's AudioEffectReverb simulates this with adjustable parameters:

```gdscript
var reverb := AudioEffectReverb.new()
reverb.room_size = 0.8
reverb.damping = 0.5
reverb.predelay_msec = 20.0
reverb.predelay_feedback = 0.4
reverb.wet = 0.3
AudioServer.add_bus_effect(music_bus_idx, reverb)
```

The reverb gives the ambient loops a sense of being in a space, which is core to Eno's aesthetic.

## Generative Ambient

Brian Eno coined "generative music" to describe systems that produce ongoing compositions without a fixed duration. The map's three-loop phasing is a minimal generative system; Eno's *Generative Music 1* (1996) used more elaborate multi-voice phasing with dozens of parallel loops.

## Volume Ducking

To preserve dynamic range when multiple loops overlap, the map applies a gentle sidechain-style ducking. When one loop's amplitude spikes, the others dim slightly, preventing the cumulative signal from clipping.

```gdscript
func adjust_loop_volumes(active_loops: Array) -> void:
    var total_amplitude: float = 0.0
    for loop in active_loops:
        total_amplitude += loop.current_amplitude()
    if total_amplitude > 1.0:
        var ducking: float = 1.0 / total_amplitude
        for loop in active_loops:
            loop.apply_ducking(ducking)
```

## Pitch Tile Grid

The floor of pitch tiles is arranged in a grid where horizontal position maps to scale degree and vertical position maps to octave. The scale is configurable — major, minor, pentatonic, or raga-based scales all work with the same tile grid.
""",
'Wavefunctions_Sky_Stairs': """

## Helical Geometry

A helix is parameterised by its pitch (vertical distance per revolution) and radius. For a helix with pitch P and radius R, arc length per revolution is sqrt((2πR)² + P²). The map's default helix has R=4 and P=20, giving arc length ~28.6 per revolution.

## Step Placement

Each step is placed tangent to the helix, so its front face is perpendicular to the direction of travel. Computing the tangent requires the derivative of the helical parameterisation:

```gdscript
func helix_tangent(t: float, radius: float, pitch: float, angular_rate: float) -> Vector3:
    var dx: float = -angular_rate * TAU * radius * sin(angular_rate * TAU * t)
    var dy: float = pitch
    var dz: float = angular_rate * TAU * radius * cos(angular_rate * TAU * t)
    return Vector3(dx, dy, dz).normalized()
```

The step's orientation basis is built from this tangent plus an up vector (global UP projected onto the plane perpendicular to the tangent).

## Safety Railings

Real staircases need railings; VR staircases need them more because a fall at height is immersion-breaking if handled poorly. The map adds railings whose height is standardised (waist-high from step surface) but whose shape follows the helix.

```gdscript
func add_railing(step_position: Vector3, tangent: Vector3) -> void:
    var railing := RAILING_SCENE.instantiate()
    railing.global_position = step_position + Vector3(0, 1.0, 0)
    railing.look_at(step_position + tangent, Vector3.UP)
    add_child(railing)
```

## Cube Field Density

The floating cube fields' density is sampled from a wave equation: density(altitude) = (sin(altitude * k) + 1) / 2, producing alternating bands of high and low density. At low wavelength, the cubes form thick bands; at high wavelength, finer stratification.

```gdscript
func density_at_altitude(altitude: float, wavelength: float) -> float:
    var k: float = TAU / wavelength
    return (sin(altitude * k) + 1.0) / 2.0
```

Cubes are spawned via rejection sampling: candidate positions are proposed at random altitudes, and each candidate is accepted with probability equal to the density at its altitude.

## Performance

The tower contains about 300 steps across three staircases and 600 cubes across multiple altitude fields. Rendering uses MultiMeshInstance3D for the cubes and instanced meshes for the steps, keeping draw calls below 50.
""",
'WaveFunctions_TrigWalkingPath': """

## Lane Separation

The two lanes are separated by 2 units horizontally — close enough for the learner to step between them, far enough that the two functions' offset is visible as a spatial relationship rather than merely on a chart.

## Dynamic Path Generation

Generating the path procedurally as the learner approaches means the map has effectively infinite length. Old steps are removed when they fall behind the walker by a fixed distance, bounding memory use.

```gdscript
class_name PathGenerator extends Node3D

@export var lookahead_distance: float = 8.0
@export var behind_cleanup_distance: float = 4.0

func _process(_delta: float) -> void:
    var walker_x: float = walker.global_position.x
    ensure_steps_up_to(walker_x + lookahead_distance)
    remove_steps_before(walker_x - behind_cleanup_distance)
```

## Phase Offset Demonstration

At any horizontal position x, the vertical difference between the sin lane's step height and the cos lane's step height is |sin(x) - cos(x)|, which equals √2·|sin(x - π/4)|. This reaches its maximum of √2 at x = 3π/4 + kπ for integer k.

```gdscript
func maximum_offset_positions(frequency: float, total_range: float) -> Array:
    var positions: Array = []
    var k: int = 0
    while true:
        var x: float = (3.0 * PI / 4.0 + k * PI) / (frequency * TAU)
        if x > total_range: break
        positions.append(x)
        k += 1
    return positions
```

## Pitch Mapping

A variant of the map maps lane height to pitch — the learner's altitude determines the tone that plays as they walk. Climbing the sin lane produces a sine-like pitch profile; the cos lane produces the same profile offset by 90°.

## Chart Rendering

The reference panel redraws the chart once per frame. Drawing two sinusoids at panel resolution (say 300 pixels wide) is 600 line segments per frame — trivial on modern hardware.

## Interactive Parameters

The entrance sliders adjust frequency and amplitude for both lanes simultaneously. Independent adjustment would be possible but would break the "sin and cos are the same function offset" pedagogy the map is built around.
""",
'Chamber_Waves': """

## Helix Projectile Geometry

The helix projectile's position at time t is: base_position + forward_direction * speed * t + (cos(f*t*TAU) * radius) * right + (sin(f*t*TAU) * radius) * up. The right and up vectors are derived from the forward direction and a reference up vector using cross products.

```gdscript
func helix_position(start: Vector3, forward: Vector3, speed: float, radius: float, frequency: float, age: float) -> Vector3:
    var right := forward.cross(Vector3.UP).normalized()
    var up := right.cross(forward).normalized()
    var helix_angle: float = frequency * age * TAU
    return start + forward * speed * age + right * cos(helix_angle) * radius + up * sin(helix_angle) * radius
```

## Waterbomb Bounce Physics

The waterbomb uses a simplified bounce that treats collision as an elastic rebound with gravity between bounces. The bounce frequency is set to match the catalyst's tuning target.

```gdscript
func _physics_process(delta: float) -> void:
    linear_velocity.y += -9.81 * delta
    global_position += linear_velocity * delta
    if global_position.y < floor_y:
        global_position.y = floor_y
        linear_velocity.y = abs(linear_velocity.y) * restitution
        # Correct velocity magnitude to maintain frequency
        var period: float = 1.0 / bounce_frequency
        var required_vy: float = 9.81 * period / 4.0  # from kinematic analysis
        linear_velocity.y = max(linear_velocity.y, required_vy)
```

Direct velocity correction is pedagogically motivated — it keeps the creature's frequency constant so the learner can focus on tuning the catalyst.

## Resonance Condition

Perfect resonance requires frequency match and phase alignment. The chamber tests both: frequency match is computed from the difference of the two frequencies, and phase alignment is computed from the instantaneous dot product of the two waveforms.

```gdscript
func resonance_score(catalyst_freq: float, creature_freq: float, time: float) -> float:
    var freq_diff: float = abs(catalyst_freq - creature_freq)
    var freq_score: float = 1.0 / (1.0 + freq_diff * freq_diff)
    var catalyst_wave: float = sin(catalyst_freq * time * TAU)
    var creature_wave: float = sin(creature_freq * time * TAU)
    var phase_score: float = (catalyst_wave * creature_wave + 1.0) / 2.0
    return freq_score * phase_score
```

## Beat Frequency

When frequencies differ slightly, the combined signal produces beats at the difference frequency. Two tones at 440 Hz and 442 Hz produce a 2 Hz beating envelope. The chamber's science screen visualises this directly: the product waveform oscillates at the sum frequency inside an envelope at the difference frequency.

## Befriending Persistence

Once befriended, the waterbomb follows the learner to subsequent chambers. The befriending state is saved in the global game state and recovered across sessions.

```gdscript
func save_befriending_state() -> void:
    var save := get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature("waterbomb")
```

## Science Screen Log

Every resonance event (frequency match sustained for more than one second) is logged to the science screen. The log accumulates across chamber visits and becomes part of the learner's historical record.
""",
}

for m, add in adds.items():
    p = Path(f'commons/maps/{m}/technical.md')
    t = p.read_text(encoding='utf-8')
    p.write_text(t.rstrip() + add, encoding='utf-8')

print('done', len(adds))
