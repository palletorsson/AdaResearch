# TileEffectController.gd
extends Node
class_name TileEffectController

# Reference to the grid system
@export var grid_system_path: NodePath
var grid_system: Node

# Effect settings
@export_group("Effect Controls")
@export var reveal_on_start: bool = false
@export var disco_on_start: bool = false
@export var reveal_center: Vector3i = Vector3i(5, 0, 5)

# Input handling
@export_group("Input Controls")
@export var enable_keyboard_controls: bool = false
@export var reveal_key: Key = KEY_R
@export var disco_key: Key = KEY_D
@export var stop_key: Key = KEY_S
@export var show_all_key: Key = KEY_A
@export var hide_all_key: Key = KEY_H

# UI controls
@export_group("UI Debug")
@export var show_debug_info: bool = false
@export var show_trigger_info: bool = true
var debug_label: Label

# Trigger management
var tile_effect_triggers: Array = []
var active_triggers_count: int = 0

func _ready():
	print("TileEffectController: Initialized (simplified mode)")
	
	# Try to get grid system reference if path is provided
	if not grid_system_path.is_empty():
		var node = get_node_or_null(grid_system_path)
		if node:
			grid_system = node
			print("TileEffectController: Connected to grid system")
		else:
			print("TileEffectController: Grid system not found at path: %s" % grid_system_path)

func _process(_delta):
	# Handle keyboard input
	if enable_keyboard_controls:
		_handle_input()

func _handle_input():
	pass

# Public API methods (simplified placeholders)
func start_reveal_effect(center_pos: Vector3i = Vector3i(-1, -1, -1)):
	print("TileEffectController: Start reveal effect at %s" % center_pos)

func start_disco_effect():
	print("TileEffectController: Start disco effect")

func stop_all_effects():
	print("TileEffectController: Stop all effects")

func reveal_all_tiles():
	print("TileEffectController: Reveal all tiles")

func hide_all_tiles():
	print("TileEffectController: Hide all tiles")

func set_grid_system(new_grid_system: Node):
	"""Set the grid system reference manually"""
	grid_system = new_grid_system
	print("TileEffectController: Grid system set manually")

func get_grid_array() -> Array:
	"""Get the current grid state as an array - placeholder"""
	return []

func describe_grid() -> String:
	"""Get grid description - placeholder"""
	return "TileEffectController: Simplified mode - no grid data available"

# Trigger management methods

func get_active_triggers() -> Array:
	"""Get all active tile effect triggers"""
	var active = []
	for trigger in tile_effect_triggers:
		if trigger.is_active:
			active.append(trigger)
	return active

func get_trigger_by_effect_type(effect_type: String) -> Array:
	"""Get all triggers with a specific effect type"""
	var matching = []
	for trigger in tile_effect_triggers:
		if trigger.effect_type == effect_type:
			matching.append(trigger)
	return matching

func activate_all_triggers_of_type(effect_type: String):
	"""Manually activate all triggers of a specific type"""
	var triggers = get_trigger_by_effect_type(effect_type)
	for trigger in triggers:
		trigger.activate()

func reset_all_triggers():
	"""Reset all triggers to be usable again"""
	for trigger in tile_effect_triggers:
		trigger.reset_trigger()
	print("TileEffectController: All triggers reset")

func deactivate_all_triggers():
	"""Deactivate all triggers"""
	for trigger in tile_effect_triggers:
		trigger.deactivate()
	print("TileEffectController: All triggers deactivated")

func get_trigger_info_summary() -> Dictionary:
	"""Get a summary of all triggers"""
	var summary = {
		"total_triggers": tile_effect_triggers.size(),
		"active_triggers": 0,
		"effect_types": {},
		"trigger_methods": {}
	}
	
	for trigger in tile_effect_triggers:
		var info = trigger.get_trigger_info()
		if info.is_active:
			summary.active_triggers += 1
		
		var effect_type = info.effect_type
		if not summary.effect_types.has(effect_type):
			summary.effect_types[effect_type] = 0
		summary.effect_types[effect_type] += 1
		
		var trigger_method = info.trigger_method
		if not summary.trigger_methods.has(trigger_method):
			summary.trigger_methods[trigger_method] = 0
		summary.trigger_methods[trigger_method] += 1
	
	return summary 
