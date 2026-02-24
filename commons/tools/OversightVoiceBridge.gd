extends Node

@export var enabled: bool = true
@export var oversight_base_url: String = "http://localhost:3001"
@export var voice_endpoint: String = "/api/audio" # Use "/api/voice" for direct retry/create without manual editing.
@export var push_to_talk_action: StringName = &"oversight_push_to_talk"
@export var secondary_push_to_talk_action: StringName = &"vr_button_a"
@export var controller_push_to_talk_button: StringName = &"ax_button"
@export var controller_push_to_talk_tracker: StringName = &"right_hand"
@export var debug_controller_input: bool = true
@export var controller_rescan_interval_sec: float = 2.0
@export var default_mode: String = "auto" # auto | retry | create
@export var include_memories: bool = true
@export var include_last_output: bool = true
@export var auto_resume_queue: bool = false
@export var default_priority: String = "high"
@export var create_title_prefix: String = "Voice Debug"
@export var scene_hint: String = ""
@export var min_recording_seconds: float = 0.25
@export var max_recording_seconds: float = 20.0
@export var show_status_label: bool = true
@export var status_label_distance: float = 0.55
@export var status_label_height_offset: float = -0.16
@export var status_label_lifetime: float = 3.0
@export var silence_peak_threshold: float = 0.00001
@export var nearby_artifact_radius_m: float = 6.0
@export var max_nearby_artifacts: int = 5

const RECORD_BUS_NAME := "OversightMicCapture"
const RECORD_FILE_PATH := "user://oversight_voice/latest_debug.wav"
const CONTROLLER_OWNER_META := "_oversight_voice_owner_id"
const ANDROID_RECORD_AUDIO_PERMISSION := "android.permission.RECORD_AUDIO"

signal voice_recording_started()
signal voice_recording_stopped(duration_seconds: float)
signal voice_dispatch_succeeded(response: Dictionary)
signal voice_dispatch_failed(message: String)

var _record_effect: AudioEffectRecord
var _mic_player: AudioStreamPlayer
var _is_recording := false
var _record_start_msec := 0
var _status_label: Label3D
var _status_hide_at_msec := 0
var _left_controller: XRController3D
var _right_controller: XRController3D
var _next_controller_scan_msec := 0

func _ready() -> void:
	var root_singleton := get_node_or_null("/root/OversightVoiceBridge")
	if root_singleton != null and root_singleton != self:
		enabled = false
		push_warning("OversightVoiceBridge: duplicate scene instance disabled, using /root/OversightVoiceBridge singleton")
		return

	print("OversightVoiceBridge: ready (enabled=%s, base_url=%s, push_action=%s, secondary_action=%s)" % [
		enabled,
		oversight_base_url,
		push_to_talk_action,
		secondary_push_to_talk_action
	])
	if not bool(ProjectSettings.get_setting("audio/driver/enable_input", false)):
		push_warning("OversightVoiceBridge: audio input is disabled in Project Settings (audio/driver/enable_input=false)")
	_log_mic_capture_context()
	_ensure_input_action()
	_setup_recording_pipeline()
	call_deferred("_connect_controller_signals")
	if show_status_label:
		call_deferred("_setup_status_label")

func _exit_tree() -> void:
	_release_controller_owner(_left_controller)
	_release_controller_owner(_right_controller)

func _input(event: InputEvent) -> void:
	if not enabled:
		return

	if _is_push_to_talk_pressed(event):
		_start_recording()
		return

	if _is_push_to_talk_released(event):
		_stop_and_dispatch()

