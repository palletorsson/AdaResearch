# Bipyramid.gd - Double pyramid (square base with top and bottom apex)
extends Node3D

# @identity
# essence: a square bipyramid — a four-sided ring with an apex above and below — two pyramids fused at their base
# desire: the learner sees a solid built by mirroring: take one pyramid, reflect it, and the base vanishes into an interior seam
# critical_parameter: the two apex points at (0,±0.4,0) and the square ring between them — stretch the apexes and it elongates toward the octahedron
# triggers: builds on ready; set_base_color recolors the grid-shaded faces
# emerges: that reflection is a construction operator — a whole new solid is made by mirroring a simpler one across a plane
# needs: [has grid-shaded faces [has], missing an apex-height slider to morph between flat, octahedral, and spindle forms]
# relationships: a near-cousin of the octahedron (which is the special case where all edges are equal); built from the same triangle-fan logic as the pyramid
# truth: mirror a shape across its base and the base disappears — reflection makes a whole from a half
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")
const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")


var base_color: Color = Color(0.6, 0.0, 0.8)
var _mesh_instance: MeshInstance3D

func _ready():
	_build_bipyramid()

func _build_bipyramid() -> void:
	_teardown()
	var geometry := _bipyramid_geometry()
	var material = GridMaterialFactory.make(base_color)
	_mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		geometry["vertices"],
		geometry["faces"],
		{
			"name": "Bipyramid",
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

func _bipyramid_geometry() -> Dictionary:
	var vertices: Array[Vector3] = [
		Vector3(0, 0.4, 0),
		Vector3(0, -0.4, 0),
		Vector3(0.3, 0, 0.3),
		Vector3(-0.3, 0, 0.3),
		Vector3(-0.3, 0, -0.3),
		Vector3(0.3, 0, -0.3)
	]
	var faces: Array = [
		[0, 2, 3], [0, 3, 4], [0, 4, 5], [0, 5, 2],
		[1, 3, 2], [1, 4, 3], [1, 5, 4], [1, 2, 5]
	]
	return {
		"vertices": vertices,
		"faces": faces
	}

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)
