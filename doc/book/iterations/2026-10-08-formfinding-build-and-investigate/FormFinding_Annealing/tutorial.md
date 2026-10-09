# Keep the best; let the search move

## Learning elements

- Random proposals
- Acceptance probability
- Cooling
- Current versus best
- Repeatable comparison

Watch the search point change its mind. At the annealing cabinet, some accepted moves raise the displayed cost. The lower region it has already found remains worth keeping even while the current candidate explores elsewhere.

## What you bring

Return to the two-valley function and point marker from Descent. Keep the objective unchanged so the new rule, rather than a new landscape, carries the comparison. Conditionals, saved values and bounded loops are already available.

## Build inside the museum

Propose a nearby address, accept improvements, sometimes accept a worse move, and gradually reduce that willingness. Store current and best separately. The smaller raised marker records the best address found so far.

Save `05_annealing.gd` beside the [complete shared code](../../../doc/book/course/formfinding-shared-code.md), on your existing `PointStudy` Node3D. The inspected working bay is hall-local `(16, 0, 7)` metres, floor level, upright, unit scale. The museum supplies the floor, camera, light, hands and button scene. The larger artifact remains available for comparison.

## Complete code — 05_annealing.gd

<!-- student-code:05_annealing.gd -->

```gdscript
extends "study.gd"
const Landscape = preload("landscape.gd")
var rng := RandomNumberGenerator.new()
var current := Vector2(2, 0)
var best := current
var temperature := 0.5
var cooling := 0.98
var attempts := 0
var status := "READY"
var point: Node3D
var best_point: Node3D
var readout: Label3D

func _ready() -> void:
    landscape_surface(true)
    point = make_point(Vector3.ZERO, false)
    best_point = make_point(Vector3.ZERO, false)
    point.scale = Vector3.ONE * 0.45
    best_point.scale = Vector3.ONE * 0.3
    readout = caption("", Vector3(0, 2.1, 0))
    button("PROPOSE", Vector3(-0.3, 1, -1.65), step_once)
    button("RESET", Vector3(0.3, 1, -1.65), restart)
    restart()

func restart() -> void:
    rng.seed = 7
    current = Vector2(2, 0)
    best = current
    temperature = 0.5
    attempts = 0
    status = "READY"
    refresh()

func accepts(change: float, draw: float) -> bool:
    return change <= 0 or (temperature > 0 and draw < exp(-change / temperature))

func step_once() -> void:
    if temperature < 0.01 or attempts >= 240:
        status = "STOPPED"
        refresh()
        return
    var candidate := current + Vector2(rng.randf_range(-0.5, 0.5), rng.randf_range(-0.5, 0.5))
    var draw := rng.randf()
    status = "OUTSIDE"
    if absf(candidate.x) <= 3 and absf(candidate.y) <= 3:
        var change := Landscape.cost(candidate, true) - Landscape.cost(current, true)
        status = "REJECTED"
        if accepts(change, draw):
            current = candidate
            status = "ACCEPTED"
            if Landscape.cost(current, true) < Landscape.cost(best, true):
                best = current
    attempts += 1
    temperature *= cooling
    refresh()

func refresh() -> void:
    point.position = Landscape.plot(current, true)
    best_point.position = Landscape.plot(best, true) + Vector3.UP * 0.12
    readout.text = "%s | attempt %d | T %.3f\nCurrent %.3f / best %.3f\nSmall raised point keeps the best address" % [status, attempts,
        temperature, Landscape.cost(current, true), Landscape.cost(best, true)]
```

## Read the operation

RandomNumberGenerator supplies the proposals. seed = 7 restarts its sequence for repeatable comparisons in this engine version. randf_range(-0.5, 0.5) chooses each coordinate offset; randf() supplies the acceptance draw. This is a first use of random sampling, before the later Randomness sequence studies its varieties.

change is candidate cost minus current cost. A nonpositive change is accepted. For a positive change and positive temperature, exp(-change / temperature) gives an acceptance probability between zero and one. Compare the random draw with that threshold. At change 0.05 and temperature 0.2, the threshold is about 0.779: a draw of 0.7 accepts and 0.9 rejects.

Current may become worse. Best only changes when the accepted current cost improves on it. Cooling multiplies temperature by 0.98 after each attempt, including rejected and out-of-frame proposals. The counter counts attempts, not accepted moves. Below 0.01, or at 240 attempts, the search stops. A reset restores the seed, both addresses, temperature and counter.

## Predict, then change

Keep the initial state and proposal rule. Set cooling to 0.9 and compare with 0.98. Predict which schedule stops sooner, then record both attempt counts and best costs. A faster cooling schedule gives fewer opportunities; one result does not establish that every slower run will be better.

## Build another experiment

Add counters for accepted improvements, accepted worse moves and rejected in-frame proposals. Define where equal-cost moves belong. Verify that their sum plus out-of-frame proposals equals the attempt count. Run several distinct seeds and keep a small table of best costs. Explain why keeping a best record is different from forcing current to move only downhill.

## Carry onward

A stopping rule finishes a search; it does not decide whether its result serves your purpose. Forge makes that decision into visible code.

## Model notes

The installed cabinet uses another objective and a richer adaptive algorithm, including occasional forced hops and reheating. This study isolates basic acceptance and cooling on the earlier landscape. Temperature here is an algorithmic parameter, not a measured material temperature. Finite runs provide no guarantee of the global optimum.
