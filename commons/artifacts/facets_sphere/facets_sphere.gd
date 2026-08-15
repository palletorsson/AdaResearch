extends Node3D
class_name FacetsSphere

## facets_sphere — there is no smooth object. `facets` is not a display option, it is
## the seam between what a thing is BUILT of and what it is PRESENTED as.
##
## THE FAMILY. Three artifacts declare an axis called `facets`, and all three carry the
## same three words in the same order — shown · hidden · only — and all three default to
## `shown` (3 of 3):
##   grab_trihedron  commons/primitives/trihedron/grab_trihedron.gd:53   (also `figure`)
##   sphere_high     commons/primitives/godotmeshes/sphere_high.gd:40    (also `tessellation`)
##   sphere_low      commons/primitives/godotmeshes/sphere_low.gd:46     (also `grain`)
## Their `_build_material()` bodies are the same seventeen lines three times over, down to
## the comment. sphere_mid — the third sibling of the sphere trio — is NOT a member: it
## declares `resolution` and `budget_bias` and never took the word. Three members, one
## vocabulary, and the vocabulary is a copy.
##
## ARE sphere_high AND sphere_low ONE SCENE UNDER TWO NAMES? NO — checked, and the answer
## is more interesting than either yes or no. Two scenes, two scripts, two colours
## (0.9,0.8,0.3 against 0.8,0.3,0.9) and two DIFFERENT second axes: sphere_high's
## `tessellation` is a square resolution ladder (coarse 4 · low 7 · high 16 · ultra 32,
## rings = radial_segments = n) and sphere_low's `grain` is an anisotropic budget
## (meridian [1,10] · parallel [10,3] · even [4,4], the same ~20 quads spent in different
## directions). But their `facets` HALVES are identical code, and so is grab_trihedron's.
## The family is one implementation under three names, not one scene under two.
##
## WHAT THE MEMBERS' CODE ACTUALLY DOES FOR EACH VALUE — read, not guessed, and it
## overrules the obvious story:
##   shown   material_override = GridMaterialFactory.make(BASE_COLOR, {})
##           → the SimpleGrid shader. It reads VERTEX_ID % 3 as a barycentric coordinate
##             and paints a band `width` = 2.0 px wide along every triangle edge, white
##             albedo plus the shader's unset emissionColor (RED) at strength 2.0.
##   hidden  material_override = a plain StandardMaterial3D, albedo BASE_COLOR, emission
##           BASE_COLOR * 0.3.
##   only    the same SimpleGrid with show_only_wireframe → show_interior = false, so the
##           fill goes to ALPHA 0 and the edge bands are all that is left.
##
## SO `hidden` DOES NOT SMOOTH ANYTHING. It does not touch the mesh, the normals, the
## subdivision or the silhouette — every member's `facets` branch assigns a MATERIAL and
## nothing else. `hidden` removes the DRAWN edge and leaves the BUILT edge exactly where
## it was. Whether the object then reads as smooth is decided entirely by things `facets`
## cannot reach: the normals the mesh carries and how many triangles there are. That is
## the whole thesis, and it is why the axis is worth a body.
##
## AND IT PREDICTS THE OPPOSITE OF THE FOLK STORY. sphere_high's own qfep line says
## "smooth is just faceted with the facets small enough to forgive" — i.e. at a fine
## enough mesh, `shown` and `hidden` should converge. The code forbids it: `shown` is a
## SCREEN-SPACE ink whose band is 2 px wide however small the triangle, so its coverage
## GROWS with triangle count. More triangles is a LOUDER confession, not a quieter one.
## Pre-registered in the registry as a falsifiable ordering, with the arithmetic.
##
## THE CONSTRUCTION. One body, built here as real non-indexed triangles (SurfaceTool with
## no index() call, exactly as PrimitiveMeshBuilder does for grab_trihedron) so that
## VERTEX_ID % 3 IS the barycentric coordinate and the painted lines really are this
## mesh's own triangle edges. `facets` never changes a vertex. `body` changes which of
## the family's three shipped meshes is standing there, and nothing else.

## WHETHER THE CONSTRUCTION IS ADMITTED. The family's three words, the family's order,
## the family's default (shown, 3 of 3).
##   shown   the SimpleGrid fill plus a white 2 px band on every real triangle edge: the
##           mesh confesses what it is made of. The shipped material of all three members.
##   hidden  the same triangles under a plain lit material. No band is drawn. Nothing is
##           smoothed — this is the axis declining to speak, and the silence reads as
##           smoothness only where the normals and the subdivision were already hiding
##           the facets.
##   only    the bands alone; the fill goes transparent. The construction without the
##           object — an edge count with nothing to be the edge count OF.
@export_enum("shown", "hidden", "only") var facets: String = "shown":
	set(v):
		facets = v
		if is_inside_tree() and not _applying:
			_rebuild()

