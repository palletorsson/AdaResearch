extends LineSnapPuzzleBase
class_name QuadLinePuzzle

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
	print("QuadLinePuzzle: 4 lines, 4 vertices, constraints: CONNECTED + CLOSED_LOOP")

func _complete_puzzle() -> void:
	var display = get_node_or_null("CategoryLogicDisplay")
	if display:
		display.visible = false
	super._complete_puzzle()
