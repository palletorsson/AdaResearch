# TileEffectExample.gd
extends Node
class_name TileEffectExample

# Example script showing how to use the tile effect system

var grid_system: GridSystem
var tile_effect_controller: TileEffectController

func _ready():
	# Find the grid system and tile effect controller
	grid_system = find_child("multiLayerGrid") as GridSystem
	tile_effect_controller = find_child("TileEffectController") as TileEffectController
	
	if not grid_system:
		print("GridSystem not found!")
		return
	
	if not tile_effect_controller:
		print("TileEffectController not found!")
		return
	
	print("=== Tile Effect System Example ===")
	print("Press number keys to try different effects:")
	print("1 - Center reveal")
	print("2 - Corner reveal")
	print("3 - Disco effect")
	print("4 - Progressive reveal pattern")
	print("5 - Show all tiles")
	print("6 - Hide all tiles")
	print("0 - Stop all effects")

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		KEY_1:
			center_reveal_example()
		KEY_2:
			corner_reveal_example()
		KEY_3:
			disco_effect_example()
		KEY_4:
			progressive_reveal_example()
		KEY_5:
			show_all_example()
		KEY_6:
			hide_all_example()
		KEY_0:
			stop_effects_example()

func center_reveal_example():
	"""Example: Reveal tiles from the center of the grid"""
	print("Example 1: Center reveal effect")
	
	if grid_system:
		var center = Vector3i(
			grid_system.grid_x / 2,
			0,
			grid_system.grid_z / 2
		)
		grid_system.start_tile_reveal(center)

func corner_reveal_example():
	"""Example: Reveal tiles from a corner"""
	print("Example 2: Corner reveal effect")
	
	if tile_effect_controller:
		tile_effect_controller.start_reveal_effect(Vector3i(0, 0, 0))

func disco_effect_example():
	"""Example: Start disco effect on all tiles"""
	print("Example 3: Disco effect")
	
	if grid_system:
		grid_system.start_disco_tiles()

func progressive_reveal_example():
	"""Example: Progressive reveal pattern"""
	print("Example 4: Progressive reveal pattern")
	
	# First hide all tiles
	if grid_system:
		grid_system.hide_all_tiles()
	
	# Wait a moment then start progressive reveals
	await get_tree().create_timer(0.5).timeout
	
	# Reveal in a pattern
	var positions = [
		Vector3i(2, 0, 2),
		Vector3i(7, 0, 2),
		Vector3i(2, 0, 7),
		Vector3i(7, 0, 7),
		Vector3i(5, 0, 5)  # Center last
	]
	
	for i in positions.size():
		print("Revealing from position: ", positions[i])
		if grid_system:
			grid_system.start_tile_reveal(positions[i])
		await get_tree().create_timer(1.0).timeout

func show_all_example():
	"""Example: Show all tiles instantly"""
	print("Example 5: Show all tiles")
	
	if grid_system:
		grid_system.reveal_all_tiles()

func hide_all_example():
	"""Example: Hide all tiles"""
	print("Example 6: Hide all tiles")
	
	if grid_system:
		grid_system.hide_all_tiles()

func stop_effects_example():
	"""Example: Stop all effects"""
	print("Example 0: Stop all effects")
	
	if grid_system:
		grid_system.stop_tile_effects()

# Advanced examples

func wave_pattern_example():
	"""Create a wave pattern across the grid"""
	if not grid_system:
		return
	
	print("Advanced: Wave pattern")
	grid_system.hide_all_tiles()
	await get_tree().create_timer(0.5).timeout
	
	# Create wave from left to right
	for x in grid_system.grid_x:
		grid_system.start_tile_reveal(Vector3i(x, 0, grid_system.grid_z / 2))
		await get_tree().create_timer(0.2).timeout

func spiral_pattern_example():
	"""Create a spiral reveal pattern"""
	if not grid_system:
		return
	
	print("Advanced: Spiral pattern")
	grid_system.hide_all_tiles()
	await get_tree().create_timer(0.5).timeout
	
	var center_x = grid_system.grid_x / 2
	var center_z = grid_system.grid_z / 2
	
	# Simple spiral approximation
	var radius = 1
	var max_radius = max(center_x, center_z)
	
	while radius <= max_radius:
		# Reveal in a circular pattern
		for angle in range(0, 360, 45):
			var rad = deg_to_rad(angle)
			var x = center_x + int(cos(rad) * radius)
			var z = center_z + int(sin(rad) * radius)
			
			if x >= 0 and x < grid_system.grid_x and z >= 0 and z < grid_system.grid_z:
				grid_system.start_tile_reveal(Vector3i(x, 0, z))
		
		radius += 1
		await get_tree().create_timer(0.3).timeout

func get_grid_info() -> Dictionary:
	"""Get information about the current grid state"""
	if not grid_system:
		return {}
	
	return {
		"description": grid_system.get_tile_grid_description(),
		"array_data": grid_system.get_tile_grid_as_array(),
		"dimensions": Vector3i(grid_system.grid_x, grid_system.grid_y, grid_system.grid_z),
		"tile_effects_enabled": grid_system.enable_tile_effects
	}

func print_grid_info():
	"""Print current grid information"""
	var info = get_grid_info()
	print("=== Grid Information ===")
	for key in info.keys():
		if key == "array_data":
			print("%s: [Large array data - %d items]" % [key, info[key].size()])
		else:
			print("%s: %s" % [key, str(info[key])])

# Usage examples for external scripts:

# Example 1: Basic usage
# var tile_example = TileEffectExample.new()
# tile_example.center_reveal_example()

# Example 2: Get grid state
# var grid_info = tile_example.get_grid_info()
# print("Grid dimensions: ", grid_info.dimensions)

# Example 3: Custom reveal pattern
# tile_example.progressive_reveal_example()

# Example 4: Advanced patterns
# tile_example.wave_pattern_example()
# tile_example.spiral_pattern_example() 
