# Main scene script - attach to a Node3D
extends Node3D

const LIGHT_COUNT := 8
const LIGHT_SPAWN_TIME := TAU

# Wheel configuration - frequency, radius, phase
var wheels = [
	{"freq": 1.0, "radius": 2.0, "phase": 0.0},
	{"freq": 3.0, "radius": 0.8, "phase": 0.0},
	{"freq": 5.0, "radius": 0.4, "phase": PI / 2},
	{"freq": 7.0, "radius": 0.2, "phase": PI / 4}
]

var wheel_nodes = []
var connection_lines = []
var trace_points = []
var trace_line: Line3D
var time = 0.0
var trace_material: StandardMaterial3D
var light_nodes: Array = []
var lights_spawned := false
var wheel_audio_players: Array[AudioStreamPlayer3D] = []
var audio_playbacks: Array[AudioStreamGeneratorPlayback] = []
const SAMPLE_RATE = 44100.0
const BASE_FREQ = 110.0

var theremin_player: AudioStreamPlayer3D
var theremin_playback: AudioStreamGeneratorPlayback
var theremin_phase := 0.0
var last_tip_pos := Vector3.ZERO

# Mario sound trigger state
var last_quadrant: int = 0
var sound_time: float = 0.0
var is_playing_sound: bool = false
var sound_start_freq: float = 540.0
var sound_end_freq: float = 880.0
var sound_decay: float = 8.0
const SOUND_DURATION: float = 0.36

func _ready():
	setup_camera()
	setup_wheels()
	setup_trace()
	setup_audio()

func setup_audio():
	for i in range(wheels.size()):
		var wheel_data = wheels[i]
		var player = AudioStreamPlayer3D.new()
		add_child(player)
		player.unit_size = 15.0
		player.max_db = -6.0
		
		var generator = AudioStreamGenerator.new()
		generator.mix_rate = SAMPLE_RATE
		generator.buffer_length = 0.1
		player.stream = generator
		
		wheel_audio_players.append(player)
		player.play()
		audio_playbacks.append(player.get_stream_playback())
	
	print("FourierTransform: Ready with %d spatial harmonics" % wheels.size())
	
	setup_theremin()

func setup_theremin():
	theremin_player = AudioStreamPlayer3D.new()
	add_child(theremin_player)
	theremin_player.unit_size = 25.0
	theremin_player.max_db = 0.0 # Master voice
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.1
	theremin_player.stream = generator
	
	theremin_player.play()
	theremin_playback = theremin_player.get_stream_playback()

func setup_camera():
	var camera = Camera3D.new()
	camera.position = Vector3(0, 3, 8)
	camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
	add_child(camera)

func setup_wheels():
	# Create materials
	var wheel_material = StandardMaterial3D.new()
	wheel_material.albedo_color = Color.CYAN
	wheel_material.emission_enabled = true
	wheel_material.emission = Color.CYAN
	wheel_material.emission_energy_multiplier = 0.6

	var connection_material = StandardMaterial3D.new()
	connection_material.albedo_color = Color.WHITE
	connection_material.emission_enabled = true
	connection_material.emission = Color(0.9, 0.95, 1.0)
	connection_material.emission_energy_multiplier = 1.0

	var center_pos = Vector3.ZERO

	for i in range(wheels.size()):
		var wheel_data = wheels[i]

		# Create wheel (torus)
		var wheel_mesh = TorusMesh.new()
		wheel_mesh.inner_radius = wheel_data.radius * 0.8
		wheel_mesh.outer_radius = wheel_data.radius
		wheel_mesh.rings = 16
		wheel_mesh.ring_segments = 32

		var wheel_node = MeshInstance3D.new()
		wheel_node.mesh = wheel_mesh
		wheel_node.material_override = wheel_material
		wheel_node.position = center_pos
		add_child(wheel_node)
		wheel_nodes.append(wheel_node)

		# Create connection line to next wheel (or trace point for last wheel)
		var line_mesh = CylinderMesh.new()
		line_mesh.top_radius = 0.04
		line_mesh.bottom_radius = 0.04
		line_mesh.height = 1.0

		var line_node = MeshInstance3D.new()
		line_node.mesh = line_mesh
		line_node.material_override = connection_material
		add_child(line_node)
		connection_lines.append(line_node)

