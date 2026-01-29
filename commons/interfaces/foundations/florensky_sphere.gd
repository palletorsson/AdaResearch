# florensky_sphere.gd
# Pavel Florensky's paraconsistent logic visualized
# "A and not-A" — truth that holds contradiction without collapse
#
# Florensky (mathematician-priest, 1882-1937) argued that
# mystical/mathematical truth can be paradoxical:
# The infinite cannot be described positively, only by what it is NOT.
#
# This sphere simultaneously IS and IS NOT
# It holds both states without resolution — the queer signature

extends Node3D

class_name FlorenskySphere

signal state_observed(is_A: bool, is_not_A: bool)
signal superposition_entered()
signal superposition_collapsed()

## Sphere parameters
@export var radius: float = 0.3
@export var detail: int = 32

## State A color (assertion)
@export var color_A: Color = Color(0.2, 0.4, 1.0, 0.8)  # Blue

## State not-A color (negation)
@export var color_not_A: Color = Color(1.0, 0.3, 0.2, 0.8)  # Red

## Superposition color (A and not-A)
@export var color_both: Color = Color(0.8, 0.3, 1.0, 0.8)  # Purple

## Current logical state
enum LogicState { A, NOT_A, BOTH, NEITHER }
@export var current_state: LogicState = LogicState.BOTH

## Enable observation (collapses superposition temporarily)
@export var allow_observation: bool = true

# Internal
var _sphere: MeshInstance3D
var _inner_sphere: MeshInstance3D
var _glow: OmniLight3D
var _label: Label3D
var _state_label: Label3D
var _animation_time: float = 0.0
var _is_observed: bool = false
var _observation_timer: float = 0.0
const OBSERVATION_DURATION = 2.0

func _ready() -> void:
	_create_sphere()
	_create_inner_sphere()
	_create_glow()
	_create_labels()
	_create_interactable()
	_update_visual_state()
	print("FlorenskySphere: Ready — 'A and not-A'")

func _create_sphere() -> void:
	_sphere = MeshInstance3D.new()
	_sphere.name = "OuterSphere"
	
	var mesh = SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	mesh.radial_segments = detail
	mesh.rings = detail / 2
	_sphere.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color_both
	mat.metallic = 0.3
	mat.roughness = 0.4
	mat.rim_enabled = true
	mat.rim = 0.5
	mat.rim_tint = 0.3
	_sphere.material_override = mat
	
	add_child(_sphere)

func _create_inner_sphere() -> void:
	_inner_sphere = MeshInstance3D.new()
	_inner_sphere.name = "InnerSphere"
	
	var mesh = SphereMesh.new()
	mesh.radius = radius * 0.6
	mesh.height = radius * 1.2
	mesh.radial_segments = detail
	mesh.rings = detail / 2
	_inner_sphere.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1, 1, 1, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.5
	_inner_sphere.material_override = mat
	
	add_child(_inner_sphere)

func _create_glow() -> void:
	_glow = OmniLight3D.new()
	_glow.light_color = color_both
	_glow.light_energy = 1.0
	_glow.omni_range = 1.0
	add_child(_glow)

