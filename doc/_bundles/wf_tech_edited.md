<<<ADA_BUNDLE>>>
sequence: wavefunctions
file: technical.md
maps: 8
skipped_passing: 5
created: 2026-04-24T01:00:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: WaveFunctions_3D_Wave_Propagation>>>
# WaveFunctions 3D Wave Propagation — Technical

The map fills a volume with spherical waves emanating from multiple sources. Each source emits a wavefield with distance-dependent attenuation and phase delay. Where fields overlap, they superpose.

```gdscript
class_name WaveSource extends Node3D

@export var frequency: float = 2.0       # Hz
@export var amplitude: float = 1.0
@export var attenuation: float = 1.0     # falloff exponent (2.0 = inverse-square)
@export var speed: float = 5.0           # propagation speed (units/sec)

func amplitude_at(point: Vector3, time: float) -> float:
    var distance: float = global_position.distance_to(point)
    if distance < 0.01: return amplitude
    var delay: float = distance / speed
    var phase: float = 2.0 * PI * frequency * (time - delay)
    var falloff: float = 1.0 / pow(distance, attenuation)
    return amplitude * falloff * sin(phase)
```

## Superposition

Multiple sources' fields add. Constructive interference produces maxima; destructive interference produces nodes.

```gdscript
class_name WaveField extends Node3D

var sources: Array = []  # array of WaveSource

func field_at(point: Vector3, time: float) -> float:
    var total: float = 0.0
    for src in sources:
        total += src.amplitude_at(point, time)
    return total
```

## Visualising the Field

A lattice of small markers samples the field at discrete points. Each marker's brightness or scale reflects the local amplitude.

```gdscript
class_name MarkerLattice extends MultiMeshInstance3D

@export var resolution: int = 12
@export var extent: float = 10.0

var field: WaveField

func _ready() -> void:
    multimesh = MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.use_custom_data = true
    multimesh.instance_count = resolution * resolution * resolution
    # position each instance

func _process(_delta: float) -> void:
    var t: float = Time.get_ticks_msec() / 1000.0
    var idx := 0
    for ix in range(resolution):
        for iy in range(resolution):
            for iz in range(resolution):
                var p := instance_position(ix, iy, iz)
                var amplitude := field.field_at(p, t)
                multimesh.set_instance_custom_data(idx, Color(amplitude, amplitude, 1.0, 1.0))
                idx += 1
```

## Complexity

The field at a single point is O(S) for S sources. The full lattice update is O(R³ · S) per frame for resolution R. At R=12, S=4, that is 6912 source evaluations per frame, or about 410,000 per second at 60 fps — trivial on modern CPUs but expensive enough that the map caps resolution.

GPU evaluation via a compute shader reduces this dramatically: the same lattice can be updated at 128³ resolution in under a millisecond on modern hardware. The map uses CPU for pedagogical readability.

## Damping

Real wavefields lose energy over time and distance through viscous damping and scattering. A damping term in the propagation reduces amplitude as a function of time:

```gdscript
func damped_amplitude(amplitude: float, damping: float, time: float) -> float:
    return amplitude * exp(-damping * time)
```

The map uses minimal damping so the wavefields persist long enough to observe interference patterns.

## Interference Geometry

For two sources separated by distance d with the same frequency, maxima form hyperbolas where the path-length difference is an integer multiple of the wavelength. The hyperbolas' asymptotes make an angle with the line between sources that depends on the wavelength-to-separation ratio.

Within the sequence, 3D_Wave_Propagation is where oscillation acquires spatial extent. The subsequent maps treat waves as fields rather than as point oscillators.

<<<MAP: WaveFunctions_Effect_Sound>>>
# WaveFunctions Effect Sound — Technical

Four synthesiser stations drive oscillators at different waveforms and pipe their output to Godot's audio bus. An FFT station decomposes live input into frequency components.

