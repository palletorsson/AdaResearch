extends Node
## The viewfinder's numbers come from a file, and the file can be sent to a running game.
##
## res://commons/void/hud_config.json travels with the game and is read at the start. If a file of the same
## shape lies at user://hud_config.json it is laid over that, and it is looked at twice a second: when it
## changes, the viewfinder is set again at once, with nothing built and nothing restarted. On a Quest,
## user:// is the app's own files folder, which `python tools/push_hud_config.py` writes to over the cable.
##
## What was used is written to user://hud_config_applied.json (with why, when a sent file was refused: a
## file that cannot be read changes nothing), so the tool that sent it can say whether it took.
##
## The numbers themselves are read by the display (commons/void/camcorder_hud.gd, `configure`); this node
## only carries them. Sections: "vr" for the plane in a headset, "desktop" for the overlay.

const SHIPPED := "res://commons/void/hud_config.json"
const SENT := "user://hud_config.json"
const APPLIED := "user://hud_config_applied.json"
const EVERY := 0.5

var shipped := {}
var sent_text := ""
var applied := {}
var applied_count := 0
var _since := EVERY
var _display: Object


func _ready() -> void:
	name = "HudConfig"
	process_mode = Node.PROCESS_MODE_ALWAYS
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SHIPPED)) if FileAccess.file_exists(SHIPPED) else null
	if parsed is Dictionary: shipped = parsed


func _process(delta: float) -> void:
	_since += delta
	if _since < EVERY: return
	_since = 0.0
	var display: Variant = get_parent().get("charge_display") if get_parent() != null else null
	if not (display is Object and is_instance_valid(display) and (display as Object).has_method("configure")): return
	var text := FileAccess.get_file_as_string(SENT) if FileAccess.file_exists(SENT) else ""
	if display == _display and text == sent_text: return
	_display = display
	sent_text = text
	var merged := shipped.duplicate(true)
	var problem := ""
	if text != "":
		var parsed: Variant = JSON.parse_string(text)
		if parsed is Dictionary:
			for section in parsed:
				if parsed[section] is Dictionary and merged.get(section) is Dictionary: (merged[section] as Dictionary).merge(parsed[section], true)
				else: merged[section] = parsed[section]
		else:
			problem = "the sent file is not a JSON object; nothing was changed"
	if problem == "":
		applied = (display as Object).call("configure", merged)
		applied_count += 1
	var report := {"applied": problem == "", "problem": problem, "values": applied, "times_applied": applied_count, "at_unix": Time.get_unix_time_from_system(),
		"sent_file": text != ""}
	var file := FileAccess.open(APPLIED, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	print("[hud] config %s%s" % ["applied: " + JSON.stringify(applied) if problem == "" else "REFUSED: " + problem, "" if text != "" else "  (no sent file: as shipped)"])
