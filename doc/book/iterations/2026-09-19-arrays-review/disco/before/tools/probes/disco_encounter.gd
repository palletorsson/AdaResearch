extends SceneTree
## Scripted behaviour of the actual sequencer/floor scenes; no pointer or listening claim.

var failures: Array[String] = []
var events: Array = []
var observations: Array = []
var report: Dictionary = {}
var placement_config: Dictionary = {}

func _initialize() -> void:
	call_deferred("run")

func check(tag: String, passed: bool, detail: Dictionary = {}) -> void:
	detail["tag"] = tag
	detail["passed"] = passed
	observations.append(detail)
	if not passed:
		failures.append(tag)

func room(parent: Node, name_text: String, with_sequencer: bool = true) -> Dictionary:
	var hall := Node3D.new()
	hall.name = name_text
	hall.set_meta("em_map", name_text)
	parent.add_child(hall)
	var seq: Node3D = null
	if with_sequencer:
		seq = (load("res://commons/audio/sequencer/step_sequencer.tscn") as PackedScene).instantiate()
		hall.add_child(seq)
		seq.call("apply_grid_config", placement_config)
		seq.set_process(false)
	var setup: Node3D = (load("res://commons/context/discofloor/standalone_disco_floor.tscn") as PackedScene).instantiate()
	hall.add_child(setup)
	var floor_node: Node3D = setup.get_node("DiscoFloor")
	floor_node.set_process(false)
	return {"hall": hall, "seq": seq, "floor": floor_node, "bridge": floor_node.get_node("SequencerBridge")}

func run() -> void:
	var output: String = OS.get_cmdline_user_args()[0]
	var map_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/Tutorial_Disco/map_data.json"))
	for row in map_data["layers"]["interactables"]:
		for cell in row:
			if str(cell).begins_with("step_sequencer:"):
				for fragment in str(cell).split("#").slice(1):
					var pair: PackedStringArray = str(fragment).split(":", true, 1)
					if pair.size() == 2:
						placement_config[pair[0]] = pair[1]
	var world := Node3D.new()
	world.name = "ActualDiscoScenes"
	root.add_child(world)
	current_scene = world
	check_preset_sync(world)
	var first := room(world, "FirstHall")
	var second := room(world, "SecondHall")
	var empty := room(world, "HallWithoutSequencer", false)
	await process_frame
	await process_frame
	await process_frame
	check("first_hall_uses_own_sequencer", first["bridge"].get("step_sequencer") == first["seq"])
	check("second_hall_uses_own_sequencer", second["bridge"].get("step_sequencer") == second["seq"])
	check("missing_local_sequencer_does_not_borrow", empty["bridge"].get("step_sequencer") == null)
	var seq: Node3D = second["seq"]
	check("explicit_house_config_reaches_sequencer", placement_config.get("sound_preset") == "90s_house" and seq.get("sound_preset") == "90s_house", {"config": placement_config})
	var ui: Control = seq.get("_sequencer_ui") as Control
	check("actual_packed_scene_ui_is_connected", ui != null)
	if ui == null:
		finish(output)
		return
	seq.connect("step_triggered", func(track: int, step: int):
		events.append({"track": track, "step": step, "displayed_during_event": ui.get("_playhead_position")}))
	ui.call("clear_pattern")
	ui.call("set_cell", 1, 5, true)
	seq.call("play")
	seq.set("_playhead_position", 5)
	seq.call("_advance_playhead")
	var event: Dictionary = events[0] if events.size() > 0 else {}
	var displayed: int = int(ui.get("_playhead_position"))
	check("active_cell_sound_and_address_agree", events.size() == 1 and event.get("track") == 1 and event.get("step") == 5 and event.get("displayed_during_event") == 5 and displayed == 5,
		{"events": events.duplicate(true), "displayed_after_event": displayed})
	var players: Array = seq.get("_audio_players")
	check("active_track_generates_audio_stream", players.size() > 1 and players[1].stream != null,
		{"scope": "Actual AudioStreamPlayer receives generated stream; no human listening check."})
	var before_count: int = events.size()
	seq.call("_advance_playhead")
	check("inactive_column_adds_no_event", events.size() == before_count and int(ui.get("_playhead_position")) == 6,
		{"event_count_before": before_count, "event_count_after": events.size(), "displayed": ui.get("_playhead_position")})
	var buttons: Array = ui.get("_buttons")
	var address_button: Button = buttons[1][5]
	var address_id: int = address_button.get_instance_id()
	ui.call("set_cell", 1, 5, false)
	check("turning_value_off_preserves_address", is_instance_valid(address_button) and address_button.get_instance_id() == address_id and not bool(ui.call("get_cell", 1, 5)) and buttons.size() == 4 and (buttons[1] as Array).size() == 16,
		{"track": 1, "step": 5, "value": ui.call("get_cell", 1, 5), "same_button": address_button.get_instance_id() == address_id, "rows": buttons.size(), "columns": (buttons[1] as Array).size()})
	seq.set("_playhead_position", 5)
	seq.call("_advance_playhead")
	check("cleared_cell_no_longer_triggers", events.size() == before_count and int(ui.get("_playhead_position")) == 5)
	ui.call("set_cell", 2, 15, true)
	seq.set("_playhead_position", 15)
	seq.call("_advance_playhead")
	var last_event: Dictionary = events[-1]
	check("last_column_displays_before_wrap", events.size() == before_count + 1 and last_event.get("step") == 15 and last_event.get("displayed_during_event") == 15 and int(ui.get("_playhead_position")) == 15 and int(seq.get("_playhead_position")) == 0,
		{"event": last_event, "next_step": seq.get("_playhead_position")})
	seq.call("_advance_playhead")
	check("wrapped_empty_first_column_adds_no_event", events.size() == before_count + 1 and int(ui.get("_playhead_position")) == 0)
	seq.call("stop")
	var low_interval: float = float(seq.get("_step_interval"))
	seq.call("_on_bpm_changed", 240.0)
	var high_interval: float = float(seq.get("_step_interval"))
	check("tempo_changes_time_not_grid_bounds", is_equal_approx(low_interval, high_interval * 2.0) and (ui.get("_buttons") as Array).size() == 4 and ((ui.get("_buttons") as Array)[1] as Array).size() == 16,
		{"120_bpm_seconds": low_interval, "240_bpm_seconds": high_interval})
	var floor_node: Node3D = second["floor"]
	var bridge: Node = second["bridge"]
	var base := Color(0.15, 0.2, 0.25)
	reset_floor(floor_node, base)
	bridge.call("_on_step_triggered", 1, 0)
	var at_zero: Array = changed_columns(floor_node, base)
	reset_floor(floor_node, base)
	bridge.call("_on_step_triggered", 1, 12)
	var at_twelve: Array = changed_columns(floor_node, base)
	check("sixteen_steps_fold_onto_twelve_columns", at_zero == [0] and at_twelve == [0],
		{"step_0_columns": at_zero, "step_12_columns": at_twelve, "floor_width": floor_node.get("grid_width"), "sequencer_steps": seq.get("num_steps")})
	reset_floor(first["floor"], base)
	reset_floor(floor_node, base)
	seq.emit_signal("step_triggered", 1, 3)
	check("second_hall_event_affects_only_own_floor", changed_columns(first["floor"], base).is_empty() and changed_columns(floor_node, base) == [3],
		{"first_hall_columns": changed_columns(first["floor"], base), "second_hall_columns": changed_columns(floor_node, base)})
	var old_animation: int = int(floor_node.get("animation_step"))
	floor_node.call("_process", 0.1)
	check("floor_can_animate_with_sequencer_stopped", not bool(seq.get("_is_playing")) and int(floor_node.get("animation_step")) > old_animation,
		{"animation_step_before": old_animation, "animation_step_after": floor_node.get("animation_step")})
	finish(output)

