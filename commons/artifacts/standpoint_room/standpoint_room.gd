extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name StandpointRoom

## @identity
## name: Standpoint Room — Knowledge Has a Body
## concept: Situated computation
## tier: large
## lineage: the room-scale embodiment of Haraway's situated knowledges. After the
##   foundations crisis foreclosed the dream of a single God's-eye formalisation, the
##   constructive reply is to make standpoint a first-class part of the apparatus. You
##   walk into the room and the central object has no single true form: from each marked
##   standpoint it reads as a different shape, and the labels say so out loud. The room
##   does not hide the dependence on position — it stages it as the content.
## essence: a 7x7 room with a morphing centerpiece on a plinth. Four standpoint pads are
##   marked on the floor around it, each with a post, an eye-beacon, a sightline to the
##   centre, and a label naming what it sees (CUBE / SPHERE / SPIRAL / LATTICE). The
##   centerpiece slowly cycles its apparent form so that, standing on any one pad, the
##   object keeps resolving to that pad's reading.
## truth: knowledge has a body — the view changes with where you stand. The object is not
##   one fixed thing photographed from many sides; the standpoint is constitutive of what
##   gets seen, and naming the standpoint is the honest move.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.16, 0.18, 0.24)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var accent_warm: Color = Color(0.98, 0.70, 0.30)   # constructive amber accent
@export var morph_time: float = 4.0                         # seconds per form

var _t: float = 0.0
var _core_root: Node3D
var _core_forms: Array[Node3D] = []      # the four candidate forms (only one bright at a time)
var _pad_mats: Array[StandardMaterial3D] = []
var _eye_mats: Array[StandardMaterial3D] = []
var _line_mats: Array[StandardMaterial3D] = []
var _pad_colors: Array[Color] = []
var _core_pos: Vector3 = Vector3(0.0, 1.5, 0.0)
var _active_form: int = 0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("morph_time"):
		morph_time = float(config["morph_time"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_core_forms = []
	_pad_mats = []
	_eye_mats = []
	_line_mats = []
	_pad_colors = []

	# --- room floor (large tier: 7x7, y = -0.05) ---
	var floor_mat: StandardMaterial3D = _matte_mat(Color(0.11, 0.12, 0.15), 0.92)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(7.0, 0.1, 7.0), floor_mat))
	_floor_frame(3.4, 0.03, _glow_mat(wire_purple, 0.5))

	# --- central plinth ---
	add_child(_cylinder(Vector3(0.0, 0.4, 0.0), 0.45, 0.8, _matte_mat(slate, 0.8)))
	add_child(_cylinder(Vector3(0.0, 0.82, 0.0), 0.5, 0.06, _steel_mat(Color(0.30, 0.32, 0.37))))

	# --- the morphing centerpiece: four candidate forms stacked at the same point ---
	_core_root = Node3D.new()
	_core_root.position = _core_pos
	add_child(_core_root)
	# 0 = CUBE
	var f_cube: Node3D = Node3D.new()
	f_cube.add_child(_box(Vector3.ZERO, Vector3(0.7, 0.7, 0.7), _glow_mat(cool_white, 1.0)))
	_core_root.add_child(f_cube)
	_core_forms.append(f_cube)
	# 1 = SPHERE
	var f_sphere: Node3D = Node3D.new()
	f_sphere.add_child(_sphere(Vector3.ZERO, 0.5, _glow_mat(cool_white, 1.0)))
	_core_root.add_child(f_sphere)
	_core_forms.append(f_sphere)
	# 2 = SPIRAL — a coil of small spheres
	var f_spiral: Node3D = Node3D.new()
	var smat: StandardMaterial3D = _glow_mat(cool_white, 1.0)
	var k: int = 0
	while k < 18:
		var tt: float = float(k) / 18.0
		var ang: float = tt * TAU * 2.0
		var rr: float = 0.45 * (1.0 - tt * 0.5)
		var pos: Vector3 = Vector3(cos(ang) * rr, (tt - 0.5) * 0.8, sin(ang) * rr)
		f_spiral.add_child(_sphere(pos, 0.06, smat))
		k += 1
	_core_root.add_child(f_spiral)
	_core_forms.append(f_spiral)
	# 3 = LATTICE — a 3x3x3 wire grid of small cubes
	var f_lat: Node3D = Node3D.new()
	var lmat: StandardMaterial3D = _glow_mat(cool_white, 1.0)
	var gx: int = 0
	while gx < 3:
		var gy: int = 0
		while gy < 3:
			var gz: int = 0
			while gz < 3:
				var p: Vector3 = Vector3(float(gx - 1) * 0.28, float(gy - 1) * 0.28, float(gz - 1) * 0.28)
				f_lat.add_child(_box(p, Vector3(0.08, 0.08, 0.08), lmat))
				gz += 1
			gy += 1
		gx += 1
	_core_root.add_child(f_lat)
	_core_forms.append(f_lat)

	# wire shell around the whole ambiguous core
	add_child(_torus(_core_pos, 0.62, 0.01, _glow_mat(wire_purple, 0.6)))
	var shell2: MeshInstance3D = _torus(_core_pos, 0.62, 0.01, _glow_mat(wire_purple, 0.5))
	shell2.rotation = Vector3(PI / 2.0, 0.0, 0.0)
	add_child(shell2)

	# --- four standpoint pads around the core ---
	var see_names: Array[String] = ["CUBE", "SPHERE", "SPIRAL", "LATTICE"]
	var pad_cols: Array[Color] = [
		Color(0.40, 0.85, 0.95),   # teal
		accent_warm,               # amber
		Color(0.70, 0.55, 0.98),   # violet
		Color(0.50, 0.95, 0.65),   # green
	]
	var pad_radius: float = 2.7
	var pi_: int = 0
	while pi_ < 4:
		var ang: float = float(pi_) * TAU / 4.0 + PI / 4.0
		var pad_p: Vector3 = Vector3(cos(ang) * pad_radius, 0.0, sin(ang) * pad_radius)
		_pad_colors.append(pad_cols[pi_])
		# floor pad disc
		var pm: StandardMaterial3D = _glow_mat(pad_cols[pi_], 0.6)
		_pad_mats.append(pm)
		add_child(_cylinder(pad_p + Vector3(0.0, 0.03, 0.0), 0.55, 0.04, pm))
		# standpoint post + eye beacon
		add_child(_cylinder(pad_p + Vector3(0.0, 0.8, 0.0), 0.04, 1.5, _steel_mat(Color(0.32, 0.33, 0.37))))
		var eye_p: Vector3 = pad_p + Vector3(0.0, 1.6, 0.0)
		var eyem: StandardMaterial3D = _glow_mat(pad_cols[pi_], 1.3)
		_eye_mats.append(eyem)
		add_child(_sphere(eye_p, 0.14, eyem))
		add_child(_torus(eye_p, 0.22, 0.01, _glow_mat(pad_cols[pi_], 0.7)))
		# sightline from eye to the core
		var lm: StandardMaterial3D = _glow_mat(pad_cols[pi_], 0.9)
		_line_mats.append(lm)
		add_child(_cylinder_between(eye_p, _core_pos, 0.012, lm))
		# labels — what THIS standpoint sees
		add_child(_billboard_label("STANDPOINT " + char(65 + pi_), eye_p + Vector3(0.0, 0.36, 0.0), 22, pad_cols[pi_]))
		add_child(_billboard_label("sees a " + see_names[pi_], eye_p + Vector3(0.0, 0.12, 0.0), 18, pad_cols[pi_]))
		pi_ += 1

	# --- overhead label (large tier: y ~ 3.6) ---
	add_child(_billboard_label("KNOWLEDGE HAS A BODY — THE VIEW CHANGES WITH WHERE YOU STAND", Vector3(0.0, 3.6, 0.0), 30, cool_white))


