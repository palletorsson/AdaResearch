extends LineSnapPuzzleBase
class_name TriangleLinePuzzle

# @identity
# essence: triangle = 3 edges connecting 3 vertices — the minimal closed polygon
# desire: learner discovers that three lines can close into the simplest possible bounded shape
# critical_parameter: closure — all 3 snap targets must be occupied with shared endpoints to complete
# triggers: snapping all 3 line endpoints into the 3 triangle vertex targets
# emerges: the triangle as the atomic unit of all mesh geometry — every surface is triangles beneath
# needs: [missing VR controls — all interaction is line-endpoint snapping]
# relationships: extends LineSnapPuzzleBase; logical predecessor to snap_tetrahedron_puzzle
# truth: three points that are not collinear always define a triangle — and a unique plane

## TriangleLinePuzzle - Interactive puzzle to form a triangle from three lines
## Any endpoint can snap to any of the 3 triangle vertices

# --- DNA (stage 2 — variation) ---
#
# The truth line above says the three points define a unique PLANE, but the shipped puzzle only
# ever offered one plane and one way of handing you the parts. Both were hard-coded literals in
# _init(). They are now axes.

## Which plane the three points close in.
## "upright" is the shipped layout — the triangle stands in the local ZY plane like a picture you
## face. "ground" lays the same triangle flat, so you assemble a floor facet rather than a sign.
## "tilted" hangs it at 45°, where neither reading is available and the plane has to be read as a
## choice rather than a default.
@export_enum("upright", "ground", "tilted") var target_plane: String = "upright"

## How the three unformed lines are presented before assembly.
## "racked" is the shipped stock — three identical parallel lines stacked off to the side, parts
## issued from a rack. "strewn" drops them at unrelated angles, so the triangle is a recognition
## you impose on debris. "ringed" parks each line just outside the edge it belongs to, so nothing
## needs finding and the whole puzzle is closure.
@export_enum("racked", "strewn", "ringed") var stock: String = "racked"

# Canonical triangle in plane coordinates (u across, v up): equilateral, ~40 cm sides, apex up.
const TRI_UV: Array = [
	Vector2(-0.2, -0.173),  # Bottom-left vertex
	Vector2(0.2, -0.173),   # Bottom-right vertex
	Vector2(0.0, 0.173),    # Top apex
]
const TILT_DEG: float = 45.0
const GROUND_Y: float = -0.173  # lay the flat triangle at the height of the upright one's base
const STOCK_HALF: float = 0.15  # half-length of an unformed line, as shipped
const RING_OFFSET: float = 0.14 # how far outside its edge a "ringed" line waits


func _init() -> void:
	# Shipped defaults, kept here verbatim so the puzzle is valid even before _ready runs.
	# Equilateral triangle in ZY plane, ~40cm sides
	target_positions = [
		Vector3(0, -0.173, -0.2),  # Bottom-left vertex
		Vector3(0, -0.173, 0.2),   # Bottom-right vertex
		Vector3(0, 0.173, 0)       # Top apex
	]

	# Define starting positions for each line [start, end]
	# Three horizontal lines in front of the player
	line_start_positions = [
		[Vector3(0.2, -0.2, -0.15), Vector3(0.2, -0.2, 0.15)],  # Line 1: top
		[Vector3(0.2, -0.3, -0.15), Vector3(0.2, -0.3, 0.15)],  # Line 2: middle
		[Vector3(0.2, -0.4, -0.15), Vector3(0.2, -0.4, 0.15)]   # Line 3: bottom
	]

	# Customize success message
	success_message = "Triangle Complete!"

	# Form constraints: Triangle requires 3 connected lines forming a closed loop
	form_constraints = FormConstraint.triangle_constraints()


func _ready() -> void:
	_apply_dna()
	super._ready()
	print("TriangleLinePuzzle: 3 lines, 3 vertices, plane=%s stock=%s, constraints: CONNECTED + CLOSED_LOOP" % [target_plane, stock])


func _complete_puzzle() -> void:
	# Hide logic display if needed
	var display = get_node_or_null("TriangleLogicDisplay")
	if display:
		display.visible = false

	super._complete_puzzle()


# --- DNA layout ---

## Recompute both hard-coded tables from the two axes. At the defaults this reproduces the shipped
## literals exactly (see _to_local and _racked_lines).
func _apply_dna() -> void:
	target_positions = _dna_targets()
	line_start_positions = _dna_stock()


