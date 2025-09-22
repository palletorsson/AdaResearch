# TerrainCollisionFix.gd
# Helper script to debug and fix terrain collision issues
# Attach this to your terrain node or call its functions

extends Node

@onready var terrain: NoiseLayers

func _ready():
	"""Find the terrain node automatically"""
	terrain = get_parent() as NoiseLayers
	if not terrain:
		# Try to find it in the scene
		terrain = get_tree().get_first_node_in_group("terrain")
	
	if not terrain:
		print("Error: No NoiseLayers terrain found!")

func _input(event):
	"""Handle input for debugging"""
	if event.is_action_pressed("ui_accept"):  # Space key
		debug_terrain_collision()
	
	elif event.is_action_pressed("ui_cancel"):  # Escape key
		fix_collision_issues()
	
	elif event.is_action_pressed("ui_select"):  # Enter key
		regenerate_terrain()

func debug_terrain_collision():
	"""Debug terrain collision system"""
	if not terrain:
		print("No terrain found!")
		return
	
	print("\n=== TERRAIN COLLISION DEBUG ===")
	
	# Show terrain info
	terrain.debug_terrain_info()
	
	# Show collision info
	terrain.debug_collision_info()
	
	# Test walkable surface detection
	test_walkable_surfaces()
	
	print("=== END DEBUG ===\n")

func test_walkable_surfaces():
	"""Test walkable surface detection at various positions"""
	if not terrain:
		return
	
	print("Testing walkable surface detection...")
	
	var test_positions = [
		Vector3(0, 5, 0),      # Center, above terrain
		Vector3(10, 5, 10),    # Corner, above terrain
		Vector3(-10, 5, -10),  # Opposite corner
		Vector3(0, -5, 0),     # Below terrain
	]
	
	for pos in test_positions:
		var is_walkable = terrain.is_position_walkable(pos)
		var height = terrain.get_terrain_height_at_position(pos.x, pos.z)
		var slope = terrain.get_terrain_slope_at_position(pos.x, pos.z)
		
		print("Position %v: Walkable=%s, Height=%.2f, Slope=%.1f°" % [
			pos, is_walkable, height, slope
		])

func fix_collision_issues():
	"""Fix collision issues by using basic collision"""
	if not terrain:
		print("No terrain found!")
		return
	
	print("Fixing collision issues...")
	terrain.fix_collision_issues()
	print("Collision fixed! Try moving around now.")

func regenerate_terrain():
	"""Regenerate the entire terrain"""
	if not terrain:
		print("No terrain found!")
		return
	
	print("Regenerating terrain...")
	terrain.regenerate_terrain()
	print("Terrain regenerated!")

func enable_basic_collision():
	"""Permanently enable basic collision mode"""
	if not terrain:
		print("No terrain found!")
		return
	
	terrain.enable_collision_optimization = false
	terrain.regenerate_terrain()
	print("Switched to basic collision mode")

func enable_optimized_collision():
	"""Enable optimized collision mode"""
	if not terrain:
		print("No terrain found!")
		return
	
	terrain.enable_collision_optimization = true
	terrain.regenerate_terrain()
	print("Switched to optimized collision mode")

# Quick fix functions you can call from the editor or code
func quick_fix():
	"""Quick fix for getting stuck in terrain"""
	if terrain:
		terrain.enable_collision_optimization = false
		terrain.regenerate_terrain()
		print("Quick fix applied - using basic collision")

func increase_walkable_slope():
	"""Increase walkable slope to make more surfaces walkable"""
	if not terrain:
		return
	
	terrain.max_walkable_slope = 45.0  # Increase from 30 to 45 degrees
	terrain.regenerate_terrain()
	print("Increased walkable slope to 45 degrees")

func disable_erosion():
	"""Disable erosion simulation which might cause collision issues"""
	if not terrain:
		return
	
	terrain.enable_erosion_simulation = false
	terrain.regenerate_terrain()
	print("Disabled erosion simulation")
