extends Node3D
class_name EdgeGround

## edge_ground — TWO THINGS ARE CALLED A LINE IN THIS CORPUS AND THEY HAVE BEEN SHARING
## A WORD. One is a MARK: something drawn, with a thickness, that could be rubbed out.
## The other is a BOUNDARY: where a solid stops, which is not drawn at all, has no
## thickness, and does not belong to the object — a silhouette is not ON the cube, it is
## where the cube ends RELATIVE TO WHERE YOU STAND.
##
## THE FAMILY, three members, one question — what is the line the EDGE of, rather than a
## drawing of:
##
##   cube_lines               disclosure: frame · visible · silhouette · plan · corner
##   (primitives)             coding:     uniform · axes · depth · horizon
##                            Twelve thin lines and NO SOLID. Its own registry line is
##                            "the volume was always an inference the eye supplies."
##
##   edge_as_ground_capstone  rim:        closed · gapped · arc · crowded
##   (postfoundations)        assertion:  disc · void · cairn · shards
##                            The spine's last artifact, inscribed "The edge is the
##                            ground." At assertion=void the platform is BORED THROUGH
##                            its full 0.4 m (gd:227-232, _make_ring_mesh) and the object
##                            becomes its own rim: the boundary with the ground removed.
##
##   coincident_face          separation: coincident · clear · hairline · inverted
##   (boolean_surfaces)       Two solids whose faces claim ONE depth. Its subject is not
##                            a line at all — it is what happens at the place a boundary
##                            is supposed to be, when the float grid cannot say which
##                            side is in front.
##
## THE CORRECTION THE CODE FORCED, and it is the whole reason this bench exists.
## cube_lines' `disclosure` is NOT one axis. Read _drawn_edges() (gd:126-141):
##
##   frame       [1..12]                    a MARK — every edge drawn, occlusion denied
##   visible     [2,3,5,6,7,8,10,11,12]     a MARK about a VIEWER — the draughtsman's
##                                          hidden-line removal, done by hand
##   silhouette  [2,3,5,8,10,12]            a BOUNDARY — the six edges of the outline
##   plan        [1,2,3,4]                  a PROJECTION onto a surface that is not the
##                                          object
##   corner      [1,4,9]                    a MARK at the far vertex, the exact
##                                          complement of `visible`
##
## AND `silhouette` IS A HARD-CODED LIST. It is not computed from any camera at runtime:
## `return PackedInt32Array([2, 3, 5, 8, 10, 12])`, with the comment "edges touching
## neither the near nor the far vertex", against NEAR_CORNER = Vector3(0.5, 0.5, 0.5) and
## FAR_CORNER = Vector3(-0.5, -0.5, -0.5) declared as consts at gd:52-53. So it is a
## boundary that was computed ONCE, at authoring time, for a viewer standing in the +++
## octant — and then FROZEN AS A MARK. That is the interesting case, and it is sharper
## than "computed then drawn", because this one cannot even notice that the camera moved.
##
## THE ARITHMETIC THAT MAKES IT LUCKY. capture_config_sweep's standpoint is yaw 0.62,
## pitch -0.26, i.e. dir = (0.562, 0.257, 0.787) — all three components positive, so the
## near vertex of an unrotated cube IS (+,+,+) and cube_lines' frozen list is CORRECT
## here. This bench is therefore NOT yaw-rotated (rule_bench and postulate_bench both turn
## their bodies to face the sweep; turning this one would falsify the very list it is
## quoting). Checked at all five of probe_anamorphic's standpoints:
##
##   canonical   (0.562, 0.257, 0.787)  near v6  true outline {2,3,5,8,10,12}   CORRECT
##   from-above  (0.289, 0.867, 0.405)  near v6  true outline {2,3,5,8,10,12}   CORRECT
##   opposite    (-0.562, 0.257,-0.787) near v4  true outline {1,4,6,7,10,12}   4 of 6 WRONG
##   from-below  (0.555,-0.296, 0.778)  near v2  true outline {1,4,6,7,10,12}   4 of 6 WRONG
##   square-on   (0.000, 0.100, 0.995)  degenerate: two faces exactly edge-on, so TEN
##                                      edges qualify and only edge 1 is hidden  WRONG
##
## `silhouette` is expected to be STANDPOINT-DEPENDENT BY CONSTRUCTION. It is the one axis
## value in this corpus where anamorphism is the CORRECT BEHAVIOUR rather than a fault:
## a boundary that photographed the same from every standpoint would not be a boundary.
## And `corner` inherits the same property from the other side — the far triad {1,4,9} is
## fully occluded by the body at canonical and from-above, and VISIBLE at the other three.
##
## WHAT THIS BENCH ADDS THAT NO MEMBER HAS: A SOLID. cube_lines has none, so nothing in
## its sheet can tell a mark from a boundary — every value is twelve-or-fewer blue lines
## in air. Put an opaque 0.56 m cube where the drawing is, and the difference becomes a
## measurement rather than a claim:
##
##   · `frame` and `visible` produce ALMOST THE SAME PICTURE, because the body performs
##     by occlusion exactly the hidden-line removal `visible` performs by hand. What
##     survives is only the three overhangs that reach past the body's outline.
##   · `silhouette`'s six marks land exactly on the body's own edge, so the mark and the
##     boundary coincide and you cannot tell which you are looking at — until the camera
##     moves and only one of them follows.
##   · `corner` is three fully specified marks that the boundary DELETES.
##
## THE SECOND AXIS, from coincident_face, asks how far the mark stands off the surface it
## describes — and the failure sits in the middle of the ladder with order on both sides,
## which is that artifact's own sentence about its own axis.
##
## Nothing animates, nothing is printed, nothing is random. Every number below is a
## constant and every variant is built synchronously in _ready.


