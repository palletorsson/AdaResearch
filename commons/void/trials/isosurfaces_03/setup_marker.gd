extends "res://commons/artifacts/timing_machines/iso_specimen_stage.gd"
## Original nonvisual setup script. Marker exists only in the browser export.
func prepare_editor_preview() -> void:
    var plate := MeshInstance3D.new()
    plate.name = "NonvisualSetupArrangementMarker"
    var mesh := BoxMesh.new()
    mesh.size = Vector3(0.8,0.018,0.45)
    plate.mesh = mesh
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color("485065")
    finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    plate.material_override = finish
    add_child(plate)
    var caption := Label3D.new()
    caption.text = "SOURCE SETUP ONLY / " + study.to_upper()
    caption.font_size = 24
    caption.pixel_size = 0.0015
    caption.position.y = 0.10
    add_child(caption)
    set_meta("void_preview_kind","nonvisual_source_setup_marker")
