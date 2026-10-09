# The player becomes the receiver

**Learning elements**

- Held actions
- Controller direction
- Acceleration requests
- Receiver ownership
- Continued velocity

Take the two black points in the capability court. Aim where you want to travel and hold the triggers. Release them while you are moving. The acceleration request ends; your acquired motion remains, while gravity and contact continue. The visor can show velocity beside the request.

## Continue the object

Extend the same point once more. The complete thrust_point.gd below reports an acceleration only while held and activated. It identifies the actual XRTools player from the holding controller. The tiny station script creates two instances. Mount this study inside the existing capability court: its already-installed FieldCarryAdapter supplies collision-aware player movement.

Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code](../../../doc/book/course/forces-shared-code.md). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.

Save the following as `11_flight.gd` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.

This last lesson requires the loaded `force_capability_lab` court and its movement adapter; a bare Node3D scene will display the points but will not make a player fly. Save `thrust_point.gd` beside the other files.

### thrust_point.gd

<!-- student-code:thrust_point.gd -->

```gdscript
extends "free_point.gd"
var firing := false

func _ready() -> void:
    super()
    freeze = true
    gravity_scale = 1.0
    add_to_group("ada_thrust_points")
    action_pressed.connect(func(_hand): firing = is_picked_up())
    action_released.connect(func(_hand): firing = false)
    dropped.connect(func(_hand): firing = false)

func held() -> bool:
    return is_picked_up()

func receiver() -> CharacterBody3D:
    var controller := get_picked_up_by_controller()
    if controller == null:
        return null
    var origin := XRHelpers.get_xr_origin(controller)
    for body in get_tree().get_nodes_in_group("player_body"):
        if origin != null and body is XRToolsPlayerBody and origin.is_ancestor_of(body):
            return body
    return null

func acceleration() -> Vector3:
    var controller := get_picked_up_by_controller()
    if not firing or not held() or controller == null:
        return Vector3.ZERO
    return -controller.global_basis.z.normalized() * 11.0
```

## Complete continuation — 11_flight.gd

<!-- student-code:11_flight.gd -->

```gdscript
extends "study.gd"
const ThrustPoint = preload("thrust_point.gd")
var points: Array = []

func _ready() -> void:
    for x in [-0.3, 0.3]:
        var point = ThrustPoint.new()
        point.position = Vector3(x, 1.2, 0)
        add_child(point)
        points.append(point)
    caption("Hold both points. Aim where you want to go. Press triggers.")
```

## Read what changes

The controller’s local -Z is its pointing direction. Each point returns 11 m/s² along that direction. Two aligned points request 22; opposed points cancel. The existing museum receiver sums requests belonging to that player, adds gravity once, and retains velocity through move_player. The point never sets the camera transform. The request uses the museum’s `ada_thrust_points` contract: `receiver()`, `acceleration()` and `held()`. Dropping stops firing. This minimal continuation implements XR hands; the larger museum point also has a desktop pointer adapter.

## Try another beginning

Point one hand up and one down, press both triggers, and predict cancellation of thrust. Gravity still acts. Then aim both upward: 22 m/s² of requested thrust exceeds the court’s 9.8 m/s² gravity. Release without dropping and compare the continuing velocity. Physical headset comfort remains a playtest question.

## Carry onward

The object has become a capacity in the world. It can still be studied through the same distinctions: direction, request, receiver, accumulated state and contact. The racer and large experiments remain places to use those distinctions together.

[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/Vectors_Act5_ForceAsPlace/tutorial.md).
