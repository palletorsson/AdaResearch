# CubeColorizer3D.gd
# Simple 3D cube colorizer that finds MeshInstance3D nodes with "cube" in their name
# and applies the rose vase color pattern to an 11x11 grid

extends Node

@export var color_palette_resource: Resource = preload("res://algorithms/color/color_palettes.tres")

const DEFAULT_PALETTE_SEQUENCE := [
	"starry_night",
	"mondrian_grid",
	"stonewall_freedom",
	"frida_kahlo",
	"neon_cyberpunk"
]
const GRADIENT_PATTERN_NAMES := [
	"rainbow_gradient",
	"sunset_gradient",
	"ocean_gradient",
	"pink_gradient"
]
const SPECIAL_PATTERN_NAMES := ["sphere_reflection"]

var current_pattern_index := 0
var palette_pattern_names: Array = []
var pattern_names: Array = []

# Manual pattern control
var auto_cycle_enabled := true


func _initialize_pattern_names():
	if pattern_names.size() > 0:
		return

	palette_pattern_names.clear()
	if color_palette_resource and "palettes" in color_palette_resource:
		var palettes_dict = color_palette_resource.palettes
		if typeof(palettes_dict) == TYPE_DICTIONARY:
			for palette_name in DEFAULT_PALETTE_SEQUENCE:
				if palettes_dict.has(palette_name):
					palette_pattern_names.append(palette_name)
			if palette_pattern_names.is_empty():
				for palette_name in palettes_dict.keys():
					palette_pattern_names.append(palette_name)

	pattern_names = palette_pattern_names.duplicate()
	pattern_names.append_array(GRADIENT_PATTERN_NAMES)
	pattern_names.append_array(SPECIAL_PATTERN_NAMES)
	current_pattern_index = clamp(current_pattern_index, 0, max(pattern_names.size() - 1, 0))

func _get_palette_colors(palette_name: String) -> Array:
	if color_palette_resource and "palettes" in color_palette_resource:
		var palettes_dict = color_palette_resource.palettes
		if typeof(palettes_dict) == TYPE_DICTIONARY and palettes_dict.has(palette_name):
			var entry = palettes_dict[palette_name]
			if typeof(entry) == TYPE_DICTIONARY and entry.has("colors"):
				var colors_source = entry["colors"]
				var result: Array = []
				for color_value in colors_source:
					result.append(color_value)
				return result
	return []

func _apply_named_pattern(cubes: Array[MeshInstance3D], pattern_name: String) -> void:
	if pattern_name.is_empty():
		return

	if palette_pattern_names.has(pattern_name):
		var palette_colors = _get_palette_colors(pattern_name)
		apply_pattern_to_cubes(cubes, palette_colors, pattern_name)
	elif GRADIENT_PATTERN_NAMES.has(pattern_name):
		apply_gradient_pattern(cubes, pattern_name)
	elif SPECIAL_PATTERN_NAMES.has(pattern_name):
		apply_sphere_reflection(cubes, pattern_name)
	else:
		print("ColorGrid: WARNING - Unknown pattern '%s'" % pattern_name)


func _ready():
	print("ColorGrid: Ready to cycle through vibrant queer patterns! 🌈")
	_initialize_pattern_names()
	# Wait one second before checking for cubes
	await get_tree().create_timer(1.0).timeout
	
	# Connect to next cubes if they exist
	connect_to_next_cubes()
	
	# Start auto cycling (can be disabled by next cubes)
	if auto_cycle_enabled:
		start_pattern_cycling()

func colorize_all_cubes():
	print("ColorGrid: Starting single cube colorization...")
	
	# Find all MeshInstance3D nodes with "cube" in their name
	var cube_meshes = find_all_cube_meshes()
	print("ColorGrid: Found %d cube meshes" % cube_meshes.size())
	
	if cube_meshes.is_empty():
		print("ColorGrid: No cube meshes found!")
		return
	
	# Sort cubes by position for consistent mapping
	var sorted_cubes = sort_cubes_by_3d_position(cube_meshes)
	
	_initialize_pattern_names()
	if pattern_names.is_empty():
		print("ColorGrid: WARNING - No patterns available")
		return

	var pattern_name = pattern_names[0]
	_apply_named_pattern(sorted_cubes, pattern_name)
	
	print("ColorGrid: Single cube colorization complete! 🎨")

