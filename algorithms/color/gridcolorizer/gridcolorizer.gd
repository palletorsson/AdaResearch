# CubeColorizer3D.gd
# MultiMesh-compatible cube colorizer
# Finds MultiMeshInstance3D and applies colors using per-instance color system

extends Node

@export var color_palette_resource: Resource = preload("res://algorithms/color/color_palettes.tres")
@export var multimesh_path: NodePath = ""
@export var debug_logs: bool = false
@export var auto_cycle_enabled: bool = true
@export var cycle_interval_seconds: float = 10.0

const DEFAULT_PALETTE_SEQUENCE := [
	"starry_night",
	"mondrian_grid",
	"stonewall_freedom",
	"frida_kahlo",
	"neon_cyberpunk"
]
const SPECIAL_PATTERN_NAMES := ["sphere_reflection"]

var current_pattern_index := 0
var palette_pattern_names: Array = []
var gradient_pattern_names: Array = []
var pattern_names: Array = []

# Manual pattern control
# MultiMesh references
var multimesh_instance: MultiMeshInstance3D = null
var multimesh: MultiMesh = null
var grid_structure: GridStructureComponent = null
var _cycle_active := false

func _log(message: String) -> void:
	if debug_logs:
		print(message)

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
	
	gradient_pattern_names = GameManager.get_all_gradient_names()
	
	pattern_names = palette_pattern_names.duplicate()
	pattern_names.append_array(gradient_pattern_names)
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

func _ready():
	_log("ColorGrid: Ready to cycle through palette patterns")
	_initialize_pattern_names()

	# Wait one second before checking for MultiMesh
	await get_tree().create_timer(1.0).timeout

	# Find MultiMesh
	if not find_multimesh():
		_log("ColorGrid: WARNING - Could not find MultiMeshInstance3D")
		return

	# Apply initial pattern
	if pattern_names.size() > 0:
		_apply_named_pattern(pattern_names[current_pattern_index])
		_log("ColorGrid: Applied initial pattern: %s" % pattern_names[current_pattern_index])

	# Connect to next cubes if they exist
	connect_to_next_cubes()

	# Start auto cycling (can be disabled by next cubes)
	if auto_cycle_enabled:
		start_pattern_cycling()

func find_multimesh() -> bool:
	_log("ColorGrid: Searching for MultiMesh...")

	# Try exported path first
	if not multimesh_path.is_empty():
		_log("ColorGrid: Trying path: %s" % multimesh_path)
		multimesh_instance = get_node_or_null(multimesh_path)
		if multimesh_instance:
			_log("ColorGrid: Found via exported path!")

	# Search parent hierarchy
	if not multimesh_instance:
		_log("ColorGrid: Searching parent hierarchy...")
		multimesh_instance = _find_multimesh_recursive(get_parent())
		if multimesh_instance:
			_log("ColorGrid: Found in parent hierarchy!")

	# Search scene root
	if not multimesh_instance:
		_log("ColorGrid: Searching scene root...")
		multimesh_instance = _find_multimesh_recursive(get_tree().current_scene)
		if multimesh_instance:
			_log("ColorGrid: Found in scene root!")

	if multimesh_instance:
		_log("ColorGrid: MultiMeshInstance3D found: %s" % multimesh_instance.name)
		multimesh = multimesh_instance.multimesh
		if multimesh:
			_log("ColorGrid: MultiMesh resource exists")
			_log("ColorGrid: Instance count: %d" % multimesh.instance_count)
			_log("ColorGrid: use_colors: %s" % multimesh.use_colors)

			# Enable per-instance colors if not already enabled
			if not multimesh.use_colors:
				_log("ColorGrid: WARNING - use_colors was false, enabling it now...")
				multimesh.use_colors = true

			# Try to find GridStructureComponent for position info
			grid_structure = _find_grid_structure(get_parent())
			if not grid_structure:
				grid_structure = _find_grid_structure(get_tree().current_scene)

			return true
		else:
			_log("ColorGrid: ERROR - MultiMeshInstance3D found but multimesh resource is null!")
	else:
		_log("ColorGrid: ERROR - No MultiMeshInstance3D found in scene!")

	return false

