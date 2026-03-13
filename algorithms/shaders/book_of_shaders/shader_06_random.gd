## Shader 06: Random — GPU pseudorandom
## Book of Shaders Chapter 10
extends Node3D

const DISPLAY_SIZE := Vector3(2.0, 2.0, 0.05)
const DISPLAY_GAP := 3.0
const PANEL_OFFSET_Z := 1.2

var panels: Array[ShaderRackPanel] = []
var materials: Array[ShaderMaterial] = []

var shader_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/random_basic.gdshader",
		"title": "fract(sin(dot()))",
		"code": "fract(sin(dot(st,vec2(a,b)))*43758.5);",
		"sliders": [["Scale", 1.0, 500.0, 100.0, 1.0], ["Threshold", 0.0, 1.0, 0.5, 0.01], ["Show B/W", 0.0, 1.0, 0.0, 1.0]],
		"uniforms": ["scale", "threshold", "show_threshold"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/random_grid.gdshader",
		"title": "Random Grid",
		"code": "hash(floor(uv * grid));",
		"sliders": [["Grid Size", 2.0, 30.0, 10.0, 1.0], ["Color Mode", 0.0, 2.0, 0.0, 1.0]],
		"uniforms": ["grid_size", "color_mode"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/random_animated.gdshader",
		"title": "Animated (TV Static)",
		"code": "hash(vec3(uv, floor(TIME * speed)));",
		"sliders": [["Grid", 5.0, 200.0, 50.0, 5.0], ["Speed", 0.1, 30.0, 10.0, 0.5], ["Color", 0.0, 1.0, 0.0, 0.1]],
		"uniforms": ["grid_size", "speed", "color_intensity"]
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

