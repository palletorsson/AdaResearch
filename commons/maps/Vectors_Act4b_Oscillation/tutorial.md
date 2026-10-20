# Release the point; keep the attachment

**Learning elements**

- Rest length
- Spring force
- Damping
- Equilibrium
- Spring and hinge

Pull the rose grip beside the hanging point and release. The point returns, passes its resting place and turns again. The grip lets you pull while the spring keeps acting.

## Make the small study

Make one spring from the familiar point and a fixed anchor. In your small study, grab the point itself to set its position, then release it to see the spring act. The thin cylinder shows the attachment.

**The hall adds:** The hall’s separate rose grip pulls through force while you hold it. ONE / MANY adds six more points and connecting springs. Nearby hinges offer a different kind of attachment.

Save `06_spring.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](../../../doc/book/course/forces-shared-code.md).

## Complete code — 06_spring.gd

<!-- student-code:06_spring.gd -->

```gdscript
extends "study.gd"
const ANCHOR := Vector3(0, 2.8, 0)
var point = Point.new()
var rest_length := 1.0
var stiffness := 20.0 # N/m
var damping := 0.5 # kg/s
var tether: MeshInstance3D

func _ready() -> void:
    add_child(point)
    point.position = Vector3(0.5, 1.8, 0)
    point.gravity_scale = 1.0
    tether = rod()
    caption("Pull the point. Release it. The spring keeps its anchor.")

func spring_force(offset: Vector3, velocity: Vector3) -> Vector3:
    var length := offset.length()
    if length < 0.0001:
        return -damping * velocity
    return (offset / length * (length - rest_length) * stiffness
        - damping * velocity).limit_length(150.0)

func _physics_process(_delta: float) -> void:
    var offset: Vector3 = to_global(ANCHOR) - point.global_position
    if not point.is_picked_up():
        point.apply_central_force(spring_force(offset, point.linear_velocity))
    join(tether, point.position, ANCHOR)
```

## Read the change

`offset` points from the body to the anchor. Its length tells us their current separation. Subtract `rest_length` to find how far the spring is stretched or compressed.

Multiplying that difference by `stiffness` gives the force magnitude. The normalized offset gives its direction. A stretched spring pulls toward the anchor; compression reverses the sign.

The last term subtracts `damping * velocity`. It opposes movement, so the returns gradually settle. Gravity still acts: the hanging point rests with the spring stretched enough to support its weight.

At rest under the anchor, the stretch is `mass * gravity / stiffness`, provided the spring force is below its cap and no contact supports the point. Its equilibrium length is therefore longer than `rest_length`. The rail comparison in the reflective text removes gravity, so its equilibrium is the unstretched position. Keep those two experiments distinct.

## Change one thing

Release from the same position with damping at 0.5, then at 3.0. Predict which will keep moving longer. Restore damping and double stiffness. Compare the stronger return without changing rest length.

## Return to the hall

Return to the full row with ONE / MANY. Pull one grip and follow the movement into its neighbours. Try releasing a second point while the first is still moving. Each spring follows its rule, but the next movement now depends on several bodies.

## Model notes

The zero-length check avoids dividing by zero; the force is capped at 150 N. The student point is placed by the hand while held, and resumes spring motion on release. A hinge keeps a pivot attached; this spring permits its length to change.

## Into the next room

Here a repeating movement comes from forces changing velocity. Next, make a similar repetition by assigning positions.

[Reflective text](final.md).


<!-- @pendulum_noise -->
## Optional comparison — a recorded push

**Learning elements:** common initial state; saved force input; tangential projection; matched damping comparison; replay; finite settling criterion.

Between the spring row and the swings, pull either black point and release. Both begin from the same angle. First compare external force off/on with matching damping. Then use MODE to send the same saved four-second push to both and change only B's damping. The motion continues for twenty seconds; the trace distinguishes the end of a push from the end of its consequence. These are angular models, not engine hinges. The primary spring lesson above remains the hall's first reconstruction.

The [complete companion tutorial](../../artifacts/pendulum_noise/tutorial.md) prints the model, unchanged point class, constrained hand extension, full apparatus and scene. It declares the existing museum controls and includes independent zero-input and equal-parameter cases. Randomness/Noise later returns to how the saved input is produced.
