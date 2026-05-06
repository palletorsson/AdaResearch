# subpixel_display.gd
# Subpixel Display — shows how screens create color from RGB subpixels
# A large "pixel" made of 3 vertical bars (R, G, B) with adjustable intensity.
# Above, a single quad shows the mixed color. Label shows hex value.
#
# @identity
# essence: additive color mixing at the hardware level — red + green + blue = everything
# desire: drag three sliders, watch three bars glow, see the mixed color emerge above
# critical_parameter: emission_energy on each bar — intensity maps directly to channel value 0-1
# triggers: slider_moved on R/G/B sliders updates bar emission and combined quad
# emerges: understanding that white is all channels full, black is all off, and every color is a recipe
# needs: RackTemplates panel [has]; BoxMesh bars with emission [has]; QuadMesh combined swatch [has]
# relationships: feeds into gradient_interpolator (color mixing); sibling to colorspaces (both explore color representation)
# truth: Every pixel on every screen is three tiny lights pretending to be one color.

extends Node3D

class_name SubpixelDisplay

# ── Bars ──────────────────────────────────────────────────────────────────────
@export var bar_width: float = 0.02
@export var bar_height: float = 0.15
@export var bar_depth: float = 0.05
@export var bar_spacing: float = 0.005

# ── State ─────────────────────────────────────────────────────────────────────
var _r: float = 1.0
var _g: float = 0.5
var _b: float = 0.2
var _bar_r: MeshInstance3D
var _bar_g: MeshInstance3D
var _bar_b: MeshInstance3D
var _mat_r: StandardMaterial3D
var _mat_g: StandardMaterial3D
var _mat_b: StandardMaterial3D
var _combined_quad: MeshInstance3D
var _combined_mat: StandardMaterial3D
var _hex_label: Label3D


func _ready() -> void:
	_build_subpixel_bars()
	_build_combined_swatch()
	_build_hex_label()
	_build_panel()
	_update_display()


# ═════════════════════════════════════════════════════════════════════════════
# SUBPIXEL BARS
# ═════════════════════════════════════════════════════════════════════════════

func _build_subpixel_bars() -> void:
	var total_w: float = bar_width * 3 + bar_spacing * 2
	var start_x: float = -total_w / 2.0 + bar_width / 2.0
	var bar_y: float = 0.25

	# Red bar
	_bar_r = _make_bar(Color.RED)
	_bar_r.position = Vector3(start_x, bar_y, 0)
	_mat_r = _bar_r.material_override
	add_child(_bar_r)

	# Green bar
	_bar_g = _make_bar(Color.GREEN)
	_bar_g.position = Vector3(start_x + bar_width + bar_spacing, bar_y, 0)
	_mat_g = _bar_g.material_override
	add_child(_bar_g)

	# Blue bar
	_bar_b = _make_bar(Color.BLUE)
	_bar_b.position = Vector3(start_x + (bar_width + bar_spacing) * 2, bar_y, 0)
	_mat_b = _bar_b.material_override
	add_child(_bar_b)

	# Dark housing behind bars
	var housing := MeshInstance3D.new()
	var hbox := BoxMesh.new()
	hbox.size = Vector3(total_w + 0.02, bar_height + 0.02, bar_depth + 0.01)
	housing.mesh = hbox
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.04, 0.04, 0.04)
	housing.material_override = hmat
	housing.position = Vector3(0, bar_y, -0.008)
	add_child(housing)


func _make_bar(channel: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(bar_width, bar_height, bar_depth)
	mi.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = channel
	mat.emission_enabled = true
	mat.emission = channel
	mat.emission_energy_multiplier = 1.0
	mi.material_override = mat

	return mi


# ═════════════════════════════════════════════════════════════════════════════
# COMBINED SWATCH
# ═════════════════════════════════════════════════════════════════════════════

func _build_combined_swatch() -> void:
	_combined_quad = MeshInstance3D.new()
	_combined_quad.name = "CombinedSwatch"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.1, 0.1)
	_combined_quad.mesh = quad

	_combined_mat = StandardMaterial3D.new()
	_combined_mat.albedo_color = Color(_r, _g, _b)
	_combined_mat.emission_enabled = true
	_combined_mat.emission = Color(_r, _g, _b)
	_combined_mat.emission_energy_multiplier = 0.5
	_combined_quad.material_override = _combined_mat

	_combined_quad.position = Vector3(0, 0.46, 0.01)
	add_child(_combined_quad)


