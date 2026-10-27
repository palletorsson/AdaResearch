extends "res://algorithms/randomness/RandomRotateRandomXYZ/RandomRotateRandomXYZ.gd"
## Trial-only editor marker (randomness_04, f2_Random_Rotate_Random_XYZ_3_10).
##
## The original owns no geometry. It rotates the instances of a grid floor's
## MultiMeshInstance3D named GridMultiMesh, looked up as ../GridMultiMesh or among its
## parent's descendants. A Void mount, like a museum hall, has none, so the source turns
## nothing and pushes the warning "Could not find MultiMeshInstance3D" (the source's own
## note: "With no grid floor in reach it now turns nothing", museum 2026-09-24).
##
## Runtime is unchanged: this adds nothing until the exporter calls
## prepare_editor_preview(), so the lab editor can select and move the placement.
## It is a dependency marker, not a rotation. The scene's exported overrides
## (selection_mode 1, bell_center (4,1,4), bell_radius 3, noise_source) must be
## carried across the script swap by the hook (REQUESTS.md R4).
func prepare_editor_preview() -> void:
	if multimesh_instance != null or has_node("NoGridMarker"): return
	var marker := Node3D.new()
	marker.name = "NoGridMarker"
	add_child(marker)
	var plate := MeshInstance3D.new()
	var mesh := BoxMesh.new();mesh.size = Vector3(.6, .025, .6)
	plate.mesh = mesh;plate.position.y = .0125
	var mat := StandardMaterial3D.new();mat.albedo_color = Color(.4, .4, .4)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	plate.material_override = mat;marker.add_child(plate)
	var label := Label3D.new();label.text = "DEPENDENCY MISSING\nNO GRID FLOOR: NOTHING TO ROTATE"
	label.font_size = 28;label.pixel_size = .0015;label.position = Vector3(0, .25, 0);marker.add_child(label)
