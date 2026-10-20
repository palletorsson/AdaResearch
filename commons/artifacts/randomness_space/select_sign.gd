extends Node3D
## One small 2D label presented on a physical stand.
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")

func _ready() -> void:
	Stage.box(self,Vector3(0,0.015,0),Vector3(0.32,0.03,0.24),Color("293736"))
	Stage.box(self,Vector3(0,0.46,0),Vector3(0.025,0.89,0.025),Color("64716d"))
	var backing := Stage.box(self,Vector3(0,0.96,-0.012),Vector3(0.46,0.18,0.024),Color("e6e4d3"))
	backing.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var viewport := SubViewport.new()
	viewport.name = "TextViewport"
	viewport.size = Vector2i(512,192)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var text := Label.new()
	text.name = "Select"
	text.text = "select"
	text.size = Vector2(512,192)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size",88)
	text.add_theme_color_override("font_color",Color("20302d"))
	viewport.add_child(text)
	var face := MeshInstance3D.new()
	face.name = "LabelFace"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.44,0.165)
	face.mesh = quad
	face.position = Vector3(0,0.96,0.002)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture = viewport.get_texture()
	face.material_override = material
	add_child(face)
