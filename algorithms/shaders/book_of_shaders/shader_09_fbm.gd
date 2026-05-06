## Shader 09: FBM — fractional brownian motion, turbulence, domain warp
## Book of Shaders Chapter 13

# @identity
# essence: sum(gain^i * noise(p * lacunarity^i)) — FBM layers noise at multiple frequencies; ridged folds it with abs(); turbulence removes direction; domain warp feeds output back as input
# desire: to slide octaves and watch flat noise become mountain ranges — to push warp_amount and see the procedural engine eat its own tail
# critical_parameter: lacunarity — the frequency multiplier between octaves; 2.0 is standard, lower blurs, higher sharpens
# triggers: gain slider controls amplitude decay per octave; sharpness on ridged mode creates mountain ridge profiles; warp_layers stacks self-referential distortion
# emerges: domain warping produces forms that look geological — marble, smoke, lava — from nothing but noise feeding into itself; complexity from repetition at different resolutions
# needs: [has] ShaderRackPanel sliders per display; [missing] no VR push buttons
# relationships: depends on shader_07_noise; powers every procedural landscape and organic surface; connects to shader_10_reactiondiffusion (simulation as pattern)
# truth: scale is a parameter, not a property — the same operation applied again produces something irreducibly new

extends Node3D

const DISPLAY_SIZE := Vector3(2.0, 2.0, 0.05)
const DISPLAY_GAP := 2.8
const PANEL_OFFSET_Z := 1.2

var panels: Array[ShaderRackPanel] = []
var materials: Array[ShaderMaterial] = []

var shader_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/fbm_basic.gdshader",
		"title": "FBM",
		"code": "value += amp * noise(p * freq);",
		"sliders": [["Scale", 1.0, 10.0, 4.0, 0.5], ["Octaves", 1.0, 8.0, 5.0, 1.0], ["Gain", 0.1, 0.9, 0.5, 0.05], ["Lacunarity", 1.5, 3.0, 2.0, 0.1]],
		"uniforms": ["scale", "octaves", "gain", "lacunarity"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/fbm_ridged.gdshader",
		"title": "Ridged",
		"code": "n = 1.0 - abs(noise * 2.0 - 1.0);",
		"sliders": [["Scale", 1.0, 10.0, 4.0, 0.5], ["Octaves", 1.0, 8.0, 5.0, 1.0], ["Sharpness", 0.5, 3.0, 1.5, 0.1]],
		"uniforms": ["scale", "octaves", "sharpness"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/fbm_turbulence.gdshader",
		"title": "Turbulence",
		"code": "value += amp * abs(noise*2-1);",
		"sliders": [["Scale", 1.0, 10.0, 4.0, 0.5], ["Octaves", 1.0, 8.0, 5.0, 1.0], ["Speed", 0.0, 2.0, 0.5, 0.1]],
		"uniforms": ["scale", "octaves", "speed"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/fbm_domain_warp.gdshader",
		"title": "Domain Warp",
		"code": "fbm(p + warp * fbm(p + ...))",
		"sliders": [["Scale", 1.0, 8.0, 3.0, 0.5], ["Warp", 0.0, 4.0, 2.0, 0.1], ["Layers", 1.0, 3.0, 2.0, 1.0]],
		"uniforms": ["scale", "warp_amount", "warp_layers"]
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
