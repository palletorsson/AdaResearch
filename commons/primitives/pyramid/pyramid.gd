# Pyramid.gd - Regular pyramid with square base (5 faces total)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


var base_color: Color = Color(1.0, 0.8, 0.2)
var pyramid_height: float = 0.8
var base_size: float = 0.6
var _mesh_instance: MeshInstance3D

func _ready():
	_rebuild_pyramid()

func _rebuild_pyramid() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null
	var geometry := _pyramid_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Pyramid",
			"material": material
		}
	)
	add_child(_mesh_instance)

func _pyramid_geometry() -> Dictionary:
	var vertices := _create_pyramid_vertices()
	var faces := _create_pyramid_faces()
	return {
		"vertices": vertices,
		"faces": faces
	}

func _create_pyramid_vertices() -> Array[Vector3]:
	var vertices: Array[Vector3] = []
	var half_base := base_size * 0.5
	vertices.append_array([
		Vector3(-half_base, 0, -half_base),
		Vector3(half_base, 0, -half_base),
		Vector3(half_base, 0, half_base),
		Vector3(-half_base, 0, half_base),
		Vector3(0, pyramid_height, 0)
	])
	return vertices

func _create_pyramid_faces() -> Array:
	return [
		[0, 2, 1],
		[0, 3, 2],
		[0, 1, 4],
		[1, 2, 4],
		[2, 3, 4],
		[3, 0, 4]
	]

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)

func set_pyramid_size(height: float, base: float) -> void:
	pyramid_height = height
	base_size = base
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
	_mesh_instance = null
	call_deferred("_rebuild_pyramid")
