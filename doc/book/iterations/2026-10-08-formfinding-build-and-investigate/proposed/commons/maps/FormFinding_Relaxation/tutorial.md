# Keep correcting the connection

## Learning elements

- Current and previous positions
- Pinned endpoints
- Distance constraints
- Iteration budget
- Residual error

At the cloth bench, switch WIND off, then compare PASSES. Each choice resets the same cloth. Look at its worst length error as well as its shape. Nearby frozen forms retain the result of earlier corrections; their stillness does not mean the calculation was exact.

## What you bring

Keep the endpoint points, arrays and neighbouring-index loop. Forces supplied gravity, time steps and damping. Here positions and their previous values carry the motion; a separate correction loop enforces approximate lengths.

## Build inside the museum

Reduce the cloth to seven points and six links. Only the endpoints are held. Each STEP advances one fixed 1/60-second model step, then repeats the constraint corrections. The chain has 2.7 m of requested link length across an initial two-metre span, so it has room to hang.

Save `03_relaxation.gd` beside the [complete shared code](../../../doc/book/course/formfinding-shared-code.md), on your existing `PointStudy` Node3D. The inspected working bay is hall-local `(16, 0, 7)` metres, floor level, upright, unit scale. The museum supplies the floor, camera, light, hands and button scene. The larger artifact remains available for comparison.

## Complete code — 03_relaxation.gd

<!-- student-code:03_relaxation.gd -->

```gdscript
extends "study.gd"
const COUNT := 7
const REST := 0.45
const DT := 1.0 / 60.0
var passes := 4
var positions: Array[Vector3] = []
var previous: Array[Vector3] = []
var points: Array[Node3D] = []
var links: Array[MeshInstance3D] = []
var readout: Label3D
var steps := 0

func _ready() -> void:
    for i in COUNT:
        points.append(make_point(Vector3.ZERO, i == 0 or i == COUNT - 1))
        if i > 0:
            links.append(rod())
    readout = caption("", Vector3(0, 2.3, 0))
    button("STEP", Vector3(-0.55, 1, -0.8), step_once)
    button("PASSES", Vector3(0, 1, -0.8), change_passes)
    button("RESET", Vector3(0.55, 1, -0.8), restart)
    restart()

func restart() -> void:
    positions.clear()
    for i in COUNT:
        positions.append(Vector3(-1.0 + 2.0 * i / (COUNT - 1), 1.7, 0))
        points[i].position = positions[i]
    previous = positions.duplicate()
    steps = 0
    redraw()

func change_passes() -> void:
    passes = 12 if passes == 1 else 1
    restart()

func step_once() -> void:
    for i in [0, COUNT - 1]:
        positions[i] = to_local(points[i].global_position)
        previous[i] = positions[i]
    for i in range(1, COUNT - 1):
        var here := positions[i]
        positions[i] += (here - previous[i]) * 0.99 + Vector3.DOWN * 3.0 * DT * DT
        previous[i] = here
    for pass_index in passes:
        for i in COUNT - 1:
            correct_pair(i, i + 1)
    steps += 1
    redraw()

func correct_pair(a: int, b: int) -> void:
    var d := positions[b] - positions[a]
    if d.length() < 0.00001:
        return
    var correction := d * (d.length() - REST) / d.length()
    var wa := 0.0 if a == 0 else 1.0
    var wb := 0.0 if b == COUNT - 1 else 1.0
    positions[a] += correction * wa / (wa + wb)
    positions[b] -= correction * wb / (wa + wb)

func worst_error() -> float:
    var worst := 0.0
    for i in COUNT - 1:
        worst = maxf(worst, absf(positions[i].distance_to(positions[i + 1]) / REST - 1))
    return worst

func redraw() -> void:
    for i in range(1, COUNT - 1):
        points[i].position = positions[i]
    for i in links.size():
        join(links[i], positions[i], positions[i + 1])
    readout.text = "%d passes | step %d\nWorst length error %.2f%%" % [passes, steps, worst_error() * 100]
```

## Read the operation

positions and previous are separate arrays. duplicate() preserves the previous record while the current one changes. For an interior point, here − previous[i] is displacement during the preceding fixed step, not metres per second. Multiplying by 0.99 damps that displacement. Gravity adds acceleration × DT². Jolt does not integrate these interior points.

A link compares its current length with REST. correct_pair moves its ends toward the requested distance. An endpoint has correction weight zero; a free point has weight one. Two free ends split a correction; beside a pin the free end takes it all. The tiny-distance guard avoids dividing by zero. It cannot invent a direction for coincident points.

Later corrections can disturb earlier links, so one pass need not satisfy the entire chain. Repeating the pass reduces the remaining error in this comparison. It costs more work and does not certify every possible configuration. worst_error reports the largest absolute relative length error. Moving either held endpoint supplies a new pin on the next STEP; RESET returns both original pins. PASSES switches to 1, then 12, resetting each time. The initial budget is 4.

## Predict, then change

From RESET, compare one and twelve passes after the same 420 steps. You may drive step_once() with a bounded for loop for this measurement. Predict which budget leaves less worst error. Keep the same pins, time step, initial positions and damping. Do not compare one fresh chain with another that has already been settling.

## Build another experiment

Reconstruct a second chain with the same seven points but only the first point pinned. Update the correction weights and the integration range together so the final point is free. Predict its motion before stepping. Show that the first point stays at its pin and that the last point can move. Then explain why leaving the old endpoint weight at zero would contradict your new model.

## Carry onward

Constraints can shape a configuration through repeated local corrections. Equilibrium next asks when a simpler relation lets you calculate a pose directly.

## Model notes

This study is a fixed-step position solver with no contact response for its interior markers or rods. Keep pins near their initial positions and above the floor. The full cloth includes a two-dimensional spring network and optional wind. The chain is not an exact continuous catenary.
