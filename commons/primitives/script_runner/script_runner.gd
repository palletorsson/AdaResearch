# Script Runner - Live code display with line-by-line execution
# Shows GDScript code on a panel and executes it in real-time
# Uses Expression class to actually evaluate code and show results
extends Node3D

signal script_started
signal script_stopped
signal line_executed(line_index: int, line_text: String)
signal script_completed

@export_category("Script Configuration")
@export var script_name: String = "point"
@export var script_lines: Array[Dictionary] = []
@export var auto_loop: bool = true
@export var start_delay: float = 1.0

@export_category("Timing")
@export var default_line_duration: float = 1.0
@export var highlight_transition_time: float = 0.15
@export var button_press_cooldown: float = 0.25

@export_category("Display")
@export var panel_width: float = 0.6
@export var panel_height: float = 0.4
@export var font_size: int = 18
@export var line_height: float = 24.0
@export var show_line_numbers: bool = true

@export_category("Colors")
@export var bg_color: Color = Color(0.08, 0.08, 0.12, 0.95)
@export var text_color: Color = Color(0.9, 0.9, 0.9, 1.0)
@export var keyword_color: Color = Color(0.6, 0.8, 1.0, 1.0)
@export var string_color: Color = Color(0.6, 1.0, 0.6, 1.0)
@export var number_color: Color = Color(1.0, 0.8, 0.5, 1.0)
@export var comment_color: Color = Color(0.5, 0.5, 0.5, 1.0)
@export var highlight_color: Color = Color(1.0, 0.8, 0.0, 0.85)  # Bright yellow, much more visible

# Internal state
var _current_line: int = -1
var _is_running: bool = false
var _line_timer: float = 0.0
var _current_duration: float = 0.0
var _waiting_for_start: bool = true
var _last_button_press_time: float = -10.0

# Scene references
var _viewport: SubViewport
var _viewport_sprite: Sprite3D
var _code_label: RichTextLabel
var _highlight_rect: ColorRect
var _panel_mesh: MeshInstance3D
var _play_button: Area3D
var _result_label: Label3D  # Shows current line result
var _line_indicator: Label3D  # Shows "Line X:" indicator

# Target for actions
var _target_node: Node3D = null
var _spawned_objects: Array[Node3D] = []

# Expression evaluation
var _variables: Dictionary = {}  # Stores script variables like {"point": Vector3(1,2,3)}
var _expression: Expression = Expression.new()

# Grid visualization for array tutorials
var _grid_cells: Array = []  # 2D array of MeshInstance3D
var _grid_labels: Array = []  # Index labels for each cell
var _grid_size: int = 4
var _grid_node: Node3D = null
const CELL_SIZE: float = 0.08
const CELL_GAP: float = 0.01

# Color palette for grid
const GRID_COLORS = {
	"red": Color(1.0, 0.2, 0.2, 1.0),
	"blue": Color(0.2, 0.4, 1.0, 1.0),
	"green": Color(0.2, 1.0, 0.3, 1.0),
	"yellow": Color(1.0, 1.0, 0.2, 1.0),
	"white": Color(1.0, 1.0, 1.0, 1.0),
	"black": Color(0.1, 0.1, 0.1, 1.0),
	"orange": Color(1.0, 0.5, 0.1, 1.0),
	"purple": Color(0.7, 0.2, 1.0, 1.0),
	"cyan": Color(0.2, 1.0, 1.0, 1.0),
	"off": Color(0.15, 0.15, 0.2, 0.5)
}

# Keywords for syntax highlighting
const KEYWORDS = ["var", "func", "if", "else", "elif", "for", "while", "return",
                  "class", "extends", "const", "enum", "signal", "await", "in",
                  "true", "false", "null", "self", "print", "Vector3", "Color"]

# Path to scripts JSON
const SCRIPTS_PATH = "res://commons/primitives/script_runner/scripts.json"
const PLAY_ICON_IDLE: String = ">"
const PLAY_ICON_RUNNING: String = "||"

func _ready():
	_setup_display()
	_setup_result_display()
	_setup_play_button()
	_check_config_metadata()
	_load_script_config()
	_update_code_display()

func _check_config_metadata():
	# Check for config metadata set by GridInteractablesComponent
	# Format: script_runner#point sets config_point = true
	var known_scripts = ["point", "vector_math", "array", "pattern", "loop"]
	for script in known_scripts:
		var meta_key = "config_%s" % script
		if has_meta(meta_key) and get_meta(meta_key):
			script_name = script
			print("ScriptRunner: Found config metadata, setting script_name = '%s'" % script)
			return

	# Also check for explicit script_name in metadata
	if has_meta("config_script_name"):
		script_name = get_meta("config_script_name")
		print("ScriptRunner: Found explicit script_name = '%s'" % script_name)

