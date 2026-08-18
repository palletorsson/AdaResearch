extends Node

## Claude-VR Bridge + Wrist Console
## Unified left-hand display: stats (map, XP, health) + Claude message board.
## Claude writes outbox.json via adb push → Godot polls + displays on left hand.
## User presses X button to confirm → Godot writes inbox.json → Claude pulls via adb.
## Screenshots via: adb shell "screencap -p /sdcard/claude_bridge/screen.png"

@export var enabled: bool = false  # disabled 2026-06-03: left-hand console + voice push-to-talk on by_button (B) collided with the catalyst's B-to-save. Set true (+ re-add the autoload) to restore.
@export var poll_interval: float = 1.0
@export var confirm_button_name: String = "ax_button"
@export var panel_font_size: int = 36
@export var panel_pixel_size: float = 0.0008
@export var panel_width: int = 700
@export var show_stats: bool = true
@export var hide_right_wrist_display: bool = false

## Voice recording — push-to-talk on right hand B button
@export var voice_enabled: bool = true
@export var voice_button_name: String = "by_button"
@export var voice_tracker: String = "right_hand"
@export var voice_min_seconds: float = 0.3
@export var voice_max_seconds: float = 20.0
@export var voice_silence_threshold: float = 0.00001

const BRIDGE_SUBDIR := "claude_bridge"
const BRIDGE_DIR_DESKTOP := "user://claude_bridge/"
const OUTBOX_FILE := "outbox.json"
const INBOX_FILE := "inbox.json"
const VOICE_FILE := "voice.wav"
const VOICE_READY_FILE := "voice_ready.json"
const VOICE_BUS_NAME := "ClaudeBridgeMic"

signal claude_message_received(text: String)
signal user_response_sent(text: String)
signal voice_recorded(wav_path: String)

var _bridge_dir: String
var _last_message_id: int = -1
var _current_message: String = ""
var _message_history: Array[String] = []
const MAX_CONSOLE_MESSAGES := 8
var _panel: Label3D
var _background: MeshInstance3D
var _accent_line: MeshInstance3D
var _poll_timer: Timer
var _left_controller: XRController3D
var _right_controller: XRController3D
var _panel_setup_done := false
var _confirm_connected := false
var _voice_connected := false
var _stats_dirty := true
var _cached_map: String = ""
var _cached_xp: int = 0
var _cached_health_pct: float = 100.0

# Voice recording state
var _record_effect: AudioEffectRecord
var _mic_player: AudioStreamPlayer
var _is_recording := false
var _record_start_msec: int = 0
var _last_voice_tick: int = -1


func _ready() -> void:
	# Capture mode — caller passes `--no-bridges` to silence HTTP / fs
	# chatter during screenshots. Same flag honored by OversightVoiceBridge.
	if "--no-bridges" in OS.get_cmdline_user_args() or "--no-bridges" in OS.get_cmdline_args():
		enabled = false
		print("ClaudeBridge: disabled by --no-bridges")
		return

	if not enabled:
		return

	# Determine bridge directory based on platform
	if OS.has_feature("android"):
		_bridge_dir = "/sdcard/claude_bridge/"
		var alt_dir := "/sdcard/Android/data/%s/files/%s/" % [_get_package_name(), BRIDGE_SUBDIR]
		if not _test_file_access(_bridge_dir):
			_bridge_dir = alt_dir
			if not _test_file_access(_bridge_dir):
				_bridge_dir = BRIDGE_DIR_DESKTOP
				print("ClaudeBridge: WARNING — falling back to user://")
	else:
		_bridge_dir = BRIDGE_DIR_DESKTOP

	_ensure_bridge_dir()

	# Polling timer for outbox
	_poll_timer = Timer.new()
	_poll_timer.wait_time = poll_interval
	_poll_timer.timeout.connect(_poll_outbox)
	add_child(_poll_timer)
	_poll_timer.start()

	# Connect to GameManager for stats
	if show_stats:
		call_deferred("_connect_stats_signals")

	call_deferred("_setup_panel")
	call_deferred("_connect_confirm_button")
	if hide_right_wrist_display:
		call_deferred("_hide_right_wrist_display")

	# Voice recording pipeline
	if voice_enabled:
		_setup_voice_pipeline()
		call_deferred("_connect_voice_button")

	print("ClaudeBridge: ready (dir=%s, voice=%s)" % [_bridge_dir, voice_enabled])


