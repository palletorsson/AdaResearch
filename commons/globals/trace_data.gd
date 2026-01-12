extends Node

# Stores traces. Each trace is an Array of Vector3 points.
var saved_traces: Array = []

signal trace_added(points: Array)

func _ready() -> void:
	print("TraceData: Autoload Singleton READY")

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
