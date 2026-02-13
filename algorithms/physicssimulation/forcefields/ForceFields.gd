# ===========================================================================
# Force Fields — Area3D Gravity Overrides
# Uses Godot's built-in Area3D gravity_space_override to create force regions.
# RigidBody3D balls are dropped in; the engine applies the forces automatically.
# ===========================================================================
extends Node3D

# ---------------------------------------------------------------------------
# VR interaction (matches Constraints_Interactive pattern)
# ---------------------------------------------------------------------------
var left_controller: XRController3D
var right_controller: XRController3D
var left_grab_active: bool = false
var right_grab_active: bool = false
var grabbed_body: RigidBody3D = null
var grab_joint: Generic6DOFJoint3D = null
var grab_anchor: StaticBody3D = null

# ---------------------------------------------------------------------------
# Settings
# ---------------------------------------------------------------------------
@export var ball_count: int = 18
@export var ball_radius: float = 0.12
@export var ball_mass: float = 1.0

var balls: Array[RigidBody3D] = []
var time: float = 0.0

# Vibrant palette
var colors := [
	Color(1.0, 0.4, 0.7),   # Hot pink
	Color(0.8, 0.3, 1.0),   # Purple
	Color(0.3, 0.9, 1.0),   # Cyan
	Color(1.0, 0.8, 0.2),   # Gold
	Color(0.5, 1.0, 0.4),   # Lime
	Color(1.0, 0.5, 0.3),   # Coral
]

# ===========================================================================
# Lifecycle
# ===========================================================================
func _ready():
	scale = Vector3(0.8, 0.8, 0.8)
	setup_vr_controllers()
	_build_gravity_field()
	_build_point_attractor()
	_build_wind_drag_field()
	_spawn_balls()
	_create_ui()
	print("Force Fields — drop balls into the coloured zones!")

# ===========================================================================
# 1. GRAVITY FIELD — directional override (pushes everything sideways)
# ===========================================================================
func _build_gravity_field():
	var area := Area3D.new()
	area.name = "GravityField"
	area.position = Vector3(-3.0, 1.5, 0.0)

	# Override gravity inside this region
	area.gravity_space_override = Area3D.SPACE_OVERRIDE_COMBINE
	area.gravity_direction = Vector3(1.0, 0.5, 0.0).normalized()
	area.gravity = 15.0
	area.gravity_point = false

	# Collision shape — box region
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.5, 2.5)
	col.shape = box
	area.add_child(col)

	# Visual — translucent box
	area.add_child(_zone_visual(box.size, colors[0]))
	_add_zone_label(area, "GRAVITY\n(directional)", Vector3(0, 1.5, 0))
	$Fields.add_child(area)

# ===========================================================================
# 2. POINT ATTRACTOR — radial pull towards centre
# ===========================================================================
func _build_point_attractor():
	var area := Area3D.new()
	area.name = "PointAttractor"
	area.position = Vector3(0.0, 1.5, 0.0)

	area.gravity_space_override = Area3D.SPACE_OVERRIDE_COMBINE
	area.gravity_point = true
	area.gravity_point_unit_distance = 1.0
	area.gravity = 20.0

	var col := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.8
	col.shape = sphere
	area.add_child(col)

	# Visual — translucent sphere
	var viz := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = sphere.radius
	mesh.height = sphere.radius * 2.0
	viz.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(colors[1], 0.15)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = colors[1] * 0.4
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	viz.material_override = mat
	area.add_child(viz)

	# Core glow
	var core := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.15
	cm.height = 0.3
	core.mesh = cm
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = colors[1]
	cmat.emission_enabled = true
	cmat.emission = colors[1]
	cmat.emission_energy_multiplier = 3.0
	core.material_override = cmat
	area.add_child(core)

	_add_zone_label(area, "ATTRACTOR\n(point gravity)", Vector3(0, 2.2, 0))
	$Fields.add_child(area)

# ===========================================================================
# 3. WIND / DRAG FIELD — linear damping override
# ===========================================================================
func _build_wind_drag_field():
	var area := Area3D.new()
	area.name = "WindDragField"
	area.position = Vector3(3.0, 1.5, 0.0)

	area.gravity_space_override = Area3D.SPACE_OVERRIDE_COMBINE
	area.gravity_direction = Vector3(0.0, 1.0, 0.0)  # upward push (buoyancy)
	area.gravity = 12.0

	# Heavy linear damp simulates viscous drag / wind resistance
	area.linear_damp_space_override = Area3D.SPACE_OVERRIDE_COMBINE
	area.linear_damp = 4.0
	area.angular_damp_space_override = Area3D.SPACE_OVERRIDE_COMBINE
	area.angular_damp = 2.0

	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.5, 2.5, 2.5)
	col.shape = box
	area.add_child(col)

	area.add_child(_zone_visual(box.size, colors[2]))
	_add_zone_label(area, "WIND / DRAG\n(damp + buoyancy)", Vector3(0, 1.5, 0))
	$Fields.add_child(area)

