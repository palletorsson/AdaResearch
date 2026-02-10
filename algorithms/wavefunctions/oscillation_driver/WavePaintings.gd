# WavePaintings.gd
# Three Double Pendulum painting stations in a row
# Based on PendulumGrid3x3 - uses DoublePendulum.tscn which has working painting
# Middle pendulum has a grabbable bob2 for player control

extends Node3D

const DoublePendulumScene = preload("res://algorithms/wavefunctions/oscillation_driver/DoublePendulum.tscn")
const GRAB_SPHERE_SCENE = preload("res://commons/primitives/point/grab_sphere_point.tscn")

@export var num_pendulums: int = 3
@export var spacing: float = 8.0  # Space between pendulums
@export var pendulum_scale: float = 1.0  # Full size pendulums
@export var canvas_scale: float = 2.0  # Canvas size (larger for better visibility)
@export var use_uniform_swing: bool = false
@export var enable_middle_interaction: bool = false

# Initial angles
@export var base_theta1: float = 90.0
@export var base_theta2: float = 90.0
@export var angle_variation: float = 5.0

# Uniform damping (kept name for compatibility with existing scenes)
@export var middle_damping: float = 0.0

# Frame + paint color cycle
@export var frame_thickness: float = 0.08
@export var frame_depth: float = 0.05
@export var frame_color: Color = Color(0.12, 0.12, 0.14)
@export var paint_cycle_speed: float = 0.12
@export var paint_cycle_saturation: float = 0.75
@export var paint_cycle_value: float = 0.95

var pendulums: Array[Node3D] = []
var middle_index: int = 1  # Index of middle pendulum

# Grab state for middle pendulum
var _is_grabbed: bool = false
var _grab_velocity_samples: Array[Vector3] = []
var _last_bob_position: Vector3 = Vector3.ZERO
var _grabbable_bob: Node3D = null
var _paint_surfaces: Array[Node] = []
var _paint_time: float = 0.0

func _ready():
	_spawn_pendulums()
	if enable_middle_interaction:
		_setup_middle_grabbable()
	_setup_camera()
	_setup_environment()
	_create_title()

func _spawn_pendulums():
	var total_width = (num_pendulums - 1) * spacing
	var start_x = -total_width / 2.0
	
	for i in range(num_pendulums):
		var pendulum = DoublePendulumScene.instantiate()
		pendulum.name = "Pendulum_%d" % i
		
		# Uniform swing across all pendulums (optional variation)
		var theta1_offset = 0.0
		var theta2_offset = 0.0
		if not use_uniform_swing:
			theta1_offset = (i - middle_index) * angle_variation
			theta2_offset = (i - middle_index) * -angle_variation * 0.5
		pendulum.theta1_start = base_theta1 + theta1_offset
		pendulum.theta2_start = base_theta2 + theta2_offset
		
		# Position in row
		var x = start_x + i * spacing
		pendulum.position = Vector3(x, 0, 0)
		pendulum.scale = Vector3.ONE * pendulum_scale
		
		# Disable individual camera/environment
		_disable_camera(pendulum)
		
		# Scale the canvas separately from the pendulum
		var canvas = pendulum.get_node_or_null("DrawingCanvas")
		if canvas:
			canvas.scale = Vector3.ONE * canvas_scale
			canvas.position.y -= 0.2  # Lower it
			canvas.position.z = -1.5  # Behind the pendulum
			_register_canvas_surface(canvas)
			_add_canvas_frame(canvas)
		
		# Uniform damping for all pendulums
		pendulum.damping = middle_damping
		
		add_child(pendulum)
		pendulums.append(pendulum)
	
	print("WavePaintings: Spawned %d pendulums" % pendulums.size())

func _disable_camera(pendulum: Node3D):
	var camera = pendulum.get_node_or_null("Camera3D")
	if camera:
		camera.queue_free()
	var env = pendulum.get_node_or_null("WorldEnvironment")
	if env:
		env.queue_free()
	# Hide ProductCube and labels
	var cube = pendulum.get_node_or_null("ProductCube")
	if cube:
		cube.visible = false
	var label = pendulum.get_node_or_null("Label3D")
	if label:
		label.visible = false

