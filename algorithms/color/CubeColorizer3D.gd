# CubeColorizer3D.gd
# Simple 3D cube colorizer that finds MeshInstance3D nodes with "cube" in their name
# and applies the rose vase color pattern to an 11x11 grid

extends Node

# 11x11 Rose vase color pattern from the image
var rose_vase_pattern = [
	# Row 0 (top)
	["rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose"],
	# Row 1  
	["rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose"],
	# Row 2
	["rose", "rose", "yellow", "yellow", "white", "white", "blue", "rose", "rose", "rose", "rose"],
	# Row 3
	["rose", "rose", "yellow", "yellow", "white", "white", "blue", "rose", "rose", "rose", "rose"],
	# Row 4
	["rose", "rose", "red", "yellow", "white", "white", "rose", "yellow_green", "rose", "rose", "rose"],
	# Row 5
	["rose", "rose", "red", "white", "white", "white", "rose", "yellow_green", "rose", "rose", "rose"],
	# Row 6
	["rose", "rose", "red", "white", "white", "white", "rose", "yellow_green", "rose", "rose", "rose"],
	# Row 7
	["rose", "rose", "red", "white", "white", "green", "green", "yellow_green", "rose", "rose", "rose"],
	# Row 8
	["rose", "rose", "red", "green", "green", "green", "green", "green", "rose", "rose", "rose"],
	# Row 9
	["rose", "rose", "rose", "green", "green", "green", "green", "green", "green", "rose", "rose"],
	# Row 10 (bottom)
	["rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose", "rose"]
]

# Color palette matching the image
var colors = {
	"rose": Color(0.85, 0.55, 0.55),      # Rose background
	"white": Color(0.95, 0.95, 0.95),     # White panel
	"blue": Color(0.2, 0.3, 0.6),         # Blue accent
	"yellow": Color(0.9, 0.8, 0.2),       # Yellow
	"red": Color(0.7, 0.2, 0.2),          # Deep red
	"green": Color(0.3, 0.5, 0.3),        # Green
	"yellow_green": Color(0.6, 0.7, 0.3)  # Yellow-green
}

func _ready():
	print("CubeColorizer3D: Ready to colorize cubes!")
	# Small delay to ensure scene is fully loaded
	await get_tree().create_timer(0.5).timeout
	colorize_all_cubes()

func colorize_all_cubes():
	print("CubeColorizer3D: Starting cube colorization...")
	
	# Find all MeshInstance3D nodes with "cube" in their name
	var cube_meshes = find_all_cube_meshes()
	print("CubeColorizer3D: Found %d cube meshes" % cube_meshes.size())
	
	if cube_meshes.is_empty():
		print("CubeColorizer3D: No cube meshes found!")
		return
	
	# Sort cubes by position for consistent mapping
	var sorted_cubes = sort_cubes_by_3d_position(cube_meshes)
	
	# Apply the rose vase color pattern
	apply_pattern_to_cubes(sorted_cubes)
	
	print("CubeColorizer3D: Cube colorization complete! 🎨")

func find_all_cube_meshes() -> Array[MeshInstance3D]:
	var cube_meshes: Array[MeshInstance3D] = []
	var scene_root = get_tree().current_scene
	
	# Recursively find all MeshInstance3D nodes with "cube" in the name
	find_cube_meshes_recursive(scene_root, cube_meshes)
	
	return cube_meshes

func find_cube_meshes_recursive(node: Node, cube_list: Array[MeshInstance3D]):
	# Check if this node is a MeshInstance3D with "cube" in its name
	if node is MeshInstance3D and "cube" in node.name.to_lower():
		cube_list.append(node as MeshInstance3D)
		print("CubeColorizer3D: Found cube mesh: %s at position %s" % [node.name, node.global_position])
	
	# Check all children
	for child in node.get_children():
		find_cube_meshes_recursive(child, cube_list)

