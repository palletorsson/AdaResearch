# DebugLogger.gd - Simple debug logger
# Logs to SD card on Android: /sdcard/AdaResearch/logs/
extends Node

var _log_file: FileAccess = null
var _log_path: String = ""

func _init():
	print("DebugLogger: _init()")

func _ready() -> void:
	print("DebugLogger: _ready()")
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	
	# On Android, write to external storage (sdcard) for easy access
	if OS.get_name() == "Android":
		var sdcard_path = "/sdcard/AdaResearch/logs"
		# Create directory
		DirAccess.make_dir_recursive_absolute(sdcard_path)
		_log_path = "%s/debug_%s.log" % [sdcard_path, timestamp]
		_log_file = FileAccess.open(_log_path, FileAccess.WRITE)
		
		if not _log_file:
			# Fallback to app-specific external storage
			var fallback = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) + "/AdaResearch/logs"
			DirAccess.make_dir_recursive_absolute(fallback)
			_log_path = "%s/debug_%s.log" % [fallback, timestamp]
			_log_file = FileAccess.open(_log_path, FileAccess.WRITE)
	else:
		# Desktop: use user:// as before
		var dir = DirAccess.open("user://")
		if dir and not dir.dir_exists("logs"):
			dir.make_dir("logs")
		_log_path = "user://logs/debug_%s.log" % timestamp
		_log_file = FileAccess.open(_log_path, FileAccess.WRITE)
	
	if _log_file:
		var path = ProjectSettings.globalize_path(_log_path)
		print("DebugLogger: ✅ Logging to %s" % path)
		_log_file.store_string("=== Debug Log Started: %s ===\n" % Time.get_datetime_string_from_system())
		_log_file.flush()
	else:
		push_error("DebugLogger: ❌ Failed to create log file")

func _exit_tree() -> void:
	if _log_file:
		_log_file.store_string("=== Debug Log Ended ===\n")
		_log_file.close()

func info(msg: String) -> void:
	var line = "[%s] INFO: %s\n" % [Time.get_time_string_from_system(), msg]
	if _log_file:
		_log_file.store_string(line)
		_log_file.flush()
	print(line.strip_edges())

func warn(msg: String) -> void:
	var line = "[%s] WARN: %s\n" % [Time.get_time_string_from_system(), msg]
	if _log_file:
		_log_file.store_string(line)
		_log_file.flush()
	push_warning(msg)

func err(msg: String) -> void:
	var line = "[%s] ERROR: %s\n" % [Time.get_time_string_from_system(), msg]
	if _log_file:
		_log_file.store_string(line)
		_log_file.flush()
	push_error(msg)
