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

func _init() -> void:
	# Define the 4 target vertices for + shape (shared pool)
	target_positions = [
		Vector3(0, 0, -0.2),   # Center-back (horizontal)
		Vector3(0, 0, 0.2),    # Center-front (horizontal)
		Vector3(0, -0.2, 0),   # Bottom-center (vertical)
		Vector3(0, 0.2, 0)     # Top-center (vertical)
	]

	# Define starting positions for each line [start, end]
	line_start_positions = [
		[Vector3(0.2, -0.25, -0.15), Vector3(0.2, -0.25, 0.15)],  # Line 1: top
		[Vector3(0.2, -0.4, -0.15), Vector3(0.2, -0.4, 0.15)]     # Line 2: bottom
	]

	success_message = "Plus Complete! Lines form a +"

	# Form constraints: + shape requires perpendicular lines intersecting at centers
	form_constraints = FormConstraint.plus_constraints()

func _ready() -> void:
	super._ready()
	print("PlusLinePuzzle: 2 lines, 4 vertices, constraints: PERPENDICULAR + INTERSECT_CENTER")

func _complete_puzzle() -> void:
	var display = get_node_or_null("PlusLogicDisplay")
	if display:
		display.visible = false
	super._complete_puzzle()
