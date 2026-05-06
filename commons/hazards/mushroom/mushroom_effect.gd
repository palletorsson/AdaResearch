# mushroom_effect.gd
# Manages post-processing effects when the player eats a mushroom.
#
# Usage:
#   var effect = MushroomEffect.new()
#   scene.add_child(effect)
#   effect.trigger_with_shader("res://path/to/shader.gdshader", 10.0)
#
# Each mushroom can trigger a different shader. Eating another mushroom
# while one is active replaces the current effect with the new one.
# Effects wear off after the specified duration (default 10 sec).
#
# Dual overlay mode:
#   Desktop: CanvasLayer + ColorRect with canvas_item shader
#   VR:      MeshInstance3D (QuadMesh) attached to XRCamera3D with spatial shader
#
# VR uses pre-made _spatial.gdshader versions (no runtime conversion).
# Creates audio bus effects (reverb, chorus) for sound modulation.
extends Node3D
class_name MushroomEffect

# ── Configuration ─────────────────────────────────────────────────────────
@export var fade_in_duration: float = 1.0      ## How long to ramp up
@export var fade_out_duration: float = 2.5     ## How long to fade away
@export var max_intensity: float = 0.8         ## Maximum shader intensity

# ── State ─────────────────────────────────────────────────────────────────
var _intensity: float = 0.0
var _target_intensity: float = 0.0
var _time_remaining: float = 0.0
var _phase: int = 0  # 0=idle, 1=fade_in, 2=peak, 3=fade_out
var _current_shader_path: String = ""
var _is_vr: bool = false

# ── Visual (Desktop mode) ────────────────────────────────────────────────
var _canvas_layer: CanvasLayer = null
var _color_rect: ColorRect = null
var _shader_mat: ShaderMaterial = null

# ── Visual (VR mode) ─────────────────────────────────────────────────────
var _vr_quad: MeshInstance3D = null
var _xr_camera: Camera3D = null

# ── Audio ─────────────────────────────────────────────────────────────────
var _audio_bus_name: String = "MushroomTrip"
var _audio_bus_idx: int = -1
var _eat_player: AudioStreamPlayer = null
var _ambient_player: AudioStreamPlayer = null

# ── Signals ───────────────────────────────────────────────────────────────
signal trip_started()
signal trip_ended()
signal intensity_changed(value: float)

func _ready() -> void:
	_detect_vr()
	_setup_audio_bus()
	_setup_eat_sound()
	_setup_ambient_sound()
	print("[MushroomEffect] Ready — mode: %s" % ("VR" if _is_vr else "Desktop"))

func _detect_vr() -> void:
	# Search the ENTIRE tree from root — in VR the XRCamera3D lives in the
	# staging tree above current_scene (VRStaging → Base2 → XROrigin3D → XRCamera3D).
	var root: Node = get_tree().root
	var cam: Node = root.find_child("XRCamera3D", true, false)
	if cam and cam is Camera3D:
		_is_vr = true
		_xr_camera = cam as Camera3D
		return

	# Also check "player" group as fallback
	var xr_origin: Node = get_tree().get_first_node_in_group("player")
	if xr_origin != null:
		_is_vr = true
		for child in xr_origin.get_children():
			if child is Camera3D and child.name.containsn("XRCamera"):
				_xr_camera = child as Camera3D
				return

func _process(delta: float) -> void:
	if _phase == 0:
		return

	match _phase:
		1:  # Fade in
			_intensity = move_toward(_intensity, _target_intensity, delta / fade_in_duration * _target_intensity)
			if _intensity >= _target_intensity - 0.01:
				_intensity = _target_intensity
				_phase = 2
		2:  # Peak — hold intensity, count down
			_time_remaining -= delta
			if _time_remaining <= 0.0:
				_phase = 3
		3:  # Fade out
			_intensity = move_toward(_intensity, 0.0, delta / fade_out_duration * _target_intensity)
			if _intensity <= 0.01:
				_intensity = 0.0
				_phase = 0
				_target_intensity = 0.0
				_current_shader_path = ""
				trip_ended.emit()

	_apply_intensity(_intensity)
	intensity_changed.emit(_intensity)

# ═══════════════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════════════