## WHICH LINES ARE DRAWN. cube_lines' five values, its own order, its own default, and
## its five edge sets copied index for index from _drawn_edges().
@export_enum("frame", "visible", "silhouette", "plan", "corner") var disclosure: String = "frame":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not DISCLOSURES.has(picked):
			return                      ## an unreachable value keeps the current drawing
		disclosure = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## HOW FAR THE MARK STANDS FROM THE SURFACE IT DESCRIBES, measured from the solid's own
## face plane to the OUTER face of the drawn bar. coincident_face's four words, its own
## default, and its own argued order — which is the ladder clear -> hairline -> coincident
## -> inverted, with the failure third. apply_dna_block moves the default leftmost in the
## registry; the code keeps the ladder, exactly as coincident_face's registry says of
## itself ("Same four values, and the code is the thing that renders").
@export_enum("clear", "hairline", "coincident", "inverted") var separation: String = "coincident":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not SEPARATIONS.has(picked):
			return
		separation = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One body, or all five disclosures in a row. NOT PART OF EITHER AXIS — wave 13 learned
## that an all-rungs value declared inside an axis makes capture_config_sweep union the
## row's AABB with every single and photograph the singles as specks. The registry fixture
## pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const DISCLOSURES: PackedStringArray = ["frame", "visible", "silhouette", "plan", "corner"]
const SEPARATIONS: PackedStringArray = ["clear", "hairline", "coincident", "inverted"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the solid, metres ──────────────────────────────────────────────────────────────────
## A 0.560 m cube. Not a polyhedron with more faces, because cube_lines' entire vocabulary
## is indexed against a cube's twelve edges and eight vertices and would not survive the
## change.
const HALF: float = 0.280
## The cube's centre, so it floats 0.170 m over the stage: the gap is what lets `plan`
## read as a line at the bottom of a body rather than as a scratch on the floor.
const BODY_Y: float = 0.470

# ── the drawing, metres ────────────────────────────────────────────────────────────────
const BAR: float = 0.016          ## the mark's square section. A line WITH a thickness.
## The draughtsman's overshoot, past each end of the edge. It is load-bearing, not styling:
## at separation=inverted every mark is behind the surface it describes, and the overhang
## is the only part of the drawing that is not against the body. Without it that whole rung
## is five photographs of one bare cube.
const OVER: float = 0.090
const BAR_HALF_LEN: float = HALF + OVER                       ## 0.370

# ── the stage, metres. IDENTICAL IN ALL TWENTY CELLS. ──────────────────────────────────
const PLINTH_W: float = 0.760
const PLINTH_H: float = 0.020
const STEM: float = 0.050
## The union AABB, pinned by a layers = 0 anchor so it is the SAME BOX under every value
## of both axes. The vertical bars at separation=clear reach y 0.840 and the plinth is
## 0.760 square, so the anchor is exactly the envelope and overshoots nothing.
const BOX_W: float = 0.760
const BOX_H: float = 0.840
const LADDER_PITCH: float = 1.00

## Face-plane offsets for the four rungs: the distance from the solid's face to the OUTER
## face of the bar, along that face's normal.
const GAP_CLEAR: float = 0.055        ## the drawing lifts off the body entirely
const GAP_HAIRLINE: float = 0.006     ## one step out: the mark wins the depth test
const GAP_COINCIDENT: float = 0.000   ## the tie: two surfaces claim one depth
const GAP_INVERTED: float = -0.006    ## one step in: the surface wins, outright

const STAGE_COLOR: Color = Color(0.09, 0.10, 0.12)     ## coincident_face plate, gd:350
const BODY_COLOR: Color = Color(0.18, 0.20, 0.26)      ## capstone platform_color, gd:36
const MARK_COLOR: Color = Color(0.40, 0.80, 1.00)      ## cube_lines LEGACY_TINT, gd:51

## cube_lines' twelve edges, in its numbering. Line1 is index 0 here.
const EDGE_A: PackedInt32Array = [0, 1, 2, 3, 4, 5, 6, 7, 0, 1, 2, 3]
const EDGE_B: PackedInt32Array = [1, 2, 3, 0, 5, 6, 7, 4, 4, 5, 6, 7]

var _built: Array[Node3D] = []
## Set while a whole config dictionary is landing, so three keys cost one rebuild.
var _bulk: bool = false


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("disclosure"):
		disclosure = str(config_data["disclosure"])
	if config_data.has("separation"):
		separation = str(config_data["separation"])
	_bulk = false
	_rebuild()


func _pick(value: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = value.strip_edges().to_lower()
	if allowed.has(v):
		return v
	return fallback


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	var names: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		names = DISCLOSURES.duplicate()
	else:
		names.append(_pick(disclosure, DISCLOSURES, "frame"))
	var n_cells: int = names.size()
	for i in range(n_cells):
		var holder := Node3D.new()
		holder.name = "Cell" + names[i].capitalize()
		holder.position = Vector3((float(i) - float(n_cells - 1) * 0.5) * LADDER_PITCH,
			0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_variant(holder, names[i])


# ── the vocabulary, from cube_lines' code ──────────────────────────────────────────────

## cube_lines' eight vertices, in its numbering and its comments:
##   0 bottom-back-left (the FAR corner)   4 top-back-left
##   1 bottom-back-right                   5 top-back-right
##   2 bottom-front-right                  6 top-front-right (the NEAR corner)
##   3 bottom-front-left                   7 top-front-left
func _verts() -> PackedVector3Array:
	return PackedVector3Array([
		Vector3(-HALF, -HALF, -HALF), Vector3(HALF, -HALF, -HALF),
		Vector3(HALF, -HALF, HALF), Vector3(-HALF, -HALF, HALF),
		Vector3(-HALF, HALF, -HALF), Vector3(HALF, HALF, -HALF),
		Vector3(HALF, HALF, HALF), Vector3(-HALF, HALF, HALF)])


## cube_lines._drawn_edges(), index for index, including its 1-based numbering. Nothing
## here moves an edge; a hidden edge keeps its place in the list and in the world.
##
## TAKES THE VALUE RATHER THAN READING THE PROPERTY, because `layout = ladder` builds all
## five cells in one pass and assigning to `disclosure` to ask it a question would re-enter
## the setter, which rebuilds, which asks again.
func _edges(which: String) -> PackedInt32Array:
	match which:
		"visible":
			## everything except the three meeting the far vertex (Line1, Line4, Line9)
			return PackedInt32Array([2, 3, 5, 6, 7, 8, 10, 11, 12])
		"silhouette":
			## the hexagon: edges touching neither the near nor the far vertex
			return PackedInt32Array([2, 3, 5, 8, 10, 12])
		"plan":
			## the bottom face alone
			return PackedInt32Array([1, 2, 3, 4])
		"corner":
			## the triad at the far vertex — the exact complement of "visible"
			return PackedInt32Array([1, 4, 9])
		_:
			return PackedInt32Array([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])


## The one number the separation axis is. Positive is outside the solid.
func _gap() -> float:
	match separation:
		"clear":
			return GAP_CLEAR
		"hairline":
			return GAP_HAIRLINE
		"inverted":
			return GAP_INVERTED
		_:
			return GAP_COINCIDENT


## Where a bar's axis sits in one of the two directions perpendicular to its run. The
## solid's face plane is at +/- HALF; the bar's OUTER face is put at +/- (HALF + gap), so
## gap = 0 makes the two coplanar and the depth test has nothing to decide.
func _seat(mid_component: float, gap: float) -> float:
	var s: float = 1.0 if mid_component > 0.0 else -1.0
	return s * (HALF + gap - BAR * 0.5)


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_variant(holder: Node3D, which: String) -> void:
	# THE STAGE AND THE SOLID ARE IDENTICAL IN EVERY ONE OF THE TWENTY CELLS, and are
	# drawn before either axis is consulted. capture_config_sweep unions the AABB across a
	# spec's variants, so anything that changed size here would reframe the whole sheet;
	# and more to the point, the argument only works if the body is a constant and the
	# drawing is the variable.
	var stage := SurfaceTool.new()
	stage.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(stage, Vector3(0.0, PLINTH_H * 0.5, 0.0),
		Vector3(PLINTH_W, PLINTH_H, PLINTH_W))
	var stem_h: float = BODY_Y - HALF - PLINTH_H
	_add_box(stage, Vector3(0.0, PLINTH_H + stem_h * 0.5, 0.0),
		Vector3(STEM, stem_h, STEM))
	_commit(holder, "Stage", stage, STAGE_COLOR, false)

	var solid := SurfaceTool.new()
	solid.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(solid, Vector3(0.0, BODY_Y, 0.0), Vector3(HALF * 2.0, HALF * 2.0, HALF * 2.0))
	_commit(holder, "Solid", solid, BODY_COLOR, false)

	var marks := SurfaceTool.new()
	marks.begin(Mesh.PRIMITIVE_TRIANGLES)
	var drawn: PackedInt32Array = _edges(which)
	var verts: PackedVector3Array = _verts()
	var gap: float = _gap()
	for k in range(drawn.size()):
		var e: int = drawn[k]
		var a: Vector3 = verts[EDGE_A[e - 1]]
		var b: Vector3 = verts[EDGE_B[e - 1]]
		var mid: Vector3 = (a + b) * 0.5
		var at: Vector3 = Vector3.ZERO
		var size: Vector3 = Vector3.ZERO
		if not is_equal_approx(a.x, b.x):
			size = Vector3(BAR_HALF_LEN * 2.0, BAR, BAR)
			at = Vector3(mid.x, _seat(mid.y, gap), _seat(mid.z, gap))
		elif not is_equal_approx(a.y, b.y):
			size = Vector3(BAR, BAR_HALF_LEN * 2.0, BAR)
			at = Vector3(_seat(mid.x, gap), mid.y, _seat(mid.z, gap))
		else:
			size = Vector3(BAR, BAR, BAR_HALF_LEN * 2.0)
			at = Vector3(_seat(mid.x, gap), _seat(mid.y, gap), mid.z)
		_add_box(marks, at + Vector3(0.0, BODY_Y, 0.0), size)
	_commit(holder, "Marks", marks, MARK_COLOR, true)

	# THE ANCHOR. Not rendered — layers = 0 keeps it out of every camera while
	# _subtree_aabb still counts it, which is the documented way to stop the measured box
	# from moving between values. Sized to the exact envelope: the plinth is 0.760 square
	# and the tallest thing in the sheet is a vertical bar at separation=clear, whose top
	# is BODY_Y + BAR_HALF_LEN = 0.840. It does not overshoot.
	var anchor := MeshInstance3D.new()
	anchor.name = "Anchor"
	var abox := BoxMesh.new()
	abox.size = Vector3(BOX_W, BOX_H, BOX_W)
	anchor.mesh = abox
	anchor.position = Vector3(0.0, BOX_H * 0.5, 0.0)
	anchor.layers = 0
	holder.add_child(anchor)


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
## The materials are CULL_DISABLED as well: wave 13's lesson is that a body photographed
## from behind is indistinguishable from a body that was never built.
func _add_box(st: SurfaceTool, at: Vector3, size: Vector3) -> void:
	var h: Vector3 = size * 0.5
	var p: PackedVector3Array = PackedVector3Array([
		at + Vector3(-h.x, -h.y, h.z), at + Vector3(h.x, -h.y, h.z),
		at + Vector3(h.x, h.y, h.z), at + Vector3(-h.x, h.y, h.z),
		at + Vector3(-h.x, -h.y, -h.z), at + Vector3(h.x, -h.y, -h.z),
		at + Vector3(h.x, h.y, -h.z), at + Vector3(-h.x, h.y, -h.z)])
	_quad(st, p[0], p[1], p[2], p[3], Vector3(0.0, 0.0, 1.0))
	_quad(st, p[5], p[4], p[7], p[6], Vector3(0.0, 0.0, -1.0))
	_quad(st, p[3], p[2], p[6], p[7], Vector3(0.0, 1.0, 0.0))
	_quad(st, p[4], p[5], p[1], p[0], Vector3(0.0, -1.0, 0.0))
	_quad(st, p[1], p[5], p[6], p[2], Vector3(1.0, 0.0, 0.0))
	_quad(st, p[4], p[0], p[3], p[7], Vector3(-1.0, 0.0, 0.0))


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		n: Vector3) -> void:
	var tri: PackedVector3Array = PackedVector3Array([a, b, c, a, c, d])
	for v in tri:
		st.set_normal(n)
		st.add_vertex(v)


func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color,
		emissive: bool) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = _mat(c, emissive)
	holder.add_child(mi)


func _mat(c: Color, emissive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.2 if not emissive else 0.0
	m.roughness = 0.5 if not emissive else 0.35
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.55
	return m
