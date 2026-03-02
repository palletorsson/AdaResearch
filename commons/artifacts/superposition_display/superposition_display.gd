# superposition_display.gd
# Visual representation of quantum superposition |ψ⟩ = α|0⟩ + β|1⟩

extends Node3D
class_name SuperpositionDisplay

var SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")

var _state_0: MeshInstance3D
var _state_1: MeshInstance3D
var _superposition: MeshInstance3D
var _label: Label3D
var _time: float = 0.0
var _speed: float = 2.0
var _slider: Node3D

func _ready():
	_create_states()
	_create_label()
	_setup_controls()

func _create_states():
	# |0⟩ state
	_state_0 = MeshInstance3D.new()
	var s0 = SphereMesh.new()
	s0.radius = 0.08
	s0.height = 0.16
	_state_0.mesh = s0
	_state_0.position = Vector3(-0.25, 0, 0)
	var mat0 = StandardMaterial3D.new()
	mat0.albedo_color = Color(0.3, 0.5, 1.0, 0.6)
	mat0.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_state_0.material_override = mat0
	add_child(_state_0)
	
	var lbl0 = Label3D.new()
	lbl0.text = "|0⟩"
	lbl0.pixel_size = 0.001
	lbl0.font_size = 14
	lbl0.position = Vector3(-0.25, 0.15, 0)
	add_child(lbl0)
	
	# |1⟩ state
	_state_1 = MeshInstance3D.new()
	var s1 = SphereMesh.new()
	s1.radius = 0.08
	s1.height = 0.16
	_state_1.mesh = s1
	_state_1.position = Vector3(0.25, 0, 0)
	var mat1 = StandardMaterial3D.new()
	mat1.albedo_color = Color(1.0, 0.5, 0.3, 0.6)
	mat1.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_state_1.material_override = mat1
	add_child(_state_1)
	
	var lbl1 = Label3D.new()
	lbl1.text = "|1⟩"
	lbl1.pixel_size = 0.001
	lbl1.font_size = 14
	lbl1.position = Vector3(0.25, 0.15, 0)
	add_child(lbl1)
	
	# Superposition (between them)
	_superposition = MeshInstance3D.new()
	var ss = SphereMesh.new()
	ss.radius = 0.1
	ss.height = 0.2
	_superposition.mesh = ss
	_superposition.position = Vector3(0, 0, 0)
	var mats = StandardMaterial3D.new()
	mats.albedo_color = Color(0.7, 0.4, 0.9, 0.7)
	mats.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mats.emission_enabled = true
	mats.emission = Color(0.5, 0.3, 0.7)
	mats.emission_energy_multiplier = 0.5
	_superposition.material_override = mats
	add_child(_superposition)

func _create_label():
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	_label.text = "SUPERPOSITION\n|ψ⟩ = α|0⟩ + β|1⟩\n\nBoth states at once\nuntil measurement"
	_label.position = Vector3(0, -0.25, 0)
	add_child(_label)

func _process(delta):
	_time += delta
	# Oscillate superposition
	var alpha = 0.5 + 0.3 * sin(_time * _speed)
	var beta = 1.0 - alpha
	
	var mat0 = _state_0.material_override as StandardMaterial3D
	var mat1 = _state_1.material_override as StandardMaterial3D
	mat0.albedo_color.a = 0.3 + 0.4 * alpha
	mat1.albedo_color.a = 0.3 + 0.4 * beta

func _setup_controls():
	_slider = SliderScene.instantiate()
	_slider.position = Vector3(0, 0.5, 0.6)
	_slider.set_param_name("Speed")
	_slider.set_normalized_value(0.25)
	_slider.slider_moved.connect(_on_speed_changed)
	add_child(_slider)

func _on_speed_changed():
	var val = _slider.get_normalized_value()
	_speed = 0.5 + val * 7.5

func apply_grid_config(config_data: Dictionary) -> void:
	pass
