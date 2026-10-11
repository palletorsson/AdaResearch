# The player becomes the receiver

**Learning elements**

- Pickup and trigger actions
- Hand direction
- Player acceleration
- Combining two inputs
- Continued velocity

Take the two black points. Aim where you want to travel and hold the triggers. Let go of the triggers while keeping hold of the points. The thrust ends; your movement continues under gravity and contact.

## Make the small study

Extend the familiar point into a thruster. While held and activated, it reports an acceleration in the direction of your hand. The small station script creates two of these points.

**The hall adds:** The existing capability court supplies the player movement, collisions, gravity and visor. Your new code supplies the held action, direction and identity of the player who receives it.

Save `11_flight.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](../../../doc/book/course/forces-shared-code.md).

Work inside the existing capability court, whose movement adapter is required for flight. Save `thrust_point.gd` beside the other files.

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

## Complete code — 11_flight.gd

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

## Read the change

`action_pressed` turns firing on while the point is held. Releasing the trigger or dropping the point turns it off. `held()` reports whether someone has picked it up.

`receiver()` follows the holding controller to its XR origin, then finds the player body under that origin. This connects the action to the player whose hand holds the point.

`acceleration()` reads the controller’s forward direction, local -Z, and multiplies it by 11 m/s². When firing stops, it returns zero. It does not clear the player’s velocity.

Adding the point to `ada_thrust_points` lets the existing court find it. The court asks each held point who its receiver is and what acceleration it requests. Two aligned points request 22 m/s²; opposed directions cancel. The court combines those requests, adds gravity once and moves the player with collisions.

## Change one thing

Aim one hand up and one down. Before pressing, predict that the two thrusts cancel while gravity still acts. Then aim both upward: their 22 m/s² request exceeds the court’s 9.8 m/s² gravity. Release the triggers and watch how velocity continues to change.

## Model notes

Compare the court with the outlined field in the reflective text. That field selects receivers by location and replaces ordinary gravity inside its boundary. Here the held point selects its player and requests thrust only while activated; the court adds gravity to that request. Both change retained velocity, but they choose receivers and combine influences differently.

Mount this study inside the loaded capability court. Its FieldCarryAdapter owns player movement; the points do not set the camera position. The required connection is `receiver()`, `acceleration()` and `held()` in the `ada_thrust_points` group. This small script uses XR hands; the museum version also supports a desktop pointer. Physical headset comfort still needs a playtest.

## Into the next room

The point now gives you a capacity in the world. Direction, acceleration, resistance and contact are things you can use together. The racer and the larger experiments give you places to try.

[Reflective text](final.md).
