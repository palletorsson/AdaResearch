extends Node3D
class_name AssemblyYard

## assembly_yard — an assembly puzzle's state is a DISTANCE from being itself, and one of
## the family's four words is not on the same dial as the other three.
##
## THE FAMILY. Seven artifacts, two axis names, one idea. `solid` on snap_cube_puzzle,
## snap_octahedron_puzzle, snap_tetra_puzzle and snap_tetrahedron_puzzle, all four declaring
## loose / closed / scattered / short — and they are TWO scenes under four names:
## snap_tetra_puzzle's registry entry points at snap_tetrahedron_puzzle.tscn and
## snap_cube_puzzle's at snap_octahedron_puzzle.tscn. There has never been a cube in that
## family; the cube is the octahedron's `dual`, drawn only when a second axis is asked for
## it. `stock` on cross_line_puzzle and plus_line_puzzle (stacked / crossed / scattered) and
## on triangle_line_puzzle (racked / strewn / ringed): the same question — how much of the
## order is pre-given before you touch it — asked of LINES instead of POINTS. pick_up_cube
## also declares `stock` (wire / foam / crate / steel / clay), but that is what the cube is
## MADE OF, a material axis with the family's word on it, so it is left out.
##
## THE ARGUMENT. Read each value as how far the parts stand from the solid they make:
##
##   closed     distance zero          — every part on its place, every edge built
##   loose      a snap away            — the parts hover within snap range (0.12 m in
##                                       snap_point.tscn), the solid implied and not made
##   scattered  far, and complete      — every part present, thrown to unrelated
##                                       directions; the same objects implying nothing
##   short      near, and INCOMPLETE   — the parts that exist stand exactly on their
##                                       places, and one vertex is not there at all
##
## The first three are one dial. `short` is not on it: it is CLOSER than loose on the
## placement dial (its vertices are exact) and further than scattered on a second dial the
## word list never names — whether the parts add up to the solid at all. Both snap sources
## know this; each says `short` is "the value that earns the axis". What neither does is
## stand it next to `scattered` so the two distances can be read against each other:
## scattered can still close, short never can.
##
## THE BODY, NOT A GAUGE. One solid, built of the family's own parts — amber snap points
## and cyan struts, edge 0.28 m as both snap sources use — at whichever state is asked for.
## The struts are PARTS in every state (the line family's ontology) and the vertices are
## PARTS in every state (the snap family's), so a viewer can count them: four, six or eight
## amber points; six or twelve cyan struts. In `short` the count comes up one point short and
## the three or four edges that needed it are dashed ghosts stopping in air, exactly as both
## snap sources draw them. In `scattered` the count is full. That is the whole claim, in
## parts.

## How far the parts stand from the solid. The four values and their order are the snap
## family's own — snap_tetrahedron_puzzle.gd:45 and snap_octahedron_puzzle.gd:50 both
## declare the axis they call `solid` with these four words, default loose. (Not quoted
## verbatim here on purpose: check_dna_declarations reads the FIRST enum line that precedes
## a `var <axis>`, comments included, and a quoted source line derived the wrong axis.)
##   loose      — vertices pulled in to 0.70 of their radius, as both snap scenes ship them
##                (tetra base ring 0.11 m against 0.16 built; octa equator 0.14 against 0.20),
##                struts parked just outside the edge each belongs to, parallel to it, the way
##                triangle_line_puzzle's `ringed` parks its lines. Nothing needs finding.
##   closed     — vertices exact, every edge a built strut. snap_octahedron_puzzle: "standing
##                AS the answer".
##   scattered  — vertices at twice the loose radius in unrelated directions, struts at
##                unrelated angles and depths: the octahedron's `scattered`, the line
##                puzzles' `scattered`, the triangle's `strewn`. Fixed tables, no randf.
##   short      — the last vertex is not built. Every strut that has both ends is built
##                solid; every strut that needed the absent vertex is a dashed ghost stub
##                that stops in air 0.55 of the way there (the octahedron's GHOST_STUB).
@export_enum("loose", "closed", "scattered", "short") var state: String = "loose":
	set(v):
		state = v
		if is_inside_tree():
			_rebuild()

## Which solid is being assembled. tetra and octa are the two scenes the four snap names
## resolve to; cube is what snap_cube_puzzle is NAMED for and has never built — it exists
## in the family only as the octahedron's `dual`. Same edge for all three, so the parts are
## interchangeable stock and the same state has to read the same across solids.
##   tetra — 4 points, 6 struts. The minimal solid; `short` is the three-point case that
##           cannot enclose, which is the truth line snap_tetrahedron_puzzle claims.
##   octa  — 6 points, 12 struts. `short` loses the apex and its four edges.
##   cube  — 8 points, 12 struts. `short` loses the top-front-right corner and three edges.
@export_enum("tetra", "octa", "cube") var solid: String = "tetra":
	set(v):
		solid = v
		if is_inside_tree():
			_rebuild()