func _setup_display():
	# Create SubViewport for 2D UI
	_viewport = SubViewport.new()
	_viewport.name = "CodeViewport"
	_viewport.size = Vector2i(int(panel_width * 1000), int(panel_height * 1000))
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_viewport)

	# Background panel
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = bg_color
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_viewport.add_child(bg)

	# Highlight bar (behind text) - prominent yellow bar
	_highlight_rect = ColorRect.new()
	_highlight_rect.name = "HighlightBar"
	_highlight_rect.color = highlight_color
	_highlight_rect.size = Vector2(_viewport.size.x, line_height + 4)  # Slightly taller
	_highlight_rect.position = Vector2(0, 0)
	_highlight_rect.visible = false
	_viewport.add_child(_highlight_rect)

	# Add a brighter edge/glow bar on top
	var highlight_glow = ColorRect.new()
	highlight_glow.name = "HighlightGlow"
	highlight_glow.color = Color(1.0, 1.0, 0.5, 0.4)  # Lighter glow
	highlight_glow.size = Vector2(_viewport.size.x, 3)
	highlight_glow.position = Vector2(0, 0)
	_highlight_rect.add_child(highlight_glow)

	# Left edge accent
	var left_accent = ColorRect.new()
	left_accent.name = "LeftAccent"
	left_accent.color = Color(1.0, 0.6, 0.0, 1.0)  # Orange accent
	left_accent.size = Vector2(6, line_height + 4)
	left_accent.position = Vector2(0, 0)
	_highlight_rect.add_child(left_accent)

	# Code display label
	_code_label = RichTextLabel.new()
	_code_label.name = "CodeLabel"
	_code_label.bbcode_enabled = true
	_code_label.fit_content = true
	_code_label.scroll_active = false
	_code_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_code_label.add_theme_font_size_override("normal_font_size", font_size)
	_code_label.add_theme_color_override("default_color", text_color)
	# Add padding
	_code_label.position = Vector2(10, 10)
	_code_label.size = Vector2(_viewport.size.x - 20, _viewport.size.y - 20)
	_viewport.add_child(_code_label)

	# 3D panel backing
	_panel_mesh = MeshInstance3D.new()
	_panel_mesh.name = "PanelMesh"
	var quad = QuadMesh.new()
	quad.size = Vector2(panel_width, panel_height)
	_panel_mesh.mesh = quad

	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.1, 0.1, 0.15, 1.0)
	panel_mat.metallic = 0.2
	panel_mat.roughness = 0.8
	_panel_mesh.material_override = panel_mat
	_panel_mesh.position.z = -0.001  # Slightly behind viewport sprite
	add_child(_panel_mesh)

	# Sprite3D to display viewport
	_viewport_sprite = Sprite3D.new()
	_viewport_sprite.name = "ViewportSprite"
	_viewport_sprite.texture = _viewport.get_texture()
	_viewport_sprite.pixel_size = panel_width / _viewport.size.x
	add_child(_viewport_sprite)

func _setup_result_display():
	# Line indicator - shows "Line X:" above result
	_line_indicator = Label3D.new()
	_line_indicator.name = "LineIndicator"
	_line_indicator.text = ""
	_line_indicator.font_size = 48
	_line_indicator.pixel_size = 0.0015
	_line_indicator.modulate = Color(1.0, 0.9, 0.3, 1.0)  # Yellow
	_line_indicator.position = Vector3(0, -panel_height / 2 - 0.08, 0.01)
	_line_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_line_indicator.visible = false
	add_child(_line_indicator)

	# Result label - shows the evaluated result
	_result_label = Label3D.new()
	_result_label.name = "ResultLabel"
	_result_label.text = ""
	_result_label.font_size = 56
	_result_label.pixel_size = 0.0015
	_result_label.modulate = Color(0.6, 1.0, 0.6, 1.0)  # Green
	_result_label.position = Vector3(0, -panel_height / 2 - 0.14, 0.01)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.visible = false
	add_child(_result_label)

