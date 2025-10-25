# tetrahedron_mesh.gd - Generates a tetrahedron mesh on a MeshInstance3D parent
extends Node

const GridMaterialFactory := preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder := preload("res://commons/primitives/shared/primitive_mesh_builder.gd")

@export var base_color: Color = Color(1.0, 0.0, 1.0)
var target_mesh: MeshInstance3D

func _ready() -> void:
	if not target_mesh:
		if get_parent() is MeshInstance3D:
			target_mesh = get_parent()
		else:
			for child in get_parent().get_children():
				if child is MeshInstance3D:
					target_mesh = child
					break
	_apply_mesh()

func set_target_mesh(mesh: MeshInstance3D) -> void:
	target_mesh = mesh
	_apply_mesh()

func set_base_color(color: Color) -> void:
	base_color = color
	_apply_mesh()

func _apply_mesh() -> void:
	if not target_mesh:
		return
	var geom := _tetrahedron_geometry()
	var mesh := PrimitiveMeshBuilder.build_mesh(geom["vertices"], geom["faces"], {"generate_normals": true})
	target_mesh.mesh = mesh
	target_mesh.material_override = GridMaterialFactory.make(base_color)

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
	return {"vertices": vertices, "faces": faces}