func _find_multimesh_recursive(node: Node) -> MultiMeshInstance3D:
	if node is MultiMeshInstance3D and node.name == "GridMultiMesh":
		return node
	for child in node.get_children():
		var result = _find_multimesh_recursive(child)
		if result:
			return result
	return null

func _find_grid_structure(node: Node) -> GridStructureComponent:
	if node is GridStructureComponent:
		return node
	for child in node.get_children():
		var result = _find_grid_structure(child)
		if result:
			return result
	return null

func _apply_named_pattern(pattern_name: String) -> void:
	if pattern_name.is_empty():
		return

	if palette_pattern_names.has(pattern_name):
		var palette_colors = _get_palette_colors(pattern_name)
		apply_pattern_to_multimesh(palette_colors, pattern_name)
	elif gradient_pattern_names.has(pattern_name):
		apply_gradient_pattern(pattern_name)
	elif SPECIAL_PATTERN_NAMES.has(pattern_name):
		apply_sphere_reflection(pattern_name)
	else:
		_log("ColorGrid: WARNING - Unknown pattern '%s'" % pattern_name)

func start_pattern_cycling():
	_initialize_pattern_names()
	if _cycle_active:
		return

	if pattern_names.is_empty():
		_log("ColorGrid: No patterns available - pattern cycling aborted")
		return

	if not multimesh or multimesh.instance_count == 0:
		_log("ColorGrid: No MultiMesh found - pattern cycling aborted")
		return

	_cycle_active = true
	while _cycle_active and auto_cycle_enabled and is_inside_tree():
		var pattern_name = pattern_names[current_pattern_index]
		_log("ColorGrid: Switching to pattern: %s (%d/%d)" % [pattern_name, current_pattern_index + 1, pattern_names.size()])
		_apply_named_pattern(pattern_name)

		await get_tree().create_timer(max(cycle_interval_seconds, 0.1)).timeout
		if not _cycle_active or not auto_cycle_enabled:
			break

		if pattern_names.is_empty():
			_initialize_pattern_names()
			if pattern_names.is_empty():
				break
		current_pattern_index = (current_pattern_index + 1) % pattern_names.size()
	_cycle_active = false

func apply_pattern_to_multimesh(palette_colors: Array, pattern_name: String):
	if not multimesh:
		_log("ColorGrid: ERROR - No multimesh!")
		return

	if palette_colors.is_empty():
		_log("ColorGrid: ERROR - No palette colors!")
		return

	if not multimesh.use_colors:
		_log("ColorGrid: ERROR - MultiMesh use_colors is not enabled!")
		return

	var instance_count = multimesh.instance_count
	var grid_size := int(sqrt(float(instance_count)))
	if grid_size * grid_size < instance_count:
		grid_size += 1
	grid_size = max(grid_size, 1)

	var colors_applied = 0
	var sample_colors = []  # Debug: store first few colors to verify they're different

	for i in range(instance_count):
		var row = i / grid_size
		var col = i % grid_size
		var color_index := int((row + col) % palette_colors.size())
		var color_value = palette_colors[color_index] if color_index < palette_colors.size() else Color.WHITE

		if color_value is Color:
			multimesh.set_instance_color(i, color_value)
			colors_applied += 1

			# Debug: collect first 5 colors
			if i < 5:
				sample_colors.append("i%d=%s" % [i, color_value])

	# Debug: Verify MultiMesh configuration
	_log("ColorGrid: MultiMesh.use_colors = %s" % multimesh.use_colors)
	_log("ColorGrid: MultiMesh.instance_count = %d" % multimesh.instance_count)

	# CRITICAL: Adjust material to make instance colors visible
	_adjust_material_for_colors()

	_log("ColorGrid: Applied palette '%s' - set %d colors on %d instances" % [pattern_name, colors_applied, instance_count])
	_log("ColorGrid: Sample colors: %s" % ", ".join(sample_colors))

