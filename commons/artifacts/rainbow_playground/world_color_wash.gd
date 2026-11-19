extends Node3D
class_name RainbowWorldWash
## Live world-colouring controller shared by Color_Rainbow's Progress Pride
## Color Crossroad and its Colour Mushroom Baskets.
## Tints both SkyAtmosphere (sky, horizon, clouds, fog, ambient, directional sun)
## and a smooth chromatic screen grade (Desktop CanvasLayer / VR XRCamera3D quad).
## Restores cleanly when cleared, expired, or when the visitor leaves the floor.

const DESKTOP_SHADER := "res://commons/artifacts/rainbow_playground/world_color_wash.gdshader"
const VR_SHADER := "res://commons/artifacts/rainbow_playground/world_color_wash_spatial.gdshader"

var floor_y: float = -198.0
var _active := false
var _target_color := Color.WHITE
var _current_color := Color.WHITE
var _target_strength := 0.0
var _strength := 0.0
var _target_dream := 0.0
var _dream := 0.0
var _timed := false
var _hold_remaining := 0.0
var _label := ""
var _had_atmosphere_override := false

var _is_vr := false
var _canvas_layer: CanvasLayer
var _color_rect: ColorRect
var _vr_quad: MeshInstance3D
var _shader_mat: ShaderMaterial
var _chime_player: AudioStreamPlayer

const SELF_PATH := "res://commons/artifacts/rainbow_playground/world_color_wash.gd"

static func ensure(anchor: Node, host_floor_y: float = -198.0) -> Node3D:
	if anchor == null or anchor.get_tree() == null:
		return null
	var existing := anchor.get_tree().get_first_node_in_group("rainbow_world_wash")
	if is_instance_valid(existing) and existing is Node3D:
		return existing as Node3D
	var script: Script = load(SELF_PATH)
	if script == null:
		return null
	var node: Node3D = script.new()
	node.name = "RainbowWorldWash"
	node.set("floor_y", host_floor_y)
	var root := anchor.get_tree().current_scene
	if root != null:
		root.add_child(node)
	else:
		anchor.get_parent().add_child(node)
	return node

func _ready() -> void:
	add_to_group("rainbow_world_wash")
	_detect_vr()
	_setup_chime()

func _detect_vr() -> void:
	var game := get_tree().get_first_node_in_group("void_game")
	if is_instance_valid(game):
		_is_vr = bool(game.get("vr"))

func _setup_chime() -> void:
	_chime_player = AudioStreamPlayer.new()
	_chime_player.name = "TintChime"
	_chime_player.volume_db = -12.0
	add_child(_chime_player)

