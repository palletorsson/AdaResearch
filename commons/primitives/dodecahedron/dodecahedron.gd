# Dodecahedron.gd - Fixed Regular dodecahedron (12 pentagonal faces)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


const PHI := 1.618033988749895
var base_color: Color = Color(1.0, 0.8, 0.2)
var _mesh_instance: MeshInstance3D

func _ready():
	_build_dodecahedron()

func _build_dodecahedron() -> void:
	_teardown()
	var geometry := _dodecahedron_geometry()
	var material = GridMaterialFactory.make(base_color, {
		"edge_color": Color.CYAN,
		"edge_width": 1.0,
		"emission_strength": 0.8
	})
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Dodecahedron",
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

func _dodecahedron_geometry() -> Dictionary:
	var scale := 0.4
	var a := 1.0 / PHI
	var b := PHI
	var vertices: Array[Vector3] = [
		Vector3(1, 1, 1), Vector3(1, 1, -1), Vector3(1, -1, 1), Vector3(-1, 1, 1),
		Vector3(-1, -1, 1), Vector3(-1, 1, -1), Vector3(1, -1, -1), Vector3(-1, -1, -1),
		Vector3(0, a, b), Vector3(0, -a, b), Vector3(0, a, -b), Vector3(0, -a, -b),
		Vector3(a, b, 0), Vector3(-a, b, 0), Vector3(a, -b, 0), Vector3(-a, -b, 0),
		Vector3(b, 0, a), Vector3(-b, 0, a), Vector3(b, 0, -a), Vector3(-b, 0, -a)
	]
	for i in range(vertices.size()):
		vertices[i] = vertices[i].normalized() * scale
	var pentagons: Array = [
		[3, 17, 4, 9, 8],
		[0, 12, 13, 3, 8],
		[0, 8, 9, 2, 16],
		[0, 16, 18, 1, 12],
		[1, 18, 6, 14, 12],
		[2, 9, 4, 15, 14],
		[2, 14, 6, 18, 16],
		[3, 13, 5, 19, 17],
		[4, 17, 19, 7, 15],
		[5, 13, 12, 1, 10],
		[5, 10, 11, 7, 19],
		[6, 11, 10, 1, 18]
	]
	var faces: Array = []
	for pentagon in pentagons:
		var pivot = pentagon[0]
		for i in range(1, pentagon.size() - 1):
			faces.append([pivot, pentagon[i], pentagon[i + 1]])
	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color, {
			"edge_color": Color.CYAN,
			"edge_width": 1.0,
			"emission_strength": 0.8
		})
