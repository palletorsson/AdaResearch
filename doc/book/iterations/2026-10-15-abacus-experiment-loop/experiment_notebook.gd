extends Node
## Attach only to the reconstructed abacus. No extra museum controls.
@export var condition := "baseline-row-2"
@export_multiline var question := "What changes when the same path moves twice as fast?"
@export_multiline var prediction := "Same positions and ink after equal numbers of steps; a different pace."
@export_multiline var observation := ""
@export_multiline var next_change := ""
@export var load_path := ""
@onready var abacus = get_parent()

func _ready() -> void:
	print("Notebook: Ctrl+Shift+K save; Ctrl+Shift+L load; Ctrl+Shift+P pause/resume.")

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if not event.ctrl_pressed or not event.shift_pressed: return
	match event.keycode:
		KEY_K: save_trial()
		KEY_L: load_trial()
		KEY_P: abacus.act(1)
		_: return
	get_viewport().set_input_as_handled()

func save_trial() -> String:
	var snapshot: Dictionary = abacus.capture()
	var entry := {
		"schema":"abacus-notebook/1",
		"created_utc":Time.get_datetime_string_from_system(true),
		"engine":Engine.get_version_info().string,
		"condition":condition, "question":question, "prediction":prediction,
		"observation":observation, "next_change":next_change,
		"record":snapshot,
		# Godot's JSON number parser can round decimals; retain exact Variant bytes too.
		"record_bytes":Marshalls.raw_to_base64(var_to_bytes(snapshot))
	}
	var stamp := "%d-%d" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	var path := "user://abacus-%s.json" % stamp
	var suffix := 0
	while FileAccess.file_exists(path):
		suffix += 1
		path = "user://abacus-%s-%d.json" % [stamp,suffix]
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null:
		push_error("Recording not saved: %s" % FileAccess.get_open_error())
		return ""
	file.store_string(JSON.stringify(entry,"\t",true,true))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		push_error("Recording write failed: %s" % error)
		return ""
	load_path = path
	print("Saved: ",ProjectSettings.globalize_path(path))
	return path

func load_trial() -> bool:
	if not FileAccess.file_exists(load_path):
		push_warning("Set load_path to an existing notebook JSON file.")
		return false
	var entry = JSON.parse_string(FileAccess.get_file_as_string(load_path))
	if not entry is Dictionary or entry.get("schema") != "abacus-notebook/1":
		push_warning("This is not an abacus notebook recording.")
		return false
	if not entry.get("record_bytes") is String:
		push_warning("Recording has no packed state.")
		return false
	var snapshot = bytes_to_var(Marshalls.base64_to_raw(entry.record_bytes))
	if not snapshot is Dictionary or not abacus.restore(snapshot):
		push_warning("Load refused: release all held instruments and check the record recipe.")
		return false
	for field in ["condition","question","prediction","observation","next_change"]:
		set(field,str(entry.get(field,"")))
	print("Restored paused: ",condition,". Ctrl+Shift+P resumes; REPLAY starts again.")
	return true