## Trigger with a specific shader and duration. Each mushroom type calls this
## with its own shader path. Eating a new mushroom replaces the current effect.
func trigger_with_shader(shader_path: String, duration: float = 10.0) -> void:
	_target_intensity = max_intensity
	_time_remaining = duration

	# Load the new shader (may be different from current)
	var need_new_shader: bool = (shader_path != _current_shader_path) or _shader_mat == null
	_current_shader_path = shader_path

	_ensure_overlay()

	if need_new_shader and shader_path != "":
		_load_shader(shader_path)

	if _phase == 0:
		# Fresh effect
		_phase = 1
		trip_started.emit()
		print("[MushroomEffect] Effect started — %s, %.0fs (%s)" % [
			shader_path.get_file(), duration, "VR" if _is_vr else "Desktop"])
	else:
		# Already active — replace shader, reset timer
		print("[MushroomEffect] Effect replaced — %s, %.0fs" % [shader_path.get_file(), duration])

	# Play eat sound
	if _eat_player:
		_eat_player.play()

	# Start ambient drone
	if _ambient_player and not _ambient_player.playing:
		_ambient_player.play()

## Legacy trigger — uses mushroom_trip.gdshader with 10 sec duration
func trigger() -> void:
	trigger_with_shader("res://commons/resourses/shaders/mushroom_trip.gdshader", 10.0)

func is_tripping() -> bool:
	return _phase > 0

func get_intensity() -> float:
	return _intensity

# ═══════════════════════════════════════════════════════════════════════════
# SHADER LOADING
# ═══════════════════════════════════════════════════════════════════════════

func _load_shader(shader_path: String) -> void:
	var actual_path: String = shader_path

	if _is_vr:
		# VR needs spatial shaders — use the pre-made _spatial.gdshader version
		actual_path = _get_spatial_shader_path(shader_path)

	var shader: Shader = load(actual_path)
	if not shader:
		push_warning("[MushroomEffect] Could not load shader: %s" % actual_path)
		return

	_shader_mat = ShaderMaterial.new()
	_shader_mat.shader = shader
	_shader_mat.set_shader_parameter("intensity", _intensity)
	# Render last (on top of everything) — highest priority
	_shader_mat.render_priority = 127

	if _is_vr:
		if _vr_quad:
			_vr_quad.material_override = _shader_mat
			print("[MushroomEffect] VR quad material_override set: %s" % (
				"OK" if _vr_quad.material_override else "FAILED"))
			print("[MushroomEffect]   shader code mode: %s, render_priority: %s" % [
				shader.get_mode(), _shader_mat.render_priority])
	else:
		if _color_rect:
			_color_rect.material = _shader_mat

	print("[MushroomEffect] Loaded shader: %s (%s)" % [actual_path.get_file(), "VR spatial" if _is_vr else "Desktop"])

	# === VR DIAGNOSTIC: Also load a solid-color test shader to isolate issues ===
	# Set _USE_TEST_SHADER = true below to test if the quad renders at all
	# (bypasses SCREEN_TEXTURE which may be broken on Quest 3).
	var _USE_TEST_SHADER := false  # ← Set to true to test quad visibility without SCREEN_TEXTURE
	if _is_vr and _USE_TEST_SHADER:
		var test_path := "res://commons/resourses/shaders/pp_test_solid_spatial.gdshader"
		var test_shader: Shader = load(test_path)
		if test_shader:
			_shader_mat = ShaderMaterial.new()
			_shader_mat.shader = test_shader
			_shader_mat.set_shader_parameter("intensity", 0.8)
			if _vr_quad:
				_vr_quad.material_override = _shader_mat
			print("[MushroomEffect] *** USING TEST SHADER (solid red) — SCREEN_TEXTURE bypassed ***")

func _get_spatial_shader_path(canvas_path: String) -> String:
	## Map a canvas_item shader path to its pre-made spatial version for VR.
	## e.g. "pp_ripple.gdshader" → "pp_ripple_spatial.gdshader"
	##      "mushroom_trip.gdshader" → "mushroom_trip_spatial.gdshader"
	## If the path already ends with _spatial.gdshader, return as-is.
	if canvas_path.ends_with("_spatial.gdshader"):
		return canvas_path
	var spatial_path: String = canvas_path.replace(".gdshader", "_spatial.gdshader")
	if ResourceLoader.exists(spatial_path):
		return spatial_path
	# Fallback: if no spatial version exists, use the canvas_item shader and hope
	# it works (it won't in VR, but avoids a crash)
	push_warning("[MushroomEffect] No spatial shader found at: %s — falling back to %s" % [spatial_path, canvas_path])
	return canvas_path

