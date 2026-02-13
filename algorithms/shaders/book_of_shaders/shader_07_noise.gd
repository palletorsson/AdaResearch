## Shader 07: Noise — value, gradient, simplex, warped
## Book of Shaders Chapter 11
extends Node3D

const DISPLAY_SIZE := Vector3(2.0, 2.0, 0.05)
const DISPLAY_GAP := 2.8
const PANEL_OFFSET_Z := 1.2

var panels: Array[ShaderRackPanel] = []
var materials: Array[ShaderMaterial] = []

var shader_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/noise_value.gdshader",
		"title": "Value Noise",
		"code": "mix(hash(i), hash(i+1), smooth(f))",
		"sliders": [["Scale", 1.0, 20.0, 5.0, 0.5], ["Octaves", 1.0, 8.0, 4.0, 1.0], ["Persistence", 0.1, 0.9, 0.5, 0.05]],
		"uniforms": ["scale", "octaves", "persistence"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/noise_gradient.gdshader",
		"title": "Gradient Noise",
		"code": "dot(random_gradient, offset)",
		"sliders": [["Scale", 1.0, 20.0, 5.0, 0.5], ["Octaves", 1.0, 8.0, 4.0, 1.0], ["Contrast", 0.5, 3.0, 1.5, 0.1]],
		"uniforms": ["scale", "octaves", "contrast"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/noise_simplex.gdshader",
		"title": "Simplex Noise",
		"code": "simplex grid — more isotropic",
		"sliders": [["Scale", 1.0, 20.0, 5.0, 0.5], ["Octaves", 1.0, 6.0, 3.0, 1.0], ["Colorize", 0.0, 1.0, 0.0, 1.0]],
		"uniforms": ["scale", "octaves", "colorize"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/noise_warped.gdshader",
		"title": "Domain Warp",
		"code": "fbm(uv + warp * fbm(uv + ...))",
		"sliders": [["Scale", 1.0, 10.0, 4.0, 0.5], ["Warp", 0.0, 3.0, 1.5, 0.1], ["Color Shift", 0.0, 1.0, 0.5, 0.05]],
		"uniforms": ["scale", "warp_strength", "color_shift"]
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