func _floor_frame(half: float, rad: float, mat: Material) -> void:
	var y: float = 0.02
	var c0: Vector3 = Vector3(-half, y, -half)
	var c1: Vector3 = Vector3(half, y, -half)
	var c2: Vector3 = Vector3(half, y, half)
	var c3: Vector3 = Vector3(-half, y, half)
	add_child(_cylinder_between(c0, c1, rad, mat))
	add_child(_cylinder_between(c1, c2, rad, mat))
	add_child(_cylinder_between(c2, c3, rad, mat))
	add_child(_cylinder_between(c3, c0, rad, mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	# the centerpiece slowly turns
	if _core_root != null:
		_core_root.rotation.y += delta * 0.25

	# cycle which form is "the apparent form" — only the active one is bright/large
	_active_form = int(_t / maxf(morph_time, 0.5)) % 4
	# smooth blend factor within the current form's window (for a gentle morph feel)
	var local_t: float = fmod(_t, maxf(morph_time, 0.5)) / maxf(morph_time, 0.5)
	var rise: float = 0.5 - 0.5 * cos(local_t * TAU)   # 0..1..0 over the window

	var i: int = 0
	while i < _core_forms.size():
		var f: Node3D = _core_forms[i]
		if f != null:
			if i == _active_form:
				var s: float = 0.55 + 0.45 * rise
				f.scale = Vector3.ONE * s
				f.visible = true
				_set_form_glow(f, 1.0 + 0.8 * rise)
			else:
				f.scale = Vector3.ONE * 0.12
				_set_form_glow(f, 0.12)
		i += 1

	# the active pad + its sightline + eye glow brightest; others dim
	var p: int = 0
	while p < _pad_mats.size():
		var on: bool = (p == _active_form)
		var pulse: float = 1.4 + 0.5 * sin(_t * 4.0)
		if _pad_mats[p] != null:
			_pad_mats[p].emission_energy_multiplier = (pulse if on else 0.35) if emissive else (0.3 if on else 0.12)
		if _line_mats.size() > p and _line_mats[p] != null:
			_line_mats[p].emission_energy_multiplier = (pulse if on else 0.25) if emissive else (0.3 if on else 0.1)
		if _eye_mats.size() > p and _eye_mats[p] != null:
			_eye_mats[p].emission_energy_multiplier = ((0.9 + 0.6 * sin(_t * 3.0)) if on else 0.4) if emissive else (0.3 if on else 0.15)
		p += 1


func _set_form_glow(form: Node3D, energy: float) -> void:
	for child in form.get_children():
		if child is MeshInstance3D:
			var mi: MeshInstance3D = child as MeshInstance3D
			var mat: StandardMaterial3D = mi.material_override as StandardMaterial3D
			if mat != null:
				mat.emission_energy_multiplier = energy if emissive else energy * 0.3
