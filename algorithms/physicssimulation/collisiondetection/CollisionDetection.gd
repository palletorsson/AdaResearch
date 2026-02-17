## Collision Detection — Godot's built-in collision system
## Shows different collision shapes and visualizes contact with color changes
extends Node3D

@export var object_count: int = 8

var objects: Array[RigidBody3D] = []
var original_colors: Dictionary = {}  # node -> Color

var shape_colors := [
	Color(1.0, 0.3, 0.3),  # Sphere — red
	Color(0.3, 1.0, 0.3),  # Box — green
	Color(0.3, 0.5, 1.0),  # Capsule — blue
	Color(1.0, 0.8, 0.2),  # Cylinder — gold
]

func _ready():
	scale = Vector3(0.8, 0.8, 0.8)
	_create_containment()
	_create_objects()

func _create_containment():
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(8, 0.2, 8)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.position = Vector3(0, -0.1, 0)
	add_child(floor_body)

	# Walls
	for wall_data in [
		[Vector3(4, 2, 0), Vector3(0.2, 4, 8)],
		[Vector3(-4, 2, 0), Vector3(0.2, 4, 8)],
		[Vector3(0, 2, 4), Vector3(8, 4, 0.2)],
		[Vector3(0, 2, -4), Vector3(8, 4, 0.2)],
	]:
		var wall := StaticBody3D.new()
		var wcol := CollisionShape3D.new()
		var wshape := BoxShape3D.new()
		wshape.size = wall_data[1]
		wcol.shape = wshape
		wall.add_child(wcol)
		wall.position = wall_data[0]
		add_child(wall)

func _create_objects():
	for i in range(object_count):
		var shape_type := i % 4
		var rb := RigidBody3D.new()
		rb.name = "CollisionObj_%d" % i
		rb.mass = 1.0
		rb.contact_monitor = true
		rb.max_contacts_reported = 4

		var col := CollisionShape3D.new()
		var mesh_inst := MeshInstance3D.new()
		var color: Color = shape_colors[shape_type]

		match shape_type:
			0:  # Sphere
				var shape := SphereShape3D.new()
				shape.radius = 0.3
				col.shape = shape
				var m := SphereMesh.new()
				m.radius = 0.3
				m.height = 0.6
				mesh_inst.mesh = m
			1:  # Box
				var shape := BoxShape3D.new()
				shape.size = Vector3(0.5, 0.5, 0.5)
				col.shape = shape
				var m := BoxMesh.new()
				m.size = Vector3(0.5, 0.5, 0.5)
				mesh_inst.mesh = m
			2:  # Capsule
				var shape := CapsuleShape3D.new()
				shape.radius = 0.2
				shape.height = 0.6
				col.shape = shape
				var m := CapsuleMesh.new()
				m.radius = 0.2
				m.height = 0.6
				mesh_inst.mesh = m
			3:  # Cylinder
				var shape := CylinderShape3D.new()
				shape.radius = 0.25
				shape.height = 0.5
				col.shape = shape
				var m := CylinderMesh.new()
				m.top_radius = 0.25
				m.bottom_radius = 0.25
				m.height = 0.5
				mesh_inst.mesh = m

		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color * 0.3
		mesh_inst.material_override = mat

		rb.add_child(col)
		rb.add_child(mesh_inst)

		# Connect collision signals for color feedback
		rb.body_entered.connect(_on_body_entered.bind(rb, mesh_inst))
		rb.body_exited.connect(_on_body_exited.bind(rb, mesh_inst))

		original_colors[rb] = color

		# Random spawn position
		rb.position = Vector3(
			randf_range(-2.5, 2.5),
			2.0 + i * 0.6,
			randf_range(-2.5, 2.5)
		)
		rb.linear_velocity = Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))

		var phys_mat := PhysicsMaterial.new()
		phys_mat.bounce = 0.5
		rb.physics_material_override = phys_mat

		add_child(rb)
		objects.append(rb)

func _on_body_entered(_body: Node, rb: RigidBody3D, mesh_inst: MeshInstance3D):
	# Flash white on collision
	if mesh_inst.material_override:
		var mat: StandardMaterial3D = mesh_inst.material_override
		mat.albedo_color = Color.WHITE
		mat.emission = Color.WHITE * 0.8

		# Restore color after brief flash
		var tween := create_tween()
		var orig_color: Color = original_colors.get(rb, Color.WHITE)
		tween.tween_property(mat, "albedo_color", orig_color, 0.3)
		tween.parallel().tween_property(mat, "emission", orig_color * 0.3, 0.3)

func _on_body_exited(_body: Node, _rb: RigidBody3D, _mesh_inst: MeshInstance3D):
	pass  # Color already restoring via tween

func reset():
	for obj in objects:
		obj.queue_free()
	objects.clear()
	original_colors.clear()
	_create_objects()
