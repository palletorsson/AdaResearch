extends SnapPointPuzzleBase
class_name SnapTetrahedronPuzzle

# @identity
# essence: tetrahedron = 4 vertices, 6 edges, 4 triangular faces — the minimal 3D solid
# desire: learner constructs the simplest possible polyhedron from 4 floating snap points
# critical_parameter: 4 snap target positions — form the unique convex hull of 4 non-coplanar points
# triggers: snapping all 4 snap points to their targets → puzzle complete signal fires
# emerges: the tetrahedron as the 3D analog of the triangle — irreducible, minimum faces for enclosure
# needs: [missing VR controls besides snapping — no label or slider]
# relationships: extends SnapPointPuzzleBase; logical successor to triangle_line_puzzle in 3D
# truth: you cannot enclose volume with fewer than 4 faces — the tetrahedron is the minimum

## Snap Tetrahedron Puzzle Controller
## Manages a 4-point tetrahedron puzzle
## Extends SnapPointPuzzleBase for common functionality and tag system

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA — axis `solid`
# ═══════════════════════════════════════════════════════════════════
#
# How much of the solid the four points already give away.
#
#   loose      near the answer — the shipped arrangement, four points hovering
#              a snap apart from the minimal solid, nothing drawn between them
#   closed     standing AS the answer — the four points sit on a regular
#              tetrahedron and all six edges are built, so the solid is present
#              rather than promised
#   scattered  saying nothing — twice the spread, apex thrown up and back; the
#              hull these four imply is a sliver, not a body
#   short      one point short of ever being able to say it — three points
#              built, the apex absent, the six edges ghosted so the three risers
#              stop in air where the fourth vertex would have closed them
#
# `short` is the value this object exists for. Its truth line claims a hard
# minimum (four faces to enclose a volume) and until now the object asserted
# that in a comment and never once built the counter-case. `short` builds the
# three-point case that cannot enclose, and leaves the failure as a GAP in the
# outline rather than as an absence you have to be told about.
#
# Deliberately the same axis name and the same four values as snap_cube_puzzle:
# a map can set one word on both and get a consistent statement across the pair.
const SOLIDS: PackedStringArray = ["loose", "closed", "scattered", "short"]

@export_enum("loose", "closed", "scattered", "short") var solid: String = "loose"

## `closed` — a regular tetrahedron of this edge length about (0, 0.68, 0).
## 0.28 m puts the whole silhouette at roughly 0.30 x 0.26 m including strut
## thickness, which is the size band the shipped four points already occupy;
## the difference between `loose` and `closed` is the six edges, not a change
## of scale the camera would have to re-frame for.
const CLOSED_EDGE: float = 0.28
const CLOSED_CENTER_Y: float = 0.68

## Built edges (closed) vs ghosted edges (short). Half the radius, and dashed,
## so `short` reads as a drawing of a solid rather than as the solid itself.
const STRUT_RADIUS: float = 0.012
const GHOST_RADIUS: float = 0.006
const DASH_LEN: float = 0.022
const DASH_GAP: float = 0.014

## How far the three risers climb before stopping in air. The regular
## tetrahedron of edge 0.28 is 0.2286 m tall, so 0.20 m stops them visibly
## short of the vertex they are reaching for — close enough to name the apex,
## far enough that the outline is plainly open.
const GHOST_RISE: float = 0.20

const PUZZLE_CYAN: Color = Color(0.3, 1.0, 0.8)

## Internal
var _built: bool = false
var _emissive: bool = true
var _puzzle_material: StandardMaterial3D
var _axis_nodes: Array[Node3D] = []
var _strut_materials: Array[StandardMaterial3D] = []

## Shipped state of the scene's four snap points, so any value can be undone.
## The points are SCENE children, not nodes this script made — they are
## restored, never freed.
var _shipped_xform: Dictionary = {}
var _shipped_visible: Dictionary = {}
var _shipped_layer: Dictionary = {}
var _shipped_mask: Dictionary = {}

