extends LineSnapPuzzleBase
class_name CrossLinePuzzle

## CrossLinePuzzle - Interactive puzzle to form an X cross from two lines
## Any endpoint can snap to any of the 4 corner targets
##
## DNA (stage 2 — variation, promoted 2026-08-03)
##   frame — the orientation the crossing is asked to take. The X and the + are
##     the SAME relation (this class and plus_line_puzzle share one constraint
##     set, perpendicular + crossing at centres); only the frame differs. Hard-
##     coding the corners at 45 degrees quietly taught that an X is a kind of
##     figure. Turning this axis says it is a kind of pose.
##   stock — what the unassembled lines give away before you touch them. Shared
##     word, shared geometry with plus_line_puzzle and (by intent) the rest of
##     the family: parts issued from the same rack.
## Both defaults reproduce the pre-promotion artifact exactly.

const FRAME_MODES: Array[String] = ["diagonal", "upright", "oblique"]
const STOCK_MODES: Array[String] = ["stacked", "crossed", "scattered"]

## Where the four marks sit around the crossing point.
##   diagonal — corners of the square, 45 degrees: the saltire X (shipped)
##   upright  — the same four points turned 45 degrees, so the finished figure
##              is a plus. Same perpendicularity, same centres, same lines: the
##              only thing that changed is the frame you read it in
##   oblique  — 20 degrees off the diagonal, aligned with nothing in the room,
##              so neither name is available and only the relation is left
@export_enum("diagonal", "upright", "oblique") var frame: String = "diagonal"

## How the two lines are laid out before the learner starts.
##   stacked   — side by side below the figure, already parallel (shipped)
##   crossed   — already crossing at their centres, only the angle is wrong
##   scattered — unrelated angles and depths; nothing is given
@export_enum("stacked", "crossed", "scattered") var stock: String = "stacked"

func _init() -> void:
	# Define the 4 target vertices for X cross (shared pool)
	target_positions = _target_positions("diagonal")

	# Define starting positions for each line [start, end]
	line_start_positions = _stock_positions("stacked")

	success_message = "Cross Complete! Lines form an X"

	# Form constraints: X cross requires perpendicular lines intersecting at centers
	form_constraints = FormConstraint.cross_constraints()

func _ready() -> void:
	# Fold the declared axes into the base's fields BEFORE the base reads them.
	# With frame="diagonal" and stock="stacked" this restates exactly what
	# _init() already set, so the shipped placements are untouched.
	_apply_dna()
	super._ready()
	print("CrossLinePuzzle: 2 lines, 4 vertices, frame=%s, stock=%s, constraints: PERPENDICULAR + INTERSECT_CENTER" % [frame, stock])

func _complete_puzzle() -> void:
	var display = get_node_or_null("CrossLogicDisplay")
	if display:
		display.visible = false
	super._complete_puzzle()

# ── DNA plumbing ──────────────────────────────────────────────────────────────

func _apply_dna() -> void:
	target_positions = _target_positions(frame)
	line_start_positions = _stock_positions(stock)

## The four marks. "diagonal" returns the shipped literals rather than a rotated
## re-derivation of them, so the default is exact to the bit. The other frames
## turn the same square about the axis the puzzle is read along, which keeps the
## diagonals perpendicular and bisecting — the constraints stay satisfiable.
func _target_positions(mode: String) -> Array[Vector3]:
	var out: Array[Vector3] = []
	if mode == "diagonal":
		out.append(Vector3(0, 0.2, -0.2))   # Top-back
		out.append(Vector3(0, -0.2, 0.2))   # Bottom-front
		out.append(Vector3(0, -0.2, -0.2))  # Bottom-back
		out.append(Vector3(0, 0.2, 0.2))    # Top-front
		return out
	var turn: float = deg_to_rad(45.0)
	if mode == "oblique":
		turn = deg_to_rad(20.0)
	var base_corners: Array[Vector3] = _target_positions("diagonal")
	for i in range(base_corners.size()):
		var corner: Vector3 = base_corners[i]
		out.append(corner.rotated(Vector3.RIGHT, turn))
	return out

func _stock_positions(mode: String) -> Array[Array]:
	var out: Array[Array] = []
	if mode == "crossed":
		# Already crossing at their centres, 45 degrees apart: only the angle is left.
		out.append([Vector3(0.2, -0.3, -0.15), Vector3(0.2, -0.3, 0.15)])
		out.append([Vector3(0.2, -0.406, -0.106), Vector3(0.2, -0.194, 0.106)])
		return out
	if mode == "scattered":
		# Unrelated angles and depths — the given hides its answer.
		out.append([Vector3(0.28, -0.45, -0.2), Vector3(0.12, -0.32, 0.05)])
		out.append([Vector3(0.15, -0.2, 0.18), Vector3(0.3, -0.38, 0.02)])
		return out
	# "stacked" — the shipped layout: two parallel lines waiting below the figure.
	out.append([Vector3(0.2, -0.25, -0.15), Vector3(0.2, -0.25, 0.15)])
	out.append([Vector3(0.2, -0.4, -0.15), Vector3(0.2, -0.4, 0.15)])
	return out

## Grid config arrives deferred, after _ready(). Guarded: the grid calls this for
## every placement that carries any config, so do nothing unless a declared axis
## actually moved, and only touch nodes the base has already created.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
	var changed: bool = false
	if config_data.has("frame"):
		var new_frame: String = str(config_data["frame"]).strip_edges().to_lower()
		if FRAME_MODES.has(new_frame) and new_frame != frame:
			frame = new_frame
			changed = true
	if config_data.has("stock"):
		var new_stock: String = str(config_data["stock"]).strip_edges().to_lower()
		if STOCK_MODES.has(new_stock) and new_stock != stock:
			stock = new_stock
			changed = true
	if not changed:
		return
	_apply_dna()
	# The base builds markers and lines from these arrays on a deferred call. In
	# the usual case the grid configures before that runs, so the refreshed
	# arrays are simply picked up and nothing needs moving.
	if target_markers.is_empty() and snap_lines.is_empty():
		return
	_reseat()

## Move already-built markers and lines onto the refreshed tables. Nothing is
## freed or re-instantiated — the count of marks and of lines never changes.
func _reseat() -> void:
	for i in range(target_markers.size()):
		var marker = target_markers[i]
		if not is_instance_valid(marker):
			continue
		if i < target_positions.size():
			marker.global_position = global_transform * target_positions[i]
		marker.visible = show_target_markers
		marker.scale = Vector3.ONE
	var global_targets: Array[Vector3] = []
	for local_pos in target_positions:
		global_targets.append(global_transform * local_pos)
	for i in range(snap_lines.size()):
		var line = snap_lines[i]
		if not is_instance_valid(line):
			continue
		if line.has_method("set_shared_targets"):
			line.set_shared_targets(global_targets)
		if i < line_start_positions.size() and line.endpoint_a and line.endpoint_b:
			line.endpoint_a.global_position = global_transform * line_start_positions[i][0]
			line.endpoint_b.global_position = global_transform * line_start_positions[i][1]
			line._update_line_geometry()