func _process(_delta: float) -> void:
	if not enabled:
		return

	if _is_recording and max_recording_seconds > 0:
		var elapsed_sec := float(Time.get_ticks_msec() - _record_start_msec) / 1000.0
		if elapsed_sec >= max_recording_seconds:
			_stop_and_dispatch()

	var now_msec := Time.get_ticks_msec()
	if now_msec >= _next_controller_scan_msec:
		_next_controller_scan_msec = now_msec + int(max(0.2, controller_rescan_interval_sec) * 1000.0)
		_connect_controller_signals()

	if _status_label and _status_label.visible and _status_hide_at_msec > 0:
		if Time.get_ticks_msec() >= _status_hide_at_msec:
			_status_label.visible = false
			_status_hide_at_msec = 0

func send_transcript(transcript: String, extra: Dictionary = {}) -> void:
	var clean := transcript.strip_edges()
	if clean.is_empty():
		_emit_fail("Transcript is empty")
		return

	var payload := {
		"transcript": clean,
		"mode": default_mode,
		"includeMemories": include_memories,
		"includeLastOutput": include_last_output,
		"autoResume": auto_resume_queue,
		"priority": default_priority,
		"title": _build_title(clean),
		"scene": _resolve_scene_name(),
	}
	var context := _build_runtime_context()
	payload.merge(context, true)
	payload.merge(extra, true)
	_send_payload(payload)

func _ensure_input_action() -> void:
	if InputMap.has_action(push_to_talk_action):
		return

	InputMap.add_action(push_to_talk_action, 0.5)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = KEY_F8
	InputMap.action_add_event(push_to_talk_action, key_event)
	print("OversightVoiceBridge: created input action '%s' on F8" % push_to_talk_action)

func _is_push_to_talk_pressed(event: InputEvent) -> bool:
	if _event_is_action_pressed(event, push_to_talk_action):
		return true
	if secondary_push_to_talk_action != &"" and _event_is_action_pressed(event, secondary_push_to_talk_action):
		return true
	if _event_is_action_pressed(event, &"ax_button"):
		return true
	if _event_is_action_pressed(event, &"primary_click"):
		return true
	return false

func _is_push_to_talk_released(event: InputEvent) -> bool:
	if event.is_action_released(push_to_talk_action):
		return true
	if secondary_push_to_talk_action != &"" and event.is_action_released(secondary_push_to_talk_action):
		return true
	if event.is_action_released(&"ax_button"):
		return true
	if event.is_action_released(&"primary_click"):
		return true
	return false

func _event_is_action_pressed(event: InputEvent, action_name: StringName) -> bool:
	if action_name == &"":
		return false
	if not event.is_action_pressed(action_name):
		return false
	if event is InputEventKey and (event as InputEventKey).echo:
		return false
	return true

func _connect_controller_signals() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var left := _find_controller(scene, ["LeftHandController", "LeftController", "LeftHand"], "left")
	var right := _find_controller(scene, ["RightHandController", "RightController", "RightHand"], "right")

	if _left_controller != null and _left_controller != left:
		_release_controller_owner(_left_controller)
	if _right_controller != null and _right_controller != right:
		_release_controller_owner(_right_controller)

	_connect_controller(left)
	_connect_controller(right)

	_left_controller = left
	_right_controller = right

func _find_controller(scene: Node, preferred_names: Array, side_hint: String) -> XRController3D:
	var xr_origin := scene.find_child("XROrigin3D", true, false)
	if xr_origin != null:
		for node_name in preferred_names:
			var node := xr_origin.find_child(node_name, true, false)
			if node is XRController3D:
				return node as XRController3D

	var controllers := get_tree().get_nodes_in_group("xr_controllers")
	for node in controllers:
		if node is XRController3D:
			var controller := node as XRController3D
			var tracker := String(controller.tracker)
			if side_hint == "left" and tracker.contains("left"):
				return controller
			if side_hint == "right" and tracker.contains("right"):
				return controller

	for node in controllers:
		if node is XRController3D:
			return node as XRController3D

	return null

