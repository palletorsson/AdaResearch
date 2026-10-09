extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CalderMobile

## @identity
## lineage: a hanging Calder mobile that is actually balanced — every arm obeys the lever
##   law τ = w·d, with leaf masses computed from real sheet-aluminium geometry (π r²·t·ρ),
##   so each rod would hang level in the world, not just in the eye.
## essence: a binary tree of steel arms. Build a node's two children first, weigh them, then
##   place the pivot so w_left·d_left = w_right·d_right; the heavier child rides the shorter
##   arm. Recurse, and the whole thing balances from a single point at the ceiling.
## truth: a mobile is the lever law made into art — Calder's genius was that the weights and
##   the lengths are doing real arithmetic while they drift.
##
## use_objects=false → Calder's flat painted discs (red/yellow/blue/black/white). use_objects
## =true → the project's own primitives (point, sphere, pyramid, arch) hung as the weights.
## A plaque states the real total mass and the balance principle.

@export var seed: int = 4
@export var use_objects: bool = false
@export var depth: int = 4
@export var span: float = 1.1                  # base half-rod length (grows up the tree)
@export_range(0.0, 1.0, 0.05) var leaf_prob: float = 0.34
@export var top_y: float = 3.6                 # ceiling mount height

## --- DNA (stage 2, promoted 2026-08-04) --------------------------------------------
## lever — WHETHER THE LAW BINDS. The artifact's whole claim is that τ = w·d is solved at
##   every arm, and the claim is checkable from a photograph, because a mobile that does
##   not balance hangs crooked. `solved` is the shipped mobile, pivot placed so
##   w_l·d_l = w_r·d_r and every rod dead level. `halved` ignores the law and cuts each
##   rod in the middle — the mistake anyone makes who thinks symmetry is balance.
##   `inverted` applies the law with the ratio the wrong way round, the heavier child on
##   the LONGER arm. Both leave a residual moment, and the rod is then hung BY that
##   residual instead of pretending it is zero: an honest lie the sculpture tells about
##   itself. The residual is derived, not styled — see _build_subtree.
## evidence — how much of the arithmetic stands beside the sculpture. Family word, taken
##   character for character from force_field_visualizer / weather_vector_field / the 32
##   others; three tiers, not four, because there is no symbolic-assertion-only state
##   here that is not just the plaque.
@export_enum("solved", "halved", "inverted") var lever: String = "solved"
@export_enum("result", "trace", "longhand") var evidence: String = "longhand"

const LEVERS := ["solved", "halved", "inverted"]
const EVIDENCE := ["result", "trace", "longhand"]

const PALETTE := [Color("cc1f1f"), Color("f0c020"), Color("2050c0"), Color("0a0a0a"), Color("f4f2ec")]
const SHEET_T := 0.003                          # 3 mm aluminium sheet
const DENSITY := 2700.0                         # kg/m³
# project objects for use_objects mode: [path, mass(kg), display_scale, label]
const OBJECTS := [
	["res://commons/primitives/point/point.tscn", 0.18, 0.5, "point"],
	["res://commons/primitives/sphere/sphere.tscn", 0.55, 0.32, "sphere"],
	["res://commons/primitives/pyramid/pyramid.tscn", 0.42, 0.4, "pyramid"],
	["res://commons/primitives/arch/arch.tscn", 0.7, 0.34, "arch"],
]

var _steel: StandardMaterial3D
var _total_mass: float = 0.0
var _n_leaves: int = 0
var _plaque: Label3D


func _ready() -> void:
	_build()


# Rebuild only when a value actually CHANGED, and only once _ready has built. The old
# body rebuilt on every call including ones naming nothing this prop owns — harmless here
# only because hash(seed) makes _build deterministic, so the torn-down mobile came back
# identical. Skipping that work is therefore byte-identical, not merely equivalent.
func apply_grid_config(config: Dictionary) -> void:
	var changed: bool = false
	if config.has("seed") and int(config["seed"]) != seed:
		seed = int(config["seed"]); changed = true
	if config.has("use_objects") and bool(config["use_objects"]) != use_objects:
		use_objects = bool(config["use_objects"]); changed = true
	if config.has("depth") and int(config["depth"]) != depth:
		depth = int(config["depth"]); changed = true
	if config.has("emissive") and bool(config["emissive"]) != emissive:
		emissive = bool(config["emissive"]); changed = true
	if config.has("lever"):
		var lv: String = str(config["lever"])
		if LEVERS.has(lv) and lv != lever:
			lever = lv; changed = true
	if config.has("evidence"):
		var ev: String = str(config["evidence"])
		if EVIDENCE.has(ev) and ev != evidence:
			evidence = ev; changed = true
	if changed and is_node_ready():
		_build()