func sort_cubes_by_3d_position(cubes: Array[MeshInstance3D]) -> Array[MeshInstance3D]:
	print("CubeColorizer3D: Sorting %d cubes by 3D position..." % cubes.size())
	
	# Sort by Z position first (depth/rows), then by X position (width/columns)
	cubes.sort_custom(func(a: MeshInstance3D, b: MeshInstance3D):
		var pos_a = a.global_position
		var pos_b = b.global_position
		
		# Round positions to avoid floating point issues
		var z_a = round(pos_a.z)
		var z_b = round(pos_b.z)
		var x_a = round(pos_a.x)
		var x_b = round(pos_b.x)
		
		# First sort by Z (rows)
		if z_a != z_b:
			return z_a < z_b
		
		# Then sort by X (columns)
		return x_a < x_b
	)
	
	# Debug: print sorted positions
	print("CubeColorizer3D: Sorted cube positions:")
	for i in range(min(10, cubes.size())):  # Print first 10 for debug
		var pos = cubes[i].global_position
		print("  Cube %d: %s at (%.1f, %.1f, %.1f)" % [i, cubes[i].name, pos.x, pos.y, pos.z])
	
	return cubes

func apply_pattern_to_cubes(cubes: Array[MeshInstance3D]):
	print("CubeColorizer3D: Applying rose vase pattern to %d cubes..." % cubes.size())
	
	var cube_index = 0
	var colored_count = 0
	
	# Apply colors row by row (11x11 grid)
	for row in range(rose_vase_pattern.size()):
		var row_data = rose_vase_pattern[row]
		
		for col in range(row_data.size()):
			if cube_index >= cubes.size():
				print("CubeColorizer3D: Warning - ran out of cubes at position (%d, %d)" % [col, row])
				break
			
			var color_name = row_data[col]
			var cube_mesh = cubes[cube_index]
			
			if colors.has(color_name):
				var target_color = colors[color_name]
				apply_color_to_mesh(cube_mesh, target_color, color_name)
				colored_count += 1
			else:
				print("CubeColorizer3D: Unknown color: %s" % color_name)
			
			cube_index += 1
	
	print("CubeColorizer3D: Successfully colored %d cubes!" % colored_count)

func apply_color_to_mesh(mesh_instance: MeshInstance3D, color: Color, color_name: String):
	# Create a new StandardMaterial3D and apply the color
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	
	# Add slight emission for better visibility
	material.emission_enabled = true
	material.emission = color * 0.2
	
	# Apply the material
	mesh_instance.material_override = material
	
	print("CubeColorizer3D: Applied %s color to %s" % [color_name, mesh_instance.name])

# Utility functions for manual control

func reset_all_cube_colors():
	"""Reset all cube colors to default"""
	print("CubeColorizer3D: Resetting all cube colors...")
	var cubes = find_all_cube_meshes()
	
	for cube in cubes:
		cube.material_override = null
	
	print("CubeColorizer3D: Reset %d cubes" % cubes.size())

func test_all_red():
	"""Make all cubes red for testing"""
	print("CubeColorizer3D: Making all cubes red...")
	var cubes = find_all_cube_meshes()
	
	for cube in cubes:
		apply_color_to_mesh(cube, Color.RED, "red")
	
	print("CubeColorizer3D: Made %d cubes red" % cubes.size())

func test_rainbow():
	"""Apply rainbow colors for testing"""
	print("CubeColorizer3D: Applying rainbow colors...")
	var cubes = find_all_cube_meshes()
	var rainbow_colors = [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.BLUE, Color.PURPLE]
	
	for i in range(cubes.size()):
		var color = rainbow_colors[i % rainbow_colors.size()]
		apply_color_to_mesh(cubes[i], color, "rainbow_%d" % (i % rainbow_colors.size()))
	
	print("CubeColorizer3D: Applied rainbow to %d cubes" % cubes.size())

func reapply_pattern():
	"""Reapply the rose vase pattern"""
	colorize_all_cubes()

func debug_cube_info():
	"""Print detailed information about found cubes"""
	print("CubeColorizer3D: === CUBE DEBUG INFO ===")
	var cubes = find_all_cube_meshes()
	var sorted_cubes = sort_cubes_by_3d_position(cubes)
	
	print("Total cubes found: %d" % cubes.size())
	print("Expected for 11x11 grid: 121")
	
	for i in range(sorted_cubes.size()):
		var cube = sorted_cubes[i]
		var pos = cube.global_position
		var grid_row = i / 11
		var grid_col = i % 11
		print("Cube %d: %s | Position (%.1f, %.1f, %.1f) | Grid (%d, %d)" % [i, cube.name, pos.x, pos.y, pos.z, grid_col, grid_row])
		
		# Stop after showing first 20 to avoid spam
		if i >= 20:
			print("... (showing first 20 of %d cubes)" % cubes.size())
			break
