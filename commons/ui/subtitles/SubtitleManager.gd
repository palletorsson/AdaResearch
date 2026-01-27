extends Node
class_name SubtitleManager

## Global subtitle manager - add to autoloads as "Subtitles"
## Usage: Subtitles.show("Hello world", "GLaDOS")
##
## Text Verbosity Levels (player setting):
##   1 = Essential - Only critical story/instructions
##   2 = Info - Normal subtitles and map descriptions
##   3 = Verbose - All text including hints and details
##
## Uses XRCamera3D/MapInfo Label3D for VR-compatible display

## Text verbosity levels
enum TextLevel {
	ESSENTIAL = 1,  # Critical only
	INFO = 2,       # Normal (default)
	VERBOSE = 3     # Everything
}

var _subtitle_label: Label3D = null
var _enabled: bool = true
var _hide_timer: SceneTreeTimer = null

# Typewriter state
var _full_text: String = ""
var _speaker: String = ""
var _current_char_index: int = 0
var _is_typing: bool = false
var _display_duration: float = 8.0

## Current player text verbosity setting (1-3)
var text_level: int = TextLevel.INFO

func _ready():
	# Load setting from GameManager if available
	_load_settings()

func _process(delta: float):
	if _is_typing and _subtitle_label:
		_current_char_index += 5  # Characters per frame (faster typing)
		if _current_char_index >= _full_text.length():
			_current_char_index = _full_text.length()
			_is_typing = false
		_update_label_text()

func _load_settings():
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("get_setting"):
		text_level = game_manager.get_setting("text_verbosity", TextLevel.INFO)

## Save current text level to settings
func _save_settings():
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager and game_manager.has_method("set_setting"):
		game_manager.set_setting("text_verbosity", text_level)

func _find_subtitle_label() -> Label3D:
	# Look for MapInfo label under XRCamera3D
	var root = get_tree().current_scene
	if not root:
		return null

	# Try common paths
	var paths = [
		"XROrigin3D/XRCamera3D/MapInfo",
		"Player/XROrigin3D/XRCamera3D/MapInfo",
		"VRPlayer/XROrigin3D/XRCamera3D/MapInfo"
	]

	for path in paths:
		var label = root.get_node_or_null(path)
		if label and label is Label3D:
			return label

	# Deep search
	return _find_label_recursive(root)

func _find_label_recursive(node: Node) -> Label3D:
	if node.name == "MapInfo" and node is Label3D:
		return node
	for child in node.get_children():
		var result = _find_label_recursive(child)
		if result:
			return result
	return null

func _ensure_label():
	if _subtitle_label == null or not is_instance_valid(_subtitle_label):
		_subtitle_label = _find_subtitle_label()
		if _subtitle_label:
			print("SubtitleManager: Found MapInfo label at %s" % _subtitle_label.get_path())

## Set text verbosity level (1=Essential, 2=Info, 3=Verbose)
func set_text_level(level: int):
	text_level = clampi(level, TextLevel.ESSENTIAL, TextLevel.VERBOSE)
	_save_settings()
	print("Subtitles: Text level set to %s" % _level_name(text_level))

func get_text_level() -> int:
	return text_level

func _level_name(level: int) -> String:
	match level:
		TextLevel.ESSENTIAL: return "Essential"
		TextLevel.INFO: return "Info"
		TextLevel.VERBOSE: return "Verbose"
	return "Unknown"

## Check if a message at given level should be shown
func _should_show(level: int) -> bool:
	return _enabled and level <= text_level

func _update_label_text():
	if not _subtitle_label:
		return
	var visible_text = _full_text.substr(0, _current_char_index)
	var display_text: String
	if _speaker.is_empty():
		display_text = visible_text
	else:
		display_text = "%s: %s" % [_speaker, visible_text]

	_subtitle_label.text = display_text
	# Background is sized based on full text at show() time, no per-frame update needed