func find_all_cube_meshes() -> Array[MeshInstance3D]:
	var cube_meshes: Array[MeshInstance3D] = []
	var scene_root = get_tree().current_scene
	
	# Recursively find all MeshInstance3D nodes with "cube" in the name
	find_cube_meshes_recursive(scene_root, cube_meshes)
	
	# Only show warnings or unexpected counts
	if cube_meshes.size() == 0:
		print("ColorGrid: WARNING - No cubes found!")
	elif cube_meshes.size() != 121:
		print("ColorGrid: Found %d cubes (expected 121)" % cube_meshes.size())
	
	return cube_meshes

func find_cube_meshes_recursive(node: Node, cube_list: Array[MeshInstance3D]):
	# Check if this node is a MeshInstance3D with "CubeBaseMesh" name (from cube_scene.tscn)
	if node is MeshInstance3D and ("cubebasemesh" in node.name.to_lower() or "cube" in node.name.to_lower()):
		cube_list.append(node as MeshInstance3D)
	
	# Check all children
	for child in node.get_children():
		find_cube_meshes_recursive(child, cube_list)

func sort_cubes_by_3d_position(cubes: Array[MeshInstance3D]) -> Array[MeshInstance3D]:
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
	
	return cubes


func start_pattern_cycling():
	_initialize_pattern_names()
	if pattern_names.is_empty():
		print("ColorGrid: No patterns available - pattern cycling aborted")
		return

	var cube_meshes = find_all_cube_meshes()
	if cube_meshes.is_empty():
		print("ColorGrid: No cubes found - pattern cycling aborted")
		return

	var sorted_cubes = sort_cubes_by_3d_position(cube_meshes)

	while true:
		var pattern_name = pattern_names[current_pattern_index]
		print("ColorGrid: Switching to pattern: %s (%d/%d)" % [pattern_name, current_pattern_index + 1, pattern_names.size()])
		_apply_named_pattern(sorted_cubes, pattern_name)

		await get_tree().create_timer(10.0).timeout

		if pattern_names.is_empty():
			_initialize_pattern_names()
			if pattern_names.is_empty():
				break
		current_pattern_index = (current_pattern_index + 1) % pattern_names.size()


func apply_pattern_to_cubes(cubes: Array[MeshInstance3D], palette_colors: Array, pattern_name: String):
	if palette_colors.is_empty():
		print("ColorGrid: WARNING - Palette '%s' has no colors" % pattern_name)
		return

	var cube_total := cubes.size()
	if cube_total == 0:
		return

	var grid_size := int(sqrt(float(cube_total)))
	if grid_size * grid_size < cube_total:
		grid_size += 1
	grid_size = max(grid_size, 1)

	var cube_index := 0
	var colored_count := 0

	for row in range(grid_size):
		for col in range(grid_size):
			if cube_index >= cube_total:
				break

			var color_index := int((row + col) % palette_colors.size())
			var color_value = palette_colors[color_index] if color_index < palette_colors.size() else null
			if color_value is Color:
				var cube_mesh = cubes[cube_index]
				apply_color_to_mesh(cube_mesh, color_value, "%s_%d" % [pattern_name, color_index])
				colored_count += 1
			else:
				print("ColorGrid: WARNING - Non-color entry in palette '%s' at index %d" % [pattern_name, color_index])

			cube_index += 1

	print("ColorGrid: Applied palette '%s' to %d cubes" % [pattern_name, colored_count])

