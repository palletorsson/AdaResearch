extends Node3D
const Archive = preload("trace_archive.gd")
const FaceBody = preload("face_body.gd")
const CORNERS := Vector3i(0, 1, 2)
const DEPTH := 0.6
var points: Array[Vector3] = []
var faces: Array[Vector3i] = [
    Vector3i(0, 1, 2), Vector3i(0, 3, 1),
    Vector3i(1, 3, 2), Vector3i(2, 3, 0)]
var body := FaceBody.new()
var message := Label3D.new()

func _ready() -> void:
    add_child(body)
    add_child(message)
    message.position = Vector3(0, 2, 0)
    message.pixel_size = 0.003
    var drawing := Archive.load_drawing()
    if drawing == null:
        message.text = "Bring a drawing from Trace."
        return
    var record: PackedVector3Array = drawing.get_meta("positions")
    drawing.free()
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        if index < 0 or index >= record.size():
            message.text = "Choose three saved indices."
            return
    for index in [CORNERS.x, CORNERS.y, CORNERS.z]:
        points.append(record[index])
    var normal := (points[2] - points[0]).cross(points[1] - points[0])
    if normal.length() < 0.00001 or DEPTH <= 0.0:
        message.text = "Use a valid triangle and a positive depth."
        return
    var centre := (points[0] + points[1] + points[2]) / 3.0
    points.append(centre - normal.normalized() * DEPTH)
    body.show_faces(points, faces)
    message.text = "Four positions; four faces."
