extends Node3D
class_name ArrangementYard

## arrangement_yard — an arrangement of identical things is a CLAIM about the relation
## between them.
##
## THE FAMILY. Four artifacts declare an axis called `arrangement`, in three vocabularies.
## grabcolorcollection (ten colour swatches) and gravity_gun_test_scene (ten shootable
## spheres) declare grid · ramp · ring · stack, character for character; particle_systems
## (four emitters) declares grid · row · ring; scale_lines declares ladder · log · ruler.
## The first three ask the same question — how is a set of like things laid out — and are
## the subject. scale_lines asks a different one: its five lines are five different lengths,
## and its words are the SPACING LAW between them (fixed heights, heights by log10, all
## anchored at one zero). Where the rungs of a ladder go is not how a collection is filed,
## so scale_lines is kin and its words are not offered here — except that its `log`
## (height by the object's own magnitude) is the purest form of what the other two call
## `ramp`, and shaped how ramp is read below.
##
## THE ARGUMENT. Ten identical bodies are ten identical bodies whichever way they lie; the
## layout is the only place a collection says anything, and what it says is what RELATION
## holds between its members. grid says they are interchangeable — every body has the same
## neighbours in the same directions; a position is an address, not a rank. row says they
## are ORDERED — a first, a last, and each with a before and an after. ramp says the order
## is a QUANTITY — not merely before and after but higher-by-this-much, the rank made
## metric. ring says they are CYCLIC — every body has two neighbours and none is first.
## stack says each DEPENDS on the ones below it — take out a lower body and the ones above
## it fall. Same ten cubes, five theories of what the collection is. The disagreement
## available: that layout is decoration and the theory lives in the bodies. The relation
## reading is built to have that quarrel — it draws the relation each layout claims and
## nothing else changes.
##
## THE BODY, NOT A GAUGE. Ten cubes of one size and one colour, deterministic, no seed. The
## members' own number: grabcolorcollection files ten swatches, gravity_gun_test_scene
## spawns ten spheres and its stack is 4 + 3 + 2 + 1, which is ten. Nothing rolls and
## nothing moves.

## WHAT THE ARRANGEMENT CLAIMS. Every member that shares the honest vocabulary defaults to
## grid (grabcolorcollection gd:201, gravity_gun_test_scene gd:47, particle_systems gd:65),
## so grid is the default here, three of three.
##   grid   5 x 2 flat on the floor at 0.20 m pitch — grabcolorcollection's 5 x 2 page and
##          gravity_gun_test_scene's 2 x 5 wall laid down. Every body has the same
##          neighbours to left, right, front and back; the relation is the LATTICE, thirteen
##          rods (eight along the long side, five across), none of them first or above.
##          Interchangeable: an address, not an order.
##   row    ten in one line at 0.105 m pitch — particle_systems' `row`, "abreast like
##          specimens on a shelf, read left to right". Nine rods, a CHAIN with two ends.
##          Ordered: a first and a last, each with a before and an after.
##   ramp   the row with each body raised 0.045 m above the one before it, 0.405 m over
##          the run — gravity_gun_test_scene's ramp (spawn_ramp_pattern: half-pitch rank,
##          rise 2 x spacing) and grabcolorcollection's (each sheet lifted by its own
##          luminance) both raise by HEIGHT. With identical bodies the only quantity is the
##          rank, so the rank is made metric: the same nine rods, now sloped. Ordered by
##          how much.
##   ring   ten on a circle of radius 0.30 m, each turned to face outward — gravity_gun's
##          spawn_ring_pattern at 2 x spacing and grabcolorcollection's wheel, tiles
##          "facing outward". Ten rods, a CYCLE: two neighbours each and no first.
##   stack  a brick pyramid, courses of 4 + 3 + 2 + 1, each upper body seated across the
##          two beneath it — gravity_gun_test_scene's spawn_stack_pattern count exactly, and
##          its gloss "each level bearing the one above". Twelve rods, from each upper body
##          down to the two it rests on: a DEPENDENCY, not a chain — grabcolorcollection's
##          deck (one pile, 12 mm apart) was the other reading of `stack` and lost, because
##          a pile of identical cubes is a row stood on end and its rods are a chain.
@export_enum("grid", "row", "ramp", "ring", "stack") var arrangement: String = "grid":
	set(v):
		arrangement = v
		if is_inside_tree():
			_rebuild()

