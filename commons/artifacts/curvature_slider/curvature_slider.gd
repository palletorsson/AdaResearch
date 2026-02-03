# curvature_slider.gd
# Slider controlling curvature: negative (hyperbolic) ↔ zero (flat) ↔ positive (elliptic)

extends Node3D

signal curvature_changed(value: float)

@export var curvature: float = 0.0  # -1 to +1

var _slider: Node
var _label: Label3D
var _indicator: MeshInstance3D

const SLIDER_H = preload("res://commons/interactables/slider_horizontal.tscn")

func _ready():
	_create_slider()
	_create_label()

func _create_slider():
	if SLIDER_H:
		_slider = SLIDER_H.instantiate()
		_slider.position = Vector3(0, 0, 0)
		add_child(_slider)
		if _slider.has_signal("slider_moved"):
			_slider.slider_moved.connect(_on_slider_moved)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 14
	_label.text = "CURVATURE: K = 0\n(Flat/Euclidean)"
	_label.position = Vector3(0, 0.1, 0)
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
