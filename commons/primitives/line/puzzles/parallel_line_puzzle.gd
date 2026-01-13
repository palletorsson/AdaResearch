extends LineSnapPuzzleBase
class_name ParallelLinePuzzle

## ParallelLinePuzzle - Interactive puzzle to align two lines to be parallel
## Starting: Two lines at different angles
## Target: Two parallel vertical lines side by side

func _init() -> void:
	# Define the line configurations
	# Starting: Two lines at different angles/positions
	# Target: Two parallel vertical lines in ZY plane, separated horizontally
	line_definitions = [
		{
			# Line 1: Horizontal line, in front of puzzle, top
			"start_pos": Vector3(0.2, -0.25, -0.15),      # Back end
			"end_pos": Vector3(0.2, -0.25, 0.15),         # Front end
			"target_start": Vector3(0, -0.2, -0.1),     # a: Bottom of left parallel line
			"target_end": Vector3(0, 0.2, -0.1)         # b: Top of left parallel line
		},
		{
			# Line 2: Horizontal line, in front of puzzle, bottom
			"start_pos": Vector3(0.2, -0.4, -0.15),       # Back end
			"end_pos": Vector3(0.2, -0.4, 0.15),          # Front end
			"target_start": Vector3(0, -0.2, 0.1),      # c: Bottom of right parallel line
			"target_end": Vector3(0, 0.2, 0.1)          # d: Top of right parallel line
		}
	]
	
	# Customize success message
	success_message = "Parallel Complete! Lines aligned"

func _ready() -> void:
	# Call parent ready
	super._ready()
	
	print("ParallelLinePuzzle: Initialized with 2 lines")
	print("  Starting: Two horizontal lines at different heights")
	print("  Top line (reddish): y=+0.15m, targets a->b (left vertical)")
	print("  Bottom line (bluish): y=-0.15m, targets c->d (right vertical)")
	print("  Target: Two parallel vertical lines in ZY plane, 20cm apart")

func _complete_puzzle() -> void:
	# Hide logic display instead of success label if needed
	var display = get_node_or_null("CategoryLogicDisplay")
	if display:
		display.visible = false
		
	super._complete_puzzle()
