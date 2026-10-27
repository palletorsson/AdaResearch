extends "res://commons/artifacts/force_field_zone/force_field_zone.gd"
func _ready() -> void:
	super._ready()
	if is_carry_lesson(): add_to_group("void_controlled_carry")
