extends Node3D

const PointHandle = preload("res://prepared/point_handle.gd")
const Segment = preload("res://prepared/segment.gd")
const TraceMemory = preload("res://prepared/trace_memory.gd")
const FaceMaterial = preload("res://prepared/triangle_face.tres")
const EdgeMaterial = preload("res://prepared/triangle_edge.tres")

var source_points: Array[Vector3] = []
var a := PointHandle.new()
var b := PointHandle.new()
var c := PointHandle.new()
var ab := Segment.new()
var bc := Segment.new()
var ca := Segment.new()
var face_mesh := ImmediateMesh.new()
var face := MeshInstance3D.new()
var readout := Label3D.new()
var show_face := false

func _ready():
    for node in [a, b, c, ab, bc, ca, face, readout]:
        add_child(node)
    face.mesh = face_mesh
    face.material_override = FaceMaterial
    for edge in [ab, bc, ca]:
        edge.material_override = EdgeMaterial
    readout.position = Vector3(0.0, 2.4, -0.6)
    readout.font_size = 24
    source_points = TraceMemory.read_trace()
    if source_points.size() < 3:
        readout.text = "Draw a bend in Point Trace, then release to save.\nTriangle needs at least three stored positions."
        for node in [a, b, c, ab, bc, ca, face]:
            node.hide()
        set_process(false)
        return
    var third := source_points.size() / 3
    a.position = source_points[0]
    b.position = source_points[third]
    c.position = source_points[third * 2]
    readout.text = "From your trace: entries 0, %d, %d" % [third, third * 2]

func _process(_delta):
    ab.show_between(a.position, b.position)
    bc.show_between(b.position, c.position)
    ca.show_between(c.position, a.position)
    face_mesh.clear_surfaces()
    if show_face:
        face_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
        face_mesh.surface_add_vertex(a.position)
        face_mesh.surface_add_vertex(b.position)
        face_mesh.surface_add_vertex(c.position)
        face_mesh.surface_end()
