extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ReturnLauncher

## @identity
## lineage: the catapult, made sci-fi and made personal — instead of flinging a stone toward
##   +Z it flings YOU on a ballistic arc back to where you started. The final throw of a
##   fly-up course: the way home.
## essence: stand on the glowing launch ring and the energy arm snaps over; a velocity is
##   solved on the spot — p(t) = p0 + v0·t + ½g·t² — so that t seconds later you land exactly
##   on your spawn. It can't throw the wrong way, because it always aims at the beginning.
## truth: a launch is an initial condition; pick the landing and the velocity is forced. The
##   machine doesn't aim in a compass direction — it aims at home.
##
## A force_pad's cousin: an Area3D on the player layer fires the launch (sets the player
## CharacterBody3D's velocity). The target is the spawn, captured the first frame the player
## is seen, so the arc is correct from wherever the launcher is placed or turned.

const PLAYER_MASK := 524288                    # player body physics layer 20 (matches force_pad)

@export var flight_time: float = 3.0           # seconds of arc back to the start
@export var cooldown_time: float = 1.6
@export var energy_color: Color = Color(0.30, 0.90, 1.0)    # neon cyan
@export var accent_color: Color = Color(1.0, 0.42, 0.85)    # magenta
@export var frame_color: Color = Color(0.10, 0.12, 0.16)    # dark hull

var _arm: Node3D
var _ring_mat: StandardMaterial3D
var _reticle: Node3D
var _home: Vector3
var _home_set: bool = false
var _player: CharacterBody3D
var _cooldown: float = 0.0
var _firing: bool = false
var _fire_t: float = 0.0
const SWING := 0.30


func _ready() -> void:
	_build()
	set_physics_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("flight_time"): flight_time = float(config["flight_time"])
	if config.has("cooldown_time"): cooldown_time = float(config["cooldown_time"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	energy_color = _parse_color(config.get("energy_color", energy_color), energy_color)
	accent_color = _parse_color(config.get("accent_color", accent_color), accent_color)
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


# ─── sci-fi catapult ─────────────────────────────────────────────────────────
func _build() -> void:
	var hull := _matte_mat(frame_color, 0.5, 0.5)
	var neon := _glow_mat(energy_color, 1.8)
	var mag := _glow_mat(accent_color, 1.6)

	# angular hull base + glowing under-rim
	add_child(_box(Vector3(0, 0.10, -0.1), Vector3(1.7, 0.20, 1.6), hull))
	add_child(_box(Vector3(0, 0.21, -0.1), Vector3(1.5, 0.03, 1.4), _glow_mat(energy_color, 0.8)))
	for sx in [-0.78, 0.78]:
		add_child(_box(Vector3(sx, 0.12, -0.1), Vector3(0.04, 0.18, 1.5), neon))

	# the launch ring — where you stand (the trigger)
	add_child(_torus(Vector3(0, 0.06, 0.45), 0.62, 0.05, neon))
	add_child(_torus(Vector3(0, 0.08, 0.45), 0.40, 0.03, mag))
	add_child(_cylinder(Vector3(0, 0.03, 0.45), 0.6, 0.02, _glow_mat(energy_color, 0.5)))
	# a holographic reticle that spins on the ring
	_reticle = Node3D.new(); _reticle.position = Vector3(0, 0.12, 0.45); add_child(_reticle)
	for i in range(3):
		var a := TAU * float(i) / 3.0
		_reticle.add_child(_box(Vector3(cos(a) * 0.3, 0, sin(a) * 0.3), Vector3(0.18, 0.01, 0.03), mag))

	# two angular uprights carrying the pivot, with energy conduits
	for sx in [-0.55, 0.55]:
		add_child(_box(Vector3(sx, 0.85, -0.55), Vector3(0.12, 1.5, 0.12), hull))
		add_child(_cylinder_between(Vector3(sx, 0.25, -0.55), Vector3(sx, 1.5, -0.55), 0.03, neon))
	# pivot energy coils
	var coil := _torus(Vector3(0, 1.5, -0.55), 0.16, 0.05, mag); coil.rotation.z = PI * 0.5
	add_child(coil)
	add_child(_sphere(Vector3(0, 1.5, -0.55), 0.12, _glow_mat(energy_color, 2.4)))

	# the energy throwing arm (swings on fire), tip basket of light over the ring
	_arm = Node3D.new(); _arm.position = Vector3(0, 1.5, -0.55); add_child(_arm)
	_arm.add_child(_cylinder_between(Vector3.ZERO, Vector3(0, 0, 1.5), 0.05, _glow_mat(energy_color, 2.0)))
	_arm.add_child(_cylinder_between(Vector3.ZERO, Vector3(0, 0, -0.5), 0.06, _glow_mat(accent_color, 1.4)))
	_arm.add_child(_sphere(Vector3(0, 0, -0.5), 0.14, _glow_mat(accent_color, 1.6)))   # counterweight orb
	for r in [0.18, 0.26]:
		var b := _torus(Vector3(0, 0, 1.5), r, 0.02, neon); _arm.add_child(b)
	_apply_arm(deg_to_rad(-58.0))   # resting, wound up

	# the area trigger over the ring
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = PLAYER_MASK
	area.position = Vector3(0, 0.7, 0.45)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new(); box.size = Vector3(1.2, 1.4, 1.2)
	cs.shape = box; area.add_child(cs)
	add_child(area)
	area.body_entered.connect(_on_body_entered)

	# label
	add_child(_billboard_label("RETURN\n↩ to start", Vector3(0, 2.5, -0.55), 28, energy_color.lerp(Color.WHITE, 0.3)))


func _apply_arm(elev: float) -> void:
	if _arm: _arm.rotation.x = elev


# ─── the throw ───────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _reticle:
		_reticle.rotation.y += delta * 1.2
	if not _home_set:
		var p := _find_player()
		if p != null:
			_home = p.global_position          # the beginning — where the player starts
			_player = p
			_home_set = true
	if _cooldown > 0.0:
		_cooldown -= delta
	if _firing:
		_fire_t += delta
		var u: float = clampf(_fire_t / SWING, 0.0, 1.0)
		_apply_arm(lerpf(deg_to_rad(-58.0), deg_to_rad(38.0), 1.0 - pow(1.0 - u, 3.0)))
		if u >= 1.0:
			_firing = false
			_apply_arm(deg_to_rad(-58.0))       # reset, ready to wind again


func _on_body_entered(body: Node3D) -> void:
	if _cooldown > 0.0 or not _home_set:
		return
	if not (body.is_in_group("player_body") or body is CharacterBody3D):
		return
	if not "velocity" in body:
		return
	# solve the launch that lands the body on home in flight_time:
	#   home = from + v0·t + ½g·t²   →   v0 = (home − from)/t − ½g·t
	var from: Vector3 = body.global_position
	var g := Vector3(0.0, -9.8, 0.0)
	var v0: Vector3 = (_home - from) / flight_time - 0.5 * g * flight_time
	body.set("velocity", v0)
	_cooldown = cooldown_time
	_firing = true
	_fire_t = 0.0


func _find_player() -> CharacterBody3D:
	for n in get_tree().get_nodes_in_group("player_body"):
		if n is CharacterBody3D:
			return n as CharacterBody3D
	return null
