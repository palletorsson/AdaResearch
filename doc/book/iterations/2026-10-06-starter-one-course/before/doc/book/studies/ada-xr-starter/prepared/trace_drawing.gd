extends Node3D
## Supplied display. clear() hides the previous drawing; join(a, b) draws a
## segment and marks its stored endpoints. Inputs use this node's parent frame.
## This child stays at identity under Study. It never edits the learner's list.

const Segment = preload("res://prepared/segment.gd")
var strokes: Array[Node3D] = []
var used := 0
var dot_mesh := SphereMesh.new()
var dot_material := StandardMaterial3D.new()

func _init():
    dot_mesh.radius = 0.025
    dot_mesh.height = 0.05
    dot_mesh.radial_segments = 12
    dot_mesh.rings = 6
    dot_material.albedo_color = Color("e399b8")
    dot_material.roughness = 0.55

func clear():
    used = 0
    for stroke in strokes:
        stroke.hide()

func join(a: Vector3, b: Vector3):
    if used == strokes.size():
        var stroke := Node3D.new()
        stroke.add_child(Segment.new())
        for endpoint in range(2):
            var dot := MeshInstance3D.new()
            dot.mesh = dot_mesh
            dot.material_override = dot_material
            stroke.add_child(dot)
        strokes.append(stroke)
        add_child(stroke)
    var stroke := strokes[used]
    stroke.show()
    stroke.get_child(0).show_between(a, b)
    stroke.get_child(1).position = a
    stroke.get_child(2).position = b
    used += 1
