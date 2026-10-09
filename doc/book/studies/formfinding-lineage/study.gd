extends Node3D
# Supplied display/control furniture; no motion or force calculation.
const Point = preload("point_body.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
var buttons: Dictionary = {}

func caption(words: String, at := Vector3(0, 1.8, -0.5)) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = 36
    text.pixel_size = 0.004
    text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(text)
    return text

func button(title: String, at: Vector3, action: Callable) -> void:
    var control = PushButton.instantiate()
    control.position = at
    control.rotation.x = -PI / 2.0
    add_child(control)
    control.pressed.connect(action)
    buttons[title] = control
    caption(title, at + Vector3.UP * 0.16)

func rod() -> MeshInstance3D:
    var surface := MeshInstance3D.new()
    var shape := CylinderMesh.new()
    shape.top_radius = 0.015
    shape.bottom_radius = 0.015
    shape.height = 1.0
    surface.mesh = shape
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("ef87bc")
    surface.material_override = material
    add_child(surface)
    return surface

func join(surface: MeshInstance3D, a: Vector3, b: Vector3) -> void:
    var d := b - a
    surface.visible = d.length() > 0.0001
    if not surface.visible:
        return
    surface.position = (a + b) / 2.0
    surface.quaternion = Quaternion(Vector3.UP, d.normalized())
    surface.scale = Vector3(1, d.length(), 1)

func make_point(at: Vector3, can_hold := true) -> Node3D:
    var point := Point.new()
    point.position = at
    if not can_hold:
        point.collision_layer = 0
        point.collision_mask = 0
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("16141b")
    material.roughness = 0.22
    for child in point.get_children():
        if child is MeshInstance3D:
            child.material_override = material
    add_child(point)
    return point

func landscape_surface(valleys: bool) -> MeshInstance3D:
    var field = preload("landscape.gd")
    var surface := SurfaceTool.new()
    surface.begin(Mesh.PRIMITIVE_TRIANGLES)
    for x in 24:
        for z in 24:
            var a := Vector2(-3 + x * 0.25, -3 + z * 0.25)
            var b := a + Vector2(0.25, 0)
            var c := a + Vector2(0.25, 0.25)
            var d := a + Vector2(0, 0.25)
            for p in [a, c, b, a, d, c]:
                surface.add_vertex(field.plot(p, valleys))
    surface.generate_normals()
    var mesh := MeshInstance3D.new()
    mesh.mesh = surface.commit()
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("a4bccc")
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    mesh.material_override = material
    add_child(mesh)
    return mesh
