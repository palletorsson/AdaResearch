extends Node3D

const TraceMemory = preload("res://prepared/trace_memory.gd")
const TraceComparison = preload("res://prepared/trace_comparison.gd")

var source_points: Array[Vector3] = []
var grid_points: Array[Vector3] = []
var grid_size := 0.25
var comparison := TraceComparison.new()

func _ready():
    add_child(comparison)
    if grid_size <= 0.0:
        comparison.show_message("Use a positive grid_size.")
        return
    source_points = TraceMemory.read_trace()
    if source_points.is_empty():
        comparison.show_message("Draw in Point Trace, then release to save.\nOpen Point Grid again to see your trace here.")
        return
    for p in source_points:
        var address := Vector3i(
            roundi(p.x / grid_size),
            roundi(p.y / grid_size),
            roundi(p.z / grid_size)
        )
        var placed := Vector3(address) * grid_size
        grid_points.append(placed)
    comparison.show_traces(source_points, grid_points, grid_size)
