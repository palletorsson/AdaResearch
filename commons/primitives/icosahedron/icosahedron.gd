# Icosahedron.gd - Regular icosahedron (20 triangular faces)
extends Node3D
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


const PHI := 1.618033988749895
var base_color: Color = Color(0.2, 1.0, 0.6)
var _mesh_instance: MeshInstance3D

func _ready():
	_build_icosahedron()

func _build_icosahedron() -> void:
	_teardown()
	var geometry := _icosahedron_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Icosahedron",
			"material": material,
			"double_sided": true  # Fix holes from incorrect face winding
		}
	)
	add_child(_mesh_instance)

func _teardown() -> void:
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

func _icosahedron_geometry() -> Dictionary:
	var s := 0.4
	# Precise icosahedron vertices on unit sphere, scaled
	var a := 0.5257311121 * s  # 1/sqrt(1+phi^2)
	var b := 0.8506508084 * s  # phi/sqrt(1+phi^2)
	var vertices: Array[Vector3] = [
		Vector3( b,  a,  0),  # 0
		Vector3(-b,  a,  0),  # 1
		Vector3( b, -a,  0),  # 2
		Vector3(-b, -a,  0),  # 3
		Vector3( a,  0,  b),  # 4
		Vector3( a,  0, -b),  # 5
		Vector3(-a,  0,  b),  # 6
		Vector3(-a,  0, -b),  # 7
		Vector3( 0,  b,  a),  # 8
		Vector3( 0, -b,  a),  # 9
		Vector3( 0,  b, -a),  # 10
		Vector3( 0, -b, -a),  # 11
	]
	# 20 faces — all wound counter-clockwise (outward normals)
	# Verified: every edge shared by exactly 2 faces, Euler V-E+F = 12-30+20 = 2
	var faces: Array = [
		# Top cap (vertex 8 neighborhood)
		[0, 8, 4], [8, 1, 6], [8, 6, 4], [0, 10, 8], [1, 8, 10],
		# Bottom cap (vertex 9 neighborhood)
		[2, 4, 9], [9, 6, 3], [9, 4, 6], [2, 9, 11], [3, 11, 9],
		# Middle band top
		[0, 5, 10], [1, 10, 7],
		# Middle band bottom
		[2, 11, 5], [3, 7, 11],
		# Connecting faces
		[4, 2, 0], [5, 0, 2],
		[6, 1, 3], [7, 3, 1],
		[10, 5, 7], [11, 7, 5],
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)