# ===========================================================================
# Spawn grabbable RigidBody3D balls
# ===========================================================================
func _spawn_balls():
	for i in range(ball_count):
		var body := RigidBody3D.new()
		body.mass = ball_mass
		body.contact_monitor = true
		body.max_contacts_reported = 2
		body.continuous_cd = true

		# Spread balls above the fields
		body.position = Vector3(
			randf_range(-4.5, 4.5),
			randf_range(4.0, 6.0),
			randf_range(-1.0, 1.0)
		)

		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = ball_radius
		col.shape = shape
		body.add_child(col)

		var viz := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = ball_radius
		mesh.height = ball_radius * 2.0
		viz.mesh = mesh
		var mat := StandardMaterial3D.new()
		var c: Color = colors[i % colors.size()]
		mat.albedo_color = c
		mat.metallic = 0.4
		mat.roughness = 0.5
		mat.emission_enabled = true
		mat.emission = c * 0.6
		mat.emission_energy_multiplier = 1.5
		viz.material_override = mat
		body.add_child(viz)

		$Balls.add_child(body)
		balls.append(body)

# ===========================================================================
# Helpers
# ===========================================================================
func _zone_visual(size: Vector3, color: Color) -> MeshInstance3D:
	var viz := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	viz.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color, 0.12)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = color * 0.3
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	viz.material_override = mat
	return viz

func _add_zone_label(parent: Node3D, text: String, offset: Vector3):
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 28
	label.outline_size = 4
	label.position = offset
	label.modulate = Color.WHITE
	parent.add_child(label)

func _create_ui():
	var title := Label3D.new()
	title.text = "FORCE FIELDS"
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.font_size = 36
	title.outline_size = 5
	title.position = Vector3(0, 5.5, 0)
	add_child(title)

	var info := Label3D.new()
	info.text = "[Grab] throw balls into zones | [R] Reset"
	info.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info.font_size = 18
	info.outline_size = 3
	info.position = Vector3(0, 4.8, 0)
	add_child(info)

# ===========================================================================
# Floor so balls don't fall forever
# ===========================================================================
func _create_floor():
	# Created in .tscn — StaticBody3D at y = -0.5
	pass

# ===========================================================================
# VR grab system (same as Constraints_Interactive)
# ===========================================================================
func setup_vr_controllers():
	var xr_origin = get_tree().get_first_node_in_group("XROrigin")
	if xr_origin:
		left_controller = xr_origin.get_node_or_null("LeftController")
		right_controller = xr_origin.get_node_or_null("RightController")
		if left_controller:
			left_controller.button_pressed.connect(_on_left_button_pressed)
			left_controller.button_released.connect(_on_left_button_released)
		if right_controller:
			right_controller.button_pressed.connect(_on_right_button_pressed)
			right_controller.button_released.connect(_on_right_button_released)

func _process(_delta: float):
	_update_vr_grab()

func _update_vr_grab():
	if left_grab_active and left_controller and not grabbed_body:
		_attempt_grab(left_controller.global_position)
	elif not left_grab_active and grabbed_body:
		_release_grab()

	if right_grab_active and right_controller and not grabbed_body:
		_attempt_grab(right_controller.global_position)
	elif not right_grab_active and grabbed_body:
		_release_grab()

	# Follow controller
	if grabbed_body and grab_anchor:
		if left_grab_active and left_controller:
			grab_anchor.global_position = left_controller.global_position
		elif right_grab_active and right_controller:
			grab_anchor.global_position = right_controller.global_position

func _attempt_grab(controller_global_pos: Vector3):
	var radius := 0.35
	for body in balls:
		if not is_instance_valid(body):
			continue
		if body.global_position.distance_to(controller_global_pos) < radius:
			grabbed_body = body
			grab_anchor = StaticBody3D.new()
			grab_anchor.global_position = controller_global_pos
			add_child(grab_anchor)
			grab_joint = Generic6DOFJoint3D.new()
			grab_joint.node_a = grab_anchor.get_path()
			grab_joint.node_b = grabbed_body.get_path()
			for _axis in range(3):
				grab_joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
				grab_joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
				grab_joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
				grab_joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 120.0)
				grab_joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 120.0)
				grab_joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 120.0)
			add_child(grab_joint)
			break

func _release_grab():
	if grab_joint:
		grab_joint.queue_free()
		grab_joint = null
	if grab_anchor:
		grab_anchor.queue_free()
		grab_anchor = null
	grabbed_body = null

func _on_left_button_pressed(button_name: String):
	if button_name == "trigger_click" or button_name == "grip_click":
		left_grab_active = true
func _on_left_button_released(button_name: String):
	if button_name == "trigger_click" or button_name == "grip_click":
		left_grab_active = false
func _on_right_button_pressed(button_name: String):
	if button_name == "trigger_click" or button_name == "grip_click":
		right_grab_active = true
func _on_right_button_released(button_name: String):
	if button_name == "trigger_click" or button_name == "grip_click":
		right_grab_active = false

# ===========================================================================
# Keyboard shortcuts
# ===========================================================================
func _input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				_reset()

func _reset():
	for b in balls:
		if is_instance_valid(b):
			b.queue_free()
	balls.clear()
	await get_tree().create_timer(0.1).timeout
	_spawn_balls()