# ═══════════════════════════════════════════════════════════════════════════
# VISUAL OVERLAY
# ═══════════════════════════════════════════════════════════════════════════

func _ensure_overlay() -> void:
	if _is_vr:
		_ensure_vr_overlay()
	else:
		_ensure_desktop_overlay()

func _ensure_desktop_overlay() -> void:
	if _canvas_layer and is_instance_valid(_canvas_layer):
		return

	# CanvasLayer renders on top of everything (layer 100 = above UI)
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.name = "MushroomTripLayer"
	_canvas_layer.layer = 100

	# ColorRect fills the entire viewport — the shader reads SCREEN_TEXTURE
	_color_rect = ColorRect.new()
	_color_rect.name = "MushroomTripRect"
	_color_rect.anchors_preset = Control.PRESET_FULL_RECT
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_canvas_layer.add_child(_color_rect)
	add_child(_canvas_layer)
	print("[MushroomEffect] Desktop overlay created (CanvasLayer + ColorRect)")

func _ensure_vr_overlay() -> void:
	if _vr_quad and is_instance_valid(_vr_quad):
		return

	# For VR: attach a fullscreen quad to the XRCamera3D
	# Uses a QuadMesh with a spatial shader that samples SCREEN_TEXTURE
	if not _xr_camera:
		_xr_camera = _find_xr_camera_global()
	if not _xr_camera:
		push_warning("[MushroomEffect] No XRCamera3D found — VR overlay cannot be created")
		# Fallback to desktop overlay
		_is_vr = false
		_ensure_desktop_overlay()
		return

	_vr_quad = MeshInstance3D.new()
	_vr_quad.name = "MushroomEffectQuad"

	# Quad that fills the screen — 2x2 = clip space -1..1.
	# The spatial shader overrides POSITION to fill the screen via VERTEX coords.
	# IMPORTANT: subdivisions needed for PROJECTION_MATRIX offset (inner vertices
	# get the asymmetric FOV correction per official Godot XR docs).
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	quad.subdivide_width = 8
	quad.subdivide_depth = 8
	_vr_quad.mesh = quad

	# Render on top of everything
	_vr_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# CRITICAL: Prevent frustum culling — the CPU doesn't know our vertex shader
	# overrides POSITION, so it tries to cull the quad based on its world AABB.
	# Setting extra_cull_margin to a huge value prevents this.
	_vr_quad.extra_cull_margin = 16384.0

	# Ensure the quad is on all render layers so the XR camera sees it
	_vr_quad.layers = 0xFFFFF  # All 20 visual layers

	# Ensure the quad itself is visible
	_vr_quad.visible = true

	# Add as child of XRCamera3D so it follows the head
	_xr_camera.add_child(_vr_quad)
	print("[MushroomEffect] VR overlay created (QuadMesh 2x2 subdiv=8 on %s)" % _xr_camera.get_path())
	print("[MushroomEffect]   extra_cull_margin=%s layers=%s visible=%s" % [
		_vr_quad.extra_cull_margin, _vr_quad.layers, _vr_quad.visible])
	print("[MushroomEffect]   XRCamera3D current=%s, cull_mask=%s" % [
		_xr_camera.current, _xr_camera.cull_mask])

func _find_xr_camera_global() -> Camera3D:
	# Search from root — XRCamera3D is in the staging tree above current_scene
	var root: Node = get_tree().root
	var cam: Node = root.find_child("XRCamera3D", true, false)
	if cam and cam is Camera3D:
		return cam as Camera3D
	return null

func _apply_intensity(value: float) -> void:
	# Update shader
	if _shader_mat:
		_shader_mat.set_shader_parameter("intensity", value)

	# Update audio effects
	_apply_audio_effects(value)

	# Hide overlay when not needed
	if _is_vr:
		if _vr_quad:
			_vr_quad.visible = value > 0.001
	else:
		if _color_rect:
			_color_rect.visible = value > 0.001

	# Stop ambient sound when effect ends
	if value <= 0.001 and _ambient_player and _ambient_player.playing:
		_ambient_player.stop()

# ═══════════════════════════════════════════════════════════════════════════
# AUDIO EFFECTS
# ═══════════════════════════════════════════════════════════════════════════

