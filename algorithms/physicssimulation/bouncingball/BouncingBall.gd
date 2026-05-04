## Bouncing Ball — RigidBody3D balls with PhysicsMaterial bounce
## Godot handles ALL physics: gravity, collision, bouncing
## Visible wireframe cube containment so you can see the box
##
## @identity
## essence: Bounded chamber of bouncing balls — physics engine handles gravity, collision, restitution; we only set initial conditions
## desire: To let the player watch deterministic physics produce apparent randomness through accumulating collision micro-differences
## critical_parameter: ball_count and PhysicsMaterial.bounce — together they decide whether the box becomes still, periodic, or chaotic
## triggers: Low count and low bounce settles to floor; high count with high bounce becomes a pseudo-gas inside the cube
## emerges: Newton's laws as the engine, visible cube as the stage — the chamber's regularity reveals each ball's path as deviation
## needs: RigidBody3D physics [has], wireframe cube containment [has], spawn height tuning [has]
## relationships: Companion to NewtonsLaws — same physics, different demonstration. Both anchor forces/Newton's_Laws map
## truth: A bounce is not random — it is the moment when constraint becomes visible, when geometry refuses to let the ball pass.
extends Node3D

@export var ball_count: int = 6
@export var spawn_height: float = 5.0

## Cube dimensions
const CUBE_HALF := 4.0   # half-width of containment cube
const CUBE_HEIGHT := 6.0  # total height of cube

## Edge style
@export var edge_color: Color = Color(0.4, 0.7, 1.0, 0.6)
@export var edge_thickness: float = 0.03

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

func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)
	_create_containment()
	_create_visible_cube()
	_spawn_balls()

func _create_containment() -> void:
	# Floor
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(CUBE_HALF * 2, 0.2, CUBE_HALF * 2)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.position = Vector3(0, -0.1, 0)

	var floor_mat := PhysicsMaterial.new()
	floor_mat.bounce = 0.5
	floor_body.physics_material_override = floor_mat
	add_child(floor_body)

	# Ceiling
	var ceil_body := StaticBody3D.new()
	var ceil_col := CollisionShape3D.new()
	var ceil_shape := BoxShape3D.new()
	ceil_shape.size = Vector3(CUBE_HALF * 2, 0.2, CUBE_HALF * 2)
	ceil_col.shape = ceil_shape
	ceil_body.add_child(ceil_col)
	ceil_body.position = Vector3(0, CUBE_HEIGHT + 0.1, 0)

	var ceil_mat := PhysicsMaterial.new()
	ceil_mat.bounce = 0.7
	ceil_body.physics_material_override = ceil_mat
	add_child(ceil_body)

	# Walls (invisible collision)
	for wall_data in [
		[Vector3(CUBE_HALF, CUBE_HEIGHT / 2.0, 0), Vector3(0.2, CUBE_HEIGHT, CUBE_HALF * 2)],
		[Vector3(-CUBE_HALF, CUBE_HEIGHT / 2.0, 0), Vector3(0.2, CUBE_HEIGHT, CUBE_HALF * 2)],
		[Vector3(0, CUBE_HEIGHT / 2.0, CUBE_HALF), Vector3(CUBE_HALF * 2, CUBE_HEIGHT, 0.2)],
		[Vector3(0, CUBE_HEIGHT / 2.0, -CUBE_HALF), Vector3(CUBE_HALF * 2, CUBE_HEIGHT, 0.2)],
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

## Visible wireframe cube — 12 edges as thin glowing cylinders
func _create_visible_cube() -> void:
	var w := CUBE_HALF
	var h := CUBE_HEIGHT

	# Material for all edges
	var mat := StandardMaterial3D.new()
	mat.albedo_color = edge_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(edge_color.r, edge_color.g, edge_color.b)
	mat.emission_energy_multiplier = 0.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# The 8 corners of the cube: bottom y=0, top y=h
	var corners := [
		Vector3(-w, 0, -w), Vector3( w, 0, -w), Vector3( w, 0,  w), Vector3(-w, 0,  w),  # bottom
		Vector3(-w, h, -w), Vector3( w, h, -w), Vector3( w, h,  w), Vector3(-w, h,  w),  # top
	]

	# 12 edges: 4 bottom, 4 top, 4 vertical
	var edges := [
		# Bottom square
		[corners[0], corners[1]], [corners[1], corners[2]],
		[corners[2], corners[3]], [corners[3], corners[0]],
		# Top square
		[corners[4], corners[5]], [corners[5], corners[6]],
		[corners[6], corners[7]], [corners[7], corners[4]],
		# Vertical pillars
		[corners[0], corners[4]], [corners[1], corners[5]],
		[corners[2], corners[6]], [corners[3], corners[7]],
	]

	for i in range(edges.size()):
		var a: Vector3 = edges[i][0]
		var b: Vector3 = edges[i][1]
		_add_edge(a, b, mat, i)

	# Transparent floor panel so you can see the base
	var floor_vis := MeshInstance3D.new()
	floor_vis.name = "FloorPanel"
	var plane := PlaneMesh.new()
	plane.size = Vector2(w * 2, w * 2)
	floor_vis.mesh = plane

	var floor_vis_mat := StandardMaterial3D.new()
	floor_vis_mat.albedo_color = Color(0.2, 0.3, 0.5, 0.12)
	floor_vis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	floor_vis_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_vis.material_override = floor_vis_mat
	floor_vis.position = Vector3(0, 0.01, 0)
	add_child(floor_vis)

func _add_edge(a: Vector3, b: Vector3, mat: StandardMaterial3D, idx: int) -> void:
	var edge := MeshInstance3D.new()
	edge.name = "Edge_%d" % idx

	var length := a.distance_to(b)
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = edge_thickness
	cylinder.bottom_radius = edge_thickness
	cylinder.height = length
	cylinder.radial_segments = 4
	edge.mesh = cylinder
	edge.material_override = mat

	# Position at midpoint
	edge.position = (a + b) / 2.0

	# Orient cylinder along edge direction using Basis (same as cube_lines / line_static)
	var direction := (b - a).normalized()
	if direction.length() > 0.001:
		var up := Vector3.UP
		var right := direction.cross(up).normalized()
		if right.length() < 0.001:
			# Direction is parallel to UP — use a different reference
			right = Vector3.RIGHT
			up = right.cross(direction).normalized()
		else:
			up = right.cross(direction).normalized()
		edge.transform.basis = Basis(right, direction, up)

	add_child(edge)

func _spawn_balls() -> void:
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
		var color: Color = queer_colors[i % queer_colors.size()]
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

func reset() -> void:
	for ball in balls:
		ball.queue_free()
	balls.clear()
	_spawn_balls()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
