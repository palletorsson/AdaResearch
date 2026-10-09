extends Node3D

const PointHandle = preload("res://prepared/point_handle.gd")
const TraceDrawing = preload("res://prepared/trace_drawing.gd")
const GridRuling = preload("res://prepared/grid_ruling.gd")

var point := PointHandle.new()
var marker := MeshInstance3D.new()
var drawing := TraceDrawing.new()
var ruling := GridRuling.new()
var input_readout := Label3D.new()
var address_readout := Label3D.new()
var placed_readout := Label3D.new()
var points: Array[Vector3] = []
var grid_size := 0.25
var capacity := 128

func _ready():
    point.position = Vector3(0.12, 1.25, 0.0)
    add_child(point)
    var sphere := SphereMesh.new()
    sphere.radius = 0.04
    sphere.height = 0.08
    marker.mesh = sphere
    add_child(marker)
    add_child(drawing)
    add_child(ruling)
    ruling.build(grid_size)
    input_readout.position = Vector3(0.0, 2.65, -0.6)
    address_readout.position = Vector3(0.0, 2.4, -0.6)
    placed_readout.position = Vector3(0.0, 2.15, -0.6)
    add_child(input_readout)
    add_child(address_readout)
    add_child(placed_readout)

func _process(_delta):
    var p := point.position
    var address := Vector3i(
        roundi(p.x / grid_size),
        roundi(p.y / grid_size),
        roundi(p.z / grid_size)
    )
    var placed := Vector3(address) * grid_size
    marker.position = placed
    input_readout.text = "input m  " + str(p)
    address_readout.text = "address  " + str(address)
    placed_readout.text = "placed m  " + str(placed)
    if points.is_empty():
        points.append(placed)
    if placed != points[-1]:
        points.append(placed)
        if points.size() > capacity:
            points.pop_front()
        drawing.clear()
        for i in range(1, points.size()):
            drawing.join(points[i - 1], points[i])
