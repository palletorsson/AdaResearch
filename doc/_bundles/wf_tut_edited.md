<<<ADA_BUNDLE>>>
sequence: wavefunctions
file: tutorial.md
maps: 13
<<</ADA_BUNDLE>>>

<<<MAP: WaveFunctions_Intro>>>
# Wavefunctions Intro

A room lined with oscilloscopes. Four cubes teach the grammar. Start where every periodic motion starts.

Declare the waveform kinds.

```gdscript
enum WaveKind { SINE, SQUARE, SAWTOOTH, TRIANGLE }

@export var kind: WaveKind = WaveKind.SINE
@export var amplitude: float = 1.0
@export var frequency: float = 1.0
```

Four kinds, three parameters. The enum is the alphabet. Amplitude and frequency are the first two letters.

Sample a sine wave.

```gdscript
func sample_sine(t: float) -> float:
    return amplitude * sin(TAU * frequency * t)
```

Time goes in, displacement comes out. The function is the entire contract. Everything else is visualization.

Render the trace to an oscilloscope line.

```gdscript
func render_trace(line: Line2D, width: float) -> void:
    line.clear_points()
    for i in 128:
        var x := float(i) / 128.0 * width
        var t := float(i) / 128.0
        line.add_point(Vector2(x, -sample(t) * 40.0))
```

Green pixels sweep left to right. The trace is the waveform made visible. Oscillation becomes legible as a shape.

Spawn the four teaching cubes.

```gdscript
func build_cubes(parent: Node3D) -> void:
    for i in 4:
        var cube := preload("res://commons/artifacts/wavefunctions/teach_cube.tscn").instantiate()
        cube.kind = i
        cube.position = Vector3(i * 1.5 - 2.25, 1.0, 0.0)
        parent.add_child(cube)
```

Four cubes in a row. Static, rotating, oscillating, transforming. The progression runs left to right: rest, motion, return, change.

Animate the oscillating cube.

```gdscript
func animate_oscillating(cube: Node3D, t: float) -> void:
    cube.position.y = 1.0 + 0.5 * sin(TAU * t)
```

The cube rises and falls between 0.5 and 1.5. The learner sees the sine trace on the scope and the cube in the air as the same curve.

Switch kinds by button.

```gdscript
func _on_kind_button_pressed(k: int) -> void:
    current_kind = k
    sample_func = _sampler_for(k)
    trace_line.clear_points()
```

Each press selects a waveform. The sampler changes; the scope redraws. The button cycles through the alphabet.

Expose the parameter sliders.

```gdscript
func _on_amplitude_slider(v: float) -> void:
    amplitude = lerp(0.1, 2.0, v)

func _on_frequency_slider(v: float) -> void:
    frequency = lerp(0.2, 4.0, v)
```

Two sliders control the trace. Turning amplitude taller or frequency faster is done by hand. The math is the room.

You have met the grammar. The next map, Pendulum, grounds sine in gravity.
<<</MAP>>>

<<<MAP: WaveFunctions_Pendulum>>>
# Pendulum

Gravity creates rhythm. Build a weight on a string and watch sine become physical.

Declare the pendulum state.

```gdscript
class_name Pendulum
extends Node3D

@export var length: float = 2.0
@export var gravity: float = 9.81
@export var angle: float = 0.3
var angular_velocity: float = 0.0
```

Length, gravity, angle, angular velocity. Four numbers describe the entire swing.

Integrate the small-angle equation.

```gdscript
func step(dt: float) -> void:
    var accel: float = -(gravity / length) * sin(angle)
    angular_velocity += accel * dt
    angle += angular_velocity * dt
```

Newton's second law applied to arc length. For small angles, `sin(angle)` approaches angle and the motion becomes simple harmonic.

Position the bob.

```gdscript
func update_bob(bob: Node3D, pivot: Vector3) -> void:
    bob.position = pivot + Vector3(sin(angle) * length, -cos(angle) * length, 0.0)
```

The bob hangs below the pivot. At zero angle, it is directly under. The shape of the swing is a circular arc.

Display the period.

```gdscript
func period() -> float:
    return TAU * sqrt(length / gravity)
```

The formula reads as a signature. Longer strings swing slower; stronger gravity swings faster. Nothing depends on mass.

Trace the angle against time.

```gdscript
func trace_angle(line: Line2D, time: float) -> void:
    line.add_point(Vector2(time * 60.0, -angle * 80.0))
    if line.get_point_count() > 240:
        line.remove_point(0)
```

The trace is a scrolling sine wave. The pendulum in the air and the green line on the scope show the same motion.

Add the Foucault twist.