# ── Path helpers ────────────────────────────────────────────────────

func _ensure_bridge_dir() -> void:
	if _bridge_dir.begins_with("user://"):
		var dir := DirAccess.open("user://")
		if dir and not dir.dir_exists(BRIDGE_SUBDIR):
			dir.make_dir(BRIDGE_SUBDIR)
	else:
		DirAccess.make_dir_recursive_absolute(_bridge_dir)
	print("ClaudeBridge: dir=%s" % _bridge_dir)


func _test_file_access(dir_path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(dir_path)
	var test_path := dir_path + "_bridge_test.tmp"
	var f := FileAccess.open(test_path, FileAccess.WRITE)
	if f == null:
		print("ClaudeBridge: cannot write to %s (error: %s)" % [dir_path, error_string(FileAccess.get_open_error())])
		return false
	f.store_string("ok")
	f.close()
	var r := FileAccess.open(test_path, FileAccess.READ)
	if r == null:
		return false
	r.close()
	DirAccess.remove_absolute(test_path)
	print("ClaudeBridge: path OK: %s" % dir_path)
	return true


func _get_package_name() -> String:
	var data_dir := OS.get_user_data_dir()
	var parts := data_dir.split("/")
	for i in range(parts.size()):
		if parts[i] == "data" and i + 1 < parts.size() and parts[i + 1] == "data" and i + 2 < parts.size():
			return parts[i + 2]
	for part in parts:
		if part.count(".") >= 2 and part.begins_with("com."):
			return part
	return "com.example.adaresearchzeroone"


# ── Stats integration ───────────────────────────────────────────────

func _connect_stats_signals() -> void:
	if not GameManager:
		return
	GameManager.score_updated.connect(_on_stats_changed)
	GameManager.health_updated.connect(_on_stats_changed)
	GameManager.current_map_changed.connect(_on_map_changed)
	# Initial values
	_cached_map = GameManager.get_current_map().replace("_", " ").get_file()
	_cached_xp = GameManager.get_score()
	var max_hp: float = GameManager.max_player_health
	_cached_health_pct = (GameManager.get_health() / max_hp * 100.0) if max_hp > 0 else 100.0
	_stats_dirty = true
	print("ClaudeBridge: stats connected (map=%s xp=%d hp=%.0f%%)" % [_cached_map, _cached_xp, _cached_health_pct])


func _on_stats_changed(_value = null) -> void:
	if GameManager:
		_cached_xp = GameManager.get_score()
		var max_hp: float = GameManager.max_player_health
		_cached_health_pct = (GameManager.get_health() / max_hp * 100.0) if max_hp > 0 else 100.0
		_stats_dirty = true


func _on_map_changed(map_name = null) -> void:
	if map_name is String:
		_cached_map = map_name.replace("_", " ").get_file()
	elif GameManager:
		_cached_map = GameManager.get_current_map().replace("_", " ").get_file()
	_stats_dirty = true


func _get_health_bar(pct: float) -> String:
	var filled: int = int(pct / 10.0)
	var empty: int = 10 - filled
	return "█".repeat(filled) + "░".repeat(empty)


func _hide_right_wrist_display() -> void:
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var xr_origin := scene.find_child("XROrigin3D", true, false)
	if xr_origin == null:
		return
	for name in ["RightHandController", "RightController", "RightHand"]:
		var hand := xr_origin.find_child(name, true, false)
		if hand:
			var wrist := hand.find_child("WristStatsDisplay", true, false)
			if wrist:
				wrist.visible = false
				print("ClaudeBridge: hid WristStatsDisplay on %s" % name)
				return


# ── Hand panel ──────────────────────────────────────────────────────

func _setup_panel() -> void:
	if _panel_setup_done:
		return

	var left_hand := _find_left_hand()
	if left_hand == null:
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(2.0).timeout
		_setup_panel()
		return

	var existing := left_hand.get_node_or_null("ClaudeConsole") as Label3D
	if existing:
		_panel = existing
		_background = _panel.get_node_or_null("ConsoleBG") as MeshInstance3D
		_accent_line = _panel.get_node_or_null("AccentLine") as MeshInstance3D
		_panel_setup_done = true
		_refresh_display()
		return

	# Main text label
	_panel = Label3D.new()
	_panel.name = "ClaudeConsole"
	_panel.position = Vector3(-0.02, 0.08, 0.05)
	_panel.rotation_degrees = Vector3(-35, 0, 0)
	_panel.scale = Vector3(0.35, 0.35, 0.35)
	_panel.pixel_size = panel_pixel_size
	_panel.font_size = panel_font_size
	_panel.modulate = Color(0.85, 0.92, 1.0, 0.95)
	_panel.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
	_panel.outline_size = 5
	_panel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_panel.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_panel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel.width = panel_width
	_panel.no_depth_test = true
	_panel.visible = true
	left_hand.add_child(_panel)

	# Dark background panel
	_background = MeshInstance3D.new()
	_background.name = "ConsoleBG"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.6, 0.25)
	_background.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.015, 0.025, 0.06, 0.88)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_background.material_override = mat
	_background.position.z = 0.001
	_panel.add_child(_background)

	# Cyan accent line at top
	_accent_line = MeshInstance3D.new()
	_accent_line.name = "AccentLine"
	var line_quad := QuadMesh.new()
	line_quad.size = Vector2(0.6, 0.003)
	_accent_line.mesh = line_quad
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(0.2, 0.7, 1.0, 0.9)
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_accent_line.material_override = line_mat
	_accent_line.position.z = 0.0005
	_panel.add_child(_accent_line)

	_panel_setup_done = true
	_refresh_display()
	print("ClaudeBridge: console attached to %s" % left_hand.name)


