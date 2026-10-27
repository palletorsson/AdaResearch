extends "res://algorithms/cellularautomata/ca_showcase/disease_spread_ca.gd"
## The source samples only every fourth cell. Its five random infections often
## miss that display lattice entirely; keep the native state and disclose this
## honestly with an arrangement marker only when exporting an empty snapshot.
func prepare_editor_preview() -> void:
	if multi_mesh_instance.multimesh.visible_instance_count != 0: return
	set_meta("void_preview_kind", "empty_sample_arrangement_marker")
	var marker := MeshInstance3D.new()
	marker.name = "EmptySampleArrangementMarker"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.6, .08, .8)
	marker.mesh = mesh
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("384e57")
	marker.material_override = finish
	add_child(marker)
	var label_ := Label3D.new()
	label_.text = "SIR / EMPTY DISPLAY SAMPLE\n64 cubed state; every fourth cell shown\nArrangement marker only"
	label_.font_size = 32
	label_.pixel_size = .012
	label_.position.y = .65
	label_.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label_)
