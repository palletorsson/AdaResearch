extends SceneTree
## Make the tower's sung phrases travel with the game. Reads commons/data/opera/tower_bindings.json (score,
## renderer, the renderer's settings), has the game's own voice node make every phrase of that score (from its
## cache where it has them; the airway voice takes most of a minute a phrase otherwise), and writes each as
## res://audio/voice_cache/<key>.wav, the name the voice node looks for first. A headset then plays them
## instead of making them. Run again after a phrase, a setting or the voice changes; old files are left (they
## are simply not asked for) unless --clean is given.
##
##   godot --headless --audio-driver Dummy --path . --xr-mode off --script res://tools/probes/ship_voice.gd [-- --clean]

const Voice := preload("res://commons/void/inner_voice_godot.gd")
const BINDINGS := "res://commons/data/opera/tower_bindings.json"
const FOLDER := "res://audio/voice_cache/"


func _initialize() -> void:
	var bindings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BINDINGS))
	var voice: Node = Voice.new()
	root.add_child(voice)
	var wrong := str(voice.call("load_score", str(bindings.score), bindings.get("voice", {}), str(bindings.get("renderer", ""))))
	if wrong != "":
		print("SHIP_VOICE cannot: ", wrong)
		quit(1)
		return
	var ids: Array = (voice.get("phrases") as Dictionary).keys()
	var began := Time.get_ticks_msec()
	while (voice.get("streams") as Dictionary).size() < ids.size() and Time.get_ticks_msec() - began < 1800000:
		await process_frame
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var wanted := {}
	var written := 0
	for id in ids:
		var stream: Variant = (voice.get("streams") as Dictionary).get(id)
		var file_name := str(voice.call("_key", id)) + ".wav"
		wanted[file_name] = true
		if stream is AudioStreamWAV and not (voice.get("costs") as Dictionary)[id].get("shipped", false):
			if (stream as AudioStreamWAV).save_to_wav(FOLDER + file_name) == OK: written += 1
		print("SHIP_VOICE ", id, " -> ", file_name, "  ", (voice.get("costs") as Dictionary).get(id))
	if OS.get_cmdline_user_args().has("--clean"):
		for existing in DirAccess.get_files_at(FOLDER):
			if existing.ends_with(".wav") and not wanted.has(existing): DirAccess.remove_absolute(FOLDER + existing)
	print("SHIP_VOICE ", written, " written of ", ids.size(), " (", str(bindings.get("renderer", "")), ", ", bindings.get("voice", {}), ")")
	quit(0)
