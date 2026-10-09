extends Node3D

const PointHandle = preload("res://prepared/point_handle.gd")
const TraceDrawing = preload("res://prepared/trace_drawing.gd")

var point := PointHandle.new()
var drawing := TraceDrawing.new()
var readout := Label3D.new()
var points: Array[Vector3] = []
var spacing := 0.08
var capacity := 128

func _ready():
    point.position = Vector3(-0.75, 1.25, 0.0)
    add_child(point)
    add_child(drawing)
    readout.position = Vector3(0.0, 2.4, -0.6)
    add_child(readout)
    points.append(point.position)
    readout.text = str(points.size()) + " positions kept"

func _process(_delta):
    var displacement := point.position - points[-1]
    if displacement.length() >= spacing:
        points.append(point.position)
        if points.size() > capacity:
            points.pop_front()
        drawing.clear()
        for i in range(1, points.size()):
            drawing.join(points[i - 1], points[i])
        readout.text = str(points.size()) + " positions kept"
