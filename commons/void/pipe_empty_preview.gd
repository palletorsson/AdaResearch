extends "res://algorithms/wavefunctions/big_pipe_system/big_pipe_system.gd"
## The original source ignores #path and disables auto_build. Preserve that
## runtime; make its location selectable in the editor without inventing a pipe.
func prepare_editor_preview() -> void:
	if not _curves.is_empty():return
	var plate:=MeshInstance3D.new()
	var mesh:=BoxMesh.new();mesh.size=Vector3(.6,.025,.6)
	plate.mesh=mesh;plate.position.y=.025
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.4,.4,.4)
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	plate.material_override=mat;add_child(plate)
	var label:=Label3D.new();label.text="UNBUILT SOURCE\nPIPE PATH NOT WIRED";label.font_size=28;label.pixel_size=.0015
	label.position=Vector3(0,.25,0);add_child(label)
