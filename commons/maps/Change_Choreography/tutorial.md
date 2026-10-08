# The same return, a different cause

**Learning elements**

- Period
- Phase
- Relative rate
- Accumulated angle
- Prescribed motion

Watch the rods turn together, then notice one that is out of step. Look back toward the spring. Both repeat. What keeps each one moving?

## Make the small study

Use two sphere points as the tips of two arms. Give each an angle and a turning rate. OFFSET changes one angle once; DRIFT changes how quickly that angle advances.

**The hall adds:** The hall adds a whole rod array and eyes that follow you. The conveyor nearby shows what repeated arrivals can do to a physical queue.

Save `07_phase.gd` beside your shared files and use it on `PointStudy`. [Setup and complete shared code](../../../doc/book/course/forces-shared-code.md).

## Complete code — 07_phase.gd

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

## Read the change

`angles` stores where each arm is in its turn. `rates` stores how much angle it gains per second. `TAU` is one full turn, so `TAU / 6` completes it in six seconds.

Each frame adds rate times `delta`. The `sin` and `cos` you met in periodic motion turn the angle into a position on a circle. The point is frozen and has no collision; the script places it.

OFFSET adds 45° to one angle. With equal rates, the gap stays fixed. DRIFT raises one rate by 4%, so the gap keeps growing. `fposmod` wraps angles after each complete turn.

## Change one thing

Press OFFSET with equal rates and watch the 45° gap persist. Restart, press DRIFT and wait thirty seconds: predict an added gap of 72°. Change the rate difference to 2% and predict 36°.

## Model notes

The study accumulates angle so a rate change preserves the current position. The museum’s full rod array calculates angle from elapsed time, frequency and phase; changing frequency there can cause a jump. Neither calculation applies a spring force or torque.

## Into the next room

A circular path can be prescribed. Next, let two points attract each other and see what path results.

[Reflective text](final.md).
