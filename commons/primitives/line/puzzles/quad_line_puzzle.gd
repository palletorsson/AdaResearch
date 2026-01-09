extends LineSnapPuzzleBase
class_name QuadLinePuzzle

## QuadLinePuzzle - Interactive puzzle to form a square from four lines
## Starting: Four horizontal lines at different heights
## Target: Four lines forming a square outline

func _init() -> void:
	# Define the line configurations
	# Starting: Four horizontal lines in XY plane
	# Target: Square outline in ZY plane (40cm x 40cm)
	var half_size = 0.2  # 20cm from center
	
	line_definitions = [
		{
			"start_pos": Vector3(-0.25, 0.25, 0),      # Line 1: Top horizontal
			"end_pos": Vector3(0.25, 0.25, 0),
			"target_start": Vector3(0, half_size, -half_size),  # a: Top-left
			"target_end": Vector3(0, half_size, half_size)      # b: Top-right (top edge)
		},
		{
			"start_pos": Vector3(-0.25, 0.08, 0),      # Line 2: Upper-mid horizontal
			"end_pos": Vector3(0.25, 0.08, 0),
			"target_start": Vector3(0, half_size, half_size),   # c: Top-right
			"target_end": Vector3(0, -half_size, half_size)     # d: Bottom-right (right edge)
		},
		{
			"start_pos": Vector3(-0.25, -0.08, 0),     # Line 3: Lower-mid horizontal
			"end_pos": Vector3(0.25, -0.08, 0),
			"target_start": Vector3(0, -half_size, half_size),  # e: Bottom-right
			"target_end": Vector3(0, -half_size, -half_size)    # f: Bottom-left (bottom edge)
		},
		{
			"start_pos": Vector3(-0.25, -0.25, 0),     # Line 4: Bottom horizontal
			"end_pos": Vector3(0.25, -0.25, 0),
			"target_start": Vector3(0, -half_size, -half_size), # g: Bottom-left
			"target_end": Vector3(0, half_size, -half_size)     # h: Top-left (left edge)
		}
	]
	
	# Customize success message
	success_message = "Square Complete!"

func _ready() -> void:
	# Call parent ready
	super._ready()
	
	print("QuadLinePuzzle: Initialized with 4 lines")
	print("  Starting: Four horizontal lines at different heights")
	print("  Line 1: y=+0.25m, targets a->b (top edge)")
	print("  Line 2: y=+0.08m, targets c->d (right edge)")
	print("  Line 3: y=-0.08m, targets e->f (bottom edge)")
	print("  Line 4: y=-0.25m, targets g->h (left edge)")
	print("  Target: 40cm x 40cm square in ZY plane")
