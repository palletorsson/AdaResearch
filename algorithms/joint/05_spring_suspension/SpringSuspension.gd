# @identity
# essence: 6DOF joint with Y-axis spring, all other axes locked. Vertical bounce, nothing else.
# desire: To feel suspension — the spring absorbs the drop, the damping kills the ringing.
# critical_parameter: spring_stiffness (30.0) and spring_damping (3.5) — tune between trampoline and concrete.
# triggers: Space key drops the wheel; spring-damper responds.
# emerges: The exponentially decaying oscillation of a damped harmonic system.
# needs: Spring bounce [has], space-key impulse [has]. Missing: stiffness slider, damping slider.
# relationships: Only 6DOF joint demo. Contrasts with ConeTwistBag (angular spring). Pairs with SliderPress (linear motion without spring).
# truth: A spring joint is a constraint that remembers where it wants to be. Damping is how fast it forgets being disturbed.

extends "res://algorithms/joint/shared/joint_demo_base.gd"
class_name SpringSuspensionDemo

# --- Color palette ---
const COLOR_WHEEL    := Color(0.0,  0.85, 1.0)   # cyan
const COLOR_CHASSIS  := Color(0.55, 0.55, 0.62)  # cool gray
const COLOR_JOINT    := Color(1.0,  0.55, 0.05)  # orange

# --- Trail config ---
const TRAIL_MAX_PTS  := 200
const TRAIL_WIDTH    := 0.04

var wheel: RigidBody3D
var suspension: Generic6DOFJoint3D

# Visual nodes
var _joint_marker: MeshInstance3D
var _trail_mesh:   MeshInstance3D
var _trail_mat:    StandardMaterial3D
var _info_label:   Label3D

# Trail ring buffer
var _trail_pts: Array[Vector3] = []
var _wheel_rest_y: float = 1.6   # initial wheel Y — used to compute displacement

# -------------------------------------------------------------------------
# Material factory
# -------------------------------------------------------------------------
func _make_emissive(color: Color, energy: float = 1.5) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	mat.emission_energy_multiplier = energy
	mat.metallic = 0.3
	mat.roughness = 0.4
	return mat

# -------------------------------------------------------------------------
# Build
# -------------------------------------------------------------------------
func _build_demo() -> void:
	# --- Physics bodies (unchanged logic) ---
	var chassis := create_static_box("Chassis", Vector3(4.0, 0.4, 2.0), Vector3(0.0, 3.0, 0.0), Color(0.5, 0.5, 0.6))

	wheel = create_cylinder("Wheel", 0.7, 0.4, Vector3(0.0, 1.6, 0.0), 2.0, Color(0.2, 0.2, 0.8))
	wheel.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	wheel.angular_damp = 0.8

	suspension = Generic6DOFJoint3D.new()
	suspension.name = "Suspension"
	suspension.node_a = chassis.get_path()
	suspension.node_b = wheel.get_path()
	suspension.position = Vector3(0.0, 2.6, 0.0)
	suspension.rotation = Vector3.ZERO
	# Lock lateral translation
	suspension.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	suspension.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
	suspension.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
	suspension.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	suspension.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
	suspension.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
	# Allow vertical travel with spring behaviour
	suspension.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, -0.6)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.25)
	suspension.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, 30.0)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, 3.5)
	# Lock rotations to keep wheel upright
	suspension.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	suspension.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
	suspension.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)
	suspension.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
	suspension.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)
	suspension.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	suspension.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, 0.0)
	suspension.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, 0.0)
	suspension.set_exclude_nodes_from_collision(true)
	add_child(suspension)

	# --- Visual upgrades ---
	_apply_visuals(chassis)
	_add_joint_marker()
	_add_trail()
	_add_info_label()

	add_label("Damped Spring Suspension", Vector3(0.0, 4.2, 2.5))

# -------------------------------------------------------------------------
# Visual helpers
# -------------------------------------------------------------------------