func setup_trace():
	trace_material = StandardMaterial3D.new()
	trace_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	trace_material.albedo_color = Color(1.0, 0.85, 0.2)
	trace_material.emission_enabled = true
	trace_material.emission = Color(1.0, 0.85, 0.3)
	trace_material.emission_energy_multiplier = 2.0
	trace_material.vertex_color_use_as_albedo = true
	trace_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	trace_line = Line3D.new()
	trace_line.width = 0.12
	# Use the custom Line3D implementation found in core/line3d.gd
	# which supports width, default_color, texture_mode and material_override.
	trace_line.texture_mode = Line3D.TEXTURE_MODE.TEXTURE_MODE_TILE
	trace_line.default_color = Color(1.0, 0.9, 0.4, 0.9)
	trace_line.material_override = trace_material
	add_child(trace_line)

func _process(delta):
	time += delta * 0.5  # Control animation speed

	update_wheels()
	update_trace()
	ensure_trace_lights()
	_generate_theremin_audio()

func update_wheels():
	var current_pos = Vector3.ZERO

	# After 3 cycles, start adding modulation
	var modulation_start = 3.0 * TAU
	var mod_amount = 0.0
	if time > modulation_start:
		# Gradually increase modulation over the next 2 cycles
		mod_amount = clamp((time - modulation_start) / (2.0 * TAU), 0.0, 1.0)

	for i in range(wheels.size()):
		var wheel_data = wheels[i]
		var wheel_node = wheel_nodes[i]
		var line_node = connection_lines[i]

		# Base wheel rotation
		var angle = time * wheel_data.freq + wheel_data.phase

		# After 3 cycles, add subtle modulations to each wheel
		if mod_amount > 0.0:
			# Each wheel gets unique modulation based on its harmonic number
			var harmonic = wheel_data.freq

			# Frequency wobble - subtle variation in rotation speed
			var freq_mod = sin(time * 0.3 * harmonic) * 0.05 * mod_amount
			angle += freq_mod * time

			# Phase drift - slow wandering of phase
			var phase_mod = sin(time * 0.1 + i * PI / 2) * 0.2 * mod_amount
			angle += phase_mod

			# Radius breathing - subtle pulsing (affects arm_end calculation below)
			var radius_mod = 1.0 + sin(time * 0.2 * (i + 1)) * 0.08 * mod_amount
			wheel_data["_radius_mod"] = radius_mod
		else:
			wheel_data["_radius_mod"] = 1.0

		wheel_node.rotation.z = angle

		# Position wheel at current position
		wheel_node.position = current_pos

		# Calculate next position (end of this wheel's arm) with radius modulation
		var effective_radius = wheel_data.radius * wheel_data.get("_radius_mod", 1.0)
		var arm_end = current_pos + Vector3(
			cos(angle) * effective_radius,
			sin(angle) * effective_radius,
			0
		)

		# Update connection line
		var line_center = (current_pos + arm_end) / 2
		var line_direction = (arm_end - current_pos).normalized()
		var line_length = current_pos.distance_to(arm_end)

		line_node.position = line_center
		line_node.scale.y = line_length

		# Rotate line to point in correct direction
		if line_direction.length() > 0:
			var up = Vector3.UP
			if abs(line_direction.dot(up)) > 0.99:
				up = Vector3.RIGHT
			var right = line_direction.cross(up).normalized()
			up = right.cross(line_direction).normalized()
			line_node.basis = Basis(right, line_direction, up)

		# Update audio position to follow wheel tip
		if i < wheel_audio_players.size():
			wheel_audio_players[i].position = arm_end
			
		current_pos = arm_end

	# Add current end position to trace
	if trace_points.size() < 1000:  # Limit trace length
		trace_points.append(current_pos)
	else:
		trace_points.pop_front()
		trace_points.append(current_pos)

func update_trace():
	trace_line.clear_points()

	if trace_points.size() < 2:
		return

	for i in range(trace_points.size()):
		trace_line.add_point(trace_points[i])