```gdscript
func apply_foucault(dt: float, latitude_deg: float) -> void:
    var omega: float = 0.000072921
    var angle_of_plane: float = omega * sin(deg_to_rad(latitude_deg)) * dt
    pivot_yaw += angle_of_plane
```

At non-equator latitudes, Earth's rotation twists the swing plane. The room rotates slowly around a stationary pendulum. Geography becomes a parameter.

Introduce the double pendulum.

```gdscript
func step_double(dt: float, b: Pendulum) -> void:
    b.angular_velocity += coupled_accel(self, b) * dt
    b.angle += b.angular_velocity * dt
```

Two pendulums coupled at a pivot. Energy flows between them. Chaos emerges because the coupled equations have no closed-form solution.

You have met sine as gravity's handwriting. The next map, Sine Space, turns the wave spatial.
<<</MAP>>>

<<<MAP: WaveFunctions_Sine_Space>>>
# Sine Space

Walk through sin(t) frozen in three dimensions. Build a corridor where the wall is the waveform.

Declare the wall.

```gdscript
class_name SineWall
extends Node3D

@export var amplitude: float = 1.0
@export var frequency: float = 0.5
@export var length: float = 20.0
```

One wall, three parameters. Amplitude is wall height; frequency is crest count along the length.

Tessellate the wall.

```gdscript
func build_wall() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for i in 120:
        var x := float(i) / 120.0 * length
        var y := amplitude * sin(TAU * frequency * x)
        st.add_vertex(Vector3(x, y, 0.0))
        st.add_vertex(Vector3(x, 0.0, 0.0))
    wall_mesh.mesh = st.commit()
```

Vertices step along the length, alternating top and bottom of the wall. The resulting ribbon rises and falls with sine.

Mirror the wall across the corridor.

```gdscript
func build_mirror() -> void:
    mirror_wall.amplitude = amplitude
    mirror_wall.frequency = frequency
    mirror_wall.phase = PI
```

A second wall with phase-shifted sine creates a pinched corridor. The learner walks where the two curves meet.

Sample corridor width at any point.

```gdscript
func corridor_width(x: float) -> float:
    var a := amplitude * sin(TAU * frequency * x)
    var b := amplitude * sin(TAU * frequency * x + PI)
    return abs(a - b)
```

Width varies with position. At certain phases the corridor is wide enough to run through; at others the learner must turn sideways.

Light the peaks warmer.

```gdscript
func tint_height(index: int, height: float) -> void:
    var t: float = clamp((height + amplitude) / (2.0 * amplitude), 0.0, 1.0)
    wall_material.set_instance_shader_parameter("height_tint_%d" % index, Color(1.0, 0.9 - t * 0.4, 0.4))
```

Peaks glow warmer than troughs. The learner sees the waveform as weather.

Spawn markers every wavelength.

```gdscript
func place_markers() -> void:
    var wavelength := 1.0 / frequency
    for i in int(length / wavelength):
        var marker := preload("res://commons/artifacts/wavefunctions/wave_marker.tscn").instantiate()
        marker.position = Vector3(i * wavelength, 0, 0)
        add_child(marker)
```

Markers repeat at the wavelength. Counting markers tells the learner the frequency without reading a panel.

Expose amplitude as a physical lever.

```gdscript
func _on_amplitude_lever_pulled(v: float) -> void:
    amplitude = lerp(0.3, 2.5, v)
    rebuild_wall()
```

Pulling a lever at the corridor entrance rebuilds the walls. The learner changes the weather before walking through it.

You have walked inside a sine function. The next map, Unit Circle, reveals where the wave comes from.
<<</MAP>>>

<<<MAP: WaveFunctions_Unit_Circle>>>
# Unit Circle

A point travels a circle; its shadow traces a wave. Build the amphitheater where rotation becomes oscillation.

Declare the rotating point.

```gdscript
class_name CircleRunner
extends Node3D

@export var radius: float = 1.0
@export var omega: float = 1.0
var angle: float = 0.0
```

Radius and angular velocity. The runner travels the unit circle at rate omega.

Step the angle.

```gdscript
func _process(dt: float) -> void:
    angle += omega * dt
    position = Vector3(cos(angle) * radius, sin(angle) * radius, 0.0)
```

Position follows cosine and sine of angle. The runner traces a circle in the xy plane.

Project the shadow.

```gdscript
func project_shadow(screen_x: float, time: float) -> Vector3:
    return Vector3(screen_x, sin(omega * time) * radius, 0.0)
```

The shadow is sine against time. It strips away the x-component and leaves the sine trace scrolling along a screen.

Draw the projection line.

