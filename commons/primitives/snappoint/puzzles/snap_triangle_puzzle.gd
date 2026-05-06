extends SnapPointPuzzleBase
class_name SnapTrianglePuzzle

## Snap Triangle Puzzle Controller
## Manages a puzzle where 3 snap points must be connected to form a triangle
## Extends SnapPointPuzzleBase for common functionality and tag system

func _connect_signals() -> void:
	# Connect to triangle formation signal
	if connection_manager:
		if not connection_manager.triangle_formed.is_connected(_on_triangle_formed):
			connection_manager.triangle_formed.connect(_on_triangle_formed)
		print("SnapTrianglePuzzle: Connected to triangle_formed signal")

func _on_triangle_formed(points: Array) -> void:
	# Check if this triangle uses our points
	var our_points_count = 0
	for point in points:
		if point in snap_points:
			our_points_count += 1
	
	# If all 3 points are ours, this is our triangle!
	if our_points_count == 3:
		print("SnapTrianglePuzzle: Triangle completed with our points!")
		print("SnapTrianglePuzzle: 3/3 edges connected")
		_complete_puzzle()  # Call base class completion method