## Map a point in the triangle's own plane coordinates into the puzzle's local space.
## The "upright" branch is the shipped mapping: (u, v) -> (0, v, u).
func _to_local(u: float, v: float) -> Vector3:
	if target_plane == "ground":
		return Vector3(v, GROUND_Y, u)
	if target_plane == "tilted":
		var a: float = deg_to_rad(TILT_DEG)
		return Vector3(v * sin(a), v * cos(a), u)
	return Vector3(0.0, v, u)


func _dna_targets() -> Array[Vector3]:
	var pts: Array[Vector3] = []
	for uv in TRI_UV:
		pts.append(_to_local(uv.x, uv.y))
	return pts


func _dna_stock() -> Array[Array]:
	if stock == "strewn":
		return _strewn_lines()
	if stock == "ringed":
		return _ringed_lines()
	return _racked_lines()


## The shipped stock: three parallel lines racked beside the target, verbatim.
func _racked_lines() -> Array[Array]:
	var out: Array[Array] = []
	out.append([Vector3(0.2, -0.2, -0.15), Vector3(0.2, -0.2, 0.15)])
	out.append([Vector3(0.2, -0.3, -0.15), Vector3(0.2, -0.3, 0.15)])
	out.append([Vector3(0.2, -0.4, -0.15), Vector3(0.2, -0.4, 0.15)])
	return out


## Three lines dropped at unrelated angles in the same side plane. Fixed constants, not randf —
## this artifact ships in sequences where randomness has not been taught yet.
func _strewn_lines() -> Array[Array]:
	var centers: Array[Vector3] = [
		Vector3(0.2, -0.18, -0.22),
		Vector3(0.2, -0.34, 0.06),
		Vector3(0.2, -0.46, -0.04),
	]
	var angles: Array[float] = [18.0, -55.0, 78.0]

	var out: Array[Array] = []
	for i in centers.size():
		var a: float = deg_to_rad(angles[i])
		var half: Vector3 = Vector3(0.0, sin(a), cos(a)) * STOCK_HALF
		out.append([centers[i] - half, centers[i] + half])
	return out


## Each line parked just outside the triangle edge it belongs to, parallel to it. Follows
## target_plane, so the ring lies in whatever plane the triangle closes in.
func _ringed_lines() -> Array[Array]:
	var centroid: Vector2 = (TRI_UV[0] + TRI_UV[1] + TRI_UV[2]) / 3.0

	var out: Array[Array] = []
	for i in TRI_UV.size():
		var a: Vector2 = TRI_UV[i]
		var b: Vector2 = TRI_UV[(i + 1) % TRI_UV.size()]
		var mid: Vector2 = (a + b) * 0.5
		var along: Vector2 = (b - a).normalized() * STOCK_HALF
		var outward: Vector2 = (mid - centroid).normalized() * RING_OFFSET
		var p0: Vector2 = mid + outward - along
		var p1: Vector2 = mid + outward + along
		out.append([_to_local(p0.x, p0.y), _to_local(p1.x, p1.y)])
	return out


## Grid system integration — accept DNA from map data.
## Guarded: the grid call_deferreds this for every placement, so do nothing unless an axis
## actually moved, and only re-seat nodes that the base class has already created.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed := false

	if config_data.has("target_plane"):
		var p: String = str(config_data["target_plane"]).strip_edges().to_lower()
		if p in ["upright", "ground", "tilted"] and p != target_plane:
			target_plane = p
			changed = true

	if config_data.has("stock"):
		var s: String = str(config_data["stock"]).strip_edges().to_lower()
		if s in ["racked", "strewn", "ringed"] and s != stock:
			stock = s
			changed = true

	if not changed:
		return

	_apply_dna()

	# The base class builds markers and lines from these arrays on a deferred call. If that has not
	# happened yet (the usual case — the grid configures right after add_child) the refreshed arrays
	# are simply picked up, and nothing needs moving.
	if target_markers.is_empty() and snap_lines.is_empty():
		return

	_reseat()


## Move already-built markers and lines onto the refreshed layout.
func _reseat() -> void:
	var global_targets: Array[Vector3] = []
	for p in target_positions:
		global_targets.append(global_transform * p)

	for i in range(target_markers.size()):
		if i < global_targets.size() and is_instance_valid(target_markers[i]):
			target_markers[i].global_position = global_targets[i]

	for i in range(snap_lines.size()):
		var line = snap_lines[i]
		if not is_instance_valid(line):
			continue
		line.set_shared_targets(global_targets)
		if i < line_start_positions.size() and line.endpoint_a and line.endpoint_b:
			line.endpoint_a.global_position = global_transform * line_start_positions[i][0]
			line.endpoint_b.global_position = global_transform * line_start_positions[i][1]
			line._update_line_geometry()
