# ===========================================================================
# NOC Example 6.8: Collision Layers
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 6.8: Collision Layers and Masks
## Demonstrates selective collision using physics layers
## Chapter 06: Physics Libraries

var group_a_objects: Array[RigidBody3D] = []
var group_b_objects: Array[RigidBody3D] = []
var group_c_objects: Array[RigidBody3D] = []
var ground: StaticBody3D

# Collision layers (Godot supports 32 layers)
const LAYER_GROUND = 1      # Layer 1
const LAYER_GROUP_A = 2     # Layer 2 (Pink)
const LAYER_GROUP_B = 4     # Layer 3 (Blue)
const LAYER_GROUP_C = 8     # Layer 4 (Green)

# Spawn control
var spawn_timer: float = 0.0
var auto_spawn: bool = true

# UI
var info_label: Label3D
var legend_label: Label3D

# Current spawn mode
var spawn_mode: int = 0  # 0=A, 1=B, 2=C

func _ready():

	# Create UI
	create_ui_labels()

	# Create ground
	create_ground()

	# Create initial objects
	spawn_object_a(Vector3(-0.2, 0.3, 0))
	spawn_object_b(Vector3(0, 0.3, 0))
	spawn_object_c(Vector3(0.2, 0.3, 0))

	print("Example 6.8: Collision Layers - Selective collision demonstration")

func _process(delta):
	if auto_spawn:
		spawn_timer += delta
		if spawn_timer >= 1.5:
			spawn_timer = 0.0
			spawn_random_object()

	cleanup_fallen_objects()
	update_info_label()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1:
			spawn_mode = 0
			spawn_object_a(Vector3(randf_range(-0.2, 0.2), 0.4, randf_range(-0.2, 0.2)))
		elif event.keycode == KEY_2:
			spawn_mode = 1
			spawn_object_b(Vector3(randf_range(-0.2, 0.2), 0.4, randf_range(-0.2, 0.2)))
		elif event.keycode == KEY_3:
			spawn_mode = 2
			spawn_object_c(Vector3(randf_range(-0.2, 0.2), 0.4, randf_range(-0.2, 0.2)))
		elif event.keycode == KEY_R:
			reset()
		elif event.keycode == KEY_T:
			auto_spawn = !auto_spawn

func create_ui_labels():
	"""Create UI labels"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.6, 0)
	add_child(info_label)

	legend_label = Label3D.new()
	legend_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	legend_label.font_size = 16
	legend_label.modulate = Color(0.9, 0.9, 0.9)
	legend_label.position = Vector3(0, 0.45, 0)
	legend_label.text = """PINK: Collides with Ground + Pink
BLUE: Collides with Ground + Blue
GREEN: Collides with Ground only
[1/2/3] Spawn | [R] Reset"""
	add_child(legend_label)

func update_info_label():
	"""Update info label"""
	if info_label:
		info_label.text = "Collision Layers\nP:%d B:%d G:%d" % [group_a_objects.size(), group_b_objects.size(), group_c_objects.size()]

func create_ground():
	"""Create ground with layer 1"""
	ground = StaticBody3D.new()
	ground.position = Vector3(0, -0.45, 0)
	ground.collision_layer = LAYER_GROUND
	ground.collision_mask = LAYER_GROUP_A | LAYER_GROUP_B | LAYER_GROUP_C
	add_child(ground)

	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.9, 0.02, 0.9)
	mesh_instance.mesh = box

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7, 1.0)
	mesh_instance.material_override = material

	ground.add_child(mesh_instance)

	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.9, 0.02, 0.9)
	collision.shape = box_shape
	ground.add_child(collision)

func spawn_random_object():
	"""Spawn random object type"""
	var x = randf_range(-0.25, 0.25)
	var z = randf_range(-0.25, 0.25)
	var pos = Vector3(x, 0.4, z)

	var choice = randi() % 3
	match choice:
		0: spawn_object_a(pos)
		1: spawn_object_b(pos)
		2: spawn_object_c(pos)

func spawn_object_a(pos: Vector3):
	"""Spawn Group A (Pink) - Collides with Ground + Group A only"""
	var obj = create_object(
		pos,
		Color(1.0, 0.6, 1.0),  # Pink
		LAYER_GROUP_A,
		LAYER_GROUND | LAYER_GROUP_A  # Collides with ground and other A objects
	)
	group_a_objects.append(obj)

func spawn_object_b(pos: Vector3):
	"""Spawn Group B (Blue) - Collides with Ground + Group B only"""
	var obj = create_object(
		pos,
		Color(0.5, 0.5, 1.0),  # Blue
		LAYER_GROUP_B,
		LAYER_GROUND | LAYER_GROUP_B  # Collides with ground and other B objects
	)
	group_b_objects.append(obj)

func spawn_object_c(pos: Vector3):
	"""Spawn Group C (Green) - Collides with Ground ONLY (passes through all objects)"""
	var obj = create_object(
		pos,
		Color(0.5, 1.0, 0.5),  # Green
		LAYER_GROUP_C,
		LAYER_GROUND  # Only collides with ground (ghost through other objects!)
	)
	group_c_objects.append(obj)

func create_object(pos: Vector3, color: Color, layer: int, mask: int) -> RigidBody3D:
	"""Create physics object with specified collision layer/mask"""
	var obj = RigidBody3D.new()
	obj.position = pos
	obj.mass = 0.5

	# Set collision layer and mask
	obj.collision_layer = layer
	obj.collision_mask = mask

	add_child(obj)

	# Random shape (box or sphere)
	var use_sphere = randf() > 0.5

	if use_sphere:
		# Sphere
		var mesh_instance = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.05
		mesh_instance.mesh = sphere

		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.5
		material.emission_energy_multiplier = 0.6
		mesh_instance.material_override = material

		obj.add_child(mesh_instance)

		var collision = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = 0.05
		collision.shape = sphere_shape
		obj.add_child(collision)
	else:
		# Box
		var size = Vector3(0.08, 0.08, 0.08)
		var mesh_instance = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = size
		mesh_instance.mesh = box

		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.5
		material.emission_energy_multiplier = 0.6
		mesh_instance.material_override = material

		obj.add_child(mesh_instance)

		var collision = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = size
		collision.shape = box_shape
		obj.add_child(collision)

	# Random rotation
	obj.rotation = Vector3(randf() * TAU, randf() * TAU, randf() * TAU)

	return obj

func cleanup_fallen_objects():
	"""Remove objects that fell too far"""
	var all_objects = group_a_objects + group_b_objects + group_c_objects
	var to_remove: Array[RigidBody3D] = []

	for obj in all_objects:
		if obj.global_position.y < -1.0:
			to_remove.append(obj)

	for obj in to_remove:
		group_a_objects.erase(obj)
		group_b_objects.erase(obj)
		group_c_objects.erase(obj)
		obj.queue_free()

func reset():
	"""Reset scene"""
	# Clear all objects
	for obj in group_a_objects:
		obj.queue_free()
	group_a_objects.clear()

	for obj in group_b_objects:
		obj.queue_free()
	group_b_objects.clear()

	for obj in group_c_objects:
		obj.queue_free()
	group_c_objects.clear()

	spawn_timer = 0.0

	# Spawn initial objects
	spawn_object_a(Vector3(-0.2, 0.3, 0))
	spawn_object_b(Vector3(0, 0.3, 0))
	spawn_object_c(Vector3(0.2, 0.3, 0))
