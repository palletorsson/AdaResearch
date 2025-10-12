# ===========================================================================
# NOC Example 6.1: Basic RigidBody
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 6.1: Basic RigidBody Physics
## Introduction to Godot's native 3D physics engine
## Chapter 06: Physics Libraries

var boxes: Array[VRRigidBody] = []

# Ground plane
var ground: StaticBody3D

# UI
var info_label: Label3D

func _ready():

	# Create UI
	create_info_label()

	# Create ground
	create_ground()

	# Create a single falling box
	create_box(Vector3(0, 0.3, 0))

	print("Example 6.1: Basic RigidBody - Single falling box with gravity")

func create_info_label():
	"""Create info label"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.6, 0)
	info_label.text = "Basic RigidBody Physics\nSingle Box Falling"
	add_child(info_label)

func create_ground():
	"""Create static ground plane"""
	ground = StaticBody3D.new()
	ground.position = Vector3(0, -0.4, 0)

	# Create ground mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.8, 0.02, 0.8)
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.8, 0.8, 1.0)
	mesh_instance.material_override = material

	ground.add_child(mesh_instance)

	# Create collision shape
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.8, 0.02, 0.8)
	collision.shape = box_shape
	ground.add_child(collision)

	add_child(ground)

func create_box(position: Vector3, size: Vector3 = Vector3(0.1, 0.1, 0.1)):
	"""Create a falling box"""
	var box = VRRigidBody.new()
	box.position = position
	box.use_pink_material = true

	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_instance.mesh = box_mesh
	box.mesh_instance = mesh_instance
	box.add_child(mesh_instance)

	# Create collision shape
	box.create_box_shape(size)

	# Apply pink material
	box.setup_pink_material()

	# Connect collision signal
	box.body_entered.connect(_on_box_collision.bind(box))

	add_child(box)
	boxes.append(box)

func _on_box_collision(body: Node, box: VRRigidBody):
	"""Handle box collision"""
	print("Box collided with: %s" % body.name)

func spawn_box():
	"""Spawn a new box at random position"""
	var x = randf_range(-0.2, 0.2)
	var z = randf_range(-0.2, 0.2)
	create_box(Vector3(x, 0.4, z))

	# Update label
	info_label.text = "Basic RigidBody Physics\n%d Boxes" % boxes.size()

func reset():
	"""Reset scene"""
	for box in boxes:
		box.queue_free()
	boxes.clear()

	# Create single box again
	create_box(Vector3(0, 0.3, 0))
	info_label.text = "Basic RigidBody Physics\nSingle Box Falling"
