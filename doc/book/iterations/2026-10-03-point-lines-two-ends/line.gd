extends Node3D

const PointHandle = preload("res://prepared/point_handle.gd")
const Segment = preload("res://prepared/segment.gd")

var a := PointHandle.new()
var b := PointHandle.new()
var segment := Segment.new()
var displacement_readout := Label3D.new()
var distance_readout := Label3D.new()

func _ready():
    a.position = Vector3(-0.75, 1.12, 0.0)
    b.position = Vector3(0.75, 1.12, 0.0)
    add_child(a)
    add_child(b)
    add_child(segment)

    displacement_readout.position = Vector3(0.0, 2.25, -0.6)
    add_child(displacement_readout)
    distance_readout.position = Vector3(0.0, 1.9, -0.6)
    add_child(distance_readout)

func _process(_delta):
    var displacement := b.position - a.position
    var distance := displacement.length()
    segment.show_between(a.position, b.position)
    displacement_readout.text = str(displacement)
    distance_readout.text = "%.2f m" % distance