## WHAT IS DRAWN OF THE COLLECTION.
##   bodies     the ten cubes alone, at full edge — what every member ships. The
##              arrangement makes its claim without help.
##   relation   the claim drawn out: each body pulled back to half its edge about its own
##              centre, and the neighbour relation laid between them as thin amber rods —
##              the lattice, the chain, the sloped chain, the cycle, the bearing. The
##              arrangement as the graph it claims.
##   footprint  the arrangement as its floor plan knows it: a slate plate over the hull
##              of the bodies' plan squares, a pad under each body's plan — every body
##              projected to the floor whether it touches it or not — and no bodies.
##              Whatever the layout said in height is gone: a ramp's plan is a row's,
##              and a stack of ten shows four pads because its upper courses project
##              inside its bottom course. That is a fact about floor plans, and it is
##              the designed null in the registry.
@export_enum("bodies", "relation", "footprint") var reading: String = "bodies":
	set(v):
		reading = v
		if is_inside_tree():
			_rebuild()

const ARRANGEMENTS: PackedStringArray = ["grid", "row", "ramp", "ring", "stack"]
const READINGS: PackedStringArray = ["bodies", "relation", "footprint"]

## Ten, the family's number. Not an export: the pyramid is 4 + 3 + 2 + 1 and the grid is
## 5 x 2, and a different count is a different artifact.
const COUNT: int = 10
const COURSES: PackedInt32Array = [4, 3, 2, 1]

## Body and pitch, metres. Sized so the widest arrangement (row, 1.035 m) stays near one
## metre and the tightest (stack, 0.36 m) is not a speck beside it. Extents, X x Y x Z:
## grid 0.89 x 0.09 x 0.29 · row 1.035 x 0.09 x 0.09 · ramp 1.035 x 0.495 x 0.09 ·
## ring 0.69 x 0.09 x 0.69 · stack 0.36 x 0.36 x 0.09. The pitches differ per arrangement
## because the members' do (gravity_gun's ring is at 2 x spacing, its ramp at half).
const EDGE: float = 0.09
const ROW_PITCH: float = 0.105
const RAMP_RISE: float = 0.045
const GRID_PITCH: float = 0.20
const RING_RADIUS: float = 0.30
const NODE_EDGE: float = 0.045
const ROD_RADIUS: float = 0.006
const PLATE_THICK: float = 0.012
const PAD_THICK: float = 0.03
const PLATE_MARGIN: float = 0.02

const BONE: Color = Color(0.86, 0.82, 0.74)
const AMBER: Color = Color(1.0, 0.70, 0.30)
const SLATE: Color = Color(0.22, 0.23, 0.27)

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("arrangement"):
		arrangement = _pick(str(config_data["arrangement"]), ARRANGEMENTS, arrangement)
	if config_data.has("reading"):
		reading = _pick(str(config_data["reading"]), READINGS, reading)
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
	var arr: String = _pick(arrangement, ARRANGEMENTS, "grid")
	var rd: String = _pick(reading, READINGS, "bodies")
	var holder := Node3D.new()
	holder.name = arr + "_" + rd
	add_child(holder)
	_built.append(holder)
	var places: Array = _placements(arr)
	match rd:
		"relation":
			_build_relation(holder, places, _relations(arr))
		"footprint":
			_build_footprint(holder, places)
		_:
			_build_bodies(holder, places, EDGE)


# ── the arrangement: where each body stands, and what it is related to ─────────────────

## One entry per body: {"pos": centre, "yaw": rotation about Y}. Bases on the floor at
## y = 0 (the ramp's rise lifts each base by its rank), so the yard grounds like a body.
func _placements(arr: String) -> Array:
	var out: Array = []
	var half: float = EDGE * 0.5
	match arr:
		"row":
			for i in range(COUNT):
				out.append({"pos": Vector3((float(i) - 4.5) * ROW_PITCH, half, 0.0), "yaw": 0.0})
		"ramp":
			for i in range(COUNT):
				out.append({"pos": Vector3((float(i) - 4.5) * ROW_PITCH, half + float(i) * RAMP_RISE, 0.0),
						"yaw": 0.0})
		"ring":
			for i in range(COUNT):
				var a: float = TAU * float(i) / float(COUNT)
				out.append({"pos": Vector3(RING_RADIUS * sin(a), half, RING_RADIUS * cos(a)), "yaw": a})
		"stack":
			for k in range(COURSES.size()):
				var cnt: int = COURSES[k]
				for j in range(cnt):
					var x: float = (float(j) - float(cnt - 1) * 0.5) * EDGE
					out.append({"pos": Vector3(x, half + float(k) * EDGE, 0.0), "yaw": 0.0})
		_:
			for i in range(COUNT):
				var r: int = 1 if i >= 5 else 0
				var c: int = i % 5
				out.append({"pos": Vector3((float(c) - 2.0) * GRID_PITCH, half,
						(float(r) - 0.5) * GRID_PITCH), "yaw": 0.0})
	return out


