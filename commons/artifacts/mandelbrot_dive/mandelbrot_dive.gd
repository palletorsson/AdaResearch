# mandelbrot_dive.gd
# GPU-accelerated Mandelbrot set on a 1×1m table
# VR-enabled with slider controls for zoom, pan, and palette
#
# @identity
# essence: z = z² + c, iterated. Escape or stay forever. The boundary between these is infinitely complex.
# desire: To be zoomed into. To reveal that every magnification contains the whole. To never end.
# critical_parameter: Zoom depth. At 10x you see the cardioid. At 10000x you see seahorses. At 10^15 you see copies of yourself.
# triggers: Zoom slider → deeper structure, palette switch → different beauty from same math, auto-dive → the infinite descent
# emerges: Self-similarity from iteration. The Mandelbrot set from the simplest possible complex map. Beauty from z²+c.
# needs: VR zoom slider [has], palette selector [has], auto-dive [has]. Could use: Julia set toggle (show connected set for current c).
# relationships: Contains all Julia sets as slices. Connects to fractals sequence. Demonstrates escape-time algorithms.
# truth: The simplest equation in complex dynamics produces the most complex object in mathematics.

extends Node3D

class_name MandelbrotDive

## Implements the Mandelbrot set escape-time algorithm to visualize complex dynamics.
## Each pixel maps to a point c in the complex plane; the iteration z = z² + c
## determines whether c escapes to infinity. Smooth coloring uses a normalized
## iteration count with log-log smoothing. A GPU shader performs the per-pixel
## computation while GDScript handles zoom, pan, palette selection, and VR controls.
## Key parameters: max_iterations controls detail depth, zoom/center navigate the plane.

# --- Constants ---
const MIN_ZOOM: float = 0.0001
const MAX_ZOOM: float = 1000000.0
const MAX_ITER_CAP: int = 500
const MIN_ITER: int = 20
const DEFAULT_ITERATIONS: int = 100
const ZOOM_LOG_MIN: float = -1.0
const ZOOM_LOG_RANGE: float = 6.0
const PALETTE_COUNT: int = 5
const PAN_BASE: float = 0.1
const KEYBOARD_ZOOM_STEP: float = 1.5
const BUTTON_ZOOM_STEP: float = 2.0
const AUTO_ZOOM_ITER_BASE: int = 100
const AUTO_ZOOM_ITER_LOG_SCALE: float = 20.0
const AUTO_ZOOM_LERP_BASE: float = 0.5
## Famous deep-zoom coordinates in the Mandelbrot set (Seahorse Valley)
const DEFAULT_TARGET_X: float = -0.743643887037151
const DEFAULT_TARGET_Y: float = 0.131825904205330

## Table width and depth in meters
@export_range(0.2, 3.0, 0.1) var table_size: float = 1.0

## Maximum escape-time iterations (higher = more detail, slower)
@export_range(20, 500) var max_iterations: int = DEFAULT_ITERATIONS:
	set(value):
		max_iterations = clampi(value, MIN_ITER, MAX_ITER_CAP)
		_update_shader_params()

## Current zoom level (logarithmic; 1.0 = full set visible)
@export_range(0.0001, 1000000.0) var zoom: float = 1.0:
	set(value):
		zoom = clampf(value, MIN_ZOOM, MAX_ZOOM)
		_update_shader_params()
		_sync_zoom_slider()

## Real-axis center of the viewport in the complex plane
@export_range(-3.0, 3.0, 0.001) var center_x: float = -0.5:
	set(value):
		center_x = value
		_update_shader_params()

## Imaginary-axis center of the viewport in the complex plane
@export_range(-3.0, 3.0, 0.001) var center_y: float = 0.0:
	set(value):
		center_y = value
		_update_shader_params()

## Color palette applied to the escape-time gradient
@export_enum("Classic", "Fire", "Ocean", "Neon", "Grayscale") var color_scheme: int = 0:
	set(value):
		color_scheme = clampi(value, 0, PALETTE_COUNT - 1)
		_update_shader_params()
		_sync_palette_slider()

## Whether the camera auto-zooms toward the target coordinates
@export var auto_zoom: bool = false
## Speed multiplier for the auto-zoom animation
@export_range(0.01, 5.0, 0.01) var zoom_speed: float = 0.5
## Auto-zoom target real coordinate
@export_range(-3.0, 3.0, 0.0001) var zoom_target_x: float = DEFAULT_TARGET_X
## Auto-zoom target imaginary coordinate
@export_range(-3.0, 3.0, 0.0001) var zoom_target_y: float = DEFAULT_TARGET_Y

var _display_mesh: MeshInstance3D
var _shader_material: ShaderMaterial
var _info_label: Label3D
var _created_nodes: Array[Node] = []