func apply_gradient_pattern(cubes: Array[MeshInstance3D], gradient_name: String):
	var grid_size = 11  # 11x11 grid
	var cube_index = 0
	
	# Define gradient color schemes
	var gradient_colors = get_gradient_colors(gradient_name)
	
	for row in range(grid_size):
		for col in range(grid_size):
			if cube_index >= cubes.size():
				break
			
			var cube_mesh = cubes[cube_index]
			var gradient_color = calculate_gradient_color(row, col, grid_size, gradient_colors, gradient_name)
			
			apply_color_to_mesh(cube_mesh, gradient_color, gradient_name)
			cube_index += 1

func get_gradient_colors(gradient_name: String) -> Array:
	match gradient_name:
		"rainbow_gradient":
			return [
				Color(1.0, 0.0, 0.8),   # Magenta
				Color(1.0, 0.2, 0.4),   # Hot pink
				Color(1.0, 0.5, 0.0),   # Orange
				Color(1.0, 0.9, 0.0),   # Yellow
				Color(0.5, 1.0, 0.0),   # Lime
				Color(0.2, 0.9, 0.4),   # Green
				Color(0.0, 0.8, 0.8),   # Cyan
				Color(0.2, 0.6, 1.0),   # Blue
				Color(0.6, 0.2, 1.0)    # Purple
			]
		"sunset_gradient":
			return [
				Color(0.1, 0.1, 0.3),   # Deep purple (night)
				Color(0.4, 0.1, 0.5),   # Purple
				Color(0.8, 0.2, 0.4),   # Magenta
				Color(1.0, 0.4, 0.2),   # Orange-red
				Color(1.0, 0.6, 0.1),   # Orange
				Color(1.0, 0.8, 0.3),   # Yellow-orange
				Color(1.0, 0.9, 0.7),   # Warm yellow
				Color(0.9, 0.9, 0.8)    # Pale yellow
			]
		"ocean_gradient":
			return [
				Color(0.0, 0.1, 0.2),   # Deep ocean
				Color(0.0, 0.2, 0.4),   # Deep blue
				Color(0.0, 0.4, 0.6),   # Ocean blue
				Color(0.1, 0.6, 0.8),   # Bright blue
				Color(0.3, 0.8, 0.9),   # Light blue
				Color(0.5, 0.9, 0.9),   # Cyan
				Color(0.7, 0.95, 0.95), # Light cyan
				Color(0.9, 0.98, 0.98)  # Almost white
			]
		"pink_gradient":
			return [
				Color(0.4, 0.1, 0.2),   # Deep magenta
				Color(0.6, 0.2, 0.4),   # Dark pink
				Color(0.8, 0.3, 0.5),   # Medium pink
				Color(0.9, 0.4, 0.6),   # Rose pink
				Color(1.0, 0.5, 0.7),   # Hot pink
				Color(1.0, 0.7, 0.8),   # Light pink
				Color(1.0, 0.85, 0.9),  # Very light pink
				Color(1.0, 0.95, 0.97)  # Almost white pink
			]
		_:
			return [Color.RED, Color.BLUE]  # Fallback

func calculate_gradient_color(row: int, col: int, grid_size: int, gradient_colors: Array, gradient_name: String) -> Color:
	match gradient_name:
		"rainbow_gradient":
			# Diagonal rainbow from top-left to bottom-right
			var progress = float(row + col) / float(2 * (grid_size - 1))
			return interpolate_gradient(progress, gradient_colors)
			
		"sunset_gradient":
			# Horizontal gradient from left (night) to right (day)
			var progress = float(col) / float(grid_size - 1)
			return interpolate_gradient(progress, gradient_colors)
			
		"ocean_gradient":
			# Vertical gradient from top (deep) to bottom (surface)
			var progress = float(row) / float(grid_size - 1)
			return interpolate_gradient(progress, gradient_colors)
			
		"pink_gradient":
			# Diagonal gradient from top-left to bottom-right
			var progress = float(row + col) / float(2 * (grid_size - 1))
			return interpolate_gradient(progress, gradient_colors)
			
		_:
			return Color.WHITE

