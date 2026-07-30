extends SnapPointPuzzleBase
class_name SnapOctahedronPuzzle

# @identity
# essence: octahedron = 6 vertices, 12 edges, 8 faces — dual of the cube, all faces equilateral triangles
# desire: learner places 6 floating points and discovers the shape that emerges from this particular arrangement
# critical_parameter: 6 snap target positions — form a regular octahedron at ±1 on each axis
# triggers: snapping all 6 snap points to their targets → puzzle complete signal fires
# emerges: the dual relationship to the cube — realizing these 6 positions are the face-centers of a cube
# needs: the cube this thing is the dual OF, visible rather than asserted [has, 2026-07-29 — the `dual` axis]. Missing: VR controls besides snapping — no label or slider.
# relationships: extends SnapPointPuzzleBase; sibling to snap_tetrahedron_puzzle; grab_octahedron is its held version
# truth: the octahedron is the cube's dual — swap faces and vertices and you get the other

## Snap Octahedron Puzzle Controller
## Manages a 6-point octahedron puzzle
## Extends SnapPointPuzzleBase for common functionality and tag system

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — axis `solid`
# ═══════════════════════════════════════════════════════════════════
#
# Every position in this puzzle used to be frozen in snap_octahedron_puzzle.tscn:
# the artifact carrying the sequence's F term shipped in exactly one arrangement —
# six points hovering NEAR, but not on, the answer. The two states its own @identity
# talks about, the solved octahedron and the dual relation to the cube, existed only
# as a transient side-effect of a player finishing it, and were gone a second later.
#
# `solid` is the knob that arrangement hides: HOW MUCH OF THE ORDER IS PRE-GIVEN.
#
#   loose      the shipped look — near the answer, not on it
#   closed     standing AS the answer: six vertices, twelve struts, the solid built
#   scattered  the same six objects implying no shape at all
#   short      five vertices built and one absent — an outline that cannot close
#
# `short` is the value that earns the axis. F is order in QFE = F - λE(S) + φΔE, and
# this puzzle is one of only two objects in the sequence where order is something a
# body assembles rather than something a meter reports. A figure with one vertex
# missing is a form that CANNOT be closed — the foundations-crisis argument arriving
# in the laboratory as a physical object rather than a proof.
#
# The axis name and its four values are shared verbatim with snap_tetrahedron_puzzle:
# siblings with one geometry problem at two counts. Per the last wave's ruling on
# `support`, reuse the word, do not invent a second one for the same question.

## How much of the solid the six points already give away.
## loose = the shipped transforms (near the answer). closed = standing as the answer,
## vertices exact and the twelve edges built. scattered = six unrelated directions,
## no shape implied. short = five vertices built and the sixth absent, the ghost
## outline left open by 0.40 m at the vertex that never arrives.
@export_enum("loose", "closed", "scattered", "short") var solid: String = "loose"

const SOLIDS: PackedStringArray = ["loose", "closed", "scattered", "short"]

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — axis `dual` (promoted 2026-07-29)
# ═══════════════════════════════════════════════════════════════════
#
# This artifact's own truth statement is "the octahedron is the cube's dual — swap
# faces and vertices and you get the other", and its `emerges` line promises the
# learner will realise "these 6 positions are the face-centers of a cube". No cube
# has ever been in the scene. The claim was carried entirely by the label and by
# whatever the player already knew; the object asserted a relation it never showed.
# Same failure the sibling `apex` promotion fixed: a truth frozen out of reach.
#
# `dual` is the knob that assertion hides: WHICH SIDE OF THE DUALITY IS DRAWN.
#
#   off     the shipped look — duality asserted, never shown
#   around  the cube whose six FACE CENTRES are the octahedron's vertices
#   inside  the cube whose eight VERTICES are the octahedron's face centres
#   both    both cubes at once — the duality does not terminate, it nests
#
# `both` is the value that earns the axis. Taught once, duality reads as a pair of
# solids swapping roles. Drawn twice at two scales around one octahedron it stops
# being a pair and becomes a LADDER: every dual has a dual, and the reciprocal that
# looked like an identity is a step. That is a different argument from `around`,
# and it is the argument the sequence actually wants.
#
# Orthogonal to `solid` on purpose. The cube is the ideal frame, so it can stand
# around a scattered arrangement (the answer's frame with no answer in it) or around
# the `short` outline (the dual survives a vertex the figure has lost).

