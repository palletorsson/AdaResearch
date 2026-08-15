extends Node3D
class_name FaceConvention

## face_convention — a triangle is three points; WHICH SIDE IS ITS FRONT IS NOT IN THE
## THREE POINTS. It comes from a convention laid over them, and a renderer that honours
## that convention deletes the other side. Four poles, four flags, and the four things a
## triangle can declare about itself.
##
## THE FAMILY — the PLANE, and its face as a convention rather than a property.
##
##   parasol_triangle   sidedness two_tone|flat|inverted|split, convention none|normal|
##                      winding|both. The centre of this synthesis and the only member
##                      that names the mechanism: "a triangle is three points IN AN
##                      ORDER, and that order is the only thing that gives a flat sheet
##                      a front and a back" (gd:29-33). It states orientation twice —
##                      the surface NORMAL and the WINDING order — says they encode the
##                      same fact, and draws them as arrows.
##   coincident_face    separation coincident|clear|hairline|inverted. Two faces that
##                      claim the same depth; the renderer awards each pixel to whichever
##                      float rounded higher. WHAT DEPTH a face claims when two claims tie.
##   penrose_triangle   disclosure marker|bare|seam|exploded|sealed. Three beams, each
##                      locally correct; the joint that cannot close. WHAT A FIGURE
##                      CONFESSES about its own break.
##   impossible_trident fault global|confessed|none|doubled. Two round prongs at the base
##                      resolve into three flat prongs at the top. WHERE the contradiction
##                      is allowed to live.
##
## Read together they are four questions about one thing a polygon cannot answer from its
## own vertices — which side, which depth, which joint, which prong. This bench takes the
## first, because it is the one the machine actually acts on.
##
## THE ARGUMENT, and it is checkable. parasol_triangle says the normal and the winding
## "encode the same fact and neither is visible". HALF OF THAT IS WRONG, and the source
## says so in its own material: gd:149 sets `cull_mode = BaseMaterial3D.CULL_DISABLED`,
## which switches OFF the one of the two notations a GPU can execute. A rasteriser has no
## normal test — a stored normal only feeds shading — so of the two languages that
## "encode the same fact", ONE IS ENFORCED AND THE OTHER IS ONLY BELIEVED. Nothing makes
## them agree. This bench builds all four combinations of the two declarations on four
## otherwise identical flags and then lets each convention delete what it does not accept.
##
##   pole 0   order outward, normal outward   the two agree, pointing at you
##   pole 1   order outward, normal inward    they disagree
##   pole 2   order inward,  normal outward   they disagree, the other way
##   pole 3   order inward,  normal inward    the two agree, pointing away
##
## THE WORKED CASE, and it is not hypothetical. Earlier in this programme frequency_shell
## derived twenty icosahedron faces from mutual edge distance. That fixes the vertices and
## says NOTHING about their order, so roughly half came out wound inward and were culled:
## its v1 photographed as a handful of loose triangles and its v4 as a ball with a bite
## taken out of it. The repair is one line (frequency_shell gd:186) —
##
##     if (b - a).cross(c - a).dot(a + b + c) < 0.0:
##
## — the cross product of the edges checked against the centroid, which on a sphere at the
## origin points outward by definition. Twenty correct triangles, half of them invisible,
## and the fault was in an ordering nobody had written down. THE CONVENTION IS INVISIBLE
## UNTIL IT IS WRONG, and that sentence is what this bench photographs: at convention=none
## the four flags are two blues and two ochres and NOTHING in the picture says which two
## will vanish under `normal`.
##
## Nothing animates, nothing is printed, nothing is random. The whole stand is built
## synchronously in _ready from constants, so two builds of one cell are the same mesh.

## WHAT THE SURFACE CLAIMS. parasol_triangle's own four values, in its own order.
##
##   two_tone  the shipped parasol: the winding made legible as colour. A flag wound
##             toward you shows its declared FRONT colour, one wound away shows its BACK.
##             Two blues, two ochres, and the ORDER is the only thing being reported.
##   flat      one neutral colour on both faces. The claim withdrawn entirely — this is
##             what a triangle looks like when nobody has decided which way it faces, and
##             it is the honest opposite of the artifact's thesis. Four identical flags
##             over four different declarations.
##   inverted  the convention reversed. The geometry does not move by a micron; the
##             naming does. Under convention=none that is a repaint and nothing else —
##             the registered null. Under any enforcing convention it stands the exact
##             COMPLEMENT of the flags two_tone stands.
##   split     both terms on ONE face, divided along the median from apex to base
##             midpoint, with a 4 mm slot cut between the halves so the division reads in
##             a greyscale still and not only in colour. Which half is which is the
##             winding, so facing stops being a secret you have to walk around to learn.
@export_enum("two_tone", "flat", "inverted", "split") var sidedness: String = "two_tone":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not SIDEDNESS.has(picked):
			return                      ## an unreachable value keeps the stand we have
		sidedness = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHICH NOTATION IS ENFORCED. parasol_triangle's own four values, in its own order, and
