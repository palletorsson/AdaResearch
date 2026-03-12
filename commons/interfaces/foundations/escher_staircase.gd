# escher_staircase.gd
# An "impossible staircase" inspired by Escher/Penrose
# Locally coherent, globally impossible
# Visual demonstration of Gödel's incompleteness:
# Each local step is valid, but the global structure is paradoxical
#
# You can walk "up" forever and end where you started
# Or walk "down" forever and also end where you started

extends Node3D

class_name EscherStaircase

signal step_taken(step_index: int, direction: String)
signal paradox_completed()

## Staircase parameters
@export var steps_per_side: int = 4
@export var step_width: float = 0.4
@export var step_height: float = 0.15
@export var step_depth: float = 0.3
@export var inner_radius: float = 0.8

## Colors
@export var step_color: Color = Color(0.7, 0.7, 0.75)
@export var rail_color: Color = Color(0.3, 0.25, 0.2)
@export var glow_color: Color = Color(0.5, 0.8, 1.0)

## Animation
@export var rotate_view: bool = true
@export var rotation_speed: float = 0.1

# Internal
var _steps: Array[MeshInstance3D] = []
var _current_step: int = 0
var _total_steps: int = 0
var _steps_climbed: int = 0
var _animation_time: float = 0.0
var _paradox_label: Label3D

func _ready() -> void:
	_total_steps = steps_per_side * 4
	_create_staircase()
	_create_labels()
	_create_highlight()
	print("EscherStaircase: Ready — 'Locally valid, globally impossible'")

func _create_staircase() -> void:
	# Create 4 sides of stairs that form an impossible loop
	# The trick: each side goes "up" but connects back to start
	
	for side in range(4):
		var side_rotation = side * PI / 2
		
		for i in range(steps_per_side):
			var step = _create_step(side, i)
			_steps.append(step)
			add_child(step)

func _create_step(side: int, index: int) -> MeshInstance3D:
	var step = MeshInstance3D.new()
	step.name = "Step_%d_%d" % [side, index]
	
	var mesh = BoxMesh.new()
	mesh.size = Vector3(step_width, step_height, step_depth)
	step.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	# Alternate colors slightly for visibility
	var shade = 0.9 + (index % 2) * 0.1
	mat.albedo_color = step_color * shade
	mat.metallic = 0.1
	mat.roughness = 0.8
	step.material_override = mat
	
	# Position the step
	# Each step goes "up" but we use perspective tricks
	var angle = (side * steps_per_side + index) * (TAU / _total_steps)
	var radius = inner_radius + step_depth / 2
	
	# The "impossible" part: height increases linearly but wraps
	# We fake it by making each side appear to go up relative to viewer
	var apparent_height = index * step_height
	
	# Position in a square loop
	var side_angle = side * PI / 2
	var local_progress = float(index) / float(steps_per_side)
	
	var pos = Vector3.ZERO
	match side:
		0:  # Front side (going right)
			pos.x = -inner_radius + local_progress * inner_radius * 2
			pos.z = inner_radius
			pos.y = apparent_height
		1:  # Right side (going back)
			pos.x = inner_radius
			pos.z = inner_radius - local_progress * inner_radius * 2
			pos.y = apparent_height + steps_per_side * step_height
		2:  # Back side (going left)
			pos.x = inner_radius - local_progress * inner_radius * 2
			pos.z = -inner_radius
			pos.y = apparent_height + 2 * steps_per_side * step_height
		3:  # Left side (going front) - wraps back to start height
			pos.x = -inner_radius
			pos.z = -inner_radius + local_progress * inner_radius * 2
			# This is where the impossibility happens
			# Heights should be high, but we lerp back to 0
			var target_height = apparent_height + 3 * steps_per_side * step_height
			var wrap_factor = local_progress
			pos.y = lerp(target_height, 0.0, wrap_factor * wrap_factor)
	
	step.position = pos
	step.rotation.y = side_angle
	
	return step