```gdscript
class_name Synthesizer extends AudioStreamPlayer

@export var frequency: float = 440.0  # Hz
@export var waveform: String = "sine"

var stream_generator: AudioStreamGenerator
var playback: AudioStreamGeneratorPlayback

func _ready() -> void:
    stream_generator = AudioStreamGenerator.new()
    stream_generator.mix_rate = 44100.0
    stream_generator.buffer_length = 0.1
    stream = stream_generator
    play()
    playback = get_stream_playback()
    fill_buffer()

func fill_buffer() -> void:
    var sample_rate: float = stream_generator.mix_rate
    while playback.can_push_buffer(1):
        var phase_step: float = frequency / sample_rate * TAU
        var sample: float = waveform_sample(phase)
        playback.push_frame(Vector2(sample, sample))
        phase = fmod(phase + phase_step, TAU)

func waveform_sample(phase: float) -> float:
    match waveform:
        "sine": return sin(phase)
        "square": return 1.0 if sin(phase) > 0.0 else -1.0
        "sawtooth": return 2.0 * (phase / TAU) - 1.0
        "triangle":
            var t: float = phase / TAU
            return 2.0 * abs(2.0 * (t - floor(t + 0.5))) - 1.0
    return 0.0
```

## FFT

The FFT monitor decomposes the live audio signal into frequency bins. Godot's `AudioServer.get_bus_peak_volume_left_db` exposes bus levels but not full spectra; a custom FFT implementation reads the audio buffer and transforms it.

```gdscript
class_name FFTMonitor extends Node

@export var buffer_size: int = 1024

var samples: PackedFloat32Array

func compute_fft() -> PackedFloat32Array:
    # Cooley-Tukey radix-2 FFT
    var n: int = samples.size()
    if n <= 1: return samples
    # Bit-reverse permutation
    var real: PackedFloat32Array = samples.duplicate()
    var imag: PackedFloat32Array = []; imag.resize(n)
    bit_reverse_permute(real)
    # Butterfly stages
    var stage: int = 1
    while stage < n:
        var angle_step: float = -PI / stage
        for k in range(0, n, stage * 2):
            for j in range(stage):
                var angle: float = angle_step * j
                var wr: float = cos(angle)
                var wi: float = sin(angle)
                # butterfly
                var tr: float = wr * real[k + j + stage] - wi * imag[k + j + stage]
                var ti: float = wr * imag[k + j + stage] + wi * real[k + j + stage]
                real[k + j + stage] = real[k + j] - tr
                imag[k + j + stage] = imag[k + j] - ti
                real[k + j] += tr
                imag[k + j] += ti
        stage *= 2
    var spectrum: PackedFloat32Array = []
    for i in range(n / 2):
        spectrum.append(sqrt(real[i] * real[i] + imag[i] * imag[i]))
    return spectrum
```

## Complexity

The FFT is O(N log N) for N samples. At N=1024, that is roughly 10,000 operations per transform; at 30 Hz update rate the total cost is 300,000 operations per second, well within budget.

Per-sample synthesis is O(1). The per-frame audio buffer fill is O(buffer_size); at 44100 Hz mix rate and 0.1s buffer, that is 4410 samples per 100 ms, running continuously.

## Latency

Every audio stage adds latency. Buffer size directly affects latency: a 100 ms buffer adds 100 ms of delay between a key press and the first sample of audible sound. Interactive audio applications minimise buffer size at the cost of higher CPU usage and occasional underruns.

Within the sequence, Effect_Sound is the pivot from visible waves to audible ones. Bernini will next treat wave geometry as sculptural form.

<<<MAP: Wavefunctions_Bernini>>>
# Wavefunctions Bernini — Technical

Baroque columns are generated procedurally by displacing cylinder vertices according to helical sine functions plus noise layers.

```gdscript
class_name BerniniColumn extends MeshInstance3D

@export var height: float = 5.0
@export var base_radius: float = 0.5
@export var twist_rate: float = 2.0          # revolutions per column
@export var swirl_amplitude: float = 0.2
@export var swirl_frequency: float = 6.0
@export var noise_scale: float = 0.05

func generate_mesh() -> ArrayMesh:
    var array_mesh := ArrayMesh.new()
    var surface_tool := SurfaceTool.new()
    surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
    var rings: int = 64
    var sides: int = 24
    var noise := FastNoiseLite.new()
    for ring in range(rings + 1):
        var t: float = float(ring) / rings
        var y: float = t * height
        var angle_offset: float = twist_rate * TAU * t
        for side in range(sides + 1):
            var angle: float = float(side) / sides * TAU + angle_offset
            var radial_swirl: float = swirl_amplitude * sin(swirl_frequency * y)
            var current_radius: float = base_radius + radial_swirl
            var noise_offset: float = noise.get_noise_2d(angle, y) * noise_scale
            current_radius += noise_offset
            var x: float = cos(angle) * current_radius
            var z: float = sin(angle) * current_radius
            surface_tool.add_vertex(Vector3(x, y, z))
    # Generate triangle indices ...
    surface_tool.commit(array_mesh)
    return array_mesh
```