```gdscript
func draw_projection(line: ImmediateMesh, runner_pos: Vector3, shadow_pos: Vector3) -> void:
    line.clear_surfaces()
    line.surface_begin(Mesh.PRIMITIVE_LINES)
    line.surface_add_vertex(runner_pos)
    line.surface_add_vertex(shadow_pos)
    line.surface_end()
```

A faint line connects the runner to its shadow. The line lengthens and shortens; the learner sees where the sine comes from.

Build the oscillating bridge.

```gdscript
func update_bridge(plank: Node3D, offset: float) -> void:
    plank.position.y = sin(omega * Time.get_ticks_msec() / 1000.0 + offset) * 0.3
```

Planks rise and fall with staggered phase. The bridge becomes a travelling wave the learner walks across.

Label the angle readout.

```gdscript
func update_angle_label(label: Label3D) -> void:
    label.text = "θ = %.2f rad\nsin(θ) = %+0.2f\ncos(θ) = %+0.2f" % [angle, sin(angle), cos(angle)]
```

Three numbers update each frame. The label makes the mapping between angle and projection explicit.

Offer a second runner for cosine.

```gdscript
func spawn_cosine_runner() -> void:
    cos_runner = preload("res://commons/artifacts/wavefunctions/runner.tscn").instantiate()
    cos_runner.phase_offset = PI / 2.0
    add_child(cos_runner)
```

A second runner lags by 90 degrees. Its shadow traces cosine. Two shadows on one screen show the fundamental phase relationship.

You have seen the origin of trigonometry. The next map, 3D Wave Propagation, releases the wave to travel.
<<</MAP>>>

<<<MAP: WaveFunctions_3D_Wave_Propagation>>>
# 3D Wave Propagation

Waves spread from a source. Build ripples that attenuate with distance and interfere where they meet.

Declare the source.

```gdscript
class_name WaveSource
extends Node3D

@export var frequency: float = 1.0
@export var amplitude: float = 1.0
@export var speed: float = 3.0
```

Source holds the three numbers every wave needs. Speed is how fast a crest travels outward.

Sample the wave field at a point.

```gdscript
func sample_at(p: Vector3, t: float) -> float:
    var d := p.distance_to(global_position)
    var falloff: float = 1.0 / max(d, 0.1)
    return amplitude * falloff * sin(TAU * frequency * (t - d / speed))
```

Distance becomes delay. Amplitude falls as one over distance. The sample returns displacement at that point and time.

Render the field on a mesh.

```gdscript
func update_field(mesh: ArrayMesh, t: float) -> void:
    for i in vertices.size():
        var h := 0.0
        for source in sources:
            h += source.sample_at(vertices[i], t)
        heights[i] = h
    mesh.surface_update_vertex_region(0, 0, heights.to_byte_array())
```

Each vertex sums contributions from every source. The mesh updates every frame. Interference emerges from the sum.

Place two sources for a double slit.

```gdscript
func build_double_source() -> void:
    var a := preload("res://commons/artifacts/wavefunctions/source.tscn").instantiate()
    var b := preload("res://commons/artifacts/wavefunctions/source.tscn").instantiate()
    a.position = Vector3(-1.0, 0, 0)
    b.position = Vector3(1.0, 0, 0)
    sources = [a, b]
```

Two sources, one metre apart. The interference pattern appears as bands. The bands move toward either source as amplitudes change.

Colour peaks and troughs.

```gdscript
func tint_by_height(material: ShaderMaterial) -> void:
    material.set_shader_parameter("peak_color", Color(0.9, 0.7, 0.3))
    material.set_shader_parameter("trough_color", Color(0.2, 0.4, 0.7))
```

Peaks warm, troughs cool. The field becomes weather across a reflective surface.

Let the learner drop a pebble.

```gdscript
func _on_pebble_dropped(pos: Vector3) -> void:
    var s := preload("res://commons/artifacts/wavefunctions/source.tscn").instantiate()
    s.position = pos
    s.amplitude = 1.5
    s.lifetime = 3.0
    sources.append(s)
```

A dropped pebble spawns a short-lived source. Ripples expand outward. The learner makes weather.

Attenuate lifetime.

```gdscript
func _process(dt: float) -> void:
    for s in sources:
        s.lifetime -= dt
    sources = sources.filter(func(s): return s.lifetime > 0.0)
```

Sources fade out. The field returns to stillness unless the learner keeps dropping pebbles.

You have released the wave to travel. The next map, Effect Sound, turns the wave audible.
<<</MAP>>>

<<<MAP: WaveFunctions_Effect_Sound>>>
# Effect Sound

Waves become bleeps. Build the audio lab where sine drives a speaker and FFT reveals the harmonics.

