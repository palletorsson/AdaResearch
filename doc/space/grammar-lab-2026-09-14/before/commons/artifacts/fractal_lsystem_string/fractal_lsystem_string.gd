# fractal_lsystem_string.gd
# Visualizes L-system string expansion as stacked 3D text
# Teaching tool: shows how rewriting rules transform the axiom string
# generation by generation, making the grammar's growth visible.
#
# Algorithm: Starting from an axiom string, each generation applies a
# production rule that replaces every matching symbol with its expansion.
# The string grows exponentially, revealing the self-similar structure
# encoded in the grammar before any geometric interpretation.
#
# QFEP: Grammar as generative engine — the string IS the structure
#
# @identity
# essence: string(n+1) = replace_all(string(n), F, rule) — exponential rewriting made visible
# desire: To show the string before the tree — stacked generations revealing how F→F[+F]F[-F]F explodes
# critical_parameter: rule_to — the production rule determines the entire growth pattern of the string
# triggers: Each generation multiplies string length exponentially; truncation at 50000 chars shows the limit of display
# emerges: The realization that the tree was always in the string — geometry is just an interpretation of grammar
# needs: VR rule editor [missing], generation stepper [missing], Label3D [has]
# relationships: Paired with lsystem_tree (string vs geometry). Opens LSystems_Grammar_Lab.
# truth: The string is the structure — the tree is just one way to read it.

extends Node3D

class_name FractalLSystemString

## Overall display scale for spacing and base sizing
@export var display_size: float = 0.6

## L-system axiom (starting string)
@export var axiom: String = "F"

## Production rule: what F expands to each generation
@export var rule_from: String = "F"
@export var rule_to: String = "F[+F]F[-F]F"

## Number of generations to display (0 = axiom only)
@export var num_generations: int = 5

## Maximum characters to display per line before truncating
@export var max_display_chars: int = 60

## Vertical spacing between generation lines
@export var line_spacing: float = 0.12

## Font size for the generation strings
@export var string_font_size: int = 20

## Font size for the title label
@export var title_font_size: int = 28

# Internal references
var _generation_labels: Array[Label3D] = []
var _gen_number_labels: Array[Label3D] = []
var _title_label: Label3D
var _rule_label: Label3D
var _base_mesh: MeshInstance3D

func _ready():
	_create_base()
	_create_title()
	_create_rule_label()
	_generate_and_display()


func _create_base():
	_base_mesh = MeshInstance3D.new()
	_base_mesh.name = "Base"

	var box = BoxMesh.new()
	box.size = Vector3(display_size * 1.6, 0.03, display_size * 0.4)
	_base_mesh.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.13)
	mat.metallic = 0.6
	mat.roughness = 0.4
	_base_mesh.material_override = mat

	_base_mesh.position = Vector3(0, -0.015, 0)
	add_child(_base_mesh)


func _create_title():
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "L-System String Expansion"
	_title_label.pixel_size = 0.001
	_title_label.font_size = title_font_size
	_title_label.modulate = Color(0.9, 0.9, 1.0)
	_title_label.outline_size = 4
	_title_label.outline_modulate = Color(0, 0, 0, 0.6)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_title_label)


func _create_rule_label():
	_rule_label = Label3D.new()
	_rule_label.name = "RuleLabel"
	_rule_label.pixel_size = 0.001
	_rule_label.font_size = 18
	_rule_label.modulate = Color(0.7, 0.7, 0.8)
	_rule_label.outline_size = 3
	_rule_label.outline_modulate = Color(0, 0, 0, 0.5)
	_rule_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rule_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_rule_label)


func _generate_and_display():
	# Clear any existing generation labels
	for label in _generation_labels:
		if is_instance_valid(label):
			label.queue_free()
	_generation_labels.clear()

	for label in _gen_number_labels:
		if is_instance_valid(label):
			label.queue_free()
	_gen_number_labels.clear()

	# Build all generation strings
	var generations: Array[String] = []
	var current_string = axiom
	generations.append(current_string)

	for gen in range(num_generations):
		var next_string = ""
		for c in current_string:
			if c == rule_from:
				next_string += rule_to
			else:
				next_string += c
		current_string = next_string
		generations.append(current_string)

		# Safety: stop if the string gets excessively long internally
		if current_string.length() > 50000:
			break

	# Color gradient: white (gen 0) to bright green (final gen)
	var color_start = Color(1.0, 1.0, 1.0)
	var color_end = Color(0.3, 1.0, 0.3)

	var total_gens = generations.size()
	var base_y = 0.04  # just above the pedestal

	for i in range(total_gens):
		var y_pos = base_y + i * line_spacing
		var t = float(i) / maxf(float(total_gens - 1), 1.0)
		var gen_color = color_start.lerp(color_end, t)

		# Create generation number label (left side)
		var num_label = Label3D.new()
		num_label.name = "GenNum%d" % i
		num_label.text = "G%d:" % i
		num_label.pixel_size = 0.001
		num_label.font_size = 16
		num_label.modulate = Color(0.5, 0.5, 0.6)
		num_label.outline_size = 3
		num_label.outline_modulate = Color(0, 0, 0, 0.5)
		num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		num_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		num_label.position = Vector3(-display_size * 0.65, y_pos, 0)
		add_child(num_label)
		_gen_number_labels.append(num_label)

		# Create the string label
		var str_label = Label3D.new()
		str_label.name = "GenString%d" % i
		str_label.pixel_size = 0.001
		str_label.font_size = string_font_size
		str_label.modulate = gen_color
		str_label.outline_size = 4
		str_label.outline_modulate = Color(0, 0, 0, 0.6)
		str_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		str_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		str_label.position = Vector3(-display_size * 0.55, y_pos, 0)

		# Truncate long strings
		var display_text = generations[i]
		if display_text.length() > max_display_chars:
			display_text = display_text.substr(0, max_display_chars - 3) + "..."

		# Add character count for truncated strings
		if generations[i].length() > max_display_chars:
			str_label.text = display_text + "  [%d chars]" % generations[i].length()
		else:
			str_label.text = display_text

		add_child(str_label)
		_generation_labels.append(str_label)

	# Position title above all generations
	var top_y = base_y + (total_gens) * line_spacing + 0.06
	_title_label.position = Vector3(0, top_y, 0)

	# Position rule label just below the title
	_rule_label.text = "Rule: %s -> %s" % [rule_from, rule_to]
	_rule_label.position = Vector3(0, top_y - 0.05, 0)


## Grid system integration point for positioning and configuration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("axiom"):
		axiom = str(config_data["axiom"])
	if config_data.has("rule_from"):
		rule_from = str(config_data["rule_from"])
	if config_data.has("rule_to"):
		rule_to = str(config_data["rule_to"])
	if config_data.has("num_generations"):
		num_generations = clampi(int(config_data["num_generations"]), 1, 8)
	if config_data.has("max_display_chars"):
		max_display_chars = clampi(int(config_data["max_display_chars"]), 20, 200)

	_generate_and_display()