## Parameter Interactions

The twist_rate parameter produces the solomonic spiral — the defining feature of Bernini's Baldachin columns. A twist_rate of 2.0 produces two full revolutions from base to top; 1.0 produces a single twist; 0.5 produces a half-twist only.

The swirl_amplitude and swirl_frequency produce the secondary undulation along the column's length. Setting swirl_amplitude to zero produces a straight twisted column; higher values produce more organic sculpted forms.

## Mesh Complexity

A column with 64 rings and 24 sides has 1560 vertices and 3072 triangles. Ten columns fill the map; total geometry is about 15,000 vertices. Godot renders this comfortably at 60 fps.

## Normal Smoothing

Procedurally generated meshes need smoothed normals for consistent shading. Surface tool's `generate_normals` computes per-vertex normals by averaging adjacent face normals, producing smooth shading without visible facets.

```gdscript
surface_tool.generate_normals()
```

## LOD

Distant columns can use reduced mesh resolution. Godot 4's built-in MeshInstance3D.lod_bias controls automatic LOD switching. The map uses three LOD levels: full detail at close range, half detail at medium, quarter detail at long distance.

Within the sequence, Bernini applies wave mathematics to sculptural form. Cage will next withdraw oscillation to ask what remains.

<<<MAP: WaveFunctions_John_Cage>>>
# WaveFunctions John Cage — Technical

The map stages Cage's 4'33" via a controlled audio environment that exposes the ambient noise floor. A toggle switches between "play" mode (a synthesized tone) and "pause" mode (silence from the synth but the room's ambience remains audible).

```gdscript
class_name CageStation extends Node3D

@export var noise_floor_meter: RangeControl
@export var countdown_timer: Timer

var is_playing: bool = false
var tone_player: AudioStreamPlayer

func _ready() -> void:
    countdown_timer.wait_time = 4 * 60 + 33  # 4 minutes 33 seconds
    countdown_timer.timeout.connect(_on_piece_end)

func start_piece() -> void:
    countdown_timer.start()
    begin_noise_floor_recording()

func toggle_tone() -> void:
    is_playing = not is_playing
    if is_playing:
        tone_player.play()
    else:
        tone_player.stop()

func _process(_delta: float) -> void:
    var floor_level: float = measure_ambient_noise()
    noise_floor_meter.value = floor_level
```

## Noise Floor Measurement

The ambient noise floor is measured from the input bus — microphone input, if available, or the system's reported audio baseline otherwise.

```gdscript
func measure_ambient_noise() -> float:
    # dB below reference (typically 0 dBFS)
    var db_left: float = AudioServer.get_bus_peak_volume_left_db(input_bus_idx, 0)
    var db_right: float = AudioServer.get_bus_peak_volume_right_db(input_bus_idx, 0)
    return max(db_left, db_right)
```

In the absence of microphone input, the map uses a simulated noise floor that varies slowly according to a noise function, producing visible variation on the meter.

## Aleatoric Devices

Three chance devices drive aleatoric composition: dice for pitch, coin for rhythm, spinner for duration.

```gdscript
class_name AleatoricDevice extends Node3D

@export var parameter_name: String  # "pitch", "rhythm", "duration"

func roll() -> float:
    match parameter_name:
        "pitch":
            var dice := randi() % 6 + 1
            return dice * 100.0  # Hz, simplified
        "rhythm":
            return randf() < 0.5  # coin toss, returns 0 or 1
        "duration":
            return randf_range(0.1, 2.0)
    return 0.0
```

The rolled values drive a minimal composition engine that plays short tones at the chosen pitches, rhythms, and durations.

## Attention vs Signal

The map's argument about silence operates through the meter rather than through the audio. Cage's piece claims that silence is a reassignment of attention rather than an absence of sound, and the noise-floor meter makes this claim mechanically: the meter never reads zero, and the learner can see that the "silence" contains continuous signal.

## Complexity

Audio measurement is O(1) per frame. Aleatoric devices are O(1) per roll. The map's computational cost is negligible; the entire station runs within a fraction of a millisecond per frame.

Within the sequence, Cage is the philosophical counter-weight. AirMusic will next reintroduce sound as emergent rather than composed.

<<<MAP: WaveFunctions_AirMusic>>>
# WaveFunctions AirMusic — Technical