func _connect_controller(controller: XRController3D) -> void:
	if controller == null:
		return
	if not controller.has_signal("button_pressed") or not controller.has_signal("button_released"):
		return

	var owner_id := int(controller.get_meta(CONTROLLER_OWNER_META, 0))
	if owner_id != 0 and owner_id != get_instance_id():
		var owner := instance_from_id(owner_id)
		if owner != null:
			if debug_controller_input:
				print("OversightVoiceBridge: controller %s already owned by %d" % [controller.name, owner_id])
			return
	if owner_id == get_instance_id():
		return

	var pressed_cb := _on_controller_button_pressed.bind(controller)
	if not controller.button_pressed.is_connected(pressed_cb):
		controller.button_pressed.connect(pressed_cb)
		print("OversightVoiceBridge: connected button_pressed on %s (%s)" % [controller.name, controller.tracker])

	var released_cb := _on_controller_button_released.bind(controller)
	if not controller.button_released.is_connected(released_cb):
		controller.button_released.connect(released_cb)
		print("OversightVoiceBridge: connected button_released on %s (%s)" % [controller.name, controller.tracker])

	controller.set_meta(CONTROLLER_OWNER_META, get_instance_id())

func _release_controller_owner(controller: XRController3D) -> void:
	if controller == null:
		return
	var owner_id := int(controller.get_meta(CONTROLLER_OWNER_META, 0))
	if owner_id == get_instance_id():
		controller.remove_meta(CONTROLLER_OWNER_META)

func _on_controller_button_pressed(button: String, controller: XRController3D) -> void:
	if debug_controller_input:
		print("OversightVoiceBridge: controller pressed %s on %s (%s)" % [button, controller.name, controller.tracker])
	if not enabled:
		return
	if _controller_button_matches(button, controller):
		_set_status("PTT pressed", Color(0.9, 0.8, 1.0, 1.0), 1.2)
		_start_recording()

func _on_controller_button_released(button: String, controller: XRController3D) -> void:
	if debug_controller_input:
		print("OversightVoiceBridge: controller released %s on %s (%s)" % [button, controller.name, controller.tracker])
	if not enabled:
		return
	if _controller_button_matches(button, controller):
		_stop_and_dispatch()

func _controller_button_matches(button: String, controller: XRController3D) -> bool:
	if controller_push_to_talk_button != &"" and String(controller_push_to_talk_button) != button:
		return false
	if controller_push_to_talk_tracker == &"":
		return true
	return controller != null and controller.tracker == controller_push_to_talk_tracker

func _setup_status_label() -> void:
	if not show_status_label:
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var camera := scene.find_child("XRCamera3D", true, false) as Node3D
	if camera == null:
		camera = get_viewport().get_camera_3d() as Node3D
	if camera == null:
		return
	if camera.get_node_or_null("OversightVoiceStatus"):
		_status_label = camera.get_node("OversightVoiceStatus") as Label3D
	else:
		_status_label = Label3D.new()
		_status_label.name = "OversightVoiceStatus"
		_status_label.position = Vector3(0.18, status_label_height_offset, -status_label_distance)
		_status_label.pixel_size = 0.001
		_status_label.font_size = 42
		_status_label.outline_size = 4
		_status_label.no_depth_test = true
		_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_status_label.visible = false
		camera.add_child(_status_label)
	_set_status("Voice bridge ready", Color(0.6, 0.9, 1.0, 1.0), 2.0)

func _set_status(message: String, color: Color = Color(1, 1, 1, 1), lifetime_sec: float = -1.0) -> void:
	if not show_status_label:
		return
	if _status_label == null:
		_setup_status_label()
	if _status_label == null:
		return
	_status_label.text = message
	_status_label.modulate = color
	_status_label.visible = true
	var duration := lifetime_sec if lifetime_sec >= 0 else status_label_lifetime
	if duration > 0:
		_status_hide_at_msec = Time.get_ticks_msec() + int(duration * 1000.0)
	else:
		_status_hide_at_msec = 0

