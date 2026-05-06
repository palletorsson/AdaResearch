# curvature_slider.gd
# Slider controlling curvature: negative (hyperbolic) ↔ zero (flat) ↔ positive (elliptic)

extends Node3D
class_name CurvatureSlider

# @identity
# essence: K ∈ [-1, +1] — Gaussian curvature as continuous parameter
# desire: slide between hyperbolic, flat, and elliptic geometry with one hand
# critical_parameter: curvature — the ONE number that determines the entire geometry
# triggers: slider movement emits curvature_changed signal, updates label with geometry type
# emerges: the intuition that geometry is not fixed — it is a parameter you can vary
# needs: VR horizontal slider [has]
# relationships: controls hyperbolic_surface (K<0) and elliptic_surface (K>0); depends on euclid_postulates_plaque (the fifth postulate IS the curvature assumption)
# truth: flat space is not the default — it is the singular boundary between two infinite families of geometries

signal curvature_changed(value: float)

@export var curvature: float = 0.0  # -1 to +1

var _slider: Node
var _label: Label3D
var _indicator: MeshInstance3D

func _ready():
	_create_controls()
	_create_label()

func _create_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_parameter_panel(1, ["CURVATURE K"], [0.5])
	add_child(panel)
	_slider = panel.get_node_or_null("Param_0")
	if _slider and _slider.has_signal("slider_moved"):
		_slider.slider_moved.connect(_on_slider_moved)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 14
	_label.text = "CURVATURE: K = 0\n(Flat/Euclidean)"
	_label.position = Vector3(0, 0.18, 0)
	_label.modulate = Color(0.1, 0.1, 0.1)
	add_child(_label)

func _on_slider_moved(_pos):
	if _slider and _slider.has_method("get_normalized_value"):
		curvature = _slider.get_normalized_value() * 2.0 - 1.0  # Map 0-1 to -1 to +1
		_update_label()
		curvature_changed.emit(curvature)

func _update_label():
	var type_str = "Flat/Euclidean"
	if curvature < -0.1:
		type_str = "Hyperbolic"
	elif curvature > 0.1:
		type_str = "Elliptic"
	_label.text = "CURVATURE: K = %.2f\n(%s)" % [curvature, type_str]


func apply_grid_config(config_data: Dictionary) -> void:
	pass
