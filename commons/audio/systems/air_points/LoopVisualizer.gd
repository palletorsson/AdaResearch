extends Node3D

@export var looper_path: NodePath
var looper: SystemsMusicLooper

# Visuals
var visual_quad: MeshInstance3D
var shader_mat: ShaderMaterial

# Arrays for Shader Uniforms
var ring_radii: Array[float] = []
var phases: Array[float] = []
var active_timers: Array[float] = []

const ACTIVE_DURATION = 0.3 # How long sphere stays colored after note hit

func _ready():
	if looper_path:
		looper = get_node(looper_path)
		await get_tree().process_frame
		_setup_visuals()

func _setup_visuals():
	if not looper: return

	# Clear existing
	for c in get_children():
		c.queue_free()

	# 1. Calculate and Store Radii
	var min_dur = 1000.0
	var max_dur = 0.0
	for loop in looper.loops:
		if loop.duration < min_dur: min_dur = loop.duration
		if loop.duration > max_dur: max_dur = loop.duration

	ring_radii.clear()
	phases.clear()
	active_timers.clear()

	for i in range(looper.loops.size()):
		var loop = looper.loops[i]
		var norm_dur = (loop.duration - min_dur) / (max_dur - min_dur + 0.001)
		var radius = 1.0 + norm_dur * 1.5
		radius += i * 0.05
		ring_radii.append(radius)
		phases.append(0.0)
		active_timers.append(0.0)

	# 2. Setup Single Quad for Shader
	var quad_mesh = PlaneMesh.new()
	quad_mesh.size = Vector2(6, 6) # Covers the -3..3 range defined in shader
	
	shader_mat = ShaderMaterial.new()
	shader_mat.shader = load("res://commons/audio/systems/air_points/SystemsMusicVisualizer.gdshader")
	shader_mat.set_shader_parameter("ring_radii", ring_radii)
	shader_mat.set_shader_parameter("loop_count", looper.loops.size())
	
	visual_quad = MeshInstance3D.new()
	visual_quad.mesh = quad_mesh
	visual_quad.material_override = shader_mat
	add_child(visual_quad)

func _process(delta):
	if not looper or not visual_quad: return
	
	for i in range(looper.loops.size()):
		var loop = looper.loops[i]

		# Calculate total cycle length
		var total_len = loop.duration + loop.delay

		# Determine current position in cycle
		var current_time_in_cycle = 0.0
		if looper.loop_states[i]: # Delay Phase
			current_time_in_cycle = loop.duration + looper.loop_timers[i]
		else: # Loop Phase
			current_time_in_cycle = looper.loop_timers[i]

		phases[i] = current_time_in_cycle / total_len

		# Update active timers for hit effect
		if not looper.loop_states[i] and looper.loop_timers[i] < delta * 2.0:
			active_timers[i] = 1.0 # Start Hit (Intensity 1.0)
		else:
			if active_timers[i] > 0.0:
				active_timers[i] = max(0.0, active_timers[i] - delta / ACTIVE_DURATION)

	# Pass updated arrays to shader
	shader_mat.set_shader_parameter("phases", phases)
	shader_mat.set_shader_parameter("active_timers", active_timers)
