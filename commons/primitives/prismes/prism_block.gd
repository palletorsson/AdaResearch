# @identity
# essence: the reference triangular unit — a 1 m prism kept next to a cube so a room has
#          something asymmetric to measure against
# desire: to show that "one unit" is a claim about wholeness, not about size
# critical_parameter: grain — how many pieces the unit is made of, at constant silhouette
# triggers: _ready() builds the grain; apply_grid_config re-reads `#grain:` from map JSON
# emerges: the same triangle read five ways — one block, a parted block, four, nine, and
#          nine edges with no faces at all
# needs: the shipped PrismMesh + SimpleGrid material [present]; a collider that follows the
#        grain [absent by choice — collision stays the solid 1 m prism at every value]
# relationships: sibling of cube_scene, which carries the SAME axis under the SAME word;
#                the 4- and 9-piece subdivisions are the geodesic frequencies dome_kit
#                teaches later, so primitive and dome now rhyme
# truth: subdividing a triangle is not the same operation as subdividing a square. The
#        square splits into squares forever; the triangle splits into triangles that point
#        the OTHER WAY. Half the pieces of a subdivided triangle are upside down, and there
#        is no way to make them agree.

extends Node3D
class_name PrismBlock

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS
# ═══════════════════════════════════════════════════════════════════

## grain — how finely the reference unit is made of parts.
##
## The SAME WORD as on cube_scene, deliberately, with the same meaning and the same value
## ladder: a map author who learns `grain` on the cube already knows it here. The
## triangular silhouette is held constant at every value — 1 m tall, 1 m base, 1 m deep —
## and what varies is how many pieces occupy it. That is the whole point of a reference
## unit: it exists to be compared against, so it must not move when it changes.
##
## Worth varying because this block's job in a room is to answer "how big is one thing?",
## and every value asks that question differently. `solid` says one thing is one thing.
## `split` says it has an inside and the inside has a seam. `quartered` and `lattice` say
## the unit was always an aggregate at some frequency, and pick the triangle's OWN
## subdivision (4 = 3 upright + 1 inverted; 9 = 6 upright + 3 inverted) rather than a grid
## imported from the cube. `shell` says the unit was never volume at all, only its edges.
##
## solid is the pre-promotion look, exactly: the shipped PrismMesh, untouched, no children.
@export_enum("solid", "split", "quartered", "lattice", "shell") var grain: String = "solid"

## Allow-list for _pick_axis. A map token outside this set is a typo and must land back on
## the legacy look rather than half-resolving into no geometry at all.
const GRAINS: PackedStringArray = ["solid", "split", "quartered", "lattice", "shell"]

# ── Reference unit ────────────────────────────────────────────────
# The shipped PrismMesh is the Godot default, size (1,1,1), left_to_right 0.5: a triangle
# in XY with apex (0, +0.5) and base corners (±0.5, -0.5), extruded 1 m along Z. Every
# variant below is built from these three numbers so the silhouette cannot drift.
const HALF: float = 0.5
const DEPTH: float = 1.0

# ── split ─────────────────────────────────────────────────────────
## The lower block is a truncated prism — the shipped triangle cut off at 0.48 m, which
## leaves a trapezoid 1.0 m wide at the floor and 0.52 m wide at the cut. The upper piece
## is the top half of the same prism (a PrismMesh at half scale in X and Y, full depth)
## floated 0.04 m clear. 4 cm is chosen to read as a parting and not as a crack: at the
## capture distance for a 1 m object it is roughly 4% of frame height.
const SPLIT_LOWER_H: float = 0.48
const SPLIT_GAP: float = 0.04

# ── quartered / lattice ───────────────────────────────────────────
## Sub-prism edge scale, and the radial nudge away from the parent triangle's centroid that
## opens the gaps. Scaling a sub-triangle about its own centroid only buys ~0.013 m of gap
## at frequency 2, so the nudge carries the rest. Both numbers are constants, not jitter —
## two builds of one value are pixel-identical.
const QUARTER_SCALE: float = 0.48
const QUARTER_PUSH: float = 0.010
const LATTICE_SCALE: float = 0.31
const LATTICE_PUSH: float = 0.004

# ── shell ─────────────────────────────────────────────────────────
## Strut section. 0.05 m on a 1 m unit is 5% of the silhouette — thick enough to survive
## the capture camera's auto-framing, thin enough that the prism reads as hollow.
const STRUT: float = 0.05