func _setup_recording_pipeline() -> void:
	var bus_index := _ensure_record_bus()
	_record_effect = _find_or_add_record_effect(bus_index)

	_mic_player = AudioStreamPlayer.new()
	_mic_player.name = "OversightMicPlayer"
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = RECORD_BUS_NAME
	_mic_player.volume_db = 0.0
	add_child(_mic_player)
	print("OversightVoiceBridge: recording pipeline ready (bus=%s, input_enabled=%s)" % [
		RECORD_BUS_NAME,
		bool(ProjectSettings.get_setting("audio/driver/enable_input", false))
	])

func _ensure_record_bus() -> int:
	var idx := AudioServer.get_bus_index(RECORD_BUS_NAME)
	if idx != -1:
		AudioServer.set_bus_mute(idx, false)
		return idx

	AudioServer.add_bus(AudioServer.bus_count)
	idx = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, RECORD_BUS_NAME)
	AudioServer.set_bus_mute(idx, false)
	return idx

func _find_or_add_record_effect(bus_index: int) -> AudioEffectRecord:
	for i in range(AudioServer.get_bus_effect_count(bus_index)):
		var effect := AudioServer.get_bus_effect(bus_index, i)
		if effect is AudioEffectRecord:
			return effect as AudioEffectRecord

	var record_effect := AudioEffectRecord.new()
	AudioServer.add_bus_effect(bus_index, record_effect, 0)
	return record_effect

func _start_recording() -> void:
	if _is_recording:
		return
	if _record_effect == null:
		_emit_fail("Recording effect is unavailable")
		return
	if not _ensure_android_microphone_permission(true):
		_set_status("Mic permission required", Color(1.0, 0.35, 0.35, 1.0), 5.0)
		return

	_record_start_msec = Time.get_ticks_msec()
	_is_recording = true

	_mic_player.play()
	_record_effect.set_recording_active(true)
	emit_signal("voice_recording_started")
	print("OversightVoiceBridge: recording started (mic_player.playing=%s)" % _mic_player.playing)
	_set_status("REC", Color(1.0, 0.25, 0.25, 1.0), 0.0)

func _stop_and_dispatch() -> void:
	if not _is_recording:
		return
	if _record_effect == null:
		_emit_fail("Recording effect is unavailable")
		return

	_record_effect.set_recording_active(false)
	_mic_player.stop()
	_is_recording = false

	var duration_sec := float(Time.get_ticks_msec() - _record_start_msec) / 1000.0
	emit_signal("voice_recording_stopped", duration_sec)
	_set_status("Sending...", Color(1.0, 0.85, 0.3, 1.0), 8.0)

	if duration_sec < min_recording_seconds:
		print("OversightVoiceBridge: recording ignored (%.2fs < %.2fs)" % [duration_sec, min_recording_seconds])
		_set_status("Ignored: too short", Color(1.0, 0.7, 0.25, 1.0), 2.5)
		return

	var stream := _record_effect.get_recording()
	if stream == null:
		_emit_fail("No recording data captured")
		return
	if not (stream is AudioStreamWAV):
		_emit_fail("Captured stream is not AudioStreamWAV")
		return

	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("oversight_voice"):
		dir.make_dir("oversight_voice")

	var wav := stream as AudioStreamWAV
	var save_err := wav.save_to_wav(RECORD_FILE_PATH)
	if save_err != OK:
		_emit_fail("Failed to save WAV: %s" % error_string(save_err))
		return
	print("OversightVoiceBridge: saved recording to %s" % RECORD_FILE_PATH)

	var file := FileAccess.open(RECORD_FILE_PATH, FileAccess.READ)
	if file == null:
		_emit_fail("Failed to open saved recording")
		return
	var data := file.get_buffer(file.get_length())
	file.close()
	if data.is_empty():
		_emit_fail("Recording file is empty")
		return
	if data.size() <= 64:
		_emit_fail("No microphone samples captured (recording too short or mic unavailable)")
		return
	var peak := _estimate_wav_peak(data)
	if peak <= silence_peak_threshold:
		_emit_fail("Captured audio is silent (peak=%.6f). Check Quest mic permission + audio input setting." % peak)
		return
	print("OversightVoiceBridge: captured %.2fs audio (%d bytes)" % [duration_sec, data.size()])

	var payload := {
		"audio_base64": Marshalls.raw_to_base64(data),
		"filename": "voice_debug.wav",
		"mime_type": "audio/wav",
		"mode": default_mode,
		"includeMemories": include_memories,
		"includeLastOutput": include_last_output,
		"autoResume": auto_resume_queue,
		"priority": default_priority,
		"title": _build_title(""),
		"scene": _resolve_scene_name(),
	}
	var context := _build_runtime_context()
	payload.merge(context, true)
	_send_payload(payload)

