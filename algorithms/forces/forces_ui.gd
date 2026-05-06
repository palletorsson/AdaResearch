extends RefCounted
class_name ForcesUI

## Shared UI styling helpers for Forces examples.
## Keeps Label3D visuals consistent with the new commons/ui palette.

const ADA_PALETTE := preload("res://commons/ui/ada_palette.gd")
const OUTLINE_COLOR := Color(0.04, 0.05, 0.08, 0.95)

static func style_title_label(label: Label3D, position: Vector3, font_size: int = 30) -> void:
	if not is_instance_valid(label):
		return
	_style_base(label, position)
	label.font_size = font_size
	label.outline_size = 5
	label.modulate = ADA_PALETTE.TEXT_ON_DARK
	label.outline_modulate = OUTLINE_COLOR

static func style_value_label(
	label: Label3D,
	position: Vector3,
	color: Color = Color(0.95, 0.75, 0.10, 1.0),
	font_size: int = 24
) -> void:
	if not is_instance_valid(label):
		return
	_style_base(label, position)
	label.font_size = font_size
	label.outline_size = 4
	label.modulate = color
	label.outline_modulate = OUTLINE_COLOR

static func style_instruction_label(label: Label3D, position: Vector3, font_size: int = 18) -> void:
	if not is_instance_valid(label):
		return
	_style_base(label, position)
	label.font_size = font_size
	label.outline_size = 3
	label.modulate = ADA_PALETTE.ACCENT_CYAN
	label.outline_modulate = OUTLINE_COLOR

static func style_tag_label(
	label: Label3D,
	position: Vector3,
	color: Color = Color(0.92, 0.92, 0.94, 1.0),
	font_size: int = 15
) -> void:
	if not is_instance_valid(label):
		return
	_style_base(label, position)
	label.font_size = font_size
	label.outline_size = 2
	label.modulate = color
	label.outline_modulate = OUTLINE_COLOR

static func set_label_text(label: Label3D, value: String) -> bool:
	if not is_instance_valid(label):
		return false
	if label.text == value:
		return false
	label.text = value
	return true

static func _style_base(label: Label3D, position: Vector3) -> void:
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = position
