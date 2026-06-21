extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ContradictionEngine

## @identity
## name: Contradiction Engine — Contained, Inference Stable
## concept: Florensky & paraconsistency
## tier: applied
## lineage: paraconsistent logic (da Costa 1963, Priest's LP). In classical logic a single
##   contradiction explodes — ex falso quodlibet, everything follows. A paraconsistent
##   reasoner quarantines P ∧ ¬P and keeps inferring soundly around it.
## essence: a desktop reasoner. Feed it a contradiction crystal — P AND not-P. A classical
##   engine would detonate (a runaway cascade where every conclusion lights at once). This
##   engine clamps the crystal in a containment ring and keeps its inference rotor turning
##   steadily. A readout reports CONTRADICTION CONTAINED — INFERENCE STABLE.
## truth: you can run a working machine on inconsistent input. Quarantine the contradiction
##   instead of letting it prove everything, and reasoning survives.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent: Color = Color(0.45, 0.95, 0.70)    # stable / contained
@export var danger: Color = Color(1.0, 0.40, 0.34)     # the explosion that does NOT happen
@export var cycle_time: float = 6.0

var _t: float = 0.0
var _crystal: Node3D            # the P ∧ ¬P contradiction crystal
var _ring: MeshInstance3D       # containment ring (torus)
var _ring_mat: StandardMaterial3D
var _rotor: Node3D              # the inference rotor (keeps turning)
var _conclusions: Array = []    # MeshInstance3D lamps around the rim (would all light if exploding)
var _conc_mats: Array = []
var _readout: Label3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cycle_time"):
		cycle_time = float(config["cycle_time"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_conclusions = []
	_conc_mats = []

	var steel: StandardMaterial3D = _steel_mat(Color(0.32, 0.34, 0.42))
	var base_mat: StandardMaterial3D = _matte_mat(Color(0.10, 0.11, 0.16), 0.85)
	var purple_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.6)

	# --- base ---
	add_child(_cylinder(Vector3(0.0, 0.05, 0.0), 0.5, 0.1, base_mat))
	add_child(_torus(Vector3(0.0, 0.11, 0.0), 0.48, 0.02, purple_mat))

	# --- containment ring (holds the contradiction) ---
	_ring_mat = _glow_mat(accent, 1.2)
	_ring = _torus(Vector3(0.0, 0.55, 0.0), 0.24, 0.035, _ring_mat)
	add_child(_ring)
	# three clamp arms reaching in to the crystal
	for a in range(3):
		var ang: float = float(a) * TAU / 3.0
		var outer: Vector3 = Vector3(cos(ang) * 0.24, 0.55, sin(ang) * 0.24)
		var inner: Vector3 = Vector3(cos(ang) * 0.10, 0.55, sin(ang) * 0.10)
		add_child(_cylinder_between(outer, inner, 0.018, steel))

	# --- the contradiction crystal: P ∧ ¬P (two interpenetrating tetra-ish prisms) ---
	_crystal = Node3D.new()
	_crystal.position = Vector3(0.0, 0.55, 0.0)
	add_child(_crystal)
	var pos_mat: StandardMaterial3D = _glow_mat(accent, 1.4)
	var neg_mat: StandardMaterial3D = _glow_mat(danger, 1.4)
	# P: upward prism
	var p_box: MeshInstance3D = _box(Vector3(0.0, 0.04, 0.0), Vector3(0.09, 0.16, 0.09), pos_mat)
	_crystal.add_child(p_box)
	# ¬P: downward prism, interpenetrating
	var np_box: MeshInstance3D = _box(Vector3(0.0, -0.04, 0.0), Vector3(0.09, 0.16, 0.09), neg_mat)
	np_box.rotation = Vector3(0.0, PI * 0.25, PI)
	_crystal.add_child(np_box)
	# the seam where P meets ¬P
	add_child(_torus(Vector3(0.0, 0.55, 0.0), 0.075, 0.012, _glow_mat(cool_white, 1.6)))

	# --- the inference rotor: keeps turning, drawing sound conclusions AROUND the crystal ---
	_rotor = Node3D.new()
	_rotor.position = Vector3(0.0, 0.55, 0.0)
	add_child(_rotor)
	for r in range(3):
		var ang2: float = float(r) * TAU / 3.0
		var tip: Vector3 = Vector3(cos(ang2) * 0.18, 0.0, sin(ang2) * 0.18)
		_rotor.add_child(_cylinder_between(Vector3.ZERO, tip, 0.012, _glow_mat(cool_white, 0.8)))
		_rotor.add_child(_sphere(tip, 0.03, _glow_mat(accent, 1.2)))

	# --- conclusion lamps around the rim (in classical logic, ALL would light = explosion) ---
	var n: int = 12
	var k: int = 0
	while k < n:
		var ang3: float = float(k) * TAU / float(n)
		var lp: Vector3 = Vector3(cos(ang3) * 0.46, 0.16, sin(ang3) * 0.46)
		var lmat: StandardMaterial3D = _glow_mat(danger, 0.2)
		add_child(_sphere(lp, 0.026, lmat))
		_conclusions.append(true)
		_conc_mats.append(lmat)
		k += 1

	# --- readout ---
	_readout = _billboard_label("INFERENCE STABLE", Vector3(0.0, 1.1, 0.0), 22, accent)
	add_child(_readout)
	add_child(_billboard_label("CONTRADICTION CONTAINED", Vector3(0.0, 0.92, 0.0), 14, cool_white))
	add_child(_billboard_label("CONTRADICTION ENGINE", Vector3(0.0, 1.28, 0.0), 18, cool_white))
	add_child(_billboard_label("classical logic would explode — this does not", Vector3(0.0, 0.74, 0.0), 11, wire_purple))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	var phase: float = fmod(_t, cycle_time) / cycle_time

	# crystal spins, seam pulses — the contradiction is alive but held
	if is_instance_valid(_crystal):
		_crystal.rotation.y = _t * 0.9
		_crystal.rotation.x = sin(_t * 0.6) * 0.2

	# inference rotor turns steadily — reasoning never stops
	if is_instance_valid(_rotor):
		_rotor.rotation.y = _t * 1.6

	# containment ring breathes; tightens during the "near-explosion" beat
	if _ring_mat != null:
		var strain: float = 0.0
		# in the middle of each cycle, the crystal surges (would-be explosion)
		if phase > 0.4 and phase < 0.6:
			strain = sin((phase - 0.4) / 0.2 * PI)
		_ring_mat.emission_energy_multiplier = (1.2 if emissive else 0.4) * (0.8 + 0.5 * strain)
		_ring_mat.albedo_color = accent.lerp(danger, strain * 0.5)
		if is_instance_valid(_ring):
			_ring.scale = Vector3.ONE * (1.0 - 0.06 * strain)   # ring clamps DOWN, containing

	# the conclusion lamps: in classical logic ALL would blaze during the surge.
	# here they only flicker faintly then settle — the explosion is quarantined.
	var surge: float = 0.0
	if phase > 0.4 and phase < 0.62:
		surge = sin((phase - 0.4) / 0.22 * PI)
	var i: int = 0
	while i < _conc_mats.size():
		var m: StandardMaterial3D = _conc_mats[i]
		# a brief threatened flare, capped low (never full explosion), then dark again
		var threat: float = surge * (0.3 + 0.2 * sin(float(i) * 1.7 + _t * 6.0))
		m.emission_energy_multiplier = (1.0 if emissive else 0.4) * clampf(threat, 0.0, 0.45)
		i += 1

	# readout: mostly STABLE, briefly notes the contained surge
	if is_instance_valid(_readout):
		if surge > 0.5:
			_readout.text = "SURGE CONTAINED"
			_readout.modulate = danger.lerp(accent, 0.5)
		else:
			_readout.text = "INFERENCE STABLE"
			_readout.modulate = accent