# ═════════════════════════════════════════════════════════════════════════════
# HEX LABEL
# ═════════════════════════════════════════════════════════════════════════════

func _build_hex_label() -> void:
	_hex_label = Label3D.new()
	_hex_label.name = "HexLabel"
	_hex_label.text = "#FFFFFF"
	_hex_label.pixel_size = 0.0015
	_hex_label.font_size = 16
	_hex_label.modulate = Color(0.9, 0.9, 0.95)
	_hex_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hex_label.position = Vector3(0, 0.54, 0.01)
	add_child(_hex_label)


# ═════════════════════════════════════════════════════════════════════════════
# PANEL
# ═════════════════════════════════════════════════════════════════════════════

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("SUBPIXEL", [
		[{"type": "slider_h", "label": "RED", "default": 1.0}],
		[{"type": "slider_h", "label": "GREEN", "default": 0.5}],
		[{"type": "slider_h", "label": "BLUE", "default": 0.2}],
	])
	panel.position = Vector3(0, 0.02, 0.06)
	panel.rotation_degrees = Vector3(-20, 0, 0)
	add_child(panel)

	# R slider (Param_0)
	var r_slider: Node = panel.find_child("Param_0", true, false)
	if r_slider and r_slider.has_signal("slider_moved"):
		r_slider.slider_moved.connect(_on_r_slider)

	# G slider (Param_1)
	var g_slider: Node = panel.find_child("Param_1", true, false)
	if g_slider and g_slider.has_signal("slider_moved"):
		g_slider.slider_moved.connect(_on_g_slider)

	# B slider (Param_2)
	var b_slider: Node = panel.find_child("Param_2", true, false)
	if b_slider and b_slider.has_signal("slider_moved"):
		b_slider.slider_moved.connect(_on_b_slider)


func _on_r_slider(_value: float) -> void:
	var slider: Node = get_node_or_null("SUBPIXEL/Param_0")
	if slider and slider.has_method("get_normalized_value"):
		_r = slider.get_normalized_value()
		_update_display()


func _on_g_slider(_value: float) -> void:
	var slider: Node = get_node_or_null("SUBPIXEL/Param_1")
	if slider and slider.has_method("get_normalized_value"):
		_g = slider.get_normalized_value()
		_update_display()


func _on_b_slider(_value: float) -> void:
	var slider: Node = get_node_or_null("SUBPIXEL/Param_2")
	if slider and slider.has_method("get_normalized_value"):
		_b = slider.get_normalized_value()
		_update_display()


func _update_display() -> void:
	# Update bar emissions
	_mat_r.emission = Color(_r, 0, 0)
	_mat_r.emission_energy_multiplier = _r * 2.0
	_mat_r.albedo_color = Color(_r, 0, 0)

	_mat_g.emission = Color(0, _g, 0)
	_mat_g.emission_energy_multiplier = _g * 2.0
	_mat_g.albedo_color = Color(0, _g, 0)

	_mat_b.emission = Color(0, 0, _b)
	_mat_b.emission_energy_multiplier = _b * 2.0
	_mat_b.albedo_color = Color(0, 0, _b)

	# Update combined swatch
	var mixed := Color(_r, _g, _b)
	_combined_mat.albedo_color = mixed
	_combined_mat.emission = mixed
	_combined_mat.emission_energy_multiplier = 0.5

	# Update hex label
	var ri := int(_r * 255)
	var gi := int(_g * 255)
	var bi := int(_b * 255)
	_hex_label.text = "#%02X%02X%02X" % [ri, gi, bi]


func apply_grid_config(config: Dictionary) -> void:
	pass
