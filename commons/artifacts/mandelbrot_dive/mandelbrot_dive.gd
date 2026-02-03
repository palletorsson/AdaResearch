# mandelbrot_dive.gd
# GPU-accelerated Mandelbrot set on a 1×1m table
# VR-enabled with slider controls for zoom, pan, and palette

extends Node3D

class_name MandelbrotDive

## Table dimensions
@export var table_size: float = 1.0

## Fractal parameters
@export var max_iterations: int = 100:
	set(value):
		max_iterations = clampi(value, 20, 500)
		_update_shader_params()

@export var zoom: float = 1.0:
	set(value):
		zoom = clampf(value, 0.0001, 1000000.0)
		_update_shader_params()
		_sync_zoom_slider()

@export var center_x: float = -0.5:
	set(value):
		center_x = value
		_update_shader_params()

@export var center_y: float = 0.0:
	set(value):
		center_y = value
		_update_shader_params()

## Color scheme
@export_enum("Classic", "Fire", "Ocean", "Neon", "Grayscale") var color_scheme: int = 0:
	set(value):
		color_scheme = clampi(value, 0, 4)
		_update_shader_params()
		_sync_palette_slider()

## Animation
@export var auto_zoom: bool = false
@export var zoom_speed: float = 0.5
@export var zoom_target_x: float = -0.743643887037151
@export var zoom_target_y: float = 0.131825904205330

var _display_mesh: MeshInstance3D
var _shader_material: ShaderMaterial
var _info_label: Label3D

# VR Controls
var _zoom_slider: Node
var _palette_slider: Node
var _control_panel: Node3D

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

