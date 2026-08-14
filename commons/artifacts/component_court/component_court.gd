## component_court — one vector, four ways of taking it apart, asked of four vector artifacts.
##
## THE FAMILY. Four artifacts let you decompose a vector and share one vocabulary for how:
## chain, star, box, none. Read from their dispatch rather than their prose:
##
##   chain  the components walked TIP TO TAIL — origin -> x -> xy -> tip. force_cube:132-136
##          draws exactly that and says "the last leg lands exactly on the resultant's point".
##   star   the three terms of the sum, EACH LEAVING THE ORIGIN. basis_vectors_rig:694-697
##          calls them "the three terms of the sum, each leaving the origin".
##   box    the twelve edges of the solid the components span, whose body diagonal IS the
##          vector. force_cube:138-141: "the diagonal is the resultant arrow drawn below, so
##          the box closes on the force itself".
##   none   the claim left to the arrow alone. force_cube:142-144, a bare `pass`.
##
## THE SAME THREE NUMBERS, DRAWN AS A SEQUENCE OR AS A SET. That is the whole argument and it
## is not a metaphor: chain and star draw identical component vectors and differ only in
## where each one starts. Chain says addition is a JOURNEY and the order of the legs is the
## order you walked them. Star says addition is a FACT and the three terms are simultaneous.
## Box says the components span a solid and the vector is its diagonal. None says: do not take
## it apart.
##
## AND THE TIP NEVER MOVES. Whatever you do to the decomposition, u+v+w lands in the same
## place — the resultant arrow is drawn AFTER the match block in every member and no branch
## touches it. That invariance is the point of the court and it is what dna.predicted_relationship
## asserts.
##
## ONE MEMBER SHIPS THE UNION AND CALLS IT `both`. force_cube:42 declares
## ("both", "chain", "box", "none") — no `star` — and its default branch (:145-153) draws the
## dashed staircase AND the three legs from the origin. So `both` is chain UNION star, named
## as if it were a fifth thing. It is drawn here as its own bay rather than argued about.
##
## LAW 16, FROM THE MEMBERS' CODE: the four members are PARALLEL — four scenes, four
## exclusive `match decomposition:` blocks, no shared state — so the members are the exhibit
## and `decomposition` is the AXIS. Same shape as residue_hall and aftermath_grove.
##
## THE SECOND AXIS IS `obliquity`, AND THE FAMILY NAMES THE INTERACTION WITHOUT SWEEPING IT.
## basis_vectors_rig:699-702 says its box is "a rectangular box under an orthogonal frame, a
## parallelepiped under a skewed one, which is where the two axes read each other". So the
## basis angle is a real second question that the family already knows changes the answer, and
## no member ever varied it against decomposition. square is orthogonal; leaning and skewed
## shear the second and third basis vectors while HOLDING THE RESULTANT FIXED, so the tip
## stays put and only the route to it changes.
##
## LAW 1: NO BAR, NO SLAT, NO RACK. Every bay draws arrows, legs and a spanned solid in real
## coordinates — the geometry these four artifacts are made of.
extends Node3D
class_name ComponentCourt

@export_enum("chain", "star", "box", "none") var decomposition: String = "chain"
const DECOMPOSITIONS: PackedStringArray = ["chain", "star", "box", "none"]

## Declared SECOND: the gallery trims from the end of the later axis, and `skewed` is the
## value a capped sweep can most afford to lose. 4 x 3 = 12 fits a cap of 16 whole.
@export_enum("square", "leaning", "skewed") var obliquity: String = "square"
const OBLIQUITIES: PackedStringArray = ["square", "leaning", "skewed"]

# ── the four bays, one per member ────────────────────────────────────────────
const BAY_X: Array = [-1.35, -0.45, 0.45, 1.35]
const BAY_NAME: PackedStringArray = ["basis_vectors_rig", "example_1_5_vector_magnitude_vr",
		"vector_magnitude_demo", "force_cube"]
## Bay 4 is force_cube, the member that ships `both`. At decomposition = star it draws its
## OWN word instead — the union — because it has no `star` to draw. The refusal is the mark.
const BAY_BOTH: int = 3

