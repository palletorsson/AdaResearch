extends LineSnapPuzzleBase
class_name CrossLinePuzzle

## CrossLinePuzzle - Interactive puzzle to form an X cross from two horizontal lines
## Starting: Two horizontal parallel lines (20cm apart, 40cm long)
## Target: X cross formation (diagonal lines)

func _init() -> void:
	# Define the line configurations
	# Starting: Two horizontal lines in XY plane (30cm apart vertically)
	# Target: Diagonal cross (X shape) in ZY plane (vertical, facing player)
	line_definitions = [
		{
			"start_pos": Vector3(-0.2, 0.15, 0),    # Left end of top horizontal line (15cm above center)
			"end_pos": Vector3(0.2, 0.15, 0),       # Right end of top horizontal line
			"target_start": Vector3(0, 0.2, -0.2),  # a: Top-back diagonal
			"target_end": Vector3(0, -0.2, 0.2)     # b: Bottom-front diagonal (forms \ line)
		},
		{
			"start_pos": Vector3(-0.2, -0.15, 0),   # Left end of bottom horizontal line (15cm below center)
			"end_pos": Vector3(0.2, -0.15, 0),      # Right end of bottom horizontal line
			"target_start": Vector3(0, -0.2, -0.2), # c: Bottom-back diagonal
			"target_end": Vector3(0, 0.2, 0.2)      # d: Top-front diagonal (forms / line)
		}
	]
	
	# Customize success message
	success_message = "Cross Complete! Lines form an X"

func _ready() -> void:
	# Call parent ready
	super._ready()
	
	print("CrossLinePuzzle: Initialized with 2 lines")
	print("  Starting: Two horizontal lines in XY plane (30cm apart, 40cm long)")
	print("  Top line (reddish): y=+0.15m, targets a->b")
	print("  Bottom line (bluish): y=-0.15m, targets c->d")
	print("  Target: X cross formation in ZY plane (vertical, facing player)")