Declare the tone player.

```gdscript
class_name TonePlayer
extends AudioStreamPlayer

@export var frequency: float = 440.0
@export var kind: int = 0
```

The player extends Godot's AudioStreamPlayer. Frequency defaults to A4. Kind selects waveform.

Generate a sine buffer.

```gdscript
func generate_sine_buffer(sample_rate: int, seconds: float) -> PackedFloat32Array:
    var out := PackedFloat32Array()
    var n: int = int(sample_rate * seconds)
    for i in n:
        var t := float(i) / float(sample_rate)
        out.append(sin(TAU * frequency * t))
    return out
```

A sample buffer at the given sample rate. Each sample is the sine displacement at that moment. Godot plays the buffer when fed.

Push the buffer to the playback stream.

```gdscript
func push_buffer(playback: AudioStreamGeneratorPlayback, buffer: PackedFloat32Array) -> void:
    for sample in buffer:
        playback.push_frame(Vector2(sample, sample))
```

Stereo frame with the same sample in left and right. The speaker reproduces the sine as pressure waves.

Shape the waveform.

```gdscript
func shape(sample: float, k: int) -> float:
    match k:
        0: return sample
        1: return sign(sample)
        2: return 2.0 * (fmod(sample + 1.0, 2.0) - 1.0)
        3: return abs(sample) * 2.0 - 1.0
    return sample
```

Four waveform shapes from a single sine source. Square is sign. Sawtooth is fmod. Triangle is absolute value. Chiptune from one function.

Compute the FFT.

```gdscript
func fft(samples: PackedFloat32Array) -> PackedVector2Array:
    var bins := PackedVector2Array()
    for k in samples.size() / 2:
        var re := 0.0
        var im := 0.0
        for n in samples.size():
            var angle := -TAU * k * n / samples.size()
            re += samples[n] * cos(angle)
            im += samples[n] * sin(angle)
        bins.append(Vector2(re, im))
    return bins
```

Direct DFT, not FFT, but fast enough for teaching. Each bin holds a real and imaginary part. Magnitude is sqrt of the sum of squares.

Render the spectrum on a panel.

```gdscript
func draw_spectrum(line: Line2D, bins: PackedVector2Array) -> void:
    line.clear_points()
    for i in bins.size():
        var mag := bins[i].length()
        line.add_point(Vector2(i * 2.0, -mag * 20.0))
```

Height per bin shows how much of that frequency is present. The spectrum is a fingerprint of the waveform.

Expose a knob for frequency.

```gdscript
func _on_frequency_knob(v: float) -> void:
    frequency = lerp(110.0, 1760.0, v)
    reload_buffer()
```

Two octaves from A2 to A6. The knob sweeps the audible range in that band. Pitch follows the hand.

You have turned waves into sound. The next map, Bernini, wraps oscillation around columns.
<<</MAP>>>

<<<MAP: Wavefunctions_Bernini>>>
# Bernini

Solomonic columns are sines wrapped around cylinders. Build the vertex displacement that turns stone into frozen motion.

Declare the column generator.

```gdscript
class_name SolomonicColumn
extends MeshInstance3D

@export var height: float = 4.0
@export var base_radius: float = 0.3
@export var twist_amount: float = 0.4
@export var twist_frequency: float = 3.0
```

Height, base radius, twist amount, twist frequency. The solomonic spiral is two sines along the vertical axis.

Build the ring loop.

```gdscript
func ring_at(y: float) -> PackedVector3Array:
    var ring := PackedVector3Array()
    var twist_x: float = twist_amount * sin(TAU * twist_frequency * y / height)
    var twist_z: float = twist_amount * cos(TAU * twist_frequency * y / height)
    for i in 24:
        var angle := TAU * i / 24.0
        var x := base_radius * cos(angle) + twist_x
        var z := base_radius * sin(angle) + twist_z
        ring.append(Vector3(x, y, z))
    return ring
```

Each ring is 24 vertices around the central axis, with its centre displaced by a small sine. The stack of displaced rings produces the helix.

Stack the rings into a mesh.

```gdscript
func build_mesh() -> void:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
    for i in 40:
        var y := float(i) / 40.0 * height
        for v in ring_at(y):
            st.add_vertex(v)
    mesh = st.commit()
```

Forty rings yield a smooth column. Each ring is the same size; the centres spiral. Baroque geometry with twenty-odd lines.

Add vertex colours for depth.

```gdscript
func colour_vertex(st: SurfaceTool, pos: Vector3) -> void:
    var t: float = clamp(pos.y / height, 0.0, 1.0)
    st.set_color(Color(0.8 - t * 0.2, 0.7 - t * 0.1, 0.6))
```

