extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EdgeGroundBench

## @identity
## name: Edge-Ground Bench — Build On the Limit, Not Despite It
## concept: The edge is the ground
## tier: medium
## lineage: post-crisis synthesis. The old instinct was to avoid the edge — to set foundations
##   far inside the safe, ordered interior and treat the boundary as a hazard to be fenced off.
##   The reversal: you build directly ON the limit. The edge-seam — the join between the ordered
##   crystal and the open void — is where the foundations are sunk, because that is the only
##   place with both the structure to hold and the openness to grow into. A tower whose piles
##   go down into the seam does not topple; it stands precisely because it is rooted in the limit.
## essence: a floor-standing bench (~1 m). Across its deck runs the edge-seam: an ordered lattice
##   on one half, an open void of motes on the other, the bright join between them. A small
##   structure RISES on the seam itself — foundation piles drive down INTO the join (lit warm),
##   then floors stack up above, course by course, stable. It builds, holds, and on completion
##   glows steady, then resets and rises again. Nothing is built away from the edge; everything
##   is built on it.
## truth: build on the limit, not despite it. Sink the foundations into the seam and it rises
##   stable — the edge bears the load.

# NOTE: `emissive` is declared by the parent (embodied_prop.gd) — do not redeclare.
@export var cool_white: Color = Color(0.90, 0.93, 1.0)
@export var slate: Color = Color(0.20, 0.23, 0.30)
@export var wire_purple: Color = Color(0.62, 0.50, 0.95)
@export var build_amber: Color = Color(0.98, 0.72, 0.32)    # warm "foundation in the limit" accent
@export var ground_teal: Color = Color(0.35, 0.88, 0.80)
@export var max_floors: int = 6
@export var build_period: float = 0.5                       # seconds between courses
@export var mote_count: int = 16

var _t: float = 0.0
var _deck_y: float = 0.84
var _seam_mat: StandardMaterial3D
var _piles: Array = []           # {mat:StandardMaterial3D}
var _floors: Array = []          # {mi:MeshInstance3D, mat:StandardMaterial3D, glow:float}
var _motes: Array = []
var _struct_root: Node3D
var _phase: String = "found"     # found -> rise -> hold -> reset
var _built: int = 0
var _accum: float = 0.0
var _hold: float = 0.0
var _readout: Label3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("max_floors"):
		max_floors = int(config["max_floors"])
	if config.has("build_period"):
		build_period = float(config["build_period"])
	if config.has("mote_count"):
		mote_count = int(config["mote_count"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_piles = []
	_floors = []
	_motes = []
	_phase = "found"
	_built = 0
	_accum = 0.0
	_hold = 0.0
	_t = 0.0

	# --- bench (floor-standing ~1 m) ---
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.2, 0.2, 0.7), _matte_mat(slate, 0.85, 0.1)))
	add_child(_cylinder(Vector3(0.0, 0.52, 0.0), 0.05, 0.65, _steel_mat(Color(0.34, 0.36, 0.42))))
	# deck
	add_child(_box(Vector3(0.0, _deck_y - 0.02, 0.0), Vector3(1.1, 0.02, 0.6), _matte_mat(slate, 0.7, 0.2)))

	# --- ORDER half: a cool regular lattice on the deck, z < 0 (well, x < 0) ---
	var order_mat: StandardMaterial3D = _glow_mat(wire_purple, 0.6)
	var gx: int = 0
	while gx < 4:
		var gz: int = 0
		while gz < 4:
			var p: Vector3 = Vector3(-0.45 + float(gx) * 0.1, _deck_y, -0.22 + float(gz) * 0.12)
			add_child(_box(p, Vector3(0.06, 0.03, 0.06), order_mat))
			gz += 1
		gx += 1

	# --- VOID half: open drifting motes, x > 0.1 ---
	var m: int = 0
	while m < mote_count:
		var base: Vector3 = Vector3(
			_rng.randf_range(0.16, 0.5),
			_deck_y + _rng.randf_range(0.02, 0.3),
			_rng.randf_range(-0.25, 0.25))
		var mote: MeshInstance3D = _sphere(base, 0.012, _glow_mat(cool_white, 0.7))
		add_child(mote)
		_motes.append({"mi": mote, "base": base, "phase": _rng.randf_range(0.0, TAU)})
		m += 1

	# --- THE SEAM: bright join down the middle (x = 0) — this is the ground we build on ---
	_seam_mat = _glow_mat(ground_teal, 1.6)
	add_child(_box(Vector3(0.0, _deck_y + 0.005, 0.0), Vector3(0.02, 0.02, 0.56), _seam_mat))

	# structure rises under its own root (so reset clears just it)
	_struct_root = Node3D.new()
	add_child(_struct_root)

	# --- billboard title ---
	add_child(_billboard_label("BUILD ON THE LIMIT", Vector3(0.0, 1.5, 0.0), 24, cool_white))
	add_child(_billboard_label("not despite it", Vector3(0.0, 1.34, 0.0), 16, ground_teal))
	_readout = _billboard_label("FOUNDATIONS: SINKING", Vector3(0.0, 1.2, 0.0), 16, build_amber)
	add_child(_readout)