func check_preset_sync(parent: Node) -> void:
	var states: Array = []
	var feedback: Array = []
	var passed := true
	for initial in ["808_kit", "90s_house"]:
		var seq: Node3D = (load("res://commons/audio/sequencer/step_sequencer.tscn") as PackedScene).instantiate()
		# Match the museum: map config is applied before the packed scene enters
		# the tree. Leave the first instance entirely unconfigured as a control.
		if initial != "808_kit":
			seq.call("apply_grid_config", {"sound_preset": initial})
		parent.add_child(seq)
		seq.set_process(false)
		var ui: Control = seq.get("_sequencer_ui") as Control
		if ui == null:
			passed = false
			seq.queue_free()
			continue
		var selector: OptionButton = ui.get("_preset_button") as OptionButton
		var initial_label := selector.get_item_text(selector.selected) if selector.selected >= 0 else ""
		passed = passed and seq.get("sound_preset") == initial and ui.get("sound_preset") == initial and initial_label == initial
		ui.connect("preset_changed", func(value: String): feedback.append({"preset_changed": value}))
		ui.connect("cell_toggled", func(track: int, step: int, active: bool): feedback.append({"cell": [track, step, active]}))
		seq.call("apply_grid_config", {"sound_preset": "disco"})
		var changed_label := selector.get_item_text(selector.selected) if selector.selected >= 0 else ""
		passed = passed and seq.get("sound_preset") == "disco" and ui.get("sound_preset") == "disco" and changed_label == "disco"
		var silent := true
		for player in seq.get("_audio_players"):
			silent = silent and player.stream == null and not player.playing
		passed = passed and silent
		states.append({"initial_model": initial, "initial_label": initial_label,
			"updated_label": changed_label, "no_preview_stream": silent})
		seq.queue_free()
	check("preset_label_follows_model_without_feedback", passed and feedback.is_empty(),
		{"states": states, "feedback": feedback})

func reset_floor(floor_node: Node, colour: Color) -> void:
	for z in range(int(floor_node.get("grid_depth"))):
		for x in range(int(floor_node.get("grid_width"))):
			floor_node.call("_set_tile", x, z, colour)

func changed_columns(floor_node: Node, original: Color) -> Array:
	var result: Array = []
	var colours: PackedColorArray = floor_node.get("tile_colors")
	for x in range(int(floor_node.get("grid_width"))):
		if not colours[x].is_equal_approx(original):
			result.append(x)
	return result

func finish(output: String) -> void:
	report = {"scope": "Actual packed scenes and their real UI/data/audio/bridge methods, advanced deterministically. No museum placement, VR pointer, headset audio or learner acceptance claim.", "checks": observations, "failures": failures, "passed": failures.is_empty()}
	var file := FileAccess.open(output, FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("DISCO ENCOUNTER ", "PASS" if failures.is_empty() else "FAIL", " ", failures)
	quit(0 if failures.is_empty() else 1)