## Which side of the octahedron-cube duality is actually drawn.
## off = the shipped scene, nothing added. around = the circumscribing cube whose six
## face centres are the six vertices. inside = the inscribed cube whose eight corners
## are the octahedron's eight face centres. both = both, showing duality nests.
@export_enum("off", "around", "inside", "both") var dual: String = "off"

const DUALS: PackedStringArray = ["off", "around", "inside", "both"]

# ── Geometry ───────────────────────────────────────────────────────
## Centre of the puzzle volume in local space — the .tscn's boundary sphere origin.
const CENTRE: Vector3 = Vector3(0.0, 0.70, 0.0)

## Circumradius of the built octahedron. Vertices land on ±0.20 on each axis about
## CENTRE, which makes each of the twelve edges 0.20 * sqrt(2) = 0.283 m.
const SOLID_R: float = 0.20

## Boundary sphere DIAMETERS. Shipped is 0.80 (SphereMesh radius 0.4 in the .tscn);
## `closed` and `short` reach ±0.20 plus strut and point radius, `scattered` reaches
## ~0.49 from centre. Sized so the translucent shell still contains its contents and
## the whole artifact stays inside its measured one-cell footprint.
const BOUNDARY_LOOSE: float = 0.80
const BOUNDARY_CLOSED: float = 0.90
const BOUNDARY_SCATTERED: float = 1.10

## Strut gauge. 0.012 m solid for `closed`, 0.006 m dashed ghost for `short`
## (stated as diameters — halved into cylinder radii at build time).
const STRUT_D: float = 0.012
const GHOST_D: float = 0.006
const DASH_PERIOD: float = 0.046

## Fraction of a ghost edge that is actually drawn when it runs at the ABSENT vertex.
## 0.55 leaves each of those struts ending in air well clear of the apex, so the gap
## reads as a hole in the figure rather than as a short edge.
const GHOST_STUB: float = 0.55

## The puzzle's amber — the same colour _apply_puzzle_materials gives the points, so
## the built edges read as belonging to the points rather than as scaffolding.
const AMBER: Color = Color(1.0, 0.8, 0.3, 1.0)

## The dual cube's cyan — the boundary sphere's own colour, so the cube reads as part
## of the frame around the puzzle rather than as more of the puzzle's amber structure.
const CYAN: Color = Color(0.3, 0.8, 1.0, 1.0)

## Circumscribing cube: half-side equals the octahedron's circumradius, which is exactly
## what puts each of the six vertices at the centre of one cube face. Corners land
## 0.20 * sqrt(3) = 0.346 m from CENTRE, inside the 0.40 m shipped boundary radius, so
## `around` needs no boundary resize and the measured footprint does not move.
const DUAL_HALF: float = SOLID_R

## Inscribed cube: an octahedron face centre is (R, 0, 0), (0, R, 0), (0, 0, R) averaged,
## i.e. R/3 on each axis — so the eight face centres are the corners of a cube of
## half-side R/3. The other direction of the same reciprocity.
const INNER_HALF: float = SOLID_R / 3.0

## Dual struts are thinner than the solid's own 0.012 m edges: the cube is the relation,
## not the figure, and must not out-weigh what it is a relation to.
const DUAL_D: float = 0.008
const INNER_D: float = 0.005

## Corner signs, as a table rather than nested sign loops — an untyped loop variable
## multiplied into a Vector3 is the compile trap this codebase keeps hitting.
const CUBE_SIGNS: Array = [
	Vector3(-1.0, -1.0, -1.0), Vector3(-1.0, -1.0, 1.0),
	Vector3(-1.0, 1.0, -1.0), Vector3(-1.0, 1.0, 1.0),
	Vector3(1.0, -1.0, -1.0), Vector3(1.0, -1.0, 1.0),
	Vector3(1.0, 1.0, -1.0), Vector3(1.0, 1.0, 1.0),
]

