extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SituatedBench

## @identity
## name: Situated Bench — No View From Nowhere
## concept: Situated computation
## tier: medium
## lineage: Donna Haraway's situated knowledges, read as an engineering constraint after
##   the foundations crisis. There is no "view from nowhere" — every measurement, every
##   dataset reading, is taken from a standpoint, with a body, an instrument, a position.
##   The post-crisis move is not to lament this (as if objectivity were lost) but to BUILD
##   with it: make the standpoint explicit, render the same data three ways for three
##   viewers, and treat the disagreement between readings as data about position, not error.
## essence: a floor-standing bench with one central dataset object at the middle. Around it
##   sit three little viewpoints — three instrument "eyes" on posts. Each eye casts a
##   coloured sightline to the centre, and beside each eye a small readout shows the SHAPE
##   that standpoint sees: from one angle a cube, from another a ring, from another a spike.
##   Same data, three bodies, three readings.
## truth: there is no view from nowhere; every reading has a standpoint. The shape you
##   measure is a fact about the data AND about where you stood to measure it.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent_a: Color = Color(0.40, 0.85, 0.95)   # standpoint A — teal
@export var accent_b: Color = Color(0.98, 0.72, 0.32)   # standpoint B — amber
@export var accent_c: Color = Color(0.70, 0.55, 0.98)   # standpoint C — violet
@export var spin_speed: float = 0.4

var _t: float = 0.0
var _center_mat: StandardMaterial3D
var _eye_mats: Array[StandardMaterial3D] = []
var _line_mats: Array[StandardMaterial3D] = []
var _readout_root: Array[Node3D] = []     # the three "what it sees" mini-shapes
var _center_pos: Vector3 = Vector3(0.0, 0.78, 0.0)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("spin_speed"):
		spin_speed = float(config["spin_speed"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_eye_mats = []
	_line_mats = []
	_readout_root = []

	# --- bench base ~1 m ---
	var base_mat: StandardMaterial3D = _matte_mat(slate, 0.85)
	add_child(_box(Vector3(0.0, 0.36, 0.0), Vector3(1.0, 0.16, 1.0), base_mat))
	var leg_mat: StandardMaterial3D = _steel_mat(Color(0.30, 0.31, 0.34))
	for sx in [-0.42, 0.42]:
		for sz in [-0.42, 0.42]:
			add_child(_cylinder(Vector3(sx, 0.18, sz), 0.03, 0.36, leg_mat))

	# --- central dataset object: a faceted, ambiguous core (the SAME data) ---
	_center_mat = _glow_mat(cool_white, 0.9)
	# pillar up to the core
	add_child(_cylinder(Vector3(0.0, 0.55, 0.0), 0.03, 0.32, _steel_mat(Color(0.34, 0.35, 0.38))))
	add_child(_sphere(_center_pos, 0.13, _center_mat))
	# wire cage around it — the raw, un-standpointed data
	add_child(_torus(_center_pos, 0.18, 0.006, _glow_mat(wire_purple, 0.7)))
	var ring2: MeshInstance3D = _torus(_center_pos, 0.18, 0.006, _glow_mat(wire_purple, 0.6))
	ring2.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	add_child(ring2)
	add_child(_billboard_label("DATASET", _center_pos + Vector3(0.0, 0.26, 0.0), 16, cool_white))

	# --- three standpoints around the centre, each seeing a different shape ---
	var accents: Array[Color] = [accent_a, accent_b, accent_c]
	var see_names: Array[String] = ["a CUBE", "a RING", "a SPIKE"]
	var si: int = 0
	while si < 3:
		var ang: float = float(si) * TAU / 3.0 - PI / 2.0
		var eye_p: Vector3 = Vector3(cos(ang) * 0.42, 0.78, sin(ang) * 0.42)
		# instrument post
		add_child(_cylinder(Vector3(eye_p.x, 0.56, eye_p.z), 0.018, 0.30, _steel_mat(Color(0.32, 0.33, 0.37))))
		# the eye
		var em: StandardMaterial3D = _glow_mat(accents[si], 1.2)
		_eye_mats.append(em)
		add_child(_sphere(eye_p, 0.05, em))
		add_child(_torus(eye_p, 0.075, 0.005, _glow_mat(accents[si], 0.7)))
		# coloured sightline from eye to centre
		var lm: StandardMaterial3D = _glow_mat(accents[si], 0.9)
		_line_mats.append(lm)
		add_child(_cylinder_between(eye_p, _center_pos, 0.006, lm))
		# the readout: a small mini-shape next to the eye = what THIS standpoint sees
		var readout: Node3D = Node3D.new()
		readout.position = eye_p + Vector3(0.0, 0.16, 0.0)
		var shape_mat: StandardMaterial3D = _glow_mat(accents[si], 1.0)
		if si == 0:
			# CUBE
			readout.add_child(_box(Vector3.ZERO, Vector3(0.07, 0.07, 0.07), shape_mat))
		elif si == 1:
			# RING
			readout.add_child(_torus(Vector3.ZERO, 0.045, 0.012, shape_mat))
		else:
			# SPIKE — a cone via short tapered cylinder stack
			readout.add_child(_box(Vector3(0.0, 0.0, 0.0), Vector3(0.02, 0.09, 0.02), shape_mat))
			readout.add_child(_sphere(Vector3(0.0, 0.05, 0.0), 0.016, shape_mat))
		add_child(readout)
		_readout_root.append(readout)
		# standpoint label
		add_child(_billboard_label("STANDPOINT " + char(65 + si), eye_p + Vector3(0.0, -0.12, 0.0), 14, accents[si]))
		add_child(_billboard_label("sees " + see_names[si], eye_p + Vector3(0.0, 0.30, 0.0), 13, accents[si]))
		si += 1

	# --- title (medium tier: y ~ 1.5) ---
	add_child(_billboard_label("NO VIEW FROM NOWHERE", Vector3(0.0, 1.5, 0.0), 26, cool_white))
	add_child(_billboard_label("every reading has a standpoint", Vector3(0.0, 1.38, 0.0), 15, Color(0.78, 0.84, 0.96)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# the central data shimmers — it is genuinely ambiguous, not fixed
	if _center_mat != null:
		var sh: float = 0.7 + 0.4 * sin(_t * 1.8)
		_center_mat.emission_energy_multiplier = sh if emissive else sh * 0.3
	# each standpoint's readout slowly rotates and breathes on its own phase
	var i: int = 0
	while i < _readout_root.size():
		var r: Node3D = _readout_root[i]
		if r != null:
			r.rotation.y += delta * (0.6 + 0.2 * float(i))
		# sightlines pulse in turn — attention moving between standpoints
		if _line_mats.size() > i and _line_mats[i] != null:
			var beat: float = 0.5 + 0.5 * sin(_t * 1.2 - float(i) * (TAU / 3.0))
			_line_mats[i].emission_energy_multiplier = (0.5 + 0.9 * beat) if emissive else 0.3
		if _eye_mats.size() > i and _eye_mats[i] != null:
			var ebeat: float = 0.6 + 0.5 * sin(_t * 1.2 - float(i) * (TAU / 3.0))
			_eye_mats[i].emission_energy_multiplier = (0.7 + 0.7 * ebeat) if emissive else 0.3
		i += 1