func _play_chime(color: Color, mushroom := false) -> void:
	if _chime_player == null:
		return
	var sr := 22050
	var dur := 0.38 if mushroom else 0.22
	var samples := int(sr * dur)
	var data := PackedByteArray()
	data.resize(samples * 2)
	var base_freq := 260.0 + color.h * 420.0
	for i in range(samples):
		var t := float(i) / float(sr)
		var env := exp(-t * (6.0 if mushroom else 11.0)) * minf(1.0, t * 60.0)
		var s := sin(TAU * base_freq * t) * 0.55 + sin(TAU * base_freq * 1.5 * t) * 0.3
		if mushroom:
			s += sin(TAU * base_freq * 2.0 * t + sin(t * 18.0) * 0.4) * 0.2
		var v := int(clampf(s * env, -1.0, 1.0) * 28000.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sr
	wav.data = data
	_chime_player.stream = wav
	_chime_player.play()

func tint_from_crosswalk(color: Color, colour_name: String = "") -> void:
	if color.r > 0.94 and color.g > 0.94 and color.b > 0.94:
		clear_tint()
		_play_chime(Color.WHITE, false)
		return
	if not _active:
		_current_color = color
	_active = true
	_timed = false
	_hold_remaining = 0.0
	_target_color = color
	_target_strength = 0.82
	_target_dream = 0.0
	_label = colour_name
	_ensure_overlay()
	_play_chime(color, false)

func tint_from_mushroom(color: Color, colour_name: String = "", duration: float = 12.0) -> void:
	if not _active:
		_current_color = color
	_active = true
	_timed = true
	_hold_remaining = maxf(duration, 2.0)
	_target_color = color
	_target_strength = 0.94
	_target_dream = 0.65
	_label = colour_name
	_ensure_overlay()
	_play_chime(color, true)

func clear_tint() -> void:
	_active = false
	_timed = false
	_hold_remaining = 0.0
	_target_strength = 0.0
	_target_dream = 0.0
	_label = ""

func get_state() -> Dictionary:
	return {
		"active": _active,
		"label": _label,
		"color": _target_color.to_html(false),
		"strength": _strength,
		"dream_wave": _dream,
	}

func _ensure_overlay() -> void:
	if _shader_mat == null:
		var path := VR_SHADER if _is_vr else DESKTOP_SHADER
		var sh: Shader = load(path)
		if sh != null:
			_shader_mat = ShaderMaterial.new()
			_shader_mat.shader = sh
			_shader_mat.render_priority = 125
	if _is_vr:
		if not is_instance_valid(_vr_quad):
			var game := get_tree().get_first_node_in_group("void_game")
			var cam: Camera3D = game.get("camera") if is_instance_valid(game) else get_viewport().get_camera_3d()
			if cam != null:
				_vr_quad = MeshInstance3D.new()
				_vr_quad.name = "WorldColorWashVR"
				var q := QuadMesh.new()
				q.size = Vector2(2.0, 2.0)
				q.subdivide_width = 4
				q.subdivide_depth = 4
				_vr_quad.mesh = q
				_vr_quad.extra_cull_margin = 16384.0
				_vr_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				_vr_quad.material_override = _shader_mat
				cam.add_child(_vr_quad)
	else:
		if not is_instance_valid(_canvas_layer):
			_canvas_layer = CanvasLayer.new()
			_canvas_layer.name = "WorldColorWashLayer"
			_canvas_layer.layer = 55
			add_child(_canvas_layer)
			_color_rect = ColorRect.new()
			_color_rect.name = "WorldColorWashRect"
			_color_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_color_rect.material = _shader_mat
			_canvas_layer.add_child(_color_rect)

func _process(delta: float) -> void:
	# Auto-clear if visitor descends/ascends to another storey.
	var game := get_tree().get_first_node_in_group("void_game")
	if _active and is_instance_valid(game) and game.get("body") != null:
		var body_y: float = (game.body as Node3D).global_position.y
		if absf(body_y - floor_y) > 5.0:
			clear_tint()

	if _timed and _active:
		_hold_remaining -= delta
		if _hold_remaining <= 0.0:
			clear_tint()

	var speed := 3.6 if _target_strength > _strength else 1.8
	_strength = move_toward(_strength, _target_strength, delta * speed)
	_dream = move_toward(_dream, _target_dream, delta * 2.2)
	_current_color = _current_color.lerp(_target_color, clampf(delta * 5.0, 0.0, 1.0))

	if _shader_mat != null:
		_shader_mat.set_shader_parameter("tint_color", Vector3(_current_color.r, _current_color.g, _current_color.b))
		_shader_mat.set_shader_parameter("intensity", _strength)
		_shader_mat.set_shader_parameter("dream_wave", _dream)
	if is_instance_valid(_color_rect):
		_color_rect.visible = _strength > 0.002
	if is_instance_valid(_vr_quad):
		_vr_quad.visible = _strength > 0.002

	_apply_atmosphere(game)

func _apply_atmosphere(game: Node) -> void:
	if not is_instance_valid(game):
		return
	var atmo: Node = game.get("atmosphere")
	if not is_instance_valid(atmo):
		return
	if _strength <= 0.002:
		if _had_atmosphere_override:
			_had_atmosphere_override = false
			if atmo.has_method("set_lighting_mode"):
				atmo.call("set_lighting_mode", atmo.get("lighting_mode"))
		return
	_had_atmosphere_override = true
	var env: Environment = atmo.get("environment")
	var sky_mat: ShaderMaterial = atmo.get("sky_material")
	var sun := atmo.get_node_or_null("WarmSun") as DirectionalLight3D
	var c := _current_color
	var dark_c := c.darkened(0.62)
	var mid_c := c.darkened(0.18)
	var bright_c := c.lightened(0.32)
	var s := _strength
	if env != null:
		env.ambient_light_color = Color("b6a9c9").lerp(bright_c, s * 0.92)
		env.ambient_light_energy = lerpf(0.28, 0.72 if c.get_luminance() > 0.08 else 0.16, s)
		env.fog_light_color = Color("62516d").lerp(mid_c, s * 0.95)
		env.fog_light_energy = lerpf(0.45, 0.92 if c.get_luminance() > 0.08 else 0.25, s)
	if sun != null:
		sun.light_color = Color("ecb6c4").lerp(bright_c, s * 0.85)
		sun.light_energy = lerpf(0.22, 0.88 if c.get_luminance() > 0.08 else 0.22, s)
	if sky_mat != null:
		sky_mat.set_shader_parameter("rose_zenith", Color("211c3d").lerp(dark_c, s))
		sky_mat.set_shader_parameter("violet_zenith", Color("171b37").lerp(dark_c, s))
		sky_mat.set_shader_parameter("rose_horizon", Color("835570").lerp(c, s))
		sky_mat.set_shader_parameter("violet_horizon", Color("565178").lerp(mid_c, s))
		sky_mat.set_shader_parameter("rose_shadow", Color("302c48").lerp(dark_c, s))
		sky_mat.set_shader_parameter("violet_shadow", Color("252b4a").lerp(dark_c, s))
		sky_mat.set_shader_parameter("rose_light", Color("926b87").lerp(bright_c, s))
		sky_mat.set_shader_parameter("violet_light", Color("746990").lerp(bright_c, s))
	var city: Node = atmo.get("city")
	if is_instance_valid(city) and city.has_method("set_haze") and env != null:
		city.call("set_haze", env.fog_light_color)

func _exit_tree() -> void:
	if _had_atmosphere_override:
		var game := get_tree().get_first_node_in_group("void_game") if get_tree() != null else null
		if is_instance_valid(game) and is_instance_valid(game.get("atmosphere")):
			var atmo: Node = game.get("atmosphere")
			if atmo.has_method("set_lighting_mode"):
				atmo.call("set_lighting_mode", atmo.get("lighting_mode"))
	if is_instance_valid(_vr_quad):
		_vr_quad.queue_free()