## Where each snap point goes when the solid is built, as an offset from CENTRE.
## The four equatorial points rotate 45° onto the four horizontal axis vertices —
## each keeps the side of the volume it shipped on. Poles just move out to ±0.20.
const CLOSED_TARGETS: Dictionary = {
	"PointEquatorialBackLeft": Vector3(-0.20, 0.0, 0.0),
	"PointEquatorialBackRight": Vector3(0.0, 0.0, -0.20),
	"PointEquatorialFrontLeft": Vector3(0.0, 0.0, 0.20),
	"PointEquatorialFrontRight": Vector3(0.20, 0.0, 0.0),
	"PointPolarTop": Vector3(0.0, 0.20, 0.0),
	"PointPolarBottom": Vector3(0.0, -0.20, 0.0),
}

## Fallback in scene-child order, for an instance whose points were renamed.
const CLOSED_ORDER: Array = [
	Vector3(-0.20, 0.0, 0.0),
	Vector3(0.0, 0.0, -0.20),
	Vector3(0.0, 0.0, 0.20),
	Vector3(0.20, 0.0, 0.0),
	Vector3(0.0, 0.20, 0.0),
	Vector3(0.0, -0.20, 0.0),
]

## The vertex `short` does NOT build. The apex: its four neighbours ring a 0.40 m
## aperture (the diagonal of the 0.283 m square they form), and an outline open at
## the top is legible from every camera the harness uses.
const ABSENT_VERTEX: Vector3 = Vector3(0.0, 0.20, 0.0)

## Six unrelated directions for `scattered` — twice the shipped radius, none of them
## axis-aligned and no two sharing an axis, so the same six objects imply nothing.
## Hand-fixed constants, not randf: the still has to be reproducible.
const SCATTER_OFFSETS: Array = [
	Vector3(0.34, -0.12, 0.20),
	Vector3(-0.28, 0.22, 0.30),
	Vector3(0.18, 0.36, -0.26),
	Vector3(-0.36, -0.20, -0.14),
	Vector3(0.24, 0.14, -0.40),
	Vector3(-0.14, -0.34, 0.32),
]

# ── Label placement ────────────────────────────────────────────────
## PRE-EMPTIVE. success_label is latent (show_success_message defaults false), but the
## base class parks it at global_position + (0, 0.30, 0) — dead centre of the six snap
## points, which live between y 0.50 and 0.90 inside the boundary sphere. Once the
## framer turns that Label3D into an opaque plate (~1.25 x 0.23 m at font 32) it covers
## the ENTIRE puzzle at the exact moment the player has just solved it. 1.45 clears the
## boundary sphere top (1.10 shipped, 1.25 scattered) and the logic display by 0.35 m.
## The base class re-asserts 0.30 inside _complete_puzzle, so this is enforced per frame
## rather than set once — see _process.
const SUCCESS_LABEL_Y: float = 1.45

# ── Runtime state ──────────────────────────────────────────────────
var _built: bool = false
var _dna_nodes: Array[Node3D] = []
var _dna_materials: Array[StandardMaterial3D] = []
var _puzzle_material: StandardMaterial3D
var _emissive_on: bool = true

var _shipped_xforms: Dictionary = {}
var _shipped_layers: Dictionary = {}
var _shipped_masks: Dictionary = {}
var _shipped_captured: bool = false
var _boundary_mesh_owned: bool = false
var _reset_timer_shipped: bool = true


func _ready() -> void:
	solid = _pick_axis(solid, SOLIDS, "loose")
	dual = _pick_axis(dual, DUALS, "off")
	_reset_timer_shipped = enable_reset_timer

	# A non-default arrangement must survive the 60 s reset. _store_initial_positions
	# snapshots the SHIPPED transforms in super._ready(), so leaving the timer on would
	# quietly undo `closed`, `scattered` and `short` one minute into a walked map.
	# Killing it before super._ready() also stops the ResetTimerBar being created at all.
	if solid != "loose":
		enable_reset_timer = false

	# Apply transparent emissive material to snap points
	_apply_puzzle_materials()

	# Call parent ready — this is what runs _find_snap_points and fills snap_points,
	# so the axis build below MUST come after it.
	super._ready()

	_build_all()
	_built = true

	_place_success_label()


