# RectCube.gd - Rectangular cube/platform (1, 0.2, 1)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


var base_color: Color = Color(0.9, 0.9, 0.3)
var width: float = 1.0
var height: float = 0.2
var depth: float = 1.0
var _mesh_instance: MeshInstance3D
var _collision_body: StaticBody3D

func _ready():
	_build_rectcube()

func _build_rectcube() -> void:
	_teardown()
	var vertices := create_rectcube_vertices()
	var faces := create_rectcube_faces()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		vertices,
		faces,
		{
			"name": "RectCubeMesh",
			"material": material
		}
	)
	add_child(_mesh_instance)
	_collision_body = _build_collision_body()
	if _collision_body:
		add_child(_collision_body)

func _teardown() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null
	if _collision_body:
		if _collision_body.get_parent() == self:
			remove_child(_collision_body)
		_collision_body.queue_free()
		_collision_body = null

func create_rectcube_vertices() -> Array[Vector3]:
	var vertices: Array[Vector3] = []
	var half_width := width * 0.5
	var half_height := height * 0.5
	var half_depth := depth * 0.5
	vertices.append_array([
		Vector3(-half_width, -half_height, -half_depth),
		Vector3(half_width, -half_height, -half_depth),
		Vector3(half_width, -half_height, half_depth),
		Vector3(-half_width, -half_height, half_depth),
		Vector3(-half_width, half_height, -half_depth),
		Vector3(half_width, half_height, -half_depth),
		Vector3(half_width, half_height, half_depth),
		Vector3(-half_width, half_height, half_depth)
	])
	return vertices

func create_rectcube_faces() -> Array:
	return [
		[0, 2, 1], [0, 3, 2],
		[4, 5, 6], [4, 6, 7],
		[0, 1, 5], [0, 5, 4],
		[1, 2, 6], [1, 6, 5],
		[2, 3, 7], [2, 7, 6],
		[3, 0, 4], [3, 4, 7]
	]

func _build_collision_body() -> StaticBody3D:
	var static_body := StaticBody3D.new()
	static_body.name = "RectCubeCollision"
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, height, depth)
	collision.shape = box
	static_body.add_child(collision)
	return static_body

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)
