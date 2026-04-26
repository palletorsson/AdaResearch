# GridColorMutator.gd
# Color-channel mutator: writes per-instance Color values into the GridMultiMesh
# via MultiMesh.set_instance_color. Registers palette sweeps, gradient patterns,
# and the special sphere-reflection pattern as named expressions.
#
# Extends GridMutatorBase. The lifecycle (multimesh finding, cycling, NextCube)
# lives in the base. This class is purely the color-pattern catalogue and
# dispatcher — extracted from the original GridColorizer so future
# GridVisibilityMutator / GridTransformMutator can reuse the same lifecycle.
#
# @identity
# essence: color_pattern(i) -> MultiMesh.set_instance_color(i)
# desire: to fill the floor with palettes, gradients, and the sphere-reflection
#   illusion as one register-and-cycle catalogue
# critical_parameter: pattern_names[current_pattern_index]
# triggers: auto-cycle (base); NextCube (base); palette resource; GameManager
#   gradient registry
# emerges: an apparent reflective sphere on a flat grid — pure positional math
# needs: GridMultiMesh with use_colors enabled [auto]; ShaderMaterial with
#   modelColor parameter [for gradient/sphere visibility]
# relationships: GridMutatorBase (parent); GameManager.gradients;
#   color_palettes.tres
# truth: color is a function of position, not a property of the cube

class_name GridColorMutator
extends GridMutatorBase

@export var color_palette_resource: Resource = preload("res://algorithms/color/color_palettes.tres")

const DEFAULT_PALETTE_SEQUENCE := [
	"starry_night",
	"mondrian_grid",
	"stonewall_freedom",
	"frida_kahlo",
	"neon_cyberpunk",
]
const SPECIAL_PATTERN_NAMES := ["sphere_reflection"]

var palette_pattern_names: Array = []
var gradient_pattern_names: Array = []


# --- base hooks ------------------------------------------------------------

func _initialize_pattern_names() -> void:
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


func _post_find_multimesh_setup() -> bool:
	if not multimesh.use_colors:
		_log("GridColorMutator: enabling use_colors on MultiMesh")
		multimesh.use_colors = true
	return true


func _apply_named_pattern(pattern_name: String) -> void:
	if pattern_name.is_empty():
		return
	if palette_pattern_names.has(pattern_name):
		var palette_colors: Array = _get_palette_colors(pattern_name)
		apply_pattern_to_multimesh(palette_colors, pattern_name)
	elif gradient_pattern_names.has(pattern_name):
		apply_gradient_pattern(pattern_name)
	elif SPECIAL_PATTERN_NAMES.has(pattern_name):
		apply_sphere_reflection(pattern_name)
	else:
		_log("GridColorMutator: WARNING - Unknown pattern '%s'" % pattern_name)


# --- color-channel logic (lifted verbatim from GridColorizer) --------------

func _get_palette_colors(palette_name: String) -> Array:
	if color_palette_resource and "palettes" in color_palette_resource:
		var palettes_dict = color_palette_resource.palettes
		if typeof(palettes_dict) == TYPE_DICTIONARY and palettes_dict.has(palette_name):
			var entry = palettes_dict[palette_name]
			if typeof(entry) == TYPE_DICTIONARY and entry.has("colors"):
				var result: Array = []
				for color_value in entry["colors"]:
					result.append(color_value)
				return result
	return []


func apply_pattern_to_multimesh(palette_colors: Array, pattern_name: String) -> void:
	if not multimesh or palette_colors.is_empty() or not multimesh.use_colors:
		return

	var instance_count: int = multimesh.instance_count
	var grid_size: int = int(sqrt(float(instance_count)))
	if grid_size * grid_size < instance_count:
		grid_size += 1
	grid_size = max(grid_size, 1)

	for i in range(instance_count):
		var row: int = i / grid_size
		var col: int = i % grid_size
		var color_index: int = (row + col) % palette_colors.size()
		var color_value = palette_colors[color_index]
		if color_value is Color:
			multimesh.set_instance_color(i, color_value)

	_adjust_material_for_colors()
	_log("GridColorMutator: applied palette '%s' to %d instances" % [pattern_name, instance_count])