Three audio stations produce loops at slightly different intervals, and their phases drift relative to one another over time. A floor of position-triggered notes lets the learner add to the composition by walking across tiles.

```gdscript
class_name AmbientLoop extends AudioStreamPlayer

@export var pattern: Array = [440.0, 523.0, 659.0, 784.0]  # Hz
@export var beat_interval: float = 0.75  # seconds per note
@export var voice: String = "fm_piano"

var beat_index: int = 0
var time_since_beat: float = 0.0

func _process(delta: float) -> void:
    time_since_beat += delta
    if time_since_beat >= beat_interval:
        time_since_beat -= beat_interval
        play_note(pattern[beat_index])
        beat_index = (beat_index + 1) % pattern.size()

func play_note(frequency: float) -> void:
    # Trigger an FM-synthesis voice at the given frequency
    pitch_scale = frequency / 440.0
    play()
```

## Phasing

Two loops with nearly-identical intervals phase against each other over many cycles. A loop at 0.75 sec and a second at 0.77 sec take about (0.75 * 0.77) / (0.77 - 0.75) = 28.9 seconds to return to alignment — about 38 beats of the faster loop.

The effect is most musical when the intervals are close but not identical; Steve Reich's *Piano Phase* uses this technique deliberately.

## Position-Triggered Notes

A grid of floor tiles triggers notes when the learner stands on them. Each tile has an associated pitch, and the ensemble of tiles forms a scale or chord progression.

```gdscript
class_name PitchTile extends Area3D

@export var pitch: float = 440.0  # Hz
@export var voice: String = "sine"

var note_player: AudioStreamPlayer

func _on_body_entered(_body: Node) -> void:
    note_player.pitch_scale = pitch / 440.0
    note_player.play()

func _ready() -> void:
    note_player = AudioStreamPlayer.new()
    note_player.stream = preload("res://audio/reference_note.ogg")
    add_child(note_player)
```

## FM Synthesis

FM synthesis drives one oscillator (the carrier) with the output of another (the modulator), producing complex spectra from simple waveforms.

```gdscript
func fm_synthesis(carrier_freq: float, modulator_freq: float, mod_index: float, time: float) -> float:
    var modulator: float = mod_index * sin(TAU * modulator_freq * time)
    return sin(TAU * carrier_freq * time + modulator)
```

The modulation index controls the spectral richness. At index 0, the output is pure sine at the carrier frequency. At higher indices, the output contains sidebands at the carrier ± integer multiples of the modulator frequency.

## Complexity

Each loop is O(1) per frame. The pitch tiles are passive and only cost CPU when triggered. FM synthesis is O(1) per sample; at 44100 Hz mix rate, that is one multiply-add and two sines per sample, well within budget.

## Spatial Audio

Godot's AudioStreamPlayer3D renders sound with distance attenuation and Doppler shift, making the map's loops spatially located. Standing close to a loop makes it louder; walking past a loop produces a slight pitch shift due to Doppler.

Within the sequence, AirMusic restores sound after Cage's withdrawal but changes its mode. Sound is now emergent rather than composed.

<<<MAP: Wavefunctions_Sky_Stairs>>>
# Wavefunctions Sky Stairs — Technical

The map generates three parallel helical staircases whose step heights follow sin, cos, and a higher-frequency harmonic.

```gdscript
class_name SineStaircase extends Node3D

@export var function_type: String = "sin"  # "sin", "cos", "harmonic"
@export var total_height: float = 30.0
@export var radius: float = 4.0
@export var angular_rate: float = 0.5  # revolutions per unit height
@export var step_count: int = 80

func build() -> void:
    var step_scene: PackedScene = preload("res://commons/interactables/helix_step.tscn")
    for i in range(step_count):
        var height_fraction: float = float(i) / step_count
        var y: float = height_fraction * total_height
        var angle: float = height_fraction * angular_rate * TAU
        var step_height: float = step_height_for(function_type, height_fraction)
        var step := step_scene.instantiate()
        step.position = Vector3(
            cos(angle) * radius,
            y + step_height,
            sin(angle) * radius
        )
        add_child(step)

func step_height_for(type: String, t: float) -> float:
    var amplitude: float = 0.3
    match type:
        "sin": return amplitude * sin(t * TAU * 3)
        "cos": return amplitude * cos(t * TAU * 3)
        "harmonic": return amplitude * sin(t * TAU * 6) * 0.5
    return 0.0
```