# ═══════════════════════════════════════════════════════════════════
# STATE
# ═══════════════════════════════════════════════════════════════════

## True once _build_all has run. apply_grid_config arrives via call_deferred AFTER _ready,
## but a caller may still reach us early; before the first build there is nothing to tear
## down and the resolved value is simply what _ready will use.
var _built: bool = false

## ONLY the nodes this script created. The teardown walks this array and never
## get_children() — the grid adds label plates, packaging and tag markers to the same
## parent, and freeing those was the regression that cost a second pass last round.
var _built_nodes: Array[Node] = []

## The scene's own MeshInstance3D. Never created here, never freed here — only shown
## (grain=solid) or hidden (every other value).
var _shipped: MeshInstance3D = null


# ═══════════════════════════════════════════════════════════════════
# LIFECYCLE
# ═══════════════════════════════════════════════════════════════════

func _ready() -> void:
	_cache_shipped()
	_build_all()          # SYNCHRONOUS — children exist when _ready returns
	_built = true


## Called by GridInteractablesComponent (deferred, ahead of framing and auto-grounding) and
## by curation_station, which passes {"emissive": false} one line after hiding our labels.
## That dict carries no axis key, so it MUST NOT rebuild: a rebuild there would throw away
## framing that was applied a moment earlier and is never re-applied.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_grain: String = grain
	if config_data.has("grain"):
		grain = _pick_axis(str(config_data["grain"]), GRAINS, grain)

	if not _built:
		return                      # nothing built yet; _ready will use the resolved value
	if grain == before_grain:
		return                      # touch nothing, say nothing

	_rebuild_now()
	print("[PrismBlock] Config applied — grain=%s" % [grain])


## Accept an axis value only if it names something this script actually builds. Lower-case,
## strip, and fall back to the legacy look on anything else.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous teardown + rebuild. No call_deferred anywhere on this path: a deferred
## rebuild that removes children first makes _auto_ground_artifact measure a zero AABB, so
## it returns early and the block is never seated on its cube.
func _rebuild_now() -> void:
	for c in _built_nodes:
		if is_instance_valid(c):
			remove_child(c)         # leaves the tree synchronously — no double-render
			c.queue_free()
	_built_nodes.clear()
	_build_all()


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	# The shipped mesh IS the solid variant. Every other value hides it and replaces it.
	if _shipped != null:
		_shipped.visible = (grain == "solid")

	match grain:
		"split":
			_build_split()
		"quartered":
			_build_subdivision(2, QUARTER_SCALE, QUARTER_PUSH)
		"lattice":
			_build_subdivision(3, LATTICE_SCALE, LATTICE_PUSH)
		"shell":
			_build_shell()
		_:
			pass                    # solid — adds nothing, hides nothing


## solid → split. One horizontal cut through the mid-plane, opened 4 cm.
##
## Lower: the shipped triangle truncated at y = -0.5 + 0.48, extruded the full metre —
## a trapezoid 1.00 m wide at the floor tapering to 0.52 m at the cut.
## Upper: the top half of the same prism, i.e. a PrismMesh of size (0.5, 0.5, 1.0), its
## base floated to y = -0.02 + 0.04.
func _build_split() -> void:
	var cut_y: float = -HALF + SPLIT_LOWER_H              # -0.02
	var hw_cut: float = _half_width_at(cut_y)             # 0.26

	var outline: PackedVector2Array = PackedVector2Array([
		Vector2(-HALF, -HALF),
		Vector2(HALF, -HALF),
		Vector2(hw_cut, cut_y),
		Vector2(-hw_cut, cut_y),
	])
	var lower: MeshInstance3D = MeshInstance3D.new()
	lower.name = "GrainSplitLower"
	lower.mesh = _extrude_polygon(outline, DEPTH * 0.5)
	_adopt(lower, Transform3D.IDENTITY)

	var top: PrismMesh = PrismMesh.new()
	top.size = Vector3(HALF, HALF, DEPTH)
	var upper: MeshInstance3D = MeshInstance3D.new()
	upper.name = "GrainSplitUpper"
	upper.mesh = top
	var base_y: float = cut_y + SPLIT_GAP                 # 0.02
	_adopt(upper, Transform3D(Basis.IDENTITY, Vector3(0.0, base_y + HALF * 0.5, 0.0)))