# 2. COLOR / GLOW — override mesh materials on chassis and wheel
func _apply_visuals(chassis: StaticBody3D) -> void:
	# Chassis: cool gray with subtle glow
	var chassis_mesh := chassis.get_child(1) as MeshInstance3D
	if chassis_mesh:
		chassis_mesh.material_override = _make_emissive(COLOR_CHASSIS, 0.6)

	# Wheel: cyan with stronger glow
	var wheel_mesh := wheel.get_child(1) as MeshInstance3D
	if wheel_mesh:
		wheel_mesh.material_override = _make_emissive(COLOR_WHEEL, 2.0)

# 4. CONNECTIONS — glowing orange sphere at the joint attachment point
func _add_joint_marker() -> void:
	_joint_marker = MeshInstance3D.new()
	_joint_marker.name = "JointMarker"
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	_joint_marker.mesh = sphere
	_joint_marker.material_override = _make_emissive(COLOR_JOINT, 3.0)
	_joint_marker.position = suspension.position
	add_child(_joint_marker)

# 3. TRAILS — ImmediateMesh ribbon following wheel Y bounce
func _add_trail() -> void:
	_trail_mesh = MeshInstance3D.new()
	_trail_mesh.name = "WheelTrail"
	_trail_mesh.mesh = ImmediateMesh.new()
	_trail_mat = StandardMaterial3D.new()
	_trail_mat.albedo_color = COLOR_WHEEL
	_trail_mat.emission_enabled = true
	_trail_mat.emission = COLOR_WHEEL * 0.5
	_trail_mat.emission_energy_multiplier = 1.2
	_trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_mat.no_depth_test = false
	_trail_mesh.material_override = _trail_mat
	add_child(_trail_mesh)

# 7. INFORMATION — label showing current wheel displacement
func _add_info_label() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.text = "disp: 0.00 m"
	_info_label.font_size = 18
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.modulate = COLOR_WHEEL
	_info_label.position = Vector3(2.0, 2.2, 0.0)
	add_child(_info_label)

# -------------------------------------------------------------------------
# Per-frame updates
# -------------------------------------------------------------------------
func _process(delta: float) -> void:
	# Physics impulse trigger (unchanged)
	if Input.is_action_just_pressed("ui_accept"):
		wheel.apply_impulse(Vector3(0.0, 6.0, 0.0))

	if not is_instance_valid(wheel):
		return

	var wheel_pos := wheel.global_position

	# --- Trail update ---
	_trail_pts.push_back(wheel_pos)
	if _trail_pts.size() > TRAIL_MAX_PTS:
		_trail_pts.pop_front()
	_rebuild_trail()

	# --- Info label update ---
	var disp := wheel_pos.y - _wheel_rest_y
	var vel_y := wheel.linear_velocity.y
	if is_instance_valid(_info_label):
		_info_label.position = wheel_pos + Vector3(1.2, 0.0, 0.0)
		_info_label.text = "disp: %+.2f m\nvel: %+.2f m/s" % [disp, vel_y]

	# --- Joint marker: pulse scale with displacement magnitude ---
	if is_instance_valid(_joint_marker):
		var pulse: float = 1.0 + clamp(abs(disp) * 0.6, 0.0, 0.6)
		_joint_marker.scale = Vector3.ONE * pulse

func _rebuild_trail() -> void:
	if _trail_pts.size() < 2:
		return
	var im := _trail_mesh.mesh as ImmediateMesh
	if not im:
		return
	im.clear_surfaces()
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	var count := _trail_pts.size()
	for i in count:
		var t := float(i) / float(count - 1)
		var alpha := t * 0.85 + 0.05
		# Fade from near-transparent tail to bright head
		im.surface_set_color(Color(COLOR_WHEEL.r, COLOR_WHEEL.g, COLOR_WHEEL.b, alpha))
		im.surface_add_vertex(_trail_pts[i])
	im.surface_end()

# -------------------------------------------------------------------------
# Cleanup
# -------------------------------------------------------------------------
func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