## Whether the four states stand together or one at a time. NOT PART OF THE AXES: with an
## all-rungs value inside the axis the sweep unions the AABB across variants and photographs
## every single state as a speck against the row. dna.fixture pins this to `single` for the
## sweep. By default the artifact stands as the whole comparison — closed, loose, scattered
## in a row at one spacing, and `short` set apart by an extra half-spacing and stepped back,
## because it is not the next rung of that row.
@export_enum("ladder", "single") var layout: String = "ladder":
	set(v):
		layout = v
		if is_inside_tree():
			_rebuild()

## Strut length. 0.28 m is snap_tetrahedron_puzzle's CLOSED_EDGE and, to a millimetre, the
## octahedron's 0.20 * sqrt(2). Every solid here is built of this one part.
@export var edge: float = 0.28
@export var spacing: float = 1.0

## Height of the solid's centre. Both snap scenes centre their puzzle volume at hand height
## (0.68 and 0.70); a little lower keeps the scattered ball's lowest part above the floor.
const CENTRE_Y: float = 0.60

## snap_point.tscn: snap_distance = 0.12. Every displacement in `loose` is under this.
const SNAP: float = 0.12
## Both snap scenes ship their points at about 0.7 of the built radius (tetra 0.11/0.16,
## octa 0.141/0.20). That is what "near the answer, not on it" measures.
const LOOSE_SHRINK: float = 0.70
## triangle_line_puzzle.RING_OFFSET is 0.14 on a 0.40 m triangle; scaled to a 0.28 m edge.
const RING_OFF: float = 0.10
## Fraction of a ghost edge drawn from its present end. snap_octahedron_puzzle.GHOST_STUB.
## (The tetrahedron sibling stops its risers at 0.87; the shorter stub is taken because that
## source argues its number — "the gap reads as a hole in the figure rather than as a short
## edge" — and the argument here is a hole.)
const GHOST_STUB: float = 0.55
## Gauges. snap_tetrahedron_puzzle: STRUT_RADIUS 0.012, GHOST_RADIUS 0.006. (The octahedron
## writes the same digits as DIAMETERS, so the two siblings differ by 2x under one number;
## the thicker reading is taken because the evidence is a still.)
const STRUT_R: float = 0.012
const GHOST_R: float = 0.006
const DASH_PERIOD: float = 0.046
## snap_point.tscn: the point's Sphere radius = 0.018.
const POINT_R: float = 0.018

## The octahedron's snap-point amber and the tetrahedron's built-strut cyan: the two kinds of
## part wear the colours the two sources gave them.
const AMBER: Color = Color(1.0, 0.8, 0.3)
const CYAN: Color = Color(0.3, 1.0, 0.8)

## `scattered` vertex offsets from the centre: magnitudes 0.36-0.43, which is twice the loose
## radius band (0.12-0.17) — the octahedron's own rule, "twice the shipped radius". No two
## share an axis, none is axis-aligned. The tetra uses the first four, the octa the first
## six, the cube all eight, so a shared part lands in the same place in every solid.
const SCATTER_VERTS: Array = [
	Vector3(0.30, -0.10, 0.18),
	Vector3(-0.24, 0.20, 0.26),
	Vector3(0.16, 0.32, -0.22),
	Vector3(-0.32, -0.18, -0.12),
	Vector3(0.20, 0.12, -0.34),
	Vector3(-0.12, -0.30, 0.28),
	Vector3(0.26, -0.26, -0.18),
	Vector3(-0.18, 0.34, -0.06),
]

## `scattered` strut poses: [centre offset, direction]. Centres within 0.31 m, so no strut
## end passes 0.45 m from the centre; the whole scattered state fits a 0.9 m ball. Checked
## offline: no strut passes within 0.06 m of a vertex or 0.05 m of another strut.
const SCATTER_STRUTS: Array = [
	[Vector3(0.06, -0.26, 0.02), Vector3(0.8, 0.3, -0.5)],
	[Vector3(-0.22, -0.06, 0.14), Vector3(0.2, 0.9, 0.4)],
	[Vector3(0.20, 0.22, 0.10), Vector3(-0.6, 0.4, 0.7)],
	[Vector3(-0.06, 0.28, -0.16), Vector3(0.9, -0.2, 0.4)],
	[Vector3(0.26, -0.02, -0.14), Vector3(0.3, 0.7, 0.65)],
	[Vector3(-0.16, -0.24, -0.20), Vector3(-0.5, 0.6, -0.6)],
	[Vector3(0.04, 0.06, 0.28), Vector3(0.7, -0.5, 0.5)],
	[Vector3(-0.28, 0.14, -0.04), Vector3(0.4, 0.5, -0.75)],
	[Vector3(0.12, -0.16, -0.26), Vector3(-0.8, 0.5, 0.3)],
	[Vector3(-0.10, -0.22, 0.20), Vector3(0.75, 0.1, 0.65)],
	[Vector3(0.16, 0.26, -0.02), Vector3(-0.35, -0.7, 0.6)],
	[Vector3(-0.20, 0.0, -0.24), Vector3(0.5, 0.85, 0.15)],
]