func _build_title(transcript: String) -> String:
	if transcript.is_empty():
		return "%s: %s" % [create_title_prefix, _resolve_scene_name()]
	var short_text := transcript.substr(0, min(60, transcript.length())).strip_edges()
	return "%s: %s" % [create_title_prefix, short_text]

func _resolve_scene_name() -> String:
	if not scene_hint.strip_edges().is_empty():
		return scene_hint.strip_edges()

	var scene := get_tree().current_scene
	return scene.name if scene != null else "unknown_scene"

func _build_runtime_context() -> Dictionary:
	var context: Dictionary = {}

	var map_name := _resolve_current_map_name()
	if not map_name.is_empty():
		context["map_name"] = map_name

	var player := _resolve_player_node()
	if player == null:
		context["nearby_artifacts"] = []
		return context

	var player_pos := player.global_position
	context["player_position"] = {
		"x": snappedf(player_pos.x, 0.01),
		"y": snappedf(player_pos.y, 0.01),
		"z": snappedf(player_pos.z, 0.01),
	}
	context["nearby_artifacts"] = _collect_nearby_artifacts(player_pos)
	return context

func _resolve_current_map_name() -> String:
	var grid_nodes: Array = get_tree().get_nodes_in_group("grid_system")
	for grid_node in grid_nodes:
		if grid_node == null:
			continue
		var map_value: Variant = grid_node.get("map_name")
		var map_text := str(map_value).strip_edges()
		if not map_text.is_empty():
			return map_text

	var scene := get_tree().current_scene
	if scene == null:
		return ""

	var scene_data_variant: Variant = scene.get_meta("scene_user_data", scene.get_meta("scene_data", {}))
	if scene_data_variant is Dictionary:
		var scene_data := scene_data_variant as Dictionary
		if scene_data.has("map_name"):
			return str(scene_data.get("map_name", "")).strip_edges()
		if scene_data.has("initial_map"):
			return str(scene_data.get("initial_map", "")).strip_edges()
	return ""

func _resolve_player_node() -> Node3D:
	var grouped_player := get_tree().get_first_node_in_group("player_body")
	if grouped_player is Node3D:
		var grouped_node := grouped_player as Node3D
		if grouped_node.name == "PlayerBody" and grouped_node.get_parent() is Node3D:
			return grouped_node.get_parent() as Node3D
		return grouped_node

	var scene := get_tree().current_scene
	if scene == null:
		return null
	var xr_origin := scene.find_child("XROrigin3D", true, false)
	if xr_origin is Node3D:
		return xr_origin as Node3D
	return null

func _collect_nearby_artifacts(player_pos: Vector3) -> Array:
	var scene := get_tree().current_scene
	if scene == null:
		return []
	var matches: Array[Dictionary] = []
	_append_nearby_artifacts(scene, player_pos, nearby_artifact_radius_m, matches)
	matches.sort_custom(_sort_artifacts_by_distance)

	var limit: int = min(max_nearby_artifacts, matches.size())
	var result: Array = []
	for i in range(limit):
		var entry: Dictionary = matches[i]
		result.append({
			"lookup_name": entry.get("lookup_name", ""),
			"artifact_name": entry.get("artifact_name", ""),
			"distance_m": entry.get("distance_m", 0.0),
		})
	return result

