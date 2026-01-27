extends LineSnapPuzzleBase
class_name CrossLinePuzzle

## CrossLinePuzzle - Interactive puzzle to form an X cross from two lines
## Any endpoint can snap to any of the 4 corner targets

func _init() -> void:
	# Define the 4 target vertices for X cross (shared pool)
	target_positions = [
		Vector3(0, 0.2, -0.2),   # Top-back
		Vector3(0, -0.2, 0.2),   # Bottom-front
		Vector3(0, -0.2, -0.2),  # Bottom-back
		Vector3(0, 0.2, 0.2)     # Top-front
	]

	# Define starting positions for each line [start, end]
	line_start_positions = [
		[Vector3(0.2, -0.25, -0.15), Vector3(0.2, -0.25, 0.15)],  # Line 1: top
		[Vector3(0.2, -0.4, -0.15), Vector3(0.2, -0.4, 0.15)]     # Line 2: bottom
	]

	success_message = "Cross Complete! Lines form an X"

	# Form constraints: X cross requires perpendicular lines intersecting at centers
	form_constraints = FormConstraint.cross_constraints()

func _ready() -> void:
	super._ready()
	print("CrossLinePuzzle: 2 lines, 4 vertices, constraints: PERPENDICULAR + INTERSECT_CENTER")

func _complete_puzzle() -> void:
	var display = get_node_or_null("CrossLogicDisplay")
	if display:
		display.visible = false
	super._complete_puzzle()
