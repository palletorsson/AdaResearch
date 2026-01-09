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
			"start_pos": Vector3(-0.2, 0.15, 0),    # Left end of top line
			"end_pos": Vector3(0.2, 0.15, 0),       # Right end of top line
			"target_start": Vector3(0, -0.2, -0.1), # a: Bottom of left parallel line
			"target_end": Vector3(0, 0.2, -0.1)     # b: Top of left parallel line
		},
		{
			"start_pos": Vector3(-0.2, -0.15, 0),   # Left end of bottom line
			"end_pos": Vector3(0.2, -0.15, 0),      # Right end of bottom line
			"target_start": Vector3(0, -0.2, 0.1),  # c: Bottom of right parallel line
			"target_end": Vector3(0, 0.2, 0.1)      # d: Top of right parallel line
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
