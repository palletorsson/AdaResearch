# godel_statement_plaque.gd
# A self-referential artifact that demonstrates Gödel's incompleteness
# The plaque displays a statement that refers to itself
# Grabbing/interacting cycles through increasingly self-referential statements
#
# "This statement is unprovable within this system"
# — The sentence that broke mathematics (1931)

extends Node3D

class_name GodelStatementPlaque

# @identity
# essence: G: ¬∃p: Proves(p, G) — a sentence that asserts its own unprovability
# desire: cycle through nine statements of increasing self-reference, feel the paradox tighten
# critical_parameter: current_index — at index 4+ the plaque pulses gold, the paradox is live
# triggers: click/grab advances to next statement; index >= 4 fires paradox_triggered signal; glow intensifies on hover
# emerges: the vertigo of self-reference — each statement is more dangerous than the last
# needs: VR area interaction [has], mouse click [has], XR grab [has conceptual]
# relationships: unlocks escher_staircase (visual Godel); contrasts russell_set_box (set-theoretic vs arithmetic self-reference); depends on excluded_middle_demo
# truth: every sufficiently powerful formal system contains true statements it cannot prove — completeness and consistency are mutually exclusive

signal statement_changed(statement: String, index: int)
signal paradox_triggered()

## Current statement index
@export var current_index: int = 0

## Plaque dimensions
@export var width: float = 0.6
@export var height: float = 0.4
@export var depth: float = 0.05

## Text properties
@export var text_color: Color = Color(0.9, 0.85, 0.7)
@export var plaque_color: Color = Color(0.15, 0.12, 0.1)
@export var glow_color: Color = Color(1.0, 0.9, 0.5)

## Enable grabbable
@export var grabbable: bool = true

## The statements — each more self-referential than the last
var statements: Array[String] = [
	"This statement exists.",
	"This statement refers to itself.",
	"This statement cannot be proven true.",
	"This statement is unprovable within this system.",
	"If this statement is provable, then it is false.",
	"I am lying.",
	"The set of all statements not containing themselves...",
	"∃x: ¬Provable(x) ∧ True(x)",
	"G: ¬∃p: Proves(p, G)",
]

var statement_notes: Array[String] = [
	"Existence — the starting point",
	"Self-reference — the dangerous turn",
	"The claim Gödel encoded",
	"The incompleteness theorem",
	"The paradox made formal",
	"The Liar Paradox — ancient Greece",
	"Russell's Paradox — 1901",
	"Formal logic notation",
	"Gödel sentence G — 1931",
]

# Internal
var _plaque_mesh: MeshInstance3D
var _text_label: Label3D
var _note_label: Label3D
var _glow_effect: OmniLight3D
var _interactable: Area3D
var _animation_time: float = 0.0
var _is_glowing: bool = false

func _ready() -> void:
	_create_plaque()
	_create_text()
	_create_glow()
	_create_interactable()
	_update_display()
	print("GodelStatementPlaque: Ready — 'Every formal system has an outside'")

func _create_plaque() -> void:
	_plaque_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(width, height, depth)
	_plaque_mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = plaque_color
	mat.metallic = 0.3
	mat.roughness = 0.7
	_plaque_mesh.material_override = mat
	
	add_child(_plaque_mesh)
	
	# Frame
	var frame = MeshInstance3D.new()
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(width + 0.04, height + 0.04, depth * 0.5)
	frame.mesh = frame_mesh
	frame.position.z = -depth * 0.3
	
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.4, 0.35, 0.2)
	frame_mat.metallic = 0.6
	frame_mat.roughness = 0.4
	frame.material_override = frame_mat
	
	add_child(frame)

func _create_text() -> void:
	# Main statement
	_text_label = Label3D.new()
	_text_label.text = ""
	_text_label.font_size = 48
	_text_label.position = Vector3(0, 0.05, depth / 2 + 0.01)
	_text_label.pixel_size = 0.001
	_text_label.width = width * 900
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.modulate = text_color
	_text_label.outline_size = 8
	_text_label.outline_modulate = Color.BLACK
	add_child(_text_label)
	
	# Note/explanation
	_note_label = Label3D.new()
	_note_label.text = ""
	_note_label.font_size = 24
	_note_label.position = Vector3(0, -height / 2 + 0.05, depth / 2 + 0.01)
	_note_label.pixel_size = 0.001
	_note_label.modulate = Color(0.6, 0.6, 0.5, 0.8)
	_note_label.outline_size = 4
	_note_label.outline_modulate = Color.BLACK
	add_child(_note_label)
	
	# Index indicator
	var index_label = Label3D.new()
	index_label.name = "IndexLabel"
	index_label.text = ""
	index_label.font_size = 18
	index_label.position = Vector3(width / 2 - 0.05, -height / 2 + 0.03, depth / 2 + 0.01)
	index_label.pixel_size = 0.001
	index_label.modulate = Color(0.5, 0.5, 0.4, 0.6)
	add_child(index_label)

func _create_glow() -> void:
	_glow_effect = OmniLight3D.new()
	_glow_effect.light_color = glow_color
	_glow_effect.light_energy = 0.0
	_glow_effect.omni_range = 0.5
	_glow_effect.position.z = depth
	add_child(_glow_effect)

func _create_interactable() -> void:
	_interactable = Area3D.new()
	_interactable.name = "InteractableArea"
	
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(width, height, depth + 0.1)
	collision.shape = shape
	_interactable.add_child(collision)
	
	_interactable.input_event.connect(_on_input_event)
	_interactable.mouse_entered.connect(_on_hover_start)
	_interactable.mouse_exited.connect(_on_hover_end)
	
	add_child(_interactable)
	
	# Make it pickable for XR
	_interactable.input_ray_pickable = true

func _on_input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance_statement()

func _on_hover_start() -> void:
	_is_glowing = true

func _on_hover_end() -> void:
	_is_glowing = false

func _process(delta: float) -> void:
	_animation_time += delta
	
	# Glow effect on hover
	var target_energy = 0.5 if _is_glowing else 0.0
	_glow_effect.light_energy = lerp(_glow_effect.light_energy, target_energy, delta * 5.0)
	
	# Subtle pulse on paradox statements (index >= 4)
	if current_index >= 4:
		var pulse = sin(_animation_time * 2.0) * 0.5 + 0.5
		_text_label.modulate = text_color.lerp(glow_color, pulse * 0.3)
	else:
		_text_label.modulate = text_color

func _update_display() -> void:
	if current_index < statements.size():
		_text_label.text = statements[current_index]
		_note_label.text = statement_notes[current_index]
		
		var index_label = get_node_or_null("IndexLabel")
		if index_label:
			index_label.text = "%d/%d" % [current_index + 1, statements.size()]
		
		emit_signal("statement_changed", statements[current_index], current_index)
		
		# Trigger paradox event on the self-referential statements
		if current_index >= 4:
			emit_signal("paradox_triggered")

func advance_statement() -> void:
	current_index = (current_index + 1) % statements.size()
	_update_display()
	
	# Visual feedback
	_glow_effect.light_energy = 1.0
	
	print("GodelStatementPlaque: '%s'" % statements[current_index])

func previous_statement() -> void:
	current_index = (current_index - 1 + statements.size()) % statements.size()
	_update_display()

func set_statement(index: int) -> void:
	current_index = clamp(index, 0, statements.size() - 1)
	_update_display()

func get_current_statement() -> String:
	return statements[current_index] if current_index < statements.size() else ""

# For XR grab interaction
func _on_grabbed() -> void:
	advance_statement()
