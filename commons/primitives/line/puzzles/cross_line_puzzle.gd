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
			# Line 1: Horizontal line, in front of puzzle, top
			"start_pos": Vector3(0.2, -0.25, -0.15),      # Back end
			"end_pos": Vector3(0.2, -0.25, 0.15),         # Front end
			"target_start": Vector3(0, 0.2, -0.2),       # a: Top-back diagonal
			"target_end": Vector3(0, -0.2, 0.2)          # b: Bottom-front diagonal (forms \ line)
		},
		{
			# Line 2: Horizontal line, in front of puzzle, bottom
			"start_pos": Vector3(0.2, -0.4, -0.15),       # Back end
			"end_pos": Vector3(0.2, -0.4, 0.15),          # Front end
			"target_start": Vector3(0, -0.2, -0.2),      # c: Bottom-back diagonal
			"target_end": Vector3(0, 0.2, 0.2)           # d: Top-front diagonal (forms / line)
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

func _complete_puzzle() -> void:
	# Hide logic display instead of success label if needed
	# But for now, let's keep success_label behavior from base and just hide the display
	var display = get_node_or_null("CategoryLogicDisplay")
	if display:
		display.visible = false
		
	super._complete_puzzle()