const STATES: Array = ["closed", "loose", "scattered", "short"]

var _built: Array[Node3D] = []


func _ready() -> void:
	_rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("layout"):
		layout = str(config_data["layout"])
	if config_data.has("state"):
		state = str(config_data["state"])
	if config_data.has("solid"):
		solid = str(config_data["solid"])
	if config_data.has("edge"):
		edge = float(config_data["edge"])
	if config_data.has("spacing"):
		spacing = float(config_data["spacing"])
	_rebuild()


func _rebuild() -> void:
	for n in _built:
		if is_instance_valid(n):
			n.queue_free()
	_built.clear()
	if layout == "ladder":
		# closed, loose, scattered: one dial, one spacing. short: set apart by an extra
		# half-spacing and stepped back half a spacing — near on the placement dial, and
		# not on that dial at all.
		var xs: Array = [-1.5 * spacing, -0.5 * spacing, 0.5 * spacing, 2.0 * spacing]
		var zs: Array = [0.0, 0.0, 0.0, -0.5 * spacing]
		for i in range(STATES.size()):
			_build_yard(str(STATES[i]), Vector3(float(xs[i]), CENTRE_Y, float(zs[i])))
	else:
		_build_yard(state, Vector3(0.0, CENTRE_Y, 0.0))


## One solid, in one state, centred at `at`.
func _build_yard(st: String, at: Vector3) -> void:
	var holder := Node3D.new()
	holder.name = "%s_%s" % [solid, st]
	holder.position = at
	add_child(holder)
	_built.append(holder)

	var verts: Array[Vector3] = _vertices(solid)
	var edges: Array = _edges(verts)
	var n: int = verts.size()
	var absent: int = n - 1

	match st:
		"closed":
			for i in range(n):
				_point(holder, verts[i])
			for e in edges:
				var ia: int = e[0]
				var ib: int = e[1]
				_strut(holder, verts[ia], verts[ib], STRUT_R, _strut_mat(false))
		"scattered":
			for i in range(n):
				_point(holder, SCATTER_VERTS[i % SCATTER_VERTS.size()])
			for j in range(edges.size()):
				var pose: Array = SCATTER_STRUTS[j % SCATTER_STRUTS.size()]
				var c: Vector3 = pose[0]
				var d: Vector3 = (pose[1] as Vector3).normalized()
				_strut(holder, c - d * edge * 0.5, c + d * edge * 0.5, STRUT_R, _strut_mat(false))
		"short":
			for i in range(n):
				if i == absent:
					continue
				_point(holder, verts[i])
			for e in edges:
				var ia: int = e[0]
				var ib: int = e[1]
				if ia == absent or ib == absent:
					# The stub runs from the present end toward the vertex that is not
					# there, and stops in air. Both snap sources draw exactly this.
					var here: Vector3 = verts[ib] if ia == absent else verts[ia]
					var gone: Vector3 = verts[ia] if ia == absent else verts[ib]
					_dashed(holder, here, here + (gone - here) * GHOST_STUB, GHOST_R, _strut_mat(true))
				else:
					_strut(holder, verts[ia], verts[ib], STRUT_R, _strut_mat(false))
		_:
			# loose — points pulled in to 0.70 of their radius, struts parked just outside
			# the edge each belongs to. Every displacement is under one snap (0.12 m).
			for i in range(n):
				_point(holder, verts[i] * LOOSE_SHRINK)
			for e in edges:
				var ia: int = e[0]
				var ib: int = e[1]
				var a: Vector3 = verts[ia]
				var b: Vector3 = verts[ib]
				var mid: Vector3 = (a + b) * 0.5
				var out: Vector3 = mid.normalized()
				var dir: Vector3 = (b - a).normalized()
				var c: Vector3 = mid + out * RING_OFF
				_strut(holder, c - dir * edge * 0.5, c + dir * edge * 0.5, STRUT_R, _strut_mat(false))


# ═══════════════════════════════════════════════════════════════════
# SOLIDS — vertices about the origin, every edge = `edge`, absent vertex LAST
# ═══════════════════════════════════════════════════════════════════

