extends SceneTree
## File-IPC visitor for the real seed replay artifact in an isolated fixture.
## Inputs are synthetic mouse clicks through the production desktop pointer.
## This does not test museum navigation, occlusion, human reach or headset use.
## Public observations contain authored visible labels and mesh material RGB;
## privileged state and fixture details stay in separately named oracle files.

const ARTIFACT_SCENE := "res://algorithms/randomness/seed_replay/seed_replay_demo.tscn"
const MAP_FILE := "res://commons/maps/Random_Definition/map_data.json"
const STAGE_SCRIPT := "res://commons/artifacts/randomness_space/museum_exhibit_stage.gd"
const POINTER_SCENE := "res://commons/scenes/DesktopInteractionPointer.tscn"
const ACTIONS := {"replay": "REPLAY", "random": "RANDOM", "extra_draw": "+1 DRAW", "finish": "End experiment"}
const BUTTONS := {"replay": "Btn_0", "random": "Btn_1", "extra_draw": "Btn_2"}
const MAX_ACTIONS := 12
const LANE := "synthetic mouse -> production DesktopInteractionPointer ray -> area button -> artifact callback"

var run_dir: String = ""
var render_requested: bool = false
var disable_replay: bool = false
var timeout_seconds: float = 180.0
var demo: Node3D
var stage_root: Node3D
var eye: Node3D
var camera: Camera3D
var pointer: Node3D
var picture_camera: Camera3D
var fixture: Dictionary = {}
var controls: Dictionary = {}
var press_counts: Dictionary = {}
var release_counts: Dictionary = {}
var started_ms: int = 0
var last_heartbeat_ms: int = 0
var completed_id: int = 0
var stopped: bool = false


func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--visitor-dir="):
			run_dir = argument.trim_prefix("--visitor-dir=").replace("\\", "/")
		elif argument == "--visitor-render":
			render_requested = true
		elif argument == "--visitor-disable-replay":
			disable_replay = true
		elif argument.begins_with("--visitor-timeout="):
			timeout_seconds = clampf(float(argument.trim_prefix("--visitor-timeout=")), 10.0, 900.0)
	call_deferred("run")


func _write_json(filename: String, value: Dictionary) -> bool:
	var target: String = run_dir.path_join(filename)
	var temporary: String = target + ".tmp"
	var stream := FileAccess.open(temporary, FileAccess.WRITE)
	if stream == null:
		push_error("Seed visitor cannot write " + temporary)
		return false
	stream.store_string(JSON.stringify(value, "\t"))
	stream.close()
	# Every observation/oracle has a unique name. The command producer must also
	# use temp+rename so the bridge never reads a partially written command.
	var err: Error = DirAccess.rename_absolute(temporary, target)
	if err != OK:
		push_error("Seed visitor atomic rename failed: " + str(err))
		return false
	return true


func _heartbeat(phase: String) -> void:
	var now: int = Time.get_ticks_msec()
	if now - last_heartbeat_ms >= 500:
		print("SEED_VISITOR heartbeat phase=%s id=%d elapsed_ms=%d" % [phase, completed_id, now - started_ms])
		last_heartbeat_ms = now
		_write_json("heartbeat.json", {"id": completed_id, "phase": phase, "elapsed_ms": now - started_ms})


func _read_placement() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MAP_FILE))
	if not parsed is Dictionary:
		return {}
	var rows: Array = parsed.get("layers", {}).get("interactables", [])
	var matches: Array = []
	for z in range(rows.size()):
		var row: Array = rows[z]
		for x in range(row.size()):
			var token: String = str(row[x])
			if token.split(":")[0].split("#")[0] != "seed_replay_demo":
				continue
			var sections: PackedStringArray = token.split("#")
			var base: PackedStringArray = sections[0].split(":")
			var config: Dictionary = {}
			for part in sections.slice(1):
				var separator: int = part.find(":")
				if separator > 0:
					config[part.left(separator)] = part.substr(separator + 1)
			matches.append({"map": "Random_Definition", "token": token,
				"map_cell": [x, z], "config": config,
				"yaw_degrees": float(base[1]) if base.size() > 1 else 0.0})
	if matches.size() != 1:
		push_error("Expected exactly one seed_replay_demo placement, got " + str(matches.size()))
		return {}
	return matches[0]


