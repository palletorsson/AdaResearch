# Form Finding — working inside the museum

Continue after Forces in the existing Endless Museum. Try the primary exhibit, reconstruct its selected operation, then make another experiment. The remaining exhibits belong to the wider inquiry; you do not need to rebuild every one.

Keep the point class from Lines and Coordinates. A class and saved code travel onward; this does not imply that the museum automatically carries a single physical instance between halls. Use your existing PointStudy Node3D and replace its lesson script. Place it in the stated clear bay under the current hall, at unit scale with Y up. If your scene uses a saved study instance rather than a runtime hall child, give it the same world transform as that hall-local position. Do not put it under a scaled artifact.

All four shared files below and the current lesson script live in one folder. Descent introduces landscape.gd; Annealing reuses it unchanged. The already installed XRToolsPickable class and res://commons/interactables/push_button.tscn are declared museum dependencies. No unnamed node or dollar reference is required.

PointBody still supplies a sphere, boundary and pickup. make_point adds its black material. Markers have collision disabled; endpoint points remain grabbable and stay where released. The rod, caption, button and sampled surface are display helpers, printed below in full. None chooses a search step, relaxes a chain, balances a lever or judges a construction. Those operations remain in the lessons.

The cube helper repeats the earlier mesh-and-collider construction using BoxMesh. It releases into Jolt physics. Its contact geometry is part of the environment for the last lesson; the acceptance rule remains yours to inspect.

## point_body.gd

<!-- student-code:point_body.gd -->

```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```

## study.gd

<!-- student-code:study.gd -->

```gdscript
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
```

## landscape.gd

<!-- student-code:landscape.gd -->

```gdscript
extends RefCounted
# The same two functions used by the hall's descent landscape.
static func cost(p: Vector2, valleys: bool) -> float:
    if valleys:
        return 0.08 * pow(p.x * p.x - 4.0, 2) + 0.25 * p.y * p.y + 0.15 * p.x
    return 0.25 * p.length_squared()

static func gradient(p: Vector2, valleys: bool) -> Vector2:
    var h := 0.03
    var x := Vector2(h, 0)
    var y := Vector2(0, h)
    return Vector2(cost(p + x, valleys) - cost(p - x, valleys),
        cost(p + y, valleys) - cost(p - y, valleys)) / (2.0 * h)

static func plot(p: Vector2, valleys: bool) -> Vector3:
    return Vector3(p.x * 0.45, 0.9 + 0.12 * cost(p, valleys), p.y * 0.45)
```

## cube_body.gd

<!-- student-code:cube_body.gd -->

```gdscript
extends XRToolsPickable
# The earlier grabbable body's construction, now with a cube mesh and boundary.
func _init() -> void:
    collision_layer = 4
    collision_mask = 196615
    mass = 1.0
    release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
    var surface := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = Vector3.ONE * 0.2
    surface.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("ee84b8")
    surface.material_override = material
    add_child(surface)
    var boundary := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = mesh.size
    boundary.shape = shape
    add_child(boundary)
```

