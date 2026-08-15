extends Node3D
class_name PointMark

## point_mark — a POINT has no extension, so everything you can see of one is notation.
## Two pieces of notation, and neither of them is the point: the MARK you draw where it is,
## and the FRAME you measure it against. Cross them and count what is left when you take
## each away.
##
## THE FAMILY. Four artifacts in this corpus declare an axis about a point, and they carry
## FOUR disjoint vocabularies:
##
##   interactive_point_origin  mark: bead · crosshair ·   the BODY. What is drawn where the
##                             cage · halo                position is. gd:214-293.
##   point                     frame: world · local ·     the ADDRESS. Which origin it
##                             grid · mute                measures itself from, and whether
##                             attach: float · stake ·    the report faces you, stands, or
##                             plate                      lies on the ground. gd:92-109.
##   cube_scene_drag_points    handles: corners · top ·   the HANDLE. A point that exists
##                             diagonal                   because you can pull it; eight of
##                             triangulation: fixed ·     them are a cube, and the seam
##                             shortest                   between them is arguable.
##   citation_graph_node       reception: cited ·         the RELATION. A claim marked by
##                             contested · overturned ·   what orbits it — twelve refutations
##                             dogma · orphan             at 0.45 m, or, at `orphan`, nothing
##                                                        built at all. gd:176-200.
##
## Body · address · handle · relation. THE SPLIT THAT DECIDED THIS SYNTHESIS: only the first
## two work on ONE point. A handle needs seven siblings to be a corner of anything, and a
## reception needs a crowd — citation_graph_node's `orphan` builds no rings because a point
## with no relations has nothing to draw. So a single point, alone, can be given exactly two
## things, and they are the two this bench crosses. That is not a preference; it is what the
## four files can and cannot do with one point, read off their code.
##
## THE ARGUMENT, and someone can disagree with it. Klee's point is non-dimensional. Every
## mark is therefore a lie, and the four marks are four different lies, each importing a
## property the point does not have: bead lends it SIZE, crosshair lends it DIRECTION, cage
## lends it VOLUME, halo lends it a declared REACH. And a mark alone still does not locate
## anything, so a frame has to be supplied as well — which is a second piece of notation, and
## the axis measures how much of the picture it costs.
##
## The disagreement available: that the frame is not notation but the world itself, and only
## the mark is drawn. The grid column is where that objection is strongest — a lattice looks
## like a fact about space rather than a choice — and it is exactly where it costs something,
## because at `cage` the mark redraws the very cell the lattice already drew and adds nothing
## but brightness.
##
## WHAT THE VALUES ARE, all eight from the members' own files.
##
##   mark, interactive_point_origin's four, its numbers character for character
##     (MARK_SPAN 0.12, MARK_BAR 0.006, MARK_CELL 0.10, the .tscn's bead radius 0.03):
##       bead       the shipped 60 mm ball. Size, borrowed.
##       crosshair  three 120 mm bars on X, Y, Z. "the position is the INTERSECTION of its
##                  three coordinates, and what you see is a reach" (its gd:64-66).
##       cage       the twelve edges of a 100 mm cell and nothing inside — "an address with
##                  walls", which is what a voxel world actually stores.
##       halo       a ring at 51.6-60 mm around a 4 mm speck. The mark declares itself a mark.
##   frame, point's four, in point.gd's own order of nerve:
##       world      the address as three lengths from an origin that is NOT the point. Three
##                  smooth legs — x, then y, then z, the order the label prints them in.
##       local      the origin IS the point. point.gd:103 returns pos - global_position, and
##                  at rest that is (0.0, 0.0, 0.0), so all three legs have length zero and
##                  there is nothing to draw. See the null below.
##       grid       point.gd:106 rounds to whole cells, so the address is not three lengths
##                  but a CELL: space partitioned, drawn as the lattice around the point.
##       mute       point.gd:100 returns "" and hides the label. No frame at all.
##
## THE DESIGNED NULL, pre-registered in the registry before any capture: local and mute are
## the SAME PICTURE, to the byte, under every mark. In point.gd the two differ by a caption —
## "offset: (0.0, 0.0, 0.0)" against nothing — and a caption is the one thing this bench does
## not draw. Strip the text and a frame carried by the thing it locates is indistinguishable
## from no frame. A point cannot locate itself. That is the artifact's thesis standing in a
## cell of its own sheet, and it is falsifiable: if those tiles differ, this file drew
## something at `local` that it had no business drawing.
##
## Nothing animates, nothing is printed, nothing is random. Every box is integer arithmetic
## on the constants below, so two builds of one value are the same mesh.

