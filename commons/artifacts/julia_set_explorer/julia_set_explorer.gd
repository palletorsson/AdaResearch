# julia_set_explorer.gd
# GPU-accelerated Julia set on a 1×1m table
# VR-enabled with c-parameter control — the Mandelbrot's sibling
#
# Julia sets: fix c, vary z₀ (each pixel is a starting point)
# Mandelbrot: fix z₀=0, vary c (each pixel is a c value)
# Connected Julia sets come from c values INSIDE the Mandelbrot

extends Node3D

class_name JuliaSetExplorer

## Table dimensions
@export var table_size: float = 1.0

## Julia parameters
@export var max_iterations: int = 100:
	set(value):
		max_iterations = clampi(value, 20, 500)
		_update_shader_params()

@export var c_real: float = -0.7:
	set(value):
		c_real = clampf(value, -2.0, 2.0)
		_update_shader_params()
		_sync_c_real_slider()

@export var c_imag: float = 0.27015:
	set(value):
		c_imag = clampf(value, -2.0, 2.0)
		_update_shader_params()
		_sync_c_imag_slider()

@export var zoom: float = 1.0:
	set(value):
		zoom = clampf(value, 0.1, 100.0)
		_update_shader_params()

## Color scheme
@export_enum("Classic", "Fire", "Ocean", "Neon", "Grayscale") var color_scheme: int = 0:
	set(value):
		color_scheme = clampi(value, 0, 4)
		_update_shader_params()

## Presets - famous Julia sets
const PRESETS = {
	0: [-0.7, 0.27015, "Dendrite"],
	1: [-0.8, 0.156, "San Marco"],
	2: [-0.4, 0.6, "Rabbit"],
	3: [0.285, 0.01, "Spiral"],
	4: [-0.70176, -0.3842, "Dragon"],
	5: [-0.835, -0.2321, "Douady Rabbit"],
}

var _display_mesh: MeshInstance3D
var _shader_material: ShaderMaterial
var _info_label: Label3D

# VR Controls
var _c_real_slider: Node
var _c_imag_slider: Node
var _control_panel: Node3D

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

const JULIA_SHADER = """
shader_type spatial;
render_mode unshaded;

uniform float zoom = 1.0;
uniform vec2 c_param = vec2(-0.7, 0.27015);
uniform int max_iter = 100;
uniform int color_scheme = 0;

vec3 palette_classic(float t) {
	return 0.5 + 0.5 * cos(6.28318 * (t + vec3(0.0, 0.1, 0.2)));
}

vec3 palette_fire(float t) {
	return vec3(
		smoothstep(0.0, 0.5, t),
		smoothstep(0.3, 0.8, t) * 0.8,
		smoothstep(0.7, 1.0, t) * 0.3
	);
}

vec3 palette_ocean(float t) {
	return vec3(
		smoothstep(0.7, 1.0, t) * 0.3,
		smoothstep(0.3, 0.8, t) * 0.7,
		smoothstep(0.0, 0.5, t)
	);
}

vec3 palette_neon(float t) {
	float r = sin(t * 6.28 + 0.0) * 0.5 + 0.5;
	float g = sin(t * 6.28 + 2.09) * 0.5 + 0.5;
	float b = sin(t * 6.28 + 4.18) * 0.5 + 0.5;
	return vec3(r, g, b) * 1.2;
}

vec3 palette_grayscale(float t) {
	return vec3(t);
}

vec3 get_color(float t, int scheme) {
	if (scheme == 0) return palette_classic(t);
	if (scheme == 1) return palette_fire(t);
	if (scheme == 2) return palette_ocean(t);
	if (scheme == 3) return palette_neon(t);
	return palette_grayscale(t);
}

void fragment() {
	// For Julia: each pixel is a starting z value
	vec2 uv = UV - 0.5;
	vec2 z = uv * 4.0 / zoom;
	
	int iter = 0;
	
	for (int i = 0; i < 500; i++) {
		if (i >= max_iter) break;
		if (dot(z, z) > 4.0) break;
		z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c_param;
		iter++;
	}
	
	if (iter >= max_iter) {
		ALBEDO = vec3(0.0);
	} else {
		float log_zn = log(dot(z, z)) / 2.0;
		float nu = log(log_zn / log(2.0)) / log(2.0);
		float smooth_iter = float(iter) + 1.0 - nu;
		float t = smooth_iter / float(max_iter);
		ALBEDO = get_color(fract(t * 5.0), color_scheme);
	}
	
	EMISSION = ALBEDO * 0.2;
}
"""

func _ready():
	_create_table()
	_create_display()
	_create_info_label()
	_create_vr_controls()

func _create_table():
	var base = MeshInstance3D.new()
	base.name = "Base"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = table_size * 0.55
	cylinder.bottom_radius = table_size * 0.6
	cylinder.height = 0.06
	base.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.15)
	mat.metallic = 0.7
	mat.roughness = 0.3
	base.material_override = mat
	
	base.position = Vector3(0, -0.03, 0)
	add_child(base)

