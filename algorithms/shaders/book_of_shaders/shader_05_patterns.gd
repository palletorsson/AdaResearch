## Shader 05: Patterns — tiles, truchet, bricks
## Book of Shaders Chapter 9
extends Node3D

const DISPLAY_SIZE := Vector3(2.0, 2.0, 0.05)
const DISPLAY_GAP := 2.8
const PANEL_OFFSET_Z := 1.2

var panels: Array[ShaderRackPanel] = []
var materials: Array[ShaderMaterial] = []

var shader_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_tile.gdshader",
		"title": "Tiling",
		"code": "vec2 tile_uv = fract(uv * grid);",
		"sliders": [["Grid Size", 1.0, 20.0, 5.0, 1.0], ["Shape Size", 0.1, 0.5, 0.3, 0.01], ["Animate", 0.0, 1.0, 0.0, 1.0]],
		"uniforms": ["grid_size", "shape_size", "animate"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_truchet.gdshader",
		"title": "Truchet",
		"code": "arc from random corner flip",
		"sliders": [["Grid", 2.0, 20.0, 8.0, 1.0], ["Thickness", 0.01, 0.2, 0.08, 0.01], ["Seed", 0.0, 100.0, 42.0, 1.0]],
		"uniforms": ["grid_size", "line_thickness", "seed"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_offset.gdshader",
		"title": "Offset Rows",
		"code": "uv.x += mod(row, 2.0) * 0.5;",
		"sliders": [["Grid", 2.0, 16.0, 6.0, 1.0], ["Offset", 0.0, 0.5, 0.5, 0.01], ["Dot Size", 0.05, 0.45, 0.25, 0.01]],
		"uniforms": ["grid_size", "offset_amount", "dot_size"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_brick.gdshader",
		"title": "Brick",
		"code": "offset row + mortar gap",
		"sliders": [["Rows", 2.0, 20.0, 8.0, 1.0], ["Cols", 1.0, 10.0, 4.0, 0.5], ["Mortar", 0.01, 0.1, 0.04, 0.005]],
		"uniforms": ["rows", "cols", "mortar"]
	}
]


func _ready() -> void:
	var start_x := -(float(shader_defs.size()) - 1.0) * DISPLAY_GAP * 0.5
	for i in range(shader_defs.size()):
		var def: Dictionary = shader_defs[i]
		var x_pos := start_x + float(i) * DISPLAY_GAP
		var display := MeshInstance3D.new()
		display.name = "Display_%d" % i
		var box := BoxMesh.new()
		box.size = DISPLAY_SIZE
		display.mesh = box
		var mat := ShaderMaterial.new()
		mat.shader = load(def["shader"])
		display.material_override = mat
		display.position = Vector3(x_pos, 1.5, 0.0)
		add_child(display)
		materials.append(mat)

		var title := Label3D.new()
		title.text = def["title"]
		title.font_size = 18
		title.pixel_size = 0.001
		title.modulate = Color(0.92, 0.92, 0.94)
		title.position = Vector3(x_pos, 2.7, 0.01)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(title)

		var slider_count: int = def["sliders"].size()
		var panel := ShaderRackPanel.new()
		panel.setup(def["title"], mini(slider_count, 2), maxi(3, ceili(float(slider_count) / 2.0) + 2))
		panel.set_code_snippet(def["code"])
		for s in def["sliders"]:
			panel.add_slider(s[0], s[1], s[2], s[3], s[4])
		panel.position = Vector3(x_pos, 0.5, PANEL_OFFSET_Z)
		panel.rotation_degrees = Vector3(-15, 0, 0)
		add_child(panel)
		panels.append(panel)


func _process(_delta: float) -> void:
	for i in range(panels.size()):
		if i >= materials.size():
			break
		var mat: ShaderMaterial = materials[i]
		var panel: ShaderRackPanel = panels[i]
		var uniforms: Array = shader_defs[i]["uniforms"]
		for j in range(uniforms.size()):
			mat.set_shader_parameter(uniforms[j], panel.get_slider_value(j))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