const MANDELBROT_SHADER = """
shader_type spatial;
render_mode unshaded;

uniform float zoom = 1.0;
uniform vec2 center = vec2(-0.5, 0.0);
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
	vec2 uv = UV - 0.5;
	vec2 c = center + uv * 4.0 / zoom;
	
	vec2 z = vec2(0.0);
	int iter = 0;
	
	for (int i = 0; i < 500; i++) {
		if (i >= max_iter) break;
		if (dot(z, z) > 4.0) break;
		z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
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
	_display_mesh.name = "MandelbrotDisplay"
	
	var quad = QuadMesh.new()
	quad.size = Vector2(table_size, table_size)
	_display_mesh.mesh = quad
	
	_display_mesh.rotation_degrees = Vector3(-90, 0, 0)
	_display_mesh.position = Vector3(0, 0.01, 0)
	
	_shader_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = MANDELBROT_SHADER
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
	panel_mesh.size = Vector3(0.5, 0.18, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Zoom slider (logarithmic: 0.1 to 100000)
	_zoom_slider = SLIDER_HORIZONTAL.instantiate()
	_zoom_slider.name = "ZoomSlider"
	_zoom_slider.position = Vector3(-0.12, 0.04, 0)
	_zoom_slider.rotation_degrees.x = -30
	var zoom_label = _zoom_slider.get_node_or_null("Frame/LabelName")
	if zoom_label:
		zoom_label.text = "ZOOM"
	_control_panel.add_child(_zoom_slider)
	_zoom_slider.slider_moved.connect(_on_zoom_slider_moved)
	
	# Palette slider (0-4)
	_palette_slider = SLIDER_HORIZONTAL.instantiate()
	_palette_slider.name = "PaletteSlider"
	_palette_slider.position = Vector3(0.12, 0.04, 0)
	_palette_slider.rotation_degrees.x = -30
	var palette_label = _palette_slider.get_node_or_null("Frame/LabelName")
	if palette_label:
		palette_label.text = "COLOR"
	_control_panel.add_child(_palette_slider)
	_palette_slider.slider_moved.connect(_on_palette_slider_moved)
	
	# Zoom In / Out buttons
	var zoom_in_btn = PUSH_BUTTON.instantiate()
	zoom_in_btn.name = "ZoomInButton"
	zoom_in_btn.position = Vector3(-0.15, -0.04, 0)
	zoom_in_btn.rotation_degrees.x = -30
	_control_panel.add_child(zoom_in_btn)
	_add_button_label(zoom_in_btn, "+")
	var zoom_in_area = zoom_in_btn.get_node_or_null("InteractableAreaButton")
	if zoom_in_area:
		zoom_in_area.button_pressed.connect(func(): zoom *= 2.0)
	
	var zoom_out_btn = PUSH_BUTTON.instantiate()
	zoom_out_btn.name = "ZoomOutButton"
	zoom_out_btn.position = Vector3(-0.08, -0.04, 0)
	zoom_out_btn.rotation_degrees.x = -30
	_control_panel.add_child(zoom_out_btn)
	_add_button_label(zoom_out_btn, "-")
	var zoom_out_area = zoom_out_btn.get_node_or_null("InteractableAreaButton")
	if zoom_out_area:
		zoom_out_area.button_pressed.connect(func(): zoom /= 2.0)
	
	# Auto-dive button
	var dive_btn = PUSH_BUTTON.instantiate()
	dive_btn.name = "DiveButton"
	dive_btn.position = Vector3(0.02, -0.04, 0)
	dive_btn.rotation_degrees.x = -30
	_control_panel.add_child(dive_btn)
	_add_button_label(dive_btn, "DIVE")
	var dive_area = dive_btn.get_node_or_null("InteractableAreaButton")
	if dive_area:
		dive_area.button_pressed.connect(func(): auto_zoom = not auto_zoom)
	
	# Reset button
	var reset_btn = PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetButton"
	reset_btn.position = Vector3(0.12, -0.04, 0)
	reset_btn.rotation_degrees.x = -30
	_control_panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RST")
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_reset)
	
	call_deferred("_sync_sliders_deferred")

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 12
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

func _sync_sliders_deferred():
	_sync_zoom_slider()
	_sync_palette_slider()

func _sync_zoom_slider():
	if _zoom_slider and _zoom_slider.has_method("set_normalized_value"):
		# Logarithmic scale: zoom 0.1 to 100000
		var log_zoom = log(zoom) / log(10)  # -1 to 5
		var norm = (log_zoom + 1.0) / 6.0
		_zoom_slider.set_normalized_value(clampf(norm, 0, 1))

func _sync_palette_slider():
	if _palette_slider and _palette_slider.has_method("set_normalized_value"):
		_palette_slider.set_normalized_value(float(color_scheme) / 4.0)

func _on_zoom_slider_moved(_position):
	if _zoom_slider and _zoom_slider.has_method("get_normalized_value"):
		var norm = _zoom_slider.get_normalized_value()
		# Logarithmic: norm 0-1 maps to zoom 0.1 to 100000
		var log_zoom = norm * 6.0 - 1.0  # -1 to 5
		zoom = pow(10, log_zoom)

func _on_palette_slider_moved(_position):
	if _palette_slider and _palette_slider.has_method("get_normalized_value"):
		var norm = _palette_slider.get_normalized_value()
		color_scheme = int(norm * 4.99)

func _update_shader_params():
	if not _shader_material:
		return
	_shader_material.set_shader_parameter("zoom", zoom)
	_shader_material.set_shader_parameter("center", Vector2(center_x, center_y))
	_shader_material.set_shader_parameter("max_iter", max_iterations)
	_shader_material.set_shader_parameter("color_scheme", color_scheme)
	_update_info_label()

func _update_info_label():
	if not _info_label:
		return
	var scheme_names = ["Classic", "Fire", "Ocean", "Neon", "Gray"]
	_info_label.text = "MANDELBROT\nZoom: %.2e | %s" % [zoom, scheme_names[color_scheme]]

func _process(delta):
	if auto_zoom:
		zoom *= (1.0 + zoom_speed * delta)
		var lerp_speed = 0.5 * delta
		center_x = lerpf(center_x, zoom_target_x, lerp_speed)
		center_y = lerpf(center_y, zoom_target_y, lerp_speed)
		if zoom > 100:
			max_iterations = mini(500, int(100 + log(zoom) * 20))
		_update_shader_params()

func _reset():
	zoom = 1.0
	center_x = -0.5
	center_y = 0.0
	max_iterations = 100
	auto_zoom = false
	_update_shader_params()
	_sync_zoom_slider()

# Keep keyboard for desktop
func _input(event):
	if event is InputEventKey and event.pressed:
		var pan_amount = 0.1 / zoom
		match event.keycode:
			KEY_UP, KEY_EQUAL:
				zoom *= 1.5
			KEY_DOWN, KEY_MINUS:
				zoom /= 1.5
			KEY_W:
				center_y += pan_amount
			KEY_S:
				center_y -= pan_amount
			KEY_A:
				center_x -= pan_amount
			KEY_D:
				center_x += pan_amount
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5:
				color_scheme = event.keycode - KEY_1
			KEY_R:
				_reset()
			KEY_Z:
				auto_zoom = not auto_zoom
		_update_shader_params()

func set_zoom(value: float):
	zoom = value

func set_center(x: float, y: float):
	center_x = x
	center_y = y
	_update_shader_params()

func dive_to(x: float, y: float, target_zoom: float = 10000.0):
	zoom_target_x = x
	zoom_target_y = y
	auto_zoom = true