# NOTE: this scene has NO PuzzleBoundary node (the octahedron scene does). The
# builders below never look one up, so there is nothing here to guard and
# nothing to inherit from the sibling by copy.


func _ready() -> void:
	# Non-default arrangements must not be restored by the 60 s reset timer —
	# _store_initial_positions() records the SHIPPED transforms during
	# super._ready(), so leaving the timer on would quietly undo the axis.
	# Set before super so _setup_progress_bar() skips the bar entirely.
	if solid != "loose":
		enable_reset_timer = false

	# Parent first: _find_snap_points() runs before the base _ready's only
	# await, so snap_points is populated by the time this call returns.
	super._ready()

	_snapshot_shipped()
	_apply_puzzle_materials()
	_build_all()
	_built = true


func _connect_signals() -> void:
	# Connect to tetrahedron formation signal
	if connection_manager:
		if not connection_manager.tetrahedron_formed.is_connected(_on_tetrahedron_formed):
			connection_manager.tetrahedron_formed.connect(_on_tetrahedron_formed)
		print("SnapTetrahedronPuzzle: Connected to tetrahedron_formed signal")


func _on_tetrahedron_formed(points: Array) -> void:
	# Check if this tetrahedron uses our snap points
	var our_points_count = 0
	for point in points:
		if point in snap_points:
			our_points_count += 1

	# If all 4 points are ours, this is our tetrahedron!
	if our_points_count == 4:
		print("SnapTetrahedronPuzzle: Tetrahedron completed with our points!")
		_complete_puzzle()  # Call base class completion method


func _apply_puzzle_materials() -> void:
	# Synchronous: snap_points is already populated (super._ready() ran first),
	# so the old one-frame await is gone — no deferral in the build path.
	var puzzle_material = StandardMaterial3D.new()
	puzzle_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puzzle_material.albedo_color = Color(0.3, 1.0, 0.8, 0.6)  # Cyan-ish with 60% opacity
	puzzle_material.metallic = 0.5
	puzzle_material.roughness = 0.3
	puzzle_material.emission_enabled = _emissive
	puzzle_material.emission = Color(0.3, 1.0, 0.8, 1.0)
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
			print("SnapTetrahedronPuzzle: Applied transparent material to ", point.name)


# ═══════════════════════════════════════════════════════════════════
# AXIS BUILD
# ═══════════════════════════════════════════════════════════════════

func _build_all() -> void:
	match solid:
		"closed":
			_build_closed()
		"scattered":
			_build_scattered()
		"short":
			_build_short()
		_:
			pass  # loose — shipped transforms, nothing drawn between them
	_apply_emissive()


## The four vertices of a regular tetrahedron of edge CLOSED_EDGE, centred on
## (0, CLOSED_CENTER_Y, 0), ordered to match the scene's own point order:
## Base1 (-x), Base2 (+x), Base3 (+z), Apex.
func _closed_vertices() -> Array[Vector3]:
	var a: float = CLOSED_EDGE
	var circum: float = a / sqrt(3.0)          # 0.161658 — base circumradius
	var height: float = a * sqrt(2.0 / 3.0)    # 0.228619 — solid height
	var y_base: float = CLOSED_CENTER_Y - height * 0.25
	var y_apex: float = CLOSED_CENTER_Y + height * 0.75
	var half: float = a * 0.5                  # 0.14 — circum * sin(120°)
	var back: float = circum * 0.5             # 0.080829
	var out: Array[Vector3] = [
		Vector3(-half, y_base, -back),
		Vector3(half, y_base, -back),
		Vector3(0.0, y_base, circum),
		Vector3(0.0, y_apex, 0.0),
	]
	return out


## closed — the minimal solid, standing built.
func _build_closed() -> void:
	var verts: Array[Vector3] = _closed_vertices()
	for i in range(4):
		_place_point(i, verts[i])

	var mat: StandardMaterial3D = _make_strut_material(1.0, 2.0)
	for pair in _edge_pairs():
		var ia: int = pair[0]
		var ib: int = pair[1]
		_strut(verts[ia], verts[ib], STRUT_RADIUS, mat)


