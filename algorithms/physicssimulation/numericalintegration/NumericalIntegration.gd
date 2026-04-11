## Numerical Integration — Compares Euler, RK4, and Godot's built-in integrator
## The blue ball uses RigidBody3D (Godot physics = "ground truth")
## Red and green trails show how Euler and RK4 approximate the same trajectory
extends Node3D

@export var time_step: float = 0.016
@export var trail_length: int = 200

var godot_ball: RigidBody3D  # Ground truth — Godot physics
var euler_pos: Vector3       # Manual Euler tracking
var euler_vel: Vector3
var rk4_pos: Vector3         # Manual RK4 tracking
var rk4_vel: Vector3

var euler_trail: Array[Vector3] = []
var rk4_trail: Array[Vector3] = []
var godot_trail: Array[Vector3] = []

var euler_mesh: ImmediateMesh
var rk4_mesh: ImmediateMesh
var godot_mesh: ImmediateMesh
var euler_inst: MeshInstance3D
var rk4_inst: MeshInstance3D
var godot_inst: MeshInstance3D

var gravity := Vector3(0, -9.8, 0)
var initial_pos := Vector3(-3, 4, 0)
var initial_vel := Vector3(3, 5, 0)

func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)
	_create_godot_ball()
	_create_trail_renderers()
	_create_containment()
	_reset_manual_particles()

func _create_godot_ball() -> void:
	godot_ball = RigidBody3D.new()
	godot_ball.name = "GodotBall"
	godot_ball.mass = 1.0

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.15
	col.shape = shape
	godot_ball.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	mesh_inst.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.5, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.5, 1.0) * 0.5
	mesh_inst.material_override = mat
	godot_ball.add_child(mesh_inst)

	var phys_mat := PhysicsMaterial.new()
	phys_mat.bounce = 0.7
	godot_ball.physics_material_override = phys_mat

	godot_ball.position = initial_pos
	godot_ball.linear_velocity = initial_vel
	add_child(godot_ball)

func _create_trail_renderers() -> void:
	# Euler trail (red)
	euler_mesh = ImmediateMesh.new()
	euler_inst = MeshInstance3D.new()
	euler_inst.mesh = euler_mesh
	var emat := StandardMaterial3D.new()
	emat.albedo_color = Color(1.0, 0.3, 0.3)
	emat.emission_enabled = true
	emat.emission = Color(1.0, 0.3, 0.3) * 0.5
	emat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	euler_inst.material_override = emat
	add_child(euler_inst)

	# RK4 trail (green)
	rk4_mesh = ImmediateMesh.new()
	rk4_inst = MeshInstance3D.new()
	rk4_inst.mesh = rk4_mesh
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.3, 1.0, 0.3)
	rmat.emission_enabled = true
	rmat.emission = Color(0.3, 1.0, 0.3) * 0.5
	rmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rk4_inst.material_override = rmat
	add_child(rk4_inst)

	# Godot trail (blue)
	godot_mesh = ImmediateMesh.new()
	godot_inst = MeshInstance3D.new()
	godot_inst.mesh = godot_mesh
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.3, 0.5, 1.0)
	gmat.emission_enabled = true
	gmat.emission = Color(0.3, 0.5, 1.0) * 0.5
	gmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	godot_inst.material_override = gmat
	add_child(godot_inst)

func _create_containment() -> void:
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(10, 0.2, 6)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.position = Vector3(0, -0.1, 0)
	var phys_mat := PhysicsMaterial.new()
	phys_mat.bounce = 0.7
	floor_body.physics_material_override = phys_mat
	add_child(floor_body)

func _reset_manual_particles() -> void:
	euler_pos = initial_pos
	euler_vel = initial_vel
	rk4_pos = initial_pos
	rk4_vel = initial_vel
	euler_trail.clear()
	rk4_trail.clear()
	godot_trail.clear()

func _physics_process(delta: float) -> void:
	# Euler integration (manual)
	euler_vel += gravity * delta
	euler_pos += euler_vel * delta
	# Floor bounce for Euler
	if euler_pos.y < 0.15:
		euler_pos.y = 0.15
		euler_vel.y = -euler_vel.y * 0.7

	# RK4 integration (manual)
	var k1_v := gravity * delta
	var k1_p := rk4_vel * delta
	var k2_v := gravity * delta
	var k2_p := (rk4_vel + k1_v * 0.5) * delta
	var k3_v := gravity * delta
	var k3_p := (rk4_vel + k2_v * 0.5) * delta
	var k4_v := gravity * delta
	var k4_p := (rk4_vel + k3_v) * delta
	rk4_vel += (k1_v + 2.0 * k2_v + 2.0 * k3_v + k4_v) / 6.0
	rk4_pos += (k1_p + 2.0 * k2_p + 2.0 * k3_p + k4_p) / 6.0
	if rk4_pos.y < 0.15:
		rk4_pos.y = 0.15
		rk4_vel.y = -rk4_vel.y * 0.7

	# Record trails
	euler_trail.append(euler_pos)
	rk4_trail.append(rk4_pos)
	godot_trail.append(godot_ball.position)

	if euler_trail.size() > trail_length:
		euler_trail.remove_at(0)
		rk4_trail.remove_at(0)
		godot_trail.remove_at(0)

	_draw_trails()

func _draw_trails() -> void:
	_draw_trail(euler_mesh, euler_trail)
	_draw_trail(rk4_mesh, rk4_trail)
	_draw_trail(godot_mesh, godot_trail)

func _draw_trail(mesh: ImmediateMesh, trail: Array[Vector3]) -> void:
	mesh.clear_surfaces()
	if trail.size() < 2:
		return
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in trail:
		mesh.surface_add_vertex(point)
	mesh.surface_end()

func reset() -> void:
	godot_ball.position = initial_pos
	godot_ball.linear_velocity = initial_vel
	godot_ball.angular_velocity = Vector3.ZERO
	_reset_manual_particles()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
