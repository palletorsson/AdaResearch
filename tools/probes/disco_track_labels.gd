extends SceneTree
## Real sequencer UI/model switching and same-viewport captures, without headset claims.

const OUT := "res://doc/book/iterations/2026-09-19-arrays-review/disco/"
const SYNTH := preload("res://commons/audio/generators/AudioSynthesizer.gd")
var checks: Array = []
var label := "after"
var capture := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--label="):
			label = arg.trim_prefix("--label=")
		elif arg == "--capture":
			capture = true
	call_deferred("run")

func record(tag: String, ok: bool, detail: Dictionary = {}) -> void:
	detail["tag"] = tag
	detail["passed"] = ok
	checks.append(detail)

func labels(ui: Control) -> Array:
	var result: Array = []
	for child in ui.get_node("Background/MainVBox/GridHBox").get_child(0).get_children():
		result.append(child.text)
	return result

func expected(seq: Node) -> Array:
	var result: Array = []
	var sounds: Array = seq.get("_track_sounds")
	for track in range(int(seq.get("num_tracks"))):
		var name_text := SYNTH.get_sound_type_name(sounds[track])
		result.append("Track %d" % (track + 1) if name_text == "Unknown Sound" else name_text)
	return result

func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var seq: Node3D = load("res://commons/audio/sequencer/step_sequencer.tscn").instantiate()
	# This is Tutorial_Disco's authored sound configuration, before tree entry.
	seq.call("apply_grid_config", {"sound_preset": "90s_house"})
	world.add_child(seq)
	seq.set_process(false)
	var ui: Control = seq.get("_sequencer_ui")
	await process_frame
	await process_frame
	record("placed_house_instruments", labels(ui) == ["TR-909 Kick", "Korg M1 Piano", "Acid 606 Hi-Hat", "TB-303 Acid Bass"], {"actual": labels(ui)})
	ui.call("set_cell", 1, 5, true)
	# Turning on a cell deliberately auditions it. Clear that setup preview
	# before checking that later preset changes do not introduce another sound.
	for player in seq.get("_audio_players"):
		player.stop()
		player.stream = null
	var buttons: Array = ui.get("_buttons")
	var address: Button = buttons[1][5]
	var address_id := address.get_instance_id()
	var feedback: Array = []
	ui.connect("preset_changed", func(value: String): feedback.append(value))
	if capture:
		var viewport: SubViewport = seq.get_node("Viewport2Din3D/Viewport")
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		await process_frame
		await RenderingServer.frame_post_draw
		var png := OUT + label + "-house-panel.png"
		var error := viewport.get_texture().get_image().save_png(png)
		record("actual_ui_capture", error == OK, {"path": png, "size": [viewport.size.x, viewport.size.y], "scope": "Direct capture of the actual packed scene's 800 x 300 screen, identical preset and cell; no museum or headset view."})
	var presets: Array = seq.get("SOUND_PRESETS").keys()
	var configurations: Array = []
	var all_ok := true
	for preset in presets:
		seq.call("apply_grid_config", {"sound_preset": preset})
		var wanted := expected(seq)
		var actual := labels(ui)
		all_ok = all_ok and actual == wanted
		configurations.append({"preset": preset, "actual": actual, "expected": wanted})
	record("all_17_model_presets_match_resolved_sounds", all_ok and presets.size() == 17, {"presets": configurations})
	record("model_refresh_emits_no_selection_feedback", feedback.is_empty(), {"events": feedback.duplicate()})
	var selector: OptionButton = ui.get("_preset_button")
	var names: Array = ui.get("SOUND_PRESETS")
	var house_index := names.find("90s_house")
	selector.select(house_index)
	selector.item_selected.emit(house_index)
	record("visitor_selector_updates_model_and_track_names", seq.get("sound_preset") == "90s_house" and labels(ui) == ["TR-909 Kick", "Korg M1 Piano", "Acid 606 Hi-Hat", "TB-303 Acid Bass"] and feedback == ["90s_house"], {"actual": labels(ui), "events": feedback.duplicate()})
	seq.call("apply_grid_config", {"sound_preset": "unknown_preset"})
	record("unknown_preset_labels_actual_fallback_kit", labels(ui) == ["Dark 808 Kick", "TR-909 Kick", "Acid 606 Hi-Hat", "Dark 808 Sub Bass"], {"actual": labels(ui)})
	seq.call("apply_grid_config", {"sound_preset": "disco"})
	record("uncatalogued_sound_uses_neutral_track_number", labels(ui)[3] == "Track 4", {"actual": labels(ui), "sound": "POP_FUNK_BASS exists in SoundType but lacks a catalog display name."})
	var silent := true
	for player in seq.get("_audio_players"):
		silent = silent and player.stream == null and not player.playing
	record("preset_switch_does_not_audition_sounds", silent)
	record("preset_switch_preserves_cell_and_address", ui.call("get_cell", 1, 5) and address.get_instance_id() == address_id and buttons.size() == 4 and buttons[1].size() == 16)
	seq.call("apply_grid_config", {"sound_preset": "90s_house"})
	seq.set("_playhead_position", 5)
	seq.call("_advance_playhead")
	var players: Array = seq.get("_audio_players")
	record("labelled_piano_still_generates_playback_stream", players[1].stream != null and seq.get("_track_sounds")[1] == SYNTH.SoundType.KORG_M1_PIANO)
	var failures: Array = checks.filter(func(item): return not item["passed"])
	FileAccess.open(OUT + label + "-checks.json", FileAccess.WRITE).store_string(JSON.stringify({"scope": "Actual packed sequencer scene, resolved instrument types, UI signals, unchanged grid and audio stream generation. Scripted, no pointer, listening or headset claim.", "passed": failures.is_empty(), "checks": checks}, "\t"))
	print("DISCO LABELS: ", checks.size(), " checks; ", failures.size(), " failures")
	world.queue_free()
	await process_frame
	await process_frame
	quit(0 if failures.is_empty() else 1)
