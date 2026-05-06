extends Node3D

## Grid Editor Main Scene
## Designed to be loaded into MainSceneLoader's AlgorithmContainer

@onready var grid_manager: GridEditorManager = $GridEditorManager

func _ready() -> void:
	print("GridEditorMain: Scene loaded")
	print("GridEditorMain: Miniature grid at %s" % grid_manager.miniature_origin)
	print("GridEditorMain: Full-scale grid offset: %s" % grid_manager.fullscale_offset)
	print("GridEditorMain: Use VR controllers (from main scene) to grab and move cubes")

func apply_grid_config(config: Dictionary) -> void:
	pass