func _setup_middle_grabbable():
	"""Add a grabbable sphere overlaying the middle pendulum's Bob2"""
	if not enable_middle_interaction:
		return
	if middle_index >= pendulums.size():
		return
	
	var middle = pendulums[middle_index]
	var bob2_node = middle.get_node_or_null("Pivot/Joint1/Bob2")
	if not bob2_node:
		push_error("WavePaintings: Could not find Bob2 in middle pendulum")
		return
	
	# Hide the original bob2 mesh but keep the node active
	# (set mesh to invisible, not the node itself, so children remain visible)
	if bob2_node is MeshInstance3D:
		bob2_node.transparency = 1.0
		var mat = bob2_node.get_active_material(0)
		if mat == null:
			mat = StandardMaterial3D.new()
			bob2_node.material_override = mat
		if mat is StandardMaterial3D:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.0
	
	# Create grabbable sphere as sibling of bob2 (at same position)
	_grabbable_bob = GRAB_SPHERE_SCENE.instantiate()
	_grabbable_bob.name = "GrabbableBob2"
	
	# Scale to match original bob size (original radius 0.15, grab sphere ~0.045)
	var scale_factor = 0.15 / 0.045
	_grabbable_bob.scale = Vector3.ONE * scale_factor
	
	# Configure
	if "glow_color" in _grabbable_bob:
		_grabbable_bob.glow_color = Color(0.95, 0.7, 0.2)  # Gold color
	
	# Connect signals
	if _grabbable_bob.has_signal("picked_up"):
		_grabbable_bob.picked_up.connect(_on_bob_picked_up)
	if _grabbable_bob.has_signal("dropped"):
		_grabbable_bob.dropped.connect(_on_bob_dropped)
	
	# Add as sibling of bob2 in Joint1 (so it moves with pendulum)
	var joint1 = bob2_node.get_parent()
	_grabbable_bob.position = bob2_node.position
	joint1.add_child(_grabbable_bob)
	
	# Add instruction label
	var label = Label3D.new()
	label.name = "GrabLabel"
	label.text = "GRAB & SWING"
	label.font_size = 48
	label.position = Vector3(0, 4.0, 0) * pendulum_scale
	label.modulate = Color(0.95, 0.8, 0.3)
	label.outline_size = 6
	middle.add_child(label)

func _setup_camera():
	var camera = Camera3D.new()
	camera.name = "Camera3D"
	var view_distance = num_pendulums * spacing * 0.7
	var cam_pos = Vector3(0, 2.0, view_distance)
	var look_target = Vector3(0, 1.5, 0)
	camera.position = cam_pos
	# Use look_at_from_position since node isn't in tree yet
	camera.look_at_from_position(cam_pos, look_target)
	add_child(camera)

func _setup_environment():
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.08, 0.08, 0.1)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.5
	
	var world_env = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	
	var light = DirectionalLight3D.new()
	light.transform = Transform3D.IDENTITY.rotated(Vector3.RIGHT, -0.5).rotated(Vector3.UP, 0.3)
	light.position = Vector3(3, 5, 5)
	light.light_energy = 0.8
	light.shadow_enabled = true
	add_child(light)
	
	var fill = DirectionalLight3D.new()
	fill.transform = Transform3D.IDENTITY.rotated(Vector3.RIGHT, -0.3).rotated(Vector3.UP, -0.5)
	fill.position = Vector3(-3, 3, 3)
	fill.light_energy = 0.3
	add_child(fill)

func _create_title():
	var title = Label3D.new()
	title.text = "Wave Paintings"
	title.font_size = 72
	title.position = Vector3(0, 4.5 * pendulum_scale, -1)
	title.modulate = Color(0.9, 0.9, 0.95)
	title.outline_size = 10
	add_child(title)
	
	var subtitle = Label3D.new()
	subtitle.text = "Chaos & Control"
	subtitle.font_size = 32
	subtitle.position = Vector3(0, 4.0 * pendulum_scale, -1)
	subtitle.modulate = Color(0.6, 0.6, 0.7)
	add_child(subtitle)