func _fixture_setup() -> bool:
	fixture = _read_placement()
	if fixture.is_empty():
		return false
	stage_root = Node3D.new()
	stage_root.name = "SeedVisitorFixture"
	root.add_child(stage_root)
	var packed: PackedScene = load(ARTIFACT_SCENE)
	if packed == null:
		return false
	demo = packed.instantiate()
	var config: Dictionary = fixture.config
	for key in config:
		demo.set_meta("config_" + str(key), config[key])
	demo.call("apply_grid_config", config)
	demo.rotation_degrees.y = float(fixture.yaw_degrees)
	stage_root.add_child(demo)
	load(STAGE_SCRIPT).install(demo, config)
	# The stage waits two frames before reparenting the live controls.
	for i in range(8):
		await process_frame
	for action in BUTTONS:
		var button: Node = demo.find_child(BUTTONS[action], true, false)
		var area: Node3D = button.get_node_or_null("InteractableAreaButton") if button != null else null
		if area == null:
			push_error("Missing seed visitor button: " + str(action))
			return false
		controls[action] = area
		press_counts[action] = 0
		release_counts[action] = 0
		area.button_pressed.connect(_on_pressed.bind(str(action)))
		area.button_released.connect(_on_released.bind(str(action)))
	if disable_replay:
		var removed: int = 0
		var replay_area: Node = controls.replay
		for connection in replay_area.get_signal_connection_list("button_pressed"):
			var callback: Callable = connection.callable
			if callback.get_object() == demo:
				replay_area.disconnect("button_pressed", callback)
				removed += 1
		fixture["test_fault"] = {"disabled_replay_callbacks": removed}
		if removed != 1:
			push_error("Negative control expected exactly one artifact REPLAY callback")
			return false
	var standing: Node3D = demo.find_child("StandingPosition", true, false)
	if standing == null:
		push_error("Compact console has no authored StandingPosition")
		return false
	eye = Node3D.new()
	eye.name = "FixedVisitorEye"
	stage_root.add_child(eye)
	eye.global_position = standing.global_position + Vector3(0, 1.6, 0)
	camera = Camera3D.new()
	camera.name = "Camera3D"
	eye.add_child(camera)
	camera.make_current()
	pointer = load(POINTER_SCENE).instantiate()
	eye.add_child(pointer)
	picture_camera = Camera3D.new()
	stage_root.add_child(picture_camera)
	picture_camera.position = demo.to_global(Vector3(0, 2.1, 4.4))
	picture_camera.look_at(demo.to_global(Vector3(0, 1.75, 0)))
	picture_camera.fov = 55.0
	var environment_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.035, 0.047, 0.062)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.85
	environment_node.environment = environment
	stage_root.add_child(environment_node)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	stage_root.add_child(light)
	root.size = Vector2i(1280, 900)
	fixture["standing_position"] = _vector(standing.global_position)
	fixture["eye_position"] = _vector(eye.global_position)
	fixture["scope"] = "Isolated real artifact and museum compact-console staging; fixed synthetic eye. No full hall, walking, human reach, headset or learner test."
	fixture["observation_scope"] = "Visible-in-tree Label3D text and material albedo RGB, not image perception or an occlusion test. Control label strings transcribed from this artifact's public rack labels."
	fixture["source_hashes"] = {}
	for source in [MAP_FILE, ARTIFACT_SCENE, "res://algorithms/randomness/seed_replay/seed_replay_demo.gd", STAGE_SCRIPT, "res://commons/audio/rack_templates/RackTemplates.gd", "res://commons/scenes/DesktopInteractionPointer.gd", "res://commons/interactables/interactable_area_button_pointer.gd", "res://addons/godot-xr-tools/interactables/interactable_area_button.gd"]:
		fixture.source_hashes[source] = FileAccess.get_sha256(source)
	await physics_frame
	return true