The column darkens slightly at the top. Ambient light reads as contour. Bernini's drama becomes geometric tinting.

Layer noise on the surface.

```gdscript
func perturb(vertex: Vector3, noise: FastNoiseLite) -> Vector3:
    var offset: float = noise.get_noise_3dv(vertex * 4.0) * 0.02
    return vertex + vertex.normalized() * offset
```

Tiny perturbations break the mathematical smoothness. The column reads as stone, not plastic.

Animate the twist over time.

```gdscript
func animate_twist(t: float) -> void:
    twist_amount = 0.3 + 0.1 * sin(t * 0.5)
    build_mesh()
```

The column breathes. It rebuilds slowly as if still being carved. The studio becomes active.

Place a candle at the base for raking light.

```gdscript
func place_candle_light() -> void:
    var light := OmniLight3D.new()
    light.position = Vector3(1.5, 0.3, 0.0)
    light.light_color = Color(1.0, 0.85, 0.6)
    add_child(light)
```

A warm off-centre light grazes the surface. Highlights trace the spiral. Baroque lighting completes the effect.

You have cast sine into stone. The next map, John Cage, turns from oscillation to silence.
<<</MAP>>>

<<<MAP: WaveFunctions_John_Cage>>>
# John Cage

4'33" made the silence the piece. Build a room where absence is measurable and the noise floor is never actually zero.

Declare the listener.

```gdscript
class_name SilenceListener
extends Node3D

@export var sample_seconds: float = 0.25
var noise_floor_db: float = -60.0
```

A listener records short windows and computes the noise floor. Nothing is ever fully silent; the listener measures how quiet the room actually is.

Sample the ambient level.

```gdscript
func sample_ambient(bus: int) -> float:
    return AudioServer.get_bus_peak_volume_left_db(bus, 0)
```

Godot's AudioServer reports the bus peak in dB. Lower numbers are quieter. The method returns the current read.

Update the floor display.

```gdscript
func update_floor_display(label: Label3D) -> void:
    var level := sample_ambient(ambient_bus)
    noise_floor_db = lerp(noise_floor_db, level, 0.1)
    label.text = "floor: %.1f dB" % noise_floor_db
```

Exponential smoothing keeps the reading stable. The label shows the floor changing with the learner's own breath and movement.

Mark the 4'33" sections.

```gdscript
const CAGE_SECTIONS := [30.0, 162.0, 81.0]

func compute_total() -> float:
    var total := 0.0
    for s in CAGE_SECTIONS: total += s
    return total
```

Cage's score prescribes three movements with specific durations. The total matches the title. The constant records the piece.

Drive a timer against the sections.

```gdscript
func _process(dt: float) -> void:
    elapsed += dt
    if elapsed > CAGE_SECTIONS[current_section]:
        current_section = min(current_section + 1, CAGE_SECTIONS.size() - 1)
        elapsed = 0.0
        movement_label.text = "movement %d" % (current_section + 1)
```

The timer advances through the sections. Movement labels change quietly. The piece performs itself without a musician.

Generate an aleatoric event.

```gdscript
func aleatoric_event() -> void:
    if randf() < 0.005:
        var sound := preload("res://commons/artifacts/wavefunctions/ambient_click.tscn").instantiate()
        sound.position = Vector3(randf_range(-3, 3), randf_range(1, 2), randf_range(-3, 3))
        add_child(sound)
```

Rare, random clicks. The room performs chance. Cage's indeterminacy as a spawn rule.

Log each event for reflection.

```gdscript
func log_event(at: float, kind: String) -> void:
    events.append({"at": at, "kind": kind})
```

The log captures what happened in the silence. Every visit generates a different piece. The score is the rule; the performance is unique.

You have listened to the space between. The next map, AirMusic, lets position in space become note.
<<</MAP>>>

<<<MAP: WaveFunctions_AirMusic>>>
# Air Music

Walk into a position, the room plays a note. Build the spatial instrument where phasing loops drift over each other.

Declare the voice registry.

```gdscript
class_name SpatialVoice
extends Node3D

@export var midi_note: int = 60
@export var phase_period: float = 7.3
```

Each voice is a Node3D with a note and a phase period. Periods are irrationally spaced so the voices drift rather than lock.

Build the grid of voices.

```gdscript
func populate_voices(parent: Node3D) -> void:
    var scale := [0, 2, 4, 5, 7, 9, 11]
    for i in 12:
        var v := preload("res://commons/artifacts/wavefunctions/spatial_voice.tscn").instantiate()
        v.midi_note = 48 + scale[i % scale.size()] + 12 * (i / scale.size())
        v.position = Vector3(i * 1.2 - 6.5, 1.2, 0.0)
        v.phase_period = 5.0 + float(i) * 0.7
        parent.add_child(v)
```