## scattered — twice the shipped spread. The base ring opens to 0.40 m across,
## the apex leaves the axis entirely (up to y 1.00, 0.18 m further in z), and
## what the four imply flattens into a sliver.
func _build_scattered() -> void:
	_place_point(0, Vector3(-0.20, 0.60, -0.10))
	_place_point(1, Vector3(0.20, 0.60, -0.10))
	_place_point(2, Vector3(0.00, 0.60, 0.24))
	_place_point(3, Vector3(0.00, 1.00, 0.20))


## short — three points, no fourth. The six edges are ghosted; the three
## reaching for the apex end in air. This is what three points cannot enclose.
func _build_short() -> void:
	var verts: Array[Vector3] = _closed_vertices()
	for i in range(3):
		_place_point(i, verts[i])
	_hide_apex()

	var mat: StandardMaterial3D = _make_strut_material(0.45, 0.8)

	# Three base edges — complete, because the base triangle DOES close.
	_dashed_strut(verts[0], verts[1], GHOST_RADIUS, mat)
	_dashed_strut(verts[1], verts[2], GHOST_RADIUS, mat)
	_dashed_strut(verts[2], verts[0], GHOST_RADIUS, mat)

	# Three risers — truncated at GHOST_RISE above the ring, short of the
	# vertex that is not there.
	var apex_v: Vector3 = verts[3]
	var rise: float = apex_v.y - verts[0].y
	var frac: float = 1.0
	if rise > 0.0001:
		frac = clampf(GHOST_RISE / rise, 0.0, 1.0)
	for i in range(3):
		var base_v: Vector3 = verts[i]
		var stop: Vector3 = base_v + (apex_v - base_v) * frac
		_dashed_strut(base_v, stop, GHOST_RADIUS, mat)


func _edge_pairs() -> Array:
	return [[0, 1], [1, 2], [2, 0], [0, 3], [1, 3], [2, 3]]


# ═══════════════════════════════════════════════════════════════════
# PRIMITIVES
# ═══════════════════════════════════════════════════════════════════

func _make_strut_material(alpha: float, energy: float) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(PUZZLE_CYAN.r, PUZZLE_CYAN.g, PUZZLE_CYAN.b, alpha)
	m.metallic = 0.4
	m.roughness = 0.3
	m.emission_enabled = _emissive
	m.emission = PUZZLE_CYAN
	m.emission_energy_multiplier = energy
	_strut_materials.append(m)
	return m


func _strut(a: Vector3, b: Vector3, radius: float, mat: StandardMaterial3D) -> void:
	var seg_len: float = a.distance_to(b)
	if seg_len <= 0.0001:
		return

	var cyl: CylinderMesh = CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = seg_len
	cyl.radial_segments = 8
	cyl.rings = 1

	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = "AxisStrut"
	mi.mesh = cyl
	mi.material_override = mat

	var y_axis: Vector3 = (b - a).normalized()
	var helper: Vector3 = Vector3.UP
	if absf(y_axis.dot(helper)) > 0.9:
		helper = Vector3.RIGHT
	var x_axis: Vector3 = helper.cross(y_axis).normalized()
	var z_axis: Vector3 = x_axis.cross(y_axis).normalized()
	mi.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (a + b) * 0.5)

	add_child(mi)
	_axis_nodes.append(mi)


func _dashed_strut(a: Vector3, b: Vector3, radius: float, mat: StandardMaterial3D) -> void:
	var total: float = a.distance_to(b)
	if total <= 0.0001:
		return
	var dir: Vector3 = (b - a) / total
	var period: float = DASH_LEN + DASH_GAP
	var walked: float = 0.0
	while walked < total:
		var seg_end: float = minf(walked + DASH_LEN, total)
		if seg_end - walked > 0.002:
			_strut(a + dir * walked, a + dir * seg_end, radius, mat)
		walked += period