func _setup_play_button():
	# Create clickable play button area - larger for VR touch
	_play_button = Area3D.new()
	_play_button.name = "PlayButton"
	_play_button.monitoring = true
	_play_button.monitorable = true

	# Set collision layers for VR interaction
	_play_button.collision_layer = 4  # Pickable objects layer
	_play_button.collision_mask = 1 + 4 + 1048576  # Static + pickable + player body

	var shape = BoxShape3D.new()
	shape.size = Vector3(0.12, 0.12, 0.08)  # Larger and deeper for easier touch

	var collision = CollisionShape3D.new()
	collision.shape = shape
	_play_button.add_child(collision)

	# Visual indicator - larger button
	var button_mesh = MeshInstance3D.new()
	button_mesh.name = "ButtonMesh"
	var box = BoxMesh.new()
	box.size = Vector3(0.10, 0.10, 0.02)
	button_mesh.mesh = box

	var button_mat = StandardMaterial3D.new()
	button_mat.albedo_color = Color(0.2, 0.6, 0.3, 1.0)
	button_mat.emission_enabled = true
	button_mat.emission = Color(0.1, 0.4, 0.2, 1.0)
	button_mat.emission_energy_multiplier = 0.5
	button_mesh.material_override = button_mat
	_play_button.add_child(button_mesh)

	# Play icon (triangle)
	var play_icon = Label3D.new()
	play_icon.name = "PlayIcon"
	play_icon.text = PLAY_ICON_IDLE
	play_icon.font_size = 64
	play_icon.pixel_size = 0.001
	play_icon.position.z = 0.012
	_play_button.add_child(play_icon)

	_play_button.position = Vector3(panel_width / 2 + 0.08, -panel_height / 2 + 0.06, 0.02)
	add_child(_play_button)

	# Connect signals for VR touch and mouse interaction
	_play_button.area_entered.connect(_on_play_button_touched)
	_play_button.body_entered.connect(_on_play_button_body_touched)
	_play_button.input_event.connect(_on_play_button_input)
	_play_button.mouse_entered.connect(_on_play_button_hover)

func _load_script_config():
	# Load script lines from JSON based on script_name
	# script_name can be set via export or map config (e.g., script_runner#point)
	if script_lines.is_empty() and not script_name.is_empty():
		_load_script_from_json(script_name)

func _load_script_from_json(name: String):
	var file = FileAccess.open(SCRIPTS_PATH, FileAccess.READ)
	if not file:
		push_error("ScriptRunner: Could not open scripts.json")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("ScriptRunner: Failed to parse scripts.json: %s" % json.get_error_message())
		return

	var data = json.get_data()
	if not data is Dictionary or not data.has("scripts"):
		push_error("ScriptRunner: Invalid scripts.json structure")
		return

	var scripts = data["scripts"]
	if not scripts.has(name):
		push_error("ScriptRunner: Script '%s' not found in scripts.json" % name)
		return

	var script_data = scripts[name]
	var lines = script_data.get("lines", [])

	# Convert JSON arrays to Vector3 where needed
	script_lines.clear()
	for line in lines:
		var converted_line = line.duplicate()
		if converted_line.has("params"):
			converted_line["params"] = _convert_params(converted_line["params"])
		script_lines.append(converted_line)

	print("ScriptRunner: Loaded script '%s' with %d lines" % [name, script_lines.size()])

func _convert_params(params: Dictionary) -> Dictionary:
	var result = params.duplicate()

	# Convert arrays to Vector3 for known position/offset parameters
	for key in ["pos", "offset"]:
		if result.has(key) and result[key] is Array:
			var arr = result[key]
			if arr.size() >= 3:
				result[key] = Vector3(arr[0], arr[1], arr[2])

	return result

func _update_code_display():
	var bbcode = ""
	var line_num = 1

	for i in range(script_lines.size()):
		var line = script_lines[i]
		var text = line.get("text", "")

		if text.is_empty():
			bbcode += "\n"
			continue

		# Line number
		if show_line_numbers:
			bbcode += "[color=#666666]%2d [/color]" % line_num

		# Syntax highlight the line
		bbcode += _syntax_highlight(text)
		bbcode += "\n"
		line_num += 1

	_code_label.text = bbcode

func _syntax_highlight(text: String) -> String:
	var result = text

	# Comments
	var comment_idx = result.find("#")
	if comment_idx >= 0:
		var before = result.substr(0, comment_idx)
		var comment = result.substr(comment_idx)
		result = before + "[color=#%s]%s[/color]" % [comment_color.to_html(false), comment]
		return _highlight_code_part(result.substr(0, comment_idx)) + result.substr(comment_idx)

	return _highlight_code_part(result)