Twelve voices across a major scale. Phase periods grow slowly. No two voices share a rate.

Detect the listener within range.

```gdscript
func within_range(listener: Vector3) -> bool:
    return global_position.distance_to(listener) < 1.0
```

The voice wakes only when the learner comes close. Everything else stays silent. The instrument plays by being visited.

Emit when triggered.

```gdscript
func _process(dt: float) -> void:
    if within_range(listener.global_position):
        var t := Time.get_ticks_msec() / 1000.0
        var phase_gate: bool = fmod(t, phase_period) < phase_period * 0.3
        if phase_gate and not sounding:
            play_note()
            sounding = true
        elif not phase_gate:
            sounding = false
```

Within range, the voice plays only during its phase window. Two nearby voices overlap only when their windows coincide. Harmony emerges from independent cycles.

Render a soft halo on the active voice.

```gdscript
func show_halo(active: bool) -> void:
    halo.visible = active
    halo.modulate = Color(1.0, 0.9, 0.6, 0.6)
```

A warm halo marks the active voice without sound alone. Visually quiet, sonically present.

Apply FM synthesis on the note.

```gdscript
func play_note() -> void:
    var freq: float = 440.0 * pow(2.0, (midi_note - 69) / 12.0)
    audio_player.frequency = freq
    audio_player.modulator = freq * 2.1
    audio_player.play()
```

FM piano-like tone, bright and bell-like. The modulator ratio gives Eno-era character. No composed sequence; the room composes.

Log the walk as a piece.

```gdscript
func log_note(v: SpatialVoice, t: float) -> void:
    piece.append({"t": t, "note": v.midi_note})
```

The piece records each voice that played and when. The learner takes a generated composition home. The room is a pencil, not a score.

You have made the space an instrument. The next map, Sky Stairs, ascends the wave.
<<</MAP>>>

<<<MAP: Wavefunctions_Sky_Stairs>>>
# Sky Stairs

Stairs climb along a sine curve. Build the vertical amphitheater and mount the wave one step at a time.

Declare the staircase.

```gdscript
class_name SineStaircase
extends Node3D

@export var step_count: int = 60
@export var horizontal_span: float = 15.0
@export var amplitude: float = 6.0
@export var frequency: float = 0.25
```

Sixty steps across fifteen horizontal metres. Amplitude peaks six metres above the base line.

Place each step.

```gdscript
func build_steps() -> void:
    for i in step_count:
        var t: float = float(i) / float(step_count)
        var x := t * horizontal_span - horizontal_span * 0.5
        var y := amplitude * sin(TAU * frequency * x)
        var step := preload("res://commons/artifacts/wavefunctions/stair_step.tscn").instantiate()
        step.position = Vector3(x, y, 0.0)
        add_child(step)
```

Each step sits at sine of its x. The staircase is the waveform; walking the staircase is tracing the wave.

Set step sizes.

```gdscript
func size_step(step: Node3D) -> void:
    step.scale = Vector3(0.25, 0.15, 0.6)
```

Narrow and deep. The learner can walk at a normal stride. Depth matters because the wave steepens near peaks.

Tilt the step to the local slope.

```gdscript
func tilt_step(step: Node3D, x: float) -> void:
    var slope: float = TAU * frequency * amplitude * cos(TAU * frequency * x)
    step.rotation.z = -atan(slope * 0.1)
```

Steps tilt into the wave so the walker's foot finds a level top. The tilt is tiny but prevents the feeling of climbing a corrugated roof.

Spawn floating cubes sampling the air.

```gdscript
func populate_cubes() -> void:
    for i in 40:
        var cube := preload("res://commons/artifacts/wavefunctions/float_cube.tscn").instantiate()
        cube.position = Vector3(randf_range(-7, 7), randf_range(0, 12), randf_range(-3, 3))
        add_child(cube)
```

Cubes hang in the air around the staircase. Most are above the wave; some are below. The sample makes the invisible field legible.

Light peaks with a lamp.

```gdscript
func place_peak_lamps() -> void:
    var wavelength: float = 1.0 / frequency
    for i in int(horizontal_span / wavelength) + 1:
        var x: float = i * wavelength - horizontal_span * 0.5
        var lamp := OmniLight3D.new()
        lamp.position = Vector3(x, amplitude + 1.0, 0.0)
        lamp.light_color = Color(1.0, 0.9, 0.6)
        add_child(lamp)
```

Lamps sit above each peak. The learner climbs toward light and descends into cooler air.

Chime on reaching a peak.

