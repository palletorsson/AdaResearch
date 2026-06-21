extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name QfepReactorBench

## @identity
## name: "The reactor — the whole formula"
## tier: medium
## lineage: A floor-standing bench reactor (~1m). Three dials — F, λ, φ — feed a
##   central glass chamber where a system flickers across its life as the dials
##   sweep: dead-ordered (a frozen lattice) → living-complex at the edge (a
##   loose, breathing swarm) → dead-random (a scattered cloud). A readout panel
##   shows QFE = F − λE + φΔE and a one-word verdict: FROZEN / ALIVE / NOISE.
## truth: "SET THE TERMS, WATCH IT FLICKER INTO LIFE."
## applications: the QFEP machine made operable — a bench you set and read; the
##   edge of chaos as an instrument reading; the whole formula, dialled.

@export var sweep_rate: float = 0.12
@export var particle_count: int = 14
@export var body_col: Color = Color(0.14, 0.16, 0.23)
@export var glass_col: Color = Color(0.46, 0.78, 0.98)
@export var frozen_col: Color = Color(0.40, 0.64, 1.0)
@export var alive_col: Color = Color(0.50, 0.99, 0.74)
@export var noise_col: Color = Color(0.78, 0.52, 0.98)
@export var dial_f_col: Color = Color(0.55, 0.92, 0.99)
@export var dial_l_col: Color = Color(0.62, 0.55, 0.98)
@export var dial_p_col: Color = Color(0.55, 0.99, 0.78)
@export var panel_col: Color = Color(0.07, 0.09, 0.13)
@export var readout_col: Color = Color(0.55, 0.98, 0.85)
@export var label_col: Color = Color(0.92, 0.96, 1.0)

var _t: float = 0.0
var _sweep: float = 0.5            # 0 = frozen, 0.5 = alive (edge), 1 = noise
var _chamber_c := Vector3(0.0, 0.78, 0.0)
var _chamber_r: float = 0.20
var _particles: Array[MeshInstance3D] = []
var _order_pos: Array[Vector3] = []
var _chaos_pos: Array[Vector3] = []
var _needle_f: MeshInstance3D = null
var _needle_l: MeshInstance3D = null
var _needle_p: MeshInstance3D = null
var _readout: Label3D = null
var _verdict: Label3D = null
var _dial_f_c := Vector3(-0.32, 0.62, 0.30)
var _dial_l_c := Vector3(0.0, 0.62, 0.34)
var _dial_p_c := Vector3(0.32, 0.62, 0.30)
var _dial_r: float = 0.085


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("sweep_rate"):
		sweep_rate = clampf(float(config["sweep_rate"]), 0.05, 0.4)
	if config.has("particle_count"):
		particle_count = int(clampf(float(config["particle_count"]), 6.0, 28.0))
	if config.has("alive_col"):
		alive_col = _parse_color(config["alive_col"], alive_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_particles.clear()
	_order_pos.clear()
	_chaos_pos.clear()
	_needle_f = null
	_needle_l = null
	_needle_p = null
	_readout = null
	_verdict = null
	_build()


func _build() -> void:
	# Bench body — a ~1m console with a sloped control deck.
	add_child(_box(Vector3(0.0, 0.30, 0.0), Vector3(0.95, 0.60, 0.55), _matte_mat(body_col, 0.85)))
	add_child(_box(Vector3(0.0, 0.605, 0.0), Vector3(0.97, 0.02, 0.57), _steel_mat(Color(0.32, 0.34, 0.40))))
	# Plinth feet hint.
	add_child(_box(Vector3(0.0, 0.01, 0.0), Vector3(1.0, 0.02, 0.60), _matte_mat(Color(0.08, 0.09, 0.12), 0.9)))

	# Three dials on the deck — the terms F, λ, φ.
	_needle_f = _add_dial(_dial_f_c, dial_f_col, "F")
	_needle_l = _add_dial(_dial_l_c, dial_l_col, "λ")
	_needle_p = _add_dial(_dial_p_c, dial_p_col, "φ")

	# Feed-lines from each dial up into the chamber base.
	add_child(_cylinder_between(_dial_f_c + Vector3(0, 0.02, 0), _chamber_c + Vector3(-0.12, -0.18, 0), 0.012, _glow_mat(dial_f_col, 0.7)))
	add_child(_cylinder_between(_dial_l_c + Vector3(0, 0.02, 0), _chamber_c + Vector3(0.0, -0.20, 0), 0.012, _glow_mat(dial_l_col, 0.7)))
	add_child(_cylinder_between(_dial_p_c + Vector3(0, 0.02, 0), _chamber_c + Vector3(0.12, -0.18, 0), 0.012, _glow_mat(dial_p_col, 0.7)))

	# Central chamber — glass sphere on a steel collar.
	add_child(_cylinder(_chamber_c + Vector3(0, -0.22, 0), 0.10, 0.10, _steel_mat(Color(0.28, 0.30, 0.36))))
	add_child(_sphere(_chamber_c, _chamber_r + 0.02, _glass_mat(glass_col, 0.13)))

	# Particles — order homes (lattice ring) + chaos homes (scatter).
	for i in range(particle_count):
		var ang: float = TAU * float(i) / float(particle_count)
		var ord_p: Vector3 = _chamber_c + Vector3(cos(ang), sin(ang * 2.3) * 0.5, sin(ang)) * (_chamber_r * 0.62)
		_order_pos.append(ord_p)
		var ch_p: Vector3 = _chamber_c + Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)).normalized() * (_chamber_r * _rng.randf_range(0.45, 0.92))
		_chaos_pos.append(ch_p)
		var p: MeshInstance3D = _sphere(ord_p, 0.016, _glow_mat(frozen_col, 1.0))
		_particles.append(p)
		add_child(p)

	# Readout panel — raised behind the chamber.
	add_child(_box(Vector3(0.0, 1.18, -0.12), Vector3(0.72, 0.30, 0.02), _matte_mat(panel_col, 0.4)))
	add_child(_box(Vector3(0.0, 1.18, -0.118), Vector3(0.70, 0.28, 0.005), _glow_mat(Color(0.12, 0.18, 0.24), 0.25)))
	_readout = _billboard_label(_readout_text(), Vector3(0.0, 1.22, -0.10), 15, readout_col)
	add_child(_readout)
	_verdict = _billboard_label(_verdict_text(), Vector3(0.0, 1.08, -0.10), 22, alive_col)
	add_child(_verdict)

	# Billboard title.
	add_child(_billboard_label("QFEP REACTOR BENCH — THE WHOLE FORMULA", Vector3(0.0, 1.5, 0.0), 18, label_col))


