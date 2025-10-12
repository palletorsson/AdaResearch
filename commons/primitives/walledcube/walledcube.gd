# WalledCube.gd - Cube with walls on four sides (open top and bottom)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


var base_color: Color = Color(0.8, 0.3, 0.9)
var cube_size: float = 1.0
var _mesh_instance: MeshInstance3D

func _ready():
	_build_walled_cube()

func _build_walled_cube() -> void:
	_teardown()
	var vertices := create_cube_vertices()
	var faces := create_wall_faces()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		vertices,
		faces,
		{
			"name": "WalledCube",
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

func create_cube_vertices() -> Array[Vector3]:
	var vertices: Array[Vector3] = []
	var half_size := cube_size * 0.5
	vertices.append_array([
		Vector3(-half_size, -half_size, -half_size),
		Vector3(half_size, -half_size, -half_size),
		Vector3(half_size, -half_size, half_size),
		Vector3(-half_size, -half_size, half_size),
		Vector3(-half_size, half_size, -half_size),
		Vector3(half_size, half_size, -half_size),
		Vector3(half_size, half_size, half_size),
		Vector3(-half_size, half_size, half_size)
	])
	return vertices

func create_wall_faces() -> Array:
	return [
		[3, 6, 2], [3, 7, 6],
		[1, 5, 4], [1, 4, 0],
		[0, 7, 3], [0, 4, 7],
		[2, 5, 1], [2, 6, 5]
	]

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)

func set_cube_size(size: float) -> void:
	cube_size = size
\tif _mesh_instance:\r\n\t\tif _mesh_instance.get_parent() == self:\r\n\t\t\tremove_child(_mesh_instance)\r\n\t\t_mesh_instance.queue_free()\r\n\t_mesh_instance = null
	call_deferred("_build_walled_cube")
