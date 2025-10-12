# ===========================================================================
# NOC Example 6.4: Windmill
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 6.4: Windmill
## Demonstrates HingeJoint3D with motor
## Chapter 06: Physics Libraries

var windmill: Node3D
var blades: RigidBody3D
var pole: StaticBody3D
var hinge_joint: HingeJoint3D

# UI
var info_label: Label3D
var speed_controller: ParameterController3D
var motor_speed: float = 2.0

func _ready():

	# Create UI
	create_info_label()
	create_speed_controller()

	# Create windmill
	create_windmill()

	print("Example 6.4: Windmill - HingeJoint3D with motor")

func _process(_delta):
	update_info_label()

	# Update motor speed based on controller
	if hinge_joint:
		hinge_joint.set("motor/target_velocity", motor_speed)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			motor_speed = clamp(motor_speed + 0.5, -10.0, 10.0)
		elif event.keycode == KEY_DOWN:
			motor_speed = clamp(motor_speed - 0.5, -10.0, 10.0)
		elif event.keycode == KEY_SPACE:
			motor_speed = 0.0
		elif event.keycode == KEY_R:
			motor_speed = 2.0

func create_info_label():
	"""Create info label"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.6, 0)
	add_child(info_label)

func update_info_label():
	"""Update info label"""
	if info_label:
		info_label.text = "Windmill (HingeJoint3D)\nMotor Speed: %.1f" % motor_speed

func _on_speed_changed(new_speed: float):
	"""Update motor speed from controller"""
	motor_speed = new_speed
	print("Motor speed changed to: %.1f" % motor_speed)

func create_speed_controller():
	"""Create 3D slider for motor speed"""
	speed_controller = ParameterController3D.new()
	speed_controller.parameter_name = "Motor Speed"
	speed_controller.min_value = -10.0
	speed_controller.max_value = 10.0
	speed_controller.default_value = motor_speed
	speed_controller.step_size = 0.5
	speed_controller.position = Vector3(0, 0.5, 0)
	speed_controller.value_changed.connect(_on_speed_changed)
	add_child(speed_controller)
	
	var instructions = Label3D.new()
	instructions.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions.font_size = 18
	instructions.modulate = Color(0.8, 1.0, 0.8)
	instructions.position = Vector3(0, 0.4, 0)
	instructions.text = "[↑/↓] Speed | [SPACE] Stop | [R] Reset"
	add_child(instructions)

func create_windmill():
	"""Create windmill structure"""
	windmill = Node3D.new()
	windmill.position = Vector3(0, 0, 0)
	add_child(windmill)

	# Create static pole
	create_pole()

	# Create rotating blades
	create_blades()

	# Create hinge joint connecting pole and blades
	create_hinge()

func create_pole():
	"""Create static pole (base)"""
	pole = StaticBody3D.new()
	pole.position = Vector3(0, -0.1, 0)
	windmill.add_child(pole)

	# Pole mesh (vertical cylinder)
	var mesh_instance = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 0.3
	mesh_instance.mesh = cylinder

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.6, 0.6, 0.6, 1.0)
	mesh_instance.material_override = material

	pole.add_child(mesh_instance)

	# Collision
	var collision = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 0.02
	cyl_shape.height = 0.3
	collision.shape = cyl_shape
	pole.add_child(collision)

	# Hub at top (connection point)
	var hub = MeshInstance3D.new()
	var hub_sphere = SphereMesh.new()
	hub_sphere.radius = 0.03
	hub.mesh = hub_sphere
	hub.position = Vector3(0, 0.15, 0)
	hub.material_override = material
	pole.add_child(hub)

func create_blades():
	"""Create rotating blade assembly"""
	blades = RigidBody3D.new()
	blades.position = Vector3(0, 0.05, 0)  # At top of pole
	blades.mass = 1.0
	blades.gravity_scale = 0.0  # No gravity on blades
	windmill.add_child(blades)

	# Create 4 blades in cross pattern
	var blade_material = StandardMaterial3D.new()
	blade_material.albedo_color = Color(1.0, 0.6, 1.0, 1.0)
	blade_material.emission_enabled = true
	blade_material.emission = Color(1.0, 0.6, 1.0) * 0.4
	blade_material.emission_energy_multiplier = 0.6

	# Blade 1 (+X)
	create_blade(blades, Vector3(0.1, 0, 0), Vector3(0.15, 0.02, 0.04), blade_material)
	# Blade 2 (-X)
	create_blade(blades, Vector3(-0.1, 0, 0), Vector3(0.15, 0.02, 0.04), blade_material)
	# Blade 3 (+Z)
	create_blade(blades, Vector3(0, 0, 0.1), Vector3(0.04, 0.02, 0.15), blade_material)
	# Blade 4 (-Z)
	create_blade(blades, Vector3(0, 0, -0.1), Vector3(0.04, 0.02, 0.15), blade_material)

	# Center hub
	var center = MeshInstance3D.new()
	var center_sphere = SphereMesh.new()
	center_sphere.radius = 0.04
	center.mesh = center_sphere
	center.material_override = blade_material
	blades.add_child(center)

	# Center collision
	var center_collision = CollisionShape3D.new()
	var center_shape = SphereShape3D.new()
	center_shape.radius = 0.04
	center_collision.shape = center_shape
	blades.add_child(center_collision)

func create_blade(parent: RigidBody3D, pos: Vector3, size: Vector3, mat: Material):
	"""Create single blade"""
	# Mesh
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.material_override = mat
	parent.add_child(mesh_instance)

	# Collision
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = size
	collision.shape = box_shape
	collision.position = pos
	parent.add_child(collision)

func create_hinge():
	"""Create hinge joint connecting pole and blades"""
	hinge_joint = HingeJoint3D.new()
	hinge_joint.node_a = pole.get_path()
	hinge_joint.node_b = blades.get_path()

	# Position at connection point
	hinge_joint.position = Vector3(0, 0.05, 0)

	# Hinge rotates around Y-axis (vertical)
	# The axis is relative to the joint's local space
	hinge_joint.set("angular_limit/enable", false)  # Free rotation

	# Enable motor
	hinge_joint.set("motor/enable", true)
	hinge_joint.set("motor/target_velocity", motor_speed)
	hinge_joint.set("motor/max_impulse", 10.0)

	windmill.add_child(hinge_joint)

func reset():
	"""Reset windmill"""
	if blades:
		blades.angular_velocity = Vector3.ZERO
		blades.rotation = Vector3.ZERO

	motor_speed = 2.0

	if hinge_joint:
		hinge_joint.set("motor/target_velocity", motor_speed)