func _find_left_hand() -> Node3D:
	# Search the ENTIRE scene tree — staging and loaded scenes each have
	# their own XROrigin3D. We want the deepest one (loaded scene's controller
	# tracks the actual hand, staging's may be inactive).
	var root := get_tree().root
	var candidates: Array[Node3D] = []
	_collect_left_hands(root, candidates)
	if candidates.is_empty():
		return null
	# Last found = deepest in tree = loaded scene's controller
	var picked: Node3D = candidates.back() as Node3D
	if candidates.size() > 1:
		print("ClaudeBridge: found %d left hands, using %s (path: %s)" % [
			candidates.size(), picked.name, picked.get_path()])
	return picked


func _collect_left_hands(node: Node, out: Array[Node3D]) -> void:
	if node is Node3D:
		var n := node.name
		if n == "LeftHandController" or n == "LeftController" or n == "LeftHand":
			out.append(node as Node3D)
			return
	for child in node.get_children():
		_collect_left_hands(child, out)


var _reattach_timer: float = 0.0

func _process(delta: float) -> void:
	# Check if panel was freed (scene destroyed)
	if _panel_setup_done and not is_instance_valid(_panel):
		_reattach()
		return

	# Periodic check: is our panel still on the CURRENT scene's left hand?
	# XRToolsStaging may swap scenes, creating a new LeftHandController
	_reattach_timer += delta
	if _reattach_timer >= 2.0:
		_reattach_timer = 0.0
		if _panel_setup_done and is_instance_valid(_panel):
			var current_left := _find_left_hand()
			if current_left != null and _panel.get_parent() != current_left:
				# Panel is on wrong controller — remove old and reattach
				print("ClaudeBridge: controller changed (%s → %s) — re-attaching" % [
					_panel.get_parent().name if _panel.get_parent() else "null",
					current_left.name])
				_panel.get_parent().remove_child(_panel)
				_panel.queue_free()
				_reattach()
				return
			elif not _panel.is_inside_tree():
				_reattach()
				return

	# Voice: update elapsed time display + enforce max duration
	if _is_recording:
		var elapsed := float(Time.get_ticks_msec() - _record_start_msec) / 1000.0
		if voice_max_seconds > 0 and elapsed >= voice_max_seconds:
			_stop_voice_recording()
		elif is_instance_valid(_panel) and int(elapsed * 2) != _last_voice_tick:
			# Update display every 0.5s
			_last_voice_tick = int(elapsed * 2)
			_refresh_display_with_voice(elapsed)

	if _stats_dirty and is_instance_valid(_panel):
		_stats_dirty = false
		_refresh_display()


func _reattach() -> void:
	_panel_setup_done = false
	_confirm_connected = false
	_voice_connected = false
	_panel = null
	_background = null
	_accent_line = null
	_left_controller = null
	_right_controller = null
	call_deferred("_setup_panel")
	call_deferred("_connect_confirm_button")
	if hide_right_wrist_display:
		call_deferred("_hide_right_wrist_display")
	if voice_enabled:
		call_deferred("_connect_voice_button")
	print("ClaudeBridge: re-attaching console")


