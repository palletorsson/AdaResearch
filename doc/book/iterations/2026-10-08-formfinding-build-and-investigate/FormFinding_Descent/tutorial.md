# Choose the next address

## Learning elements

- Objective function
- Finite-difference gradient
- Update rule
- Distinct stopping conditions

At the large blue surface, press STEP and follow the gold point. The point changes address because a rule proposes another one. In Forces, a released body kept velocity. This search keeps no velocity: every accepted step replaces its two-number address.

## What you bring

Keep the point class, Vector2 and Vector3, functions, conditionals and the controls from Forces. The displayed sphere is a marker here; its collider is disabled. A grabbable point would let a hand move the picture without changing the search address.

## Build inside the museum

Reconstruct the STEP operation and both cost functions. The supplied display samples the same functions into a small surface; it does not decide the step. A Vector2 holds the search coordinates. Its second component becomes spatial Z when plotted; surface height shows cost.

Save `01_descent.gd` beside the [complete shared code](../../../doc/book/course/formfinding-shared-code.md), on your existing `PointStudy` Node3D. The inspected working bay is hall-local `(10.5, 0, 6)` metres, floor level, upright, unit scale. The museum supplies the floor, camera, light, hands and button scene. The larger artifact remains available for comparison.

## Complete code — 01_descent.gd

<!-- student-code:01_descent.gd -->

```gdscript
extends "study.gd"
const Landscape = preload("landscape.gd")
var address := Vector2(-2.8, -2)
var rate := 0.7
var tolerance := 0.08
var valleys := false
var steps := 0
var status := "READY"
var point: Node3D
var readout: Label3D
var terrain: MeshInstance3D

func _ready() -> void:
    terrain = landscape_surface(valleys)
    point = make_point(Vector3.ZERO, false)
    point.scale = Vector3.ONE * 0.45
    readout = caption("", Vector3(0, 2.0, 0))
    button("STEP", Vector3(-0.55, 1, -1.65), step_once)
    button("RESET", Vector3(0, 1, -1.65), restart)
    button("SURFACE", Vector3(0.55, 1, -1.65), change_surface)
    refresh()

func step_once() -> void:
    if status not in ["READY", "STEPPING"]:
        return
    var slope := Landscape.gradient(address, valleys)
    if steps >= 160:
        status = "STEP LIMIT"
    elif slope.length() < tolerance:
        status = "SMALL SLOPE"
    else:
        var proposed := address - rate * slope
        if absf(proposed.x) > 3 or absf(proposed.y) > 3:
            status = "LEFT FRAME"
        else:
            address = proposed
            steps += 1
            status = "STEPPING"
    refresh()

func restart() -> void:
    address = Vector2(-2.8, -2)
    steps = 0
    status = "READY"
    refresh()

func change_surface() -> void:
    valleys = not valleys
    terrain.queue_free()
    terrain = landscape_surface(valleys)
    restart()

func refresh() -> void:
    point.position = Landscape.plot(address, valleys)
    readout.text = "%s | step %d\nx %.2f  z %.2f | cost %.3f" % [status, steps,
        address.x, address.y, Landscape.cost(address, valleys)]
```

## landscape.gd — keep this for Annealing

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

## Read the operation

The bowl costs one quarter of x² + z². Its gradient is (x/2, z/2). The two-valley expression is the hall’s second authored landscape; it gives us two possible local arrivals. In landscape.gd, sample the cost 0.03 to either side of each coordinate and divide the difference by the full 0.06 separation. This estimates the slope of the cost function, not a normal read from the rendered mesh.

Subtract rate × gradient to propose an address. The rate is a search step size, not seconds. STEP does one update. A small gradient, an exhausted budget and an out-of-frame proposal have different names. The last case retains the old address; it does not clamp the point onto the edge and pretend it has settled.

## Predict, then change

On the bowl, predict the first step from (−2.8, −2) at rate 0.7: (−1.82, −1.3). Press STEP once and read it. Set rate to 5 and restart: the first proposal leaves the frame, so the point must stay at its start. These outcomes test the operation and the boundary separately.

## Build another experiment

Make a second search beginning at (2.8, −2). Give it its own address, step count and status. Use the same two-valley function and rate 0.2 for both searches. Predict whether they finish together. Record their final costs and stopping reasons. A single shared STEP button can call each search once; do not share the mutable address. Explain why two SMALL SLOPE messages need not identify the same result.

## Carry onward

You now have an objective, a proposed change and a reason to stop. Keep landscape.gd: Annealing will revisit this exact landscape with another proposal and acceptance rule.

## Model notes

The hall adds RUN, three starts, rate and tolerance controls, a history and explanatory boards. This study keeps STEP, RESET and two surfaces. Small slope is a local observation; no code here proves a global minimum.