func _highlight_code_part(text: String) -> String:
	var result = text

	# Keywords
	for keyword in KEYWORDS:
		var pattern = "\\b" + keyword + "\\b"
		var regex = RegEx.new()
		regex.compile(pattern)
		var matches = regex.search_all(result)
		# Process in reverse to not mess up indices
		for i in range(matches.size() - 1, -1, -1):
			var m = matches[i]
			var replacement = "[color=#%s]%s[/color]" % [keyword_color.to_html(false), m.get_string()]
			result = result.substr(0, m.get_start()) + replacement + result.substr(m.get_end())

	# Numbers
	var num_regex = RegEx.new()
	num_regex.compile("\\b\\d+\\.?\\d*\\b")
	var num_matches = num_regex.search_all(result)
	for i in range(num_matches.size() - 1, -1, -1):
		var m = num_matches[i]
		# Skip if inside a color tag
		if result.find("[color=", m.get_start() - 10) > m.get_start() - 20:
			continue
		var replacement = "[color=#%s]%s[/color]" % [number_color.to_html(false), m.get_string()]
		result = result.substr(0, m.get_start()) + replacement + result.substr(m.get_end())

	# Strings
	var str_regex = RegEx.new()
	str_regex.compile("\"[^\"]*\"")
	var str_matches = str_regex.search_all(result)
	for i in range(str_matches.size() - 1, -1, -1):
		var m = str_matches[i]
		var replacement = "[color=#%s]%s[/color]" % [string_color.to_html(false), m.get_string()]
		result = result.substr(0, m.get_start()) + replacement + result.substr(m.get_end())

	return result

func _process(delta):
	if not _is_running:
		return

	_line_timer += delta

	if _line_timer >= _current_duration:
		_advance_line()

func _advance_line():
	_current_line += 1
	_line_timer = 0.0

	if _current_line >= script_lines.size():
		if auto_loop:
			_reset_script()
			_current_line = 0
		else:
			stop()
			script_completed.emit()
			return

	var line_data = script_lines[_current_line]
	_current_duration = line_data.get("duration", default_line_duration)

	# Update highlight position
	_update_highlight(_current_line)

	# Execute action
	var action = line_data.get("action", "none")
	var params = line_data.get("params", {})
	_execute_action(action, params)

	line_executed.emit(_current_line, line_data.get("text", ""))

func _update_highlight(line_index: int):
	if not _highlight_rect:
		return

	# Calculate Y position based on line index
	# Account for empty lines and line numbers
	var display_line = 0
	for i in range(line_index):
		if not script_lines[i].get("text", "").is_empty():
			display_line += 1
		else:
			display_line += 1  # Empty lines still take space

	var y_pos = 8 + display_line * line_height  # Slight offset adjustment

	_highlight_rect.visible = true

	# Strong highlight animation - flash bright then stay visible
	var tween = create_tween()

	# Move to position
	tween.tween_property(_highlight_rect, "position:y", y_pos, highlight_transition_time)

	# Flash bright white then settle to yellow
	tween.parallel().tween_property(_highlight_rect, "color", Color(1.0, 1.0, 0.8, 1.0), 0.05)
	tween.tween_property(_highlight_rect, "color", highlight_color, 0.2)

	# Keep it bright - no fade to low alpha
	tween.parallel().tween_property(_highlight_rect, "modulate:a", 1.0, 0.05)

	# Slight scale pulse for emphasis
	tween.parallel().tween_property(_highlight_rect, "scale:y", 1.2, 0.08)
	tween.tween_property(_highlight_rect, "scale:y", 1.0, 0.15)

# Expression evaluation - actually runs the code!
func _evaluate_expression(expr_text: String) -> Variant:
	# Replace variable references with their values
	var processed = expr_text

	# Build list of variable names and values for Expression
	var var_names: PackedStringArray = PackedStringArray()
	var var_values: Array = []

	for var_name in _variables.keys():
		var_names.append(var_name)
		var_values.append(_variables[var_name])

	# Parse and execute the expression
	var error = _expression.parse(processed, var_names)
	if error != OK:
		push_warning("ScriptRunner: Expression parse error: %s" % _expression.get_error_text())
		return null

	var result = _expression.execute(var_values)
	if _expression.has_execute_failed():
		push_warning("ScriptRunner: Expression execute failed: %s" % _expression.get_error_text())
		return null

	return result