## THE RESULTANT IS THE SAME IN EVERY BAY AND AT EVERY VALUE. One vector, four readings.
const RESULTANT := Vector3(0.42, 0.36, 0.30)

const ARROW_R: float = 0.012
const LEG_R: float = 0.009
const EDGE_R: float = 0.004

const COL_X := Color(1.00, 0.42, 0.38)
const COL_Y := Color(0.45, 0.95, 0.55)
const COL_Z := Color(0.42, 0.68, 1.00)
const COL_RESULT := Color(1.00, 0.86, 0.30)
const COL_EDGE := Color(0.60, 0.62, 0.68)
const COL_RIM := Color(0.40, 0.43, 0.52)

var _owned: Array[Node] = []


func _ready() -> void:
	_check_hints()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("decomposition"):
		var d: String = str(config_data["decomposition"]).strip_edges().to_lower()
		if DECOMPOSITIONS.has(d):
			decomposition = d
	if config_data.has("obliquity"):
		var o: String = str(config_data["obliquity"]).strip_edges().to_lower()
		if OBLIQUITIES.has(o):
			obliquity = o
	for n in _owned:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_owned.clear()
	_build()


func _check_hints() -> void:
	for pair in [["decomposition", DECOMPOSITIONS], ["obliquity", OBLIQUITIES]]:
		var key: String = pair[0]
		var want: PackedStringArray = pair[1]
		for p in get_property_list():
			if String(p.get("name", "")) != key:
				continue
			var got := PackedStringArray()
			for part in String(p.get("hint_string", "")).split(",", false):
				got.append(part.split(":")[0].strip_edges())
			if got != want:
				push_error("component_court: '%s' hint %s != const %s" % [key, got, want])
			break


## THE BASIS. square is orthogonal; the other two shear the second and third vectors. The
## components are then SOLVED so that u + v + w is still exactly RESULTANT — the tip is
## nailed down and only the route to it moves. Without that solve, obliquity would move the
## answer as well as the decomposition and the two axes would be entangled.
func _basis() -> Array:
	var i := Vector3.RIGHT
	var j := Vector3.UP
	var k := Vector3.FORWARD
	match obliquity:
		"leaning":
			j = Vector3(0.34, 1.0, 0.0).normalized()
			k = Vector3(0.0, 0.18, 1.0).normalized()
		"skewed":
			j = Vector3(0.62, 1.0, 0.16).normalized()
			k = Vector3(0.30, 0.44, 1.0).normalized()
	# solve a*i + b*j + c*k = RESULTANT by Cramer's rule on the 3x3 basis
	var det: float = i.dot(j.cross(k))
	if absf(det) < 0.0001:
		return [i * RESULTANT.x, j * RESULTANT.y, k * RESULTANT.z]
	var a: float = RESULTANT.dot(j.cross(k)) / det
	var b: float = i.dot(RESULTANT.cross(k)) / det
	var c: float = i.dot(j.cross(RESULTANT)) / det
	return [i * a, j * b, k * c]


func _build() -> void:
	var comp: Array = _basis()
	for bay in 4:
		var root := Node3D.new()
		root.name = "bay_%d" % bay
		root.position = Vector3(BAY_X[bay], 0.0, 0.0)
		add_child(root)
		_owned.append(root)
		_rim(root)
		_draw_bay(root, comp, bay)


## One datum square per bay. No plinth: two of these members put components below y = 0 under
## a skewed basis, and a slab would hide the part that moved.
func _rim(bay: Node3D) -> void:
	var h: float = 0.42
	var pts := [Vector3(-h, 0, -h), Vector3(h, 0, -h), Vector3(h, 0, h), Vector3(-h, 0, h)]
	for i in 4:
		_rod(bay, pts[i], pts[(i + 1) % 4], 0.005, COL_RIM, 0.3)


