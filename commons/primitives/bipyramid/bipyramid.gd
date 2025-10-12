# Bipyramid.gd - Double pyramid (square base with top and bottom apex)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


var base_color: Color = Color(0.6, 0.0, 0.8)
var _mesh_instance: MeshInstance3D

func _ready():
	_build_bipyramid()

func _build_bipyramid() -> void:
	_teardown()
	var geometry := _bipyramid_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Bipyramid",
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

func _bipyramid_geometry() -> Dictionary:
	var vertices: Array[Vector3] = [
		Vector3(0, 0.4, 0),
		Vector3(0, -0.4, 0),
		Vector3(0.3, 0, 0.3),
		Vector3(-0.3, 0, 0.3),
		Vector3(-0.3, 0, -0.3),
		Vector3(0.3, 0, -0.3)
	]
	var faces: Array = [
		[0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 2],
		[1, 3, 2], [1, 4, 3], [1, 5, 4], [1, 2, 5]
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)
