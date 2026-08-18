# DialecticPanelGenerator.gd
# Spawns text panels from dialectic JSON files along Z-axis
# Usage: criticalinfo:dialectic_name:rotation:scale

extends Node3D
class_name DialecticPanelGenerator

const DIALECTIC_PATH = "res://commons/infoboards_3d/content/dialectic/"
const CODE_DISPLAY_SCENE = "res://commons/context/clipboard/codeDisplay.tscn"

# Layout settings (can be overridden by JSON)
var z_spacing: float = 3.0
var x_spacing: float = 2.5
var panel_scale: float = 0.8
var base_rotation: float = 0.0

# Loaded data
var dialectic_data: Dictionary = {}
var panels: Array = []

# Theme colors for panel borders
const THEME_COLORS = {
	"thesis": Color(0.8, 0.2, 0.2),
	"counter": Color(0.2, 0.4, 0.8),
	"critique": Color(0.8, 0.7, 0.2),
	"critique_of_counter": Color(0.8, 0.7, 0.2),
	"pragmatic": Color(0.2, 0.7, 0.3),
	"reality_check": Color(0.9, 0.5, 0.2),
	"hacker_response": Color(0.2, 0.8, 0.8),
	"limit": Color(0.8, 0.4, 0.2),
	"collective": Color(0.3, 0.8, 0.7),
	"recursion": Color(0.6, 0.3, 0.8)
}

func _ready():
	pass

# Load and generate panels from a dialectic JSON file
func generate_from_dialectic(dialectic_name: String, origin: Vector3, rotation_degrees: float = 0.0, scale_factor: float = 1.0) -> bool:
	base_rotation = rotation_degrees
	panel_scale = scale_factor

	# Load the dialectic JSON
	var json_path = DIALECTIC_PATH + dialectic_name + ".json"
	if not FileAccess.file_exists(json_path):
		push_error("DialecticPanelGenerator: Dialectic file not found: %s" % json_path)
		return false

	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("DialecticPanelGenerator: Could not open file: %s" % json_path)
		return false

	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("DialecticPanelGenerator: JSON parse error: %s" % json.get_error_message())
		return false

	dialectic_data = json.data

	# Get layout settings from JSON metadata
	if dialectic_data.has("_meta"):
		var meta = dialectic_data._meta
		if meta.has("layout"):
			var layout = meta.layout
			z_spacing = layout.get("z_spacing", z_spacing)
			x_spacing = layout.get("x_spacing", x_spacing)
			panel_scale = layout.get("panel_scale", panel_scale) * scale_factor

	print("DialecticPanelGenerator: Loaded '%s' with %d levels" % [dialectic_name, dialectic_data.get("levels", []).size()])
	print("DialecticPanelGenerator: Layout - z_spacing: %.1f, x_spacing: %.1f, scale: %.2f" % [z_spacing, x_spacing, panel_scale])

	# Generate panels for each level
	var levels = dialectic_data.get("levels", [])
	for level_data in levels:
		var level_index = level_data.get("level", 0)
		var theme = level_data.get("theme", "thesis")
		var level_panels = level_data.get("panels", [])

		for panel_data in level_panels:
			var x_offset = panel_data.get("x", 0)
			var panel_position = origin + Vector3(
				x_offset * x_spacing,
				1.5,  # Panel height above ground
				level_index * z_spacing
			)

			_spawn_panel(panel_data, panel_position, theme, level_index)

	print("DialecticPanelGenerator: Generated %d panels" % panels.size())
	return true

# Spawn a single panel at the given position
func _spawn_panel(panel_data: Dictionary, position: Vector3, theme: String, level: int) -> void:
	# Load the code_display scene as base
	if not ResourceLoader.exists(CODE_DISPLAY_SCENE):
		push_error("DialecticPanelGenerator: Code display scene not found: %s" % CODE_DISPLAY_SCENE)
		return

	var panel_scene = load(CODE_DISPLAY_SCENE)
	if not panel_scene:
		push_error("DialecticPanelGenerator: Could not load panel scene")
		return

	var panel = panel_scene.instantiate()
	panel.position = position
	panel.rotation_degrees.y = base_rotation
	panel.scale = Vector3.ONE * panel_scale

	add_child(panel)
	panels.append(panel)

	# Format the content for display
	var content = _format_panel_content(panel_data, theme, level)

	# Store content in metadata for delayed initialization
	panel.set_meta("dialectic_content", content)

	# Use a timer to delay content setting - codeDisplay needs time to initialize
	_set_panel_content_delayed(panel, content)

# Set panel content after delay to ensure RichTextLabel is ready
func _set_panel_content_delayed(panel: Node, content: String) -> void:
	# Wait for multiple frames to ensure full initialization
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame

	if not is_instance_valid(panel):
		return

	print("DialecticPanelGenerator: Setting content on panel (length: %d)" % content.length())

	if panel.has_method("set_tutorial_from_text"):
		panel.set_tutorial_from_text(content)
	elif panel.has_method("_display_content"):
		panel._display_content(content)
	else:
		push_warning("DialecticPanelGenerator: Panel has no content display method")

# Format panel content with BBCode
func _format_panel_content(panel_data: Dictionary, theme: String, level: int) -> String:
	var title = panel_data.get("title", "")
	var position_text = panel_data.get("position", "")
	var narrative = panel_data.get("narrative", [])
	var code = panel_data.get("code", {})
	var qfep = panel_data.get("qfep", {})
	var transition = panel_data.get("transition", null)

	var theme_color = THEME_COLORS.get(theme, Color.WHITE)
	var color_hex = "#%02x%02x%02x" % [int(theme_color.r * 255), int(theme_color.g * 255), int(theme_color.b * 255)]

	var content = ""

	# Level indicator
	content += "[center][color=#666666]Level %d[/color][/center]\n\n" % level

	# Title with theme color
	content += "[center][font_size=24][color=%s][b]%s[/b][/color][/font_size][/center]\n\n" % [color_hex, title]

	# Position statement (emphasized)
	if not position_text.is_empty():
		content += "[center][i]\"%s\"[/i][/center]\n\n" % position_text

	content += "[hr]\n\n"

	# Narrative paragraphs
	if narrative.size() > 0:
		for paragraph in narrative:
			if not paragraph.is_empty():
				content += "%s\n\n" % paragraph

	# Code block
	if code.has("block") and not code.block.is_empty():
		content += "[code]%s[/code]\n\n" % code.block

	# QFEP connection
	if qfep.has("term"):
		content += "[color=cyan][b]QFEP: %s[/b][/color]\n" % qfep.get("term", "")
		if qfep.has("description"):
			content += "[color=cyan]%s[/color]\n\n" % qfep.get("description", "")

	# Transition to next level
	if transition != null and not str(transition).is_empty():
		content += "\n[center][color=#888888][i]%s[/i][/color][/center]" % transition

	return content

# Get number of panels generated
func get_panel_count() -> int:
	return panels.size()

# Clear all generated panels
func clear_panels() -> void:
	for panel in panels:
		if is_instance_valid(panel):
			panel.queue_free()
	panels.clear()