func _adjust_material_for_colors():
	"""Adjust shader parameters to make instance colors visible"""
	if not multimesh_instance:
		_log("ColorGrid: No multimesh_instance found")
		return

	var material = multimesh_instance.material_override
	if not material:
		_log("ColorGrid: No material_override found on MultiMeshInstance3D")
		return

	if material is ShaderMaterial:
		var shader_mat = material as ShaderMaterial
		var shader_path: String = "no shader"
		if shader_mat.shader:
			shader_path = str(shader_mat.shader.resource_path)
		_log("ColorGrid: Found ShaderMaterial: %s" % shader_path)

		# Set modelColor to white so instance colors show through
		shader_mat.set_shader_parameter("modelColor", Color.WHITE)

		# Reduce wireframe opacity to make interior colors more visible
		shader_mat.set_shader_parameter("wireframeOpacity", 0.3)

		# Ensure interior is visible
		shader_mat.set_shader_parameter("show_interior", true)

		# Increase model opacity
		shader_mat.set_shader_parameter("modelOpacity", 1.0)

		_log("ColorGrid: Adjusted shader parameters for instance color visibility")
	else:
		_log("ColorGrid: Material is not a ShaderMaterial. Type: %s" % material.get_class())

func apply_gradient_pattern(gradient_name: String):
	if not multimesh:
		return

	var instance_count = multimesh.instance_count
	var grid_size = int(sqrt(float(instance_count)))
	if grid_size * grid_size < instance_count:
		grid_size += 1

	var gradient_colors = get_gradient_colors(gradient_name)

	for i in range(instance_count):
		var row = i / grid_size
		var col = i % grid_size
		var gradient_color = calculate_gradient_color(row, col, grid_size, gradient_colors, gradient_name)
		multimesh.set_instance_color(i, gradient_color)

	# CRITICAL: Adjust material to make instance colors visible
	_adjust_material_for_colors()

func get_gradient_colors(gradient_name: String) -> Array:
	return GameManager.get_gradient_palette(gradient_name)

func calculate_gradient_color(row: int, col: int, grid_size: int, gradient_colors: Array, gradient_name: String) -> Color:
	match gradient_name:
		"rainbow_gradient":
			var progress = float(row + col) / float(2 * (grid_size - 1))
			return interpolate_gradient(progress, gradient_colors)
		"sunset_gradient":
			var progress = float(col) / float(grid_size - 1)
			return interpolate_gradient(progress, gradient_colors)
		"ocean_gradient":
			var progress = float(row) / float(grid_size - 1)
			return interpolate_gradient(progress, gradient_colors)
		"pink_gradient":
			var progress = float(row + col) / float(2 * (grid_size - 1))
			return interpolate_gradient(progress, gradient_colors)
		_:
			return Color.WHITE

func interpolate_gradient(progress: float, gradient_colors: Array) -> Color:
	progress = clamp(progress, 0.0, 1.0)

	if gradient_colors.size() <= 1:
		return gradient_colors[0] if gradient_colors.size() > 0 else Color.WHITE

	var segment_size = 1.0 / float(gradient_colors.size() - 1)
	var segment_index = int(progress / segment_size)

	if segment_index >= gradient_colors.size() - 1:
		return gradient_colors[gradient_colors.size() - 1]

	var local_progress = (progress - segment_index * segment_size) / segment_size
	var color1 = gradient_colors[segment_index] as Color
	var color2 = gradient_colors[segment_index + 1] as Color

	return color1.lerp(color2, local_progress)

func apply_sphere_reflection(_pattern_name: String):
	if not multimesh:
		return

	var instance_count = multimesh.instance_count
	var grid_size = int(sqrt(float(instance_count)))
	if grid_size * grid_size < instance_count:
		grid_size += 1

	var center = Vector2(grid_size / 2.0, grid_size / 2.0)

	for i in range(instance_count):
		var row = i / grid_size
		var col = i % grid_size
		var sphere_color = calculate_sphere_reflection_color(row, col, center, grid_size)
		multimesh.set_instance_color(i, sphere_color)

	# CRITICAL: Adjust material to make instance colors visible
	_adjust_material_for_colors()

