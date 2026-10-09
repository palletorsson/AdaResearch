extends Node3D
const PointBody = preload("point_body.gd")
const FaceBody = preload("face_body.gd")
const Archive = preload("trace_archive.gd")
const CORNERS := Vector3i(0, 1, 2)
var handles: Array[Node3D] = []
var points: Array[Vector3] = []
var face := FaceBody.new()
var message := Label3D.new()

func _ready() -> void:
    add_child(face)
    add_child(message)
    message.position = Vector3(0, 2, 0)
    message.font_size = 32
    message.pixel_size = 0.003
    var drawing := Archive.load_drawing()
    if drawing == null:
        message.text = "Return to Trace; draw and release the point."
        return
    var record: PackedVector3Array = drawing.get_meta("positions")
    drawing.free()
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        if index < 0 or index >= record.size():
            message.text = "Choose three indices inside the saved record."
            return
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        var point := PointBody.new()
        point.position = record[index]
        add_child(point)
        handles.append(point)

func _process(_delta: float) -> void:
    if handles.size() != 3:
        return
    var current: Array[Vector3] = []
    for point in handles:
        current.append(point.position)
    if current == points:
        return
    points = current
    if face.show_faces(points, [Vector3i(0, 1, 2)]):
        message.text = "Three positions; one face."
    else:
        message.text = "Separate the corners; lift one off the line."
