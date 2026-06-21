extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MolecularToy

## @identity
## name: Molecular Toy — Build From Valence, Not From Blueprint
## concept: Molecular design after crisis
## tier: small
## lineage: post-crisis design after the foundations crisis. When no master blueprint can be
##   trusted, you build from what the parts ALLOW. A molecule is not drawn and then enforced —
##   it self-assembles because each atom carries a fixed number of bonding slots (its valence),
##   and the only shapes that can exist are the ones those slots permit. The constraint is not
##   a limit imposed from outside; it is the material's own grammar, and it is generative.
## essence: a held cluster (~0.4 m). A handful of atoms (coloured spheres) each carry a small
##   number of valence slots shown as short stubs. An atom with a FREE slot drifts until its
##   stub meets another atom's free stub, then locks — a bond forms (a teal link lights), the
##   two slots consumed. The shape that emerges (a chain, a ring, a little tetrahedral knot)
##   was never specified; it is whatever the valences could close into. When all slots are
##   filled the molecule is stable and rotates, complete.
## truth: build from valence, not from blueprint. The geometry is the constraint, and the
##   constraint is what makes the form — the shape is dictated by the slots, not the plan.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var bond_teal: Color = Color(0.35, 0.88, 0.80)      # warm constructive accent (a bond)
@export var atom_count: int = 6
@export var bond_period: float = 0.9                        # seconds between bond attempts
@export var spin_speed: float = 0.35

