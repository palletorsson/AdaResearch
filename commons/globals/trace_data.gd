extends Node

## Persistent storage for player-generated creations.
## Stores traces (from DrawDot) and tile patterns (from PatternTilePuzzle)
## so they can be displayed in other scenes (grid_lines, array_carpet, etc).

# --- Traces ---
# Each trace is an Array of Vector3 points.
var saved_traces: Array = []

signal trace_added(points: Array)

# --- Tile Patterns ---
# Stores the player's tile pattern from the arrays lesson.
# {grid_data: Array, tile_size: int, repeat_mode: int, palette: Array[Color]}
var _pattern: Dictionary = {}

signal pattern_saved


func _ready() -> void:
	print("TraceData: Autoload Singleton READY")


# --- Trace API ---

func add_trace(points: Array) -> void:
	if points.size() > 1:
		# points is Array[Vector3], we duplicate it to store a snapshot
		var new_trace = points.duplicate()
		saved_traces.append(new_trace)
		print("TraceData: Saved new trace with %d points" % points.size())
		trace_added.emit(new_trace)


func clear_traces() -> void:
	saved_traces.clear()


func get_all_traces() -> Array:
	return saved_traces


# --- Pattern API ---

func save_pattern(grid_data: Array, tile_size: int, repeat_mode: int, palette: Array) -> void:
	_pattern = {
		"grid_data": grid_data.duplicate(true),
		"tile_size": tile_size,
		"repeat_mode": repeat_mode,
		"palette": palette.duplicate()
	}
	pattern_saved.emit()


func get_pattern() -> Dictionary:
	return _pattern


func has_pattern() -> bool:
	return not _pattern.is_empty()


func clear_pattern() -> void:
	_pattern.clear()