func _parse_and_execute_line(line_text: String) -> Dictionary:
	# Parse the line and execute it, returning result info
	# Returns: {"type": "assignment"|"expression"|"print"|"comment", "var_name": "", "result": value}

	var result = {"type": "none", "var_name": "", "result": null, "display": ""}

	# Skip empty lines
	if line_text.strip_edges().is_empty():
		return result

	# Skip comments
	if line_text.strip_edges().begins_with("#"):
		result["type"] = "comment"
		result["display"] = line_text.strip_edges()
		return result

	# Handle variable assignment: var x = expr OR x = expr
	var var_regex = RegEx.new()
	var_regex.compile("^\\s*(?:var\\s+)?(\\w+)\\s*=\\s*(.+)$")
	var match_result = var_regex.search(line_text)

	if match_result:
		var var_name = match_result.get_string(1)
		var expr_text = match_result.get_string(2)

		var eval_result = _evaluate_expression(expr_text)
		if eval_result != null:
			_variables[var_name] = eval_result
			result["type"] = "assignment"
			result["var_name"] = var_name
			result["result"] = eval_result
			result["display"] = "%s = %s" % [var_name, _format_result(eval_result)]
		return result

	# Handle print statements: print(expr)
	var print_regex = RegEx.new()
	print_regex.compile("^\\s*print\\s*\\(\\s*(.+?)\\s*\\)\\s*$")
	var print_match = print_regex.search(line_text)

	if print_match:
		var expr_text = print_match.get_string(1)
		var eval_result = _evaluate_expression(expr_text)
		result["type"] = "print"
		result["result"] = eval_result
		result["display"] = ">>> %s" % _format_result(eval_result)
		return result

	# Handle property access: point.x, point.y, etc.
	var prop_regex = RegEx.new()
	prop_regex.compile("^\\s*(\\w+)\\.(\\w+)\\s*$")
	var prop_match = prop_regex.search(line_text)

	if prop_match:
		var var_name = prop_match.get_string(1)
		var prop_name = prop_match.get_string(2)
		if _variables.has(var_name):
			var obj = _variables[var_name]
			if obj.has_method("get") or prop_name in ["x", "y", "z", "r", "g", "b", "a"]:
				var eval_result = _evaluate_expression(line_text)
				result["type"] = "expression"
				result["result"] = eval_result
				result["display"] = "%s.%s = %s" % [var_name, prop_name, _format_result(eval_result)]
		return result

	# Try as general expression
	var eval_result = _evaluate_expression(line_text)
	if eval_result != null:
		result["type"] = "expression"
		result["result"] = eval_result
		result["display"] = "= %s" % _format_result(eval_result)

	return result

func _format_result(value: Variant) -> String:
	if value == null:
		return "null"
	elif value is Vector3:
		return "Vector3(%.2f, %.2f, %.2f)" % [value.x, value.y, value.z]
	elif value is Vector2:
		return "Vector2(%.2f, %.2f)" % [value.x, value.y]
	elif value is Color:
		return "Color(%.2f, %.2f, %.2f, %.2f)" % [value.r, value.g, value.b, value.a]
	elif value is float:
		return "%.4f" % value
	elif value is bool:
		return "true" if value else "false"
	else:
		return str(value)

func _show_result(line_num: int, display_text: String, result_value: Variant):
	# Update the result display labels
	if _line_indicator:
		_line_indicator.text = "Line %d:" % (line_num + 1)
		_line_indicator.visible = true
		# Animate
		_line_indicator.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(_line_indicator, "modulate:a", 1.0, 0.15)

	if _result_label and not display_text.is_empty():
		_result_label.text = display_text
		_result_label.visible = true
		# Animate
		_result_label.modulate.a = 0
		var tween = create_tween()
		tween.tween_property(_result_label, "modulate:a", 1.0, 0.15)

	# If result is a Vector3, visualize it as a point
	if result_value is Vector3:
		_visualize_vector3(result_value)

