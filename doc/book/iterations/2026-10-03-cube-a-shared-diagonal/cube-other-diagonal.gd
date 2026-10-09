extends Node3D

const PointHandle = preload("res://prepared/point_handle.gd")
const Segment = preload("res://prepared/segment.gd")
const FaceMaterial = preload("res://prepared/triangle_face.tres")
const FoldMaterial = preload("res://prepared/cube_fold.tres")
const EdgeMaterial = preload("res://prepared/triangle_edge.tres")
const DiagonalMaterial = preload("res://prepared/cube_diagonal.tres")

var positions: Array[Vector3] = [
    Vector3(-0.5, 0.8, -0.5), # 0
    Vector3(0.5, 0.8, -0.5),  # 1
    Vector3(0.5, 1.8, -0.5),  # 2
    Vector3(-0.5, 1.8, -0.5), # 3
    Vector3(-0.5, 0.8, 0.5),  # 4
    Vector3(0.5, 0.8, 0.5),   # 5
    Vector3(0.5, 1.8, 0.5),   # 6
    Vector3(-0.5, 1.8, 0.5),  # 7
]

var faces := [
    [4, 5, 6], [4, 6, 7],
    [0, 1, 4], [1, 5, 4],
    [2, 3, 6], [3, 7, 6],
    [1, 0, 2], [0, 3, 2],
    [0, 4, 3], [4, 7, 3],
    [5, 1, 6], [1, 2, 6],
]

var edges := [
    [0, 1], [1, 2], [2, 3], [3, 0],
    [4, 5], [5, 6], [6, 7], [7, 4],
    [0, 4], [1, 5], [2, 6], [3, 7],
]

var diagonal_pair := [4, 6]
var corner_shift := 0.35
var show_diagonal := true
var show_faces := true
var handles: Array[PointHandle] = []
var segments: Array[Segment] = []
var face_mesh := ImmediateMesh.new()
var surface := MeshInstance3D.new()
var diagonal := Segment.new()
var readout := Label3D.new()

func _ready():
    positions[6].z += corner_shift
    surface.mesh = face_mesh
    add_child(surface)
    diagonal.material_override = DiagonalMaterial
    add_child(diagonal)
    readout.position = Vector3(0.0, 2.65, -0.6)
    readout.font_size = 24
    readout.text = "8 corners / 12 boundary edges / 12 triangles"
    add_child(readout)
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
    diagonal.show_between(positions[diagonal_pair[0]], positions[diagonal_pair[1]])
    diagonal.visible = show_diagonal and diagonal.visible
    face_mesh.clear_surfaces()
    if show_faces:
        for i in range(faces.size()):
            var triangle = faces[i]
            var material := FaceMaterial
            if i == 1:
                material = FoldMaterial
            face_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, material)
            for index in triangle:
                face_mesh.surface_add_vertex(positions[index])
            face_mesh.surface_end()
