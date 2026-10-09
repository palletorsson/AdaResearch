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


---

# Draw between the points

## Learning elements

- Curve3D
- Endpoints and handles
- Sampling a curve
- Parameters versus simulated forces

Move a point on the cable builder. The hanging line follows immediately. Its shape is drafted by handles; it does not wait for gravity to settle a chain. Walk on to the formula-built catenoid and laundry curves before deciding what their resemblance establishes.

## What you bring

Bring the two held points from Lines and Coordinates, local/world conversion, and the loop that joined neighbouring positions in Trace. Here those familiar points become endpoints of a curved span.

## Build inside the museum

Make one span using the same handle rule as the existing cable builder. Keep two PointBody instances and 24 thin cylinders. The hand supplies endpoints; the script resamples the span as they move.

Save `02_curve.gd` beside the [complete shared code](../../../doc/book/course/formfinding-shared-code.md), on your existing `PointStudy` Node3D. The inspected working bay is hall-local `(16, 0, 7)` metres, floor level, upright, unit scale. The museum supplies the floor, camera, light, hands and button scene. The larger artifact remains available for comparison.

## Complete code — 02_curve.gd

<!-- student-code:02_curve.gd -->

```gdscript
extends "study.gd"
var sag := 0.5
var ends: Array[Node3D] = []
var segments: Array[MeshInstance3D] = []
var curve := Curve3D.new()
var readout: Label3D

func _ready() -> void:
    ends = [make_point(Vector3(-1, 1.6, 0)), make_point(Vector3(1, 1.6, 0))]
    for i in 24:
        segments.append(rod())
    readout = caption("", Vector3(0, 2.15, 0))
    button("SAG", Vector3(0, 1, -0.8), change_sag)
    rebuild()

func change_sag() -> void:
    sag = 0.8 if sag < 0.8 else 0.0
    rebuild()

func _process(_delta: float) -> void:
    rebuild()

func rebuild() -> void:
    var a := to_local(ends[0].global_position)
    var b := to_local(ends[1].global_position)
    var span := a.distance_to(b)
    var drop := Vector3.DOWN * sag * span * 0.5
    curve.clear_points()
    curve.add_point(a, Vector3.ZERO, (b - a) * 0.3 + drop)
    curve.add_point(b, (a - b) * 0.3 + drop, Vector3.ZERO)
    for i in segments.size():
        var t := float(i) / segments.size()
        var next_t := float(i + 1) / segments.size()
        join(segments[i], curve.sample(0, t), curve.sample(0, next_t))
    readout.text = "DRAWN SAG %.2f | span %.2f m\nMove either point" % [sag, span]
```

## Read the operation

Curve3D stores endpoints with incoming and outgoing handles. A handle is an offset from its endpoint. The outgoing handle follows 30% of the displacement to the other point; the incoming handle points 30% back. Both also move down by sag × span × 0.5. This is the production artifact’s chosen Bézier construction.

curve.sample(0, t) evaluates the first span at a parameter between 0 and 1. The loop joins neighbouring evaluations. Equal parameter intervals need not have equal spatial length. to_local converts each held point’s world position into the study’s frame before constructing the curve. Local DOWN remains the study’s down; keep the study upright at unit scale.

Sag is a dimensionless control of handle depth. It is not the midpoint’s drop and not the cable’s weight. With level endpoints two metres apart and sag 0.5, both handles drop 0.5 m and the midpoint drops 0.375 m. Zero sag gives a straight span. The script evaluates a shape every frame; it does not integrate velocity or conserve cable length.

## Predict, then change

Before pressing SAG, predict which points will stay fixed. The button alternates 0.8 and 0 after the initial 0.5 setting. At sag 0, move an endpoint in height and depth: the line should still join both points. Bring the endpoints together; the zero-length drawing should disappear without an invalid direction.

## Build another experiment

Build two neighbouring spans from three held points. The middle point is shared: moving it must change both spans without creating two copies of the joint. Retain the same per-span handle rule. Compare the two sag depths when the spans have different lengths. You will need another set of rods, a loop over adjacent endpoint pairs, and the correct Curve3D span index for each sample.

## Carry onward

A shape can be determined directly from controls. In Relaxation, keep endpoints but replace the drafted interior with positions that repeatedly correct their relationships.

## Model notes

