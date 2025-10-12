# ===========================================================================
# NOC Example 6.6: Grab
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 6.6: VR Grabbable Objects
## Demonstrates VR hand grabbing with Generic6DOFJoint3D
## Chapter 06: Physics Libraries

var grabbable_objects: Array[VRRigidBody] = []
var ground: StaticBody3D

# VR controller simulation (placeholder for actual VR input)
var simulated_controller: Node3D
var controller_grabbed_object: VRRigidBody = null

# UI
var info_label: Label3D
var instructions_label: Label3D

func _ready():

	# Create UI
	create_info_labels()

	# Create ground
	create_ground()

	# Create grabbable objects
	create_grabbable_objects()

	# Create simulated controller
	create_simulated_controller()

	print("Example 6.6: VR Grabbable Objects - Click objects to grab/release")

func _process(_delta):
	# Simulate VR controller movement with mouse (placeholder)
	# In actual VR, this would track actual controller position
	update_simulated_controller()

func _input(event):
	# Simulate grab/release with mouse click
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if controller_grabbed_object:
			release_object()
		else:
			attempt_grab()

func create_info_labels():
	"""Create info labels"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.6, 0)
	info_label.text = "VR Grabbable Objects"
	add_child(info_label)

	instructions_label = Label3D.new()
	instructions_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	instructions_label.font_size = 20
	instructions_label.modulate = Color(0.8, 1.0, 0.8)
	instructions_label.position = Vector3(0, 0.5, 0)
	instructions_label.text = "[Click] Grab/Release\n[Move Mouse] Move Hand"
	add_child(instructions_label)

func create_ground():
	"""Create static ground"""
	ground = StaticBody3D.new()
	ground.position = Vector3(0, -0.45, 0)

	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.9, 0.02, 0.9)
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
	mesh_instance.material_override = material

	ground.add_child(mesh_instance)

	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.9, 0.02, 0.9)
	collision.shape = box_shape
	ground.add_child(collision)

	add_child(ground)

func create_grabbable_objects():
	"""Create various grabbable objects"""
	# Box
	create_box(Vector3(-0.2, 0, 0), Vector3(0.1, 0.1, 0.1))

	# Sphere
	create_sphere(Vector3(0, 0, 0), 0.06)

	# Cylinder
	create_cylinder(Vector3(0.2, 0, 0), 0.05, 0.15)

	# Small box
	create_box(Vector3(-0.1, 0.2, 0.1), Vector3(0.07, 0.07, 0.07))

	# Large sphere
	create_sphere(Vector3(0.1, 0.15, -0.1), 0.08)

func create_box(pos: Vector3, size: Vector3):
	"""Create grabbable box"""
	var box = VRRigidBody.new()
	box.position = pos
	box.use_pink_material = true

	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	box.mesh_instance = mesh_instance
	box.add_child(mesh_instance)

	box.create_box_shape(size)
	box.setup_pink_material()

	add_child(box)
	grabbable_objects.append(box)

func create_sphere(pos: Vector3, radius: float):
	"""Create grabbable sphere"""
	var sphere = VRRigidBody.new()
	sphere.position = pos
	sphere.use_pink_material = true

	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = radius
	sphere_mesh.height = radius * 2
	mesh_instance.mesh = sphere_mesh
	sphere.mesh_instance = mesh_instance
	sphere.add_child(mesh_instance)

	sphere.create_sphere_shape(radius)
	sphere.setup_pink_material()

	add_child(sphere)
	grabbable_objects.append(sphere)

func create_cylinder(pos: Vector3, radius: float, height: float):
	"""Create grabbable cylinder"""
	var cylinder = VRRigidBody.new()
	cylinder.position = pos
	cylinder.use_pink_material = true

	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.top_radius = radius
	cylinder_mesh.bottom_radius = radius
	cylinder_mesh.height = height
	mesh_instance.mesh = cylinder_mesh
	cylinder.mesh_instance = mesh_instance
	cylinder.add_child(mesh_instance)

	cylinder.create_cylinder_shape(radius, height)
	cylinder.setup_pink_material()

	add_child(cylinder)
	grabbable_objects.append(cylinder)

func create_simulated_controller():
	"""Create visual controller representation"""
	simulated_controller = Node3D.new()

	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.03
	mesh_instance.mesh = sphere_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 1.0, 0.3, 0.8)
	material.emission_enabled = true
	material.emission = Color(0.3, 1.0, 0.3, 1.0)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material

	simulated_controller.add_child(mesh_instance)
	simulated_controller.position = Vector3(0, 0, 0.3)

	add_child(simulated_controller)

func update_simulated_controller():
	"""Update controller position based on mouse (placeholder for VR)"""
	if not simulated_controller:
		return

	# Simple circular motion for demo
	var time = Time.get_ticks_msec() / 1000.0
	var radius = 0.2
	simulated_controller.position.x = cos(time) * radius
	simulated_controller.position.z = sin(time) * radius
	simulated_controller.position.y = 0.1 + sin(time * 2) * 0.1

	# Update grabbed object position
	if controller_grabbed_object:
		controller_grabbed_object.grab_update(simulated_controller)

func attempt_grab():
	"""Attempt to grab nearest object"""
	if not simulated_controller:
		return

	var nearest_object: VRRigidBody = null
	var nearest_distance: float = INF

	# Find nearest object within grab range
	for obj in grabbable_objects:
		var distance = simulated_controller.global_position.distance_to(obj.global_position)
		if distance < 0.15 and distance < nearest_distance:  # 15cm grab range
			nearest_object = obj
			nearest_distance = distance

	if nearest_object:
		controller_grabbed_object = nearest_object
		nearest_object.grab_start(simulated_controller)
		print("Grabbed: %s" % nearest_object.name)
		update_info_label()

func release_object():
	"""Release currently grabbed object"""
	if controller_grabbed_object:
		# Calculate throw velocity (simple version)
		var throw_velocity = controller_grabbed_object.linear_velocity

		controller_grabbed_object.grab_release(throw_velocity)
		print("Released: %s" % controller_grabbed_object.name)
		controller_grabbed_object = null
		update_info_label()

func update_info_label():
	"""Update info label"""
	if info_label:
		if controller_grabbed_object:
			info_label.text = "VR Grabbable Objects\nHolding: %s" % controller_grabbed_object.name
		else:
			info_label.text = "VR Grabbable Objects\nObjects: %d" % grabbable_objects.size()

func reset():
	"""Reset all objects"""
	if controller_grabbed_object:
		release_object()

	for obj in grabbable_objects:
		obj.queue_free()
	grabbable_objects.clear()

	create_grabbable_objects()