func _vertices(kind: String) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if kind == "octa":
		# snap_octahedron_puzzle: vertices at ±R on each axis, R = edge / sqrt(2). Its
		# CLOSED_ORDER puts the equator first and the poles last; the apex is ABSENT_VERTEX.
		var r: float = edge / sqrt(2.0)
		out.append(Vector3(-r, 0.0, 0.0))
		out.append(Vector3(0.0, 0.0, -r))
		out.append(Vector3(0.0, 0.0, r))
		out.append(Vector3(r, 0.0, 0.0))
		out.append(Vector3(0.0, -r, 0.0))
		out.append(Vector3(0.0, r, 0.0))
		return out
	if kind == "cube":
		# The corner table snap_octahedron_puzzle uses for its dual cube (CUBE_SIGNS), which
		# happens to list (+,+,+) last — the top-front-right corner is the one `short` loses.
		var h: float = edge * 0.5
		out.append(Vector3(-h, -h, -h))
		out.append(Vector3(-h, -h, h))
		out.append(Vector3(-h, h, -h))
		out.append(Vector3(-h, h, h))
		out.append(Vector3(h, -h, -h))
		out.append(Vector3(h, -h, h))
		out.append(Vector3(h, h, -h))
		out.append(Vector3(h, h, h))
		return out
	# tetra — snap_tetrahedron_puzzle._closed_vertices, re-centred on the origin:
	# Base1 (-x), Base2 (+x), Base3 (+z), Apex.
	var a: float = edge
	var circum: float = a / sqrt(3.0)
	var height: float = a * sqrt(2.0 / 3.0)
	var y_base: float = -height * 0.25
	var y_apex: float = height * 0.75
	var half: float = a * 0.5
	var back: float = circum * 0.5
	out.append(Vector3(-half, y_base, -back))
	out.append(Vector3(half, y_base, -back))
	out.append(Vector3(0.0, y_base, circum))
	out.append(Vector3(0.0, y_apex, 0.0))
	return out


## Every pair of vertices at edge distance — derived, so the edge list cannot drift from
## the vertex list (the octahedron's antipodal pairs and the cube's diagonals fall out).
func _edges(verts: Array[Vector3]) -> Array:
	var out: Array = []
	for i in range(verts.size()):
		for j in range(i + 1, verts.size()):
			if absf(verts[i].distance_to(verts[j]) - edge) < 0.001:
				out.append([i, j])
	return out


# ═══════════════════════════════════════════════════════════════════
# PARTS
# ═══════════════════════════════════════════════════════════════════

func _point(holder: Node3D, at: Vector3) -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Point"
	var sph := SphereMesh.new()
	sph.radius = POINT_R
	sph.height = POINT_R * 2.0
	sph.radial_segments = 12
	sph.rings = 6
	mi.mesh = sph
	mi.material_override = _point_mat()
	mi.position = at
	holder.add_child(mi)


func _strut(holder: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> void:
	var length: float = a.distance_to(b)
	if length < 0.0005:
		return
	var cyl := CylinderMesh.new()
	cyl.top_radius = r
	cyl.bottom_radius = r
	cyl.height = length
	cyl.radial_segments = 8
	cyl.rings = 1
	var mi := MeshInstance3D.new()
	mi.name = "Strut"
	mi.mesh = cyl
	mi.material_override = mat
	# Cylinders point along +Y; build a basis whose Y is the strut direction.
	var y_axis: Vector3 = (b - a) / length
	var ref: Vector3 = Vector3.RIGHT
	if absf(y_axis.dot(ref)) > 0.9:
		ref = Vector3.FORWARD
	var x_axis: Vector3 = ref.cross(y_axis).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()
	mi.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (a + b) * 0.5)
	holder.add_child(mi)


## A ghost edge is a run of short cylinders, dash and gap equal, fitted to the exact length
## so it ends on a dash — snap_octahedron_puzzle._add_dashed_strut.
func _dashed(holder: Node3D, a: Vector3, b: Vector3, r: float, mat: StandardMaterial3D) -> void:
	var length: float = a.distance_to(b)
	if length < 0.0005:
		return
	var dashes: int = int(maxf(3.0, floorf(length / DASH_PERIOD)))
	var unit: float = length / float(dashes * 2 - 1)
	var dir: Vector3 = (b - a) / length
	for k in range(dashes):
		var t0: float = float(k) * 2.0 * unit
		_strut(holder, a + dir * t0, a + dir * (t0 + unit), r, mat)


func _point_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = AMBER
	m.metallic = 0.3
	m.roughness = 0.3
	m.emission_enabled = true
	m.emission = AMBER
	m.emission_energy_multiplier = 1.5
	return m


func _strut_mat(ghost: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.metallic = 0.4
	m.roughness = 0.3
	m.emission_enabled = true
	m.emission = CYAN
	if ghost:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(CYAN.r, CYAN.g, CYAN.b, 0.35)
		m.emission_energy_multiplier = 0.8
	else:
		m.albedo_color = CYAN
		m.emission_energy_multiplier = 1.2
	return m
