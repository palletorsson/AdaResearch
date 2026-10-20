extends "bench.gd"
var was_held := false
var hand_at := Vector3.ZERO

func _process(_delta: float) -> void:
    if point.held():
        was_held = true
        hand_at = to_local(point.global_position)
        drag(hand_at)
    elif was_held:
        was_held = false
        release(hand_at)
    if not point.held(): point.position = point_home

func drag(_at: Vector3) -> void: pass
func release(_at: Vector3) -> void: pass

func dot(at: Vector3, colour: Color, radius: float = .035) -> void:
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius*2
    var visual := MeshInstance3D.new()
    visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    visual.material_override = material
    visual.position = at
    drawing.add_child(visual)
