# ===========================================================================
# NOC Example 6.3: Compound Bodies
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 6.3: Compound Bodies
## Objects made from multiple collision shapes
## Chapter 06: Physics Libraries

var compound_objects: Array[VRRigidBody] = []
var ground: StaticBody3D

# Spawn controls
var spawn_timer: float = 0.0
var auto_spawn: bool = true
@export var spawn_interval: float = 2.0
@export var max_objects: int = 8

# UI
var info_label: Label3D
var type_label: Label3D

# Object type to spawn
var current_type: int = 0
var type_names: Array[String] = ["Dumbbell", "T-Shape", "L-Shape", "Cross"]

func _ready():

	# Create UI
	create_ui_labels()

	# Create ground
	create_ground()

	# Spawn initial compound objects
	spawn_dumbbell(Vector3(-0.2, 0.2, 0))
	spawn_t_shape(Vector3(0.2, 0.2, 0))
	spawn_l_shape(Vector3(0, 0.3, 0.2))

	print("Example 6.3: Compound Bodies - Multi-shape objects")

func _process(delta):
	if auto_spawn and compound_objects.size() < max_objects:
		spawn_timer += delta
		if spawn_timer >= spawn_interval:
			spawn_timer = 0.0
			spawn_random_compound()

	# Clean up fallen objects
	cleanup_fallen_objects()

	update_ui()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			spawn_random_compound()
		elif event.keycode == KEY_C:
			cycle_spawn_type()
		elif event.keycode == KEY_R:
			reset()

func create_ui_labels():
	"""Create UI labels"""
	info_label = Label3D.new()
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info_label.font_size = 28
	info_label.outline_size = 4
	info_label.modulate = Color(1.0, 0.9, 1.0)
	info_label.position = Vector3(0, 0.6, 0)
	add_child(info_label)

	type_label = Label3D.new()
	type_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	type_label.font_size = 20
	type_label.modulate = Color(0.8, 1.0, 0.8)
	type_label.position = Vector3(0, 0.5, 0)
	type_label.text = "[SPACE] Spawn | [C] Cycle Type | [R] Reset"
	add_child(type_label)

func update_ui():
	"""Update UI labels"""
	if info_label:
		info_label.text = "Compound Bodies\n%s (%d/%d)" % [type_names[current_type], compound_objects.size(), max_objects]

func create_ground():
	"""Create static ground plane"""
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

func spawn_random_compound():
	"""Spawn random compound object at top"""
	var x = randf_range(-0.25, 0.25)
	var z = randf_range(-0.25, 0.25)
	var pos = Vector3(x, 0.4, z)

	match current_type:
		0: spawn_dumbbell(pos)
		1: spawn_t_shape(pos)
		2: spawn_l_shape(pos)
		3: spawn_cross(pos)

