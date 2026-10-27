extends "res://algorithms/randomness/PickupCubePlacer.gd"
## Trial-only editor marker (randomness_03). The original placer searches for a
## GridSystem and places nothing without one. Neither the museum nor the Void has
## one ("PickupCubePlacer: WARNING - No GridSystem found!", measured natively).
## Runtime is unchanged. The exporter calls this so the lab editor can select and
## move the placement. It is a dependency marker, not placed cubes.
func prepare_editor_preview() -> void:
	if not pickup_cubes.is_empty(): return
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new();mesh.size = Vector3(.6, .025, .6)
	plate.mesh = mesh;plate.position.y = .025
	var mat := StandardMaterial3D.new();mat.albedo_color = Color(.4, .4, .4)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plate.material_override = mat;add_child(plate)
	var label := Label3D.new();label.text = "DEPENDENCY MISSING\nNO GRIDSYSTEM: NO CUBES PLACED"
	label.font_size = 28;label.pixel_size = .0015;label.position = Vector3(0, .25, 0);add_child(label)
