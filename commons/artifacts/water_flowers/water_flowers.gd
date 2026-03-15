# WaterFlowersArtifact.gd
# Grid-system wrapper for the WaterFlowers physics simulation.
# Instances the water flowers scene with floating flowers on Gerstner waves.

extends Node3D
class_name WaterFlowersArtifact

const WATER_FLOWERS := preload("res://algorithms/physicssimulation/waterflowers/waterflowers.tscn")

var _scene: Node3D = null


func _ready() -> void:
	_scene = WATER_FLOWERS.instantiate()
	add_child(_scene)


func apply_grid_config(config_data: Dictionary) -> void:
	if not _scene:
		return

	if config_data.has("flower_count"):
		_scene.flower_count = int(config_data["flower_count"])
	if config_data.has("water_size"):
		_scene.water_size = float(config_data["water_size"])
	if config_data.has("wave_strength"):
		_scene.wave_strength = float(config_data["wave_strength"])
	if config_data.has("animation_speed"):
		_scene.animation_speed = float(config_data["animation_speed"])
	if config_data.has("flower_drift_speed"):
		_scene.flower_drift_speed = float(config_data["flower_drift_speed"])
