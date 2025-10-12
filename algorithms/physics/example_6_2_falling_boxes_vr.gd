# ===========================================================================
# NOC Example 6.2: Falling Boxes
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 6.2: Falling Boxes
## Multiple RigidBody boxes with random properties
## Chapter 06: Physics Libraries

@export var num_boxes: int = 10
@export var spawn_interval: float = 0.5
@export var max_boxes: int = 30

var boxes: Array[VRRigidBody] = []
var ground: StaticBody3D

# Spawn timer
var spawn_timer: float = 0.0
var auto_spawn: bool = true

# UI
var info_label: Label3D

# Box variations
var box_colors: Array[Color] = [
	Color(1.0, 0.6, 1.0, 1.0),   # Bright pink
	Color(0.9, 0.5, 0.8, 1.0),   # Medium pink
	Color(0.8, 0.4, 0.7, 1.0),   # Dark pink
	Color(1.0, 0.7, 0.9, 1.0),   # Light pink
]

func _ready():

	# Create UI
	create_info_label()

	# Create ground
	create_ground()

	# Create initial boxes
	for i in range(num_boxes):
		spawn_box()

	print("Example 6.2: Falling Boxes - %d boxes spawning" % num_boxes)

func _process(delta):
	if auto_spawn and boxes.size() < max_boxes:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			spawn_box()

	# Clean up boxes that fell too far
	cleanup_fallen_boxes()

	update_info_label()

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
		info_label.text = "Falling Boxes\nActive: %d / %d" % [boxes.size(), max_boxes]

func create_ground():
	"""Create static ground plane"""
	ground = StaticBody3D.new()
	ground.position = Vector3(0, -0.45, 0)

	# Create ground mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.9, 0.02, 0.9)
	mesh_instance.mesh = box_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
	mesh_instance.material_override = material

	ground.add_child(mesh_instance)

	# Create collision shape
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.9, 0.02, 0.9)
	collision.shape = box_shape
	ground.add_child(collision)

	add_child(ground)

func spawn_box():
	"""Spawn a new box with random properties"""
	# Random position at top of tank
	var x = randf_range(-0.3, 0.3)
	var z = randf_range(-0.3, 0.3)
	var y = 0.4

	# Random size
	var size = Vector3(
		randf_range(0.05, 0.12),
		randf_range(0.05, 0.12),
		randf_range(0.05, 0.12)
	)

	# Random mass (affects fall speed and collision)
	var mass = randf_range(0.5, 2.0)

	create_box(Vector3(x, y, z), size, mass)

func create_box(pos: Vector3, size: Vector3, mass: float = 1.0):
	"""Create a box with specified properties"""
	var box = VRRigidBody.new()
	box.position = pos
	box.mass = mass
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

	# Random pink color
	var color = box_colors[randi() % box_colors.size()]
	box.setup_pink_material()
	box.set_custom_color(color)

	# Random initial rotation
	box.rotation = Vector3(
		randf() * TAU,
		randf() * TAU,
		randf() * TAU
	)

	# Connect collision
	box.body_entered.connect(_on_box_collision)

	add_child(box)
	boxes.append(box)

func _on_box_collision(body: Node):
	"""Handle box collision"""
	# Collision feedback handled in VRRigidBody

func cleanup_fallen_boxes():
	"""Remove boxes that fell too far below ground"""
	var boxes_to_remove: Array[VRRigidBody] = []

	for box in boxes:
		if box.global_position.y < -1.0:
			boxes_to_remove.append(box)

	for box in boxes_to_remove:
		boxes.erase(box)
		box.queue_free()

func toggle_auto_spawn():
	"""Toggle automatic spawning"""
	auto_spawn = !auto_spawn
	print("Auto-spawn: %s" % ("ON" if auto_spawn else "OFF"))

func clear_boxes():
	"""Clear all boxes"""
	for box in boxes:
		box.queue_free()
	boxes.clear()

func reset():
	"""Reset scene"""
	clear_boxes()
	spawn_timer = 0.0

	# Spawn initial boxes
	for i in range(num_boxes):
		spawn_box()
