# PrismBlock.gd - Rectangular base tapering to central ridge
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


var base_color: Color = Color(0.6, 0.8, 1.0)
var _mesh_instance: MeshInstance3D
var _collision_body: StaticBody3D

func _ready():
	create_prism_block()

func create_prism_block() -> void:
	_teardown()
	var geometry := _prism_geometry()
	var material = GridMaterialFactory.make(base_color, {
		"edge_width": 1.4,
		"emission_strength": 0.9
	})
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "PrismBlock",
			"material": material
		}
	)
	add_child(_mesh_instance)
	_collision_body = _build_collision_body(geometry["vertices"])
	add_child(_collision_body)

func _prism_geometry() -> Dictionary:
	var base_length := 0.8
	var base_width := 0.4
	var height := 0.35
	var half_l := base_length * 0.5
	var half_w := base_width * 0.5
	var ridge_offset := 0.15
	var ridge_height := height
	var vertices: Array[Vector3] = [
		Vector3(-half_l, 0, -half_w),
		Vector3(half_l, 0, -half_w),
		Vector3(half_l, 0, half_w),
		Vector3(-half_l, 0, half_w),
		Vector3(-ridge_offset, ridge_height, 0),
		Vector3(ridge_offset, ridge_height, 0)
	]
	var faces: Array = [
		{ "indices": [0, 1, 2], "normal": Vector3.DOWN },
		{ "indices": [0, 2, 3], "normal": Vector3.DOWN },
		[0, 1, 5],
		[0, 5, 4],
		[1, 2, 5],
		[2, 3, 4],
		[4, 5, 2],
		[3, 0, 4]
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func _build_collision_body(vertices: Array[Vector3]) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var convex := ConvexPolygonShape3D.new()
	convex.points = PackedVector3Array(vertices)
	shape.shape = convex
	body.add_child(shape)
	return body

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

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color, {
			"edge_width": 1.4,
			"emission_strength": 0.9
		})