func interpolate_gradient(progress: float, gradient_colors: Array) -> Color:
	# Clamp progress between 0 and 1
	progress = clamp(progress, 0.0, 1.0)
	
	if gradient_colors.size() <= 1:
		return gradient_colors[0] if gradient_colors.size() > 0 else Color.WHITE
	
	# Calculate which two colors to interpolate between
	var segment_size = 1.0 / float(gradient_colors.size() - 1)
	var segment_index = int(progress / segment_size)
	
	# Handle edge case where progress = 1.0
	if segment_index >= gradient_colors.size() - 1:
		return gradient_colors[gradient_colors.size() - 1]
	
	# Calculate local progress within the segment
	var local_progress = (progress - segment_index * segment_size) / segment_size
	
	# Interpolate between the two colors
	var color1 = gradient_colors[segment_index] as Color
	var color2 = gradient_colors[segment_index + 1] as Color
	
	return color1.lerp(color2, local_progress)

func apply_sphere_reflection(cubes: Array[MeshInstance3D], pattern_name: String):
	var grid_size = 11  # 11x11 grid
	var cube_index = 0
	var center = Vector2(5.0, 5.0)  # Center of 11x11 grid
	
	for row in range(grid_size):
		for col in range(grid_size):
			if cube_index >= cubes.size():
				break
			
			var cube_mesh = cubes[cube_index]
			var sphere_color = calculate_sphere_reflection_color(row, col, center, grid_size)
			
			apply_color_to_mesh(cube_mesh, sphere_color, pattern_name)
			cube_index += 1

func calculate_sphere_reflection_color(row: int, col: int, center: Vector2, grid_size: int) -> Color:
	# Calculate distance from center (simulating sphere surface)
	var pos = Vector2(float(col), float(row))
	var distance_from_center = pos.distance_to(center)
	var max_distance = center.distance_to(Vector2(0.0, 0.0))  # Distance to corner
	
	# Normalize distance (0 = center, 1 = edge)
	var normalized_distance = clamp(distance_from_center / max_distance, 0.0, 1.0)
	
	# Create circular reflection zones like in the image
	var sphere_radius = 0.7  # Sphere coverage
	
	if normalized_distance > sphere_radius:
		# Outside sphere - dark background
		return Color(0.05, 0.05, 0.1)  # Very dark blue-black
	else:
		# Inside sphere - create reflection effect
		var sphere_progress = normalized_distance / sphere_radius
		
		# Calculate angle for rainbow reflection (like soap bubble)
		var angle = atan2(pos.y - center.y, pos.x - center.x)
		var angle_normalized = (angle + PI) / (2.0 * PI)  # 0 to 1
		
		# Create iridescent colors based on angle and distance
		var base_hue = angle_normalized
		var saturation = 0.8 - (sphere_progress * 0.3)  # Less saturated toward edges
		var brightness = 0.9 - (sphere_progress * 0.4)   # Darker toward edges
		
		# Add some noise for more realistic reflection
		var noise_factor = sin(angle * 3.0) * 0.1
		base_hue += noise_factor
		
		# Convert HSV to RGB for iridescent effect
		var reflection_color = Color.from_hsv(base_hue, saturation, brightness)
		
		# Add some highlights for the curved surface effect
		if sphere_progress < 0.3:
			# Bright highlight in center
			var highlight_strength = (0.3 - sphere_progress) / 0.3
			reflection_color = reflection_color.lerp(Color.WHITE, highlight_strength * 0.5)
		elif sphere_progress > 0.6:
			# Darker edges for sphere curvature
			var edge_darkness = (sphere_progress - 0.6) / 0.4
			reflection_color = reflection_color.lerp(Color.BLACK, edge_darkness * 0.4)
		
		return reflection_color

