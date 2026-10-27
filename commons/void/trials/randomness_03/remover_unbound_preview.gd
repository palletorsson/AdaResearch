extends "res://algorithms/randomness/RemoveRandom.gd"
## Trial-only editor marker (randomness_03). The 10 PRINT hall's `remove_random:90`
## carries no `#local_grid:true`, so the original remover binds no board and builds
## no geometry (measured natively). Runtime is unchanged. The exporter calls this so
## the lab editor can select and move the placement. It is a marker, not a remover.
func prepare_editor_preview() -> void:
	if multimesh != null: return
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new();mesh.size = Vector3(.6, .025, .6)
	plate.mesh = mesh;plate.position.y = .025
	var mat := StandardMaterial3D.new();mat.albedo_color = Color(.4, .4, .4)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plate.material_override = mat;add_child(plate)
	var label := Label3D.new();label.text = "UNBOUND SOURCE\nREMOVER WITHOUT LOCAL GRID"
	label.font_size = 28;label.pixel_size = .0015;label.position = Vector3(0, .25, 0);add_child(label)
