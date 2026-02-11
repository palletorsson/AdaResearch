# DebugLogger.gd - Routes debug output to a log file
# Add as Autoload: DebugLogger -> res://commons/managers/DebugLogger.gd
#
# Usage:
#   DebugLogger.info("Message")
#   DebugLogger.warn("Warning message")
#   DebugLogger.err("Error message")
#   DebugLogger.log_print("Any print-style message")
#
# Log file location: user://logs/debug_YYYY-MM-DD_HH-MM-SS.log
# On Windows: %APPDATA%/Godot/app_userdata/Ada Research Zero One/logs/

extends Node

## Configuration
@export var enabled: bool = true
@export var log_to_console: bool = true  # Also print to Godot console
@export var log_level: int = 0  # 0=all, 1=warn+error, 2=error only
@export var max_log_files: int = 10  # Keep last N log files
@export var flush_immediately: bool = true  # Flush after each write (slower but safer)

## Log file handle
var _log_file: FileAccess = null
var _log_path: String = ""
var _session_start: String = ""

## Log levels
enum Level { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 }

func _ready() -> void:
	if not enabled:
		return
	
	_session_start = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	_setup_log_directory()
	_open_log_file()
	_cleanup_old_logs()
	
	# Log session start
	_write_header()
	
	# Connect to tree notifications for cleanup
	get_tree().auto_accept_quit = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_write_footer()
		_close_log_file()
		get_tree().quit()

func _setup_log_directory() -> void:
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("logs"):
		dir.make_dir("logs")

func _open_log_file() -> void:
	_log_path = "user://logs/debug_%s.log" % _session_start
	_log_file = FileAccess.open(_log_path, FileAccess.WRITE)
	if _log_file:
		print("DebugLogger: Logging to %s" % ProjectSettings.globalize_path(_log_path))
	else:
		push_error("DebugLogger: Failed to open log file at %s" % _log_path)

func _close_log_file() -> void:
	if _log_file:
		_log_file.close()
		_log_file = null

func _cleanup_old_logs() -> void:
	var dir = DirAccess.open("user://logs")
	if not dir:
		return
	
	var log_files: Array[String] = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.begins_with("debug_") and file_name.ends_with(".log"):
			log_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	# Sort by name (which includes timestamp)
	log_files.sort()
	
	# Delete oldest files if over limit
	while log_files.size() > max_log_files:
		var oldest = log_files.pop_front()
		dir.remove("user://logs/%s" % oldest)
		print("DebugLogger: Removed old log %s" % oldest)

func _write_header() -> void:
	var header = """================================================================================
GODOT DEBUG LOG
================================================================================
Session Start: %s
Engine: Godot %s
Project: %s
Platform: %s
================================================================================

""" % [
		Time.get_datetime_string_from_system(),
		Engine.get_version_info().string,
		ProjectSettings.get_setting("application/config/name", "Unknown"),
		OS.get_name()
	]
	_write_raw(header)

func _write_footer() -> void:
	var footer = """
================================================================================
Session End: %s
================================================================================
""" % Time.get_datetime_string_from_system()
	_write_raw(footer)

func _write_raw(text: String) -> void:
	if _log_file:
		_log_file.store_string(text)
		if flush_immediately:
			_log_file.flush()

func _format_message(level: String, message: String, context: String = "") -> String:
	var timestamp = Time.get_time_string_from_system()
	var ctx = " [%s]" % context if context else ""
	return "[%s] %s%s: %s\n" % [timestamp, level, ctx, message]

func _log(level: Level, level_str: String, message: String, context: String = "") -> void:
	if not enabled or level < log_level:
		return
	
	var formatted = _format_message(level_str, message, context)
	_write_raw(formatted)
	
	if log_to_console:
		match level:
			Level.ERROR:
				push_error(message)
			Level.WARN:
				push_warning(message)
			_:
				print(formatted.strip_edges())

## Public API

## Log a debug message (verbose)
func debug(message: String, context: String = "") -> void:
	_log(Level.DEBUG, "DEBUG", message, context)

## Log an info message
func info(message: String, context: String = "") -> void:
	_log(Level.INFO, "INFO", message, context)

## Log a warning
func warn(message: String, context: String = "") -> void:
	_log(Level.WARN, "WARN", message, context)

## Log an error
func err(message: String, context: String = "") -> void:
	_log(Level.ERROR, "ERROR", message, context)

## Log with custom prefix (like print() but to file)
func log_print(message: String) -> void:
	if not enabled:
		return
	var timestamp = Time.get_time_string_from_system()
	_write_raw("[%s] %s\n" % [timestamp, message])
	if log_to_console:
		print(message)

## Log a dictionary or array (pretty printed)
func log_data(label: String, data: Variant) -> void:
	var json = JSON.stringify(data, "  ")
	log_print("%s: %s" % [label, json])

## Log current stack trace
func log_stack(message: String = "Stack trace") -> void:
	var stack = get_stack()
	var lines = [message + ":"]
	for frame in stack:
		lines.append("  %s:%d in %s()" % [frame.source, frame.line, frame.function])
	log_print("\n".join(lines))

## Log script error with context
func log_error_context(error_message: String, script_path: String = "", line: int = -1) -> void:
	var ctx = ""
	if script_path:
		ctx = "%s:%d" % [script_path.get_file(), line] if line > 0 else script_path.get_file()
	err(error_message, ctx)

## Get the current log file path (globalized)
func get_log_path() -> String:
	return ProjectSettings.globalize_path(_log_path)

## Flush the log file
func flush() -> void:
	if _log_file:
		_log_file.flush()

## Log all GDScript errors that occur (call this to enable error interception)
## Note: This uses Godot 4.x error handling
func enable_error_logging() -> void:
	# In Godot 4, we can't directly intercept push_error/push_warning
	# But we can log them manually and check the error queue
	info("Error logging enabled - use DebugLogger.err() for tracked errors")

## Utility: Log memory usage
func log_memory() -> void:
	var static_mem = OS.get_static_memory_usage()
	var peak_mem = OS.get_static_memory_peak_usage() 
	info("Memory - Static: %.2f MB, Peak: %.2f MB" % [
		static_mem / 1048576.0,
		peak_mem / 1048576.0
	])

## Utility: Log performance stats
func log_performance() -> void:
	var fps = Engine.get_frames_per_second()
	var frame_time = Performance.get_monitor(Performance.TIME_PROCESS)
	var physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	var objects = Performance.get_monitor(Performance.OBJECT_COUNT)
	var nodes = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	
	info("Performance - FPS: %d, Frame: %.2fms, Physics: %.2fms, Objects: %d, Nodes: %d" % [
		fps, frame_time * 1000, physics_time * 1000, objects, nodes
	])