## Phase Relationship

Sin and cos staircases are offset by 90° of phase. At a given angle around the helix, the sin staircase and cos staircase have step heights that are 90° out of phase: when sin is at its peak, cos is at zero, and vice versa.

```gdscript
func phase_offset_at(angle: float) -> float:
    var sin_height: float = sin(angle)
    var cos_height: float = cos(angle)
    return sin_height - cos_height  # visible elevation difference
```

## Floating Cube Fields

Fields of small cubes drift at different altitudes around the tower. Their density samples the wave equation at that height.

```gdscript
class_name FloatingField extends Node3D

@export var altitude_range: Vector2 = Vector2(5, 25)
@export var cube_count: int = 200

func spawn_cubes() -> void:
    for i in range(cube_count):
        var altitude: float = randf_range(altitude_range.x, altitude_range.y)
        var density: float = abs(sin(altitude)) * 0.5 + 0.5
        if randf() > density: continue
        var p := random_position_at_altitude(altitude)
        spawn_cube(p)
```

## Height Reference Panel

A reference panel at the landing displays the learner's current altitude as a value of sin(angle), where angle is the distance travelled around the helix.

```gdscript
func update_altitude_readout() -> void:
    var p := learner.global_position
    var angle: float = atan2(p.z, p.x)
    var altitude: float = p.y
    var wave_value: float = sin(altitude / total_height * TAU * 3)
    readout_label.text = "Altitude: %.1f · Wave: %.2f" % [altitude, wave_value]
```

## Complexity

Each staircase is O(step_count) at build time. Total geometry across three staircases is about 240 steps. The floating cube fields are O(cube_count); the map uses 200 cubes per field, rendered via MultiMeshInstance3D for efficiency.

Within the sequence, Sky_Stairs returns oscillation to embodied experience. TrigWalkingPath will next put sin and cos walks next to each other.

<<<MAP: WaveFunctions_TrigWalkingPath>>>
# WaveFunctions TrigWalkingPath — Technical

Two parallel walkways generate themselves a few steps ahead of the learner. The left lane follows sin; the right lane follows cos.

```gdscript
class_name TrigPath extends Node3D

@export var function_type: String = "sin"
@export var frequency: float = 0.2   # cycles per unit distance
@export var amplitude: float = 0.5   # vertical amplitude
@export var step_spacing: float = 0.4
@export var lookahead: int = 10

var steps: Array = []  # spawned step nodes

func update_path(walker_position: Vector3) -> void:
    var walker_step_index: int = int(walker_position.x / step_spacing)
    while steps.size() < walker_step_index + lookahead:
        spawn_step_at_index(steps.size())
    # Clean up old steps behind walker
    while not steps.is_empty() and steps[0].position.x < walker_position.x - step_spacing * 3:
        steps[0].queue_free()
        steps.pop_front()

func spawn_step_at_index(index: int) -> void:
    var x: float = index * step_spacing
    var y: float = height_for(x)
    var step := STEP_SCENE.instantiate()
    step.position = Vector3(x, y, lane_z_offset())
    add_child(step)
    steps.append(step)

func height_for(x: float) -> float:
    var angle: float = frequency * x * TAU
    match function_type:
        "sin": return amplitude * sin(angle)
        "cos": return amplitude * cos(angle)
    return 0.0
```

## Cross-Bridge

The cross-bridge at the midpoint connects the two lanes. It is a single step whose height is the average of sin and cos at its position — a 45° phase midpoint.

```gdscript
class_name CrossBridge extends StaticBody3D

@export var midpoint_x: float = 20.0
@export var frequency: float = 0.2
@export var amplitude: float = 0.5

func _ready() -> void:
    var sin_y := amplitude * sin(frequency * midpoint_x * TAU)
    var cos_y := amplitude * cos(frequency * midpoint_x * TAU)
    var avg_y := (sin_y + cos_y) / 2.0
    position.y = avg_y
```

## Reference Panel

The panel shows both functions on a shared chart, with a marker indicating the walker's current horizontal position.