# =============================================================================
# GRAB HANDLING
# =============================================================================

func _on_bob_picked_up(_pickable):
	if not enable_middle_interaction:
		return
	_is_grabbed = true
	_grab_velocity_samples.clear()
	if _grabbable_bob:
		_last_bob_position = _grabbable_bob.global_position
	
	# Pause middle pendulum physics
	var middle = pendulums[middle_index]
	middle.set_process(false)
	
	# Update label
	var label = middle.get_node_or_null("GrabLabel")
	if label:
		label.text = "SWING IT!"

func _on_bob_dropped(_pickable):
	if not enable_middle_interaction:
		return
	_is_grabbed = false
	
	if middle_index >= pendulums.size():
		return
	
	var middle = pendulums[middle_index]
	
	# Calculate angular velocities from grab motion
	if _grab_velocity_samples.size() > 0:
		var avg_velocity = Vector3.ZERO
		for v in _grab_velocity_samples:
			avg_velocity += v
		avg_velocity /= _grab_velocity_samples.size()
		
		# Convert linear velocity to angular velocity for theta2
		var theta2 = middle.theta2
		var tangent = Vector3(-cos(theta2), -sin(theta2), 0)
		var tangent_vel = avg_velocity.dot(tangent)
		
		# Add to omega2 (scaled by pendulum scale)
		middle.omega2 += tangent_vel / (middle.l2 * pendulum_scale)
		middle.omega2 = clampf(middle.omega2, -15.0, 15.0)
		
		# Also affect omega1 slightly
		middle.omega1 += tangent_vel / (middle.l1 * pendulum_scale) * 0.3
		middle.omega1 = clampf(middle.omega1, -15.0, 15.0)
	
	_grab_velocity_samples.clear()
	
	# Resume middle pendulum physics
	middle.set_process(true)
	
	# Update label
	var label = middle.get_node_or_null("GrabLabel")
	if label:
		label.text = "GRAB & SWING"

func _physics_process(delta):
	if not enable_middle_interaction:
		return
	if not _is_grabbed or middle_index >= pendulums.size():
		return
	
	var middle = pendulums[middle_index]
	if not _grabbable_bob:
		return
	
	# Track velocity for release
	var current_pos = _grabbable_bob.global_position
	if _last_bob_position != Vector3.ZERO:
		var velocity = (current_pos - _last_bob_position) / delta
		_grab_velocity_samples.append(velocity)
		if _grab_velocity_samples.size() > 5:
			_grab_velocity_samples.pop_front()
	_last_bob_position = current_pos
	
	# Calculate angles from grabbed position
	var pivot = middle.get_node("Pivot")
	var joint1 = middle.get_node("Pivot/Joint1")
	
	var pivot_global = pivot.global_position
	var joint1_global = joint1.global_position
	var bob_global = _grabbable_bob.global_position
	
	# Calculate theta1 from pivot to joint1 direction
	var to_joint1 = joint1_global - pivot_global
	var theta1 = atan2(to_joint1.x, -to_joint1.y)
	
	# Calculate theta2 from joint1 to bob direction
	var to_bob = bob_global - joint1_global
	var theta2 = atan2(to_bob.x, -to_bob.y)
	
	# Update pendulum state (stop physics, set angles directly)
	middle.theta1 = theta1
	middle.theta2 = theta2
	middle.omega1 = 0.0
	middle.omega2 = 0.0

func _process(_delta):
	_update_paint_colors(_delta)
	# Override middle pendulum physics when grabbed
	if not enable_middle_interaction:
		return
	if _is_grabbed and middle_index < pendulums.size():
		var middle = pendulums[middle_index]
		# Force visual update from our angles
		var pivot = middle.get_node("Pivot")
		var joint1 = middle.get_node("Pivot/Joint1")
		pivot.rotation.z = middle.theta1
		joint1.rotation.z = middle.theta2 - middle.theta1

