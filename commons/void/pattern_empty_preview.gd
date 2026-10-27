extends "res://commons/artifacts/pattern_artifact/pattern_artifact.gd"
## Preserve the source token's intentionally empty, unconfigured runtime.
## Give only the editor export a selectable, labelled location marker.
func prepare_editor_preview() -> void:
	if _current!=null or not config_path.is_empty() or group!="unset":return
	var plate:=MeshInstance3D.new()
	plate.name="UnconfiguredSourceMarker"
	var mesh:=BoxMesh.new();mesh.size=Vector3(.6,.025,.6)
	plate.mesh=mesh;plate.position.y=.025
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color(.4,.4,.4)
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	plate.material_override=mat;add_child(plate)
	var label:=Label3D.new();label.text="UNCONFIGURED\nPATTERN SOURCE";label.font_size=28;label.pixel_size=.0015
	label.position=Vector3(0,.25,0);add_child(label)
