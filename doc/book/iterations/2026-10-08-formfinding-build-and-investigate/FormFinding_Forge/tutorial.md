# Write what counts

## Learning elements

- Combining conditions
- Measured state
- Accumulated time
- Success criteria
- Counterexamples

At the balance puzzle, make a low quiet arrangement, then a taller one. The detector asks for more than stillness. Turn to the forge’s arriving body and notice that its destination was prescribed in advance. These two forms arrive under different kinds of instruction.

## What you bring

Bring the grabbable cube, engine velocity, conditions, counters and a boolean state. The cube’s complete construction is included with the shared code. The museum floor and XR hands remain the environment.

## Build inside the museum

Make three small physical cubes. Measure their highest corner above the floor and whether they are moving slowly. Accumulate credit when the height and quietness conditions hold; lose credit when movement returns. Keep ACCEPTED visible once reached.

Save `06_criterion.gd` beside the [complete shared code](../../../doc/book/course/formfinding-shared-code.md), on your existing `PointStudy` Node3D. The inspected working bay is hall-local `(16, 0, 7)` metres, floor level, upright, unit scale. The museum supplies the floor, camera, light, hands and button scene. The larger artifact remains available for comparison.

## Complete code — 06_criterion.gd

<!-- student-code:06_criterion.gd -->

```gdscript
extends "study.gd"
const Cube = preload("cube_body.gd")
var cubes: Array[RigidBody3D] = []
var required_height := 0.5
var required_time := 1.5
var credit := 0.0
var accepted := false
var readout: Label3D

func _ready() -> void:
    for i in 3:
        var cube := Cube.new()
        cube.position = Vector3((i - 1) * 0.5, 0.22, 0)
        add_child(cube)
        cubes.append(cube)
    readout = caption("", Vector3(0, 1.8, 0))
    button("RESET", Vector3(0, 1, -0.8), restart)

func restart() -> void:
    credit = 0.0
    accepted = false
    for i in cubes.size():
        cubes[i].position = Vector3((i - 1) * 0.5, 0.22, 0)
        cubes[i].rotation = Vector3.ZERO
        cubes[i].linear_velocity = Vector3.ZERO
        cubes[i].angular_velocity = Vector3.ZERO

func observe(height: float, quiet: bool, delta: float) -> void:
    if accepted:
        return
    if height < required_height:
        credit = 0.0
    elif quiet:
        credit += delta
    else:
        credit = maxf(0, credit - delta * 2.0)
    accepted = credit >= required_time

func _physics_process(delta: float) -> void:
    var height := 0.0
    var quiet := true
    for cube in cubes:
        # Transform all corners: a turned cube has another vertical extent.
        for x in [-0.1, 0.1]:
            for y in [-0.1, 0.1]:
                for z in [-0.1, 0.1]:
                    height = maxf(height, to_local(cube.to_global(Vector3(x, y, z))).y)
        quiet = quiet and cube.linear_velocity.length() <= 0.05 and cube.angular_velocity.length() <= 0.1
        quiet = quiet and not cube.is_picked_up()
    observe(height, quiet, delta)
    readout.text = "%s | top %.3f / %.3f m\nQuiet credit %.2f / %.2f s" % [
        "ACCEPTED" if accepted else "BUILD", height, required_height, credit, required_time]
```

## Read the operation

The eight corners of each cube are transformed into the study’s frame before measuring height, so a turned cube’s top is still measured correctly. The study origin must be on the floor and its axes upright at unit scale. The quiet test checks linear speed in m/s and angular speed in radians/s. It also rejects a held cube, whose low reported rigid-body velocity would otherwise be misleading.

observe is the decision rule separated from measurement. A low result clears credit. A high, quiet result gains delta seconds. A high moving result loses twice delta, down to zero. This follows the museum puzzle’s gain-and-decay idea; it is not a requirement for one perfectly uninterrupted quiet interval. Crossing required_time latches accepted. RESET clears that record and places the cubes separately. Release them before resetting.

The rule measures height and low motion, not whether the cubes support one another or remain inside a tray. A cube resting on an unrelated high ledge could satisfy these measurements. That limitation is part of what you are learning to inspect, not a property to hide behind the word success.

## Predict, then change

Let three separate cubes settle on the floor. They should remain below the 0.5 m threshold. Stack them into a roughly 0.6 m column and let go. Watch the credit rather than assuming the first tall frame will pass. Disturb the stack before acceptance and follow the loss of credit.

## Build another experiment

Author a second criterion that rewards a low arrangement. Keep the physical cubes and the measurement code; change the decision function. Supply one measured situation that the original accepts and yours rejects, and another that reverses that judgment. Test both functions with known height, quietness and time values, then build the two arrangements in the room. State what both criteria still fail to measure.

## Carry onward

An objective, constraint and stopping rule each make a different decision. Keep that distinction when Wavefunctions begins: a continuing oscillation may be a successful behaviour even though it never settles.

## Model notes

The installed puzzle has eight mixed pieces and a walking reward animation. Your study has three cubes and a latched caption. It improves height measurement and excludes held cubes, but does not claim to reproduce every part of the production detector. Its success rule does not certify physical stability for all future disturbances.