func _create_display():
	_display_mesh = MeshInstance3D.new()
	_display_mesh.name = "JuliaDisplay"
	
	var quad = QuadMesh.new()
	quad.size = Vector2(table_size, table_size)
	_display_mesh.mesh = quad
	
	_display_mesh.rotation_degrees = Vector3(-90, 0, 0)
	_display_mesh.position = Vector3(0, 0.01, 0)
	
	_shader_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = JULIA_SHADER
	_shader_material.shader = shader
	
	_display_mesh.material_override = _shader_material
	add_child(_display_mesh)
	
	_update_shader_params()

func _create_info_label():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.0015
	_info_label.font_size = 24
	_info_label.position = Vector3(0, 0.04, -table_size/2 - 0.06)
	add_child(_info_label)
	_update_info_label()

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, table_size/2 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.5, 0.2, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# C real slider (-2 to 2)
	_c_real_slider = SLIDER_HORIZONTAL.instantiate()
	_c_real_slider.name = "CRealSlider"
	_c_real_slider.position = Vector3(-0.12, 0.05, 0)
	_c_real_slider.rotation_degrees.x = -30
	var real_label = _c_real_slider.get_node_or_null("Frame/LabelName")
	if real_label:
		real_label.text = "C REAL"
	_control_panel.add_child(_c_real_slider)
	_c_real_slider.slider_moved.connect(_on_c_real_slider_moved)
	
	# C imaginary slider (-2 to 2)
	_c_imag_slider = SLIDER_HORIZONTAL.instantiate()
	_c_imag_slider.name = "CImagSlider"
	_c_imag_slider.position = Vector3(0.12, 0.05, 0)
	_c_imag_slider.rotation_degrees.x = -30
	var imag_label = _c_imag_slider.get_node_or_null("Frame/LabelName")
	if imag_label:
		imag_label.text = "C IMAG"
	_control_panel.add_child(_c_imag_slider)
	_c_imag_slider.slider_moved.connect(_on_c_imag_slider_moved)
	
	# Preset buttons
	var preset_names = ["DEND", "MARCO", "RABBIT", "SPIRAL", "DRAG", "DOUADY"]
	for i in range(6):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.2 + (i % 3) * 0.1, -0.03 - floor(i / 3.0) * 0.05, 0)
		btn.scale = Vector3(0.8, 0.8, 0.8)
		_control_panel.add_child(btn)
		_add_button_label(btn, preset_names[i])
		
		var preset_idx = i
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(): _apply_preset(preset_idx))
	
	call_deferred("_sync_sliders_deferred")

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 8
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

func _sync_sliders_deferred():
	_sync_c_real_slider()
	_sync_c_imag_slider()

func _sync_c_real_slider():
	if _c_real_slider and _c_real_slider.has_method("set_normalized_value"):
		_c_real_slider.set_normalized_value((c_real + 2.0) / 4.0)

func _sync_c_imag_slider():
	if _c_imag_slider and _c_imag_slider.has_method("set_normalized_value"):
		_c_imag_slider.set_normalized_value((c_imag + 2.0) / 4.0)

func _on_c_real_slider_moved(_position):
	if _c_real_slider and _c_real_slider.has_method("get_normalized_value"):
		var norm = _c_real_slider.get_normalized_value()
		c_real = norm * 4.0 - 2.0

func _on_c_imag_slider_moved(_position):
	if _c_imag_slider and _c_imag_slider.has_method("get_normalized_value"):
		var norm = _c_imag_slider.get_normalized_value()
		c_imag = norm * 4.0 - 2.0

func _apply_preset(idx: int):
	if PRESETS.has(idx):
		var p = PRESETS[idx]
		c_real = p[0]
		c_imag = p[1]

func _update_shader_params():
	if not _shader_material:
		return
	_shader_material.set_shader_parameter("zoom", zoom)
	_shader_material.set_shader_parameter("c_param", Vector2(c_real, c_imag))
	_shader_material.set_shader_parameter("max_iter", max_iterations)
	_shader_material.set_shader_parameter("color_scheme", color_scheme)
	_update_info_label()

func _update_info_label():
	if not _info_label:
		return
	var preset_name = ""
	for key in PRESETS:
		var p = PRESETS[key]
		if absf(p[0] - c_real) < 0.01 and absf(p[1] - c_imag) < 0.01:
			preset_name = " (%s)" % p[2]
			break
	_info_label.text = "JULIA SET%s\nc = %.3f + %.3fi" % [preset_name, c_real, c_imag]

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_LEFT:
				c_real -= 0.01
			KEY_RIGHT:
				c_real += 0.01
			KEY_UP:
				c_imag += 0.01
			KEY_DOWN:
				c_imag -= 0.01
			KEY_EQUAL:
				zoom *= 1.5
			KEY_MINUS:
				zoom /= 1.5
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
				_apply_preset(event.keycode - KEY_1)
		_update_shader_params()

func set_c(real: float, imag: float):
	c_real = real
	c_imag = imag

func get_c() -> Vector2:
	return Vector2(c_real, c_imag)