func _process(delta: float) -> void:
	super._process(delta)
	# _complete_puzzle sets success_label.global_position to +0.30 m at show time, which
	# would drop a framed opaque plate straight onto the six points. Re-assert the
	# clearing height every frame it is visible — cheap, and it cannot lose a race.
	if success_label != null and success_label.visible:
		success_label.global_position = global_position + Vector3(0.0, SUCCESS_LABEL_Y, 0.0)


func _connect_signals() -> void:
	# Connect to octahedron formation signal
	if connection_manager:
		if not connection_manager.octahedron_formed.is_connected(_on_octahedron_formed):
			connection_manager.octahedron_formed.connect(_on_octahedron_formed)
		print("SnapOctahedronPuzzle: Connected to octahedron_formed signal")

func _on_octahedron_formed(points: Array) -> void:
	# Check if this octahedron uses our snap points
	var our_points_count = 0
	for point in points:
		if point in snap_points:
			our_points_count += 1

	# If all 6 points are ours, this is our octahedron!
	if our_points_count == 6:
		print("SnapOctahedronPuzzle: Octahedron completed with our points!")
		_complete_puzzle()  # Call base class completion method

func _apply_puzzle_materials() -> void:
	# Wait for snap points to be found
	await get_tree().process_frame

	# Create transparent emissive material
	var puzzle_material = StandardMaterial3D.new()
	puzzle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puzzle_material.albedo_color = Color(1.0, 0.8, 0.3, 0.6)  # Orange-ish with 60% opacity
	puzzle_material.metallic = 0.5
	puzzle_material.roughness = 0.3
	puzzle_material.emission_enabled = _emissive_on
	puzzle_material.emission = Color(1.0, 0.8, 0.3, 1.0)
	puzzle_material.emission_energy_multiplier = 2.0
	_puzzle_material = puzzle_material

	# Apply to all snap points
	for point in snap_points:
		if not point:
			continue

		# Find the MeshInstance3D child
		var mesh_instance = point.get_node_or_null("MeshInstance3D")
		if mesh_instance and mesh_instance is MeshInstance3D:
			# Apply material to the mesh instance
			mesh_instance.material_override = puzzle_material
			print("SnapOctahedronPuzzle: Applied transparent material to ", point.name)


# ═══════════════════════════════════════════════════════════════════
# BUILD — one branch per axis value, all synchronous
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	_capture_shipped()
	match solid:
		"closed":
			_build_closed()
		"scattered":
			_build_scattered()
		"short":
			_build_short()
		_:
			_build_loose()
	_build_dual()


## loose — the pre-promotion look, untouched. The six points stay on the transforms
## the .tscn gives them (four at ±0.10 on x and z at y 0.70, poles at 0.90 and 0.50),
## the boundary sphere stays at 0.80 m, and nothing is added. Deliberately not even a
## redundant boundary write, so the default renders byte-identically to the ship.
func _build_loose() -> void:
	pass


## closed — the answer, standing. The six points move onto their exact regular-
## octahedron vertices and the twelve 0.283 m edges are drawn as solid amber struts,
## so the solid is built rather than implied.
func _build_closed() -> void:
	_seat_points_on_vertices(Vector3.INF)
	_set_boundary_diameter(BOUNDARY_CLOSED)

	var mat: StandardMaterial3D = _make_strut_material(false)
	for edge in _octahedron_edges():
		var v0: Vector3 = edge[0]
		var v1: Vector3 = edge[1]
		_add_strut(CENTRE + v0, CENTRE + v1, STRUT_D * 0.5, mat)


## scattered — the same six objects, no shape. Each point is pushed to twice its
## shipped radius along a direction shared with no other point and aligned to no axis.
func _build_scattered() -> void:
	_set_boundary_diameter(BOUNDARY_SCATTERED)
	for i in range(snap_points.size()):
		var p: Node3D = snap_points[i]
		if not is_instance_valid(p):
			continue
		var off: Vector3 = SCATTER_OFFSETS[i % SCATTER_OFFSETS.size()]
		p.position = CENTRE + off