## Show a subtitle with optional speaker (default: INFO level)
func show(text: String, speaker: String = "", duration: float = 6.0, level: int = TextLevel.INFO):
	print("SubtitleManager.show() called - text='%s', speaker='%s', level=%d" % [text.substr(0, 50), speaker, level])
	if not _should_show(level):
		print("SubtitleManager: Skipped due to level filter (current=%d, required=%d)" % [text_level, level])
		return

	_ensure_label()
	print("SubtitleManager: _subtitle_label=%s" % (_subtitle_label != null))

	if _subtitle_label:
		# Cancel any existing hide timer
		if _hide_timer:
			_hide_timer = null

		# Setup typewriter effect
		_full_text = text
		_speaker = speaker
		_display_duration = duration
		_current_char_index = 0
		_is_typing = true

		# Show the label with background
		_subtitle_label.visible = true
		_subtitle_label.modulate = Color(1, 1, 1, 1)
		_update_label_text()

		# Notify MapInfoLabel to show background (if it has the method)
		if _subtitle_label.has_method("show_subtitle_text"):
			var display_text = "%s: %s" % [speaker, text] if not speaker.is_empty() else text
			_subtitle_label.show_subtitle_text(display_text)

		# Schedule hide after duration + typing time
		var typing_time = text.length() * 0.02  # ~50 chars/sec
		var total_time = typing_time + duration
		_hide_timer = get_tree().create_timer(total_time)
		_hide_timer.timeout.connect(_on_hide_timeout)

		print("SubtitleManager: Showing subtitle on MapInfo label")
	else:
		push_warning("SubtitleManager: Could not find MapInfo Label3D!")

func _on_hide_timeout():
	if _subtitle_label:
		# Use MapInfoLabel's hide method if available (handles background)
		if _subtitle_label.has_method("hide_subtitle"):
			_subtitle_label.hide_subtitle()
		else:
			_subtitle_label.text = ""
			_subtitle_label.visible = false
	_is_typing = false

## Show essential subtitle (always shown unless disabled)
func essential(text: String, speaker: String = "", duration: float = 6.0):
	show(text, speaker, duration, TextLevel.ESSENTIAL)

## Show info subtitle (shown at level 2+)
func info(text: String, speaker: String = "", duration: float = 6.0):
	show(text, speaker, duration, TextLevel.INFO)

## Show verbose subtitle (shown at level 3 only)
func verbose(text: String, speaker: String = "", duration: float = 6.0):
	show(text, speaker, duration, TextLevel.VERBOSE)

## Show map annotation when entering a map (INFO level by default)
func show_map_entry(map_name: String, description: String, level: int = TextLevel.INFO):
	if not _should_show(level):
		return
	if description.is_empty():
		return
	# Use the standard show with map name as speaker
	show(description, map_name.replace("_", " "), 8.0, level)

## Show a sequence of subtitles (simplified - shows one at a time)
func show_sequence(subtitles: Array, level: int = TextLevel.INFO):
	if not _should_show(level):
		return
	# For now, just show the first one
	if subtitles.size() > 0:
		var sub = subtitles[0]
		show(sub.get("text", ""), sub.get("speaker", ""), sub.get("duration", 6.0), level)

## Skip current typewriter animation
func skip():
	if _is_typing and _subtitle_label:
		_current_char_index = _full_text.length()
		_is_typing = false
		_update_label_text()

## Hide current subtitle
func hide():
	if _subtitle_label:
		# Use MapInfoLabel's hide method if available (handles background)
		if _subtitle_label.has_method("hide_subtitle"):
			_subtitle_label.hide_subtitle()
		else:
			_subtitle_label.text = ""
			_subtitle_label.visible = false
	_is_typing = false

## Clear all subtitles
func clear():
	hide()

## Enable/disable subtitle system entirely
func set_enabled(enabled: bool):
	_enabled = enabled
	if not enabled:
		clear()

func is_enabled() -> bool:
	return _enabled

## Check if currently showing
func is_showing() -> bool:
	return _subtitle_label != null and _subtitle_label.visible and _subtitle_label.text.length() > 0

## Convenience: Cycle through text levels (for settings UI)
func cycle_text_level() -> int:
	text_level = (text_level % 3) + 1
	_save_settings()
	return text_level