## WHAT IS DRAWN WHERE THE POINT IS. Default bead — interactive_point_origin's shipped
## default and the lineage of the whole primitives sequence.
@export_enum("bead", "crosshair", "cage", "halo") var mark: String = "bead":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not MARKS.has(picked):
			return                      ## an unreachable value keeps the current body
		mark = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHAT IT IS MEASURED AGAINST. Default world — point.gd's shipped default, which reproduces
## its pre-promotion label exactly.
@export_enum("world", "local", "grid", "mute") var frame: String = "world":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not FRAMES.has(picked):
			return
		frame = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## One point, or all four marks in a row. NOT PART OF EITHER AXIS — wave 13 learned that an
## all-values value declared inside an axis makes capture_config_sweep union the row's AABB
## with every single and photograph the singles as specks. The registry fixture pins `single`.
@export_enum("single", "ladder") var layout: String = "single":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not LAYOUTS.has(picked):
			return
		layout = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

const MARKS: PackedStringArray = ["bead", "crosshair", "cage", "halo"]
const FRAMES: PackedStringArray = ["world", "local", "grid", "mute"]
const LAYOUTS: PackedStringArray = ["single", "ladder"]

# ── the stage, metres ──────────────────────────────────────────────────────────────────
## The stage is a 0.50 m cube of empty air with the point at its centre, and it is drawn by
## an INVISIBLE anchor (layers = 0) present in all sixteen variants. That is what pins the
## union AABB: capture_config_sweep unions across a spec's variants, and without the anchor
## the `mute` tiles would frame a 0.12 m mark while the `grid` tiles frame a 0.30 m lattice,
## which moves the camera between cells and makes every number a fact about the framing.
##
## 0.50 and not the 0.80 the brief asked for, and the reason is a measured number: rasterised
## through the sweep's own camera, a bare mark at frame=mute covers 0.66% of the frame on a
## 0.50 m stage and 0.30% on a 0.80 m one — and artifact_dna_critic refuses to judge below
## BLANK_SUBJECT = 0.20%. A point is legitimately a small subject; it is not allowed to be
## an unjudgeable one.
const STAGE: float = 0.50
## Reading height. The registry sets auto_ground:false, so this survives placement: a point
## has no base to stand on, and grounding a 0.50 m stage would put the mark at 0.25 m.
const POINT_Y: float = 0.95

## The lattice pitch, and it is interactive_point_origin's MARK_CELL to the millimetre. That
## identity is the whole reason the (cage, grid) cell means anything: the cage IS one cell of
## the grid, so there the mark redraws what the frame already said.
const CELL: float = 0.10
## Three cells on a side, centred, so the point sits at the centre of the middle cell. A
## lattice has no edge; this is a patch of one, and it is the patch the mark is inside.
const CELLS: int = 3
## Thinner than the cage bar (0.0051) ON PURPOSE: at frame=grid the cage's twelve bars
## swallow the middle cell's twelve edges whole rather than z-fighting with them.
const LAT_T: float = 0.0032
const LEG_T: float = 0.005

