## Shader 04: Matrices — translate, rotate, scale UV
## Book of Shaders Chapter 8

# @identity
# essence: uv' = M * uv — translate shifts origin, rotate spins space, scale stretches it; composition is matrix multiplication, and order matters (non-commutative)
# desire: to drag translate X/Y and rotate simultaneously — to feel that the coordinate system itself is moving, not the shape
# critical_parameter: rotation angle — the single value that proves sequence is meaning (translate-then-rotate != rotate-then-translate)
# triggers: animate toggle sets auto_rotate, making the combined transform orbit continuously; combined panel stacks all three operations
# emerges: the combined display reveals that every spinning object in every game is just one matrix multiplied per frame
# needs: [has] ShaderRackPanel sliders per display; [missing] no VR push buttons
# relationships: builds on shader_03_shapes (transforms applied to SDF shapes); essential for shader_05_patterns (fract requires centered UV)
# truth: the coordinate system is never fixed — it was always a choice, and a matrix is a machine for making that choice visible

extends Node3D

const DISPLAY_SIZE := Vector3(2.0, 2.0, 0.05)
const DISPLAY_GAP := 2.8
const PANEL_OFFSET_Z := 1.2

var panels: Array[ShaderRackPanel] = []
var materials: Array[ShaderMaterial] = []

var shader_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/matrices_translate.gdshader",
		"title": "Translate",
		"code": "uv -= vec2(offset_x, offset_y);",
		"sliders": [["Offset X", -0.5, 0.5, 0.0, 0.01], ["Offset Y", -0.5, 0.5, 0.0, 0.01], ["Animate", 0.0, 1.0, 0.0, 1.0]],
		"uniforms": ["offset_x", "offset_y", "animate"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/matrices_rotate.gdshader",
		"title": "Rotate",
		"code": "uv = mat2(cos(a),-sin(a),sin(a),cos(a)) * uv;",
		"sliders": [["Angle", -6.28, 6.28, 0.0, 0.05], ["Auto Rotate", 0.0, 2.0, 0.0, 0.1]],
		"uniforms": ["angle", "auto_rotate"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/matrices_scale.gdshader",
		"title": "Scale",
		"code": "uv /= vec2(sx, sy) * s;",
		"sliders": [["Scale X", 0.2, 4.0, 1.0, 0.05], ["Scale Y", 0.2, 4.0, 1.0, 0.05], ["Uniform", 0.2, 4.0, 1.0, 0.05]],
		"uniforms": ["scale_x", "scale_y", "uniform_scale"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/matrices_combined.gdshader",
		"title": "Combined",
		"code": "translate → rotate → scale",
		"sliders": [["Translate X", -0.5, 0.5, 0.0, 0.01], ["Translate Y", -0.5, 0.5, 0.0, 0.01], ["Rotation", -6.28, 6.28, 0.0, 0.05], ["Scale", 0.3, 3.0, 1.0, 0.05], ["Animate", 0.0, 1.0, 0.0, 0.1]],
		"uniforms": ["translate_x", "translate_y", "rotation", "scale_val", "auto_animate"]
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
