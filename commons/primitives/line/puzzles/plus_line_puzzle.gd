extends LineSnapPuzzleBase
class_name PlusLinePuzzle

## PlusLinePuzzle - Interactive puzzle to form a + (plus) from two horizontal lines
## Starting: Two horizontal parallel lines
## Target: One horizontal, one vertical, forming + shape (perpendicular intersection)

func _init() -> void:
	# Define the line configurations
	# Starting: Two horizontal lines in XY plane
	# Target: + shape in ZY plane (one horizontal, one vertical, intersecting at center)
	line_definitions = [
		{
			"start_pos": Vector3(-0.2, 0.15, 0),    # Left end of top horizontal line
			"end_pos": Vector3(0.2, 0.15, 0),       # Right end of top horizontal line
			"target_start": Vector3(0, 0, -0.2),    # a: Center-back (horizontal line in ZY)
			"target_end": Vector3(0, 0, 0.2)        # b: Center-front (horizontal line)
		},
		{
			"start_pos": Vector3(-0.2, -0.15, 0),   # Left end of bottom horizontal line
			"end_pos": Vector3(0.2, -0.15, 0),      # Right end of bottom horizontal line
			"target_start": Vector3(0, -0.2, 0),    # c: Bottom-center (vertical line in ZY)
			"target_end": Vector3(0, 0.2, 0)        # d: Top-center (vertical line)
		}
	]
	
	# Customize success message
	success_message = "Plus Complete! Lines form a +"

func _ready() -> void:
	# Call parent ready
	super._ready()
	
	print("PlusLinePuzzle: Initialized with 2 lines")
	print("  Starting: Two horizontal lines in XY plane")
	print("  Top line (reddish): y=+0.15m, targets a->b (horizontal)")
	print("  Bottom line (bluish): y=-0.15m, targets c->d (vertical)")
	print("  Target: + shape in ZY plane (perpendicular intersection)")