func _refresh_display() -> void:
	if not _panel:
		return

	var lines: PackedStringArray = []

	# Stats header
	if show_stats:
		var map_display := _cached_map if not _cached_map.is_empty() else "---"
		var health_bar := _get_health_bar(_cached_health_pct)
		lines.append("%s  |  %d XP  |  %s %.0f%%" % [map_display, _cached_xp, health_bar, _cached_health_pct])
		lines.append("───────────────────────────")

	# Claude messages (show history, max 8)
	if _message_history.size() > 0:
		lines.append("Claude:")
		for msg in _message_history:
			lines.append(msg)
	else:
		lines.append("Claude: [awaiting]")

	_panel.text = "\n".join(lines)
	_update_background()


func _update_background() -> void:
	if not _background or not _panel:
		return
	var char_w: float = _panel.pixel_size * _panel.font_size * 0.42
	var line_h: float = _panel.pixel_size * _panel.font_size * 1.3
	var max_w: float = _panel.width * _panel.pixel_size if _panel.width > 0 else 0.55
	var num_lines: int = max(4, ceili(_panel.text.length() * char_w / max_w))
	var text_h: float = num_lines * line_h
	var pad := Vector2(0.018, 0.012)
	var bg_w: float = max_w + pad.x * 2
	var bg_h: float = text_h + pad.y * 2
	var quad := _background.mesh as QuadMesh
	if quad:
		quad.size = Vector2(bg_w, bg_h)
	_background.position.x = bg_w / 2.0 - pad.x
	_background.position.y = -bg_h / 2.0 + pad.y
	# Accent line at top edge
	if _accent_line:
		var lq := _accent_line.mesh as QuadMesh
		if lq:
			lq.size.x = bg_w
		_accent_line.position.x = _background.position.x
		_accent_line.position.y = _background.position.y + bg_h / 2.0


# ── Confirm button ──────────────────────────────────────────────────

func _connect_confirm_button() -> void:
	if _confirm_connected:
		return
	var left := _find_left_hand()
	if left == null or not (left is XRController3D):
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(2.0).timeout
		_connect_confirm_button()
		return
	var controller := left as XRController3D
	if controller.has_signal("button_pressed"):
		controller.button_pressed.connect(_on_left_button_pressed)
		_left_controller = controller
		_confirm_connected = true
		print("ClaudeBridge: confirm on %s (button=%s)" % [controller.name, confirm_button_name])


func _on_left_button_pressed(button: String) -> void:
	if not enabled or button != confirm_button_name or _current_message.is_empty():
		return
	_send_confirm("done")


# ── File polling ────────────────────────────────────────────────────

var _poll_debug_count: int = 0

func _poll_outbox() -> void:
	if not enabled:
		return

	var outbox_path := _bridge_dir + OUTBOX_FILE
	_poll_debug_count += 1

	if _poll_debug_count % 10 == 1:
		var exists := FileAccess.file_exists(outbox_path)
		print("ClaudeBridge: poll #%d exists=%s" % [_poll_debug_count, exists])

	if not FileAccess.file_exists(outbox_path):
		return

	var f := FileAccess.open(outbox_path, FileAccess.READ)
	if f == null:
		print("ClaudeBridge: can't open outbox (err=%s)" % error_string(FileAccess.get_open_error()))
		return
	var content := f.get_as_text()
	f.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		return

	var data: Dictionary = json.data if json.data is Dictionary else {}
	var msg_id: int = int(data.get("id", -1))
	if msg_id <= _last_message_id:
		return

	_last_message_id = msg_id
	_current_message = str(data.get("text", ""))
	var ts := Time.get_time_string_from_system().substr(0, 5)  # "HH:MM"
	_message_history.append("[%s] %s" % [ts, _current_message])
	if _message_history.size() > MAX_CONSOLE_MESSAGES:
		_message_history = _message_history.slice(-MAX_CONSOLE_MESSAGES)
	_refresh_display()

	print("ClaudeBridge: message #%d → %s" % [msg_id, _current_message.substr(0, 80)])
	claude_message_received.emit(_current_message)