func _draw_bay(bay: Node3D, comp: Array, idx: int) -> void:
	var u: Vector3 = comp[0]
	var v: Vector3 = comp[1]
	var w: Vector3 = comp[2]
	var mode: String = decomposition
	# force_cube has no `star`; asked for one it draws its own word, the union.
	if idx == BAY_BOTH and mode == "star":
		mode = "both"

	match mode:
		"chain":
			# TIP TO TAIL. The last leg lands exactly on the resultant's point.
			_arrow(bay, Vector3.ZERO, u, LEG_R, COL_X, 1.2)
			_arrow(bay, u, u + v, LEG_R, COL_Y, 1.2)
			_arrow(bay, u + v, u + v + w, LEG_R, COL_Z, 1.2)
		"star":
			# The three terms of the sum, each leaving the origin.
			_arrow(bay, Vector3.ZERO, u, LEG_R, COL_X, 1.2)
			_arrow(bay, Vector3.ZERO, v, LEG_R, COL_Y, 1.2)
			_arrow(bay, Vector3.ZERO, w, LEG_R, COL_Z, 1.2)
		"box":
			# The solid the components span. Rectangular under an orthogonal basis, a
			# PARALLELEPIPED under a skewed one — the interaction basis_vectors_rig names
			# in its own comment and never swept.
			for e in _span_edges(u, v, w):
				_rod(bay, e[0], e[1], EDGE_R, COL_EDGE, 0.5)
		"both":
			# force_cube's union: the dashed staircase AND the three legs from the origin.
			_rod(bay, Vector3.ZERO, u, EDGE_R, COL_EDGE, 0.4)
			_rod(bay, u, u + v, EDGE_R, COL_EDGE, 0.4)
			_rod(bay, u + v, u + v + w, EDGE_R, COL_EDGE, 0.4)
			_arrow(bay, Vector3.ZERO, u, LEG_R, COL_X, 1.2)
			_arrow(bay, Vector3.ZERO, v, LEG_R, COL_Y, 1.2)
			_arrow(bay, Vector3.ZERO, w, LEG_R, COL_Z, 1.2)
		_:
			# `none` — the claim left to the arrow alone.
			pass

	# THE RESULTANT, DRAWN AFTER THE MATCH IN EVERY MEMBER AND TOUCHED BY NO BRANCH.
	_arrow(bay, Vector3.ZERO, u + v + w, ARROW_R, COL_RESULT, 1.9)


## The twelve edges of the parallelepiped spanned by u, v, w.
func _span_edges(u: Vector3, v: Vector3, w: Vector3) -> Array:
	var o := Vector3.ZERO
	return [
		[o, u], [v, v + u], [w, w + u], [v + w, v + w + u],
		[o, v], [u, u + v], [w, w + v], [u + w, u + w + v],
		[o, w], [u, u + w], [v, v + w], [u + v, u + v + w],
	]


# ── drawing ──────────────────────────────────────────────────────────────────

func _mat(c: Color, e: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.45
	if e > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = e
	return m


func _rod(parent: Node3D, a: Vector3, b: Vector3, r: float, c: Color, e: float) -> void:
	var d := b - a
	var len_m: float = d.length()
	if len_m < 0.0005:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = len_m
	cyl.radial_segments = 6
	cyl.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = cyl
	mi.transform = _between(a, b, len_m)
	mi.material_override = _mat(c, e)
	parent.add_child(mi)


func _arrow(parent: Node3D, a: Vector3, b: Vector3, r: float, c: Color, e: float) -> void:
	var d := b - a
	var len_m: float = d.length()
	if len_m < 0.0005:
		return
	var head: float = minf(0.055, len_m * 0.32)
	var shaft_end: Vector3 = b - d.normalized() * head
	_rod(parent, a, shaft_end, r, c, e)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = r * 2.6
	cone.height = head
	cone.radial_segments = 8
	cone.rings = 1
	var mi := MeshInstance3D.new()
	mi.mesh = cone
	mi.transform = _between(shaft_end, b, head)
	mi.material_override = _mat(c, e)
	parent.add_child(mi)


## Explicit basis rather than look_at, which is undefined for a segment parallel to UP — the
## y component of every decomposition here is exactly that.
func _between(a: Vector3, b: Vector3, len_m: float) -> Transform3D:
	var up := (b - a) / len_m
	var ref := Vector3.RIGHT if absf(up.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var side := ref.cross(up).normalized()
	var fwd := up.cross(side).normalized()
	return Transform3D(Basis(side, up, fwd), (a + b) * 0.5)
