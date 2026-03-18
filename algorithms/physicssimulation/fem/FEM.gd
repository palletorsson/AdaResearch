## Finite Element Method — Deformable mesh using SoftBody3D
## FEM discretizes a continuous body into finite elements (triangles/tetrahedra)
## Godot's SoftBody3D handles the deformation; we visualize stress via color
extends Node3D

@export var mesh_size: float = 2.0
@export var stiffness: float = 0.8
@export var precision: int = 8

var soft_body: SoftBody3D
var poke_sphere: StaticBody3D

func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)
	_create_deformable_body()
	_create_poke_sphere()
	_create_supports()

func _create_deformable_body() -> void:
	soft_body = SoftBody3D.new()
	soft_body.name = "FEMBody"

	# Use a subdivided box mesh as the deformable body
	var box := BoxMesh.new()
	box.size = Vector3(mesh_size, mesh_size * 0.3, mesh_size)
	box.subdivide_width = 8
	box.subdivide_height = 2
	box.subdivide_depth = 8
	soft_body.mesh = box

	soft_body.simulation_precision = precision
	soft_body.total_mass = 2.0
	soft_body.linear_stiffness = stiffness
	soft_body.pressure_coefficient = 0.5
	soft_body.damping_coefficient = 0.02

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.7, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.4, 0.2) * 0.3
	mat.metallic = 0.2
	mat.roughness = 0.6
	soft_body.material_override = mat

	soft_body.position = Vector3(0, 2, 0)
	add_child(soft_body)

	# Pin the corners after adding to tree
	call_deferred("_pin_edges")

func _pin_edges() -> void:
	# Pin some edge vertices to simulate fixed boundary conditions
	# This mimics FEM with Dirichlet boundary conditions
	var mesh_data := soft_body.mesh
	if mesh_data == null:
		return
	var arrays: Array = mesh_data.get_mesh_arrays()
	if arrays.size() == 0:
		return
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var half := mesh_size * 0.45
	for i in range(vertices.size()):
		var v := vertices[i]
		# Pin vertices at the edges
		if abs(v.x) > half or abs(v.z) > half:
			soft_body.set_point_pinned(i, true)

func _create_poke_sphere() -> void:
	# Interactive sphere that deforms the mesh when moved into it
	poke_sphere = StaticBody3D.new()
	poke_sphere.name = "PokeSphere"

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.3
	col.shape = shape
	poke_sphere.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.3
	sphere.height = 0.6
	mesh_inst.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.3, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.2) * 0.5
	mesh_inst.material_override = mat
	poke_sphere.add_child(mesh_inst)

	poke_sphere.position = Vector3(0, 3, 0)
	add_child(poke_sphere)

func _create_supports() -> void:
	# Floor support
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(6, 0.2, 6)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.position = Vector3(0, -0.1, 0)
	add_child(floor_body)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
