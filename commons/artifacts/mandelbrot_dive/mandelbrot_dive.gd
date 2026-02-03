# mandelbrot_dive.gd
# GPU-accelerated Mandelbrot set on a 1×1m table
# Infinite detail zoom - demonstrates self-similarity and fractals

extends Node3D

class_name MandelbrotDive

## Table dimensions
@export var table_size: float = 1.0

## Fractal parameters
@export var max_iterations: int = 100:
	set(value):
		max_iterations = value
		_update_shader_params()

@export var zoom: float = 1.0:
	set(value):
		zoom = clampf(value, 0.0001, 1000000.0)
		_update_shader_params()

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
		color_scheme = value
		_update_shader_params()

## Animation
@export var auto_zoom: bool = false
@export var zoom_speed: float = 0.5
@export var zoom_target_x: float = -0.743643887037151
@export var zoom_target_y: float = 0.131825904205330

var _display_mesh: MeshInstance3D
var _shader_material: ShaderMaterial
var _info_label: Label3D

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
	// Map UV to complex plane
	vec2 uv = UV - 0.5;
	float aspect = 1.0;
	
	vec2 c = center + uv * 4.0 / zoom;
	
	// Mandelbrot iteration
	vec2 z = vec2(0.0);
	int iter = 0;
	
	for (int i = 0; i < 500; i++) {
		if (i >= max_iter) break;
		if (dot(z, z) > 4.0) break;
		
		z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + c;
		iter++;
	}
	
	// Color based on iteration count
	if (iter >= max_iter) {
		ALBEDO = vec3(0.0);
	} else {
		// Smooth coloring
		float log_zn = log(dot(z, z)) / 2.0;
		float nu = log(log_zn / log(2.0)) / log(2.0);
		float smooth_iter = float(iter) + 1.0 - nu;
		
		float t = smooth_iter / float(max_iter);
		ALBEDO = get_color(fract(t * 5.0), color_scheme);
	}
	
	// Slight emission for glow
	EMISSION = ALBEDO * 0.2;
}
"""

func _ready():
	_create_table()
	_create_display()
	_create_info_label()
	_create_controls_hint()

func _create_table():
	# Pedestal/base
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
	
	# Rotate to be horizontal (face up)
	_display_mesh.rotation_degrees = Vector3(-90, 0, 0)
	_display_mesh.position = Vector3(0, 0.01, 0)
	
	# Create shader material
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

func _create_controls_hint():
	var hint = Label3D.new()
	hint.name = "ControlsHint"
	hint.pixel_size = 0.001
	hint.font_size = 20
	hint.text = "↑↓ Zoom  |  WASD Pan  |  1-5 Colors  |  A Auto-dive"
	hint.position = Vector3(0, 0.03, table_size/2 + 0.05)
	hint.modulate = Color(0.6, 0.6, 0.6)
	add_child(hint)

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
	_info_label.text = "MANDELBROT\nZoom: %.2e\nIter: %d | %s" % [zoom, max_iterations, scheme_names[color_scheme]]

func _process(delta):
	if auto_zoom:
		# Gradually zoom toward interesting point
		zoom *= (1.0 + zoom_speed * delta)
		
		# Lerp center toward target
		var lerp_speed = 0.5 * delta
		center_x = lerpf(center_x, zoom_target_x, lerp_speed)
		center_y = lerpf(center_y, zoom_target_y, lerp_speed)
		
		# Increase iterations as we zoom deeper
		if zoom > 100:
			max_iterations = mini(500, int(100 + log(zoom) * 20))
		
		_update_shader_params()

func _input(event):
	if event is InputEventKey and event.pressed:
		var pan_amount = 0.1 / zoom
		
		match event.keycode:
			KEY_UP, KEY_EQUAL, KEY_KP_ADD:
				zoom *= 1.5
			KEY_DOWN, KEY_MINUS, KEY_KP_SUBTRACT:
				zoom /= 1.5
			KEY_W:
				center_y += pan_amount
			KEY_S:
				center_y -= pan_amount
			KEY_A:
				center_x -= pan_amount
			KEY_D:
				center_x += pan_amount
			KEY_1:
				color_scheme = 0
			KEY_2:
				color_scheme = 1
			KEY_3:
				color_scheme = 2
			KEY_4:
				color_scheme = 3
			KEY_5:
				color_scheme = 4
			KEY_R:
				_reset()
			KEY_Z:
				auto_zoom = not auto_zoom
		
		_update_shader_params()

func _reset():
	zoom = 1.0
	center_x = -0.5
	center_y = 0.0
	max_iterations = 100
	auto_zoom = false
	_update_shader_params()

## External control methods
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