## Index pairs of related bodies — the relation each arrangement claims.
func _relations(arr: String) -> Array:
	var out: Array = []
	match arr:
		"row", "ramp":
			for i in range(COUNT - 1):
				out.append(Vector2i(i, i + 1))
		"ring":
			for i in range(COUNT):
				out.append(Vector2i(i, (i + 1) % COUNT))
		"stack":
			# Course starts 0, 4, 7, 9. Each upper body rests on the two beneath it: the
			# body at slot j of course k sits across slots j and j + 1 of course k - 1.
			var starts: PackedInt32Array = [0, 4, 7, 9]
			for k in range(1, COURSES.size()):
				for j in range(COURSES[k]):
					var up: int = starts[k] + j
					out.append(Vector2i(up, starts[k - 1] + j))
					out.append(Vector2i(up, starts[k - 1] + j + 1))
		_:
			for i in range(COUNT):
				var r: int = 1 if i >= 5 else 0
				var c: int = i % 5
				if c < 4:
					out.append(Vector2i(i, i + 1))
				if r == 0:
					out.append(Vector2i(i, i + 5))
	return out


# ── the readings ────────────────────────────────────────────────────────────────────────

func _build_bodies(holder: Node3D, places: Array, edge: float) -> void:
	for i in range(places.size()):
		var p: Dictionary = places[i]
		var mi: MeshInstance3D = _box(p["pos"], Vector3(edge, edge, edge), BONE, "Body%d" % i)
		mi.rotate_y(float(p["yaw"]))
		holder.add_child(mi)


func _build_relation(holder: Node3D, places: Array, rels: Array) -> void:
	_build_bodies(holder, places, NODE_EDGE)
	for k in range(rels.size()):
		var e: Vector2i = rels[k]
		var a: Vector3 = (places[e.x] as Dictionary)["pos"]
		var b: Vector3 = (places[e.y] as Dictionary)["pos"]
		holder.add_child(_rod(a, b, ROD_RADIUS, AMBER, 0.45, "Rod%d" % k))


## The plate is the convex hull of every body's plan square, pushed out PLATE_MARGIN; the
## pads are the plan squares themselves, sitting on the plate in the body colour. A plan
## view: every body projects to the floor whether it touches it or not (the ramp's ten
## squares are the row's), and where projections overlap — the stack's upper courses lie
## over its bottom course — the later square is clipped against what is already drawn, so
## the stack's plan is four pads and nothing is drawn twice on one plane.
func _build_footprint(holder: Node3D, places: Array) -> void:
	var corners: PackedVector2Array = PackedVector2Array()
	var half: float = EDGE * 0.5
	var drawn: Array[PackedVector2Array] = []
	for i in range(places.size()):
		var p: Dictionary = places[i]
		var sq: PackedVector2Array = _floor_square(p["pos"], float(p["yaw"]), half)
		for j in range(sq.size()):
			corners.append(sq[j])
		var pieces: Array[PackedVector2Array] = [sq]
		for d in drawn:
			var kept: Array[PackedVector2Array] = []
			for piece in pieces:
				var cut: Array[PackedVector2Array] = Geometry2D.clip_polygons(piece, d)
				for c in cut:
					if c.size() >= 3:
						kept.append(c)
			pieces = kept
		for k in range(pieces.size()):
			holder.add_child(_prism(pieces[k], PLATE_THICK, PAD_THICK, BONE, "Pad%d_%d" % [i, k]))
		drawn.append(sq)
	var hull: PackedVector2Array = Geometry2D.convex_hull(corners)
	if hull.size() > 1 and hull[0].is_equal_approx(hull[hull.size() - 1]):
		hull.remove_at(hull.size() - 1)
	holder.add_child(_prism(_grow_convex(hull, PLATE_MARGIN), 0.0, PLATE_THICK, SLATE, "Plate"))


## A convex polygon pushed out by m on every edge — each vertex moved to where its two
## offset edges meet (the mitre, m (n1 + n2) / (1 + n1 . n2)). Orientation is normalised
## first so the outward side is known.
func _grow_convex(poly: PackedVector2Array, m: float) -> PackedVector2Array:
	var n: int = poly.size()
	if n < 3:
		return poly
	var area2: float = 0.0
	for i in range(n):
		var p0: Vector2 = poly[i]
		var p1: Vector2 = poly[(i + 1) % n]
		area2 += p0.x * p1.y - p1.x * p0.y
	var ccw: PackedVector2Array = PackedVector2Array()
	if area2 < 0.0:
		for i in range(n):
			ccw.append(poly[n - 1 - i])
	else:
		ccw = poly
	var out: PackedVector2Array = PackedVector2Array()
	for i in range(n):
		var prev: Vector2 = ccw[(i + n - 1) % n]
		var cur: Vector2 = ccw[i]
		var next: Vector2 = ccw[(i + 1) % n]
		var e0: Vector2 = cur - prev
		var e1: Vector2 = next - cur
		# Outward normal of a counter-clockwise edge is on its right-hand side.
		var n0: Vector2 = Vector2(e0.y, -e0.x).normalized()
		var n1: Vector2 = Vector2(e1.y, -e1.x).normalized()
		var denom: float = 1.0 + n0.dot(n1)
		if denom < 0.05:
			out.append(cur + n1 * m)
		else:
			out.append(cur + (n0 + n1) * (m / denom))
	return out