# =============================================================================
# UTILITY
# =============================================================================

func get_pendulum(index: int) -> Node3D:
	if index >= 0 and index < pendulums.size():
		return pendulums[index]
	return null

func reset_all():
	for i in range(pendulums.size()):
		var p = pendulums[i]
		var theta1_offset = 0.0
		var theta2_offset = 0.0
		if not use_uniform_swing:
			theta1_offset = (i - middle_index) * angle_variation
			theta2_offset = (i - middle_index) * -angle_variation * 0.5
		p.theta1 = deg_to_rad(base_theta1 + theta1_offset)
		p.theta2 = deg_to_rad(base_theta2 + theta2_offset)
		p.omega1 = 0.0
		p.omega2 = 0.0
		p.trail_points.clear()

func _register_canvas_surface(canvas: Node3D) -> void:
	var surface = canvas.get_node_or_null("CanvasBody/CanvasSurface")
	if surface:
		_paint_surfaces.append(surface)

func _add_canvas_frame(canvas: Node3D) -> void:
	var body = canvas.get_node_or_null("CanvasBody")
	if not body:
		return
	if body.get_node_or_null("CanvasFrame"):
		return
	var surface = body.get_node_or_null("CanvasSurface")
	var plane_size = Vector2(2.0, 2.0)
	if surface and surface is MeshInstance3D:
		var mesh = (surface as MeshInstance3D).mesh
		if mesh and mesh is PlaneMesh:
			plane_size = (mesh as PlaneMesh).size

	var half_x = plane_size.x * 0.5
	var half_z = plane_size.y * 0.5
	var depth = frame_depth
	var thickness = frame_thickness

	var frame = Node3D.new()
	frame.name = "CanvasFrame"
	frame.position.y = depth * 0.5
	body.add_child(frame)

	# Top
	frame.add_child(_make_frame_piece(
		Vector3(plane_size.x + thickness * 2.0, depth, thickness),
		Vector3(0, 0, half_z + thickness * 0.5)
	))
	# Bottom
	frame.add_child(_make_frame_piece(
		Vector3(plane_size.x + thickness * 2.0, depth, thickness),
		Vector3(0, 0, -half_z - thickness * 0.5)
	))
	# Left
	frame.add_child(_make_frame_piece(
		Vector3(thickness, depth, plane_size.y + thickness * 2.0),
		Vector3(-half_x - thickness * 0.5, 0, 0)
	))
	# Right
	frame.add_child(_make_frame_piece(
		Vector3(thickness, depth, plane_size.y + thickness * 2.0),
		Vector3(half_x + thickness * 0.5, 0, 0)
	))

func _make_frame_piece(size: Vector3, position: Vector3) -> MeshInstance3D:
	var mesh = BoxMesh.new()
	mesh.size = size
	var piece = MeshInstance3D.new()
	piece.mesh = mesh
	piece.position = position
	var material = StandardMaterial3D.new()
	material.albedo_color = frame_color
	material.metallic = 0.05
	material.roughness = 0.7
	piece.material_override = material
	return piece

func _update_paint_colors(delta: float) -> void:
	if _paint_surfaces.is_empty():
		return
	_paint_time = fmod(_paint_time + delta * paint_cycle_speed, 1.0)
	var tint = Color.from_hsv(_paint_time, paint_cycle_saturation, paint_cycle_value)
	for surface in _paint_surfaces:
		if surface and surface is MeshInstance3D:
			var mesh_surface: MeshInstance3D = surface
			var material = mesh_surface.material_override
			if material == null:
				material = mesh_surface.get_active_material(0)
			if material == null:
				material = StandardMaterial3D.new()
				mesh_surface.material_override = material
			if material is StandardMaterial3D:
				(material as StandardMaterial3D).albedo_color = tint