func _visualize_vector3(pos: Vector3):
	# Create or update a visual marker at the Vector3 position
	var marker_name = "ResultMarker"
	var existing = get_parent().get_node_or_null(marker_name)

	if not existing:
		# Create new marker sphere
		existing = MeshInstance3D.new()
		existing.name = marker_name
		var mesh = SphereMesh.new()
		mesh.radius = 0.06
		mesh.height = 0.12
		existing.mesh = mesh

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 1.0, 0.5, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.8, 0.3, 1.0)
		mat.emission_energy_multiplier = 1.5
		existing.material_override = mat

		get_parent().add_child(existing)
		_spawned_objects.append(existing)

		# Spawn animation
		existing.scale = Vector3.ZERO
		var tween = create_tween()
		tween.tween_property(existing, "scale", Vector3.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Move to position
	var target = global_position + pos
	var tween = create_tween()
	tween.tween_property(existing, "global_position", target, 0.3).set_ease(Tween.EASE_IN_OUT)

func _execute_action(action: String, params: Dictionary):
	match action:
		"none":
			pass
		"eval":
			# New action: evaluate the code text and show result
			var code = params.get("code", "")
			if not code.is_empty():
				var result = _parse_and_execute_line(code)
				_show_result(_current_line, result["display"], result["result"])
		"spawn_point":
			_action_spawn_point(params)
		"move_point":
			_action_move_point(params)
		"shrink_point":
			_action_shrink_point(params)
		"show_label":
			_action_show_label(params)
		"clear_all":
			_action_clear_all()
			_variables.clear()  # Also clear variables on reset
		"init_grid":
			_action_init_grid(params)
		"set_cell":
			_action_set_cell(params)
		"set_diagonal":
			_action_set_diagonal(params)
		"highlight_row":
			_action_highlight_row(params)
		"highlight_col":
			_action_highlight_col(params)
		"clear_grid":
			_action_clear_grid()
		_:
			# Try to call method on target node
			if _target_node and _target_node.has_method(action):
				_target_node.callv(action, params.values())

func _action_spawn_point(params: Dictionary):
	var pos = params.get("pos", Vector3.ZERO)
	var color = params.get("color", Color(0.3, 0.8, 1.0, 1.0))

	# Create glowing sphere
	var sphere = MeshInstance3D.new()
	sphere.name = "ScriptPoint"

	var mesh = SphereMesh.new()
	mesh.radius = 0.08
	mesh.height = 0.16
	sphere.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	sphere.material_override = mat

	sphere.position = to_local(global_position + pos)
	get_parent().add_child(sphere)
	_spawned_objects.append(sphere)

	# Spawn animation
	sphere.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(sphere, "scale", Vector3.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _action_move_point(params: Dictionary):
	var pos = params.get("pos", Vector3.ZERO)

	for obj in _spawned_objects:
		if obj.name == "ScriptPoint":
			var target_pos = to_local(global_position + pos)
			var tween = create_tween()
			tween.tween_property(obj, "position", target_pos, 1.0).set_ease(Tween.EASE_IN_OUT)

func _action_shrink_point(params: Dictionary):
	var target_scale = params.get("scale", 0.5)

	for obj in _spawned_objects:
		if obj.name == "ScriptPoint":
			var tween = create_tween()
			tween.tween_property(obj, "scale", Vector3.ONE * target_scale, 0.5)

func _action_show_label(params: Dictionary):
	var text = params.get("text", "")
	var offset = params.get("offset", Vector3.ZERO)

	var label = Label3D.new()
	label.name = "ScriptLabel"
	label.text = text
	label.font_size = 32
	label.pixel_size = 0.002
	label.modulate = Color(1, 1, 0.8, 1)

	# Position relative to first spawned point
	if _spawned_objects.size() > 0:
		label.position = _spawned_objects[0].position + offset
	else:
		label.position = offset

	get_parent().add_child(label)
	_spawned_objects.append(label)

	# Fade in
	label.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)

func _action_clear_all():
	for obj in _spawned_objects:
		if is_instance_valid(obj):
			var tween = create_tween()
			tween.tween_property(obj, "modulate:a", 0.0, 0.5)
			tween.tween_callback(obj.queue_free)
	_spawned_objects.clear()
	# Also clear the grid
	_action_clear_grid()

# ============ GRID VISUALIZATION ACTIONS ============

func _action_init_grid(params: Dictionary):
	# Create a visual grid of cells
	var size = params.get("size", 4)
	_grid_size = size

	# Clean up existing grid
	if _grid_node:
		_grid_node.queue_free()
	_grid_cells.clear()
	_grid_labels.clear()

	# Create grid container
	_grid_node = Node3D.new()
	_grid_node.name = "VisualGrid"
	# Position grid to the right of the panel
	_grid_node.position = Vector3(panel_width / 2 + 0.25, 0, 0)
	add_child(_grid_node)

	# Calculate total grid size for centering
	var total_size = size * (CELL_SIZE + CELL_GAP) - CELL_GAP
	var offset = total_size / 2.0

	# Create cells
	for row in range(size):
		var row_cells = []
		var row_labels = []
		for col in range(size):
			# Create cell mesh
			var cell = MeshInstance3D.new()
			cell.name = "Cell_%d_%d" % [row, col]

			var box = BoxMesh.new()
			box.size = Vector3(CELL_SIZE, CELL_SIZE, CELL_SIZE * 0.3)
			cell.mesh = box

			var mat = StandardMaterial3D.new()
			mat.albedo_color = GRID_COLORS["off"]
			mat.emission_enabled = true
			mat.emission = GRID_COLORS["off"] * 0.3
			mat.emission_energy_multiplier = 0.5
			cell.material_override = mat

			# Position: row is Y (top to bottom), col is X (left to right)
			cell.position = Vector3(
				col * (CELL_SIZE + CELL_GAP) - offset + CELL_SIZE / 2,
				-row * (CELL_SIZE + CELL_GAP) + offset - CELL_SIZE / 2,
				0
			)

			_grid_node.add_child(cell)
			row_cells.append(cell)

			# Create index label
			var label = Label3D.new()
			label.name = "Label_%d_%d" % [row, col]
			label.text = "[%d,%d]" % [row, col]
			label.font_size = 24
			label.pixel_size = 0.001
			label.modulate = Color(0.5, 0.5, 0.5, 0.7)
			label.position = cell.position + Vector3(0, 0, CELL_SIZE * 0.2)
			label.visible = false  # Hidden by default
			_grid_node.add_child(label)
			row_labels.append(label)

		_grid_cells.append(row_cells)
		_grid_labels.append(row_labels)

	# Add row/column headers
	_add_grid_headers(size, offset)

	# Spawn animation
	_grid_node.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(_grid_node, "scale", Vector3.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Show result
	_show_result(_current_line, "grid[%d][%d] created" % [size, size], null)

func _add_grid_headers(size: int, offset: float):
	# Add column headers (0, 1, 2, 3...)
	for col in range(size):
		var header = Label3D.new()
		header.name = "ColHeader_%d" % col
		header.text = str(col)
		header.font_size = 32
		header.pixel_size = 0.0012
		header.modulate = Color(0.8, 0.8, 0.3, 1.0)
		header.position = Vector3(
			col * (CELL_SIZE + CELL_GAP) - offset + CELL_SIZE / 2,
			offset + CELL_SIZE * 0.3,
			0
		)
		_grid_node.add_child(header)

	# Add row headers
	for row in range(size):
		var header = Label3D.new()
		header.name = "RowHeader_%d" % row
		header.text = str(row)
		header.font_size = 32
		header.pixel_size = 0.0012
		header.modulate = Color(0.8, 0.8, 0.3, 1.0)
		header.position = Vector3(
			-offset - CELL_SIZE * 0.4,
			-row * (CELL_SIZE + CELL_GAP) + offset - CELL_SIZE / 2,
			0
		)
		_grid_node.add_child(header)

func _action_set_cell(params: Dictionary):
	var row = params.get("row", params.get("x", 0))
	var col = params.get("col", params.get("y", 0))
	var color_name = params.get("color", "white")

	# Auto-init grid if not created
	if _grid_cells.is_empty():
		_action_init_grid({"size": 4})
		await get_tree().create_timer(0.1).timeout

	if row < 0 or row >= _grid_cells.size():
		return
	if col < 0 or col >= _grid_cells[row].size():
		return

	var cell = _grid_cells[row][col]
	var color = GRID_COLORS.get(color_name, Color.WHITE)

	if cell and cell.material_override:
		# Animate color change
		var mat = cell.material_override
		var tween = create_tween()
		tween.tween_property(mat, "albedo_color", color, 0.2)
		tween.parallel().tween_property(mat, "emission", color * 0.8, 0.2)
		tween.parallel().tween_property(mat, "emission_energy_multiplier", 1.5, 0.1)
		tween.tween_property(mat, "emission_energy_multiplier", 0.8, 0.3)

		# Pulse animation
		var original_scale = cell.scale
		var pulse_tween = create_tween()
		pulse_tween.tween_property(cell, "scale", original_scale * 1.3, 0.1)
		pulse_tween.tween_property(cell, "scale", original_scale, 0.2)

	# Show index label briefly
	if row < _grid_labels.size() and col < _grid_labels[row].size():
		var label = _grid_labels[row][col]
		label.visible = true
		label.modulate.a = 1.0
		var label_tween = create_tween()
		label_tween.tween_interval(1.0)
		label_tween.tween_property(label, "modulate:a", 0.0, 0.5)
		label_tween.tween_callback(func(): label.visible = false)

	# Show result
	_show_result(_current_line, "grid[%d][%d] = %s" % [row, col, color_name.to_upper()], null)

func _action_set_diagonal(params: Dictionary):
	var color_name = params.get("color", "white")
	var color = GRID_COLORS.get(color_name, Color.WHITE)

	if _grid_cells.is_empty():
		_action_init_grid({"size": 4})
		await get_tree().create_timer(0.1).timeout

	# Set diagonal cells with staggered animation
	for i in range(min(_grid_cells.size(), _grid_cells[0].size() if _grid_cells.size() > 0 else 0)):
		# Delay each cell
		var delay_tween = create_tween()
		delay_tween.tween_interval(i * 0.15)
		delay_tween.tween_callback(func():
			_action_set_cell({"row": i, "col": i, "color": color_name})
		)

	_show_result(_current_line, "diagonal = %s" % color_name.to_upper(), null)

func _action_highlight_row(params: Dictionary):
	var row = params.get("row", 0)
	var color_name = params.get("color", "yellow")

	if row < 0 or row >= _grid_cells.size():
		return

	for col in range(_grid_cells[row].size()):
		_action_set_cell({"row": row, "col": col, "color": color_name})

	_show_result(_current_line, "row %d highlighted" % row, null)

func _action_highlight_col(params: Dictionary):
	var col = params.get("col", 0)
	var color_name = params.get("color", "cyan")

	for row in range(_grid_cells.size()):
		if col < _grid_cells[row].size():
			_action_set_cell({"row": row, "col": col, "color": color_name})

	_show_result(_current_line, "column %d highlighted" % col, null)

func _action_clear_grid():
	if _grid_node:
		var tween = create_tween()
		tween.tween_property(_grid_node, "scale", Vector3.ZERO, 0.3)
		tween.tween_callback(_grid_node.queue_free)
		_grid_node = null
	_grid_cells.clear()
	_grid_labels.clear()

func _reset_script():
	_action_clear_all()
	_variables.clear()
	_current_line = -1
	_highlight_rect.visible = false
	# Hide result display
	if _line_indicator:
		_line_indicator.visible = false
	if _result_label:
		_result_label.visible = false

# Public API
func play():
	if _is_running:
		return
	_is_running = true
	_waiting_for_start = false
	_current_line = -1
	_line_timer = 0.0
	_current_duration = start_delay
	script_started.emit()

	# Update button visual
	if _play_button:
		var icon: Label3D = _play_button.get_node_or_null("PlayIcon") as Label3D
		if icon:
			icon.text = PLAY_ICON_RUNNING
		# Change button color to indicate running
		var mesh: MeshInstance3D = _play_button.get_node_or_null("ButtonMesh") as MeshInstance3D
		if mesh and mesh.material_override:
			var mesh_material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
			if mesh_material:
				mesh_material.albedo_color = Color(0.6, 0.3, 0.2, 1.0)
				mesh_material.emission = Color(0.4, 0.2, 0.1, 1.0)

func stop():
	_is_running = false
	if _play_button:
		var icon: Label3D = _play_button.get_node_or_null("PlayIcon") as Label3D
		if icon:
			icon.text = PLAY_ICON_IDLE
		# Restore button color
		var mesh: MeshInstance3D = _play_button.get_node_or_null("ButtonMesh") as MeshInstance3D
		if mesh and mesh.material_override:
			var mesh_material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
			if mesh_material:
				mesh_material.albedo_color = Color(0.2, 0.6, 0.3, 1.0)
				mesh_material.emission = Color(0.1, 0.4, 0.2, 1.0)
	script_stopped.emit()

func toggle():
	if _is_running:
		stop()
	else:
		play()

func set_target(node: Node3D):
	_target_node = node

func load_script(lines: Array[Dictionary]):
	script_lines = lines
	_update_code_display()
	_reset_script()

func _try_toggle_from_interaction() -> bool:
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	if now - _last_button_press_time < button_press_cooldown:
		return false
	_last_button_press_time = now
	toggle()
	_animate_button_press()
	return true

# Input handling
func _on_play_button_input(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		_try_toggle_from_interaction()

func _on_play_button_touched(area: Area3D):
	# Handle VR finger/hand touch
	var area_name = area.name.to_lower()
	if "finger" in area_name or "hand" in area_name or "pointer" in area_name:
		if _try_toggle_from_interaction():
			print("ScriptRunner: Button touched by %s" % area.name)

func _on_play_button_body_touched(body: Node3D):
	# Handle physics body collision (grabbing hand, thrown objects, etc.)
	var body_name = body.name.to_lower()
	if "hand" in body_name or "finger" in body_name or "controller" in body_name:
		if _try_toggle_from_interaction():
			print("ScriptRunner: Button touched by body %s" % body.name)

func _on_play_button_hover():
	# Brighten button on hover
	var mesh: MeshInstance3D = _play_button.get_node_or_null("ButtonMesh") as MeshInstance3D
	if mesh and mesh.material_override:
		var mesh_material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
		if mesh_material:
			mesh_material.emission_energy_multiplier = 1.0

func _animate_button_press():
	# Visual feedback for button press
	if not _play_button:
		return
	var mesh = _play_button.get_node_or_null("ButtonMesh")
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "position:z", -0.01, 0.05)
		tween.tween_property(mesh, "position:z", 0.0, 0.1)

func _input(event):
	# Keyboard controls for testing
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			toggle()
		elif event.keycode == KEY_R:
			_reset_script()
			play()

