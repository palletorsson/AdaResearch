# Icosahedron.gd - Regular icosahedron (20 triangular faces)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


const PHI := 1.618033988749895
var base_color: Color = Color(0.2, 1.0, 0.6)
var _mesh_instance: MeshInstance3D

func _ready():
	_build_icosahedron()

func _build_icosahedron() -> void:
	_teardown()
	var geometry := _icosahedron_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Icosahedron",
			"material": material
		}
	)
	add_child(_mesh_instance)

func _teardown() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

func _icosahedron_geometry() -> Dictionary:
	var scale := 0.4
	var vertices: Array[Vector3] = [
		Vector3(0.85065, 0.52573, 0.0),
		Vector3(-0.85065, 0.52573, 0.0),
		Vector3(0.85065, -0.52573, 0.0),
		Vector3(-0.85065, -0.52573, 0.0),
		Vector3(0.52573, 0.0, 0.85065),
		Vector3(0.52573, 0.0, -0.85065),
		Vector3(-0.52573, 0.0, 0.85065),
		Vector3(-0.52573, 0.0, -0.85065),
		Vector3(0.0, 0.85065, 0.52573),
		Vector3(0.0, -0.85065, 0.52573),
		Vector3(0.0, 0.85065, -0.52573),
		Vector3(0.0, -0.85065, -0.52573)
	]
	for i in range(vertices.size()):
		vertices[i] *= scale
	var faces: Array = [
		[0, 8, 4], [0, 5, 10], [2, 4, 9], [2, 11, 5],
		[1, 6, 8], [1, 10, 7], [3, 9, 6], [3, 7, 11],
		[0, 10, 8], [1, 8, 10], [2, 9, 11], [3, 11, 9],
		[4, 2, 0], [5, 0, 2], [6, 1, 3], [7, 3, 1],
		[8, 6, 4], [9, 4, 6], [10, 5, 7], [11, 7, 5]
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)
