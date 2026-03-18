extends "res://algorithms/wavefunctions/static_cables/SplineCables.gd"

@export var environment_enabled: bool = false

func _create_environment() -> void:
	if environment_enabled:
		super._create_environment()

func apply_grid_config(config: Dictionary) -> void:
	pass