func _create_labels() -> void:
	# Title
	var title = Label3D.new()
	title.text = "Escher Staircase"
	title.font_size = 32
	title.position = Vector3(0, 2.5, 0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color.WHITE
	title.outline_size = 5
	title.outline_modulate = Color.BLACK
	add_child(title)
	
	# Paradox explanation
	_paradox_label = Label3D.new()
	_paradox_label.text = "Locally coherent\nGlobally impossible"
	_paradox_label.font_size = 20
	_paradox_label.position = Vector3(0, 2.1, 0)
	_paradox_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_paradox_label.modulate = Color(0.8, 0.8, 0.8, 0.9)
	_paradox_label.outline_size = 4
	_paradox_label.outline_modulate = Color.BLACK
	_paradox_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_paradox_label)
	
	# Step counter
	var counter = Label3D.new()
	counter.name = "StepCounter"
	counter.text = "Steps climbed: 0"
	counter.font_size = 18
	counter.position = Vector3(0, -0.5, 0)
	counter.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	counter.modulate = Color(0.7, 0.7, 0.7)
	counter.outline_size = 3
	counter.outline_modulate = Color.BLACK
	add_child(counter)
	
	# Gödel connection
	var godel_note = Label3D.new()
	godel_note.text = "Like Gödel's theorem:\nEvery local step is valid.\nThe global conclusion is impossible."
	godel_note.font_size = 14
	godel_note.position = Vector3(0, -1.0, 0)
	godel_note.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	godel_note.modulate = Color(0.6, 0.6, 0.6, 0.8)
	godel_note.outline_size = 3
	godel_note.outline_modulate = Color.BLACK
	godel_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(godel_note)

func _create_highlight() -> void:
	# Glowing marker for current step
	var highlight = MeshInstance3D.new()
	highlight.name = "StepHighlight"
	var mesh = SphereMesh.new()
	mesh.radius = 0.1
	mesh.height = 0.2
	highlight.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = glow_color
	mat.emission_enabled = true
	mat.emission = glow_color
	mat.emission_energy_multiplier = 2.0
	highlight.material_override = mat
	
	add_child(highlight)
	_update_highlight()

func _update_highlight() -> void:
	var highlight = get_node_or_null("StepHighlight")
	if highlight and _current_step < _steps.size():
		highlight.position = _steps[_current_step].position + Vector3(0, step_height, 0)

func _process(delta: float) -> void:
	_animation_time += delta
	
	if rotate_view:
		rotation.y += delta * rotation_speed
	
	# Pulse the current step
	if _current_step < _steps.size():
		var step = _steps[_current_step]
		var mat = step.material_override as StandardMaterial3D
		if mat:
			var pulse = sin(_animation_time * 3.0) * 0.5 + 0.5
			mat.emission_enabled = true
			mat.emission = glow_color * pulse * 0.3

func climb_step() -> void:
	# Turn off glow on current step
	if _current_step < _steps.size():
		var mat = _steps[_current_step].material_override as StandardMaterial3D
		if mat:
			mat.emission_enabled = false
	
	_current_step = (_current_step + 1) % _total_steps
	_steps_climbed += 1
	
	_update_highlight()
	_update_counter()
	
	emit_signal("step_taken", _current_step, "up")
	
	# Check for paradox completion (full loop)
	if _current_step == 0 and _steps_climbed > 0:
		emit_signal("paradox_completed")
		print("EscherStaircase: PARADOX — climbed %d steps 'up' and returned to start!" % _steps_climbed)
		_paradox_label.text = "PARADOX COMPLETE\nClimbed %d steps up\nReturned to start" % _steps_climbed

func descend_step() -> void:
	if _current_step < _steps.size():
		var mat = _steps[_current_step].material_override as StandardMaterial3D
		if mat:
			mat.emission_enabled = false
	
	_current_step = (_current_step - 1 + _total_steps) % _total_steps
	_steps_climbed += 1
	
	_update_highlight()
	_update_counter()
	
	emit_signal("step_taken", _current_step, "down")
	
	if _current_step == 0 and _steps_climbed > 0:
		emit_signal("paradox_completed")
		print("EscherStaircase: PARADOX — descended %d steps 'down' and returned to start!" % _steps_climbed)

func _update_counter() -> void:
	var counter = get_node_or_null("StepCounter")
	if counter:
		counter.text = "Steps climbed: %d" % _steps_climbed

func reset() -> void:
	_current_step = 0
	_steps_climbed = 0
	_update_highlight()
	_update_counter()
	_paradox_label.text = "Locally coherent\nGlobally impossible"