The museum cable has four control points and a swept tube. The study uses two and thin cylinders. Neither is a physical catenary solver. The evaluated cosh curves and surfaces elsewhere in the hall are separate constructions.


---

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


---

# Place the pivot

## Learning elements

- Mass moments
- Solving a constraint
- Assumptions of a model
- Balance versus stability

Follow one arm of the hanging mobile. The heavier side has less distance to the suspension. Its stillness was constructed from an arithmetic relation. The room’s truss and animated triangle offer other appearances of support without a load test.

## What you bring

Use masses from Forces, displacement and distance from Lines, functions and the drawn rods. We only need two familiar point markers to reconstruct one arm of the recursive mobile.

## Build inside the museum

Choose two positive masses and a total span. Calculate both distances from the pivot, then place the points. One nearby button changes the left mass while retaining the span.

Save `04_balance.gd` beside the [complete shared code](../../../doc/book/course/formfinding-shared-code.md), on your existing `PointStudy` Node3D. The inspected working bay is hall-local `(16, 0, 7)` metres, floor level, upright, unit scale. The museum supplies the floor, camera, light, hands and button scene. The larger artifact remains available for comparison.

## Complete code — 04_balance.gd

<!-- student-code:04_balance.gd -->

```gdscript
extends "study.gd"
var masses := Vector2(1, 2)
var span := 2.0
var distances := Vector2.ZERO
var points: Array[Node3D] = []
var arm: MeshInstance3D
var wire: MeshInstance3D
var readout: Label3D

func _ready() -> void:
    points = [make_point(Vector3.ZERO, false), make_point(Vector3.ZERO, false)]
    arm = rod()
    wire = rod()
    readout = caption("", Vector3(0, 2.4, 0))
    button("LEFT MASS", Vector3(0, 1, -0.8), change_mass)
    rebuild()

func change_mass() -> void:
    masses.x = 4.0 if masses.x == 1 else 1.0
    rebuild()

func rebuild() -> void:
    assert(masses.x > 0 and masses.y > 0 and span > 0)
    distances = Vector2(span * masses.y, span * masses.x) / (masses.x + masses.y)
    points[0].position = Vector3(-distances.x, 1.5, 0)
    points[1].position = Vector3(distances.y, 1.5, 0)
    join(arm, points[0].position, points[1].position)
    join(wire, Vector3(0, 1.5, 0), Vector3(0, 2.15, 0))
    readout.text = "%.1f kg / %.1f kg | arms %.3f / %.3f m\nmass x arm: %.3f / %.3f kg m\nCalculated pose; massless arm" % [
        masses.x, masses.y, distances.x, distances.y,
        masses.x * distances.x, masses.y * distances.y]
```

## Read the operation

For opposite vertical weights acting on a level, massless arm, equal torque magnitudes require m_left × g × d_left = m_right × g × d_right. The same g cancels. Also, the two arm lengths must add to span. Solving both relations gives d_left = span × m_right / total_mass and the opposite expression for d_right.

With masses 1 and 2 kg over two metres, the arms are 4/3 and 2/3 m. The heavier mass is closer to the pivot. The label shows mass × arm in kg m; multiply by g for torque magnitude in N m. Equal products express the selected static model.

The PointBody instances display the calculated places. The masses are numeric inputs, not a claim that these frozen markers are hanging under simulated forces. No joint, collision or settling solver determines this pose. That distinction also applies to the current mobile.

## Predict, then change

Predict the pivot’s relation to the points when the left mass changes from 1 to 4 kg. Press LEFT MASS and compare both products. Check that the arm lengths still add to two metres. Then give the sides equal mass and predict the midpoint.

## Build another experiment

Build a second two-point arm carrying masses 3 and 7 kg over 1.5 m. Display both distances and the residual m_left × d_left − m_right × d_right. It should be near zero. Construct an intentionally centred pivot as a comparison and show its nonzero residual. Explain why a zero residual in this model does not show that a disturbed physical mobile will return to rest.

## Carry onward

A calculated relation can construct a pose without waiting. In Annealing we return to a search where a useful next step may first make the objective worse.

## Model notes

The museum recurses over many arms and uses nominal disc masses. This lesson isolates one level. It omits rod and wire mass, friction, wind, and dynamic stability. The two points are a diagram of its inputs, not a new physics engine.


---

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


---

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