func _create_labels() -> void:
	# Title
	_label = Label3D.new()
	_label.text = "Florensky Sphere"
	_label.font_size = 24
	_label.position = Vector3(0, radius + 0.3, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color.WHITE
	_label.outline_size = 4
	_label.outline_modulate = Color.BLACK
	add_child(_label)
	
	# State display
	_state_label = Label3D.new()
	_state_label.text = "A ∧ ¬A"
	_state_label.font_size = 36
	_state_label.position = Vector3(0, 0, radius + 0.1)
	_state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_state_label.modulate = Color.WHITE
	_state_label.outline_size = 5
	_state_label.outline_modulate = Color.BLACK
	add_child(_state_label)
	
	# Explanation
	var explanation = Label3D.new()
	explanation.text = "Paraconsistent Logic\n'Truth that holds contradiction'"
	explanation.font_size = 14
	explanation.position = Vector3(0, -radius - 0.2, 0)
	explanation.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	explanation.modulate = Color(0.7, 0.7, 0.7, 0.9)
	explanation.outline_size = 3
	explanation.outline_modulate = Color.BLACK
	explanation.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(explanation)

func _create_interactable() -> void:
	var area = Area3D.new()
	area.name = "InteractableArea"
	
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = radius * 1.2
	collision.shape = shape
	area.add_child(collision)
	
	area.input_event.connect(_on_input_event)
	area.mouse_entered.connect(_on_hover_start)
	area.mouse_exited.connect(_on_hover_end)
	area.input_ray_pickable = true
	
	add_child(area)

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			observe()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			cycle_state()

func _on_hover_start() -> void:
	_glow.light_energy = 1.5

func _on_hover_end() -> void:
	_glow.light_energy = 1.0

func _process(delta: float) -> void:
	_animation_time += delta
	
	# Handle observation collapse timer
	if _is_observed:
		_observation_timer -= delta
		if _observation_timer <= 0:
			_is_observed = false
			current_state = LogicState.BOTH
			_update_visual_state()
			emit_signal("superposition_entered")
	
	# Animate based on state
	match current_state:
		LogicState.BOTH:
			_animate_superposition()
		LogicState.A, LogicState.NOT_A:
			_animate_collapsed()
		LogicState.NEITHER:
			_animate_void()

func _animate_superposition() -> void:
	# Oscillate between A and not-A colors
	var t = sin(_animation_time * 2.0) * 0.5 + 0.5
	var current_color = color_A.lerp(color_not_A, t)
	
	var mat = _sphere.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = current_color
	
	_glow.light_color = current_color
	
	# Inner sphere pulses
	var inner_mat = _inner_sphere.material_override as StandardMaterial3D
	if inner_mat:
		var pulse = sin(_animation_time * 4.0) * 0.5 + 0.5
		inner_mat.emission_energy_multiplier = 0.3 + pulse * 0.7
	
	# State label flickers between symbols
	if fmod(_animation_time, 0.5) < 0.25:
		_state_label.text = "A ∧ ¬A"
	else:
		_state_label.text = "¬(A ∨ ¬A)"

func _animate_collapsed() -> void:
	var target_color = color_A if current_state == LogicState.A else color_not_A
	
	var mat = _sphere.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = target_color
	
	_glow.light_color = target_color

func _animate_void() -> void:
	var mat = _sphere.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(0.2, 0.2, 0.2, 0.5)
	
	_glow.light_energy = 0.3

func _update_visual_state() -> void:
	match current_state:
		LogicState.A:
			_state_label.text = "A"
			_state_label.modulate = color_A
		LogicState.NOT_A:
			_state_label.text = "¬A"
			_state_label.modulate = color_not_A
		LogicState.BOTH:
			_state_label.text = "A ∧ ¬A"
			_state_label.modulate = color_both
		LogicState.NEITHER:
			_state_label.text = "¬A ∧ ¬(¬A)"
			_state_label.modulate = Color(0.5, 0.5, 0.5)

func observe() -> void:
	if not allow_observation:
		return
	
	if current_state == LogicState.BOTH:
		# Observation collapses superposition
		_is_observed = true
		_observation_timer = OBSERVATION_DURATION
		
		# Randomly collapse to A or not-A
		current_state = LogicState.A if randf() > 0.5 else LogicState.NOT_A
		_update_visual_state()
		
		emit_signal("superposition_collapsed")
		emit_signal("state_observed", current_state == LogicState.A, current_state == LogicState.NOT_A)
		
		print("FlorenskySphere: Observation collapsed state to %s" % ("A" if current_state == LogicState.A else "¬A"))
		print("FlorenskySphere: Will return to superposition in %.1f seconds" % OBSERVATION_DURATION)

func cycle_state() -> void:
	match current_state:
		LogicState.A:
			current_state = LogicState.NOT_A
		LogicState.NOT_A:
			current_state = LogicState.BOTH
		LogicState.BOTH:
			current_state = LogicState.NEITHER
		LogicState.NEITHER:
			current_state = LogicState.A
	
	_is_observed = false
	_update_visual_state()
	print("FlorenskySphere: State set to %s" % LogicState.keys()[current_state])

func set_state(state: LogicState) -> void:
	current_state = state
	_is_observed = false
	_update_visual_state()
