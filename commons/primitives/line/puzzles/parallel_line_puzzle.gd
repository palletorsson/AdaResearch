extends LineSnapPuzzleBase
class_name ParallelLinePuzzle

## ParallelLinePuzzle - Interactive puzzle to align two parallel lines
## Any endpoint can snap to any of the 4 targets

func _init() -> void:
	# Define the 4 target vertices for parallel lines (shared pool)
	target_positions = [
		Vector3(0, -0.2, -0.1),  # Bottom of left line
		Vector3(0, 0.2, -0.1),   # Top of left line
		Vector3(0, -0.2, 0.1),   # Bottom of right line
		Vector3(0, 0.2, 0.1)     # Top of right line
	]

	# Define starting positions for each line [start, end]
	line_start_positions = [
		[Vector3(0.2, -0.25, -0.15), Vector3(0.2, -0.25, 0.15)],  # Line 1: top
		[Vector3(0.2, -0.4, -0.15), Vector3(0.2, -0.4, 0.15)]     # Line 2: bottom
	]

	success_message = "Parallel Complete! Lines aligned"

	# Form constraints: Two lines must be parallel
	form_constraints = FormConstraint.parallel_constraints()

func _ready() -> void:
	super._ready()
	print("ParallelLinePuzzle: 2 lines, 4 vertices, constraints: PARALLEL")

func _complete_puzzle() -> void:
	var display = get_node_or_null("ParallelLogicDisplay")
	if display:
		display.visible = false
	super._complete_puzzle()
