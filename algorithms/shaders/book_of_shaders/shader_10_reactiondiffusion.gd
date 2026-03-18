## Shader 10: Reaction-Diffusion and DLA
## Simulation as pattern generation
extends Node3D

const DISPLAY_SIZE := Vector3(2.5, 2.5, 0.05)
const DISPLAY_GAP := 3.5
const PANEL_OFFSET_Z := 1.5

var panels: Array[ShaderRackPanel] = []
var materials: Array[ShaderMaterial] = []

var shader_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/dla_visual.gdshader",
		"title": "DLA Growth",
		"code": "branch = smoothstep(r, r-e, dist + noise);",
		"sliders": [["Scale", 1.0, 8.0, 3.0, 0.5], ["Growth", 0.0, 2.0, 1.0, 0.05], ["Density", 0.3, 0.9, 0.55, 0.05]],
		"uniforms": ["scale", "growth", "branch_density"]
	}
]


func _ready() -> void:
	# Check if existing reaction-diffusion shader exists, add as first display
	var rd_shader_path := "res://commons/resourses/shaders/reaction_diffusion.gdshader"
	var rd_shader = load(rd_shader_path)
	if rd_shader:
		var rd_display := MeshInstance3D.new()
		rd_display.name = "Display_RD"
		var box := BoxMesh.new()
		box.size = DISPLAY_SIZE
		rd_display.mesh = box
		var mat := ShaderMaterial.new()
		mat.shader = rd_shader
		rd_display.material_override = mat
		rd_display.position = Vector3(-DISPLAY_GAP * 0.5, 1.5, 0.0)
		add_child(rd_display)

		var title := Label3D.new()
		title.text = "Reaction-Diffusion"
		title.font_size = 18
		title.pixel_size = 0.001
		title.modulate = Color(0.92, 0.92, 0.94)
		title.position = Vector3(-DISPLAY_GAP * 0.5, 3.0, 0.01)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(title)

	# DLA display
	for i in range(shader_defs.size()):
		var def: Dictionary = shader_defs[i]
		var x_pos := DISPLAY_GAP * 0.5

		var display := MeshInstance3D.new()
		display.name = "Display_DLA_%d" % i
		var box2 := BoxMesh.new()
		box2.size = DISPLAY_SIZE
		display.mesh = box2
		var mat2 := ShaderMaterial.new()
		mat2.shader = load(def["shader"])
		display.material_override = mat2
		display.position = Vector3(x_pos, 1.5, 0.0)
		add_child(display)
		materials.append(mat2)

		var title2 := Label3D.new()
		title2.text = def["title"]
		title2.font_size = 18
		title2.pixel_size = 0.001
		title2.modulate = Color(0.92, 0.92, 0.94)
		title2.position = Vector3(x_pos, 3.0, 0.01)
		title2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(title2)

		var slider_count: int = def["sliders"].size()
		var panel := ShaderRackPanel.new()
		panel.setup(def["title"], mini(slider_count, 2), maxi(3, ceili(float(slider_count) / 2.0) + 2))
		panel.set_code_snippet(def["code"])
		for s in def["sliders"]:
			panel.add_slider(s[0], s[1], s[2], s[3], s[4])
		panel.position = Vector3(x_pos, 0.4, PANEL_OFFSET_Z)
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
