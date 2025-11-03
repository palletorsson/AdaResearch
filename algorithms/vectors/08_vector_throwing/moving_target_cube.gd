# moving_target_cube.gd
# Extends hit_target_cube to add movement patterns
extends "res://algorithms/vectors/08_vector_throwing/hit_target_cube.gd"

@export_group("Movement")
@export var enable_movement: bool = true
@export var movement_pattern: String = "linear"  # linear, circular, figure8, random
@export var movement_speed: float = 1.0
@export var movement_range: float = 2.0
@export var pause_on_hit: bool = true
@export var pause_duration: float = 1.0

# Movement state
var movement_timer: float = 0.0
var start_position: Vector3 = Vector3.ZERO
var is_paused: bool = false
var pause_timer: float = 0.0

func _ready() -> void:
	super._ready()
	start_position = global_position

func _process(delta: float) -> void:
	if enable_movement:
		if is_paused:
			pause_timer += delta
			if pause_timer >= pause_duration:
				is_paused = false
				pause_timer = 0.0
		else:
			_update_movement(delta)

func _update_movement(delta: float) -> void:
	"""Update target position based on movement pattern"""
	movement_timer += delta * movement_speed

	match movement_pattern:
		"linear":
			_move_linear()
		"circular":
			_move_circular()
		"figure8":
			_move_figure8()
		"random":
			_move_random()
		"vertical":
			_move_vertical()
		"horizontal":
			_move_horizontal()

func _move_linear() -> void:
	"""Move back and forth along X axis"""
	var offset_x = sin(movement_timer) * movement_range
	global_position = start_position + Vector3(offset_x, 0, 0)

func _move_circular() -> void:
	"""Move in a circle on XZ plane"""
	var offset_x = cos(movement_timer) * movement_range
	var offset_z = sin(movement_timer) * movement_range
	global_position = start_position + Vector3(offset_x, 0, offset_z)

func _move_figure8() -> void:
	"""Move in a figure-8 pattern"""
	var offset_x = sin(movement_timer) * movement_range
	var offset_y = sin(movement_timer * 2.0) * movement_range * 0.5
	global_position = start_position + Vector3(offset_x, offset_y, 0)

func _move_random() -> void:
	"""Smooth random movement using Perlin-like noise"""
	var offset_x = (sin(movement_timer * 1.1) + cos(movement_timer * 0.7)) * movement_range * 0.5
	var offset_y = (sin(movement_timer * 0.9) + cos(movement_timer * 1.3)) * movement_range * 0.3
	var offset_z = (sin(movement_timer * 0.8) + cos(movement_timer * 1.1)) * movement_range * 0.5
	global_position = start_position + Vector3(offset_x, offset_y, offset_z)

func _move_vertical() -> void:
	"""Move up and down"""
	var offset_y = sin(movement_timer) * movement_range
	global_position = start_position + Vector3(0, offset_y, 0)

func _move_horizontal() -> void:
	"""Move side to side"""
	var offset_x = sin(movement_timer) * movement_range
	global_position = start_position + Vector3(offset_x, 0, 0)

func _trigger_hit(impact_velocity: Vector3) -> void:
	"""Override to pause movement on hit"""
	super._trigger_hit(impact_velocity)

	if pause_on_hit:
		is_paused = true
		pause_timer = 0.0
		print("[MovingTarget] Pausing movement for ", pause_duration, "s")

func reset() -> void:
	"""Override to reset movement state"""
	super.reset()
	movement_timer = 0.0
	is_paused = false
	pause_timer = 0.0
	global_position = start_position