# VR Controls
var _zoom_slider: Node
var _palette_slider: Node
var _control_panel: Node3D

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

const MANDELBROT_SHADER = """
shader_type spatial;
render_mode unshaded, cull_disabled;

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
		ALBEDO = get_color(fmod(t * 5.0, 1.0), color_scheme);
	}

	EMISSION = ALBEDO * 0.2;
}
"""

func _ready() -> void:
	_create_table()
	_create_display()
	_create_info_label()
	_create_vr_controls()

## Builds the cylindrical table base that holds the fractal display.
func _create_table() -> void:
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
	_created_nodes.append(base)

## Creates the quad mesh that displays the Mandelbrot shader.
func _create_display() -> void:
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
	_created_nodes.append(_display_mesh)

	_update_shader_params()

## Creates the 3D label showing current zoom level and palette name.
func _create_info_label() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.0015
	_info_label.font_size = 24
	_info_label.position = Vector3(0, 0.04, -table_size / 2.0 - 0.06)
	add_child(_info_label)
	_created_nodes.append(_info_label)
	_update_info_label()

## Assembles VR control panel with sliders and buttons for zoom, palette, and navigation.
func _create_vr_controls() -> void:
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, table_size / 2.0 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	_created_nodes.append(_control_panel)

	_create_panel_backing()
	_create_sliders()
	_create_buttons()

	call_deferred("_sync_sliders_deferred")

## Adds the dark background mesh behind the control panel.
func _create_panel_backing() -> void:
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

## Creates zoom and palette VR sliders on the control panel.
func _create_sliders() -> void:
	_zoom_slider = SLIDER_HORIZONTAL.instantiate()
	_zoom_slider.name = "ZoomSlider"
	_zoom_slider.position = Vector3(-0.12, 0.04, 0)
	_zoom_slider.rotation_degrees.x = -30
	var zoom_label = _zoom_slider.get_node_or_null("Frame/LabelName")
	if zoom_label:
		zoom_label.text = "ZOOM"
	_control_panel.add_child(_zoom_slider)
	_zoom_slider.slider_moved.connect(_on_zoom_slider_moved)

	_palette_slider = SLIDER_HORIZONTAL.instantiate()
	_palette_slider.name = "PaletteSlider"
	_palette_slider.position = Vector3(0.12, 0.04, 0)
	_palette_slider.rotation_degrees.x = -30
	var palette_label = _palette_slider.get_node_or_null("Frame/LabelName")
	if palette_label:
		palette_label.text = "COLOR"
	_control_panel.add_child(_palette_slider)
	_palette_slider.slider_moved.connect(_on_palette_slider_moved)

## Creates zoom in/out, dive, and reset push buttons on the control panel.
func _create_buttons() -> void:
	var zoom_in_btn = PUSH_BUTTON.instantiate()
	zoom_in_btn.name = "ZoomInButton"
	zoom_in_btn.position = Vector3(-0.15, -0.04, 0)
	zoom_in_btn.rotation_degrees.x = -30
	_control_panel.add_child(zoom_in_btn)
	_add_button_label(zoom_in_btn, "+")
	var zoom_in_area = zoom_in_btn.get_node_or_null("InteractableAreaButton")
	if zoom_in_area:
		zoom_in_area.button_pressed.connect(func(_b): zoom *= BUTTON_ZOOM_STEP)

	var zoom_out_btn = PUSH_BUTTON.instantiate()
	zoom_out_btn.name = "ZoomOutButton"
	zoom_out_btn.position = Vector3(-0.08, -0.04, 0)
	zoom_out_btn.rotation_degrees.x = -30
	_control_panel.add_child(zoom_out_btn)
	_add_button_label(zoom_out_btn, "-")
	var zoom_out_area = zoom_out_btn.get_node_or_null("InteractableAreaButton")
	if zoom_out_area:
		zoom_out_area.button_pressed.connect(func(_b): zoom /= BUTTON_ZOOM_STEP)

	var dive_btn = PUSH_BUTTON.instantiate()
	dive_btn.name = "DiveButton"
	dive_btn.position = Vector3(0.02, -0.04, 0)
	dive_btn.rotation_degrees.x = -30
	_control_panel.add_child(dive_btn)
	_add_button_label(dive_btn, "DIVE")
	var dive_area = dive_btn.get_node_or_null("InteractableAreaButton")
	if dive_area:
		dive_area.button_pressed.connect(func(_b): auto_zoom = not auto_zoom)

	var reset_btn = PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetButton"
	reset_btn.position = Vector3(0.12, -0.04, 0)
	reset_btn.rotation_degrees.x = -30
	_control_panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RST")
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_reset)

## Adds a small text label below a push button.
func _add_button_label(btn: Node, text: String) -> void:
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 12
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

