# RockSpawner.gd - Spawns multiple simple dynamic rocks
extends Node3D

@export var rock_count: int = 30
@export var spawn_area: Vector3 = Vector3(3.0, 2.0, 3.0)
@export var spawn_height: float = 3.5
@export var generation_seed: int = 0

var rock_scene: PackedScene

func _ready():
	# Load the rock scene
	rock_scene = preload("res://commons/primitives/rockfactory/SimpleDynamicRock.tscn")

	# Set random seed if specified
	if generation_seed != 0:
		seed(generation_seed)
	else:
		randomize()

	# Spawn rocks
	spawn_rocks()

func spawn_rocks():
	for i in range(rock_count):
		var rock = rock_scene.instantiate()

		# Random position within spawn area
		var spawn_pos = Vector3(
			randf_range(-spawn_area.x / 2, spawn_area.x / 2),
			spawn_height + randf_range(0, spawn_area.y),
			randf_range(-spawn_area.z / 2, spawn_area.z / 2)
		)

		rock.position = spawn_pos

		# Give each rock a unique seed for variation
		rock.rock_seed = randi()

		add_child(rock)

	print("RockSpawner: Spawned %d rocks" % rock_count)

func apply_grid_config(config: Dictionary):
	"""Apply configuration from grid system"""
	if config.has("rock_count"):
		rock_count = int(config["rock_count"])
	if config.has("spawn_height"):
		spawn_height = float(config["spawn_height"])
	if config.has("spawn_area_x"):
		spawn_area.x = float(config["spawn_area_x"])
	if config.has("spawn_area_y"):
		spawn_area.y = float(config["spawn_area_y"])
	if config.has("spawn_area_z"):
		spawn_area.z = float(config["spawn_area_z"])
	if config.has("generation_seed"):
		generation_seed = int(config["generation_seed"])
