extends Node3D

## Grid Editor Main Scene
## Designed to be loaded into MainSceneLoader's AlgorithmContainer

@onready var grid_manager: GridEditorManager = $GridEditorManager

func _ready() -> void:
	pass

func apply_grid_config(config: Dictionary) -> void:
	pass
