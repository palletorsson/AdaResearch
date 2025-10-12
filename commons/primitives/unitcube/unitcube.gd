# UnitCube.gd - Unit cube from vertex/face arrays (fits within 1,1,1 scaled to 0.5)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


var base_color: Color = Color(0.5, 0.5, 1.0)  # Light blue
var scale_factor: float = 0.5  # Scale from 2x2x2 to 1x1x1
var _mesh_instance: MeshInstance3D
var _collision_body: StaticBody3D

func _ready():
	_build_unitcube()

func _build_unitcube() -> void:
	_teardown()
	var vertices := create_unitcube_vertices()
	var faces := create_unitcube_faces()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		vertices,
		faces,
		{
			"name": "UnitCubeMesh",
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

func create_unitcube_vertices() -> Array:
	# Original vertex array scaled to fit within 1x1x1
	var raw_vertices = [
		Vector3(1.0, 1.0, 1.0),    # 0
		Vector3(1.0, 1.0, -1.0),   # 1
		Vector3(1.0, -1.0, 1.0),   # 2
		Vector3(1.0, -1.0, -1.0),  # 3
		Vector3(-1.0, 1.0, 1.0),   # 4
		Vector3(-1.0, 1.0, -1.0),  # 5
		Vector3(-1.0, -1.0, 1.0),  # 6
		Vector3(-1.0, -1.0, -1.0), # 7
	]

	# Scale to fit within 1x1x1
	var vertices: Array[Vector3] = []
	for v in raw_vertices:
		vertices.append(v * scale_factor)

	return vertices

func create_unitcube_faces() -> Array:
	var faces: Array = []

	faces.append([0, 4, 6])
	faces.append([0, 6, 2])
	faces.append([3, 2, 6])
	faces.append([3, 6, 7])
	faces.append([7, 6, 4])
	faces.append([7, 4, 5])
	faces.append([5, 1, 3])
	faces.append([5, 3, 7])
	faces.append([1, 0, 2])
	faces.append([1, 2, 3])
	faces.append([5, 4, 0])
	faces.append([5, 0, 1])

	return faces

func _build_collision_body() -> StaticBody3D:
	var static_body := StaticBody3D.new()
	static_body.name = "UnitCubeCollision"
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.0, 1.0, 1.0) * scale_factor * 2.0
	collision.shape = box
	static_body.add_child(collision)
	return static_body

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)