# ── the marks, interactive_point_origin's constants verbatim ───────────────────────────
const BEAD_R: float = 0.03            ## the .tscn's Sphere radius, point_mesh.gd's 30 mm
const MARK_SPAN: float = 0.12         ## its gd:118
const MARK_BAR: float = 0.006         ## its gd:119
const MARK_CELL: float = 0.10         ## its gd:120
const CAGE_T: float = MARK_BAR * 0.85 ## its gd:270
const HALO_IN: float = MARK_SPAN * 0.43
const HALO_OUT: float = MARK_SPAN * 0.5
const SPECK_R: float = 0.004

const LADDER_PITCH: float = 0.62

## The mark's palette is interactive_point_origin's _build_mark_material with the .tscn's
## overrides (glow_color white, glow_emission_energy 2.5, times its own 0.6), so the axis is
## about form and not colour — its own words.
const MARK_COLOR: Color = Color(0.95, 0.95, 0.92)
const MARK_EMISSION: Color = Color(1.0, 1.0, 1.0)
const MARK_ENERGY: float = 1.5
## The apparatus is deliberately a different register: dim, unlit, subordinate. Notation
## about the space rather than notation about the point.
const FRAME_COLOR: Color = Color(0.42, 0.44, 0.50)

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
	if config_data.has("mark"):
		mark = str(config_data["mark"])
	if config_data.has("frame"):
		frame = str(config_data["frame"])
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
		names = MARKS.duplicate()
	else:
		names.append(_pick(mark, MARKS, "bead"))
	var count: int = names.size()
	for i in range(count):
		var holder := Node3D.new()
		holder.name = "Mark_" + names[i]
		holder.position = Vector3((float(i) - float(count - 1) * 0.5) * LADDER_PITCH, 0.0, 0.0)
		add_child(holder)
		_built.append(holder)
		_build_variant(holder, names[i])


## NO YAW. rule_bench turns its wall to face the standpoint because a wall seen edge-on is
## not a wall; this body is axis-aligned on purpose, because the standpoint's own bearing
## (yaw 0.62, pitch -0.26) is off-axis from all three of X, Y and Z. Every coordinate
## direction therefore has visible extent in the frame — the crosshair's third bar is not
## end-on, the lattice is seen in three-quarter — which is the anamorphic check made
## structural rather than left to luck.
func _build_variant(holder: Node3D, mark_name: String) -> void:
	_build_anchor(holder)

	var app := SurfaceTool.new()
	app.begin(Mesh.PRIMITIVE_TRIANGLES)
	var drew_frame: bool = _build_frame(app)
	if drew_frame:
		_commit(holder, "Frame", app, FRAME_COLOR, false)

	var body := SurfaceTool.new()
	body.begin(Mesh.PRIMITIVE_TRIANGLES)
	var drew_body: bool = _build_mark(holder, body, mark_name)
	if drew_body:
		_commit(holder, "Mark", body, MARK_COLOR, true)


## The invisible 0.50 m cube. layers = 0 and not visible = false: visibility propagates to
## children and would take anything parented here down with it, while layers is per-instance
## and leaves the mesh where _subtree_aabb (capture_config_sweep gd:1488) can still measure
## it. This is the whole reason all sixteen tiles share one camera.
func _build_anchor(holder: Node3D) -> void:
	var anchor := MeshInstance3D.new()
	anchor.name = "StageAnchor"
	var bm := BoxMesh.new()
	bm.size = Vector3(STAGE, STAGE, STAGE)
	anchor.mesh = bm
	anchor.position = Vector3(0.0, POINT_Y, 0.0)
	anchor.layers = 0
	anchor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(anchor)