## short — five of six. The built points sit on their vertices, the sixth is not there
## at all, and the whole twelve-edge outline is drawn as thin dashed ghost struts. The
## edges that run at the absent vertex stop in air, leaving the 0.40 m aperture its
## four neighbours ring — the figure this puzzle can no longer close.
func _build_short() -> void:
	_seat_points_on_vertices(ABSENT_VERTEX)
	_set_boundary_diameter(BOUNDARY_CLOSED)

	var mat: StandardMaterial3D = _make_strut_material(true)
	for edge in _octahedron_edges():
		var v0: Vector3 = edge[0]
		var v1: Vector3 = edge[1]
		var a: Vector3 = CENTRE + v0
		var b: Vector3 = CENTRE + v1
		if v1.is_equal_approx(ABSENT_VERTEX):
			b = a + (b - a) * GHOST_STUB
		elif v0.is_equal_approx(ABSENT_VERTEX):
			a = b + (a - b) * GHOST_STUB
		_add_dashed_strut(a, b, GHOST_D * 0.5, mat)


## Move every point onto its octahedron vertex. A point whose vertex equals `skip`
## is not built at all — hidden and taken out of the collision world, so `short` is
## genuinely five points rather than five points and a ghost you can still grab.
func _seat_points_on_vertices(skip: Vector3) -> void:
	for i in range(snap_points.size()):
		var p: Node3D = snap_points[i]
		if not is_instance_valid(p):
			continue
		var v: Vector3 = _vertex_for(p, i)
		if skip != Vector3.INF and v.is_equal_approx(skip):
			_set_point_present(p, false)
			continue
		p.position = CENTRE + v


func _vertex_for(point: Node3D, index: int) -> Vector3:
	if CLOSED_TARGETS.has(point.name):
		var named: Vector3 = CLOSED_TARGETS[point.name]
		return named
	var ordered: Vector3 = CLOSED_ORDER[index % CLOSED_ORDER.size()]
	return ordered


## The twelve edges as vertex-offset pairs: every pair of vertices except the three
## antipodal ones. Derived, not typed out, so the pair list cannot drift from the
## vertex list.
func _octahedron_edges() -> Array:
	var verts: Array = [
		Vector3(SOLID_R, 0.0, 0.0), Vector3(-SOLID_R, 0.0, 0.0),
		Vector3(0.0, SOLID_R, 0.0), Vector3(0.0, -SOLID_R, 0.0),
		Vector3(0.0, 0.0, SOLID_R), Vector3(0.0, 0.0, -SOLID_R),
	]
	var edges: Array = []
	for i in range(verts.size()):
		for j in range(i + 1, verts.size()):
			var a: Vector3 = verts[i]
			var b: Vector3 = verts[j]
			if (a + b).length() < 0.0001:
				continue  # antipodal — not an edge
			edges.append([a, b])
	return edges


# ═══════════════════════════════════════════════════════════════════
# DUAL — the cube the six points have always been about
# ═══════════════════════════════════════════════════════════════════

## Builds nothing at all on the default, so an `off` placement takes exactly the code
## path it took before this axis existed.
func _build_dual() -> void:
	if dual == "off":
		return
	if dual == "around" or dual == "both":
		_add_cube(DUAL_HALF, DUAL_D * 0.5, _make_dual_material())
	if dual == "inside" or dual == "both":
		_add_cube(INNER_HALF, INNER_D * 0.5, _make_dual_material())


func _add_cube(half: float, radius: float, mat: StandardMaterial3D) -> void:
	for edge in _cube_edges(half):
		var a: Vector3 = edge[0]
		var b: Vector3 = edge[1]
		_add_strut(CENTRE + a, CENTRE + b, radius, mat)


## The twelve edges as corner pairs: two corners are joined exactly when they differ on
## one axis, which is when their distance is the full side length. Derived from the same
## sign table the corners come from, so edges cannot drift from vertices.
func _cube_edges(half: float) -> Array:
	var corners: Array = []
	for i in range(CUBE_SIGNS.size()):
		var sign_vec: Vector3 = CUBE_SIGNS[i]
		corners.append(sign_vec * half)
	var side: float = half * 2.0
	var edges: Array = []
	for i in range(corners.size()):
		for j in range(i + 1, corners.size()):
			var a: Vector3 = corners[i]
			var b: Vector3 = corners[j]
			if absf(a.distance_to(b) - side) < 0.0001:
				edges.append([a, b])
	return edges