## WHAT IS FACETED. Three shipped meshes, one from each member, at the literals each
## member actually ships.
##   sphere_fine    rings 16, radial_segments 16 — sphere_high's TESSELLATION["high"],
##                  512 triangles, SMOOTH (radial) normals as SphereMesh generates them.
##   sphere_coarse  rings 1, radial_segments 10 — sphere_low's GRAIN["meridian"], the
##                  shipped literal, 20 triangles, smooth normals: a decagonal bipyramid
##                  that shades like a ball and is silhouetted like a lantern.
##   trihedron      grab_trihedron's shipped four-vertex wedge, 4 flat-shaded faces, per
##                  PrimitiveMeshBuilder's one-normal-per-face emit.
## The normal treatment is NOT a third axis — it is each member's own builder, carried
## over unchanged, and it is the reason `hidden` conceals a great deal on the first two
## and nothing at all on the third.
@export_enum("sphere_fine", "sphere_coarse", "trihedron") var body: String = "sphere_fine":
	set(v):
		body = v
		if is_inside_tree() and not _applying:
			_rebuild()

## One body, or all three in a row. NOT PART OF EITHER AXIS — an all-rungs value declared
## inside an axis makes capture_config_sweep union the row's AABB with every single and
## photograph the singles as specks. The registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		layout = v
		if is_inside_tree() and not _applying:
			_rebuild()

const FACET_MODES: PackedStringArray = ["shown", "hidden", "only"]
const BODY_ORDER: PackedStringArray = ["sphere_fine", "sphere_coarse", "trihedron"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the bodies, metres. Every value sits inside the same 1.0 m cube ────────────────────
const RADIUS: float = 0.50        ## sphere_high / sphere_low ship radius 0.5, height 1.0
const HALF: float = 0.50          ## trihedron half-extent; grab_trihedron ships 0.6
const CENTRE_Y: float = 0.50      ## so every body's base sits on y = 0
const FINE_RINGS: int = 16        ## sphere_high TESSELLATION["high"]
const FINE_SEGS: int = 16
const COARSE_RINGS: int = 1       ## sphere_low GRAIN["meridian"] = [1, 10]
const COARSE_SEGS: int = 10
const LADDER_PITCH: float = 1.30  ## design view only; the fixture pins layout = single

## ONE colour for all three bodies. The members wear three (yellow, purple, cyan) and
## those are identity marks, not part of either axis; sphere_low's is taken because it is
## the darkest of the three and so gives the white edge band the most to argue with.
const BASE_COLOR: Color = Color(0.8, 0.3, 0.9)

## Named GridMatFactory, not GridMaterialFactory — that identifier is a global class name
## and shadowing it at script scope is a parse error. sphere_high and sphere_low both
## carry this comment; it is kept because the trap has not moved.
const GridMatFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

## True while apply_grid_config is assigning, so three keys do not cost three rebuilds.
var _applying: bool = false


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var mat: Material = _build_material()
	if layout == "ladder":
		var i: int = 0
		for token in BODY_ORDER:
			var mi: MeshInstance3D = _make_body(String(token), mat)
			mi.position = Vector3((float(i) - 1.0) * LADDER_PITCH, 0.0, 0.0)
			add_child(mi)
			i += 1
		return
	add_child(_make_body(body, mat))


func _make_body(which: String, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Body_" + which
	match which:
		"sphere_coarse":
			mi.mesh = _sphere_mesh(COARSE_RINGS, COARSE_SEGS)
		"trihedron":
			mi.mesh = _trihedron_mesh()
		_:
			mi.mesh = _sphere_mesh(FINE_RINGS, FINE_SEGS)
	mi.material_override = mat
	return mi


## The three materials, character for character from the members' `_build_material()`.
## The one addition is CULL_DISABLED on `hidden`: SimpleGrid already declares it in its
## own render_mode, so without it the two ends of the axis would disagree about winding
## and a mis-wound triangle would read as an axis effect.
func _build_material() -> Material:
	if facets == "hidden":
		var plain := StandardMaterial3D.new()
		plain.albedo_color = BASE_COLOR
		plain.emission_enabled = true
		plain.emission = BASE_COLOR * 0.3
		plain.cull_mode = BaseMaterial3D.CULL_DISABLED
		return plain
	if facets == "only":
		return GridMatFactory.make(BASE_COLOR, {"show_only_wireframe": true})
	# "shown" — the shipped SimpleGrid material, unchanged.
	return GridMatFactory.make(BASE_COLOR, {})


## Godot's SphereMesh shape, rebuilt by hand: `rings` horizontal rings means rings + 1
## stacks, so rings = 1 is two stacks — a bipyramid with a `segs`-gon equator and no
## parallel but the equator, which is precisely the lantern sphere_low's own note
## describes. Each quad is split on one diagonal, as SphereMesh splits it, so the third
## family of lines `shown` paints is real and not an artefact of this rebuild.
##
## NON-INDEXED BY CONSTRUCTION: SurfaceTool.index() is never called, so every triangle
## owns its three vertices and VERTEX_ID % 3 in SimpleGrid.gdshader is a true barycentric
## coordinate. On an INDEXED mesh that expression is a fact about vertex-buffer order and
## the painted lines are not the triangle edges.
func _sphere_mesh(rings: int, segs: int) -> ArrayMesh:
	var stacks: int = rings + 1
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i_raw in stacks:
		var i: int = i_raw
		for j_raw in segs:
			var j: int = j_raw
			var a: Array = _sphere_point(i, j, stacks, segs)
			var b: Array = _sphere_point(i, j + 1, stacks, segs)
			var c: Array = _sphere_point(i + 1, j + 1, stacks, segs)
			var d: Array = _sphere_point(i + 1, j, stacks, segs)
			if i != 0:
				_emit(st, a, b, c)
			if i != stacks - 1:
				_emit(st, a, c, d)
	return st.commit()


## [position, normal] — the normal is the radial direction, which is what SphereMesh
## writes and what makes `hidden` able to lie at all.
func _sphere_point(i: int, j: int, stacks: int, segs: int) -> Array:
	var theta: float = PI * float(i) / float(stacks)
	var phi: float = TAU * float(j) / float(segs)
	var n := Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi))
	return [n * RADIUS + Vector3(0.0, CENTRE_Y, 0.0), n]


