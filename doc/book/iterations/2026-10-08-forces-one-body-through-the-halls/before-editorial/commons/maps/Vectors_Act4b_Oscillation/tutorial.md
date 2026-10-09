# Release the point; keep the attachment

**Learning elements**

- Rest length
- Hooke’s law
- Damping
- Equilibrium
- Force versus constraint

One central point hangs from the frame. Pull its rose grip and release. The force-transmitting grip leaves the constrained body in the simulation. ONE / MANY brings back the other six points and their coupling springs. The hinged swings stay nearby for comparison.

## Continue the object

Reconstruct one spring using the familiar pickable point. While you hold this small study’s point, the hand places it; release returns it to physics. This intentionally simpler hand boundary differs from the museum’s force-transmitting rose grip. The spring always refers to the same anchor. A thin cylinder draws the attachment; it is not the force.

Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code](../../../doc/book/course/forces-shared-code.md). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.

Save the following as `06_spring.gd` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.

## Complete continuation — 06_spring.gd

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

## Read what changes

The offset points from the body to the anchor. Subtracting rest length gives extension, which can be negative under compression. Stiffness converts extension into force. Damping subtracts a term proportional to velocity. Gravity is supplied by the engine, so the hanging equilibrium is longer than the spring’s unloaded rest length. The zero-length guard keeps direction finite; the 150 N cap bounds the authored model. A hinge is different: it constrains a pivot instead of applying this extensible spring law.

## Try another beginning

Keep stiffness and the release position fixed; change damping from 0.5 to 3.0. Predict less persistent motion. Then restore damping and double stiffness. The return should be stronger for the same extension; rest length itself has not changed.

## Carry onward

A spring can repeat because forces continually change velocity. In Choreography, a similar repetition will come from assigning positions.

[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/Vectors_Act4b_Oscillation/tutorial.md).