func spawn_dumbbell(pos: Vector3):
	"""Create dumbbell shape (sphere-cylinder-sphere)"""
	var dumbbell = VRRigidBody.new()
	dumbbell.position = pos
	dumbbell.use_pink_material = true

	# Center cylinder (bar)
	var cylinder_mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.02
	cylinder.bottom_radius = 0.02
	cylinder.height = 0.15
	cylinder_mesh.mesh = cylinder
	dumbbell.add_child(cylinder_mesh)

	# Cylinder collision
	var cyl_collision = CollisionShape3D.new()
	var cyl_shape = CylinderShape3D.new()
	cyl_shape.radius = 0.02
	cyl_shape.height = 0.15
	cyl_collision.shape = cyl_shape
	dumbbell.add_child(cyl_collision)

	# Left sphere (weight)
	var left_mesh = MeshInstance3D.new()
	var left_sphere = SphereMesh.new()
	left_sphere.radius = 0.05
	left_mesh.mesh = left_sphere
	left_mesh.position = Vector3(-0.075, 0, 0)
	dumbbell.add_child(left_mesh)

	# Left sphere collision
	var left_collision = CollisionShape3D.new()
	var left_shape = SphereShape3D.new()
	left_shape.radius = 0.05
	left_collision.shape = left_shape
	left_collision.position = Vector3(-0.075, 0, 0)
	dumbbell.add_child(left_collision)

	# Right sphere (weight)
	var right_mesh = MeshInstance3D.new()
	var right_sphere = SphereMesh.new()
	right_sphere.radius = 0.05
	right_mesh.mesh = right_sphere
	right_mesh.position = Vector3(0.075, 0, 0)
	dumbbell.add_child(right_mesh)

	# Right sphere collision
	var right_collision = CollisionShape3D.new()
	var right_shape = SphereShape3D.new()
	right_shape.radius = 0.05
	right_collision.shape = right_shape
	right_collision.position = Vector3(0.075, 0, 0)
	dumbbell.add_child(right_collision)

	# Setup material
	dumbbell.mesh_instance = cylinder_mesh
	dumbbell.setup_pink_material()

	# Apply same material to other meshes
	var mat = dumbbell.material
	left_mesh.material_override = mat
	right_mesh.material_override = mat

	dumbbell.body_entered.connect(_on_collision)
	add_child(dumbbell)
	compound_objects.append(dumbbell)

func spawn_t_shape(pos: Vector3):
	"""Create T-shape (vertical bar + horizontal bar)"""
	var t_shape = VRRigidBody.new()
	t_shape.position = pos
	t_shape.use_pink_material = true

	# Vertical bar
	var vert_mesh = MeshInstance3D.new()
	var vert_box = BoxMesh.new()
	vert_box.size = Vector3(0.03, 0.12, 0.03)
	vert_mesh.mesh = vert_box
	vert_mesh.position = Vector3(0, -0.03, 0)
	t_shape.add_child(vert_mesh)

	var vert_collision = CollisionShape3D.new()
	var vert_shape = BoxShape3D.new()
	vert_shape.size = Vector3(0.03, 0.12, 0.03)
	vert_collision.shape = vert_shape
	vert_collision.position = Vector3(0, -0.03, 0)
	t_shape.add_child(vert_collision)

	# Horizontal bar
	var horiz_mesh = MeshInstance3D.new()
	var horiz_box = BoxMesh.new()
	horiz_box.size = Vector3(0.12, 0.03, 0.03)
	horiz_mesh.mesh = horiz_box
	horiz_mesh.position = Vector3(0, 0.04, 0)
	t_shape.add_child(horiz_mesh)

	var horiz_collision = CollisionShape3D.new()
	var horiz_shape = BoxShape3D.new()
	horiz_shape.size = Vector3(0.12, 0.03, 0.03)
	horiz_collision.shape = horiz_shape
	horiz_collision.position = Vector3(0, 0.04, 0)
	t_shape.add_child(horiz_collision)

	# Setup material
	t_shape.mesh_instance = vert_mesh
	t_shape.setup_pink_material()
	horiz_mesh.material_override = t_shape.material

	t_shape.body_entered.connect(_on_collision)
	add_child(t_shape)
	compound_objects.append(t_shape)

