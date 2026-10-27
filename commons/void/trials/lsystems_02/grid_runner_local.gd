extends "res://commons/grid/mutators/grid_substrate_runner.gd"
## Void has fixed slabs, not the museum GridDataComponent/GridMultiMesh.
## Avoid the source's heuristic casting unrelated shader widths to int.
func _read_map_dimensions() -> Vector3i:
	return Vector3i.ZERO

func prepare_editor_preview() -> void:
	set_meta("void_preview_kind", "missing_dependency_arrangement_marker")
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new();mesh.size=Vector3(.6,.025,.6)
	plate.mesh=mesh;plate.position.y=.025
	var mat := StandardMaterial3D.new();mat.albedo_color=Color(.4,.4,.4)
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	plate.material_override=mat;add_child(plate)
	var label := Label3D.new();label.text="GRID SUBSTRATE RUNNER\nREQUIRES MUSEUM GRID MULTIMESH"
	label.font_size=28;label.pixel_size=.0015;label.position=Vector3(0,.25,0)
	add_child(label)