## solid → quartered (freq 2) / lattice (freq 3). The triangle's own subdivision, not the
## cube's: at frequency f the face carries f*(f+1)/2 upright sub-triangles and
## f*(f-1)/2 inverted ones. Every piece is extruded the full metre.
func _build_subdivision(freq: int, sub_scale: float, push: float) -> void:
	var big_centroid: Vector2 = Vector2(0.0, -HALF / 3.0)
	var lift: float = sub_scale / 6.0    # triangle centroid → bounding-box centre
	var made: int = 0

	for r in range(freq):
		# Upright pieces: r+1 of them in row r.
		for i in range(r + 1):
			var c_up: Vector2 = (_lattice_point(r, i, freq)
				+ _lattice_point(r + 1, i, freq)
				+ _lattice_point(r + 1, i + 1, freq)) / 3.0
			var o_up: Vector2 = c_up + (c_up - big_centroid).normalized() * push
			_add_sub_prism(sub_scale, Vector3(o_up.x, o_up.y + lift, 0.0), false, made)
			made += 1
		# Inverted pieces: r of them in row r (none in the top row).
		for i in range(r):
			var c_dn: Vector2 = (_lattice_point(r, i, freq)
				+ _lattice_point(r, i + 1, freq)
				+ _lattice_point(r + 1, i + 1, freq)) / 3.0
			var o_dn: Vector2 = c_dn + (c_dn - big_centroid).normalized() * push
			_add_sub_prism(sub_scale, Vector3(o_dn.x, o_dn.y - lift, 0.0), true, made)
			made += 1


## solid → shell. No faces: the nine edges of a triangular prism as square-section struts.
## Three at the front triangle, three at the back, three lateral. The triangle struts are
## pulled 0.025 m inboard in Z and the lateral struts shortened by the same, so the nine
## bars meet at the corners and the assembly still measures 1 m deep.
func _build_shell() -> void:
	var tri: PackedVector2Array = PackedVector2Array([
		Vector2(0.0, HALF), Vector2(-HALF, -HALF), Vector2(HALF, -HALF)])
	var z_end: float = HALF - STRUT * 0.5                 # 0.475

	# Three lateral struts, one per triangle corner, running the depth.
	for v in tri:
		var lat: BoxMesh = BoxMesh.new()
		lat.size = Vector3(STRUT, STRUT, DEPTH - STRUT)
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.name = "GrainShellLateral_%d_%d" % [int(round(v.x * 100.0)), int(round(v.y * 100.0))]
		mi.mesh = lat
		_adopt(mi, Transform3D(Basis.IDENTITY, Vector3(v.x, v.y, 0.0)))

	# Six triangle-edge struts: three at each end cap.
	for e in range(3):
		var a: Vector2 = tri[e]
		var b: Vector2 = tri[(e + 1) % 3]
		var d: Vector2 = b - a
		var edge: BoxMesh = BoxMesh.new()
		edge.size = Vector3(d.length() + STRUT, STRUT, STRUT)
		var ang: float = atan2(d.y, d.x)
		var mid: Vector2 = (a + b) * 0.5
		for s in [1.0, -1.0]:
			var mi2: MeshInstance3D = MeshInstance3D.new()
			mi2.name = "GrainShellEdge_%d_%s" % [e, "f" if s > 0.0 else "b"]
			mi2.mesh = edge
			var basis: Basis = Basis(Vector3.BACK, ang)
			_adopt(mi2, Transform3D(basis, Vector3(mid.x, mid.y, float(s) * z_end)))


# ═══════════════════════════════════════════════════════════════════
# GEOMETRY HELPERS
# ═══════════════════════════════════════════════════════════════════

## Half-width of the reference triangle at height y. 0.5 at the floor, 0 at the apex.
func _half_width_at(y: float) -> float:
	return HALF * (HALF - y)


## Barycentric lattice point (row r counted from the apex, index i along the row) on the
## reference triangle subdivided at frequency f. Row r sits at y = 0.5 - r/f and spans
## x in [-r/(2f), +r/(2f)] with r+1 evenly spaced points.
func _lattice_point(r: int, i: int, f: int) -> Vector2:
	var ff: float = float(f)
	return Vector2(-float(r) / (2.0 * ff) + float(i) / ff, HALF - float(r) / ff)


