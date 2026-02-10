extends Node3D

class_name GadgetBase

# Base class for all vector gadgets with physics joint helpers.
# Override update_from_vectors() to drive the gadget from vector values.

# Colors matching the vector scene palette
const COLOR_RED := Color(1.0, 0.3, 0.3)
const COLOR_GREEN := Color(0.3, 1.0, 0.3)
const COLOR_BLUE := Color(0.3, 0.5, 1.0)
const COLOR_ORANGE := Color(1.0, 0.55, 0.2)
const COLOR_CYAN := Color(0.3, 0.8, 0.9)
const COLOR_YELLOW := Color(0.95, 0.85, 0.2)
const COLOR_MAGENTA := Color(0.8, 0.4, 0.9)
const COLOR_METAL := Color(0.45, 0.48, 0.52)
const COLOR_DARK_METAL := Color(0.2, 0.22, 0.25)
const COLOR_FRAME := Color(0.15, 0.16, 0.18)

# Material cache to avoid duplicates within this gadget
var _materials: Dictionary = {}

# Called by the parent scene every frame with current vector values.
# Override in subclass.
func update_from_vectors(_a: Vector3, b: Vector3) -> void:
	pass

# â”€â”€â”€ BODY HELPERS â”€â”€â”€

func create_static_body(pos: Vector3, mesh: Mesh, color: Color, body_name: String = "Static") -> StaticBody3D:
	var body = StaticBody3D.new()
	body.name = body_name
	body.position = pos

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.material_override = get_material(color)
	body.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	col.shape = _shape_from_mesh(mesh)
	body.add_child(col)

	add_child(body)
	return body

func create_rigid_body(pos: Vector3, mesh: Mesh, color: Color, mass: float = 1.0, body_name: String = "Rigid") -> RigidBody3D:
	var body = RigidBody3D.new()
	body.name = body_name
	body.position = pos
	body.mass = mass
	body.can_sleep = false
	body.linear_damp = 0.5
	body.angular_damp = 1.0

	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.material_override = get_material(color)
	body.add_child(mesh_inst)

	var col = CollisionShape3D.new()
	col.shape = _shape_from_mesh(mesh)
	body.add_child(col)

	add_child(body)
	return body

# â”€â”€â”€ JOINT HELPERS â”€â”€â”€

func create_hinge_joint(body_a: PhysicsBody3D, body_b: PhysicsBody3D, anchor_pos: Vector3,
		hinge_axis_rotation: Vector3 = Vector3.ZERO, enable_motor: bool = true,
		motor_max_impulse: float = 60.0, joint_name: String = "Hinge") -> HingeJoint3D:
	var hinge = HingeJoint3D.new()
	hinge.name = joint_name
	hinge.position = anchor_pos
	hinge.rotation_degrees = hinge_axis_rotation
	hinge.node_a = body_a.get_path()
	hinge.node_b = body_b.get_path()
	hinge.set_exclude_nodes_from_collision(true)

	if enable_motor:
		hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, motor_max_impulse)
		hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.0)

	add_child(hinge)
	return hinge

func create_slider_joint(body_a: PhysicsBody3D, body_b: PhysicsBody3D, anchor_pos: Vector3,
		lower_limit: float = -1.0, upper_limit: float = 1.0,
		joint_name: String = "Slider") -> SliderJoint3D:
	var slider = SliderJoint3D.new()
	slider.name = joint_name
	slider.position = anchor_pos
	slider.node_a = body_a.get_path()
	slider.node_b = body_b.get_path()
	slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, lower_limit)
	slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, upper_limit)
	slider.set_exclude_nodes_from_collision(true)

	add_child(slider)
	return slider

func create_spring_joint(body_a: PhysicsBody3D, body_b: PhysicsBody3D, anchor_pos: Vector3,
		spring_axis: String = "y", stiffness: float = 30.0, damping: float = 3.5,
		lower_limit: float = -0.6, upper_limit: float = 0.25,
		joint_name: String = "Spring") -> Generic6DOFJoint3D:
	var joint = Generic6DOFJoint3D.new()
	joint.name = joint_name
	joint.position = anchor_pos
	joint.node_a = body_a.get_path()
	joint.node_b = body_b.get_path()
	joint.set_exclude_nodes_from_collision(true)

	# Lock all axes by default
	for axis_call in ["set_flag_x", "set_flag_y", "set_flag_z"]:
		joint.call(axis_call, Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	for axis_call in ["set_param_x", "set_param_y", "set_param_z"]:
		joint.call(axis_call, Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
		joint.call(axis_call, Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)

	# Enable spring on requested axis
	var flag_fn = "set_flag_" + spring_axis
	var param_fn = "set_param_" + spring_axis
	joint.call(flag_fn, Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
	joint.call(param_fn, Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, lower_limit)
	joint.call(param_fn, Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, upper_limit)
	joint.call(flag_fn, Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true)
	joint.call(param_fn, Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, stiffness)
	joint.call(param_fn, Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, damping)

	add_child(joint)
	return joint

# â”€â”€â”€ MESH HELPERS â”€â”€â”€

func make_box_mesh(size: Vector3) -> BoxMesh:
	var m = BoxMesh.new()
	m.size = size
	return m

func make_cylinder_mesh(radius: float, height: float) -> CylinderMesh:
	var m = CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = 16
	return m

func make_sphere_mesh(radius: float) -> SphereMesh:
	var m = SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 16
	m.rings = 8
	return m

func make_torus_mesh(inner_radius: float, outer_radius: float) -> TorusMesh:
	var m = TorusMesh.new()
	m.inner_radius = inner_radius
	m.outer_radius = outer_radius
	m.ring_segments = 24
	m.rings = 12
	return m

# â”€â”€â”€ MATERIAL HELPERS â”€â”€â”€

func get_material(color: Color, unlit: bool = false) -> StandardMaterial3D:
	var key = str(color) + ("_u" if unlit else "_l")
	if _materials.has(key):
		return _materials[key]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if unlit:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = color * 0.8
	else:
		mat.roughness = 0.6
		mat.metallic = 0.3
	_materials[key] = mat
	return mat

func get_emissive_material(color: Color, strength: float = 1.0) -> StandardMaterial3D:
	var key = str(color) + "_e" + str(strength)
	if _materials.has(key):
		return _materials[key]

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = strength
	mat.roughness = 0.4
	mat.metallic = 0.2
	_materials[key] = mat
	return mat

# â”€â”€â”€ VISUAL HELPERS â”€â”€â”€

func add_mesh_child(parent: Node3D, mesh: Mesh, material: StandardMaterial3D, pos: Vector3 = Vector3.ZERO, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi

func create_label(text: String, pos: Vector3, font_size: int = 18, color: Color = Color.WHITE) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.position = pos
	label.pixel_size = 0.001
	label.font_size = font_size
	label.modulate = color
	label.no_depth_test = true
	label.render_priority = 100
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 3
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.7)
	add_child(label)
	return label

# â”€â”€â”€ INTERNAL â”€â”€â”€

func _shape_from_mesh(mesh: Mesh) -> Shape3D:
	if mesh is BoxMesh:
		var shape = BoxShape3D.new()
		shape.size = mesh.size
		return shape
	elif mesh is CylinderMesh:
		var shape = CylinderShape3D.new()
		shape.radius = mesh.top_radius
		shape.height = mesh.height
		return shape
	elif mesh is SphereMesh:
		var shape = SphereShape3D.new()
		shape.radius = mesh.radius
		return shape
	else:
		# Fallback: small box
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.1, 0.1, 0.1)
		return shape
