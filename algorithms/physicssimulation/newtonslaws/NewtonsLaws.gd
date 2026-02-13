## Newton's Laws — Three balls under different force conditions
## Uses Godot's built-in RigidBody3D physics. No manual gravity or collision.
extends Node3D

@export var applied_force_strength: float = 5.0
@export var oscillation_speed: float = 2.0

var balls: Array[RigidBody3D] = []
var time: float = 0.0

# Visualization
var force_arrows: Array[MeshInstance3D] = []
var velocity_arrows: Array[MeshInstance3D] = []

var ball_colors := [
	Color(1.0, 0.3, 0.3),  # Red — gravity only
	Color(0.3, 1.0, 0.3),  # Green — constant applied force
	Color(0.3, 0.5, 1.0),  # Blue — oscillating force
]

func _ready():
	scale = Vector3(0.8, 0.8, 0.8)
	_create_balls()
	_create_containment()

func _create_balls():
	var positions := [Vector3(-2, 3, 0), Vector3(0, 3, 0), Vector3(2, 3, 0)]
	var masses := [1.0, 1.5, 2.0]

	for i in range(3):
		var rb := RigidBody3D.new()
		rb.mass = masses[i]
		rb.name = "Ball_%d" % i

		# Collision shape
		var col := CollisionShape3D.new()
		var shape := SphereShape3D.new()
		shape.radius = 0.3
		col.shape = shape
		rb.add_child(col)

		# Visual
		var mesh_inst := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.6
		mesh_inst.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = ball_colors[i]
		mat.emission_enabled = true
		mat.emission = ball_colors[i] * 0.5
		mat.emission_energy_multiplier = 1.5
		mesh_inst.material_override = mat
		rb.add_child(mesh_inst)

		# Physics material — different friction per ball
		var phys_mat := PhysicsMaterial.new()
		phys_mat.bounce = 0.6
		if i == 0:
			phys_mat.friction = 0.2  # Low friction
		elif i == 1:
			phys_mat.friction = 0.5  # Medium friction
		else:
			phys_mat.friction = 0.9  # High friction
		rb.physics_material_override = phys_mat

		rb.position = positions[i]
		add_child(rb)
		balls.append(rb)

		# Force arrow visualization
		var arrow := _create_arrow(ball_colors[i])
		add_child(arrow)
		force_arrows.append(arrow)

		# Velocity arrow
		var vel_arrow := _create_arrow(Color.YELLOW)
		add_child(vel_arrow)
		velocity_arrows.append(vel_arrow)

func _create_containment():
	# Floor
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(10, 0.2, 10)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.position = Vector3(0, -0.1, 0)
	add_child(floor_body)

	# Walls
	for wall_data in [
		[Vector3(5, 2, 0), Vector3(0.2, 4, 10)],
		[Vector3(-5, 2, 0), Vector3(0.2, 4, 10)],
		[Vector3(0, 2, 5), Vector3(10, 4, 0.2)],
		[Vector3(0, 2, -5), Vector3(10, 4, 0.2)],
	]:
		var wall := StaticBody3D.new()
		var wcol := CollisionShape3D.new()
		var wshape := BoxShape3D.new()
		wshape.size = wall_data[1]
		wcol.shape = wshape
		wall.add_child(wcol)
		wall.position = wall_data[0]
		add_child(wall)

func _physics_process(delta: float):
	time += delta

	# Ball 0: gravity only — no applied force needed, Godot handles it
	# Ball 1: constant horizontal force
	if balls.size() > 1:
		balls[1].apply_central_force(Vector3(applied_force_strength, 0, 0))

	# Ball 2: oscillating force
	if balls.size() > 2:
		var osc_force := Vector3(
			sin(time * oscillation_speed) * applied_force_strength * 1.5,
			0,
			cos(time * oscillation_speed * 0.75) * applied_force_strength
		)
		balls[2].apply_central_force(osc_force)

	_update_arrows()

func _update_arrows():
	for i in range(balls.size()):
		var rb := balls[i]
		var vel := rb.linear_velocity

		# Velocity arrow
		if vel.length() > 0.2 and i < velocity_arrows.size():
			var arrow := velocity_arrows[i]
			arrow.visible = true
			arrow.position = rb.position + Vector3(0, 0.4, 0)
			var target := arrow.position + vel.normalized()
			if arrow.position.distance_to(target) > 0.01:
				arrow.look_at(target, Vector3.UP)
			arrow.scale.y = clamp(vel.length() / 5.0, 0.2, 2.0)
		elif i < velocity_arrows.size():
			velocity_arrows[i].visible = false

func _create_arrow(color: Color) -> MeshInstance3D:
	var arrow := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.015
	cyl.bottom_radius = 0.015
	cyl.height = 1.0
	arrow.mesh = cyl
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.5
	arrow.material_override = mat
	arrow.visible = false
	return arrow

func reset():
	var positions := [Vector3(-2, 3, 0), Vector3(0, 3, 0), Vector3(2, 3, 0)]
	for i in range(balls.size()):
		balls[i].linear_velocity = Vector3.ZERO
		balls[i].angular_velocity = Vector3.ZERO
		balls[i].position = positions[i]
	time = 0.0
