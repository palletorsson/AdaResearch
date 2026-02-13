## Bouncing Ball — RigidBody3D balls with PhysicsMaterial bounce
## Godot handles ALL physics: gravity, collision, bouncing
extends Node3D

@export var ball_count: int = 6
@export var spawn_height: float = 5.0

var balls: Array[RigidBody3D] = []

var queer_colors := [
	Color(1.0, 0.4, 0.7),   # Hot pink
	Color(0.8, 0.3, 1.0),   # Purple
	Color(0.3, 0.9, 1.0),   # Cyan
	Color(1.0, 0.8, 0.2),   # Gold
	Color(0.5, 1.0, 0.4),   # Lime
	Color(1.0, 0.5, 0.3),   # Coral
	Color(0.4, 0.7, 1.0),   # Sky blue
	Color(1.0, 0.3, 0.5),   # Rose
]

func _ready():
	scale = Vector3(0.8, 0.8, 0.8)
	_create_containment()
	_spawn_balls()

func _create_containment():
	# Floor
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(8, 0.2, 8)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.position = Vector3(0, -0.1, 0)
	
	var floor_mat := PhysicsMaterial.new()
	floor_mat.bounce = 0.5
	floor_body.physics_material_override = floor_mat
	add_child(floor_body)

	# Walls (transparent containment)
	for wall_data in [
		[Vector3(4, 3, 0), Vector3(0.2, 6, 8)],
		[Vector3(-4, 3, 0), Vector3(0.2, 6, 8)],
		[Vector3(0, 3, 4), Vector3(8, 6, 0.2)],
		[Vector3(0, 3, -4), Vector3(8, 6, 0.2)],
	]:
		var wall := StaticBody3D.new()
		var wcol := CollisionShape3D.new()
		var wshape := BoxShape3D.new()
		wshape.size = wall_data[1]
		wcol.shape = wshape
		wall.add_child(wcol)
		wall.position = wall_data[0]
		
		var wmat := PhysicsMaterial.new()
		wmat.bounce = 0.7
		wall.physics_material_override = wmat
		add_child(wall)

func _spawn_balls():
	for i in range(ball_count):
		var rb := RigidBody3D.new()
		rb.name = "Ball_%d" % i
		
		var radius := randf_range(0.2, 0.4)
		rb.mass = radius * 3.0  # Heavier balls are bigger

		# Collision
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = radius
		col.shape = shape
		rb.add_child(col)

		# Visual
		var mesh_inst := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = radius
		sphere.height = radius * 2.0
		mesh_inst.mesh = sphere
		var mat := StandardMaterial3D.new()
		var color := queer_colors[i % queer_colors.size()]
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color * 0.4
		mat.emission_energy_multiplier = 1.5
		mat.metallic = 0.3
		mat.roughness = 0.4
		mesh_inst.material_override = mat
		rb.add_child(mesh_inst)

		# Physics material — different bounce per ball
		var phys_mat := PhysicsMaterial.new()
		phys_mat.bounce = randf_range(0.6, 0.95)
		phys_mat.friction = randf_range(0.1, 0.5)
		rb.physics_material_override = phys_mat

		# Random spawn position
		rb.position = Vector3(
			randf_range(-2.5, 2.5),
			spawn_height + i * 0.8,
			randf_range(-2.5, 2.5)
		)

		# Small random initial velocity
		rb.linear_velocity = Vector3(
			randf_range(-1, 1),
			0,
			randf_range(-1, 1)
		)

		add_child(rb)
		balls.append(rb)

func reset():
	for ball in balls:
		ball.queue_free()
	balls.clear()
	_spawn_balls()