func ensure_trace_lights():
	if lights_spawned:
		return
	if time < LIGHT_SPAWN_TIME:
		return
	if trace_points.is_empty():
		return

	var spacing = max(1, trace_points.size() / LIGHT_COUNT)
	for i in range(0, trace_points.size(), spacing):
		if light_nodes.size() >= LIGHT_COUNT:
			break

		var light = OmniLight3D.new()
		light.light_color = Color(1.0, 0.85, 0.4)
		light.light_energy = 1.6
		light.omni_range = 2.8
		light.shadow_enabled = false
		light.position = trace_points[i]
		add_child(light)
		light_nodes.append(light)

	if light_nodes.size() > 0:
		lights_spawned = true

func _generate_audio_samples():
	# MATHEMATICAL BEAUTY - Pure, clean harmonic tones
	# Each wheel represents a Fourier harmonic - pure mathematical relationship
	# Using perfect fifths and octaves for clean interference patterns
	var harmonic_freqs = [110.0, 165.0, 220.0, 330.0]  # A2, E3, A3, E4 - pure fifths

	for i in range(audio_playbacks.size()):
		var playback = audio_playbacks[i]
		if not playback: continue

		var frames_available = playback.get_frames_available()
		if frames_available <= 0: continue

		var wheel_data = wheels[i]
		var freq = harmonic_freqs[i % harmonic_freqs.size()]

		# Very subtle detuning - almost imperceptible
		freq *= 1.0 + sin(time * 0.05 + i * 0.7) * 0.001

		# Quiet amplitude based on wheel size
		var amplitude = wheel_data.radius * 0.04

		for _f in range(frames_available):
			var t = time + float(_f) / SAMPLE_RATE

			# Pure sine wave - mathematical clarity
			var sample = sin(TAU * freq * t)

			# Gentle slow swell - breathing
			var swell = 0.6 + 0.4 * sin(t * 0.15 + i * 0.5)
			sample *= swell * amplitude

			# Soft limiting
			sample = tanh(sample * 3.0) * 0.33

			playback.push_frame(Vector2(sample, sample))

func _generate_theremin_audio():
	if not theremin_playback: return
	var frames = theremin_playback.get_frames_available()
	if frames <= 0: return

	# Need enough points to make a wavetable
	if trace_points.size() < 16: return

	var tip_pos = trace_points[-1]
	theremin_player.position = tip_pos

	# The trace IS the waveform - use Y values as wavetable
	# Playback rate determines pitch
	var base_freq = 55.0  # Low A - the form cycles at this pitch
	var master_volume = 0.15

	var modulation_start = 3.0 * TAU

	for i in range(frames):
		var t = time + float(i) / SAMPLE_RATE

		# Modulation after 3 cycles
		var mod_amount = 0.0
		if time > modulation_start:
			mod_amount = clamp((time - modulation_start) / TAU, 0.0, 1.0)

		# Advance through wavetable
		theremin_phase += base_freq / SAMPLE_RATE
		if theremin_phase > 1.0: theremin_phase -= 1.0

		# Sample the trace shape as waveform
		var table_size = trace_points.size()
		var pos = theremin_phase * table_size
		var idx = int(pos) % table_size
		var next_idx = (idx + 1) % table_size
		var frac = pos - floor(pos)

		# Linear interpolation between points
		var y1 = trace_points[idx].y
		var y2 = trace_points[next_idx].y
		var sample = lerp(y1, y2, frac)

		# Normalize to audio range (trace Y is roughly -3 to 3)
		sample = sample / 3.0

		# After 3 cycles, add X dimension as second voice (detuned)
		if mod_amount > 0.0:
			var phase2 = fmod(theremin_phase * 1.002, 1.0)  # Slight detune
			var pos2 = phase2 * table_size
			var idx2 = int(pos2) % table_size
			var next_idx2 = (idx2 + 1) % table_size
			var frac2 = pos2 - floor(pos2)

			var x1 = trace_points[idx2].x
			var x2 = trace_points[next_idx2].x
			var sample2 = lerp(x1, x2, frac2) / 3.0

			sample = sample * (1.0 - mod_amount * 0.3) + sample2 * mod_amount * 0.3

		sample *= master_volume

		# Gentle limiting
		sample = tanh(sample * 1.5) * 0.6

		theremin_playback.push_frame(Vector2(sample, sample))