var _t: float = 0.0
var _atoms: Array = []           # {pos:Vector3, valence:int, used:int, mat:StandardMaterial3D, stubs:Array}
var _bonds: Array = []           # {a:int, b:int, mat:StandardMaterial3D, glow:float}
var _accum: float = 0.0
var _stable: bool = false
var _title: Label3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("atom_count"):
		atom_count = int(config["atom_count"])
	if config.has("bond_period"):
		bond_period = float(config["bond_period"])
	if config.has("spin_speed"):
		spin_speed = float(config["spin_speed"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_atoms = []
	_bonds = []
	_accum = 0.0
	_stable = false
	_t = 0.0

	# --- scatter atoms in a small blob (no tier base — held object ~0.4 m) ---
	var palette: Array = [cool_white, Color(0.55, 0.78, 0.98), Color(0.82, 0.62, 0.96)]
	var n: int = 0
	while n < atom_count:
		var p: Vector3 = Vector3(
			_rng.randf_range(-0.16, 0.16),
			_rng.randf_range(-0.12, 0.12),
			_rng.randf_range(-0.16, 0.16))
		# valence 1..3 — the fixed number of bonding slots this atom carries
		var val: int = _rng.randi_range(1, 3)
		var col: Color = palette[_rng.randi() % palette.size()]
		var amat: StandardMaterial3D = _glow_mat(col, 0.9)
		var mi: MeshInstance3D = _sphere(p, 0.028, amat)
		add_child(mi)
		# valence stubs: short purple spokes radiating from the atom (the open slots)
		var stubs: Array = []
		var s: int = 0
		while s < val:
			var dir: Vector3 = Vector3(
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0),
				_rng.randf_range(-1.0, 1.0)).normalized()
			var smat: StandardMaterial3D = _glow_mat(wire_purple, 0.8)
			var stub_mi: MeshInstance3D = _cylinder_between(p, p + dir * 0.034, 0.004, smat)
			add_child(stub_mi)
			stubs.append({"mi": stub_mi, "mat": smat, "dir": dir, "open": true})
			s += 1
		_atoms.append({"pos": p, "valence": val, "used": 0, "mat": amat, "col": col, "stubs": stubs})
		n += 1

	# --- billboard title ---
	_title = _billboard_label("BUILD FROM VALENCE", Vector3(0.0, 0.27, 0.0), 18, cool_white)
	add_child(_title)


func _free_atom() -> int:
	# an atom with at least one open slot still seeking a bond
	var out: Array = []
	var i: int = 0
	while i < _atoms.size():
		var a: Dictionary = _atoms[i]
		if int(a["used"]) < int(a["valence"]):
			out.append(i)
		i += 1
	if out.size() == 0:
		return -1
	return int(out[_rng.randi() % out.size()])


func _nearest_free_partner(idx: int) -> int:
	# nearest other atom that also has an open slot and is not already bonded to idx
	var best: int = -1
	var bestd: float = 1e9
	var pa: Vector3 = Vector3(_atoms[idx]["pos"])
	var j: int = 0
	while j < _atoms.size():
		if j != idx:
			var aj: Dictionary = _atoms[j]
			if int(aj["used"]) < int(aj["valence"]) and not _bonded(idx, j):
				var d: float = pa.distance_to(Vector3(aj["pos"]))
				if d < bestd:
					bestd = d
					best = j
		j += 1
	return best


func _bonded(a: int, b: int) -> bool:
	var e: int = 0
	while e < _bonds.size():
		var ed: Dictionary = _bonds[e]
		if (int(ed["a"]) == a and int(ed["b"]) == b) or (int(ed["a"]) == b and int(ed["b"]) == a):
			return true
		e += 1
	return false


func _consume_stub(idx: int, toward: Vector3) -> void:
	# spend one open slot on the atom nearest the bond direction; light it teal
	var a: Dictionary = _atoms[idx]
	var stubs: Array = a["stubs"]
	var want: Vector3 = (toward - Vector3(a["pos"])).normalized()
	var pick: int = -1
	var bestdot: float = -2.0
	var s: int = 0
	while s < stubs.size():
		var st: Dictionary = stubs[s]
		if bool(st["open"]):
			var dt: float = (Vector3(st["dir"])).dot(want)
			if dt > bestdot:
				bestdot = dt
				pick = s
		s += 1
	if pick >= 0:
		var chosen: Dictionary = stubs[pick]
		chosen["open"] = false
		var sm: StandardMaterial3D = chosen["mat"]
		sm.albedo_color = bond_teal
		sm.emission = bond_teal
	a["used"] = int(a["used"]) + 1


func _form_bond(a: int, b: int) -> void:
	# the geometry is the constraint: a bond consumes one slot on each atom
	_consume_stub(a, Vector3(_atoms[b]["pos"]))
	_consume_stub(b, Vector3(_atoms[a]["pos"]))
	var bmat: StandardMaterial3D = _glow_mat(bond_teal, 1.6)
	add_child(_cylinder_between(Vector3(_atoms[a]["pos"]), Vector3(_atoms[b]["pos"]), 0.009, bmat))
	_bonds.append({"a": a, "b": b, "mat": bmat, "glow": 1.0})


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	rotation.y += delta * spin_speed

	# --- attempt to close one bond per tick, while open slots remain ---
	if not _stable:
		_accum += delta
		if _accum >= bond_period:
			_accum = 0.0
			var src: int = _free_atom()
			if src >= 0:
				var partner: int = _nearest_free_partner(src)
				if partner >= 0:
					_form_bond(src, partner)
				else:
					# no partner reachable: this atom's remaining slots cannot close — molecule done
					_stable = true
			else:
				_stable = true
			# all slots filled? the molecule is complete and stable
			var open_left: bool = false
			var k: int = 0
			while k < _atoms.size():
				if int((_atoms[k] as Dictionary)["used"]) < int((_atoms[k] as Dictionary)["valence"]):
					open_left = true
					break
				k += 1
			if not open_left:
				_stable = true

	# --- animate bonds: fresh bonds flash then settle into a steady teal glow ---
	var e: int = 0
	while e < _bonds.size():
		var ed: Dictionary = _bonds[e]
		ed["glow"] = maxf(0.4, float(ed["glow"]) - delta * 0.9)
		var bm: StandardMaterial3D = ed["mat"]
		bm.emission_energy_multiplier = (1.4 + 1.8 * float(ed["glow"])) if emissive else 0.3
		e += 1

	# --- atoms breathe; brighter once the molecule is stable ---
	var q: int = 0
	while q < _atoms.size():
		var am: StandardMaterial3D = (_atoms[q] as Dictionary)["mat"]
		var base: float = 1.3 if _stable else 0.9
		am.emission_energy_multiplier = (base + 0.3 * sin(_t * 2.0 + float(q))) if emissive else 0.3
		q += 1

	if _stable and _title != null:
		_title.text = "BUILD FROM VALENCE — STABLE"
		_title.modulate = bond_teal
