## Shader 01: Shaping Functions — step, smoothstep, sin, pow
## Book of Shaders Chapter 5

# @identity
# essence: y = f(x) — step, smoothstep, sin, pow redistribute intensity across a gradient; each function is a policy for interpolation
# desire: to drag sliders and watch a gradient bend — threshold sharpens, exponent compresses, frequency breathes
# critical_parameter: threshold/exponent — the single number that decides where value concentrates
# triggers: slider changes feed directly into shader uniforms; combined mode blends all four shaping policies
# emerges: the combined panel reveals that every smooth surface is a weighted vote among discontinuity, cubic ease, oscillation, and power law
# needs: [has] ShaderRackPanel sliders per display; [missing] no VR push buttons
# relationships: foundation for all subsequent shader maps — colors, shapes, patterns all reuse these shaping primitives
# truth: a gradient is never neutral — every interpolation curve encodes a decision about how value distributes across space

extends Node3D

const DISPLAY_SIZE := Vector3(2.0, 2.0, 0.05)
const DISPLAY_GAP := 2.8
const PANEL_OFFSET := Vector3(0.0, 0.0, 1.2)

var panels: Array[ShaderRackPanel] = []
var materials: Array[ShaderMaterial] = []
var wall_setting := false

# Shader definitions: [path, title, code_snippet, sliders: [[name, min, max, default, step]]]
var shader_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/shaping_step.gdshader",
		"title": "step()",
		"code": "float y = step(threshold, x);",
		"sliders": [["Threshold", 0.0, 1.0, 0.5, 0.01]]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/shaping_smoothstep.gdshader",
		"title": "smoothstep()",
		"code": "float y = smoothstep(e0, e1, x);",
		"sliders": [["Edge 0", 0.0, 1.0, 0.2, 0.01], ["Edge 1", 0.0, 1.0, 0.8, 0.01]]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/shaping_sin.gdshader",
		"title": "sin()",
		"code": "float y = sin(freq * x + TIME);",
		"sliders": [["Frequency", 0.5, 10.0, 3.0, 0.1], ["Amplitude", 0.1, 0.5, 0.4, 0.01], ["Phase Speed", 0.0, 5.0, 1.0, 0.1]]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/shaping_pow.gdshader",
		"title": "pow()",
		"code": "float y = pow(x, exponent);",
		"sliders": [["Exponent", 0.1, 5.0, 2.0, 0.1]]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/shaping_combined.gdshader",
		"title": "Combined",
		"code": "mix(step, smooth, sin, pow)",
		"sliders": [["Blend", 0.0, 1.0, 0.5, 0.01], ["Threshold", 0.0, 1.0, 0.5, 0.01], ["Exponent", 0.1, 5.0, 2.0, 0.1], ["Frequency", 0.5, 8.0, 2.0, 0.1]]
	}
]

# Map slider names to shader uniform names per display
var uniform_maps := [
	["threshold"],
	["edge0", "edge1"],
	["frequency", "amplitude", "phase_speed"],
	["exponent"],
	["blend", "threshold", "exponent", "freq"]
]


func _ready() -> void:
	_build_gallery()


func _build_gallery() -> void:
	var start_x := -(float(shader_defs.size()) - 1.0) * DISPLAY_GAP * 0.5

	for i in range(shader_defs.size()):
		var def: Dictionary = shader_defs[i]
		var x_pos := start_x + float(i) * DISPLAY_GAP

		# Display surface
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

		# Title label
		var title := Label3D.new()
		title.text = def["title"]
		title.font_size = 18
		title.pixel_size = 0.001
		title.modulate = Color(0.92, 0.92, 0.94)
		title.position = Vector3(x_pos, 2.7, 0.01)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(title)

		# Rack panel
		var slider_count: int = def["sliders"].size()
		var cols := mini(slider_count, 2)
		var rows := ceili(float(slider_count) / float(cols))
		var rack_units := maxi(3, rows + 2)

		var panel := ShaderRackPanel.new()
		panel.setup(def["title"], cols, rack_units)
		panel.set_code_snippet(def["code"])

		for s in def["sliders"]:
			panel.add_slider(s[0], s[1], s[2], s[3], s[4])

		panel.position = Vector3(x_pos, 0.5, PANEL_OFFSET.z)
		panel.rotation_degrees = Vector3(-15, 0, 0)
		add_child(panel)
		panels.append(panel)


func _process(_delta: float) -> void:
	for i in range(panels.size()):
		if i >= materials.size():
			break
		var mat: ShaderMaterial = materials[i]
		var panel: ShaderRackPanel = panels[i]
		var uniforms: Array = uniform_maps[i]
		for j in range(uniforms.size()):
			mat.set_shader_parameter(uniforms[j], panel.get_slider_value(j))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if str(config.get("setting", "")) != "wall" or wall_setting:
		return
	# Opt-in museum mounting; older placements retain their layout.
	wall_setting = true
	if panels.is_empty():
		await ready
	var G = preload("res://commons/artifacts/jacquard_weaver/weave_geometry.gd")
	var ivory: StandardMaterial3D = G.material("e5ded0")
	var dark: StandardMaterial3D = G.material("252a2c")
	for i in range(panels.size()):
		var display: MeshInstance3D = get_node("Display_%d" % i)
		# A graph uses the complete square UV domain, not one BoxMesh atlas face.
		var square := QuadMesh.new(); square.size = Vector2(2,2)
		display.mesh = square
		display.position.y = 2.1
		panels[i].position.y = 1.02
		G.box(self,Vector3(display.position.x,2.1,-.07),Vector3(2.10,2.10,.08),dark)
		G.box(self,Vector3(display.position.x,.92,1.20),Vector3(1.5,.12,.72),ivory,true)
		for side in [-.57,.57]:
			G.box(self,Vector3(display.position.x+side,.43,1.2),Vector3(.065,.86,.52),dark,true)
	for child in get_children():
		if child is Label3D:
			child.position.y = 3.35
			child.font_size = 54
			child.pixel_size = .002
			child.modulate = Color("272b2d")
			child.outline_size = 0