func _emit(st: SurfaceTool, a: Array, b: Array, c: Array) -> void:
	var pa: Vector3 = a[0]
	var pb: Vector3 = b[0]
	var pc: Vector3 = c[0]
	var na: Vector3 = a[1]
	var nb: Vector3 = b[1]
	var nc: Vector3 = c[1]
	st.set_normal(na)
	st.add_vertex(pa)
	st.set_normal(nb)
	st.add_vertex(pb)
	st.set_normal(nc)
	st.add_vertex(pc)


## grab_trihedron's shipped four-vertex literal — apex, and a base triangle — normalised
## to HALF instead of its shipped 0.6 so that every body occupies the same 1.0 m cube and
## the sweep's fixed camera does not change between values (grab_trihedron's own
## `_fit_to_box` makes the same argument about its `figure` axis).
##
## TWO DEVIATIONS FROM THE SHIPPED MESH, both deliberate and both recorded in the
## registry's `declines`:
##   · the base is CLOSED. grab_trihedron generates three faces and no base, so its solid
##     is an open shell with V - E + F = 4 - 6 + 3 = 1 — its own registry entry records
##     this as a doc_discrepancy left as found because closing it would change 7 live
##     placements. Here there are none, and an open shell photographed at `hidden` is a
##     hole: the axis would be measuring a missing face rather than a concealed edge.
##   · winding is forced OUTWARD by testing each face normal against the solid's centroid
##     rather than trusting the shipped index order.
## Normals are per FACE, one normal for all three vertices, exactly as
## PrimitiveMeshBuilder._add_triangle emits them. Flat shading is why `hidden` conceals
## nothing here: the facets are still visible as steps in brightness.
func _trihedron_mesh() -> ArrayMesh:
	var s: float = HALF
	var lift := Vector3(0.0, CENTRE_Y, 0.0)
	var v: Array = [
		Vector3(0.0, s, 0.0) + lift,
		Vector3(-s, -s, -s) + lift,
		Vector3(s, -s, -s) + lift,
		Vector3(0.0, -s, s) + lift,
	]
	var centroid := Vector3.ZERO
	for p in v:
		var pv: Vector3 = p
		centroid += pv
	centroid = centroid / float(v.size())

	var faces: Array = [[0, 1, 2], [0, 2, 3], [0, 3, 1], [1, 3, 2]]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in faces:
		var idx: Array = f
		var p0: Vector3 = v[int(idx[0])]
		var p1: Vector3 = v[int(idx[1])]
		var p2: Vector3 = v[int(idx[2])]
		var n: Vector3 = (p1 - p0).cross(p2 - p0).normalized()
		var mid: Vector3 = (p0 + p1 + p2) / 3.0
		if n.dot(mid - centroid) < 0.0:
			var swap: Vector3 = p1
			p1 = p2
			p2 = swap
			n = -n
		st.set_normal(n)
		st.add_vertex(p0)
		st.set_normal(n)
		st.add_vertex(p1)
		st.set_normal(n)
		st.add_vertex(p2)
	return st.commit()


## Guarded on both sides: a value has to be one this code can build, and it has to differ.
## A placement token that names none of the three keys never reaches _rebuild.
func apply_grid_config(config_data: Dictionary) -> void:
	_applying = true
	var changed: bool = false

	if config_data.has("facets"):
		var want_facets: String = str(config_data["facets"]).strip_edges().to_lower()
		if FACET_MODES.has(want_facets) and want_facets != facets:
			facets = want_facets
			changed = true

	if config_data.has("body"):
		var want_body: String = str(config_data["body"]).strip_edges().to_lower()
		if BODY_ORDER.has(want_body) and want_body != body:
			body = want_body
			changed = true

	if config_data.has("layout"):
		var want_layout: String = str(config_data["layout"]).strip_edges().to_lower()
		if LAYOUTS.has(want_layout) and want_layout != layout:
			layout = want_layout
			changed = true

	_applying = false
	if changed and is_inside_tree():
		_rebuild()
