extends Node3D

@export var default_text_key: String = "point_axioms"
@export var seconds_per_line: float = 1.2
@export var auto_start: bool = true
@export var loop_lines: bool = false

const TUTORIAL_TEXT_PATH := "res://commons/context/clipboard/tutorial_text/"
const DEFAULT_SPEED_TEXT := "READY"

var _label: Label3D
var _lines: Array[String] = []
var _current_index: int = 0
var _timer: float = 0.0
var _current_line_duration: float = 1.0
var _is_running: bool = false
var _bbcode_regex: RegEx
var _pending_config: Dictionary = {}
var _ready_to_run: bool = false

func _ready():
	_label = get_node_or_null("MeshInstance3D/Label3D")
	_bbcode_regex = RegEx.new()
	var compile_error = _bbcode_regex.compile("\\[.*?\\]")
	if compile_error != OK:
		push_error("SpeedText: Failed to compile BBCode regex (%s)" % compile_error)
		_bbcode_regex = null

	if not default_text_key.is_empty():
		load_text_from_key(default_text_key)
	elif _label:
		_label.text = DEFAULT_SPEED_TEXT
	_current_line_duration = max(0.05, seconds_per_line)

	_ready_to_run = true
	if not _pending_config.is_empty():
		_apply_pending_config()
	elif auto_start:
		start()
	_update_line_duration()

func _process(delta: float) -> void:
	if not _is_running or _lines.is_empty():
		return

	_timer += delta
	if _timer < max(_current_line_duration, 0.01):
		return

	_timer = 0.0
	_current_index += 1
	if _current_index >= _lines.size():
		if loop_lines:
			_current_index = 0
		else:
			_is_running = false
			return

	_display_current_line()

func configure_speed_reader(key: String, custom_seconds: float = -1.0, should_loop: bool = false) -> void:
	var sanitized_key = key.strip_edges().to_lower()
	if sanitized_key.is_empty():
		sanitized_key = default_text_key
	if sanitized_key.is_empty():
		sanitized_key = "point_axioms"

	var seconds = seconds_per_line
	if custom_seconds > 0.0:
		seconds = custom_seconds

	default_text_key = sanitized_key
	seconds_per_line = max(0.01, seconds)
	loop_lines = should_loop

	if _ready_to_run:
		_apply_configuration(default_text_key, seconds_per_line, loop_lines)
	else:
		_pending_config = {
			"key": default_text_key,
			"seconds": seconds_per_line,
			"loop": loop_lines
		}

func load_text_from_key(key: String) -> bool:
	var sanitized = key.strip_edges().to_lower()
	if sanitized.is_empty():
		return false

	var full_path = "%s%s.gd" % [TUTORIAL_TEXT_PATH, sanitized]
	if not ResourceLoader.exists(full_path):
		push_warning("SpeedText: Tutorial text '%s' not found" % sanitized)
		return false

	var text_content = _extract_text_from_script(full_path)
	if text_content.is_empty():
		push_warning("SpeedText: Tutorial '%s' contains no text" % sanitized)
		return false

	_lines = _create_plain_lines(text_content)
	_current_index = 0
	if _ready_to_run:
		_display_current_line()
	return not _lines.is_empty()

func start():
	if _lines.is_empty():
		return
	_is_running = true
	_timer = 0.0
	_current_index = 0
	if _ready_to_run:
		_display_current_line()

func stop():
	_is_running = false

func _display_current_line():
	if _label and _current_index < _lines.size():
		_label.text = _lines[_current_index]
	elif _label:
		_label.text = DEFAULT_SPEED_TEXT
	else:
		print("SpeedText: Missing Label3D or out of bounds index")
	_update_line_duration()

func _update_line_duration():
	var base_duration = seconds_per_line
	if base_duration <= 0.0:
		base_duration = 1.0
	if _lines.is_empty() or _current_index >= _lines.size():
		_current_line_duration = max(0.05, base_duration)
		return
	var length = max(_lines[_current_index].length(), 1)
	_current_line_duration = max(0.05, base_duration * float(length))

func _extract_text_from_script(path: String) -> String:
	var script_resource = ResourceLoader.load(path)
	if script_resource and script_resource is Script:
		var temp = script_resource.new()
		var result := ""
		if "text" in temp:
			result = str(temp.text)
		if temp is Node:
			temp.free()
		if not result.is_empty():
			return result

	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		return file.get_as_text()
	return ""

func _create_plain_lines(raw_text: String) -> Array[String]:
	var cleaned_lines: Array[String] = []
	if raw_text.is_empty():
		return cleaned_lines

	var segments = raw_text.split("\n")
	for segment in segments:
		var stripped = segment
		if _bbcode_regex:
			stripped = _bbcode_regex.sub(stripped, "", true)
		stripped = stripped.replacen("\t", " ")
		stripped = stripped.strip_edges()
		if stripped.is_empty():
			continue
		cleaned_lines.append(stripped)
	return cleaned_lines

func _apply_configuration(key: String, seconds: float, loop_flag: bool) -> void:
	var final_key = key.strip_edges().to_lower()
	if final_key.is_empty():
		final_key = default_text_key
	if final_key.is_empty():
		final_key = "point_axioms"

	default_text_key = final_key
	seconds_per_line = seconds
	loop_lines = loop_flag

	if load_text_from_key(final_key):
		start()
	else:
		print("SpeedText: Unable to load tutorial key '%s'" % final_key)

func _apply_pending_config():
	if _pending_config.is_empty():
		return
	var key = _pending_config.get("key", default_text_key)
	var secs = float(_pending_config.get("seconds", seconds_per_line))
	var loop_flag = bool(_pending_config.get("loop", loop_lines))
	_pending_config.clear()
	_apply_configuration(key, secs, loop_flag)