func _make_dual_material() -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(CYAN.r, CYAN.g, CYAN.b, 0.75)
	m.metallic = 0.2
	m.roughness = 0.4
	m.emission_enabled = _emissive_on
	m.emission = CYAN
	m.emission_energy_multiplier = 1.2
	_dna_materials.append(m)
	return m


# ═══════════════════════════════════════════════════════════════════
# STRUTS
# ═══════════════════════════════════════════════════════════════════

func _make_strut_material(ghost: bool) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.metallic = 0.5
	m.roughness = 0.3
	m.emission_enabled = _emissive_on
	m.emission = AMBER
	if ghost:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = Color(AMBER.r, AMBER.g, AMBER.b, 0.35)
		m.emission_energy_multiplier = 0.8
	else:
		m.albedo_color = AMBER
		m.emission_energy_multiplier = 2.0
	_dna_materials.append(m)
	return m


func _add_strut(a: Vector3, b: Vector3, radius: float, mat: StandardMaterial3D) -> MeshInstance3D:
	var length: float = a.distance_to(b)
	if length < 0.0005:
		return null
	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = length
	cyl.radial_segments = 8
	cyl.rings = 1

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "DnaStrut"
	mi.mesh = cyl
	mi.material_override = mat
	mi.transform = _strut_xform(a, b)
	add_child(mi)
	_dna_nodes.append(mi)
	return mi


## A ghost edge is a run of short cylinders. Dash and gap are equal and the run is
## fitted to the exact edge length, so a truncated edge ends on a dash rather than
## trailing off mid-gap.
func _add_dashed_strut(a: Vector3, b: Vector3, radius: float, mat: StandardMaterial3D) -> void:
	var length: float = a.distance_to(b)
	if length < 0.0005:
		return
	var dashes: int = int(maxf(3.0, floorf(length / DASH_PERIOD)))
	var unit: float = length / float(dashes * 2 - 1)
	var dir: Vector3 = (b - a).normalized()
	for k in range(dashes):
		var t0: float = float(k) * 2.0 * unit
		var p0: Vector3 = a + dir * t0
		var p1: Vector3 = a + dir * (t0 + unit)
		_add_strut(p0, p1, radius, mat)


## Cylinders point along +Y; build a basis whose Y is the strut direction.
func _strut_xform(a: Vector3, b: Vector3) -> Transform3D:
	var mid: Vector3 = (a + b) * 0.5
	var y_axis: Vector3 = (b - a).normalized()
	var ref: Vector3 = Vector3.RIGHT
	if absf(y_axis.dot(ref)) > 0.9:
		ref = Vector3.FORWARD
	var x_axis: Vector3 = ref.cross(y_axis).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()
	return Transform3D(Basis(x_axis, y_axis, z_axis), mid)


# ═══════════════════════════════════════════════════════════════════
# BOUNDARY SPHERE
# ═══════════════════════════════════════════════════════════════════

func _boundary_node() -> MeshInstance3D:
	return get_node_or_null("PuzzleBoundary") as MeshInstance3D


## Resize the translucent shell. The SphereMesh is a sub-resource of the .tscn and is
## therefore SHARED between instances — duplicate it once before touching it, or every
## other placement of this puzzle in the map changes size too.
func _set_boundary_diameter(diameter: float) -> void:
	var b: MeshInstance3D = _boundary_node()
	if b == null:
		return
	var sm: SphereMesh = b.mesh as SphereMesh
	if sm == null:
		return
	if not _boundary_mesh_owned:
		sm = sm.duplicate() as SphereMesh
		b.mesh = sm
		_boundary_mesh_owned = true
	sm.radius = diameter * 0.5
	sm.height = diameter


# ═══════════════════════════════════════════════════════════════════
# SHIPPED STATE — captured once, restored before every rebuild
# ═══════════════════════════════════════════════════════════════════

func _capture_shipped() -> void:
	if _shipped_captured:
		return
	for p in snap_points:
		if not is_instance_valid(p):
			continue
		_shipped_xforms[p] = p.transform
		var body: CollisionObject3D = p as CollisionObject3D
		if body != null:
			_shipped_layers[p] = body.collision_layer
			_shipped_masks[p] = body.collision_mask
	_shipped_captured = true