func apply_color_to_mesh(mesh_instance: MeshInstance3D, color: Color, color_name: String):
	# Check if the mesh already has a Grid shader material
	var material = mesh_instance.material_override
	
	if material and material is ShaderMaterial:
		# Clone the existing shader material to preserve shader and other settings
		var shader_material = material as ShaderMaterial
		var new_material = shader_material.duplicate()
		
		# Update the Grid shader parameters
		new_material.set_shader_parameter("modelColor", color)
		# Keep wireframe contrasting - use white for dark colors, black for light colors
		var wireframe_color = Color.WHITE if color.get_luminance() < 0.5 else Color.BLACK
		new_material.set_shader_parameter("wireframeColor", wireframe_color)
		# Set emission color to match the model color with some intensity
		new_material.set_shader_parameter("emissionColor", color)
		
		mesh_instance.material_override = new_material
	else:
		# Fallback: create new StandardMaterial3D if no shader material exists
		var standard_material = StandardMaterial3D.new()
		standard_material.albedo_color = color
		standard_material.emission_enabled = true
		standard_material.emission = color * 0.2
		
		mesh_instance.material_override = standard_material

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

# Next cube integration functions
func connect_to_next_cubes():
	"""Find and connect to NextCube instances in the scene"""
	var next_cubes = find_next_cubes()
	if next_cubes.size() > 0:
		print("ColorGrid: Found %d NextCube(s), disabling auto-cycle" % next_cubes.size())
		auto_cycle_enabled = false  # Disable auto cycling when next cubes are present
		
		for next_cube in next_cubes:
			if next_cube.has_signal("next_requested"):
				next_cube.next_requested.connect(_on_next_requested)
				print("ColorGrid: Connected to NextCube at %s" % next_cube.global_position)

func find_next_cubes() -> Array:
	"""Find all NextCube instances in the current scene"""
	var next_cubes = []
	find_next_cubes_recursive(get_tree().current_scene, next_cubes)
	return next_cubes

func find_next_cubes_recursive(node: Node, next_cubes: Array):
	"""Recursively search for NextCube nodes"""
	if node.get_script() and node.get_script().get_global_name() == "NextCube":
		next_cubes.append(node)
	
	for child in node.get_children():
		find_next_cubes_recursive(child, next_cubes)

func _on_next_requested(from_position: Vector3):
	"""Handle next pattern request from NextCube"""
	print("ColorGrid: 🎨 Next pattern requested from %s" % from_position)
	advance_to_next_pattern()


func advance_to_next_pattern():
	"""Manually advance to the next pattern"""
	if pattern_names.is_empty():
		_initialize_pattern_names()
		if pattern_names.is_empty():
			print("ColorGrid: No patterns available to advance")
			return

	current_pattern_index = (current_pattern_index + 1) % pattern_names.size()
	var pattern_name = pattern_names[current_pattern_index]

	print("ColorGrid: Switching to pattern: %s (%d/%d)" % [pattern_name, current_pattern_index + 1, pattern_names.size()])

	var cube_meshes = find_all_cube_meshes()
	if cube_meshes.is_empty():
		return

	var sorted_cubes = sort_cubes_by_3d_position(cube_meshes)
	_apply_named_pattern(sorted_cubes, pattern_name)

# Public API for external control
func get_current_pattern_index() -> int:
	return current_pattern_index

func get_pattern_count() -> int:
	return pattern_names.size()


func set_pattern_by_index(index: int):
	"""Set pattern by index"""
	_initialize_pattern_names()
	if index >= 0 and index < pattern_names.size():
		current_pattern_index = index
		var cube_meshes = find_all_cube_meshes()
		if cube_meshes.is_empty():
			return
		var sorted_cubes = sort_cubes_by_3d_position(cube_meshes)
		_apply_named_pattern(sorted_cubes, pattern_names[current_pattern_index])

func get_current_pattern_name() -> String:
	return pattern_names[current_pattern_index]

func enable_auto_cycle():
	"""Re-enable automatic pattern cycling"""
	auto_cycle_enabled = true
	start_pattern_cycling()

func disable_auto_cycle():
	"""Disable automatic pattern cycling"""
	auto_cycle_enabled = false
