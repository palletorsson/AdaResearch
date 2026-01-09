extends LineSnapPuzzleBase
class_name TriangleLinePuzzle

## TriangleLinePuzzle - Interactive puzzle to form a triangle from three lines
## Starting: Three horizontal lines at different heights
## Target: Three lines forming an equilateral triangle

func _init() -> void:
	# Define the line configurations
	# Starting: Three horizontal lines in XY plane
	# Target: Equilateral triangle in ZY plane
	# Triangle centered at origin, 40cm sides
	var height = 0.346  # Height of equilateral triangle with 40cm sides ≈ 34.6cm
	
	line_definitions = [
		{
			"start_pos": Vector3(-0.25, 0.2, 0),     # Line 1: Top horizontal
			"end_pos": Vector3(0.25, 0.2, 0),
			"target_start": Vector3(0, -0.173, -0.2),  # a: Bottom-left
			"target_end": Vector3(0, -0.173, 0.2)      # b: Bottom-right (base of triangle)
		},
		{
			"start_pos": Vector3(-0.25, 0, 0),       # Line 2: Middle horizontal
			"end_pos": Vector3(0.25, 0, 0),
			"target_start": Vector3(0, -0.173, -0.2),  # c: Bottom-left (reuse)
			"target_end": Vector3(0, 0.173, 0)         # d: Top apex (left side)
		},
		{
			"start_pos": Vector3(-0.25, -0.2, 0),    # Line 3: Bottom horizontal
			"end_pos": Vector3(0.25, -0.2, 0),
			"target_start": Vector3(0, -0.173, 0.2),   # e: Bottom-right (reuse)
			"target_end": Vector3(0, 0.173, 0)         # f: Top apex (right side)
		}
	]
	
	# Customize success message
	success_message = "Triangle Complete!"

func _ready() -> void:
	# Call parent ready
	super._ready()
	
	print("TriangleLinePuzzle: Initialized with 3 lines")
	print("  Starting: Three horizontal lines at different heights")
	print("  Line 1: y=+0.2m, targets a->b (base)")
	print("  Line 2: y=0.0m, targets c->d (left side)")
	print("  Line 3: y=-0.2m, targets e->f (right side)")
	print("  Target: Equilateral triangle in ZY plane")
