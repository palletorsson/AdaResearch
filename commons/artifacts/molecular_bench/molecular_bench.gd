extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MolecularBench

## @identity
## name: Molecular Bench — Geometry Is the Constraint
## concept: Molecular design after crisis
## tier: medium
## lineage: post-crisis design after the foundations crisis. The molecular-design bench is
##   where making-from-the-limit becomes a craft. You do not draw the target molecule and
##   force the atoms to obey; you place atoms and let their valences decide what can close.
##   Each bonding slot is a hard geometric fact — an angle, a count — and the assembled shape
##   is the unique thing those facts permit. The limit is not the obstacle to the design; the
##   limit IS the material you are designing with.
## essence: a floor-standing bench (~1 m) holding a build-plate. Atoms feed in from a tray,
##   drift onto the plate, and snap to one another wherever an open valence slot meets an open
##   slot — bonds light warm teal as they close. A molecule grows by accretion of permitted
##   joins until no slot can close, then it lifts, rotates as a finished form, and the plate
##   clears for the next assembly. The shape is never imposed; it emerges from the constraint.
## truth: geometry is the constraint; the limit is the material. The molecule's form is
##   dictated by the slots — you build with the limit, not against it.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var bond_teal: Color = Color(0.35, 0.88, 0.80)      # warm constructive accent
@export var max_atoms: int = 9
@export var add_period: float = 0.55                        # seconds between atom snaps
@export var plate_radius: float = 0.30

var _t: float = 0.0
var _atoms: Array = []           # {pos:Vector3, mi:MeshInstance3D, valence:int, used:int, mat:StandardMaterial3D}
var _bonds: Array = []           # {a:int, b:int, mi:MeshInstance3D, mat:StandardMaterial3D, glow:float}
var _plate_y: float = 1.06
var _accum: float = 0.0
var _phase: String = "build"     # build -> finished -> clearing
var _hold: float = 0.0
var _mol_root: Node3D
var _readout: Label3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("max_atoms"):
		max_atoms = int(config["max_atoms"])
	if config.has("add_period"):
		add_period = float(config["add_period"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_atoms = []
	_bonds = []
	_accum = 0.0
	_phase = "build"
	_hold = 0.0
	_t = 0.0

	# --- bench (floor-standing ~1 m) ---
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.2, 0.7), _matte_mat(slate, 0.85, 0.1)))
	add_child(_cylinder(Vector3(0.0, 0.52, 0.0), 0.05, 0.65, _steel_mat(Color(0.34, 0.36, 0.42))))
	# build-plate disc the molecule assembles on
	add_child(_cylinder(Vector3(0.0, 0.84, 0.0), plate_radius + 0.02, 0.02, _matte_mat(slate, 0.7, 0.2)))
	add_child(_torus(Vector3(0.0, 0.86, 0.0), plate_radius + 0.02, 0.006, _glow_mat(wire_purple, 0.9)))
	# tray markers around the rim (where the atoms feed from)
	var r: int = 0
	while r < 6:
		var ang: float = float(r) / 6.0 * TAU
		add_child(_box(Vector3(cos(ang) * (plate_radius + 0.12), _plate_y - 0.02, sin(ang) * (plate_radius + 0.12)), Vector3(0.05, 0.02, 0.05), _glow_mat(wire_purple, 0.6)))
		r += 1

	# molecule lives under a sub-root so it can lift/clear as a unit
	_mol_root = Node3D.new()
	add_child(_mol_root)

	# seed the first atom at the plate centre
	_add_atom(Vector3(0.0, _plate_y, 0.0))

	# --- billboard title ---
	add_child(_billboard_label("GEOMETRY IS THE CONSTRAINT", Vector3(0.0, 1.5, 0.0), 24, cool_white))
	add_child(_billboard_label("the limit is the material", Vector3(0.0, 1.34, 0.0), 16, bond_teal))
	_readout = _billboard_label("ATOMS: 1  BONDS: 0", Vector3(0.0, 1.2, 0.0), 16, wire_purple)
	add_child(_readout)


func _add_atom(pos: Vector3) -> int:
	var palette: Array = [cool_white, Color(0.55, 0.78, 0.98), Color(0.82, 0.62, 0.96)]
	var col: Color = palette[_rng.randi() % palette.size()]
	var amat: StandardMaterial3D = _glow_mat(col, 0.9)
	var mi: MeshInstance3D = _sphere(pos, 0.03, amat)
	_mol_root.add_child(mi)
	var val: int = _rng.randi_range(2, 4)
	_atoms.append({"pos": pos, "mi": mi, "valence": val, "used": 0, "mat": amat})
	return _atoms.size() - 1