## Untyped locals on purpose: the RigidBody3D-only members below (freeze,
## velocities, collision layers) do not exist on Node3D, and GDScript 4 does
## not narrow a statically typed variable after an `is` check.
func _place_point(idx: int, pos: Vector3) -> void:
	if idx < 0 or idx >= snap_points.size():
		return
	var point = snap_points[idx]
	if not is_instance_valid(point):
		return
	if point is RigidBody3D:
		point.freeze = true
		point.linear_velocity = Vector3.ZERO
		point.angular_velocity = Vector3.ZERO
	var t: Transform3D = point.transform
	if _shipped_xform.has(point):
		t = _shipped_xform[point]
	t.origin = pos
	point.transform = t


func _hide_apex() -> void:
	if snap_points.size() < 4:
		return
	var apex = snap_points[3]
	if not is_instance_valid(apex):
		return
	apex.visible = false
	if apex is RigidBody3D:
		apex.freeze = true
		apex.set_collision_layer(0)
		apex.set_collision_mask(0)


func _apply_emissive() -> void:
	if _puzzle_material:
		_puzzle_material.emission_enabled = _emissive
	for m in _strut_materials:
		if m:
			m.emission_enabled = _emissive


# ═══════════════════════════════════════════════════════════════════
# SHIPPED-STATE SNAPSHOT / RESTORE
# ═══════════════════════════════════════════════════════════════════

func _snapshot_shipped() -> void:
	_shipped_xform.clear()
	_shipped_visible.clear()
	_shipped_layer.clear()
	_shipped_mask.clear()
	for i in range(snap_points.size()):
		var point = snap_points[i]
		if not is_instance_valid(point):
			continue
		_shipped_xform[point] = point.transform
		_shipped_visible[point] = point.visible
		if point is RigidBody3D:
			_shipped_layer[point] = point.collision_layer
			_shipped_mask[point] = point.collision_mask


func _restore_shipped() -> void:
	for i in range(snap_points.size()):
		var point = snap_points[i]
		if not is_instance_valid(point):
			continue
		if _shipped_xform.has(point):
			point.transform = _shipped_xform[point]
		if _shipped_visible.has(point):
			point.visible = _shipped_visible[point]
		if point is RigidBody3D:
			if _shipped_layer.has(point):
				point.set_collision_layer(_shipped_layer[point])
			if _shipped_mask.has(point):
				point.set_collision_mask(_shipped_mask[point])


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

func apply_grid_config(config_data: Dictionary) -> void:
	var before_solid: String = solid

	# Stage-2 DNA axis — #solid:short
	if config_data.has("solid"):
		solid = _pick_axis(str(config_data["solid"]), SOLIDS, solid)

	# curation_station passes {"emissive": false} and NOTHING else. Applied in
	# place, before every early return, so the key can never become a silent
	# no-op the way it did on barber_paradox.
	if config_data.has("emissive"):
		_emissive = _parse_bool(config_data["emissive"], _emissive)
		_apply_emissive()

	if not _built:
		return
	if solid == before_solid:
		return

	# A non-default arrangement must not be restored by the reset timer.
	enable_reset_timer = (solid == "loose")
	_rebuild_now()
	print("[SnapTetrahedronPuzzle] Config applied — solid=%s" % [solid])


func _rebuild_now() -> void:
	# Free ONLY what this script made. The snap points, the connection manager
	# and the CategoryLogicDisplay are scene children; the grid's label plates
	# are grid children. None of them are ours to free.
	for c in _axis_nodes:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_axis_nodes.clear()
	_strut_materials.clear()
	_restore_shipped()
	_build_all()


## Accept an axis value only if it names something we actually build. A typo in
## a map token falls back to the shipped look rather than stranding the
## placement in a half-recognised arrangement.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _parse_bool(raw, fallback: bool) -> bool:
	if raw is bool:
		return bool(raw)
	var v: String = str(raw).to_lower().strip_edges()
	if v in ["true", "1", "on", "yes"]:
		return true
	if v in ["false", "0", "off", "no"]:
		return false
	return fallback