func spawn_l_shape(pos: Vector3):
	"""Create L-shape (two perpendicular bars)"""
	var l_shape = VRRigidBody.new()
	l_shape.position = pos
	l_shape.use_pink_material = true

	# Vertical part
	var vert_mesh = MeshInstance3D.new()
	var vert_box = BoxMesh.new()
	vert_box.size = Vector3(0.03, 0.1, 0.03)
	vert_mesh.mesh = vert_box
	vert_mesh.position = Vector3(0, 0.02, 0)
	l_shape.add_child(vert_mesh)

	var vert_collision = CollisionShape3D.new()
	var vert_shape = BoxShape3D.new()
	vert_shape.size = Vector3(0.03, 0.1, 0.03)
	vert_collision.shape = vert_shape
	vert_collision.position = Vector3(0, 0.02, 0)
	l_shape.add_child(vert_collision)

	# Horizontal part
	var horiz_mesh = MeshInstance3D.new()
	var horiz_box = BoxMesh.new()
	horiz_box.size = Vector3(0.1, 0.03, 0.03)
	horiz_mesh.mesh = horiz_box
	horiz_mesh.position = Vector3(0.035, -0.035, 0)
	l_shape.add_child(horiz_mesh)

	var horiz_collision = CollisionShape3D.new()
	var horiz_shape = BoxShape3D.new()
	horiz_shape.size = Vector3(0.1, 0.03, 0.03)
	horiz_collision.shape = horiz_shape
	horiz_collision.position = Vector3(0.035, -0.035, 0)
	l_shape.add_child(horiz_collision)

	# Setup material
	l_shape.mesh_instance = vert_mesh
	l_shape.setup_pink_material()
	horiz_mesh.material_override = l_shape.material

	l_shape.body_entered.connect(_on_collision)
	add_child(l_shape)
	compound_objects.append(l_shape)

func spawn_cross(pos: Vector3):
	"""Create cross shape (3 perpendicular bars)"""
	var cross = VRRigidBody.new()
	cross.position = pos
	cross.use_pink_material = true

	# X-axis bar
	var x_mesh = MeshInstance3D.new()
	var x_box = BoxMesh.new()
	x_box.size = Vector3(0.12, 0.03, 0.03)
	x_mesh.mesh = x_box
	cross.add_child(x_mesh)

	var x_collision = CollisionShape3D.new()
	var x_shape = BoxShape3D.new()
	x_shape.size = Vector3(0.12, 0.03, 0.03)
	x_collision.shape = x_shape
	cross.add_child(x_collision)

	# Y-axis bar
	var y_mesh = MeshInstance3D.new()
	var y_box = BoxMesh.new()
	y_box.size = Vector3(0.03, 0.12, 0.03)
	y_mesh.mesh = y_box
	cross.add_child(y_mesh)

	var y_collision = CollisionShape3D.new()
	var y_shape = BoxShape3D.new()
	y_shape.size = Vector3(0.03, 0.12, 0.03)
	y_collision.shape = y_shape
	cross.add_child(y_collision)

	# Z-axis bar
	var z_mesh = MeshInstance3D.new()
	var z_box = BoxMesh.new()
	z_box.size = Vector3(0.03, 0.03, 0.12)
	z_mesh.mesh = z_box
	cross.add_child(z_mesh)

	var z_collision = CollisionShape3D.new()
	var z_shape = BoxShape3D.new()
	z_shape.size = Vector3(0.03, 0.03, 0.12)
	z_collision.shape = z_shape
	cross.add_child(z_collision)

	# Setup material
	cross.mesh_instance = x_mesh
	cross.setup_pink_material()
	y_mesh.material_override = cross.material
	z_mesh.material_override = cross.material

	cross.body_entered.connect(_on_collision)
	add_child(cross)
	compound_objects.append(cross)

func _on_collision(body: Node):
	"""Handle collision"""
	pass  # Collision feedback in VRRigidBody

func cycle_spawn_type():
	"""Cycle through spawn types"""
	current_type = (current_type + 1) % type_names.size()
	update_ui()

func cleanup_fallen_objects():
	"""Remove objects that fell too far"""
	var to_remove: Array[VRRigidBody] = []

	for obj in compound_objects:
		if obj.global_position.y < -1.0:
			to_remove.append(obj)

	for obj in to_remove:
		compound_objects.erase(obj)
		obj.queue_free()

func reset():
	"""Reset scene"""
	for obj in compound_objects:
		obj.queue_free()
	compound_objects.clear()

	spawn_timer = 0.0
	current_type = 0

	# Spawn initial objects
	spawn_dumbbell(Vector3(-0.2, 0.2, 0))
	spawn_t_shape(Vector3(0.2, 0.2, 0))
	spawn_l_shape(Vector3(0, 0.3, 0.2))
