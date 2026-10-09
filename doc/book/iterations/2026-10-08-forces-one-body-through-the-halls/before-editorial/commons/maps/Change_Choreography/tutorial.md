# The same return, a different cause

**Learning elements**

- Period
- Phase
- Relative rate
- Accumulated angle
- Prescribed motion

The rods turn together; one offset becomes visible against their agreement. Their eyes follow you without causing the rods to turn. Look back toward the spring. Both repeat, but the repetition is being made differently. Beside the rods, the conveyor lets timing accumulate as a physical queue.

## Continue the object

Keep two sphere points as the tips of two thin arms. Freeze them and remove collision for this diagram. Store one angle for each arm. OFFSET changes an angle once; DRIFT changes how much one angle gains each second. The small study uses accumulated angles so a rate edit preserves current position.

Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code](../../../doc/book/course/forces-shared-code.md). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.

Save the following as `07_phase.gd` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.

## Complete continuation — 07_phase.gd

<!-- student-code:07_phase.gd -->

```gdscript
extends "study.gd"
var points: Array[RigidBody3D] = []
var arms: Array[MeshInstance3D] = []
var angles := [0.0, 0.0]
var rates := [TAU / 6.0, TAU / 6.0]
var reading: Label3D

func _ready() -> void:
    for i in range(2):
        var point = Point.new()
        add_child(point)
        point.freeze = true
        point.enabled = false
        point.collision_layer = 0
        point.collision_mask = 0
        points.append(point)
        arms.append(rod())
    reading = caption("")
    button("OFFSET", Vector3(-0.5, 1, -0.8), offset)
    button("DRIFT", Vector3(0.5, 1, -0.8), drift)

func offset() -> void:
    angles[1] += PI / 4.0

func drift() -> void:
    rates[1] = TAU / 6.0 * 1.04

func _process(delta: float) -> void:
    for i in range(2):
        angles[i] = fposmod(angles[i] + rates[i] * delta, TAU)
        var pivot := Vector3(i * 1.6 - 0.8, 1.3, 0)
        points[i].position = pivot + Vector3(sin(angles[i]), cos(angles[i]), 0) * 0.6
        join(arms[i], pivot, points[i].position)
    reading.text = "gap %.1f degrees · prescribed position" % rad_to_deg(
        fposmod(angles[1] - angles[0], TAU))
```

## Read what changes

A six-second period means `TAU / 6` radians per second. Each update adds rate times delta. `sin` and `cos` place the tip on a circle. They do not calculate torque. `fposmod` keeps displayed angles within one turn and discards whole-turn counts. Equal rates preserve a phase offset; unequal rates grow it. The full phase-rod array evaluates angle from elapsed time, frequency and phase; changing its frequency can jump phase. This small continuation deliberately preserves angle, like the paired-time study. Keep that difference visible.

## Try another beginning

Apply OFFSET while rates are equal: the 45° gap remains. Restart, apply DRIFT, and wait thirty seconds: the 4% rate difference adds 72°. Halve that difference to 2% and predict 36°. A new input changes one term, not every part of the study.

## Carry onward

Keep the distinction between authored position and simulated force. The next two points attract each other; neither is assigned a circular path.

[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/Change_Choreography/tutorial.md).