```gdscript
func _on_peak_entered(index: int) -> void:
    peak_chime.pitch_scale = 1.0 + index * 0.05
    peak_chime.play()
```

Each peak sounds slightly higher. The climb becomes a melody. Walking is performance.

You have climbed the wave. The next map, TrigWalkingPath, splits sine from cosine into parallel paths.
<<</MAP>>>

<<<MAP: WaveFunctions_TrigWalkingPath>>>
# Trig Walking Path

Two lanes, 90 degrees out of phase. Build the path that generates itself under the learner's feet.

Declare the path generator.

```gdscript
class_name TrigPath
extends Node3D

@export var lane_spacing: float = 1.5
@export var amplitude: float = 0.8
@export var frequency: float = 0.5
@export var ahead_distance: float = 8.0
```

Two lanes spaced apart. Amplitude is vertical. Ahead distance is how far the path pre-generates beyond the learner.

Sample both lanes at a distance.

```gdscript
func sample_lanes(z: float) -> Array:
    var sin_y: float = amplitude * sin(TAU * frequency * z)
    var cos_y: float = amplitude * cos(TAU * frequency * z)
    return [
        Vector3(-lane_spacing * 0.5, sin_y, z),
        Vector3(lane_spacing * 0.5, cos_y, z),
    ]
```

Sine on the left, cosine on the right. The 90-degree phase difference gives the visual rhythm of the dual path.

Generate new steps ahead of the player.

```gdscript
func extend_path(player_z: float) -> void:
    while last_z < player_z + ahead_distance:
        last_z += 0.4
        var points := sample_lanes(last_z)
        spawn_step(points[0])
        spawn_step(points[1])
```

As the learner walks forward, steps spawn ahead. The path never ends because it is always being drawn in front of them.

Spawn each step.

```gdscript
func spawn_step(pos: Vector3) -> void:
    var step := preload("res://commons/artifacts/wavefunctions/trig_step.tscn").instantiate()
    step.position = pos
    add_child(step)
    steps.append(step)
```

Each spawned step is tracked for despawn. The steps are small floating plates. The learner steps from one to the next.

Despawn steps behind.

```gdscript
func cull_behind(player_z: float) -> void:
    steps = steps.filter(func(s):
        if s.position.z < player_z - 5.0:
            s.queue_free()
            return false
        return true
    )
```

Old steps free themselves. Memory stays low. The path is finite at any moment but infinite over time.

Label each step with its angle.

```gdscript
func label_step(step: Node3D, z: float) -> void:
    var label: Label3D = step.get_node("Label3D")
    label.text = "θ = %.2f" % (TAU * frequency * z)
```

Each step carries its angle. The learner can read their position in the waveform by looking down.

Colour the lanes differently.

```gdscript
func tint_lanes() -> void:
    for step in steps:
        var is_left: bool = step.position.x < 0.0
        var mat := step.get_node("MeshInstance3D").material_override as StandardMaterial3D
        mat.albedo_color = Color(0.4, 0.7, 0.9) if is_left else Color(0.9, 0.6, 0.3)
```

Sine lane cool, cosine lane warm. The colour lets the learner cross-reference the phase without checking numbers.

You have walked the two fundamentals. The next map, Synthesis Lab, stacks harmonics until any waveform appears.
<<</MAP>>>

<<<MAP: WaveFunctions_Synthesis_Lab>>>
# Synthesis Lab

Fourier said any signal is a sum of sines. Build the room where stacking harmonics rebuilds the world.

Declare a harmonic.

```gdscript
class_name Harmonic
extends Resource

@export var harmonic_number: int = 1
@export var amplitude: float = 0.0
@export var phase: float = 0.0
```

One harmonic, three numbers. The harmonic number is the integer multiple of the fundamental.

Sum a harmonic bank.

```gdscript
func sample_bank(harmonics: Array[Harmonic], fundamental: float, t: float) -> float:
    var out := 0.0
    for h in harmonics:
        out += h.amplitude * sin(TAU * fundamental * h.harmonic_number * t + h.phase)
    return out
```

Each harmonic contributes its weighted sine. The bank is the Fourier sum. Fundamental sets the base note.

Build the adjustable bank.

```gdscript
func build_bank(n: int) -> Array[Harmonic]:
    var bank: Array[Harmonic] = []
    for i in n:
        var h := Harmonic.new()
        h.harmonic_number = i + 1
        bank.append(h)
    return bank
```

Ten harmonics is a usable bank. More is possible but adds little audible difference for most shapes.

Wire sliders to amplitudes.

```gdscript
func _on_slider_moved(index: int, v: float) -> void:
    bank[index].amplitude = lerp(0.0, 1.0, v)
    rebuild_waveform()
```

