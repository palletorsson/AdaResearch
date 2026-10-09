extends Node3D

const PointHandle = preload("res://prepared/point_handle.gd")
const Segment = preload("res://prepared/segment.gd")
const FaceMaterial = preload("res://prepared/triangle_face.tres")
const EdgeMaterial = preload("res://prepared/triangle_edge.tres")

var positions: Array[Vector3] = []
var faces := [
    [2, 4, 0], [2, 1, 4], [2, 5, 1], [2, 0, 5],
    [3, 0, 4], [3, 4, 1], [3, 1, 5], [3, 5, 0],
]
var edges := [
    [0, 2], [0, 3], [0, 4], [0, 5],
    [1, 2], [1, 3], [1, 4], [1, 5],
    [2, 4], [2, 5], [3, 4], [3, 5],
]
var handles: Array[PointHandle] = []
var segments: Array[Segment] = []
var face_mesh := ImmediateMesh.new()
var surface := MeshInstance3D.new()

func octahedron_positions(radius: float) -> Array[Vector3]:
    var directions: Array[Vector3] = [
        Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1),
    ]
    var points: Array[Vector3] = []
    for direction in directions:
        points.append(direction * radius)
        points.append(-direction * radius)
    return points

func _ready():
    positions = octahedron_positions(0.55)
    surface.mesh = face_mesh
    add_child(surface)
    for i in range(positions.size()):
        var handle := PointHandle.new()
        handle.position = positions[i]
        add_child(handle)
        handles.append(handle)
        var label := Label3D.new()
        label.text = str(i)
        label.position.y = 0.14
        label.font_size = 22
        label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
        label.no_depth_test = true
        handle.add_child(label)
    for edge in edges:
        var segment := Segment.new()
        segment.material_override = EdgeMaterial
        add_child(segment)
        segments.append(segment)

func _process(_delta):
    for i in range(handles.size()):
        positions[i] = handles[i].position
    for i in range(edges.size()):
        var edge = edges[i]
        segments[i].show_between(positions[edge[0]], positions[edge[1]])
    face_mesh.clear_surfaces()
    face_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, FaceMaterial)
    for triangle in faces:
        for index in triangle:
            face_mesh.surface_add_vertex(positions[index])
    face_mesh.surface_end()
