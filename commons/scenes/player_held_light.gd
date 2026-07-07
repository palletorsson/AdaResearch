extends Node3D
## PlayerHeldLight — a warm point light that follows the player, so the world reads as
## something YOUR light is revealing rather than a fully-lit room.
##
## Inspired by the GDC talk on The Ascent (Neon Giant): their single biggest optimization
## pass was fading geometry out with distance. Here the same distance-based fade is used
## for FEEL rather than just performance — the scene's ambient light is dimmed and a
## matching fog density is set so the room dissolves into darkness beyond the light's
## reach, instead of popping. Attach as a child of the player's Head/Camera node.
##
## darken_environment (on by default) finds the scene's WorldEnvironment, dims it, and
## restores the exact original values on exit — no per-map data is touched, only this one
## scene-level Environment resource, and only while this node is alive/enabled.
## Toggle at runtime with `toggle_key` (default F).

@export var light_color: Color = Color(1.0, 0.82, 0.58)
@export var light_energy: float = 2.2
@export var light_range: float = 9.0
@export var flicker_amount: float = 0.06   # 0 = perfectly steady
@export var darken_environment: bool = true
@export var toggle_key: Key = KEY_F

var _light: OmniLight3D
var _env: Environment = null
var _orig_ambient_energy: float = 1.0
var _orig_fog_enabled: bool = false
var _orig_fog_density: float = 0.0
var _orig_fog_color: Color = Color.BLACK
var _time := 0.0
var _enabled := true


func _ready() -> void:
	_light = OmniLight3D.new()
	_light.name = "HeldLight"
	_light.light_color = light_color
	_light.light_energy = light_energy
	_light.omni_range = light_range
	_light.shadow_enabled = false   # a moving point light casting shadows is a real cost; skip it
	_light.position = Vector3(0, -0.25, -0.15)   # slightly below/ahead of the camera — reads as carried, not a headlamp
	add_child(_light)
	if darken_environment:
		_apply_environment()


func _process(delta: float) -> void:
	if not _enabled or flicker_amount <= 0.0:
		return
	_time += delta
	var n := sin(_time * 11.0) * 0.5 + sin(_time * 23.0) * 0.5
	_light.light_energy = light_energy * (1.0 - flicker_amount * 0.5 + n * flicker_amount * 0.5)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == toggle_key:
		_enabled = not _enabled
		_light.visible = _enabled
		if darken_environment:
			if _enabled:
				_apply_environment()
			else:
				_restore_environment()


func _apply_environment() -> void:
	_env = _find_environment()
	if _env == null:
		return
	_orig_ambient_energy = _env.ambient_light_energy
	_orig_fog_enabled = _env.fog_enabled
	_orig_fog_density = _env.fog_density
	_orig_fog_color = _env.fog_light_color
	_env.ambient_light_energy = minf(_env.ambient_light_energy, 0.35)
	_env.fog_enabled = true
	_env.fog_light_color = Color(0.02, 0.02, 0.03)
	_env.fog_density = clampf(1.6 / maxf(light_range, 1.0), 0.02, 0.25)


func _restore_environment() -> void:
	if _env == null:
		return
	_env.ambient_light_energy = _orig_ambient_energy
	_env.fog_enabled = _orig_fog_enabled
	_env.fog_density = _orig_fog_density
	_env.fog_light_color = _orig_fog_color


func _exit_tree() -> void:
	if darken_environment:
		_restore_environment()


func _find_environment() -> Environment:
	if not get_tree():
		return null
	var we := _find_world_environment(get_tree().get_root())
	return we.environment if we else null


func _find_world_environment(node: Node) -> WorldEnvironment:
	if node is WorldEnvironment:
		return node
	for child in node.get_children():
		var found := _find_world_environment(child)
		if found:
			return found
	return null
