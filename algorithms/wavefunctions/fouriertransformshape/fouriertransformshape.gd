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
	_generate_audio_samples()
	_generate_theremin_audio()

func update_wheels():
	var current_pos = Vector3.ZERO

	for i in range(wheels.size()):
		var wheel_data = wheels[i]
		var wheel_node = wheel_nodes[i]
		var line_node = connection_lines[i]

		# Calculate wheel rotation
		var angle = time * wheel_data.freq + wheel_data.phase
		wheel_node.rotation.z = angle

		# Position wheel at current position
		wheel_node.position = current_pos

		# Calculate next position (end of this wheel's arm)
		var arm_end = current_pos + Vector3(
			cos(angle) * wheel_data.radius,
			sin(angle) * wheel_data.radius,
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
	# ETHEREAL PAD - Soft evolving chord tones
	# Each wheel generates a note of a chord instead of harsh harmonics
	var chord_freqs = [130.8, 164.8, 196.0, 261.6]  # C3, E3, G3, C4 - C major
	
	for i in range(audio_playbacks.size()):
		var playback = audio_playbacks[i]
		if not playback: continue
		
		var frames_available = playback.get_frames_available()
		if frames_available <= 0: continue
		
		var wheel_data = wheels[i]
		var freq = chord_freqs[i % chord_freqs.size()]
		
		# Subtle detuning for richness
		freq *= 1.0 + sin(time * 0.2 + i) * 0.005
		
		var amplitude = wheel_data.radius * 0.08  # Quiet
		
		for _f in range(frames_available):
			var t = time + float(_f) / SAMPLE_RATE
			
			# Layered sine waves for pad texture
			var sample = sin(2.0 * PI * freq * t) * 0.5
			sample += sin(2.0 * PI * freq * 2.0 * t) * 0.2  # Octave
			sample += sin(2.0 * PI * freq * 1.5 * t) * 0.15  # Fifth
			
			# Gentle tremolo
			var tremolo = 0.8 + 0.2 * sin(time * 2.0 + i)
			sample *= tremolo * amplitude
			
			playback.push_frame(Vector2(sample, sample))

func _generate_theremin_audio():
	if not theremin_playback: return
	var frames = theremin_playback.get_frames_available()
	if frames <= 0: return

	if trace_points.is_empty(): return
	var tip_pos = trace_points[-1]
	
	theremin_player.position = tip_pos
	
	# ETHEREAL LEAD - Soft singing tone following the trace
	# Pitch follows Y position gently
	var base_freq = 220.0 + (tip_pos.y * 30.0)  # More subtle range
	base_freq = clamp(base_freq, 150.0, 400.0)
	
	# Speed affects vibrato depth
	var speed = tip_pos.distance_to(last_tip_pos) * 60.0
	last_tip_pos = tip_pos
	
	var vibrato_rate = 4.0
	var vibrato_depth = 3.0 + speed * 0.2
	
	var master_volume = 0.12  # Quiet
	
	for i in range(frames):
		var t = time + float(i) / SAMPLE_RATE
		
		# Gentle vibrato
		var vibrato = sin(t * TAU * vibrato_rate) * vibrato_depth
		var current_freq = base_freq + vibrato
		
		theremin_phase += current_freq / SAMPLE_RATE
		if theremin_phase > 1.0: theremin_phase -= 1.0
		
		# Pure ethereal tone
		var fundamental = sin(theremin_phase * TAU)
		var octave = sin(theremin_phase * TAU * 2.0) * 0.2
		var shimmer = sin(theremin_phase * TAU * 3.0) * 0.08
		
		# Soft envelope based on motion
		var envelope = 0.6 + 0.4 * (1.0 / (1.0 + speed * 0.5))
		
		var sample = (fundamental + octave + shimmer) * envelope * master_volume
		
		# Soft limiting
		sample = tanh(sample * 2.0) * 0.5
		
		theremin_playback.push_frame(Vector2(sample, sample))

