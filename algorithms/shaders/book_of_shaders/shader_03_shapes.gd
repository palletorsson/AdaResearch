## Shader 03: Shapes — SDF circles, rects, polygons
## Book of Shaders Chapter 7

# @identity
# essence: d = length(uv) - radius — signed distance fields reduce geometry to a single number per pixel: negative inside, zero on boundary, positive outside
# desire: to slide polygon sides from 3 to 12 and watch a triangle become a circle — to boolean-combine shapes with min/max and see geometry as arithmetic
# critical_parameter: radius/sides — the number that separates inside from outside, or the symmetry order of the polygon
# triggers: operation slider switches between union(min), intersection(max), and subtraction(max(a,-b)) — three words, three operators, infinite compositions
# emerges: the show_distance toggle reveals the full SDF field — smooth hills radiating from every boundary, making the implicit geometry explicit
# needs: [has] ShaderRackPanel sliders per display; [missing] no VR push buttons
# relationships: depends on shader_01_shaping (smoothstep for anti-aliasing); feeds into shader_05_patterns (tiled SDF shapes) and all procedural geometry
# truth: the shape is not stored — it is perpetually computed; distance is the oldest geometric concept, and the fragment shader asks it millions of times per frame

extends Node3D

const DISPLAY_SIZE := Vector3(2.0, 2.0, 0.05)
const DISPLAY_GAP := 2.8
const PANEL_OFFSET_Z := 1.2

var panels: Array[ShaderRackPanel] = []
var materials: Array[ShaderMaterial] = []

var shader_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/shapes_circle.gdshader",
		"title": "SDF Circle",
		"code": "float d = length(uv) - radius;",
		"sliders": [["Radius", 0.05, 0.5, 0.3, 0.01], ["Softness", 0.0, 0.1, 0.01, 0.005], ["Show SDF", 0.0, 1.0, 0.0, 1.0]],
		"uniforms": ["radius", "softness", "show_distance"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/shapes_rect.gdshader",
		"title": "SDF Rectangle",
		"code": "float d = sdf_box(uv, size, r);",
		"sliders": [["Width", 0.05, 0.9, 0.5, 0.01], ["Height", 0.05, 0.9, 0.4, 0.01], ["Corner R", 0.0, 0.2, 0.0, 0.005]],
		"uniforms": ["width", "height", "corner_radius"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/shapes_combination.gdshader",
		"title": "Boolean Ops",
		"code": "union / intersect / subtract",
		"sliders": [["Operation", 0.0, 2.0, 0.0, 1.0], ["Circle X", -0.5, 0.5, 0.3, 0.01], ["Circle R", 0.1, 0.5, 0.35, 0.01]],
		"uniforms": ["operation", "circle_x", "circle_r"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/shapes_polygon.gdshader",
		"title": "Polygon",
		"code": "n sides via angular repetition",
		"sliders": [["Sides", 3.0, 12.0, 6.0, 1.0], ["Size", 0.1, 0.8, 0.4, 0.01], ["Spin", 0.0, 2.0, 0.3, 0.1]],
		"uniforms": ["sides", "size", "rotation_speed"]
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