func _on_pressed(_button: Node, action: String) -> void:
	press_counts[action] = int(press_counts[action]) + 1


func _on_released(_button: Node, action: String) -> void:
	release_counts[action] = int(release_counts[action]) + 1


func _vector(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _press(action: String) -> Dictionary:
	var area: Node3D = controls[action]
	camera.make_current()
	eye.look_at(area.global_position, Vector3.UP)
	# Wait for normal production pointer/raycast processing. No target-cache
	# injection, direct artifact method call or synthetic button signal.
	for i in range(3):
		await physics_frame
		await process_frame
	var target: Node = pointer.get("_last_target")
	var before_press: int = int(press_counts[action])
	var before_release: int = int(release_counts[action])
	if target != area:
		return {"ok": false, "action": action, "lane": LANE, "reason": "pointer_did_not_reach_requested_button",
			"hover": str(target.get_path()) if target != null else "nothing"}
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.pressed = true
	down.position = Vector2(root.size) * 0.5
	down.global_position = down.position
	Input.parse_input_event(down)
	await process_frame
	await physics_frame
	var up := InputEventMouseButton.new()
	up.button_index = MOUSE_BUTTON_LEFT
	up.pressed = false
	up.position = down.position
	up.global_position = down.global_position
	Input.parse_input_event(up)
	await process_frame
	await create_timer(0.15).timeout
	var fired: int = int(press_counts[action]) - before_press
	var released: int = int(release_counts[action]) - before_release
	return {"ok": fired == 1 and released == 1 and not bool(area.get("pressed")),
		"action": action, "lane": LANE, "pressed_events": fired,
		"released_events": released, "hover": str(area.get_path()),
		"eye_position": _vector(eye.global_position)}


func _observation(id: int, dispatch: Dictionary, terminal: bool = false) -> Dictionary:
	var labels: Array = []
	for node in demo.find_children("*", "Label3D", true, false):
		var label: Label3D = node
		if label.is_visible_in_tree() and not label.text.is_empty():
			labels.append(label.text)
	var columns: Array = []
	for index in range(int(demo.call("column_count"))):
		var values: Array = []
		var colors: PackedColorArray = demo.call("column_colors", index)
		for color in colors:
			values.append([color.r, color.g, color.b])
		columns.append(values)
	return {"id": id, "labels": labels, "actions": ACTIONS,
		"columns": columns, "dispatch": dispatch, "terminal": terminal}


func _reference_check() -> Dictionary:
	# Privileged diagnostic only: independently consume a new RNG. Do not call
	# artifact raw_prefix(), _regenerate(), or reuse any expected colour values.
	var seed_value: int = int(demo.call("current_seed"))
	var extra: bool = bool(demo.call("extra_on"))
	var skipped: int = int(demo.get("extra_draws"))
	var grid_size: int = int(demo.get("grid_cols")) * int(demo.get("grid_rows"))
	var count: int = int(demo.call("column_count"))
	var per_column: Array = []
	var all_match: bool = count == 2 and str(demo.get("comparison")) == "replicas"
	for index in range(count):
		var independent := RandomNumberGenerator.new()
		independent.seed = seed_value
		if extra and index == count - 1:
			for skipped_index in range(skipped):
				independent.randf()
		var actual: PackedColorArray = demo.call("column_colors", index)
		var matches: bool = actual.size() == grid_size
		var mismatches: Array = []
		for cell in range(grid_size):
			var expected := Color(independent.randf(), independent.randf(), independent.randf())
			if cell >= actual.size() or not actual[cell].is_equal_approx(expected):
				matches = false
				mismatches.append(cell)
		per_column.append({"column": index, "cell_count": actual.size(),
			"expected_cell_count": grid_size, "matches": matches, "mismatching_cells": mismatches})
		all_match = all_match and matches
	return {"all_match": all_match, "columns": per_column,
		"method": "fresh Godot RandomNumberGenerator per column, current seed, independently consume optional discard then three draws per RGB cell"}


func _slider_check() -> Dictionary:
	var expected_seed: int = int(demo.call("current_seed"))
	var slider: Node = demo.find_child("Param_0", true, false)
	if slider == null or not slider.has_method("get_normalized_value"):
		return {"expected_seed": expected_seed, "normalized_seed": null,
			"displayed_text": "", "matches": false, "reason": "slider_missing"}
	var normalized_seed: int = roundi(float(slider.call("get_normalized_value")) * 999.0)
	var label: Label3D = slider.get_node_or_null("Frame/Label3DValue")
	var displayed_text: String = label.text if label != null else ""
	var label_visible: bool = label != null and label.is_visible_in_tree()
	return {"expected_seed": expected_seed, "normalized_seed": normalized_seed,
		"displayed_text": displayed_text, "visible": label_visible,
		"matches": normalized_seed == expected_seed and displayed_text == str(expected_seed) and label_visible}


func _check_slider_updates() -> Dictionary:
	# Post-visitor diagnostic: use XRTools' public move_slider(), which emits
	# the normal slider_moved signal. This tests callback/state/label wiring,
	# not pointer dragging, hand contact or the learner's physical reach.
	var slider: Node = demo.find_child("Param_0", true, false)
	var track: Node = slider.get_node_or_null("SliderOrigin/InteractableSlider") if slider != null else null
	if track == null or not track.has_method("move_slider"):
		return {"passed": false, "reason": "slider_track_missing"}
	var original_seed: int = int(demo.call("current_seed"))
	var minimum: float = float(track.get("slider_limit_min"))
	var maximum: float = float(track.get("slider_limit_max"))
	var cases: Array = []
	var passed: bool = true
	for target in [42, 137, 42, original_seed]:
		track.call("move_slider", lerpf(minimum, maximum, float(target) / 999.0))
		await process_frame
		var state: Dictionary = _slider_check()
		var reference: Dictionary = _reference_check()
		var step_passed: bool = int(demo.call("current_seed")) == target and bool(state.matches) and bool(reference.all_match)
		cases.append({"target_seed": target, "passed": step_passed, "slider": state, "reference": reference})
		passed = passed and step_passed
	return {"passed": passed, "lane": "XRToolsInteractableSlider.move_slider -> normal slider_moved signal -> artifact callback",
		"scope": "Signal/control-state diagnostic after visitor finish; no pointer drag or headset claim.", "cases": cases}


func _check_replay_repairs() -> bool:
	# Test-only fault in this isolated instance after the visitor has finished.
	# A no-op REPLAY preserves an unmodified image; this challenge detects it.
	var before: Dictionary = _reference_check()
	var entries: Array = demo.get("_columns")
	var cube: MeshInstance3D = entries[0]["cubes"][0]
	var material: StandardMaterial3D = cube.material_override
	var original: Color = material.albedo_color
	material.albedo_color = Color(1.0 if original.r < 0.5 else 0.0, original.g, original.b)
	var corrupted: Dictionary = _reference_check()
	var dispatch: Dictionary = await _press("replay")
	var repaired: Dictionary = _reference_check()
	var replay_passed: bool = bool(before.all_match) and not bool(corrupted.all_match) and bool(dispatch.ok) and bool(repaired.all_match)
	var slider_diagnostic: Dictionary = await _check_slider_updates()
	var passed: bool = replay_passed and bool(slider_diagnostic.passed)
	var result: Dictionary = {"passed": passed, "replay_passed": replay_passed, "slider_diagnostic": slider_diagnostic,
		"scope": "Disposable fixture only, after terminal visitor observation; diagnostic excluded from model state.",
		"test_fault_disabled_replay": disable_replay,
		"before": before, "corrupted": corrupted, "dispatch": dispatch, "after_replay": repaired,
		"check": "REPLAY must reconstruct material colours, not merely leave an already-correct picture unchanged"}
	if not _write_json("fixture_checks.json", result):
		return false
	return passed


func _publish(id: int, dispatch: Dictionary, terminal: bool = false) -> bool:
	var oracle: Dictionary = {"id": id, "fixture": fixture,
		"seed": demo.call("current_seed"), "extra_on": demo.call("extra_on"),
		"extra_draws": int(demo.get("extra_draws")), "last_action": demo.call("last_action"),
		"reference_check": _reference_check(), "slider_check": _slider_check(),
		"pressed_counts": press_counts.duplicate(), "released_counts": release_counts.duplicate(),
		"elapsed_ms": Time.get_ticks_msec() - started_ms}
	if render_requested and DisplayServer.get_name() != "headless":
		picture_camera.make_current()
		await process_frame
		await RenderingServer.frame_post_draw
		var capture: String = "capture_%03d.png" % id
		var capture_error: Error = root.get_texture().get_image().save_png(run_dir.path_join(capture))
		oracle["capture"] = capture if capture_error == OK else ""
		oracle["capture_error"] = capture_error
		camera.make_current()
	if not _write_json("oracle_%03d.json" % id, oracle):
		return false
	return _write_json("observation_%03d.json" % id, _observation(id, dispatch, terminal))


func _finish(code: int, reason: String) -> void:
	if stopped:
		return
	stopped = true
	_write_json("bridge_result.json", {"exit_code": code, "reason": reason,
		"last_observation_id": completed_id, "max_actions": MAX_ACTIONS,
		"elapsed_ms": Time.get_ticks_msec() - started_ms, "lane": LANE})
	print("SEED_VISITOR finished reason=%s id=%d exit=%d" % [reason, completed_id, code])
	quit(code)


func run() -> void:
	started_ms = Time.get_ticks_msec()
	if run_dir.is_empty() or not run_dir.is_absolute_path():
		push_error("--visitor-dir must be an absolute path")
		quit(2)
		return
	if DirAccess.make_dir_recursive_absolute(run_dir) != OK:
		push_error("Cannot create visitor directory")
		quit(2)
		return
	if FileAccess.file_exists(run_dir.path_join("observation_000.json")):
		push_error("Visitor directory already contains an observation; use a fresh directory")
		quit(2)
		return
	last_heartbeat_ms = started_ms - 500
	_heartbeat("initializing")
	if not await _fixture_setup():
		_finish(2, "fixture_setup_failed")
		return
	if not await _publish(0, {"ok": true, "action": "arrival", "lane": LANE}):
		_finish(2, "observation_write_failed")
		return
	print("SEED_VISITOR ready " + run_dir)
	for id in range(1, MAX_ACTIONS + 1):
		var command_file: String = run_dir.path_join("command_%03d.json" % id)
		while not FileAccess.file_exists(command_file):
			if Time.get_ticks_msec() - started_ms >= int(timeout_seconds * 1000.0):
				_finish(3, "visitor_timeout")
				return
			_heartbeat("waiting")
			await create_timer(0.05).timeout
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(command_file))
		if not parsed is Dictionary or int(parsed.get("id", -1)) != id:
			_finish(2, "invalid_command_id_or_json")
			return
		var action: String = str(parsed.get("action", ""))
		if not ACTIONS.has(action):
			_finish(2, "action_not_allowed")
			return
		var terminal: bool = action == "finish" or id == MAX_ACTIONS
		var dispatch: Dictionary = {"ok": true, "action": action, "lane": "visitor ends experiment"} if action == "finish" else await _press(action)
		completed_id = id
		if not await _publish(id, dispatch, terminal):
			_finish(2, "observation_write_failed")
			return
		print("SEED_VISITOR action=%s id=%d dispatch_ok=%s" % [action, id, str(dispatch.ok)])
		if not bool(dispatch.ok):
			_finish(4, "button_dispatch_failed")
			return
		if terminal:
			if not await _check_replay_repairs():
				_finish(5, "fixture_diagnostic_failed")
				return
			_finish(0, "visitor_finished" if action == "finish" else "action_limit")
			return