func _add_piles() -> void:
	# foundation piles driven DOWN into the seam (the limit) — lit warm amber
	var offs: Array = [Vector3(-0.04, 0.0, -0.18), Vector3(0.04, 0.0, -0.18), Vector3(-0.04, 0.0, 0.18), Vector3(0.04, 0.0, 0.18)]
	var i: int = 0
	while i < offs.size():
		var o: Vector3 = offs[i]
		var pmat: StandardMaterial3D = _glow_mat(build_amber, 2.2)
		# pile sinks from deck down into the seam
		_struct_root.add_child(_cylinder(Vector3(o.x, _deck_y - 0.08, o.z), 0.018, 0.18, pmat))
		_piles.append({"mat": pmat})
		i += 1


func _add_floor(level: int) -> void:
	var y: float = _deck_y + 0.06 + float(level) * 0.12
	var fmat: StandardMaterial3D = _glow_mat(build_amber, 2.0)
	var slab: MeshInstance3D = _box(Vector3(0.0, y, 0.0), Vector3(0.16, 0.03, 0.42), fmat)
	_struct_root.add_child(slab)
	# corner columns up to this floor
	var cmat: StandardMaterial3D = _glow_mat(wire_purple, 0.8)
	_struct_root.add_child(_cylinder(Vector3(-0.06, y - 0.06, -0.18), 0.01, 0.12, cmat))
	_struct_root.add_child(_cylinder(Vector3(0.06, y - 0.06, -0.18), 0.01, 0.12, cmat))
	_struct_root.add_child(_cylinder(Vector3(-0.06, y - 0.06, 0.18), 0.01, 0.12, cmat))
	_struct_root.add_child(_cylinder(Vector3(0.06, y - 0.06, 0.18), 0.01, 0.12, cmat))
	_floors.append({"mi": slab, "mat": fmat, "glow": 1.0})


func _clear_structure() -> void:
	for c in _struct_root.get_children():
		_struct_root.remove_child(c)
		c.queue_free()
	_piles = []
	_floors = []


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta

	if _phase == "found":
		_accum += delta
		if _accum >= build_period:
			_accum = 0.0
			_add_piles()
			_phase = "rise"
			if _readout != null:
				_readout.text = "RISING ON THE SEAM"
	elif _phase == "rise":
		_accum += delta
		if _accum >= build_period:
			_accum = 0.0
			_add_floor(_built)
			_built += 1
			if _built >= max_floors:
				_phase = "hold"
				_hold = 0.0
				if _readout != null:
					_readout.text = "STANDS — THE EDGE HOLDS"
	elif _phase == "hold":
		_hold += delta
		if _hold > 2.5:
			_phase = "reset"
	elif _phase == "reset":
		_clear_structure()
		_built = 0
		_phase = "found"
		if _readout != null:
			_readout.text = "FOUNDATIONS: SINKING"

	# foundations and floors cool from warm amber toward steady teal as they settle
	var i: int = 0
	while i < _floors.size():
		var fd: Dictionary = _floors[i]
		fd["glow"] = maxf(0.0, float(fd["glow"]) - delta * 0.5)
		var fm: StandardMaterial3D = fd["mat"]
		var g: float = float(fd["glow"])
		fm.albedo_color = ground_teal.lerp(build_amber, g)
		fm.emission = ground_teal.lerp(build_amber, g)
		fm.emission_energy_multiplier = (1.2 + 1.6 * g) if emissive else 0.3
		i += 1

	# the load-bearing seam pulses
	if _seam_mat != null:
		var pulse: float = 0.5 + 0.5 * sin(_t * 2.0)
		_seam_mat.emission_energy_multiplier = (1.4 + 1.0 * pulse) if emissive else 0.3

	# void motes drift
	var m: int = 0
	while m < _motes.size():
		var md: Dictionary = _motes[m]
		var b: Vector3 = Vector3(md["base"])
		var ph: float = float(md["phase"])
		var mi: MeshInstance3D = md["mi"]
		if is_instance_valid(mi):
			mi.position = b + Vector3(
				sin(_t * 0.7 + ph) * 0.03,
				cos(_t * 0.8 + ph) * 0.03,
				sin(_t * 0.6 + ph) * 0.03)
		m += 1
