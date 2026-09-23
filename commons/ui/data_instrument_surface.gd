extends Node3D
## Fixed-size data instrument: flat 2D type on a cased plane. Local +Z is front.
## Owners keep the labels so existing recording and formatting code stays intact.
## Only changed content requests a viewport redraw; numeric columns never grow the case.
const Case = preload("res://commons/ui/instrument_panel_case.gd")
const Mono = preload("res://commons/font/JetBrainsMono-Medium.ttf")
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
var heading: Label
var table: Label
var viewport: SubViewport
var screen: MeshInstance3D
var size_m := Vector2(.92, .72)
var ink := Color(.9, .5, .8)
var body_color := Color(.9, .95, 1)
var preferred_font_size := 28
var _last_content := ""

func _ready() -> void:
	viewport = SubViewport.new()
	viewport.name = "DataViewport"
	viewport.size = Vector2i(roundi(size_m.x*1000), roundi(size_m.y*1000))
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var background := ColorRect.new()
	background.size = Vector2(viewport.size)
	background.color = Color(.025, .035, .055)
	viewport.add_child(background)
	heading = Label.new()
	heading.name = "Heading"
	heading.position = Vector2(32, 25)
	heading.size = Vector2(viewport.size.x-64, 60)
	heading.add_theme_font_override("font", BakedText.project_font("medium"))
	heading.add_theme_font_size_override("font_size", 42)
	heading.add_theme_color_override("font_color", ink)
	viewport.add_child(heading)
	var rule := ColorRect.new()
	rule.position = Vector2(32, 95)
	rule.size = Vector2(viewport.size.x-64, 2)
	rule.color = ink.darkened(.45)
	viewport.add_child(rule)
	table = Label.new()
	table.name = "DataTable"
	table.position = Vector2(32, 112)
	table.size = Vector2(viewport.size.x-64, viewport.size.y-140)
	table.add_theme_font_override("font", Mono)
	table.add_theme_font_size_override("font_size", preferred_font_size)
	table.add_theme_color_override("font_color", body_color)
	viewport.add_child(table)
	screen = MeshInstance3D.new()
	screen.name = "PanelSurface"
	screen.mesh = QuadMesh.new()
	screen.mesh.size = size_m
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	screen.material_override = material
	add_child(screen)
	var casing := Case.new()
	casing.name = "Casing"
	add_child(casing)
	casing.fit_rect(Vector2.ZERO, size_m, ink)

func refresh() -> void:
	var content := heading.text + table.text + str(heading.modulate) + str(table.visible)
	if content == _last_content: return
	_last_content = content
	# Fit the text into the authored surface, including negative/large coordinates
	# and derived recorders with additional rows. Do not clip or round away data.
	_fit_label(table, preferred_font_size, Vector2(viewport.size.x-64, viewport.size.y-140))
	_fit_label(heading, 42, Vector2(viewport.size.x-64, 60))
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE

func _fit_label(label: Label, preferred: int, available: Vector2) -> void:
	var font := label.get_theme_font("font")
	var lines := label.text.split("\n")
	var font_size := preferred
	while font_size > 8:
		var width := 0.0
		for line in lines:
			width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		var height := ceilf(font.get_height(font_size))*lines.size() + label.get_theme_constant("line_spacing")*maxi(0, lines.size()-1)
		if width <= available.x and height <= available.y: break
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
	label.size = available
