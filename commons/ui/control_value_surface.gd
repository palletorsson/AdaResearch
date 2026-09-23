@tool
extends RefCounted
## A value is a flat display, seated on its control. Share the renderer between
## faders and dials; redraw only when the formatted value actually changes.
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

static func build(parent: Node3D, size: Vector2, at: Vector3, roll: float = 0.0) -> Dictionary:
	var viewport := SubViewport.new()
	viewport.name = "ValueViewport"
	viewport.size = Vector2i(240, 80)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	parent.add_child(viewport)
	var background := ColorRect.new()
	background.size = Vector2(viewport.size)
	background.color = Color(0.035, 0.05, 0.055)
	viewport.add_child(background)
	var value := Label.new()
	value.name = "Value"
	value.size = Vector2(viewport.size)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_override("font", BakedText.project_font("medium"))
	value.add_theme_font_size_override("font_size", 58)
	value.add_theme_color_override("font_color", Color(0.83, 0.97, 0.84))
	viewport.add_child(value)
	var screen := MeshInstance3D.new()
	screen.name = "ValueSurface"
	var quad := QuadMesh.new()
	quad.size = size
	screen.mesh = quad
	screen.position = at
	screen.rotation_degrees.z = roll
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	screen.material_override = material
	parent.add_child(screen)
	return {"viewport": viewport, "label": value, "screen": screen}
