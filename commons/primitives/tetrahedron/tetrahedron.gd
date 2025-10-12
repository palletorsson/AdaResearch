# Tetrahedron.gd - Regular tetrahedron (4 triangular faces)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


var base_color: Color = Color(1.0, 0.0, 1.0)
var _mesh_instance: MeshInstance3D

func _ready():
	_build_tetrahedron()

func _build_tetrahedron() -> void:
	_teardown()
	var geometry := _tetrahedron_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Tetrahedron",
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

func _tetrahedron_geometry() -> Dictionary:
	var scale := 0.6
	var vertices: Array[Vector3] = [
		Vector3(1, 1, 1) * scale,
		Vector3(1, -1, -1) * scale,
		Vector3(-1, 1, -1) * scale,
		Vector3(-1, -1, 1) * scale
	]
	var faces: Array = [
		[0, 2, 1],
		[0, 1, 3],
		[0, 3, 2],
		[1, 2, 3]
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)
