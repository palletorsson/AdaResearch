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

func _init() -> void:
	# Define the 3 target vertices of the triangle (shared pool)
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
	super._ready()
	print("TriangleLinePuzzle: 3 lines, 3 vertices, constraints: CONNECTED + CLOSED_LOOP")

func _complete_puzzle() -> void:
	# Hide logic display if needed
	var display = get_node_or_null("TriangleLogicDisplay")
	if display:
		display.visible = false

	super._complete_puzzle()
