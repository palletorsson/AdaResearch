extends LineSnapPuzzleBase
class_name ParallelLinePuzzle

# @identity
# essence: ∥ — two lines with the same direction vector, equal distance apart at every point
# desire: learner understands parallelism as a relationship between directions, not just visual sameness
# critical_parameter: the snap tolerance — how close endpoints must be to lock into position
# triggers: snapping both lines to the 4 targets — the puzzle validates direction equality
# emerges: the idea that parallel lines never meet because they share an infinite point at infinity
# needs: [missing VR controls — all interaction is line-endpoint snapping]
# relationships: extends LineSnapPuzzleBase; contrasts with plus_line_puzzle (perpendicular)
# truth: parallel means same direction — a geometric property, not a visual impression

## ParallelLinePuzzle - Interactive puzzle to align two parallel lines
## Any endpoint can snap to any of the 4 targets

# --- DNA (stage 2 — variation) ---
#
# The truth line above says parallel is a relation between DIRECTIONS, not a look. The shipped
# puzzle contradicted it twice, in two literal arrays in _init():
#
#   * the four targets made two UPRIGHT posts, so the answer could be found by reading gravity
#     rather than by comparing directions;
#   * the two lines were handed over ALREADY parallel to each other, so the learner transported a
#     parallelism instead of making one.
#
# Both literals are now axes. Defaults reproduce them exactly (0° tilt collapses both generators
# back to the shipped numbers).

## The pose the finished pair must be brought into.
## "upright" is the shipped layout — two vertical posts, parallel wearing the world's vertical.
## "lying" says the same thing as two horizontal rungs. "oblique" takes both world axes away, and
## is the only pose that actually tests the claim: no gravity to read the answer off.
@export_enum("upright", "oblique", "lying") var pair_pose: String = "upright"

## How the pair is handed over before assembly.
## "parallel" is the shipped stock — the two lines already share a direction, so only placement is
## asked for. "crossed" hands over a right angle and "tilted" hands over two disagreeing obliques;
## in both, the parallelism has to be made rather than moved.
@export_enum("parallel", "crossed", "tilted") var start_state: String = "parallel"

## The finished pair: half its length, and half the gap between the two lines.
const PAIR_HALF_LENGTH: float = 0.2
const PAIR_HALF_GAP: float = 0.1

## Where each line is handed to the learner, and how long it is, as shipped.
const START_CENTERS: Array = [Vector3(0.2, -0.25, 0.0), Vector3(0.2, -0.4, 0.0)]
const START_HALF: float = 0.15

## Pose = tilt of the target pair away from upright, about the local X axis.
const POSE_TILT_DEG: Dictionary = {"upright": 0.0, "oblique": 35.0, "lying": 90.0}

## Stock = tilt of each handed-over line away from the shipped direction (+Z).
const STOCK_TILT_DEG: Dictionary = {
	"parallel": [0.0, 0.0],
	"crossed": [0.0, 90.0],
	"tilted": [-25.0, 25.0],
}


func _init() -> void:
	# Shipped defaults, kept here verbatim so the puzzle is valid even before _ready runs.
	# The 4 target vertices for parallel lines (shared pool)
	target_positions = [
		Vector3(0, -0.2, -0.1),  # Bottom of left line
		Vector3(0, 0.2, -0.1),   # Top of left line
		Vector3(0, -0.2, 0.1),   # Bottom of right line
		Vector3(0, 0.2, 0.1)     # Top of right line
	]

	# Starting positions for each line [start, end]
	line_start_positions = [
		[Vector3(0.2, -0.25, -0.15), Vector3(0.2, -0.25, 0.15)],  # Line 1: top
		[Vector3(0.2, -0.4, -0.15), Vector3(0.2, -0.4, 0.15)]     # Line 2: bottom
	]

	success_message = "Parallel Complete! Lines aligned"

	# Form constraints: Two lines must be parallel
	form_constraints = FormConstraint.parallel_constraints()


func _ready() -> void:
	_apply_dna()
	super._ready()
	print("ParallelLinePuzzle: 2 lines, 4 vertices, pose=%s stock=%s, constraints: PARALLEL" % [pair_pose, start_state])


func _complete_puzzle() -> void:
	var display = get_node_or_null("ParallelLogicDisplay")
	if display:
		display.visible = false
	super._complete_puzzle()


# --- DNA layout ---

## Recompute both hard-coded tables from the two axes. At the defaults this reproduces the shipped
## literals exactly (both generators are identities at 0° tilt).
func _apply_dna() -> void:
	target_positions = _dna_targets()
	line_start_positions = _dna_stock()


## The 4 target vertices, in the shipped order: both ends of the near line, then both ends of the
## far line. The pair is tilted about X, so "upright" is the shipped (0, ±0.2, ±0.1) layout.
func _dna_targets() -> Array[Vector3]:
	var theta: float = deg_to_rad(float(POSE_TILT_DEG.get(pair_pose, 0.0)))
	var dir: Vector3 = Vector3(0.0, cos(theta), sin(theta))
	var off: Vector3 = Vector3(0.0, -sin(theta), cos(theta))

	var pts: Array[Vector3] = []
	for side in range(2):
		var sign_f: float = -1.0 if side == 0 else 1.0
		var centre: Vector3 = off * (PAIR_HALF_GAP * sign_f)
		pts.append(centre - dir * PAIR_HALF_LENGTH)
		pts.append(centre + dir * PAIR_HALF_LENGTH)
	return pts


## Starting [start, end] for each line. At 0° tilt both run along +Z from the shipped centres,
## which is the shipped literal array.
func _dna_stock() -> Array[Array]:
	var tilts: Array = STOCK_TILT_DEG.get(start_state, STOCK_TILT_DEG["parallel"])

	var out: Array[Array] = []
	for i in range(START_CENTERS.size()):
		var centre: Vector3 = START_CENTERS[i]
		var theta: float = deg_to_rad(float(tilts[i]))
		var half: Vector3 = Vector3(0.0, sin(theta), cos(theta)) * START_HALF
		out.append([centre - half, centre + half])
	return out


## Grid system integration — accept DNA from map data.
## Guarded: the grid call_deferreds this for every placement, so do nothing unless an axis actually
## moved, and only re-seat nodes the base class has already created.
func apply_grid_config(config_data: Dictionary) -> void:
	var changed: bool = false

	if config_data.has("pair_pose"):
		var p: String = str(config_data["pair_pose"]).strip_edges().to_lower()
		if p in ["upright", "oblique", "lying"] and p != pair_pose:
			pair_pose = p
			changed = true

	if config_data.has("start_state"):
		var s: String = str(config_data["start_state"]).strip_edges().to_lower()
		if s in ["parallel", "crossed", "tilted"] and s != start_state:
			start_state = s
			changed = true

	if not changed:
		return

	_apply_dna()

	# If the base class has not built yet (the usual case — the grid configures right after
	# add_child) the refreshed arrays are simply picked up, and nothing needs moving.
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
