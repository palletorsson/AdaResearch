# DebugLogger.gd - Simple debug logger
# Logs to SD card on Android: /sdcard/AdaResearch/logs/
extends Node

var _log_file: FileAccess = null
var _log_path: String = ""

## THE FILE IS OPENED ON FIRST USE (2026-09-14). This used to create
## user://logs/debug_<stamp>.log on every boot, and nothing calls info/warn/err, so the
## folder held 32,295 header-only files. Godot's own godot.log already records every print.
func _ready() -> void:
	pass


func _open() -> void:
	if _log_file != null or _log_path == "failed":
		return
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-").replace("T", "_")
	
	# On Android/Quest, use app-private storage (no permissions needed)
	if OS.get_name() == "Android":
		var dir = DirAccess.open("user://")
		if dir and not dir.dir_exists("logs"):
			dir.make_dir("logs")
		_log_path = "user://logs/debug_%s.log" % timestamp
		_log_file = FileAccess.open(_log_path, FileAccess.WRITE)
	else:
		# Desktop: use user:// as before
		var dir = DirAccess.open("user://")
		if dir and not dir.dir_exists("logs"):
			dir.make_dir("logs")
		_log_path = "user://logs/debug_%s.log" % timestamp
		_log_file = FileAccess.open(_log_path, FileAccess.WRITE)
	
	if _log_file:
		_log_file.store_string("=== Debug Log Started: %s ===\n" % Time.get_datetime_string_from_system())
		_log_file.flush()
	else:
		_log_path = "failed"
		push_error("DebugLogger: ❌ Failed to create log file")

func _exit_tree() -> void:
	if _log_file:
		_log_file.store_string("=== Debug Log Ended ===\n")
		_log_file.close()

func info(msg: String) -> void:
	_open()
	var line = "[%s] INFO: %s\n" % [Time.get_time_string_from_system(), msg]
	if _log_file:
		_log_file.store_string(line)
		_log_file.flush()
	print(line.strip_edges())

func warn(msg: String) -> void:
	_open()
	var line = "[%s] WARN: %s\n" % [Time.get_time_string_from_system(), msg]
	if _log_file:
		_log_file.store_string(line)
		_log_file.flush()
	push_warning(msg)

func err(msg: String) -> void:
	_open()
	var line = "[%s] ERROR: %s\n" % [Time.get_time_string_from_system(), msg]
	if _log_file:
		_log_file.store_string(line)
		_log_file.flush()
	push_error(msg)
