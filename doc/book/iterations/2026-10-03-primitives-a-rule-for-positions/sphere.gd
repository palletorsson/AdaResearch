extends Node3D

const MeshEdges = preload("res://prepared/mesh_edges.gd")
const FaceMaterial = preload("res://prepared/triangle_face.tres")

var sphere_mesh := SphereMesh.new()
var surface := MeshInstance3D.new()
var edge_view := MeshEdges.new()

func _ready():
    sphere_mesh.radius = 0.55
    sphere_mesh.height = 1.1
    sphere_mesh.radial_segments = 8
    sphere_mesh.rings = 4
    surface.mesh = sphere_mesh
    surface.material_override = FaceMaterial
    add_child(surface)
    add_child(edge_view)
    edge_view.show_edges(sphere_mesh)
