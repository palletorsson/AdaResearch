# Plane.gd - Generates a plane mesh
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

@export var width: float = 10.0
@export var height: float = 10.0
@export var x_segments: int = 10
@export var y_segments: int = 10
@export var base_color: Color = Color(0.8, 0.8, 0.8)

var _mesh_instance: MeshInstance3D

signal mesh_built(mesh_instance)

func _ready():
	_build_plane()

func _build_plane() -> void:
	_teardown()
	var geometry := _plane_geometry()
	var material = GridMaterialFactory.make(base_color, {
		"edge_color": Color.BLACK,
		"edge_width": 0.2,
		"emission_strength": 0.5
	})
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Plane",
			"material": material
		}
	)
	add_child(_mesh_instance)
	mesh_built.emit(_mesh_instance)

func _teardown() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

func _plane_geometry() -> Dictionary:
	var vertices: Array[Vector3] = []
	var faces: Array = []

	var half_width = width / 2.0
	var half_height = height / 2.0
	var x_step = width / float(x_segments)
	var y_step = height / float(y_segments)

	for j in range(y_segments + 1):
		for i in range(x_segments + 1):
			var x = -half_width + i * x_step
			var z = half_height - j * y_step
			vertices.append(Vector3(x, 0, z))

	for j in range(y_segments):
		for i in range(x_segments):
			var a = j * (x_segments + 1) + i
			var b = a + 1
			var c = (j + 1) * (x_segments + 1) + i
			var d = c + 1
			# Use CCW winding as seen from +Y to ensure upward-facing normals
			# Triangle 1
			faces.append([a, c, b])
			# Triangle 2
			faces.append([b, c, d])
			
	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color, {
			"edge_color": Color.BLACK,
			"edge_width": 0.2,
			"emission_strength": 0.5
		})