func calculate_sphere_reflection_color(row: int, col: int, center: Vector2, grid_size: int) -> Color:
	var pos = Vector2(float(col), float(row))
	var distance_from_center = pos.distance_to(center)
	var max_distance = center.distance_to(Vector2(0.0, 0.0))
	var normalized_distance = clamp(distance_from_center / max_distance, 0.0, 1.0)
	var sphere_radius = 0.7

	if normalized_distance > sphere_radius:
		return Color(0.05, 0.05, 0.1)
	else:
		var sphere_progress = normalized_distance / sphere_radius
		var angle = atan2(pos.y - center.y, pos.x - center.x)
		var angle_normalized = (angle + PI) / (2.0 * PI)

		var base_hue = angle_normalized
		var saturation = 0.8 - (sphere_progress * 0.3)
		var brightness = 0.9 - (sphere_progress * 0.4)

		var noise_factor = sin(angle * 3.0) * 0.1
		base_hue += noise_factor

		var reflection_color = Color.from_hsv(base_hue, saturation, brightness)

		if sphere_progress < 0.3:
			var highlight_strength = (0.3 - sphere_progress) / 0.3
			reflection_color = reflection_color.lerp(Color.WHITE, highlight_strength * 0.5)
		elif sphere_progress > 0.6:
			var edge_darkness = (sphere_progress - 0.6) / 0.4
			reflection_color = reflection_color.lerp(Color.BLACK, edge_darkness * 0.4)

		return reflection_color

# Next cube integration functions
func connect_to_next_cubes():
	var next_cubes = find_next_cubes()
	if next_cubes.size() > 0:
		_log("ColorGrid: Found %d NextCube(s), disabling auto-cycle" % next_cubes.size())
		auto_cycle_enabled = false
		_cycle_active = false

		for next_cube in next_cubes:
			if next_cube.has_signal("next_requested"):
				next_cube.next_requested.connect(_on_next_requested)
				_log("ColorGrid: Connected to NextCube at %s" % next_cube.global_position)

func find_next_cubes() -> Array:
	var next_cubes = []
	find_next_cubes_recursive(get_tree().current_scene, next_cubes)
	return next_cubes

func find_next_cubes_recursive(node: Node, next_cubes: Array):
	if node.get_script() and node.get_script().get_global_name() == "NextCube":
		next_cubes.append(node)
	for child in node.get_children():
		find_next_cubes_recursive(child, next_cubes)

func _on_next_requested(from_position: Vector3):
	_log("ColorGrid: Next pattern requested from %s" % from_position)
	advance_to_next_pattern()

func advance_to_next_pattern():
	if pattern_names.is_empty():
		_initialize_pattern_names()
		if pattern_names.is_empty():
			_log("ColorGrid: No patterns available to advance")
			return

	current_pattern_index = (current_pattern_index + 1) % pattern_names.size()
	var pattern_name = pattern_names[current_pattern_index]
	_log("ColorGrid: Switching to pattern: %s (%d/%d)" % [pattern_name, current_pattern_index + 1, pattern_names.size()])
	_apply_named_pattern(pattern_name)

# Public API
func get_current_pattern_index() -> int:
	return current_pattern_index

func get_pattern_count() -> int:
	return pattern_names.size()

func set_pattern_by_index(index: int):
	_initialize_pattern_names()
	if index >= 0 and index < pattern_names.size():
		current_pattern_index = index
		_apply_named_pattern(pattern_names[current_pattern_index])

func get_current_pattern_name() -> String:
	return pattern_names[current_pattern_index]

func enable_auto_cycle():
	auto_cycle_enabled = true
	if not _cycle_active:
		start_pattern_cycling()

func disable_auto_cycle():
	auto_cycle_enabled = false
	_cycle_active = false

func _exit_tree() -> void:
	_cycle_active = false