func _send_confirm(response_text: String = "done") -> void:
	var inbox_path := _bridge_dir + INBOX_FILE
	var payload := {
		"id": _last_message_id,
		"text": response_text,
		"timestamp": Time.get_datetime_string_from_system(true),
	}
	var f := FileAccess.open(inbox_path, FileAccess.WRITE)
	if f == null:
		push_warning("ClaudeBridge: failed to write inbox at %s" % inbox_path)
		return
	f.store_string(JSON.stringify(payload))
	f.close()
	print("ClaudeBridge: confirmed #%d" % _last_message_id)

	# Green flash
	if _panel:
		var original_color := _panel.modulate
		_panel.modulate = Color(0.4, 1.0, 0.4, 1.0)
		await get_tree().create_timer(0.5).timeout
		_panel.modulate = original_color

	user_response_sent.emit(response_text)


# ── Voice recording ─────────────────────────────────────────────────

func _setup_voice_pipeline() -> void:
	# Audio bus with record effect
	var bus_idx := AudioServer.get_bus_index(VOICE_BUS_NAME)
	if bus_idx == -1:
		AudioServer.add_bus(AudioServer.bus_count)
		bus_idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus_idx, VOICE_BUS_NAME)
	AudioServer.set_bus_mute(bus_idx, false)

	# Find or add record effect
	_record_effect = null
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var fx := AudioServer.get_bus_effect(bus_idx, i)
		if fx is AudioEffectRecord:
			_record_effect = fx as AudioEffectRecord
			break
	if _record_effect == null:
		_record_effect = AudioEffectRecord.new()
		AudioServer.add_bus_effect(bus_idx, _record_effect, 0)

	# Mic player routed to our bus
	_mic_player = AudioStreamPlayer.new()
	_mic_player.name = "ClaudeMicPlayer"
	_mic_player.stream = AudioStreamMicrophone.new()
	_mic_player.bus = VOICE_BUS_NAME
	_mic_player.volume_db = 0.0
	add_child(_mic_player)
	print("ClaudeBridge: voice pipeline ready (bus=%s)" % VOICE_BUS_NAME)


func _connect_voice_button() -> void:
	if _voice_connected:
		return
	# Find the right hand controller for B button
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	var root := get_tree().root
	var candidates: Array[Node3D] = []
	_collect_controllers(root, ["RightHandController", "RightController", "RightHand"], candidates)
	if candidates.is_empty():
		# out-of-tree guard: get_tree() is null once a map is torn down
		if not is_inside_tree():
			await tree_entered
		await get_tree().create_timer(2.0).timeout
		_connect_voice_button()
		return
	var picked: Node3D = candidates.back() as Node3D
	if picked is XRController3D:
		var ctrl := picked as XRController3D
		ctrl.button_pressed.connect(_on_voice_button_pressed)
		ctrl.button_released.connect(_on_voice_button_released)
		_right_controller = ctrl
		_voice_connected = true
		print("ClaudeBridge: voice button on %s (B=%s tracker=%s)" % [ctrl.name, voice_button_name, voice_tracker])


func _collect_controllers(node: Node, names: Array, out: Array[Node3D]) -> void:
	if node is Node3D:
		var n := node.name
		for candidate_name in names:
			if n == candidate_name:
				out.append(node as Node3D)
				return
	for child in node.get_children():
		_collect_controllers(child, names, out)


func _on_voice_button_pressed(button: String) -> void:
	if not voice_enabled or not enabled:
		return
	if button != voice_button_name:
		return
	# Check tracker matches (right hand only)
	if voice_tracker != "" and _right_controller != null:
		if String(_right_controller.tracker) != voice_tracker:
			return
	_start_voice_recording()


func _on_voice_button_released(button: String) -> void:
	if not voice_enabled or not enabled:
		return
	if button != voice_button_name:
		return
	if _is_recording:
		_stop_voice_recording()


func _start_voice_recording() -> void:
	if _is_recording or _record_effect == null:
		return
	# Request mic permission on Android
	if OS.has_feature("android"):
		var perms := OS.get_granted_permissions()
		if not perms.has("android.permission.RECORD_AUDIO"):
			OS.request_permission("android.permission.RECORD_AUDIO")
			print("ClaudeBridge: requesting mic permission")
			return

	_record_start_msec = Time.get_ticks_msec()
	_last_voice_tick = -1
	_is_recording = true
	_mic_player.play()
	_record_effect.set_recording_active(true)
	_refresh_display_with_voice(0.0)
	print("ClaudeBridge: recording started")


