extends Node

@export var enabled: bool = true
@export var oversight_base_url: String = "http://localhost:3001"
@export var voice_endpoint: String = "/api/voice"
@export var push_to_talk_action: StringName = &"oversight_push_to_talk"
@export var secondary_push_to_talk_action: StringName = &"vr_button_a"
@export var default_mode: String = "auto" # auto | retry | create
@export var include_memories: bool = true
@export var include_last_output: bool = true
@export var auto_resume_queue: bool = false
@export var default_priority: String = "high"
@export var create_title_prefix: String = "Voice Debug"
@export var scene_hint: String = ""
@export var min_recording_seconds: float = 0.25
@export var max_recording_seconds: float = 20.0

const RECORD_BUS_NAME := "OversightMicCapture"
const RECORD_FILE_PATH := "user://oversight_voice/latest_debug.wav"

signal voice_recording_started()
signal voice_recording_stopped(duration_seconds: float)
signal voice_dispatch_succeeded(response: Dictionary)
signal voice_dispatch_failed(message: String)

var _record_effect: AudioEffectRecord
var _mic_player: AudioStreamPlayer
var _is_recording := false
var _record_start_msec := 0

func _ready() -> void:
	_ensure_input_action()
	_setup_recording_pipeline()

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return

	if _is_push_to_talk_pressed(event):
		_start_recording()
		return

	if _is_push_to_talk_released(event):
		_stop_and_dispatch()

func _process(_delta: float) -> void:
	if not _is_recording:
		return

	if max_recording_seconds <= 0:
		return

	var elapsed_sec := float(Time.get_ticks_msec() - _record_start_msec) / 1000.0
	if elapsed_sec >= max_recording_seconds:
		_stop_and_dispatch()

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
	return false

func _is_push_to_talk_released(event: InputEvent) -> bool:
	if event.is_action_released(push_to_talk_action):
		return true
	if secondary_push_to_talk_action != &"" and event.is_action_released(secondary_push_to_talk_action):
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

func _setup_recording_pipeline() -> void:
	var bus_index := _ensure_record_bus()
	_record_effect = _find_or_add_record_effect(bus_index)

	_mic_player = AudioStreamPlayer.new()
	_mic_player.name = "OversightMicPlayer"
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = RECORD_BUS_NAME
	_mic_player.volume_db = 0.0
	add_child(_mic_player)

func _ensure_record_bus() -> int:
	var idx := AudioServer.get_bus_index(RECORD_BUS_NAME)
	if idx != -1:
		return idx

	AudioServer.add_bus(AudioServer.bus_count)
	idx = AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, RECORD_BUS_NAME)
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

	_record_start_msec = Time.get_ticks_msec()
	_is_recording = true

	_mic_player.play()
	_record_effect.set_recording_active(true)
	emit_signal("voice_recording_started")
	print("OversightVoiceBridge: recording started")

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

	if duration_sec < min_recording_seconds:
		print("OversightVoiceBridge: recording ignored (%.2fs < %.2fs)" % [duration_sec, min_recording_seconds])
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

	var file := FileAccess.open(RECORD_FILE_PATH, FileAccess.READ)
	if file == null:
		_emit_fail("Failed to open saved recording")
		return
	var data := file.get_buffer(file.get_length())
	file.close()
	if data.is_empty():
		_emit_fail("Recording file is empty")
		return

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

func _send_payload(payload: Dictionary) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed.bind(http))

	var url := "%s%s" % [oversight_base_url.trim_suffix("/"), voice_endpoint]
	var headers := PackedStringArray(["Content-Type: application/json"])
	var body := JSON.stringify(payload)

	var err := http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()
		_emit_fail("Voice request failed to start: %s" % error_string(err))
		return

	print("OversightVoiceBridge: sent voice payload to %s" % url)

func _on_request_completed(
	result: int,
	response_code: int,
	_headers: PackedStringArray,
	body: PackedByteArray,
	http: HTTPRequest
) -> void:
	http.queue_free()

	if result != HTTPRequest.RESULT_SUCCESS:
		_emit_fail("Voice request transport error: %d" % result)
		return

	var text := body.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if response_code < 200 or response_code >= 300:
		var err_text := text if not text.is_empty() else "HTTP %d" % response_code
		_emit_fail(err_text)
		return

	if parsed is Dictionary:
		emit_signal("voice_dispatch_succeeded", parsed as Dictionary)
	else:
		emit_signal("voice_dispatch_succeeded", {"raw": text})

	print("OversightVoiceBridge: dispatch complete (%d)" % response_code)

func _emit_fail(message: String) -> void:
	push_warning("OversightVoiceBridge: %s" % message)
	emit_signal("voice_dispatch_failed", message)