## Deferred call to sync both sliders after scene tree is ready.
func _sync_sliders_deferred() -> void:
	_sync_zoom_slider()
	_sync_palette_slider()

## Updates the zoom slider position to match current zoom (logarithmic scale).
func _sync_zoom_slider() -> void:
	if _zoom_slider and _zoom_slider.has_method("set_normalized_value"):
		var log_zoom = log(zoom) / log(10)
		var norm = (log_zoom - ZOOM_LOG_MIN) / ZOOM_LOG_RANGE
		_zoom_slider.set_normalized_value(clampf(norm, 0, 1))

## Updates the palette slider position to match current color scheme.
func _sync_palette_slider() -> void:
	if _palette_slider and _palette_slider.has_method("set_normalized_value"):
		_palette_slider.set_normalized_value(float(color_scheme) / float(PALETTE_COUNT - 1))

## Handles zoom slider input; converts normalized value to logarithmic zoom.
func _on_zoom_slider_moved(_position) -> void:
	if _zoom_slider and _zoom_slider.has_method("get_normalized_value"):
		var norm = _zoom_slider.get_normalized_value()
		var log_zoom = norm * ZOOM_LOG_RANGE + ZOOM_LOG_MIN
		zoom = pow(10, log_zoom)

## Handles palette slider input; maps normalized value to color scheme index.
func _on_palette_slider_moved(_position) -> void:
	if _palette_slider and _palette_slider.has_method("get_normalized_value"):
		var norm = _palette_slider.get_normalized_value()
		color_scheme = int(norm * (PALETTE_COUNT - 0.01))

## Pushes current fractal parameters to the GPU shader uniforms.
func _update_shader_params() -> void:
	if not _shader_material:
		return
	_shader_material.set_shader_parameter("zoom", zoom)
	_shader_material.set_shader_parameter("center", Vector2(center_x, center_y))
	_shader_material.set_shader_parameter("max_iter", max_iterations)
	_shader_material.set_shader_parameter("color_scheme", color_scheme)
	_update_info_label()

## Refreshes the info label with current zoom level and palette name.
func _update_info_label() -> void:
	if not _info_label:
		return
	var scheme_names = ["Classic", "Fire", "Ocean", "Neon", "Gray"]
	var zoom_text: String = "%.1f" % zoom if zoom < 1000 else "%.0f" % zoom
	_info_label.text = "MANDELBROT\nZoom: %s | %s" % [zoom_text, scheme_names[color_scheme]]

## Drives the auto-zoom animation, smoothly approaching the target coordinates.
func _process(delta: float) -> void:
	if auto_zoom:
		zoom *= (1.0 + zoom_speed * delta)
		var lerp_speed = AUTO_ZOOM_LERP_BASE * delta
		center_x = lerpf(center_x, zoom_target_x, lerp_speed)
		center_y = lerpf(center_y, zoom_target_y, lerp_speed)
		if zoom > 100:
			max_iterations = mini(MAX_ITER_CAP, int(AUTO_ZOOM_ITER_BASE + log(zoom) * AUTO_ZOOM_ITER_LOG_SCALE))
		_update_shader_params()

## Resets all fractal parameters to defaults.
func _reset() -> void:
	zoom = 1.0
	center_x = -0.5
	center_y = 0.0
	max_iterations = DEFAULT_ITERATIONS
	auto_zoom = false
	_update_shader_params()
	_sync_zoom_slider()

## Handles keyboard input for desktop zoom, pan, palette, and reset.
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var pan_amount = PAN_BASE / zoom
		match event.keycode:
			KEY_UP, KEY_EQUAL:
				zoom *= KEYBOARD_ZOOM_STEP
			KEY_DOWN, KEY_MINUS:
				zoom /= KEYBOARD_ZOOM_STEP
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

## Sets the zoom level programmatically.
func set_zoom(value: float) -> void:
	zoom = value

## Sets the viewport center in the complex plane.
func set_center(x: float, y: float) -> void:
	center_x = x
	center_y = y
	_update_shader_params()

## Starts an auto-zoom dive toward the given complex coordinates.
func dive_to(x: float, y: float, _target_zoom: float = 10000.0) -> void:
	zoom_target_x = x
	zoom_target_y = y
	auto_zoom = true

## Disconnects signals and frees dynamically created nodes.
func _exit_tree() -> void:
	if _zoom_slider and _zoom_slider.slider_moved.is_connected(_on_zoom_slider_moved):
		_zoom_slider.slider_moved.disconnect(_on_zoom_slider_moved)
	if _palette_slider and _palette_slider.slider_moved.is_connected(_on_palette_slider_moved):
		_palette_slider.slider_moved.disconnect(_on_palette_slider_moved)
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()

func apply_grid_config(config_data: Dictionary) -> void:
	pass
