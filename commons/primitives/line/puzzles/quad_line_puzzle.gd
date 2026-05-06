extends LineSnapPuzzleBase
class_name QuadLinePuzzle

# @identity
# essence: quad = 4 edges closing 4 corners — the simplest polygon with a right angle relationship
# desire: learner assembles a square and feels how four equal lengths and right angles constrain each other
# critical_parameter: the 4 corner snap targets — all must be occupied for the square to register
# triggers: snapping all 4 line endpoints to the 4 corner positions in sequence
# emerges: the quad as two triangles sharing a diagonal — every quad in 3D is secretly two triangles
# needs: [missing VR controls — all interaction is line-endpoint snapping]
# relationships: extends LineSnapPuzzleBase; logical predecessor to quad face primitive
# truth: a square is four equal sides and four right angles — remove any one constraint and it changes

## QuadLinePuzzle - Interactive puzzle to form a square from four lines
## Any endpoint can snap to any of the 4 corner targets

func _init() -> void:
	var half_size = 0.2  # 20cm from center

	# Define the 4 corner vertices of the square (shared pool)
	target_positions = [
		Vector3(0, half_size, -half_size),   # Top-left
		Vector3(0, half_size, half_size),    # Top-right
		Vector3(0, -half_size, half_size),   # Bottom-right
		Vector3(0, -half_size, -half_size)   # Bottom-left
	]

	# Define starting positions for each line [start, end]
	line_start_positions = [
		[Vector3(0.2, -0.15, -0.15), Vector3(0.2, -0.15, 0.15)],  # Line 1: topmost
		[Vector3(0.2, -0.25, -0.15), Vector3(0.2, -0.25, 0.15)],  # Line 2: upper-mid
		[Vector3(0.2, -0.35, -0.15), Vector3(0.2, -0.35, 0.15)],  # Line 3: lower-mid
		[Vector3(0.2, -0.45, -0.15), Vector3(0.2, -0.45, 0.15)]   # Line 4: bottommost
	]

	success_message = "Square Complete!"

	# Form constraints: Quad requires 4 connected lines forming a closed loop
	form_constraints = FormConstraint.quad_constraints()

func _ready() -> void:
	super._ready()
	print("QuadLinePuzzle: 4 lines, 4 vertices, constraint: CLOSED_LOOP (any connection order)")

func _complete_puzzle() -> void:
	var display = get_node_or_null("QuadLogicDisplay")
	if display:
		display.visible = false
	super._complete_puzzle()