func _restore_shipped() -> void:
	for p in snap_points:
		if not is_instance_valid(p):
			continue
		if _shipped_xforms.has(p):
			p.transform = _shipped_xforms[p]
		_set_point_present(p, true)
	_set_boundary_diameter(BOUNDARY_LOOSE)


## Presence, not just visibility: a hidden point that still answers the ray is a lie.
func _set_point_present(point: Node3D, present: bool) -> void:
	point.visible = present
	var body: CollisionObject3D = point as CollisionObject3D
	if body != null:
		if present:
			if _shipped_layers.has(point):
				body.collision_layer = int(_shipped_layers[point])
			if _shipped_masks.has(point):
				body.collision_mask = int(_shipped_masks[point])
		else:
			body.collision_layer = 0
			body.collision_mask = 0
	for child in point.get_children():
		var shape: CollisionShape3D = child as CollisionShape3D
		if shape != null:
			shape.disabled = not present


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	var before_solid: String = solid
	var before_dual: String = dual

	if config_data.has("solid"):
		solid = _pick_axis(str(config_data["solid"]), SOLIDS, solid)

	if config_data.has("dual"):
		dual = _pick_axis(str(config_data["dual"]), DUALS, dual)

	# Applied IN PLACE, before any early return — curation_station calls
	# apply_grid_config({"emissive": false}) with no axis key, and an accepted key that
	# does nothing on the no-rebuild path is a silent regression.
	if config_data.has("emissive"):
		_emissive_on = _as_bool(config_data["emissive"], _emissive_on)
		_apply_emissive()

	if not _built:
		return
	# Rebuild ONLY on a real change, and only after _ready has built once. A placement
	# that passes no axis key — or passes the value it already has — must not be torn
	# down and reassembled, or every shipped map pays for this axis existing.
	if solid == before_solid and dual == before_dual:
		return

	# Same reasoning as _ready: only the shipped arrangement may be reset out from
	# under itself, because the reset restores exactly that arrangement. `dual` adds
	# nothing to this — it never moves a snap point, so it cannot be undone by a reset.
	enable_reset_timer = _reset_timer_shipped and solid == "loose"

	_rebuild_now()
	print("[SnapOctahedronPuzzle] Config applied — solid=%s dual=%s" % [solid, dual])


## Free ONLY what this script made, put the scene's own children back the way they
## shipped, then rebuild inline. No call_deferred: a deferred rebuild that strips
## children first hands auto-grounding a zero AABB.
func _rebuild_now() -> void:
	for c in _dna_nodes:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_dna_nodes.clear()
	_dna_materials.clear()
	_restore_shipped()
	_build_all()


func _apply_emissive() -> void:
	if _puzzle_material != null:
		_puzzle_material.emission_enabled = _emissive_on
	for m in _dna_materials:
		if m != null:
			m.emission_enabled = _emissive_on


## Accept an axis value only if it names something we actually build. A typo has to
## fall back to the shipped look rather than strand the placement on nothing.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _as_bool(value, fallback: bool) -> bool:
	if value is bool:
		return bool(value)
	if value is int or value is float:
		return float(value) != 0.0
	if value is String:
		var s: String = str(value).to_lower().strip_edges()
		if s in ["false", "0", "off", "no"]:
			return false
		if s in ["true", "1", "on", "yes"]:
			return true
	return fallback


# ═══════════════════════════════════════════════════════════════════
# LABELS
# ═══════════════════════════════════════════════════════════════════

## The only hanging Label3D this artifact can ever own is the base class's
## success_label, and it is latent (show_success_message defaults false). Seat it at
## the clearing height as soon as it exists so that a map which switches it on never
## gets a framed plate parked across the puzzle. The Label3D itself is left intact —
## billboard flag untouched — because GridInteractablesComponent is what turns it into
## an opaque panel with a bezel, and a second mechanism here would fight it.
##
## The CategoryLogicDisplay at (0, 1.10, 0) renders `point x 6 = octahedron` through a
## SubViewport, not Label3D nodes. The framer never sees it. Leave it alone.
func _place_success_label() -> void:
	if success_label == null:
		return
	success_label.position = Vector3(0.0, SUCCESS_LABEL_Y, 0.0)