func _append_nearby_artifacts(node: Node, player_pos: Vector3, radius_m: float, out: Array[Dictionary]) -> void:
	if node is Node3D:
		var node3d := node as Node3D
		if node3d.has_meta("artifact_lookup_name"):
			var lookup_name := str(node3d.get_meta("artifact_lookup_name", "")).strip_edges()
			if not lookup_name.is_empty():
				var distance := player_pos.distance_to(node3d.global_position)
				if distance <= radius_m:
					var artifact_name := str(node3d.get_meta("artifact_name", lookup_name)).strip_edges()
					out.append({
						"lookup_name": lookup_name,
						"artifact_name": artifact_name if not artifact_name.is_empty() else lookup_name,
						"distance_m": snappedf(distance, 0.01),
						"_distance_raw": distance,
					})

	for child in node.get_children():
		_append_nearby_artifacts(child, player_pos, radius_m, out)

func _sort_artifacts_by_distance(a: Dictionary, b: Dictionary) -> bool:
	var da: float = float(a.get("_distance_raw", 999999.0))
	var db: float = float(b.get("_distance_raw", 999999.0))
	return da < db

func _send_payload(payload: Dictionary) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed.bind(http))

	var url := "%s%s" % [oversight_base_url.trim_suffix("/"), voice_endpoint]
	var headers := PackedStringArray(["Content-Type: application/json"])
	var body := JSON.stringify(payload)
	http.set_meta("oversight_url", url)

	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()
		_emit_fail("Voice request failed to start: %s" % error_string(err))
		return

	print("OversightVoiceBridge: sent voice payload to %s" % url)
	_set_status("Upload sent", Color(0.75, 0.85, 1.0, 1.0), 3.0)

func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http: HTTPRequest
) -> void:
	var url := String(http.get_meta("oversight_url", ""))
	http.queue_free()
	print("OversightVoiceBridge: request completed result=%d(%s) code=%d bytes=%d url=%s" % [
		result,
		_http_result_name(result),
		response_code,
		body.size(),
		url
	])

	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_fail(_build_transport_error_message(result, url))
		return

	var text := body.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if response_code < 200 or response_code >= 300:
		var err_text := text if not text.is_empty() else "HTTP %d" % response_code
		_emit_fail(err_text)
		return

	if parsed is Dictionary:
		var parsed_dict := parsed as Dictionary
		emit_signal("voice_dispatch_succeeded", parsed_dict)
		if parsed_dict.has("id"):
			print("OversightVoiceBridge: audio stored id=%s" % str(parsed_dict["id"]))
	else:
		emit_signal("voice_dispatch_succeeded", {"raw": text})

	print("OversightVoiceBridge: dispatch complete (%d)" % response_code)
	_set_status("Sent to Oversight", Color(0.45, 1.0, 0.45, 1.0), 3.0)

func _emit_fail(message: String) -> void:
	print("OversightVoiceBridge ERROR: %s" % message)
	push_warning("OversightVoiceBridge: %s" % message)
	emit_signal("voice_dispatch_failed", message)
	_set_status("Voice error", Color(1.0, 0.35, 0.35, 1.0), 6.0)

func _build_transport_error_message(result: int, url: String) -> String:
	var base := "Voice request transport error: %d (%s) -> %s" % [result, _http_result_name(result), url]
	if result == HTTPRequest.RESULT_CANT_CONNECT and OS.has_feature("android") and url.contains("localhost"):
		return "%s | Hint: USB reverse missing. Run `adb reverse tcp:3001 tcp:3001` on your PC." % base
	return base

