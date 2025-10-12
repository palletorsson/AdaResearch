class_name VRRigidBody
extends RigidBody3D

## VR-friendly RigidBody wrapper for Nature of Code physics examples
## Chapter 06: Physics Libraries
## Wraps Godot's native RigidBody3D with VR grab support

# Visual representation
var mesh_instance: MeshInstance3D
var material: StandardMaterial3D

# Pink color palette
var primary_pink: Color = Color(1.0, 0.6, 1.0, 1.0)
var secondary_pink: Color = Color(0.9, 0.5, 0.8, 1.0)

# VR grab state
var is_grabbed: bool = false
var grab_joint: Generic6DOFJoint3D = null
var grab_anchor: Node3D = null

# Fish tank reference
var fish_tank: FishTank = null

# Custom properties
@export var use_pink_material: bool = true
@export var show_collision_shape: bool = true

func _ready():
	# Set up physics properties
	contact_monitor = true
	max_contacts_reported = 4

	# Find fish tank
	find_fish_tank()

	# Setup visuals
	if not mesh_instance:
		setup_default_mesh()

	if use_pink_material:
		setup_pink_material()

func find_fish_tank():
	"""Find FishTank parent in scene tree"""
	var node = get_parent()
	while node:
		if node is FishTank:
			fish_tank = node
			return
		node = node.get_parent()

func setup_default_mesh():
	"""Create default box mesh if none exists"""
	mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.1, 0.1, 0.1)
	mesh_instance.mesh = box
	add_child(mesh_instance)

func setup_pink_material():
	"""Apply pink material"""
	material = StandardMaterial3D.new()
	material.albedo_color = primary_pink
	material.emission_enabled = true
	material.emission = primary_pink * 0.4
	material.emission_energy_multiplier = 0.6

	if mesh_instance:
		mesh_instance.material_override = material

func set_custom_color(color: Color):
	"""Set custom color"""
	if material:
		material.albedo_color = color
		material.emission = color * 0.4

func create_box_shape(size: Vector3):
	"""Create box collision shape"""
	var shape = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	add_child(shape)

func create_sphere_shape(radius: float):
	"""Create sphere collision shape"""
	var shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = radius
	shape.shape = sphere_shape
	add_child(shape)

func create_cylinder_shape(radius: float, height: float):
	"""Create cylinder collision shape"""
	var shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius = radius
	cylinder_shape.height = height
	shape.shape = cylinder_shape
	add_child(shape)

# --- VR Grab System ---

func grab_start(controller: Node3D):
	"""Called when VR controller grabs this object"""
	if is_grabbed:
		return

	is_grabbed = true

	# Create anchor point for joint
	grab_anchor = Node3D.new()
	get_parent().add_child(grab_anchor)
	grab_anchor.global_position = controller.global_position

	# Create 6DOF joint
	grab_joint = Generic6DOFJoint3D.new()
	grab_joint.node_a = grab_anchor.get_path()
	grab_joint.node_b = get_path()
	get_parent().add_child(grab_joint)

	# Configure joint for rigid grab
	for axis in range(3):
		grab_joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		grab_joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		grab_joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)

	# Highlight when grabbed
	if material:
		material.emission_energy_multiplier = 1.2

func grab_update(controller: Node3D):
	"""Update grab position while held"""
	if is_grabbed and grab_anchor:
		grab_anchor.global_position = controller.global_position
		grab_anchor.global_rotation = controller.global_rotation

func grab_release(throw_velocity: Vector3 = Vector3.ZERO):
	"""Release from VR controller"""
	if not is_grabbed:
		return

	is_grabbed = false

	# Remove joint
	if grab_joint:
		grab_joint.queue_free()
		grab_joint = null

	# Remove anchor
	if grab_anchor:
		grab_anchor.queue_free()
		grab_anchor = null

	# Apply throw velocity
	if throw_velocity.length() > 0:
		linear_velocity = throw_velocity

	# Reset highlight
	if material:
		material.emission_energy_multiplier = 0.6

# --- Collision Events ---

func _on_body_entered(body: Node):
	"""Handle collision with another body"""
	if material:
		# Flash brighter on collision
		material.emission_energy_multiplier = 1.5
		await get_tree().create_timer(0.1).timeout
		if material:
			material.emission_energy_multiplier = 0.6 if not is_grabbed else 1.2

# --- Constraints ---

func constrain_to_tank():
	"""Keep object inside fish tank boundaries"""
	if not fish_tank:
		return

	var pos = global_position
	var half_size = fish_tank.tank_size / 2.0

	# Clamp position
	pos.x = clamp(pos.x, -half_size, half_size)
	pos.y = clamp(pos.y, -half_size, half_size)
	pos.z = clamp(pos.z, -half_size, half_size)

	# Apply if outside bounds
	if pos != global_position:
		global_position = pos
		# Reverse velocity if hit boundary
		if abs(pos.x) >= half_size:
			linear_velocity.x *= -0.5
		if abs(pos.y) >= half_size:
			linear_velocity.y *= -0.5
		if abs(pos.z) >= half_size:
			linear_velocity.z *= -0.5