func _build() -> void:
	for c in get_children():
		remove_child(c); c.queue_free()
	_rng.seed = hash(seed)
	_total_mass = 0.0
	_n_leaves = 0
	_steel = _matte_mat(Color(0.18, 0.19, 0.22), 0.4, 0.7)

	# ceiling mount + the top suspension wire
	add_child(_box(Vector3(0, top_y + 0.04, 0), Vector3(0.5, 0.08, 0.5), _matte_mat(Color(0.10, 0.11, 0.13), 0.6)))
	var sub := _build_subtree(depth, true)
	(sub["node"] as Node3D).position = Vector3(0, top_y, 0)
	add_child(sub["node"])

	# the plaque — the real measurement. Withheld below `longhand`: at `trace` the gram
	# tags stay and the total does not, at `result` the sculpture stands on its own.
	if evidence == "longhand":
		_plaque = _billboard_label(
			"ALEXANDER CALDER — mobile\n%s: τ = w·d at every arm\n%d %s · total %.2f kg\n%s" % [
				("balanced" if lever == "solved" else "NOT balanced"),
				_n_leaves, ("objects" if use_objects else "discs"), sub["mass"],
				("project primitives" if use_objects else "sheet aluminium, 3 mm")],
			Vector3(0, 0.2, 0.0), 26, Color(0.92, 0.93, 0.96))
		add_child(_plaque)


# Build a subtree hanging from this node's origin. Children are weighed first, then the
# pivot is placed so the arm balances. Returns {node, mass}.
func _build_subtree(d: int, is_root: bool) -> Dictionary:
	var root := Node3D.new()
	var drop: float = _rng.randf_range(0.4, 0.85) if not is_root else _rng.randf_range(0.25, 0.4)
	root.add_child(_wire(Vector3.ZERO, Vector3(0, -drop, 0)))
	var pivot := Vector3(0, -drop, 0)

	if d <= 0 or (not is_root and _rng.randf() < leaf_prob):
		var leaf := _make_leaf(pivot)
		root.add_child(leaf["node"])
		return {"node": root, "mass": leaf["mass"]}

	var left := _build_subtree(d - 1, false)
	var right := _build_subtree(d - 1, false)
	var wl: float = left["mass"]
	var wr: float = right["mass"]
	var total: float = wl + wr
	# the lever law: w_left·d_left = w_right·d_right  →  heavier child, shorter arm
	var arm: float = span * (0.7 + 0.35 * float(d)) * _rng.randf_range(0.85, 1.15)
	var dl: float = arm * wr / total
	var dr: float = arm * wl / total
	var lp: Vector3 = pivot + Vector3(-dl, 0, 0)
	var rp: Vector3 = pivot + Vector3(dr, 0, 0)
	if lever != "solved":
		# The law disobeyed. Place the pivot by the wrong rule, then hang the rod BY what
		# is left over rather than drawing it level anyway. A truly free arm swings until
		# the heavy end is straight down (cos θ → 0 kills the moment, so the only
		# equilibrium is vertical); that would fold the whole sculpture into a tangle, so
		# the residual moment is drawn as an angle instead — sin θ = residual / (arm·W),
		# the residual normalised by the largest moment this arm could carry. Zero
		# residual is zero tilt, which is why `solved` never reaches this branch at all.
		# The ladder is derived, not chosen: at `halved` the residual is arm·(wr−wl)/2 and
		# at `inverted` it is arm·(wr−wl), so the sign error leaves exactly twice the
		# residual of the naive middle-cut, in the same direction. sin θ doubles exactly;
		# the angle a little more than doubles, because asin is convex.
		if lever == "halved":
			dl = arm * 0.5
			dr = arm * 0.5
		else:                                   # inverted — heavier child, LONGER arm
			dl = arm * wl / total
			dr = arm * wr / total
		var tilt: float = asin(clampf((wr * dr - wl * dl) / (arm * total), -1.0, 1.0))
		lp = pivot + Vector3(-dl * cos(tilt), dl * sin(tilt), 0)
		rp = pivot + Vector3(dr * cos(tilt), -dr * sin(tilt), 0)
	root.add_child(_wire(lp, rp))                                 # the balancing rod
	root.add_child(_sphere(pivot, 0.022, _steel))                 # pivot bead
	(left["node"] as Node3D).position = lp
	(right["node"] as Node3D).position = rp
	root.add_child(left["node"])
	root.add_child(right["node"])
	return {"node": root, "mass": total}


