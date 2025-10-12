# ===========================================================================
# NOC Example 8.8: L-System (String Only)
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.8: L-System String Only
## L-System string generation (no visual drawing)
## Chapter 08: Fractals


@export var generations: int = 5

var _sim_root: Node3D
var _status_label: Label3D
var _string_label: Label3D

# L-System rules
var axiom: String = "F"
var rules: Dictionary = {
	"F": "F+F-F-F+F"
}

var current_string: String = ""

func _ready() -> void:
	_setup_environment()
	_generate_lsystem()
	set_process(false)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 28
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.75, 0)
	_sim_root.add_child(_status_label)

	_string_label = Label3D.new()
	_string_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_string_label.font_size = 14
	_string_label.modulate = Color(0.9, 0.7, 1.0)
	_string_label.position = Vector3(0, 0.0, 0)
	_string_label.width = 800.0
	_string_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sim_root.add_child(_string_label)

func _generate_lsystem() -> void:
	current_string = axiom

	for i in generations:
		current_string = _apply_rules(current_string)

	_status_label.text = "L-System String | Gen: %d | Length: %d" % [generations, current_string.length()]

	# Show first part of string if too long
	var display_string := current_string
	if display_string.length() > 200:
		display_string = display_string.substr(0, 200) + "..."

	_string_label.text = display_string

	print("L-System Generation %d:" % generations)
	print("String length: %d" % current_string.length())
	print("First 100 chars: %s" % current_string.substr(0, min(100, current_string.length())))

func _apply_rules(input_string: String) -> String:
	var result := ""

	for i in input_string.length():
		var char := input_string[i]
		if char in rules:
			result += rules[char]
		else:
			result += char

	return result