## in THIS build each one is a cull rather than an annotation.
##
##   none      no cull and no side marking beyond the paint. The honest plane: every flag
##             stands, including the two whose order points away from you. A triangle
##             with nothing enforced has no front, and all four poles carry a sheet.
##   normal    culled by the STORED NORMAL — a vector somebody wrote into the mesh.
##             Keeps poles 0 and 2. No rasteriser does this; it is done here in _keep(),
##             which is the point (see `winding` below).
##   winding   culled by the VERTEX ORDER, by the same cross product frequency_shell
##             needed: `(b-a).cross(c-a).dot(VIEW)`. Keeps poles 0 and 1.
##   both      both tests applied. Keeps only pole 0 — because the two languages that
##             "encode the same fact" disagree on poles 1 and 2, and a flag has to
##             satisfy a declaration it never had to make consistently.
##
## `winding` and `normal` keep THE SAME NUMBER OF FLAGS AND A DIFFERENT SET OF THEM. That
## is the whole finding in one pair of tiles: same tally, different world.
@export_enum("none", "normal", "winding", "both") var convention: String = "none":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not CONVENTIONS.has(picked):
			return
		convention = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One stand, or all four conventions in a row. NOT PART OF EITHER AXIS — an all-rungs
## value declared inside an axis makes capture_config_sweep union the row's AABB with
## every single and photograph the singles as specks. The registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const SIDEDNESS: PackedStringArray = ["two_tone", "flat", "inverted", "split"]
const CONVENTIONS: PackedStringArray = ["none", "normal", "winding", "both"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the truth table ────────────────────────────────────────────────────────────────────
## The two declarations, per pole, along the stand's own +Z. WIND is the sign the vertex
## ORDER produces; NORM is the sign of the vector STORED with those vertices. Nothing in
## the geometry forces a column to match its neighbour, and the four rows are the four
## ways they can stand to each other. This array IS the artifact's subject.
const COUNT: int = 4
const WIND: PackedInt32Array = [1, 1, -1, -1]
const NORM: PackedInt32Array = [1, -1, 1, -1]

# ── the stand, metres ──────────────────────────────────────────────────────────────────
const PITCH: float = 0.26          ## pole to pole
const TRI_W: float = 0.25          ## the triangle's base
const TRI_H: float = 0.2165        ## TRI_W * 0.866, parasol's equilateral height
const SPLIT_GAP: float = 0.004     ## the slot on the median; 4 mm so it survives 160 px
const STICK_W: float = 0.016       ## parasol's stick, squared off so the stand is one mesh
const STICK_H: float = 0.300
const RAIL_W: float = 1.030        ## COUNT-1 pitches plus one triangle width
const RAIL_H: float = 0.045
const RAIL_D: float = 0.075
const BODY_H: float = RAIL_H + STICK_H + TRI_H     ## 0.5615
const BASE_Y: float = RAIL_H + STICK_H             ## 0.345, where every triangle stands
const LADDER_PITCH: float = 1.15

## Every artifact has a front, and this one's front is where the sweep stands: the stand
## is turned to face capture_config_sweep's standpoint bearing so the flags are seen as
## flags rather than edge-on. Same argument rule_bench and postulate_bench make.
const FRONT_YAW: float = 0.62
## The direction a face has to point in to count as facing you. Local +Z, so the whole
## cull is decided before FRONT_YAW turns the stand, and the photograph does not depend
## on the engine's front-face winding convention — see _keep().
const VIEW: Vector3 = Vector3(0.0, 0.0, 1.0)

# ── colour ─────────────────────────────────────────────────────────────────────────────
## THE FRONT AND BACK COLOURS ARE EQUILUMINANT BY CONSTRUCTION, and this is arithmetic,
## not taste. The critic greys every frame before it measures, so a front/back pair that
## differs in brightness would make `inverted` read as a real change at convention=none —
## where by construction NOTHING has changed except which side is called front. parasol's
## shipped pink (1.0, 0.2, 0.5) and blue (0.2, 0.5, 1.0) are 20 grey levels apart in
## Rec.709, which would have reported a fact about the palette. These two solve
## luma(F) = luma(B) under Rec.601 AND Rec.709 simultaneously:
##
##   Rec.601  0.299 R + 0.587 G + 0.114 B  ->  0.54430 for both
##   Rec.709  0.2126 R + 0.7152 G + 0.0722 B -> 0.54639 for both
##
## Visibly a cool blue against a warm ochre; identical to a greyscale instrument. The
## null at (two_tone|none) against (inverted|none) is only a null because of these
## six numbers, and coincident_face is the artifact that found the trap — its registry
## records amber and blue at 0.669 and 0.637 luma and warns they will read as a twin.
const FACE_FRONT: Color = Color(0.418, 0.559, 0.800)
const FACE_BACK: Color = Color(0.682, 0.541, 0.200)
## parasol_triangle's own FLAT_COLOR (gd:76), and deliberately NOT equiluminant: flat is
## a different claim, not the same claim reversed, so it is allowed to look different.
const FLAT_COLOR: Color = Color(0.86, 0.86, 0.88)
const FRAME_COLOR: Color = Color(0.30, 0.30, 0.33)

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
	if config_data.has("sidedness"):
		sidedness = str(config_data["sidedness"])
	if config_data.has("convention"):
		convention = str(config_data["convention"])
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
	var conventions: PackedStringArray = PackedStringArray()
	if layout == "ladder":
		conventions = CONVENTIONS.duplicate()
	else:
		conventions.append(_pick(convention, CONVENTIONS, "none"))
	var n: int = conventions.size()
	for i in range(n):
		var holder := Node3D.new()
		holder.name = "Stand_" + conventions[i]
		holder.position = Vector3((float(i) - float(n - 1) * 0.5) * LADDER_PITCH, 0.0, 0.0)
		holder.rotation.y = FRONT_YAW
		add_child(holder)
		_built.append(holder)
		_build_stand(holder, conventions[i])


# ── the cull ───────────────────────────────────────────────────────────────────────────

## The sign the VERTEX ORDER produces: frequency_shell's line, with the stand's own front
## direction where that artifact used the face centroid. Positive means the three points,
## traversed a -> b -> c, wrap counter-clockwise as seen from the viewer's side.
##
## THE TEST IS RUN HERE AND NOT ON THE GPU, on purpose. Godot's rasteriser is the only
## thing in this stack that can cull by winding, and it can only do it in ITS OWN
## handedness; a bench that leaned on that would be photographing my belief about Godot's
## front-face convention rather than the argument, and if the belief were backwards every
## tile would come back as its own complement with nothing to flag it. Both sources set
## CULL_DISABLED anyway (parasol gd:149, and the material below keeps it), so the family's
## own habit is to decide this in the build. The arithmetic is a rasteriser's arithmetic;
## the decision is the artifact's.
func _winding_sign(a: Vector3, b: Vector3, c: Vector3) -> float:
	return (b - a).cross(c - a).dot(VIEW)


## Which side is being called the front. +1 normally; -1 at sidedness=inverted, where the
## convention itself is reversed. parasol can afford to reverse it as a repaint because it
## never culls; once a convention is enforced, reversing it MUST reverse what survives or
## the value is a lie.
func _front_sign() -> int:
	if sidedness == "inverted":
		return -1
	return 1


## Does pole `i` keep its sheet under `conv`? Two tests of the same shape over two
## different inputs — one derived from the order of the points, one read off a number
## somebody stored — which is exactly why they can disagree.
func _keep(i: int, conv: String) -> bool:
	var fs: int = _front_sign()
	var by_order: bool = fs * WIND[i] > 0
	var by_normal: bool = fs * NORM[i] > 0
	match conv:
		"winding":
			return by_order
		"normal":
			return by_normal
		"both":
			return by_order and by_normal
	return true                  ## `none` culls nothing; the plane has no front


## Which face the viewer is looking at, in the notation the paint follows. parasol calls
## two_tone "the winding order made legible as colour", so the paint follows the ORDER —
## and therefore says nothing whatever about the normal, which is the reason poles 1 and 3
## look exactly like poles 0 and 2 until something enforces the other notation.
func _shows_front(i: int) -> bool:
	return _front_sign() * WIND[i] > 0


# ── building ───────────────────────────────────────────────────────────────────────────

func _build_stand(holder: Node3D, conv: String) -> void:
	# The rail and the four poles are IDENTICAL in every one of the sixteen cells, and so
	# is the anchor. capture_config_sweep unions the AABB across a spec's variants, so a
	# cell with one flag and a cell with four must be drawn on a body that does not move.
	# They are also why no cell is ever blank: a culled flag leaves its pole standing.
	var frame := SurfaceTool.new()
	frame.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(frame, Vector3(0.0, RAIL_H * 0.5, 0.0), Vector3(RAIL_W, RAIL_H, RAIL_D))
	for i in range(COUNT):
		var cx: float = (float(i) - float(COUNT - 1) * 0.5) * PITCH
		_add_box(frame, Vector3(cx, RAIL_H + STICK_H * 0.5, 0.0),
			Vector3(STICK_W, STICK_H, STICK_W))
	_commit(holder, "Frame", frame, FRAME_COLOR)

	var st_front := SurfaceTool.new()
	st_front.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_back := SurfaceTool.new()
	st_back.begin(Mesh.PRIMITIVE_TRIANGLES)
	var st_flat := SurfaceTool.new()
	st_flat.begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(COUNT):
		if not _keep(i, conv):
			continue
		_build_flag(i, st_front, st_back, st_flat)

	_commit(holder, "FaceFront", st_front, FACE_FRONT)
	_commit(holder, "FaceBack", st_back, FACE_BACK)
	_commit(holder, "FaceFlat", st_flat, FLAT_COLOR)
	_add_anchor(holder)


## One flag. A triangle is a SHEET with no thickness — giving it one would have quietly
## answered the question the artifact asks, because a slab has an outside.
func _build_flag(i: int, st_front: SurfaceTool, st_back: SurfaceTool,
		st_flat: SurfaceTool) -> void:
	var cx: float = (float(i) - float(COUNT - 1) * 0.5) * PITCH
	var half: float = TRI_W * 0.5
	var v0 := Vector3(cx - half, BASE_Y, 0.0)
	var v1 := Vector3(cx + half, BASE_Y, 0.0)
	var v2 := Vector3(cx, BASE_Y + TRI_H, 0.0)
	var w: int = WIND[i]
	var nrm := Vector3(0.0, 0.0, float(NORM[i]))
	var shows_front: bool = _shows_front(i)

	if sidedness == "flat":
		_wound_face(st_flat, v0, v1, v2, nrm, w)
		return

	if sidedness == "split":
		# Apex to base midpoint, with a slot opened either side of the median so the
		# division is geometry and not only paint. Which half carries which term is the
		# winding, which is the one thing split is for.
		var m := Vector3(cx, BASE_Y, 0.0)
		var g: float = SPLIT_GAP * 0.5
		var off := Vector3(g, 0.0, 0.0)
		var st_a: SurfaceTool = st_front if shows_front else st_back
		var st_b: SurfaceTool = st_back if shows_front else st_front
		_wound_face(st_a, v0, m - off, v2 - off, nrm, w)
		_wound_face(st_b, m + off, v1, v2 + off, nrm, w)
		return

	var st: SurfaceTool = st_front if shows_front else st_back
	_wound_face(st, v0, v1, v2, nrm, w)


## Emit the three points IN AN ORDER. Same triangle, same normal, and the order is the
## whole difference — which is the sentence the artifact exists to make into a picture.
## The assert-free check is _winding_sign: if the order does not already produce the sign
## the pole declares, swap the last two vertices, which is the minimal edit and the same
## one frequency_shell makes.
func _wound_face(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, n: Vector3,
		want: int) -> void:
	var s: float = _winding_sign(a, b, c)
	st.set_normal(n)
	if (s > 0.0) == (want > 0):
		st.add_vertex(a)
		st.add_vertex(b)
		st.add_vertex(c)
	else:
		st.add_vertex(a)
		st.add_vertex(c)
		st.add_vertex(b)


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals.
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


## The capture AABB counts MeshInstance3D only, and this stand's visible extent shrinks
## when flags are culled — which would let the camera creep in on the sparse cells and
## turn a framing change into a measured difference. One invisible box at the full extent
## pins it. layers = 0 is per-instance, does not propagate, and leaves mesh and material
## alone, which `visible = false` would not.
func _add_anchor(holder: Node3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "AnchorExtent"
	var box := BoxMesh.new()
	box.size = Vector3(RAIL_W, BODY_H, RAIL_D)
	mi.mesh = box
	mi.position = Vector3(0.0, BODY_H * 0.5, 0.0)
	mi.layers = 0
	holder.add_child(mi)


func _commit(holder: Node3D, mesh_name: String, st: SurfaceTool, c: Color) -> void:
	var mesh: ArrayMesh = st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = _mat(c)
	holder.add_child(mi)


## CULL_DISABLED, exactly as both sources ship it (parasol gd:149, coincident_face's
## slabs). Nothing here is hidden by the GPU: every cull in this artifact has already
## happened in _keep(), so what you see is what was built, and a missing flag is a
## decision rather than a rendering accident. No emission — the equiluminant pair above
## only holds if the two colours are lit identically, and an emissive term would have to
## be matched a second time.
func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.1
	m.roughness = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
