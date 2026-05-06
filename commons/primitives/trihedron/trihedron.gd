# Trihedron.gd - Three-sided polyhedron (wedge shape) with 3 faces and 4 vertices
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


var base_color: Color = Color(0.2, 0.8, 1.0)
var trihedron_size: float = 0.6
var _mesh_instance: MeshInstance3D

func _ready():
	_rebuild_trihedron()

func _rebuild_trihedron() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null
	var geometry := _trihedron_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Trihedron",
			"material": material
		}
	)
	add_child(_mesh_instance)

func _trihedron_geometry() -> Dictionary:
	var vertices := _create_trihedron_vertices()
	var faces := _create_trihedron_faces()
	return {
		"vertices": vertices,
		"faces": faces
	}

func _create_trihedron_vertices() -> Array[Vector3]:
	var vertices: Array[Vector3] = []
	var s := trihedron_size
	
	# Trihedron: 4 vertices forming a wedge/corner
	# Apex vertex (corner point)
	vertices.append(Vector3(0, s, 0))  # Apex (0)
	
	# Base triangle vertices
	vertices.append(Vector3(-s, -s, -s))  # Base vertex 1 (1)
	vertices.append(Vector3(s, -s, -s))   # Base vertex 2 (2)
	vertices.append(Vector3(0, -s, s))    # Base vertex 3 (3)
	
	return vertices

func _create_trihedron_faces() -> Array:
	# Trihedron has exactly 3 triangular faces, all sharing the apex vertex
	# Each face is formed by the apex and two adjacent base vertices
	return [
		# Face 1: Apex + base vertices 1 and 2
		[0, 1, 2],
		# Face 2: Apex + base vertices 2 and 3
		[0, 2, 3],
		# Face 3: Apex + base vertices 3 and 1
		[0, 3, 1]
	]

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)

func set_trihedron_size(size: float) -> void:
	trihedron_size = size
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
	_mesh_instance = null
	call_deferred("_rebuild_trihedron")
