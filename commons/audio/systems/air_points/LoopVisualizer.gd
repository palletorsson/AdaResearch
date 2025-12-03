extends Node3D

@export var looper_path: NodePath
var looper: SystemsMusicLooper

# Visuals
var guide_rings: Array[MeshInstance3D] = []
var revolving_spheres: Array[MeshInstance3D] = []
var sphere_radii: Array[float] = []
var play_head_line: MeshInstance3D

# Colors
const RING_COLOR = Color(0.92, 0.92, 0.92, 0.5) # Semi-transparent guide rings
const SPHERE_IDLE_COLOR = Color(0.6, 0.6, 0.6, 1.0) # Grey when not playing
const SPHERE_ACTIVE_COLOR = Color(0.85, 0.1, 0.38, 1.0) # Deep Pink when playing
const LINE_COLOR = Color(0.6, 0.6, 0.6, 1.0) # Dark Grey Playhead

# Sphere animation
var sphere_active_timers: Array[float] = []
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
	guide_rings.clear()
	revolving_spheres.clear()
	sphere_radii.clear()
	sphere_active_timers.clear()

	# 1. Calculate radii
	var min_dur = 1000.0
	var max_dur = 0.0
	for loop in looper.loops:
		if loop.duration < min_dur: min_dur = loop.duration
		if loop.duration > max_dur: max_dur = loop.duration

	# 2. Create Play Head Line
	_create_play_head_line()

	for i in range(looper.loops.size()):
		var loop = looper.loops[i]

		# Radius mapping
		var norm_dur = (loop.duration - min_dur) / (max_dur - min_dur + 0.001)
		var radius = 1.0 + norm_dur * 1.5
		radius += i * 0.05
		var thickness = 0.04 # Thinner guide rings

		# --- Guide Ring (Static Torus) ---
		var guide_mesh = TorusMesh.new()
		guide_mesh.inner_radius = radius
		guide_mesh.outer_radius = radius + thickness
		guide_mesh.rings = 64
		guide_mesh.ring_segments = 16

		var guide_mat = StandardMaterial3D.new()
		guide_mat.albedo_color = RING_COLOR
		guide_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		guide_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		guide_mesh.material = guide_mat

		var guide_ring = MeshInstance3D.new()
		guide_ring.mesh = guide_mesh
		# Don't rotate - keep in XZ plane to match sphere paths
		add_child(guide_ring)
		guide_rings.append(guide_ring)

		# --- Revolving Sphere ---
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.08
		sphere_mesh.height = 0.16

		var sphere_mat = StandardMaterial3D.new()
		sphere_mat.albedo_color = SPHERE_IDLE_COLOR
		sphere_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sphere_mat.emission_enabled = true
		sphere_mat.emission = SPHERE_IDLE_COLOR * 0.5
		sphere_mesh.material = sphere_mat

		var sphere = MeshInstance3D.new()
		sphere.mesh = sphere_mesh
		add_child(sphere)
		revolving_spheres.append(sphere)

		# Store radius for positioning
		sphere_radii.append(radius)
		sphere_active_timers.append(0.0)

func _create_play_head_line():
	var line_mesh = BoxMesh.new()
	line_mesh.size = Vector3(5.0, 0.02, 0.02)
	
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = LINE_COLOR
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mesh.material = line_mat
	
	play_head_line = MeshInstance3D.new()
	play_head_line.mesh = line_mesh
	play_head_line.position = Vector3(2.5, 0, 0) # Extends from 0 to 5 on X axis
	
	add_child(play_head_line)

func _process(delta):
	if not looper: return
	if revolving_spheres.size() == 0: return

	for i in range(looper.loops.size()):
		var sphere = revolving_spheres[i]
		var loop = looper.loops[i]
		var radius = sphere_radii[i]

		# Calculate total cycle length
		var total_len = loop.duration + loop.delay

		# Determine current position in cycle
		var current_time_in_cycle = 0.0
		if looper.loop_states[i]: # Delay Phase
			current_time_in_cycle = loop.duration + looper.loop_timers[i]
		else: # Loop Phase
			current_time_in_cycle = looper.loop_timers[i]

		var phase = current_time_in_cycle / total_len

		# Position sphere around the ring
		# Angle rotates clockwise, sphere follows the torus path
		var angle_rad = -phase * TAU + PI # Start at playhead (right side)

		# Position in XZ plane (rings are rotated 90 degrees on X)
		sphere.position = Vector3(
			cos(angle_rad) * radius,
			0.0,
			sin(angle_rad) * radius
		)

		# Update sphere color based on note triggering
		var mat = sphere.mesh.surface_get_material(0) as StandardMaterial3D

		# Check if note just triggered (at start of loop phase, near zero timer)
		if not looper.loop_states[i] and looper.loop_timers[i] < delta * 2.0:
			# Note just hit!
			sphere_active_timers[i] = ACTIVE_DURATION
			mat.albedo_color = SPHERE_ACTIVE_COLOR
			mat.emission = SPHERE_ACTIVE_COLOR * 2.0
			# Pulse effect
			sphere.scale = Vector3.ONE * 1.3
		else:
			# Countdown active timer
			if sphere_active_timers[i] > 0.0:
				sphere_active_timers[i] -= delta
				# Lerp back to idle color
				var t = sphere_active_timers[i] / ACTIVE_DURATION
				mat.albedo_color = SPHERE_ACTIVE_COLOR.lerp(SPHERE_IDLE_COLOR, 1.0 - t)
				mat.emission = mat.albedo_color * lerp(0.5, 2.0, t)
			else:
				# Fully idle
				mat.albedo_color = SPHERE_IDLE_COLOR
				mat.emission = SPHERE_IDLE_COLOR * 0.5

			# Lerp scale back to normal
			sphere.scale = sphere.scale.lerp(Vector3.ONE, 0.1)
