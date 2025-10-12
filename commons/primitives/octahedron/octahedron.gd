# Octahedron.gd - Regular octahedron primitive (8 faces, 6 vertices, 12 edges)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


var base_color: Color = Color(1.0, 1.0, 0.0)
var _mesh_instance: MeshInstance3D

func _ready():
	_build_octahedron()

func _build_octahedron() -> void:
	_teardown()
	var geometry := _octahedron_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Octahedron",
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

func _octahedron_geometry() -> Dictionary:
	var vertices: Array[Vector3] = [
		Vector3(0, 0.5, 0),
		Vector3(0, -0.5, 0),
		Vector3(0.5, 0, 0),
		Vector3(-0.5, 0, 0),
		Vector3(0, 0, 0.5),
		Vector3(0, 0, -0.5)
	]
	var faces: Array = [
		[0, 4, 2],
		[0, 2, 5],
		[0, 5, 3],
		[0, 3, 4],
		[1, 2, 4],
		[1, 5, 2],
		[1, 3, 5],
		[1, 4, 3]
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)