func _stop_voice_recording() -> void:
	if not _is_recording or _record_effect == null:
		return
	_record_effect.set_recording_active(false)
	_mic_player.stop()
	_is_recording = false

	var duration_sec := float(Time.get_ticks_msec() - _record_start_msec) / 1000.0
	print("ClaudeBridge: recording stopped (%.2fs)" % duration_sec)
	# Restore panel color from recording orange
	if is_instance_valid(_panel):
		_panel.modulate = Color(0.85, 0.92, 1.0, 0.95)

	if duration_sec < voice_min_seconds:
		_show_voice_status("Too short")
		return

	var stream := _record_effect.get_recording()
	if stream == null or not (stream is AudioStreamWAV):
		_show_voice_status("No audio")
		return

	# Save WAV to bridge directory
	var wav := stream as AudioStreamWAV
	var wav_path := _bridge_dir + VOICE_FILE
	var err := wav.save_to_wav(wav_path)
	if err != OK:
		_show_voice_status("Save failed")
		print("ClaudeBridge: WAV save error: %s" % error_string(err))
		return

	# Check for silence
	var f := FileAccess.open(wav_path, FileAccess.READ)
	if f == null:
		return
	var data := f.get_buffer(f.get_length())
	f.close()
	var peak := _estimate_wav_peak(data)
	if peak <= voice_silence_threshold:
		_show_voice_status("Silent")
		print("ClaudeBridge: audio silent (peak=%.6f)" % peak)
		return

	# Write voice_ready flag for Claude to pull
	var ready_path := _bridge_dir + VOICE_READY_FILE
	var payload := {
		"id": _last_message_id,
		"status": "ready",
		"duration": snappedf(duration_sec, 0.01),
		"bytes": data.size(),
		"timestamp": Time.get_datetime_string_from_system(true),
	}
	var rf := FileAccess.open(ready_path, FileAccess.WRITE)
	if rf:
		rf.store_string(JSON.stringify(payload))
		rf.close()

	_show_voice_status("Recorded %.1fs" % duration_sec)
	print("ClaudeBridge: voice saved %s (%d bytes, peak=%.4f)" % [wav_path, data.size(), peak])
	voice_recorded.emit(wav_path)


func _refresh_display_with_voice(elapsed: float) -> void:
	if not is_instance_valid(_panel):
		return
	var lines: PackedStringArray = []
	if show_stats:
		var map_display := _cached_map if not _cached_map.is_empty() else "---"
		var health_bar := _get_health_bar(_cached_health_pct)
		lines.append("%s  |  %d XP  |  %s %.0f%%" % [map_display, _cached_xp, health_bar, _cached_health_pct])
		lines.append("───────────────────────────")
	if _message_history.size() > 0:
		lines.append("Claude:")
		for msg in _message_history:
			lines.append(msg)
	else:
		lines.append("Claude: [awaiting]")
	lines.append("Recording... %ds" % int(elapsed))
	_panel.text = "\n".join(lines)
	_panel.modulate = Color(1.0, 0.6, 0.3, 0.95)
	_update_background()


func _show_voice_status(msg: String) -> void:
	# Temporarily show voice status on the console panel
	if not is_instance_valid(_panel):
		return
	var old_text := _panel.text
	var old_color := _panel.modulate
	_panel.text = old_text + "\n[voice: %s]" % msg
	_panel.modulate = Color(1.0, 0.6, 0.3, 1.0) if msg == "REC..." else Color(0.4, 1.0, 0.6, 1.0)
	# Restore after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(_panel):
		_panel.modulate = old_color
		_refresh_display()


func _estimate_wav_peak(bytes: PackedByteArray) -> float:
	if bytes.size() < 44:
		return 0.0
	var bits_per_sample := (int(bytes[35]) << 8) | int(bytes[34])
	if bits_per_sample != 16:
		return 0.0
	var data_offset := 44
	var available := bytes.size() - data_offset
	if available <= 0:
		return 0.0
	var sample_count: int = available / 2
	var step: int = max(1, sample_count / 20000)
	var peak: float = 0.0
	for i in range(0, sample_count, step):
		var idx := data_offset + i * 2
		if idx + 1 >= bytes.size():
			break
		var lo := int(bytes[idx])
		var hi := int(bytes[idx + 1])
		var sample := lo | (hi << 8)
		if sample >= 32768:
			sample -= 65536
		var amp := absf(float(sample) / 32768.0)
		if amp > peak:
			peak = amp
	return peak


# ── Public API ──────────────────────────────────────────────────────

func show_message(text: String) -> void:
	_current_message = text
	_refresh_display()


func hide_panel() -> void:
	if _panel:
		_panel.visible = false
	_current_message = ""
