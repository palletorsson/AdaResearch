extends Logger
## THE SYSTEM CONSOLE'S EAR (2026-09-14). Palle, removing the development prints: "If we
## preserve any print statement it would be good to update the system in-game terminal."
##
## Rather than rewrite every kept print into a console call, the console listens to the
## engine log itself. Godot 4.5+ hands every print, printerr, push_warning, push_error and
## script error to each registered Logger, from whatever thread produced it. So a kept
## print reaches three places unchanged: stdout, godot.log (tools parse both, byte for
## byte), and GameManager's console ring buffer, which the desktop overlay (F12) and the
## VR console (commons/monitor/VRconsole.tscn) draw.
##
## Measured on 4.6 before this was written (a SceneTree probe with OS.add_logger): print,
## print_rich, printerr, push_warning (error_type 1), push_error (error_type 0) and a print
## from a Thread all arrive; nothing arrives after OS.remove_logger.
##
## Rules a Logger lives by: it may be called from any thread, so it only appends under a
## Mutex and schedules ONE deferred drain on the main thread; and it must never print, or
## it hears itself. GameManager mutes it while draining for the same reason.

var sink: Callable            ## main-thread drain, called deferred (GameManager._drain_console_log)
var muted: bool = false       ## set by the sink while it runs, so its own echo is not heard

const MAX_PENDING := 500

var _mutex := Mutex.new()
var _pending: Array[Dictionary] = []
var _scheduled := false


func _log_message(message: String, error: bool) -> void:
	if muted:
		return
	var text := message.strip_edges(false, true)
	if text.is_empty():
		return
	_push(text, "error" if error else _type_of(text), _source_of(text))


func _log_error(function: String, file: String, line: int, code: String, rationale: String,
		editor_notify: bool, error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
	if muted:
		return
	var text := rationale if rationale != "" else code
	var where := "%s:%d" % [file.get_file(), line]
	# push_error / push_warning report from variant_utility.cpp; the script frame is the useful place
	for bt in script_backtraces:
		if bt != null and bt.get_frame_count() > 0:
			where = "%s:%d" % [bt.get_frame_file(0).get_file(), bt.get_frame_line(0)]
			break
	var type := "warning" if error_type == ERROR_TYPE_WARNING else "error"
	_push("%s  (%s)" % [text, where], type, _source_of(text))


func drain() -> Array[Dictionary]:
	_mutex.lock()
	var out := _pending
	_pending = []
	_scheduled = false
	_mutex.unlock()
	return out


func _push(text: String, type: String, source: String) -> void:
	_mutex.lock()
	_pending.append({"text": text, "type": type, "source": source})
	if _pending.size() > MAX_PENDING:
		_pending.pop_front()
	var schedule := not _scheduled
	_scheduled = true
	_mutex.unlock()
	if schedule and sink.is_valid():
		sink.call_deferred()


static func _type_of(text: String) -> String:
	var t := text.to_lower()
	if text.contains("❌") or t.contains("error") or t.contains("failed"):
		return "error"
	if text.contains("⚠") or t.contains("warning") or t.contains("refused") or t.contains("not found"):
		return "warning"
	return "info"


static func _source_of(text: String) -> String:
	# "[em-gate] ..." -> em-gate ; "GridSystem: ..." -> GridSystem ; otherwise log
	if text.begins_with("["):
		var close := text.find("]")
		if close > 1 and close < 32:
			return text.substr(1, close - 1)
	var colon := text.find(":")
	if colon > 0 and colon < 32 and not text.substr(0, colon).contains(" "):
		return text.substr(0, colon)
	return "log"