func _has_open_slot(idx: int) -> bool:
	var a: Dictionary = _atoms[idx]
	return int(a["used"]) < int(a["valence"])


func _bonded(a: int, b: int) -> bool:
	var e: int = 0
	while e < _bonds.size():
		var ed: Dictionary = _bonds[e]
		if (int(ed["a"]) == a and int(ed["b"]) == b) or (int(ed["a"]) == b and int(ed["b"]) == a):
			return true
		e += 1
	return false


func _snap_new_atom() -> bool:
	# pick an existing atom with an open slot to bond to; the new atom snaps at a
	# valence-permitted offset (geometry dictates where it can sit)
	var anchors: Array = []
	var i: int = 0
	while i < _atoms.size():
		if _has_open_slot(i):
			anchors.append(i)
		i += 1
	if anchors.size() == 0:
		return false
	var anc: int = int(anchors[_rng.randi() % anchors.size()])
	var ap: Vector3 = Vector3(_atoms[anc]["pos"])
	# permitted bond directions: spread around the plate, fixed bond length
	var ang: float = _rng.randf_range(0.0, TAU)
	var tilt: float = _rng.randf_range(-0.4, 0.4)
	var dir: Vector3 = Vector3(cos(ang), tilt, sin(ang)).normalized()
	var npos: Vector3 = ap + dir * 0.13
	# keep it over the plate
	var flat: Vector2 = Vector2(npos.x, npos.z)
	if flat.length() > plate_radius:
		flat = flat.normalized() * plate_radius
		npos = Vector3(flat.x, npos.y, flat.y)
	var newi: int = _add_atom(npos)
	_form_bond(anc, newi)
	return true


func _form_bond(a: int, b: int) -> void:
	var bmat: StandardMaterial3D = _glow_mat(bond_teal, 1.8)
	var mi: MeshInstance3D = _cylinder_between(Vector3(_atoms[a]["pos"]), Vector3(_atoms[b]["pos"]), 0.01, bmat)
	_mol_root.add_child(mi)
	_bonds.append({"a": a, "b": b, "mi": mi, "mat": bmat, "glow": 1.0})
	(_atoms[a] as Dictionary)["used"] = int((_atoms[a] as Dictionary)["used"]) + 1
	(_atoms[b] as Dictionary)["used"] = int((_atoms[b] as Dictionary)["used"]) + 1


func _clear_molecule() -> void:
	for c in _mol_root.get_children():
		_mol_root.remove_child(c)
		c.queue_free()
	_atoms = []
	_bonds = []
	_mol_root.position = Vector3.ZERO
	_mol_root.rotation = Vector3.ZERO
	_add_atom(Vector3(0.0, _plate_y, 0.0))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	if _phase == "build":
		_accum += delta
		if _accum >= add_period:
			_accum = 0.0
			if _atoms.size() >= max_atoms or not _snap_new_atom():
				_phase = "finished"
				_hold = 0.0
			if _readout != null:
				_readout.text = "ATOMS: %d  BONDS: %d" % [_atoms.size(), _bonds.size()]
	elif _phase == "finished":
		# the completed molecule lifts and rotates as one finished form
		_hold += delta
		_mol_root.position.y = lerpf(_mol_root.position.y, 0.35, delta * 1.5)
		_mol_root.rotation.y += delta * 0.8
		if _hold > 3.0:
			_phase = "clearing"
	elif _phase == "clearing":
		_clear_molecule()
		_phase = "build"
		if _readout != null:
			_readout.text = "ATOMS: 1  BONDS: 0"

	# --- animate bonds: fresh bonds flash, then settle into a steady teal glow ---
	var e: int = 0
	while e < _bonds.size():
		var ed: Dictionary = _bonds[e]
		ed["glow"] = maxf(0.35, float(ed["glow"]) - delta * 0.9)
		var bm: StandardMaterial3D = ed["mat"]
		bm.emission_energy_multiplier = (1.4 + 2.0 * float(ed["glow"])) if emissive else 0.3
		e += 1

	# --- atoms shimmer ---
	var q: int = 0
	while q < _atoms.size():
		var am: StandardMaterial3D = (_atoms[q] as Dictionary)["mat"]
		am.emission_energy_multiplier = (0.9 + 0.3 * sin(_t * 2.2 + float(q))) if emissive else 0.3
		q += 1
