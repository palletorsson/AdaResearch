extends LineSnapPuzzleBase
class_name PlusLinePuzzle

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
