extends Node
class_name LabelHelper

# Creates a 3D label with text and styling
static func create_number_label(position: Vector3, text: String, font_file: FontFile, font_size: int = 12) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.font_size = font_size
	label.outline_size = 3
	label.position = position
	label.font = font_file
	label.modulate = Color(0, 0, 0)  # Black text
	return label