func _make_leaf(at: Vector3) -> Dictionary:
	return _make_object_leaf(at) if use_objects else _make_shape_leaf(at)


# A flat painted disc — mass = π r²·t·ρ (real sheet-metal weight).
func _make_shape_leaf(at: Vector3) -> Dictionary:
	var node := Node3D.new(); node.position = at
	var r: float = _rng.randf_range(0.09, 0.24)
	# Calder uses black liberally but the primaries carry it — weight toward colour
	var roll: float = _rng.randf()
	var col: Color = PALETTE[_rng.randi() % 3] if roll < 0.68 else (PALETTE[3] if roll < 0.88 else PALETTE[4])
	var mesh := CylinderMesh.new()
	mesh.top_radius = r; mesh.bottom_radius = r; mesh.height = SHEET_T
	mesh.radial_segments = 28
	var disc := MeshInstance3D.new()
	disc.mesh = mesh
	disc.material_override = _matte_mat(col, 0.55, 0.1)
	disc.rotation = Vector3(PI * 0.5, _rng.randf_range(-0.35, 0.35), _rng.randf_range(-0.2, 0.2))  # face the room, organic tilt
	disc.position = Vector3(0, -r, 0)                            # hang below the wire end
	node.add_child(disc)
	node.add_child(_wire(Vector3.ZERO, Vector3(0, -r * 0.5, 0)))  # short hanger
	var mass: float = PI * r * r * SHEET_T * DENSITY
	if evidence != "result":
		node.add_child(_leaf_tag("%.0f g" % (mass * 1000.0), Vector3(0, -r - 0.12, 0)))
	_total_mass += mass; _n_leaves += 1
	return {"node": node, "mass": mass}


# A project primitive hung as the weight.
func _make_object_leaf(at: Vector3) -> Dictionary:
	var node := Node3D.new(); node.position = at
	var pick: Array = OBJECTS[_rng.randi() % OBJECTS.size()]
	var drop := 0.28
	node.add_child(_wire(Vector3.ZERO, Vector3(0, -drop, 0)))
	var scene: PackedScene = load(pick[0]) if ResourceLoader.exists(pick[0]) else null
	if scene:
		var inst: Node = scene.instantiate()
		if inst is Node3D:
			var holder := Node3D.new()
			holder.position = Vector3(0, -drop - 0.18, 0)
			holder.scale = Vector3.ONE * float(pick[2])
			holder.add_child(inst)
			node.add_child(holder)
			_freeze_bodies(inst)                                 # don't let pickables fall
	else:
		# fallback: a labelled cube
		node.add_child(_box(Vector3(0, -drop - 0.18, 0), Vector3(0.22, 0.22, 0.22), _matte_mat(PALETTE[_rng.randi() % 3], 0.5)))
	if evidence != "result":
		node.add_child(_leaf_tag("%s · %.0f g" % [pick[3], float(pick[1]) * 1000.0], Vector3(0, -drop - 0.42, 0)))
	_total_mass += float(pick[1]); _n_leaves += 1
	return {"node": node, "mass": float(pick[1])}


func _freeze_bodies(n: Node) -> void:
	if n is RigidBody3D:
		(n as RigidBody3D).freeze = true
	if n is Node3D and n.has_method("set_physics_process"):
		pass
	for c in n.get_children():
		_freeze_bodies(c)


func _wire(a: Vector3, b: Vector3) -> MeshInstance3D:
	return _cylinder_between(a, b, 0.006, _steel)


func _leaf_tag(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 28
	l.pixel_size = 0.0011
	l.modulate = Color(0.75, 0.78, 0.84)
	l.outline_size = 4
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	return l