func _setup_audio_bus() -> void:
	_audio_bus_idx = AudioServer.get_bus_index(_audio_bus_name)
	if _audio_bus_idx == -1:
		_audio_bus_idx = AudioServer.bus_count
		AudioServer.add_bus(_audio_bus_idx)
		AudioServer.set_bus_name(_audio_bus_idx, _audio_bus_name)
		AudioServer.set_bus_send(_audio_bus_idx, "Master")

		var reverb := AudioEffectReverb.new()
		reverb.room_size = 0.8
		reverb.damping = 0.3
		reverb.wet = 0.0
		reverb.dry = 1.0
		AudioServer.add_bus_effect(_audio_bus_idx, reverb)

		var chorus := AudioEffectChorus.new()
		chorus.voice_count = 2
		chorus.set_voice_delay_ms(1, 15.0)
		chorus.set_voice_rate_hz(1, 0.5)
		chorus.set_voice_depth_ms(1, 3.0)
		chorus.set_voice_level_db(1, -6.0)
		chorus.wet = 0.0
		chorus.dry = 1.0
		AudioServer.add_bus_effect(_audio_bus_idx, chorus)

		print("[MushroomEffect] Created audio bus '%s' with reverb + chorus" % _audio_bus_name)

func _setup_eat_sound() -> void:
	_eat_player = AudioStreamPlayer.new()
	_eat_player.name = "EatSound"
	_eat_player.bus = _audio_bus_name
	_eat_player.volume_db = -6.0
	_eat_player.stream = _generate_eat_sound()
	add_child(_eat_player)

func _setup_ambient_sound() -> void:
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.name = "AmbientDrone"
	_ambient_player.bus = _audio_bus_name
	_ambient_player.volume_db = -18.0
	_ambient_player.stream = _generate_drone_sound()
	add_child(_ambient_player)

func _apply_audio_effects(value: float) -> void:
	if _audio_bus_idx < 0:
		return

	var reverb_effect: AudioEffectReverb = AudioServer.get_bus_effect(_audio_bus_idx, 0) as AudioEffectReverb
	if reverb_effect:
		reverb_effect.wet = value * 0.6
		reverb_effect.room_size = 0.5 + value * 0.4

	var chorus_effect: AudioEffectChorus = AudioServer.get_bus_effect(_audio_bus_idx, 1) as AudioEffectChorus
	if chorus_effect:
		chorus_effect.wet = value * 0.5
		if chorus_effect.voice_count >= 2:
			chorus_effect.set_voice_depth_ms(1, 2.0 + value * 6.0)
			chorus_effect.set_voice_rate_hz(1, 0.3 + value * 0.8)

	if _ambient_player:
		_ambient_player.volume_db = -24.0 + value * 12.0

# ═══════════════════════════════════════════════════════════════════════════
# PROCEDURAL AUDIO GENERATION
# ═══════════════════════════════════════════════════════════════════════════

func _generate_eat_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 0.4
	var sample_count: int = int(sample_rate * duration)

	var data := PackedByteArray()
	data.resize(sample_count * 2)

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for i in range(sample_count):
		var t: float = float(i) / float(sample_rate)
		var env: float = 0.0

		if t < 0.08:
			env = sin(t / 0.08 * PI) * 0.8
		elif t > 0.12 and t < 0.22:
			env = sin((t - 0.12) / 0.10 * PI) * 0.5
		elif t > 0.25 and t < 0.35:
			env = sin((t - 0.25) / 0.10 * PI) * 0.3

		var noise: float = rng.randf_range(-1.0, 1.0)
		var crunch: float = sin(t * 180.0) * 0.3 + sin(t * 340.0) * 0.2
		var sample: float = (noise * 0.6 + crunch * 0.4) * env

		var s16: int = clampi(int(sample * 16000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.data = data
	return stream

func _generate_drone_sound() -> AudioStreamWAV:
	var sample_rate: int = 22050
	var duration: float = 4.0
	var sample_count: int = int(sample_rate * duration)

	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for i in range(sample_count):
		var t: float = float(i) / float(sample_rate)

		var fund: float = sin(t * TAU * 55.0)
		var h2: float = sin(t * TAU * 82.5) * 0.4
		var h3: float = sin(t * TAU * 110.0) * 0.25
		var h4: float = sin(t * TAU * 146.83) * 0.15

		var mod: float = 0.6 + 0.4 * sin(t * TAU * 0.15)
		var sample: float = (fund + h2 + h3 + h4) * 0.2 * mod

		var s16: int = clampi(int(sample * 16000.0), -32768, 32767)
		data[i * 2] = s16 & 0xFF
		data[i * 2 + 1] = (s16 >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	stream.data = data
	return stream