func _adjust_material_for_colors() -> void:
	if not multimesh_instance:
		return
	var material = multimesh_instance.material_override
	if not material or not (material is ShaderMaterial):
		return
	var shader_mat := material as ShaderMaterial
	shader_mat.set_shader_parameter("modelColor", Color.WHITE)
	shader_mat.set_shader_parameter("wireframeOpacity", 0.3)
	shader_mat.set_shader_parameter("show_interior", true)
	shader_mat.set_shader_parameter("modelOpacity", 1.0)


func apply_gradient_pattern(gradient_name: String) -> void:
	if not multimesh:
		return
	var instance_count: int = multimesh.instance_count
	var grid_size: int = int(sqrt(float(instance_count)))
	if grid_size * grid_size < instance_count:
		grid_size += 1
	var gradient_colors: Array = GameManager.get_gradient_palette(gradient_name)
	for i in range(instance_count):
		var row: int = i / grid_size
		var col: int = i % grid_size
		multimesh.set_instance_color(i, calculate_gradient_color(row, col, grid_size, gradient_colors, gradient_name))
	_adjust_material_for_colors()


func calculate_gradient_color(row: int, col: int, grid_size: int, gradient_colors: Array, gradient_name: String) -> Color:
	match gradient_name:
		"rainbow_gradient", "pink_gradient":
			var p: float = float(row + col) / float(2 * (grid_size - 1))
			return interpolate_gradient(p, gradient_colors)
		"sunset_gradient":
			var p: float = float(col) / float(grid_size - 1)
			return interpolate_gradient(p, gradient_colors)
		"ocean_gradient":
			var p: float = float(row) / float(grid_size - 1)
			return interpolate_gradient(p, gradient_colors)
		_:
			return Color.WHITE


func interpolate_gradient(progress: float, gradient_colors: Array) -> Color:
	progress = clamp(progress, 0.0, 1.0)
	if gradient_colors.size() <= 1:
		return gradient_colors[0] if gradient_colors.size() > 0 else Color.WHITE
	var segment_size: float = 1.0 / float(gradient_colors.size() - 1)
	var segment_index: int = int(progress / segment_size)
	if segment_index >= gradient_colors.size() - 1:
		return gradient_colors[gradient_colors.size() - 1]
	var local_progress: float = (progress - segment_index * segment_size) / segment_size
	var color1: Color = gradient_colors[segment_index] as Color
	var color2: Color = gradient_colors[segment_index + 1] as Color
	return color1.lerp(color2, local_progress)


func apply_sphere_reflection(_pattern_name: String) -> void:
	if not multimesh:
		return
	var instance_count: int = multimesh.instance_count
	var grid_size: int = int(sqrt(float(instance_count)))
	if grid_size * grid_size < instance_count:
		grid_size += 1
	var center := Vector2(grid_size / 2.0, grid_size / 2.0)
	for i in range(instance_count):
		var row: int = i / grid_size
		var col: int = i % grid_size
		multimesh.set_instance_color(i, calculate_sphere_reflection_color(row, col, center, grid_size))
	_adjust_material_for_colors()


func calculate_sphere_reflection_color(row: int, col: int, center: Vector2, grid_size: int) -> Color:
	var pos := Vector2(float(col), float(row))
	var distance_from_center: float = pos.distance_to(center)
	var max_distance: float = center.distance_to(Vector2(0.0, 0.0))
	var normalized_distance: float = clamp(distance_from_center / max_distance, 0.0, 1.0)
	var sphere_radius := 0.7

	if normalized_distance > sphere_radius:
		return Color(0.05, 0.05, 0.1)

	var sphere_progress: float = normalized_distance / sphere_radius
	var angle: float = atan2(pos.y - center.y, pos.x - center.x)
	var angle_normalized: float = (angle + PI) / (2.0 * PI)

	var base_hue: float = angle_normalized + sin(angle * 3.0) * 0.1
	var saturation: float = 0.8 - (sphere_progress * 0.3)
	var brightness: float = 0.9 - (sphere_progress * 0.4)

	var reflection_color := Color.from_hsv(base_hue, saturation, brightness)
	if sphere_progress < 0.3:
		var highlight_strength: float = (0.3 - sphere_progress) / 0.3
		reflection_color = reflection_color.lerp(Color.WHITE, highlight_strength * 0.5)
	elif sphere_progress > 0.6:
		var edge_darkness: float = (sphere_progress - 0.6) / 0.4
		reflection_color = reflection_color.lerp(Color.BLACK, edge_darkness * 0.4)
	return reflection_color