func _add_dial(center: Vector3, col: Color, text: String) -> MeshInstance3D:
	# Dial face, tilted up on the deck.
	add_child(_cylinder(center, _dial_r, 0.02, _matte_mat(Color(0.90, 0.92, 0.96), 0.4)))
	add_child(_torus(center + Vector3(0, 0.012, 0), _dial_r, 0.008, _glow_mat(col, 0.9)))
	# Tick marks at the sweep ends + midpoint.
	add_child(_box(center + Vector3(-_dial_r * 0.78, 0.018, 0.0), Vector3(0.008, 0.004, 0.016), _glow_mat(col, 0.8)))
	add_child(_box(center + Vector3(0.0, 0.018, _dial_r * 0.78), Vector3(0.016, 0.004, 0.008), _glow_mat(Color(1, 1, 1), 1.0)))
	add_child(_box(center + Vector3(_dial_r * 0.78, 0.018, 0.0), Vector3(0.008, 0.004, 0.016), _glow_mat(col, 0.8)))
	# Needle — a flat pointer pivoting at the dial center.
	var needle: MeshInstance3D = _box(center + Vector3(0.0, 0.02, _dial_r * 0.4), Vector3(0.010, 0.006, _dial_r * 0.8), _glow_mat(Color(0.10, 0.11, 0.14), 0.2))
	add_child(needle)
	add_child(_billboard_label(text, center + Vector3(0.0, 0.09, 0.0), 14, col))
	return needle


func _aliveness(s: float) -> float:
	# Bell curve peaking at the edge (s = 0.5), dead at both ends.
	return exp(-pow((s - 0.5) / 0.18, 2.0))


func _verdict_state() -> String:
	if _sweep < 0.28:
		return "FROZEN"
	if _sweep > 0.72:
		return "NOISE"
	return "ALIVE"


func _state_color() -> Color:
	if _sweep < 0.5:
		return frozen_col.lerp(alive_col, _sweep * 2.0)
	return alive_col.lerp(noise_col, (_sweep - 0.5) * 2.0)


func _readout_text() -> String:
	# F term high, E term penalised by λ, ΔE term the φ relational bonus.
	var f_term: float = 0.5 + (1.0 - _sweep) * 0.5
	var e_term: float = _sweep
	var de_term: float = _aliveness(_sweep)
	var qfe: float = f_term - 0.5 * e_term + 0.5 * de_term
	return "QFE = F - lambda*E + phi*dE\nF=%.2f  E=%.2f  dE=%.2f\nQFE = %.2f" % [f_term, e_term, de_term, qfe]


func _verdict_text() -> String:
	return _verdict_state()


func _set_needle(needle: MeshInstance3D, center: Vector3, frac: float) -> void:
	if needle == null:
		return
	# Sweep needle from -70deg (left tick) to +70deg (right tick) about Y.
	var ang: float = lerpf(deg_to_rad(70.0), deg_to_rad(-70.0), frac)
	var b := Basis(Vector3.UP, ang)
	needle.transform = Transform3D(b, center + Vector3(0.0, 0.02, 0.0)).translated_local(Vector3(0.0, 0.0, _dial_r * 0.4))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Slow sweep across the system's whole life.
	_sweep = sin(_t * TAU * sweep_rate) * 0.5 + 0.5
	var alive: float = _aliveness(_sweep)
	var col: Color = _state_color()

	# Dials track the terms: F falls as the system disorders; λ-load (E) rises;
	# φ-bonus (ΔE) peaks at the edge.
	_set_needle(_needle_f, _dial_f_c, 1.0 - _sweep)
	_set_needle(_needle_l, _dial_l_c, _sweep)
	_set_needle(_needle_p, _dial_p_c, alive)

	# Particles: lattice when frozen, breathing swarm at the edge, cloud as noise.
	for i in range(_particles.size()):
		var p: MeshInstance3D = _particles[i]
		var home: Vector3 = _order_pos[i].lerp(_chaos_pos[i], _sweep)
		# Edge-of-chaos breathing: motion peaks in the alive middle.
		var breath := Vector3(
			sin(_t * 4.0 + float(i) * 1.3),
			cos(_t * 3.4 + float(i) * 0.8),
			sin(_t * 4.7 + float(i))) * (0.02 * alive)
		# Hard chaos jitter that only grows toward noise.
		var jit := Vector3(
			sin(_t * 11.0 + float(i)),
			cos(_t * 9.7 + float(i) * 2.1),
			sin(_t * 13.0 + float(i) * 0.7)) * (0.012 * clampf((_sweep - 0.5) * 2.0, 0.0, 1.0))
		p.position = home + breath + jit
		p.material_override = _glow_mat(col, 0.9 + alive * 0.6)

	if _readout != null:
		_readout.text = _readout_text()
	if _verdict != null:
		_verdict.text = _verdict_text()
		_verdict.modulate = col