```gdscript
class_name TrigChart extends Control

func draw_chart(walker_x: float, frequency: float, amplitude: float) -> void:
    var w: float = size.x
    var h: float = size.y
    for px in range(int(w)):
        var world_x: float = (px / w) * total_range
        var sin_y: float = amplitude * sin(frequency * world_x * TAU)
        var cos_y: float = amplitude * cos(frequency * world_x * TAU)
        draw_line(Vector2(px, h / 2 - sin_y * h / 4), Vector2(px + 1, h / 2 - sin_y * h / 4), Color.BLUE)
        draw_line(Vector2(px, h / 2 - cos_y * h / 4), Vector2(px + 1, h / 2 - cos_y * h / 4), Color.RED)
    var marker_px: float = (walker_x / total_range) * w
    draw_line(Vector2(marker_px, 0), Vector2(marker_px, h), Color.WHITE, 2)
```

## Complexity

Path generation is O(lookahead) per frame. Cleanup removes steps behind the walker to keep memory bounded. The reference chart redraws once per frame at O(w) where w is the chart width in pixels.

Within the sequence, TrigWalkingPath is the penultimate map. Synthesis Lab will next decompose everything into Fourier components.

<<<MAP: Chamber_Waves>>>
# Chamber Waves — Technical

The chamber contains a helix_catalyst that fires spiralling projectiles at a chosen frequency, and a waterbomb creature that bounces at its own frequency. The science screen plots both frequencies and draws their product.

```gdscript
class_name HelixCatalyst extends Node3D

@export var frequency: float = 2.0   # Hz
@export var helix_radius: float = 0.3
@export var projectile_speed: float = 8.0

func fire(direction: Vector3) -> void:
    var projectile := HELIX_PROJECTILE_SCENE.instantiate()
    projectile.global_position = global_position
    projectile.direction = direction
    projectile.frequency = frequency
    get_tree().root.add_child(projectile)

class_name HelixProjectile extends Node3D

var direction: Vector3
var frequency: float
var age: float = 0.0
var speed: float = 8.0

func _process(delta: float) -> void:
    age += delta
    var forward_distance: float = speed * age
    var helix_offset: Vector3 = Vector3(
        cos(frequency * age * TAU) * 0.3,
        sin(frequency * age * TAU) * 0.3,
        0
    )
    global_position = start_position + direction * forward_distance + helix_offset
```

## Waterbomb Creature

The waterbomb bounces around the chamber at a fixed frequency; its motion follows a damped harmonic oscillator.

```gdscript
class_name WaterbombCreature extends RigidBody3D

@export var bounce_frequency: float = 2.0  # Hz
@export var bounce_amplitude: float = 2.0

var phase: float = 0.0

func _physics_process(delta: float) -> void:
    phase += delta * bounce_frequency * TAU
    # Vertical oscillation driven directly
    var target_y: float = rest_position.y + bounce_amplitude * abs(sin(phase))
    var displacement: float = target_y - global_position.y
    linear_velocity.y += displacement * 5.0 * delta
```

## Resonance Detection

The science screen compares the catalyst's frequency with the waterbomb's, computing their product as a live waveform.

```gdscript
class_name ResonanceScreen extends Node3D

func update_display(catalyst_freq: float, creature_freq: float) -> void:
    var t: float = Time.get_ticks_msec() / 1000.0
    var catalyst_wave: float = sin(catalyst_freq * t * TAU)
    var creature_wave: float = sin(creature_freq * t * TAU)
    var product: float = catalyst_wave * creature_wave
    var frequency_diff: float = abs(catalyst_freq - creature_freq)
    var alignment: float = 1.0 / (1.0 + frequency_diff)
    update_plot(catalyst_wave, creature_wave, product)
    update_alignment_indicator(alignment)
```

When catalyst_freq matches creature_freq, the product becomes sin²(θ) — always positive, pulsing at twice the base frequency. When they are far apart, the product produces a beating pattern.

## Befriending

Sustained resonance over several seconds causes the waterbomb to transition to a befriended state.

```gdscript
var sustained_resonance: float = 0.0
@export var befriend_threshold: float = 3.0  # seconds

func _process(delta: float) -> void:
    if compute_alignment() > 0.9:
        sustained_resonance += delta
    else:
        sustained_resonance = max(0.0, sustained_resonance - delta)
    if sustained_resonance > befriend_threshold:
        befriend()
```

## Complexity

Projectile updates are O(active projectiles) per frame. The science screen's FFT-like analysis is O(1) with precomputed wave values. The chamber runs well within budget at any reasonable projectile count.

Within the sequence, Chamber_Waves closes Wavefunctions with resonance as mutual attention. The chamber hands the learner back to the Lab with the waveform catalyst in their kit.