## One sub-prism of the subdivided face. Inverted pieces are the same PrismMesh turned
## through PI about Z — the reference triangle is symmetric in X, so nothing else changes.
func _add_sub_prism(sub_scale: float, at: Vector3, inverted: bool, idx: int) -> void:
	var pm: PrismMesh = PrismMesh.new()
	pm.size = Vector3(sub_scale, sub_scale, DEPTH)
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "GrainSub_%d_%s" % [idx, "dn" if inverted else "up"]
	mi.mesh = pm
	var basis: Basis = Basis(Vector3.BACK, PI) if inverted else Basis.IDENTITY
	_adopt(mi, Transform3D(basis, at))


## A convex polygon in XY, extruded along Z with both caps. Built non-indexed on purpose:
## SimpleGrid.gdshader derives its barycentric coordinates from VERTEX_ID % 3, so shared
## vertices would smear the wireframe this whole family is drawn in.
func _extrude_polygon(pts: PackedVector2Array, z_half: float) -> ArrayMesh:
	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var n: int = pts.size()
	# Front cap (+Z) and back cap (-Z), fanned from vertex 0.
	for i in range(1, n - 1):
		st.set_normal(Vector3.BACK)
		st.add_vertex(Vector3(pts[0].x, pts[0].y, z_half))
		st.add_vertex(Vector3(pts[i].x, pts[i].y, z_half))
		st.add_vertex(Vector3(pts[i + 1].x, pts[i + 1].y, z_half))
		st.set_normal(Vector3.FORWARD)
		st.add_vertex(Vector3(pts[0].x, pts[0].y, -z_half))
		st.add_vertex(Vector3(pts[i + 1].x, pts[i + 1].y, -z_half))
		st.add_vertex(Vector3(pts[i].x, pts[i].y, -z_half))

	# Side walls.
	for i in range(n):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % n]
		var d: Vector2 = b - a
		var nrm: Vector3 = Vector3(d.y, -d.x, 0.0).normalized()
		st.set_normal(nrm)
		st.add_vertex(Vector3(a.x, a.y, z_half))
		st.add_vertex(Vector3(b.x, b.y, z_half))
		st.add_vertex(Vector3(b.x, b.y, -z_half))
		st.set_normal(nrm)
		st.add_vertex(Vector3(a.x, a.y, z_half))
		st.add_vertex(Vector3(b.x, b.y, -z_half))
		st.add_vertex(Vector3(a.x, a.y, -z_half))

	return st.commit()


# ═══════════════════════════════════════════════════════════════════
# SCENE PLUMBING
# ═══════════════════════════════════════════════════════════════════

## Parent a node this script made, give it the shipped material, and record it for teardown.
func _adopt(mi: MeshInstance3D, xform: Transform3D) -> void:
	var mat: Material = _shipped_material()
	if mat != null:
		mi.material_override = mat
	add_child(mi)
	mi.transform = xform
	_built_nodes.append(mi)


## The scene's own MeshInstance3D — by path first, then by search, so the script survives
## being attached to a differently-shaped sibling scene.
func _cache_shipped() -> void:
	_shipped = get_node_or_null("StaticBody3D/MeshInstance3D") as MeshInstance3D
	if _shipped == null:
		_shipped = _find_mesh_instance(self)


func _find_mesh_instance(n: Node) -> MeshInstance3D:
	for c in n.get_children():
		if c is MeshInstance3D:
			return c as MeshInstance3D
		var deep: MeshInstance3D = _find_mesh_instance(c)
		if deep != null:
			return deep
	return null


## Whatever the shipped mesh is wearing — the SimpleGrid ShaderMaterial with its red
## wireframe and magenta emission. Read from the scene rather than re-created here so a
## palette edit in the .tscn keeps reaching every variant.
func _shipped_material() -> Material:
	if _shipped == null:
		return null
	if _shipped.material_override != null:
		return _shipped.material_override
	if _shipped.mesh == null:
		return null
	var over: Material = _shipped.get_surface_override_material(0)
	if over != null:
		return over
	if _shipped.mesh is PrimitiveMesh:
		return (_shipped.mesh as PrimitiveMesh).material
	if _shipped.mesh.get_surface_count() > 0:
		return _shipped.mesh.surface_get_material(0)
	return null
