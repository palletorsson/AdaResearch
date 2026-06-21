extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name QfepReactorToy

## @identity
## name: "The reactor — the whole formula"
## tier: small
## lineage: The whole QFEP formula in your hand (~0.4m). A tiny reactor core: a
##   glass chamber on a small steel base, ringed by three little knobs labelled
##   F, λ, φ. Inside the chamber a few particles flicker between order (a frozen
##   lattice) and chaos (a scattered cloud) — the four terms of
##   QFE = F − λE(S) + φΔE(S,t) held at once, miniature, pocket-sized.
## truth: "ALL FOUR KNOBS, IN YOUR HAND."
## applications: a desk model of the QFEP machine; a fidget that is also a
##   thesis; the reactor before it became a bench — the formula made graspable.

@export var flicker_rate: float = 0.35
@export var particle_count: int = 7
@export var base_col: Color = Color(0.15, 0.17, 0.24)
@export var glass_col: Color = Color(0.46, 0.78, 0.98)
@export var order_col: Color = Color(0.42, 0.66, 1.0)
@export var chaos_col: Color = Color(0.74, 0.52, 0.98)
@export var knob_f_col: Color = Color(0.55, 0.92, 0.99)
@export var knob_l_col: Color = Color(0.62, 0.55, 0.98)
@export var knob_p_col: Color = Color(0.55, 0.99, 0.78)
@export var label_col: Color = Color(0.92, 0.96, 1.0)

var _t: float = 0.0
var _chamber_c := Vector3(0.0, 0.18, 0.0)
var _chamber_r: float = 0.085
var _particles: Array[MeshInstance3D] = []
var _order_pos: Array[Vector3] = []
var _chaos_pos: Array[Vector3] = []
var _core: MeshInstance3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("flicker_rate"):
		flicker_rate = clampf(float(config["flicker_rate"]), 0.1, 0.8)
	if config.has("particle_count"):
		particle_count = int(clampf(float(config["particle_count"]), 3.0, 14.0))
	if config.has("order_col"):
		order_col = _parse_color(config["order_col"], order_col)
	if config.has("chaos_col"):
		chaos_col = _parse_color(config["chaos_col"], chaos_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_particles.clear()
	_order_pos.clear()
	_chaos_pos.clear()
	_core = null
	_build()


func _build() -> void:
	# Small steel base — no floor plinth, a held object.
	add_child(_cylinder(Vector3(0.0, 0.03, 0.0), 0.13, 0.06, _steel_mat(base_col)))
	add_child(_torus(Vector3(0.0, 0.06, 0.0), 0.115, 0.012, _glow_mat(glass_col, 0.6)))

	# Central chamber — a little glass dome holding the system.
	add_child(_sphere(_chamber_c, _chamber_r + 0.02, _glass_mat(glass_col, 0.16)))
	# The reacting core inside.
	_core = _sphere(_chamber_c, 0.022, _glow_mat(order_col, 1.2))
	add_child(_core)

	# Precompute order (lattice ring) and chaos (scatter) particle homes.
	for i in range(particle_count):
		var ang: float = TAU * float(i) / float(particle_count)
		var ord_p: Vector3 = _chamber_c + Vector3(cos(ang), sin(ang * 1.7) * 0.4, sin(ang)) * (_chamber_r * 0.62)
		_order_pos.append(ord_p)
		var ch_p: Vector3 = _chamber_c + Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)).normalized() * (_chamber_r * _rng.randf_range(0.45, 0.9))
		_chaos_pos.append(ch_p)
		var p: MeshInstance3D = _sphere(ord_p, 0.009, _glow_mat(order_col, 1.0))
		_particles.append(p)
		add_child(p)

	# Three tiny knobs around the base — the four terms (F, λ, φ + the chamber).
	_add_knob(Vector3(0.0, 0.085, 0.105), knob_f_col, "F")
	_add_knob(Vector3(-0.091, 0.085, -0.052), knob_l_col, "λ")
	_add_knob(Vector3(0.091, 0.085, -0.052), knob_p_col, "φ")

	# Billboard title.
	add_child(_billboard_label("QFEP REACTOR — THE WHOLE FORMULA", Vector3(0.0, 0.36, 0.0), 13, label_col))


func _add_knob(pos: Vector3, col: Color, text: String) -> void:
	add_child(_cylinder(pos, 0.018, 0.03, _steel_mat(Color(0.3, 0.32, 0.38))))
	add_child(_cylinder(pos + Vector3(0.0, 0.018, 0.0), 0.014, 0.012, _glow_mat(col, 1.0)))
	# Pointer notch on the knob top.
	add_child(_box(pos + Vector3(0.0, 0.026, 0.009), Vector3(0.004, 0.004, 0.012), _glow_mat(Color(1, 1, 1), 1.1)))
	add_child(_billboard_label(text, pos + Vector3(0.0, 0.05, 0.0), 11, col))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# blend: 0 = ordered lattice, 1 = chaos cloud. A slow flicker back and forth.
	var blend: float = sin(_t * TAU * flicker_rate) * 0.5 + 0.5
	var mix: Color = order_col.lerp(chaos_col, blend)

	for i in range(_particles.size()):
		var p: MeshInstance3D = _particles[i]
		var home: Vector3 = _order_pos[i].lerp(_chaos_pos[i], blend)
		# A little chaos jitter that grows with blend.
		var jit := Vector3(
			sin(_t * 6.0 + float(i)),
			cos(_t * 5.3 + float(i) * 1.7),
			sin(_t * 7.1 + float(i) * 0.9)) * (0.006 * blend)
		p.position = home + jit
		p.material_override = _glow_mat(mix, 0.9 + blend * 0.5)

	if _core != null:
		var pulse: float = 1.0 + sin(_t * 3.0) * 0.12
		_core.scale = Vector3.ONE * pulse
		_core.material_override = _glow_mat(mix, 1.2)
