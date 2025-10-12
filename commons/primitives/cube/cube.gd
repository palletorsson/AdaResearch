# Cube.gd - Regular cube/hexahedron (6 square faces)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


var base_color: Color = Color(0.0, 1.0, 1.0)
var _mesh_instance: MeshInstance3D

func _ready():
	_build_cube()

func _build_cube() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null
	var geometry := _cube_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Cube",
			"material": material
		}
	)
	add_child(_mesh_instance)

func _cube_geometry() -> Dictionary:
	var size := 0.5
	var vertices: Array[Vector3] = [
		Vector3(-size, -size, size),
		Vector3(size, -size, size),
		Vector3(size, size, size),
		Vector3(-size, size, size),
		Vector3(-size, -size, -size),
		Vector3(size, -size, -size),
		Vector3(size, size, -size),
		Vector3(-size, size, -size)
	]
	var faces: Array = [
		[0, 1, 2], [0, 2, 3],
		[5, 4, 7], [5, 7, 6],
		[4, 0, 3], [4, 3, 7],
		[1, 5, 6], [1, 6, 2],
		[3, 2, 6], [3, 6, 7],
		[4, 5, 1], [4, 1, 0]
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)
