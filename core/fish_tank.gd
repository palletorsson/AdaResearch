class_name FishTank
extends Node3D

## Fish Tank boundary - 1m x 1m x 1m transparent cube
## All Nature of Code examples are contained within this space

@export var tank_size: float = 1.0
@export var wall_color: Color = Color(1.0, 0.7, 0.9, 0.1)  # Light pink with transparency
@export var show_boundaries: bool = true

var boundary_mesh: MeshInstance3D

func _ready():
	if show_boundaries:
		create_boundary_visualization()

func create_boundary_visualization():
	"""Create transparent pink cube showing tank boundaries"""
	boundary_mesh = MeshInstance3D.new()
	add_child(boundary_mesh)

	# Create box mesh
	var box = BoxMesh.new()
	box.size = Vector3(tank_size, tank_size, tank_size)
	boundary_mesh.mesh = box

	# Create transparent pink material
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = wall_color
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show both sides
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	# Add emission for pink glow
	material.emission_enabled = true
	material.emission = Color(1.0, 0.7, 0.9, 1.0)
	material.emission_energy_multiplier = 0.3

	boundary_mesh.material_override = material

func get_min_bounds() -> Vector3:
	"""Get minimum corner of tank"""
	return global_position - Vector3.ONE * (tank_size / 2.0)

func get_max_bounds() -> Vector3:
	"""Get maximum corner of tank"""
	return global_position + Vector3.ONE * (tank_size / 2.0)

func constrain_position(pos: Vector3) -> Vector3:
	"""Constrain a position to be within tank boundaries"""
	var half_size = tank_size / 2.0
	return Vector3(
		clamp(pos.x, -half_size, half_size),
		clamp(pos.y, -half_size, half_size),
		clamp(pos.z, -half_size, half_size)
	)

func is_inside(pos: Vector3) -> bool:
	"""Check if a position is inside the tank"""
	var half_size = tank_size / 2.0
	return (abs(pos.x) <= half_size and
			abs(pos.y) <= half_size and
			abs(pos.z) <= half_size)

func bounce_vector(pos: Vector3, vel: Vector3) -> Vector3:
	"""Bounce velocity vector off walls if position is at boundary"""
	var half_size = tank_size / 2.0
	var new_vel = vel

	if abs(pos.x) >= half_size:
		new_vel.x *= -1
	if abs(pos.y) >= half_size:
		new_vel.y *= -1
	if abs(pos.z) >= half_size:
		new_vel.z *= -1

	return new_vel