## The XZ square a body stands on, in the plate's (x, z) plane.
func _floor_square(centre: Vector3, yaw: float, half: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var offs: Array = [Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]
	for k in range(offs.size()):
		var o: Vector2 = offs[k]
		var rx: float = o.x * cos(yaw) + o.y * sin(yaw)
		var rz: float = -o.x * sin(yaw) + o.y * cos(yaw)
		out.append(Vector2(centre.x + rx, centre.z + rz))
	return out


# ── mesh helpers ────────────────────────────────────────────────────────────────────────

func _box(at: Vector3, size: Vector3, c: Color, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = at
	mi.material_override = _mat(c, 0.0)
	return mi


## A cylinder from a to b, its local Y laid along the segment. Built from a basis, not
## look_at, so it needs no tree.
func _rod(a: Vector3, b: Vector3, r: float, c: Color, emit: float, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = maxf(a.distance_to(b), 0.0001)
	cyl.radial_segments = 8
	cyl.rings = 0
	mi.mesh = cyl
	var y_axis: Vector3 = (b - a).normalized()
	if y_axis.length_squared() < 0.5:
		y_axis = Vector3.UP
	var helper: Vector3 = Vector3.UP if absf(y_axis.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var x_axis: Vector3 = helper.cross(y_axis).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()
	mi.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (a + b) * 0.5)
	mi.material_override = _mat(c, emit)
	return mi


## A simple polygon in the (x, z) plane extruded from y0 to y0 + h: top, bottom, sides.
## Top and bottom are triangulated (ear clipping, so a clipped L-shaped pad is fine);
## normals are set per face and culling is off, so the winding of the input does not
## matter for the picture, only for which way the side normals point.
func _prism(poly: PackedVector2Array, y0: float, h: float, c: Color, label: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = label
	var n: int = poly.size()
	if n < 3:
		return mi
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var y1: float = y0 + h
	var idx: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	if idx.size() < 3:
		# Degenerate input (collinear or self-touching): fall back to a fan.
		idx = PackedInt32Array()
		for i in range(1, n - 1):
			idx.append(0)
			idx.append(i)
			idx.append(i + 1)
	for t in range(0, idx.size() - 2, 3):
		var pa: Vector2 = poly[idx[t]]
		var pb: Vector2 = poly[idx[t + 1]]
		var pc: Vector2 = poly[idx[t + 2]]
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(pa.x, y1, pa.y))
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(pb.x, y1, pb.y))
		st.set_normal(Vector3.UP)
		st.add_vertex(Vector3(pc.x, y1, pc.y))
		st.set_normal(Vector3.DOWN)
		st.add_vertex(Vector3(pa.x, y0, pa.y))
		st.set_normal(Vector3.DOWN)
		st.add_vertex(Vector3(pc.x, y0, pc.y))
		st.set_normal(Vector3.DOWN)
		st.add_vertex(Vector3(pb.x, y0, pb.y))
	# Orientation, so the side normals face out: positive signed area = counter-clockwise
	# in the (x, z) frame, whose outward normal is the right-hand side of each edge.
	var area2: float = 0.0
	for i in range(n):
		var q0: Vector2 = poly[i]
		var q1: Vector2 = poly[(i + 1) % n]
		area2 += q0.x * q1.y - q1.x * q0.y
	var flip: float = -1.0 if area2 < 0.0 else 1.0
	for i in range(n):
		var p0: Vector2 = poly[i]
		var p1: Vector2 = poly[(i + 1) % n]
		var edge: Vector2 = p1 - p0
		var nrm2: Vector2 = Vector2(edge.y, -edge.x).normalized() * flip
		var nrm: Vector3 = Vector3(nrm2.x, 0.0, nrm2.y)
		var a0 := Vector3(p0.x, y0, p0.y)
		var a1 := Vector3(p1.x, y0, p1.y)
		var b0 := Vector3(p0.x, y1, p0.y)
		var b1 := Vector3(p1.x, y1, p1.y)
		var quad: Array = [a0, a1, b1, a0, b1, b0]
		for j in range(quad.size()):
			var v: Vector3 = quad[j]
			st.set_normal(nrm)
			st.add_vertex(v)
	mi.mesh = st.commit()
	mi.material_override = _mat(c, 0.0)
	return mi


func _mat(c: Color, emit: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if emit > 0.0:
		m.emission_enabled = true
		m.emission = Color(c.r, c.g, c.b)
		m.emission_energy_multiplier = emit
	return m