Each slider controls one amplitude. Raising the odd harmonics produces a square wave; raising all produces a sawtooth. The learner sees the wave grow.

Render the live waveform.

```gdscript
func update_trace(line: Line2D) -> void:
    line.clear_points()
    for i in 256:
        var t := float(i) / 256.0
        var y := sample_bank(bank, 1.0, t)
        line.add_point(Vector2(i * 2.0, -y * 40.0))
```

The trace redraws each frame. Moving a slider changes the shape immediately. The room responds at the speed of thought.

Play the bank audibly.

```gdscript
func feed_audio(playback: AudioStreamGeneratorPlayback) -> void:
    var frames_needed: int = playback.get_frames_available()
    for i in frames_needed:
        var t := audio_time
        audio_time += 1.0 / 44100.0
        var s: float = sample_bank(bank, 220.0, t) * 0.3
        playback.push_frame(Vector2(s, s))
```

Fundamental at 220 Hz gives a low A. The timbre changes as sliders move. Seeing and hearing align.

Map harmonics to biological oscillators.

```gdscript
func link_bio_example(name: String, h: int, a: float) -> void:
    var entry := Label3D.new()
    entry.text = "%s: harmonic %d at %.2f" % [name, h, a]
    bio_panel.add_child(entry)
```

A side panel lists heartbeats, DNA rotation, circadian rhythms. Each entry names a harmonic pattern from biology. The lab is not only a synthesizer.

Trigger chords from harmonic presets.

```gdscript
func load_preset(preset_name: String) -> void:
    match preset_name:
        "square": _load_odd_only()
        "sawtooth": _load_all_inverse()
        "triangle": _load_odd_inverse_squared()
```

Presets set common waveforms instantly. The learner can start from any of them and adjust.

You have synthesized the whole sequence. The final map, Chamber Waves, turns oscillation into contact.
<<</MAP>>>

<<<MAP: Chamber_Waves>>>
# Chamber Waves

Match the creature's frequency and it greets you. Build the chamber where oscillation is the shared variable between two bodies.

Declare the resonance pair.

```gdscript
class_name ResonancePair
extends Node3D

@export var learner_freq: float = 0.5
@export var creature_freq: float = 1.2
@export var tolerance: float = 0.15
```

Two frequencies and a tolerance window. When the difference falls inside the window, the pair resonates.

Read the learner's frequency from the catalyst bracelet.

```gdscript
func read_bracelet(bracelet: Node3D) -> float:
    return bracelet.get("waveform_frequency")
```

The bracelet is the instrument. Turning the stone changes the frequency. The chamber reads it every frame.

Compute the beat frequency.

```gdscript
func beat_freq() -> float:
    return abs(learner_freq - creature_freq)
```

When the beat falls below the tolerance, the two are effectively the same. The chamber reacts then.

Fire helix shots from the bracelet.

```gdscript
func fire_helix(origin: Vector3, dir: Vector3, freq: float) -> void:
    var shot := preload("res://commons/artifacts/wavefunctions/helix_shot.tscn").instantiate()
    shot.position = origin
    shot.direction = dir
    shot.helix_frequency = freq
    add_child(shot)
```

Each shot spirals through the air at the bracelet's frequency. The visual is the waveform made projectile.

Bounce the waterbomb creature.

```gdscript
func bounce(creature: Node3D, t: float) -> void:
    creature.position.y = ground_height + abs(sin(TAU * creature_freq * t)) * 0.7
```

Rectified sine so the creature only goes up. The creature bounces at its own frequency regardless of the learner.

Detect contact.

```gdscript
func _on_shot_hit(shot: Node3D, target: Node3D) -> void:
    if beat_freq() < tolerance:
        target.greet(shot.helix_frequency)
    else:
        target.recoil()
```

Matching frequency greets; mismatched frequency recoils. The learner tunes the bracelet by listening rather than reading.

Greet visibly.

```gdscript
func greet(freq: float) -> void:
    modulate = Color(0.9, 0.9, 0.5)
    emit_signal("befriended")
    play_greeting_tone(freq)
```

The creature lights up, emits a signal, plays a tone at the shared frequency. The friendship is a frequency match.

Unlock the exit on befriending.

```gdscript
func _on_befriended() -> void:
    exit_door.unlock()
    CatalystBracelet.register_friend(creature_name)
```

The exit opens when the creature is friendly. The bracelet records the friend for later chambers. Friendship persists.

You have closed the Wavefunctions sequence. The next arc returns to the QFEP Laboratory, where oscillation is one of four fundamentals.
<<</MAP>>>
