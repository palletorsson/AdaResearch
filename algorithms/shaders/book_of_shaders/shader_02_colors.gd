## Shader 02: Colors — mix, gradients, HSB/RGB
## Book of Shaders Chapter 6
extends Node3D

const DISPLAY_SIZE := Vector3(2.0, 2.0, 0.05)
const DISPLAY_GAP := 2.8
const PANEL_OFFSET_Z := 1.2

var panels: Array[ShaderRackPanel] = []
var materials: Array[ShaderMaterial] = []

var shader_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/colors_gradient.gdshader",
		"title": "Gradient",
		"code": "color = hsb2rgb(vec3(hue, sat, val));",
		"sliders": [["Hue Offset", 0.0, 1.0, 0.0, 0.01], ["Saturation", 0.0, 1.0, 0.8, 0.01], ["Angle", 0.0, 6.28, 0.0, 0.05]],
		"uniforms": ["hue_offset", "saturation", "angle"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/colors_hsb.gdshader",
		"title": "HSB Space",
		"code": "x = hue, y = value, uniform = sat",
		"sliders": [["Saturation", 0.0, 1.0, 1.0, 0.01], ["Mode", 0.0, 1.0, 0.0, 1.0]],
		"uniforms": ["saturation", "mode"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/colors_mix.gdshader",
		"title": "mix()",
		"code": "vec3 c = mix(colorA, colorB, t);",
		"sliders": [["T Value", 0.0, 1.0, 0.5, 0.01], ["Show Gradient", 0.0, 1.0, 1.0, 1.0]],
		"uniforms": ["t_value", "show_gradient"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/colors_rainbow.gdshader",
		"title": "Rainbow",
		"code": "r = sin(t + phase_r); // etc.",
		"sliders": [["Speed", 0.0, 5.0, 1.0, 0.1], ["Frequency", 1.0, 10.0, 3.0, 0.1]],
		"uniforms": ["speed", "frequency"]
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
