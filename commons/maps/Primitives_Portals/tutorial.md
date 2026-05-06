# Primitives Portals

A portal links two points. Enter one, exit the other, regardless of the distance between them.

Define a portal pair.

```gdscript
class_name Portal extends Area3D

@export var linked_portal: Portal

func _on_body_entered(body: Node3D) -> void:
    if linked_portal:
        body.global_position = linked_portal.global_position
```

Two portals reference each other. Entering one moves the body to the other.

Preserve the entry orientation.

```gdscript
func _on_body_entered(body: Node3D) -> void:
    if linked_portal == null: return
    var entry_offset: Vector3 = body.global_position - global_position
    var entry_rotation: Basis = body.global_transform.basis
    body.global_position = linked_portal.global_position + entry_offset
    body.global_transform.basis = entry_rotation
```

The offset relative to the entry portal is preserved. The body arrives at the exit with the same orientation it entered.

Handle velocity transfer.

```gdscript
func _on_body_entered(body: RigidBody3D) -> void:
    if linked_portal == null: return
    body.global_position = linked_portal.global_position
    # Velocity reorients if portals face different directions
    var in_to_out_rotation: Basis = linked_portal.global_transform.basis * global_transform.basis.inverse()
    body.linear_velocity = in_to_out_rotation * body.linear_velocity
```

When the two portals face different directions, the body's velocity rotates through the difference. The direction is preserved relative to each portal's local frame.

Prevent immediate re-entry.

```gdscript
var cooldown_for_bodies: Dictionary = {}  # body -> time_last_teleported
const COOLDOWN_MS := 100

func can_teleport(body: Node) -> bool:
    var now: int = Time.get_ticks_msec()
    if body in cooldown_for_bodies and now - cooldown_for_bodies[body] < COOLDOWN_MS:
        return false
    cooldown_for_bodies[body] = now
    return true
```

Without the cooldown, a body might teleport, land inside the exit portal, and teleport back immediately. The cooldown ensures one-way passage.

Visualise the portal mouth.

```gdscript
func _ready() -> void:
    var mouth := MeshInstance3D.new()
    mouth.mesh = QuadMesh.new()
    mouth.mesh.size = Vector2(1.5, 2.0)
    var mat := StandardMaterial3D.new()
    mat.emission_enabled = true
    mat.emission = Color.CYAN
    mouth.material_override = mat
    add_child(mouth)
```

A glowing quad marks the portal's location. The colour of each portal matches its pair.

Render what lies beyond the portal.

```gdscript
func setup_portal_camera() -> void:
    var cam := Camera3D.new()
    cam.position = linked_portal.global_position
    var viewport := SubViewport.new()
    viewport.add_child(cam)
    # Render to texture, apply as portal surface material
```

A SubViewport renders the scene from the linked portal's position. The rendered image maps onto the entry portal's surface, showing the destination as seen from the other side.

Test for a valid portal pair.

```gdscript
func is_valid_pair() -> bool:
    if linked_portal == null: return false
    if linked_portal.linked_portal != self: return false
    return true
```

Both portals must reference each other. One-way links would allow entry but not return.

You can now link two points in space, preserving orientation and velocity through the passage, with correct cooldown and visualisation. Primitives_Melencolia will next place geometric primitives in a Dürer-referenced still-life scene.
