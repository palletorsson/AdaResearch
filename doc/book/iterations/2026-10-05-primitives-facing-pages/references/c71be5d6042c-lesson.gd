extends Node3D
const FaceBody = preload("face_body.gd")
# Connectivity is supplied; this lesson generates the positions.
const FACES: Array[Vector3i] = [
    Vector3i(2, 0, 4), Vector3i(2, 4, 1),
    Vector3i(2, 1, 5), Vector3i(2, 5, 0),
    Vector3i(3, 4, 0), Vector3i(3, 1, 4),
    Vector3i(3, 5, 1), Vector3i(3, 0, 5)]
var small_points: Array[Vector3] = []
var large_points: Array[Vector3] = []

func _ready() -> void:
    small_points = octahedron_positions(0.3)
    large_points = octahedron_positions(0.6)
    var small := FaceBody.new()
    var large := FaceBody.new()
    small.position = Vector3(-0.7, 1.1, 0)
    large.position = Vector3(0.7, 1.1, 0)
    add_child(small)
    add_child(large)
    small.show_faces(small_points, FACES)
    large.show_faces(large_points, FACES)

func octahedron_positions(radius: float) -> Array[Vector3]:
    assert(radius > 0.0)
    var result: Array[Vector3] = []
    for axis in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
        result.append(axis * radius)
        result.append(-axis * radius)
    return result