func _log_mic_capture_context() -> void:
	var input_enabled: bool = bool(ProjectSettings.get_setting("audio/driver/enable_input", false))
	var is_android: bool = OS.has_feature("android")
	print("OversightVoiceBridge: mic context input_enabled=%s android=%s" % [input_enabled, is_android])
	if not is_android:
		return
	var granted_permissions: PackedStringArray = OS.get_granted_permissions()
	var has_permission: bool = granted_permissions.has(ANDROID_RECORD_AUDIO_PERMISSION)
	print("OversightVoiceBridge: android permission %s granted=%s" % [ANDROID_RECORD_AUDIO_PERMISSION, has_permission])

func _ensure_android_microphone_permission(request_if_missing: bool) -> bool:
	if not OS.has_feature("android"):
		return true

	var granted_permissions: PackedStringArray = OS.get_granted_permissions()
	if granted_permissions.has(ANDROID_RECORD_AUDIO_PERMISSION):
		return true
	if not request_if_missing:
		return false

	var granted_now: bool = OS.request_permission(ANDROID_RECORD_AUDIO_PERMISSION)
	print("OversightVoiceBridge: request_permission(%s) -> %s" % [ANDROID_RECORD_AUDIO_PERMISSION, granted_now])
	if granted_now:
		return true

	_emit_fail("Quest microphone permission denied. Open headset Settings > Apps > Ada Research Zero One > Permissions and enable Microphone.")
	return false

func _estimate_wav_peak(bytes: PackedByteArray) -> float:
	if bytes.size() < 44:
		return 0.0

	var bits_per_sample := _read_u16_le(bytes, 34)
	if bits_per_sample != 16:
		return 0.0

	var data_size := _read_u32_le(bytes, 40)
	var data_offset := 44
	var available := bytes.size() - data_offset
	if available <= 0:
		return 0.0
	var usable: int = min(data_size, available)
	var sample_count: int = int(usable / 2)
	if sample_count <= 0:
		return 0.0

	# Sample up to 20k points for a fast silence estimate.
	var step: int = max(1, int(sample_count / 20000))
	var peak: float = 0.0
	for i in range(0, sample_count, step):
		var byte_index := data_offset + i * 2
		if byte_index + 1 >= bytes.size():
			break
		var sample: int = _read_s16_le(bytes, byte_index)
		var amp: float = abs(float(sample) / 32768.0)
		if amp > peak:
			peak = amp
	return peak

func _read_u16_le(bytes: PackedByteArray, index: int) -> int:
	if index + 1 >= bytes.size():
		return 0
	return int(bytes[index]) | (int(bytes[index + 1]) << 8)

func _read_u32_le(bytes: PackedByteArray, index: int) -> int:
	if index + 3 >= bytes.size():
		return 0
	return int(bytes[index]) | (int(bytes[index + 1]) << 8) | (int(bytes[index + 2]) << 16) | (int(bytes[index + 3]) << 24)

func _read_s16_le(bytes: PackedByteArray, index: int) -> int:
	var value := _read_u16_le(bytes, index)
	if value >= 32768:
		value -= 65536
	return value

func _http_result_name(result: int) -> String:
	match result:
		0:
			return "SUCCESS"
		1:
			return "CHUNKED_BODY_SIZE_MISMATCH"
		2:
			return "CANT_CONNECT"
		3:
			return "CANT_RESOLVE"
		4:
			return "CONNECTION_ERROR"
		5:
			return "TLS_HANDSHAKE_ERROR"
		6:
			return "NO_RESPONSE"
		7:
			return "BODY_SIZE_LIMIT_EXCEEDED"
		8:
			return "BODY_DECOMPRESS_FAILED"
		9:
			return "REQUEST_FAILED"
		10:
			return "DOWNLOAD_FILE_CANT_OPEN"
		11:
			return "DOWNLOAD_FILE_WRITE_ERROR"
		12:
			return "REDIRECT_LIMIT_REACHED"
		13:
			return "TIMEOUT"
		_:
			return "UNKNOWN"