## Returns true when the frame drew anything at all. `local` and `mute` both return false,
## and that is the designed null: see the header.
func _build_frame(st: SurfaceTool) -> bool:
	if frame == "grid":
		var span: float = float(CELLS) * CELL
		var h: float = span * 0.5
		for i in range(CELLS + 1):
			for j in range(CELLS + 1):
				var a: float = -h + float(i) * CELL
				var b: float = -h + float(j) * CELL
				_add_box(st, _at(0.0, a, b), Vector3(span, LAT_T, LAT_T))
				_add_box(st, _at(a, 0.0, b), Vector3(LAT_T, span, LAT_T))
				_add_box(st, _at(a, b, 0.0), Vector3(LAT_T, LAT_T, span))
		return true
	if frame == "world":
		# Three legs from the stage's far-lower corner to the point: along x, then y, then z,
		# which is the order point.gd prints them in. SMOOTH, ungraduated — world reads
		# "%.1f" metres, a continuous length, where grid reads "%d", a count of cells; that
		# difference between the two format strings is the difference between these two
		# bodies. The corner is at the very edge of the stage because a world origin is
		# somewhere else by definition and cannot be in the picture with the point.
		var q: float = STAGE * 0.5
		_add_box(st, _at(-q * 0.5, -q, -q), Vector3(q, LEG_T, LEG_T))
		_add_box(st, _at(0.0, -q * 0.5, -q), Vector3(LEG_T, q, LEG_T))
		_add_box(st, _at(0.0, 0.0, -q * 0.5), Vector3(LEG_T, LEG_T, q))
		return true
	return false


## Returns true when the mark contributed to the SurfaceTool. bead and halo hang engine
## primitives (SphereMesh, TorusMesh) instead, for their winding rather than mine.
func _build_mark(holder: Node3D, st: SurfaceTool, mark_name: String) -> bool:
	if mark_name == "crosshair":
		_add_box(st, _at(0.0, 0.0, 0.0), Vector3(MARK_SPAN, MARK_BAR, MARK_BAR))
		_add_box(st, _at(0.0, 0.0, 0.0), Vector3(MARK_BAR, MARK_SPAN, MARK_BAR))
		_add_box(st, _at(0.0, 0.0, 0.0), Vector3(MARK_BAR, MARK_BAR, MARK_SPAN))
		return true
	if mark_name == "cage":
		var h: float = MARK_CELL * 0.5
		for ia in range(2):
			for ib in range(2):
				var sa: float = -h if ia == 0 else h
				var sb: float = -h if ib == 0 else h
				_add_box(st, _at(0.0, sa, sb), Vector3(MARK_CELL, CAGE_T, CAGE_T))
				_add_box(st, _at(sa, 0.0, sb), Vector3(CAGE_T, MARK_CELL, CAGE_T))
				_add_box(st, _at(sa, sb, 0.0), Vector3(CAGE_T, CAGE_T, MARK_CELL))
		return true
	if mark_name == "halo":
		var torus := TorusMesh.new()
		torus.inner_radius = HALO_IN
		torus.outer_radius = HALO_OUT
		_prim(holder, "Ring", torus, Vector3.ZERO)
		var speck := SphereMesh.new()
		speck.radius = SPECK_R
		speck.height = SPECK_R * 2.0
		_prim(holder, "Speck", speck, Vector3.ZERO)
		return false
	var bead := SphereMesh.new()
	bead.radius = BEAD_R
	bead.height = BEAD_R * 2.0
	_prim(holder, "Bead", bead, Vector3.ZERO)
	return false


## Everything is built about the point, and the point is at POINT_Y.
func _at(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, POINT_Y + y, z)


func _prim(holder: Node3D, mesh_name: String, mesh: Mesh, at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = mesh
	mi.material_override = _mat(MARK_COLOR, true)
	mi.position = _at(at.x, at.y, at.z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(mi)


## An axis-aligned box, twelve triangles, wound outward with explicit per-face normals. The
## materials are CULL_DISABLED as well: wave 13's lesson is that a body photographed from
## behind is indistinguishable from a body that was never built.
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


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
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
	m.metallic = 0.1
	m.roughness = 0.65
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emissive:
		m.emission_enabled = true
		m.emission = MARK_EMISSION
		m.emission_energy_multiplier = MARK_ENERGY
	return m
