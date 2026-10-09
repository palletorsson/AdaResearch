extends Node3D

const PointHandle = preload("res://prepared/point_handle.gd")
const Segment = preload("res://prepared/segment.gd")
const TraceMemory = preload("res://prepared/trace_memory.gd")
const FaceMaterial = preload("res://prepared/triangle_face.tres")
const EdgeMaterial = preload("res://prepared/triangle_edge.tres")

var positions: Array[Vector3] = []
var handles: Array[PointHandle] = []
var segments: Array[Segment] = []
var face_mesh := ImmediateMesh.new()
var surface := MeshInstance3D.new()
var readout := Label3D.new()

var faces := [
    [0, 1, 2],
    [0, 2, 3],
    [0, 3, 1],
    [1, 3, 2],
]

var edges := [
    [0, 1], [0, 2], [0, 3],
    [1, 2], [2, 3], [3, 1],
]

func _ready():
    add_child(readout)
    readout.position = Vector3(0.0, 2.6, -0.6)
    readout.font_size = 24
    surface.mesh = face_mesh
    surface.material_override = FaceMaterial
    add_child(surface)
    var source_points := TraceMemory.read_trace()
    if source_points.size() < 3:
        readout.text = "Draw a bend in Point Trace, then release to save.\nPolyhedra needs at least three stored positions."
        set_process(false)
        return
    var third := source_points.size() / 3
    var a := source_points[0]
    var b := source_points[third]
    var c := source_points[third * 2]
    var centre := (a + b + c) / 3.0
    positions = [centre + Vector3(0.0, 0.0, -0.7), a, b, c]

    for i in range(positions.size()):
        var handle := PointHandle.new()
        handle.position = positions[i]
        add_child(handle)
        handles.append(handle)
        var label := Label3D.new()
        label.text = str(i)
        label.position.y = 0.14
        label.font_size = 24
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
    if not faces.is_empty():
        face_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
        for triangle in faces:
            for index in triangle:
                face_mesh.surface_add_vertex(positions[index])
        face_mesh.surface_end()
    readout.text = str(positions.size()) + " positions / " + str(faces.size()) + " faces"
