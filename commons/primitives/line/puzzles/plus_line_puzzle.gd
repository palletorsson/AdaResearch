extends LineSnapPuzzleBase
class_name PlusLinePuzzle

# @identity
# essence: ⊥ — two lines whose direction vectors have dot product zero
# desire: learner feels perpendicularity as a physical arrangement they construct with their hands
# critical_parameter: the intersection constraint — lines must cross at their midpoints to validate
# triggers: snapping all 4 endpoints to the cross targets — success fires only when both conditions met
# emerges: that 90 degrees is not special until you define an inner product — the dot product makes it special
# needs: [missing VR controls — all interaction is line-endpoint snapping]
# relationships: extends LineSnapPuzzleBase; contrasts with parallel_line_puzzle
# truth: perpendicularity is defined by the dot product equaling zero — geometry expressed as algebra

## PlusLinePuzzle - Interactive puzzle to form a + shape from two lines
## Any endpoint can snap to any of the 4 targets
##
## DNA (stage 2 — variation, promoted 2026-07-29)
##   proof — what counts as having made a plus. The @identity names the
##     intersection constraint as the critical parameter; this axis turns it.
##     Obedience to four marks, or a relation between two directions?
##   stock — what the unassembled lines give away before you touch them.
##     The starting arrangement is itself an argument: parts that already lie
##     parallel have half-answered the question.
## Both defaults reproduce the pre-promotion artifact exactly.

const PROOF_MODES: Array[String] = ["relation", "targets", "angle", "invariant"]
const STOCK_MODES: Array[String] = ["stacked", "crossed", "scattered"]

## What must hold before the puzzle calls itself solved.
##   relation  — endpoints on all four marks AND perpendicular AND crossing at
##               centres (the shipped behaviour)
##   targets   — the four marks alone; position is the whole proof
##   angle     — dot product zero, anywhere in space; the marks stop being law
##               and their rings are not drawn
##   invariant — a plus anywhere: perpendicular and crossing at centres, but
##               free of the marks; the form as invariant, not as location
@export_enum("relation", "targets", "angle", "invariant") var proof: String = "relation"

## How the two lines are laid out before the learner starts.
##   stacked   — side by side below the figure, already parallel (shipped)
##   crossed   — already crossing at their centres, only the angle is wrong
##   scattered — unrelated angles and depths; nothing is given
@export_enum("stacked", "crossed", "scattered") var stock: String = "stacked"

func _init() -> void:
	# Define the 4 target vertices for + shape (shared pool)
	target_positions = [
		Vector3(0, 0, -0.2),   # Center-back (horizontal)
		Vector3(0, 0, 0.2),    # Center-front (horizontal)
		Vector3(0, -0.2, 0),   # Bottom-center (vertical)
		Vector3(0, 0.2, 0)     # Top-center (vertical)
	]

	# Define starting positions for each line [start, end]
	line_start_positions = _stock_positions("stacked")

	success_message = "Plus Complete! Lines form a +"

	# Form constraints: + shape requires perpendicular lines intersecting at centers
	form_constraints = FormConstraint.plus_constraints()

func _ready() -> void:
	# Fold the declared axes into the base's fields BEFORE the base reads them.
	# With proof="relation" and stock="stacked" this restates exactly what
	# _init() already set, so the shipped placements are untouched.
	_apply_dna()
	super._ready()
	print("PlusLinePuzzle: 2 lines, 4 vertices, proof=%s, stock=%s" % [proof, stock])

func _complete_puzzle() -> void:
	var display = get_node_or_null("PlusLogicDisplay")
	if display:
		display.visible = false
	super._complete_puzzle()

## When the marks are no longer required, an endpoint move anywhere is worth
## checking. With require_all_at_targets left true (the default) this defers to
## the base untouched.
func _on_endpoints_changed(start_pos: Vector3, end_pos: Vector3, line: SnapLineSegment) -> void:
	if is_completed or not auto_validate:
		return
	if not require_all_at_targets:
		_validate_puzzle()
		return
	super._on_endpoints_changed(start_pos, end_pos, line)

# ── DNA plumbing ──────────────────────────────────────────────────────────────

func _apply_dna() -> void:
	line_start_positions = _stock_positions(stock)
	form_constraints = _constraints_for(proof)
	if proof == "targets":
		use_form_constraints = false
		require_all_at_targets = true
		show_target_markers = true
	elif proof == "angle" or proof == "invariant":
		# Position stops being the proof, so the rings that ask for obedience
		# are not drawn. The snap targets remain as a quiet aid, not a rule.
		use_form_constraints = true
		require_all_at_targets = false
		show_target_markers = false
	else:
		use_form_constraints = true
		require_all_at_targets = true
		show_target_markers = true

func _constraints_for(mode: String) -> Array[FormConstraint]:
	var out: Array[FormConstraint] = []
	if mode == "targets":
		return out
	if mode == "angle":
		var pair: Array[int] = [0, 1]
		out.append(FormConstraint.new(FormConstraint.Type.PERPENDICULAR, pair, "Lines are perpendicular"))
		return out
	return FormConstraint.plus_constraints()

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

## Grid config arrives deferred, after _ready(). Guarded: the grid calls this
## for every placement that carries any config, so do nothing unless a declared
## axis actually moved, and only touch nodes the base has already created.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data == null or config_data.is_empty():
		return
	var changed: bool = false
	if config_data.has("proof"):
		var new_proof: String = str(config_data["proof"]).strip_edges().to_lower()
		if PROOF_MODES.has(new_proof) and new_proof != proof:
			proof = new_proof
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

## Move already-built lines onto the refreshed stock and honour the marker
## visibility the new proof asks for. Nothing is freed or re-instantiated —
## the targets are the same four points in every mode.
func _reseat() -> void:
	for marker in target_markers:
		if is_instance_valid(marker):
			marker.visible = show_target_markers
	for i in range(snap_lines.size()):
		var line = snap_lines[i]
		if not is_instance_valid(line):
			continue
		if i < line_start_positions.size() and line.endpoint_a and line.endpoint_b:
			line.endpoint_a.global_position = global_transform * line_start_positions[i][0]
			line.endpoint_b.global_position = global_transform * line_start_positions[i][1]
			line._update_line_geometry()
