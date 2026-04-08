# @identity
# essence: hinge(motor) → pin → slider. Rotary-to-linear conversion through composed constraints.
# desire: To turn a wheel and watch a rod pump — the fundamental crank-slider mechanism.
# critical_parameter: hinge motor TARGET_VELOCITY (2.5) — controls rotation speed and therefore pumping frequency.
# triggers: Automatic — hinge motor drives continuously from ready.
# emerges: Reciprocating linear motion from continuous rotation. The geometry of constraint creating mechanical advantage.
# needs: Motor-driven rotation [has], slider guide [has]. Missing: speed control, force readout.
# relationships: Combines three joint types (hinge+pin+slider). Contrasts with SliderPress (pure translation). Pairs with DrawbridgeHinge (pure rotation).
# truth: Every engine is a conversation between rotation and translation. The crank is the translator.

extends "res://algorithms/joint/shared/joint_demo_base.gd"
class_name HingeCrankDemo

var wheel: RigidBody3D
var rod: RigidBody3D

# --- Visual additions ---
var _trail_points: Array[Vector3] = []
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _max_trail_length: int = 200
var _joint_markers: Array[MeshInstance3D] = []
var _info_label: Label3D

# Colors
const COLOR_AXLE  := Color(0.35, 0.38, 0.45)
const COLOR_WHEEL := Color(0.95, 0.45, 0.15)   # warm orange-red (mover)
const COLOR_ROD   := Color(0.15, 0.75, 0.95)   # cyan
const COLOR_JOINT := Color(1.0, 0.55, 0.1)     # orange joint markers
const COLOR_TRAIL := Color(0.15, 0.75, 0.95, 0.3)

func _make_emissive(color: Color, energy: float = 1.5) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.4
	mat.emission_energy_multiplier = energy
	mat.metallic = 0.3
	mat.roughness = 0.4
	return mat

func _build_demo() -> void:
	# --- Axle block (static anchor) ---
	var base := StaticBody3D.new()
	base.name = "AxleBlock"
	base.position = Vector3(0.0, 2.0, 0.0)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.6, 0.6, 0.6)
	collider.shape = shape
	base.add_child(collider)
	var base_mesh := MeshInstance3D.new()
	var base_box := BoxMesh.new()
	base_box.size = Vector3(0.6, 0.6, 0.6)
	base_mesh.mesh = base_box
	# Subtle emissive frame material
	var axle_mat := StandardMaterial3D.new()
	axle_mat.albedo_color = COLOR_AXLE
	axle_mat.emission_enabled = true
	axle_mat.emission = COLOR_AXLE * 0.15
	axle_mat.emission_energy_multiplier = 0.5
	axle_mat.roughness = 0.6
	base_mesh.material_override = axle_mat
	base.add_child(base_mesh)
	add_child(base)

	# --- Wheel (mover — warm emissive) ---
	wheel = create_cylinder("CrankWheel", 0.9, 0.3, Vector3(0.0, 2.0, 0.0), 3.0, COLOR_WHEEL)
	wheel.physics_material_override = PhysicsMaterial.new()
	wheel.physics_material_override.friction = 0.4
	var wheel_mesh: MeshInstance3D = wheel.get_child(1)
	wheel_mesh.material_override = _make_emissive(COLOR_WHEEL, 2.0)

	# --- Connecting rod (cyan emissive) ---
	rod = create_box("ConnectingRod", Vector3(1.8, 0.2, 0.2), Vector3(1.8, 2.0, 0.0), 1.5, COLOR_ROD)
	var rod_mesh: MeshInstance3D = rod.get_child(1)
	rod_mesh.material_override = _make_emissive(COLOR_ROD, 1.5)

	# --- Hinge joint (motor) ---
	var hinge := HingeJoint3D.new()
	hinge.name = "WheelHinge"
	hinge.node_a = base.get_path()
	hinge.node_b = wheel.get_path()
	hinge.position = base.position
	hinge.rotation = Vector3.ZERO
	hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 2.5)
	hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, false)
	add_child(hinge)

	# --- Pin joint (crank pin connecting wheel rim to rod) ---
	var link := PinJoint3D.new()
	link.name = "RodLink"
	link.node_a = wheel.get_path()
	link.node_b = rod.get_path()
	link.position = wheel.position + Vector3(0.9, 0.0, 0.0)
	link.set_exclude_nodes_from_collision(true)
	add_child(link)

	# --- Slider joint (rod guide) ---
	var guide := SliderJoint3D.new()
	guide.name = "RodGuide"
	guide.node_a = base.get_path()
	guide.node_b = rod.get_path()
	guide.position = Vector3(2.5, 2.0, 0.0)
	guide.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, -0.8)
	guide.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, 0.8)
	add_child(guide)

	# --- Joint markers (glowing orange spheres at constraint positions) ---
	var joint_positions: Array[Vector3] = [
		base.position,                                   # wheel axle / hinge
		wheel.position + Vector3(0.9, 0.0, 0.0),        # crank pin / rod link
		Vector3(2.5, 2.0, 0.0),                         # slider guide
	]
	for pos in joint_positions:
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.10
		sphere.height = 0.20
		marker.mesh = sphere
		marker.material_override = _make_emissive(COLOR_JOINT, 2.5)
		marker.position = pos
		add_child(marker)
		_joint_markers.append(marker)

	# --- Trail (rod tip motion history) ---
	_setup_trail()

	# --- Info label ---
	_info_label = Label3D.new()
	_info_label.font_size = 16
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.modulate = Color(1, 1, 1, 0.8)
	_info_label.position = Vector3(1.5, 3.8, 0.0)
	add_child(_info_label)

	add_label("Powered Hinge Crank", Vector3(1.5, 3.5, 2.5))

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.mesh = _trail_mesh
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = COLOR_TRAIL
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.emission_enabled = true
	trail_mat.emission = Color(COLOR_ROD.r, COLOR_ROD.g, COLOR_ROD.b) * 0.3
	trail_mat.emission_energy_multiplier = 0.8
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_instance.material_override = trail_mat
	add_child(_trail_instance)

func _process(_delta: float) -> void:
	if not is_instance_valid(rod):
		return

	# Trail follows the far tip of the connecting rod
	var tip := rod.global_position + rod.global_transform.basis.x * 0.9
	_trail_points.append(tip)
	if _trail_points.size() > _max_trail_length:
		_trail_points.remove_at(0)
	_update_trail()

	# Info label: motor RPM derived from wheel angular velocity + rod X position
	if is_instance_valid(wheel):
		var ang_vel := wheel.angular_velocity.length()
		var rpm := ang_vel * 60.0 / TAU
		var rod_x := rod.position.x
		_info_label.text = "RPM: %.1f  rod: %.2f m" % [rpm, rod_x]

func _update_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return
	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _trail_points:
		_trail_mesh.surface_add_vertex(point)
	_trail_mesh.surface_end()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
