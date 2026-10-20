# Machine Learning — complete tutorial

Eight halls of the existing Endless Museum. Review snapshot, 11 October 2026.

<!-- Canonical chapter: commons/maps/ML_Evolution/tutorial.md -->

# Evolution — what keeps a body here?

## Learning elements

- A population of records: position, energy, inherited speed and ancestry.
- Variation, reproduction and death without ranking bodies.
- Shared resources as a condition of selection.
- Seeded comparison and a fixed simulation step.
- Separate a running process, an authored arrangement and an interpretation.

## Where this sequence goes

We move from conditions of survival to a chosen loss, then grouping, fitted connections, taught poses, timed phrases, generated variations and checked intentions. These are different processes. The sphere keeps a familiar body while its role changes; the first four studies start their own local model state. Perception begins the saved hand-data branch. A hall's tutorial follows one primary construction while its other artifacts remain comparisons.

## Enter with what we already have

Graph Theory ended by changing a pairing while retaining the objects involved. Here the question changes: which bodies can remain and reproduce under a rule? Keep arrays, positions, loops, seeded randomness and the PointBody class. We use the familiar handheld point to run or pause a small population table. The little coloured bodies are new population records; they are not the player or twelve separately trained neural networks.

The existing Non-Teleological Evolution exhibit pays bodies for reaching unvisited cells, drains their energy, and permits reproduction above a threshold. There is no sorted fitness table. Yet the rule makes some encounters consequential for survival. We reconstruct that mechanism in a small, inspectable study, then change the availability of food.

Create res://doc/book/studies/ml-environment/. Copy point_body.gd unchanged from the preceding Graph Theory lesson, res://doc/book/studies/graphs-through-the-hands/GT_Matching/. Add the two complete files below. Run the supplied Evolution.tscn: evolution_museum.gd mounts this study inside ML_Evolution. The museum supplies its camera, lighting, floor and XR rig; XR Tools supplies pickup, and RackTemplates creates the named buttons used below. No unprinted creature scene or fitness method is required.

## One controlled comparison

The table arrives paused. Twelve bodies have energy 1.5 and different speeds. Its 8 × 8 cells initially contain one meal each. Green means available; dark means consumed or waiting to regrow. Each meal supplies 0.8 energy. Each body spends 0.15 energy per simulated second. Born includes the twelve initial bodies; Alive = Born − Died.

Press RUN, or hold the point and use its trigger. STEP pauses and advances exactly one thirtieth of a second. RESET repeats the current condition and seed. Read the counts and watch a family colour continue after a new body appears. Colour records ancestry only; it does not enter movement, feeding or reproduction.

FINITE lets each cell pay once. RETURN restarts the **same seeded opening**, but a consumed cell becomes available again after four seconds. This is a new comparison in the tutorial study, not a control secretly added to the original exhibit. Select each condition, then RUN. Compare at the same simulated time. NEXT SEED gives another opening; do not change both condition and seed when trying to isolate one cause.

A body still occupying a cell when its food returns may eat again. Return does not guarantee that a body must leave and come back. If you want that policy, it needs an additional record of the previous cell. Say which rule you are testing.

## Make the process explicit

population.gd contains no nodes or rendering. A body is a dictionary. Its speed is inherited with a small bounded change; direction is a new random heading for each child. Position, current energy, identity and ancestry are separate fields. Generation is the parent's generation plus one; it is not the total number of births.

Each step has an order: move; wrap around the field; collect available food; pay the energy cost; retain living bodies; split eligible parents' energy with children. A child starts moving on the next step. We collect survivors and children separately so an array edit cannot skip a neighbour during iteration.

The resource is shared. If two bodies occupy the same available cell in one step, the first in array order receives the meal. That tie-break is part of this model. It is not a claim that earlier-born organisms deserve priority. Swapping records is an independent experiment you can perform.

Splitting conserves the parent's remaining energy. Mutation changes speed; it does not add energy, predict success or rank the parent. The ceiling of 32 prevents further births when full. These choices make a small artificial-life model, not a complete account of biological evolution or a gradient-trained predictor.

<!-- student-code:population.gd -->
```gdscript
extends RefCounted
## A small environmental-selection model. No ranked fitness or target shape.
const DT := 1.0 / 30.0
const SIDE := 8
const LIMIT := 32
const REWARD := 0.8
const DRAIN := 0.15
const THRESHOLD := 3.0
const RENEW_SECONDS := 4.0
var rng := RandomNumberGenerator.new()
var bodies: Array = []
var ready_at := PackedFloat64Array()
var ticks := 0
var born := 0
var died := 0
var meals := 0
var renewal := false

func reset(seed_value: int, renew: bool) -> void:
    rng.seed = seed_value
    bodies.clear(); ticks = 0; born = 0; died = 0; meals = 0
    renewal = renew
    ready_at.resize(SIDE * SIDE); ready_at.fill(0.0)
    for i in 12:
        var p := Vector2(rng.randf_range(-0.8, 0.8), rng.randf_range(-0.8, 0.8))
        bodies.append(make_body(p, rng.randf_range(0.1, 0.4), 1.5, -1, 0, i))

func make_body(p: Vector2, speed: float, energy: float, parent: int, generation: int, family: int) -> Dictionary:
    var body := {"id":born, "parent":parent, "generation":generation, "family":family,
        "p":p, "direction":Vector2.RIGHT.rotated(rng.randf_range(-PI, PI)),
        "speed":speed, "energy":energy}
    born += 1
    return body

static func cell(p: Vector2) -> int:
    var x := clampi(int((p.x + 1.0) * 0.5 * SIDE), 0, SIDE - 1)
    var z := clampi(int((p.y + 1.0) * 0.5 * SIDE), 0, SIDE - 1)
    return z * SIDE + x

func available(index: int) -> bool:
    return ticks * DT >= ready_at[index]

func step() -> void:
    ticks += 1
    var survivors: Array = []
    # Stable array order: the first occupant collects a contested cell.
    for body: Dictionary in bodies:
        body.direction = body.direction.rotated(rng.randf_range(-0.25, 0.25))
        body.p += body.direction * body.speed * DT
        body.p = Vector2(wrapf(body.p.x, -1.0, 1.0), wrapf(body.p.y, -1.0, 1.0))
        var index := cell(body.p)
        if available(index):
            body.energy += REWARD
            ready_at[index] = ticks * DT + RENEW_SECONDS if renewal else INF
            meals += 1
        body.energy -= DRAIN * DT
        if body.energy > 0.0: survivors.append(body)
        else: died += 1
    var children: Array = []
    for parent: Dictionary in survivors:
        if parent.energy > THRESHOLD and survivors.size() + children.size() < LIMIT:
            parent.energy *= 0.5
            var speed := clampf(parent.speed + rng.randf_range(-0.05, 0.05), 0.05, 0.6)
            children.append(make_body(parent.p, speed, parent.energy,
                parent.id, parent.generation + 1, parent.family))
    # New children begin moving on the NEXT step.
    bodies = survivors + children

func total_energy() -> float:
    var total := 0.0
    for body: Dictionary in bodies: total += body.energy
    return total
```

In FINITE, at most 64 meals can be collected: 51.2 units, in addition to 18 initially held by the population. Births divide that energy. New bodies also add continuing costs. The rule can therefore produce a burst of births followed by loss, without anything malfunctioning. In RETURN, another source of energy enters through the regrowth rule; continued survival still depends on bodies meeting available cells.

The private random generator makes the same seed repeat within this implementation and engine. After two conditions lead to different births, they consume different numbers of random draws. A matched opening does not promise identical later wander. Keep the seed, code and condition together when reporting a run.

## Give the process a place in the museum

The view creates its table and grid once. A dictionary links each body ID to its visible sphere: surviving bodies keep their nodes, a birth adds one, and a death removes one. The PointBody also keeps its identity across resets. Its trigger changes whether time runs; its position does not feed or select the population.

Godot supplies elapsed frame time. An accumulator consumes it in fixed 1/30-second steps, so rendering more frames does not provide more meals. The larger exhibit now also uses a fixed simulation clock: sixty ticks per second, clearing one random cell every two simulated seconds. Its earlier rule depended on drawn frames. Our smaller model remains a different experiment: each consumed cell regrows after four seconds in RETURN mode, rather than clearing a randomly selected cell. Keep both the clock and the resource rule explicit when comparing them.

<!-- student-code:environment_study.gd -->
```gdscript
extends Node3D
const Population = preload("population.gd")
const PointBody = preload("point_body.gd")
# Supplied museum buttons; learning logic is entirely in these two new files.
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
var world := Population.new()
var seed_value := 17
var playing := false
var accumulator := 0.0
var point: PointBody
var title := Label3D.new()
var tiles: Array[StandardMaterial3D] = []
var views: Dictionary = {}

func _ready() -> void:
    var table := BoxMesh.new(); table.size = Vector3(2.2, 0.10, 2.2)
    mesh_at(table, Vector3(0, 1.0, 0), Color("161c28"))
    for z in Population.SIDE:
        for x in Population.SIDE:
            var tile := BoxMesh.new(); tile.size = Vector3(0.23, 0.012, 0.23)
            var view := mesh_at(tile, Vector3(-0.875+x*0.25, 1.06, -0.875+z*0.25), Color.WHITE)
            tiles.append(view.material_override)
    title.position = Vector3(0, 1.85, -1.0)
    title.font_size = 26; title.pixel_size = 0.002
    add_child(title)
    point = PointBody.new(); point.position = Vector3(1.23, 1.2, 0.8)
    add_child(point)
    point.action_pressed.connect(func(_p):command("RUN"))
    var rows: Array = []; var words: Array = []
    for names in [["RUN", "STEP", "RESET"], ["FINITE", "RETURN", "NEXT SEED"]]:
        var row: Array = []
        for word in names:
            row.append({"type":"button", "label":word}); words.append(word)
        rows.append(row)
    var panel := Rack.create_panel("WHAT KEEPS A BODY?", rows)
    panel.position = Vector3(0, 1.05, 1.38); panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE * 2; add_child(panel)
    for i in words.size():
        var button = panel.find_child("Btn_%d" % i, true, false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(words[i]))
    reset(false)

func mesh_at(mesh: Mesh, p: Vector3, colour: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new(); view.mesh = mesh; view.position = p
    var material := StandardMaterial3D.new(); material.albedo_color = colour
    view.material_override = material; add_child(view)
    return view

func reset(renew: bool) -> void:
    playing = false; accumulator = 0.0
    world.reset(seed_value, renew)
    for view in views.values(): remove_child(view); view.queue_free()
    views.clear(); redraw()

func command(word: String) -> void:
    match word:
        "RUN": playing = not playing
        "STEP": playing = false; accumulator = 0.0; world.step()
        "RESET": reset(world.renewal)
        "FINITE": reset(false)
        "RETURN": reset(true)
        "NEXT SEED": seed_value += 1; reset(world.renewal)
    redraw()

func _process(delta: float) -> void:
    if playing:
        accumulator += delta
        while accumulator >= Population.DT:
            world.step(); accumulator -= Population.DT
        if world.bodies.is_empty(): playing = false
        redraw()

func redraw() -> void:
    for i in tiles.size():
        tiles[i].albedo_color = Color("a3c8aa") if world.available(i) else Color("303747")
    var living: Dictionary = {}
    for body: Dictionary in world.bodies:
        living[body.id] = true
        if not views.has(body.id):
            var sphere := SphereMesh.new(); sphere.radius = 0.045; sphere.height = 0.09
            sphere.radial_segments = 12; sphere.rings = 6
            views[body.id] = mesh_at(sphere, Vector3.ZERO, Color.from_hsv(body.family/12.0, 0.65, 0.95))
        views[body.id].position = Vector3(body.p.x, 1.115, body.p.y)
    for id in views.keys():
        if not living.has(id):
            remove_child(views[id]); views[id].queue_free(); views.erase(id)
    title.text = "%s / seed %d / %.1f seconds\nAlive %d / born %d / died %d / meals %d\n%s / colour = ancestry, not fitness" % [
        "RETURN: food regrows in 4 s" if world.renewal else "FINITE: each cell pays once",
        seed_value, world.ticks*Population.DT, world.bodies.size(), world.born, world.died,
        world.meals, "RUNNING" if playing else "PAUSED"]
```

## Reconstruct, predict, investigate

Before RUN, predict what another birth does to total energy and to future drain. Pause after reproduction and compare the parent and child's speed and generation in world.bodies. Their combined energy must equal the parent's energy immediately before splitting. The new speed may be higher or lower; improvement is not built into mutation.

Then run FINITE and RETURN from seed 17 to the same simulated time. Record Alive, Born, Died and Meals. Reset and repeat. Change only the seed for a second comparison. Counts test this implementation; one surviving family does not establish that its colour or speed is universally best.

For a small code experiment, put two bodies in the same cell with stationary headings and enough energy to survive. Step once, swap their order after an identical reset, and step again. The first occupant should receive the meal each time. This tests a consequential detail that a pleasing animation can hide.

The reconstruction checks conservation at a split, inherited bounded mutation, identity and ancestry, shared-food contention, exhaustion, repeatability, actual buttons and the carried point. Its synthetic runs establish these operations, not biological validity or human VR comfort.

## Return to the surrounding exhibits

Use the original exhibit's live drift mode to compare feeding and loss. Its uniform, culled, runaway and split modes are preset arrangements that stop the process. They illustrate proposed situations; they are not evidence that running a particular selection rule produced those forms. Its Diversity count bins hues and its Gen counter increments at births; neither is the ancestry record we explicitly built here.

The judged creatures and evolving flowers provide another mechanism: an explicit score affects which parameters are carried onward. They remain supporting encounters. In Gradient Landscape, an error function will become the surface we can inspect directly. Carry this distinction: what changed, what condition allowed it, and what evidence justifies calling it an improvement?


---

<!-- Canonical chapter: commons/maps/ML_Gradient_Landscape/tutorial.md -->

# Gradient Landscape — a line and a loss

## Learning elements

- Prediction from two parameters: slope and intercept.
- Residuals, mean squared error and Huber loss.
- A numerical gradient and a learning-rate step.
- Observation space versus parameter space.
- Controlled comparisons, overshoot and a declared display boundary.

## Carry the point into another kind of space

Evolution let the same point control a population living under an energy rule. Keep that PointBody class. Here we change its job: the point stands for **one candidate line**, described by two numbers. Its horizontal position selects a slope and an intercept. The height under it shows the loss assigned to that line. We already know positions, arrays, functions, meshes and seeded comparisons; now we make the score explicit and use its local slope to change a model.

The hall's Loss Function Comparator places three losses beside one dataset. We reconstruct its central question with five visible observations, one fitted line and two losses. The existing third, wavy surface and optimizer race remain supporting encounters. Learning Adam, momentum and a complete rendering system at once would obscure what a descent step actually does.

Create res://doc/book/studies/ml-gradient/. Copy point_body.gd unchanged from the previous lesson, res://doc/book/studies/ml-environment/. Add the two complete files below. Run the supplied Gradient.tscn: gradient_museum.gd mounts the study in the existing ML_Gradient_Landscape museum hall. Camera, lights, floor and XR rig are supplied. RackTemplates supplies the eight named buttons. The fitting mathematics and the view are printed here; they import no production fitting helper.

## Read the two spaces

On the left, five orange observations sit in an x/y diagram. The turquoise line predicts y = slope * x + intercept. Pink vertical rods join observations to their predictions. Each difference is a **residual**. We take its magnitude in this implementation because both chosen losses are symmetric about zero.

On the right, every place on the surface is another pair of slope/intercept values. Across changes slope; towards you changes intercept. A low place rates that candidate line favourably under the selected loss. These coordinates describe parameters, not the locations of the observations. A line with slope 0.5 and intercept 0.2 passes through all five clean observations.

The surface height uses one fixed linear scale: base 0.9 plus 0.025 times loss. We do not rescale each surface to fill the same height. The sphere's radius is added above the surface. This is calculated placement, not gravity or a rigid body finding a valley. The mesh samples the continuous function on a 24 by 24 grid; its triangles approximate that surface.

## Score a candidate and take one step

MSE averages the squared residuals. Huber with threshold 1 uses half the square for residuals up to 1, then grows linearly. The factor of one half means the two losses have different scales even where they prefer the same line. A smaller displayed number or faster descent is not a fair comparison of their usefulness.

To estimate the gradient, change one parameter by a small h in both directions and compare the losses. Repeat for the other parameter. Divide each difference by 2h. This is a central-difference estimate: four loss evaluations tell us two local rates of change. Subtract rate times that vector to propose the next parameters.

The parameter window is [-3,3] on both axes. Hand placement is bounded to it. An optimizer step outside it is refused and named; it is not silently clamped or accepted as convergence. A small gradient stops the automatic run. In this lesson's convex losses it helps locate a fit; it is not a general proof of a good model or a global optimum on every landscape.

<!-- student-code:line_fit.gd -->
```gdscript
extends RefCounted
## Parameter space: p.x is slope, p.y is intercept, not a physical location.
const START := Vector2(-1.0, 1.0)
const BOUND := 3.0
var data := PackedVector2Array([
    Vector2(-1, -0.3), Vector2(-0.5, -0.05), Vector2(0, 0.2),
    Vector2(0.5, 0.45), Vector2(1, 0.7)])
var p := START
var robust := false
var rate := 0.1
var steps := 0
var status := "PAUSED"

func prediction(q: Vector2, x: float) -> float:
    return q.x * x + q.y

func loss(q: Vector2) -> float:
    var total := 0.0
    for sample in data:
        var e := absf(prediction(q, sample.x) - sample.y)
        total += (0.5*e*e if e <= 1.0 else e-0.5) if robust else e*e
    return total / data.size()

func gradient(q: Vector2, h: float = 0.001) -> Vector2:
    var x := Vector2(h, 0); var y := Vector2(0, h)
    return Vector2(loss(q+x)-loss(q-x), loss(q+y)-loss(q-y)) / (2.0*h)

func reset() -> void:
    p = START; steps = 0; status = "PAUSED"

func set_outlier(enabled: bool) -> void:
    data[4] = Vector2(1, 4.7 if enabled else 0.7)
    reset()

func step() -> bool:
    var g := gradient(p)
    if g.length() < 0.0001:
        status = "SMALL GRADIENT"; return false
    var proposed := p - rate*g
    if not proposed.is_finite() or absf(proposed.x) > BOUND or absf(proposed.y) > BOUND:
        status = "STEP OUTSIDE WINDOW"; return false
    p = proposed; steps += 1; status = "STEPPED"
    return true
```

## Give the line, the loss and the hand one view

Create the point once. Grabbing it pauses descent and reads its position in the study's local frame, even when the museum has rotated the study. Hand height does not alter the parameters. On release the point settles to the calculated height. The other controls wait until you put it down. This is a new use of the same pickable class; its trigger is no longer the population's run/pause control.

MSE and HUBER keep the candidate parameters while changing the score and surface. RESET keeps the current data, loss and rate but returns to (-1,1). OUTLIER toggles only the last observation between (1,0.7) and (1,4.7), then resets the candidate. Nothing is randomly redrawn. SLOW selects rate 0.1; LARGE selects 1.5. STEP pauses and attempts one update. RUN toggles repeated updates, one every 0.15 seconds. That interval controls how quickly we watch; the learning rate controls the parameter change.

A dark backing and unlit control materials keep the diagrams readable under the museum lights. The line and residual rods are redrawn when parameters change; the terrain is rebuilt only when the data or loss changes. While the point is not held, `_physics_process` keeps its position on the calculated surface, including after a paused button edit. This prevents the frozen pickable body's physics state from restoring an older position. PointBody keeps its identity through every operation. The study is session-only: no fit or observations are saved between visits.

<!-- student-code:gradient_study.gd -->
```gdscript
extends Node3D
const Fit = preload("line_fit.gd")
const PointBody = preload("point_body.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
var fit := Fit.new()
var point: PointBody
var running := false
var clock := 0.0
var outlier := false
var was_held := false
var terrain := MeshInstance3D.new()
var plot := Node3D.new()
var readout := Label3D.new()

func _ready() -> void:
    add_child(terrain); add_child(plot)
    readout.position = Vector3(0.1, 2.95, -0.7)
    readout.font_size = 28; readout.pixel_size = 0.0025
    add_child(readout)
    var backing := MeshInstance3D.new(); var slab := BoxMesh.new()
    slab.size = Vector3(1.95, 2.4, 0.04); backing.mesh = slab
    backing.position = Vector3(-1.35, 1.65, -0.85)
    backing.material_override = material(Color("161d2b")); add_child(backing)
    label("OBSERVATIONS / x and y", Vector3(-1.35, 2.6, -0.79))
    label("PARAMETERS / slope across, intercept towards you\nHeight = 0.025 x loss; no gravity", Vector3(0.95, 0.65, 0.5))
    point = PointBody.new(); add_child(point)
    var words := ["STEP", "RUN", "RESET", "MSE", "HUBER", "OUTLIER", "SLOW", "LARGE"]
    var rows: Array = []
    for r in 2:
        var row: Array = []
        for c in 4: row.append({"type":"button", "label":words[r*4+c]})
        rows.append(row)
    var panel := Rack.create_panel("FIT ONE LINE", rows)
    panel.position = Vector3(0, 1.05, 1.3); panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE*2; add_child(panel)
    for mesh in panel.find_children("*", "MeshInstance3D", true, false):
        var m := mesh.material_override as BaseMaterial3D
        if m != null:
            m = m.duplicate(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            mesh.material_override = m
    for i in words.size():
        var button = panel.find_child("Btn_%d" % i, true, false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(words[i]))
    rebuild_surface(); redraw()

func label(text: String, where: Vector3) -> void:
    var node := Label3D.new(); node.text = text; node.position = where
    node.font_size = 22; node.pixel_size = 0.002; add_child(node)

func surface_position(q: Vector2) -> Vector3:
    return Vector3(0.95+q.x*0.26, 0.9+fit.loss(q)*0.025, q.y*0.26)

func plot_position(sample: Vector2) -> Vector3:
    return Vector3(-1.35+sample.x*0.8, 1.65+sample.y*0.18, -0.8)

func material(colour: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new(); m.albedo_color = colour
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    m.cull_mode = BaseMaterial3D.CULL_DISABLED
    return m

func rod(a: Vector3, b: Vector3, colour: Color, radius: float = 0.009) -> void:
    var d := b-a
    if d.length() < 0.00001: return
    var mesh := CylinderMesh.new(); mesh.top_radius = radius; mesh.bottom_radius = radius
    mesh.height = d.length(); mesh.radial_segments = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = (a+b)*0.5
    node.quaternion = Quaternion(Vector3.UP, d.normalized())
    node.material_override = material(colour); plot.add_child(node)

func rebuild_surface() -> void:
    var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for z in 24:
        for x in 24:
            for offset: Vector2 in [Vector2(0,0),Vector2(1,0),Vector2(1,1),Vector2(0,0),Vector2(1,1),Vector2(0,1)]:
                var q := Vector2(-3+(x+offset.x)*0.25, -3+(z+offset.y)*0.25)
                st.set_color(Color("57bbc8") if (x+z)%2==0 else Color("326979"))
                st.add_vertex(surface_position(q))
    st.generate_normals(); terrain.mesh = st.commit()
    var m := material(Color.WHITE); m.vertex_color_use_as_albedo = true
    terrain.material_override = m

func redraw() -> void:
    for child in plot.get_children(): plot.remove_child(child); child.queue_free()
    rod(plot_position(Vector2(-1.1,0)), plot_position(Vector2(1.1,0)), Color.GRAY)
    rod(plot_position(Vector2(0,-6)), plot_position(Vector2(0,6)), Color.GRAY)
    rod(plot_position(Vector2(-1,fit.prediction(fit.p,-1))), plot_position(Vector2(1,fit.prediction(fit.p,1))), Color("60e3df"), 0.015)
    for sample in fit.data:
        var mesh := SphereMesh.new(); mesh.radius = 0.028; mesh.height = 0.056
        var node := MeshInstance3D.new(); node.mesh = mesh; node.position = plot_position(sample)
        node.material_override = material(Color("ffbc68")); plot.add_child(node)
        rod(node.position, plot_position(Vector2(sample.x,fit.prediction(fit.p,sample.x))), Color("e26ba2"), 0.006)
    if not point.held(): point.global_position = to_global(surface_position(fit.p)+Vector3.UP*0.085)
    readout.text = "%s / outlier %s / rate %.2f / steps %d\nslope %.3f / intercept %.3f / loss %.4f\n%s" % [
        "HUBER delta 1" if fit.robust else "MSE", outlier, fit.rate, fit.steps,
        fit.p.x, fit.p.y, fit.loss(fit.p), "RUNNING" if running else fit.status]

func command(word: String) -> void:
    if point.held(): return # Put the parameter point down before starting descent.
    var was_running := running
    running = false; clock = 0.0
    match word:
        "STEP": fit.step()
        "RUN": running = not was_running
        "RESET": fit.reset()
        "MSE": fit.robust = false; fit.steps = 0; fit.status = "SAME PARAMETERS"; rebuild_surface()
        "HUBER": fit.robust = true; fit.steps = 0; fit.status = "SAME PARAMETERS"; rebuild_surface()
        "OUTLIER": outlier = not outlier; fit.set_outlier(outlier); rebuild_surface()
        "SLOW": fit.rate = 0.1; fit.status = "RATE CHANGED"
        "LARGE": fit.rate = 1.5; fit.status = "RATE CHANGED"
    redraw()

func _physics_process(_delta: float) -> void:
    if not point.held():
        point.global_position = to_global(surface_position(fit.p)+Vector3.UP*0.085)

func _process(delta: float) -> void:
    if point.held():
        running = false; clock = 0.0; was_held = true
        var hand := to_local(point.global_position)
        fit.p = Vector2(clampf((hand.x-0.95)/0.26,-3,3), clampf(hand.z/0.26,-3,3))
        fit.steps = 0; fit.status = "HAND CHOOSES PARAMETERS"; redraw()
    elif was_held:
        was_held = false; redraw()
    elif running:
        clock += delta
        while clock >= 0.15 and running:
            clock -= 0.15
            running = fit.step()
        redraw()
```

## Predict, run, change one thing

With clean data, MSE and SLOW, RESET and STEP. The initial loss is 1.765. The gradient is approximately (-1.5,1.6), so the next parameters should be (-0.85,0.84). The line should change and its loss decrease. These numbers give you a check independent of whether the animation looks plausible. RUN should approach slope 0.5 and intercept 0.2.

Switch to HUBER without moving the sphere. The line remains the same and its score changes. RESET before comparing two full descents. Add the fixed outlier, then fit each loss from that same start at the slow rate. The least-squares solution is slope 2.1 and intercept 1.0. The Huber fit should lie near slope 1.5 and intercept 0.7. Inspect the residuals: neither result establishes why the unusual observation is present or whether it should count less. These are fits to this small teaching dataset, not evidence of performance on new observations.

For an independent experiment, restore clean data and MSE, select LARGE, RESET and STEP. Predict whether going downhill locally guarantees a better next score. The first large step stays inside the window but increases loss. The next would leave the window and is refused. Lower the rate and reset. A step that is too long and an objective that answers the wrong question are different problems.

Finally move the last observation in code to another x position. Re-run both fits and explain why changing where the residual occurs can change the slope as well as the intercept. Keep the data change separate from a change of loss or rate.

## Return to the surrounding hall

The original comparator uses twenty observations and adds a third rule, sin(3e) + 0.5e². Its label says adversarial; it is not a trained adversarial network. Its surfaces are each normalized for display, while its markers use a separate approximate normalization. Their apparent heights therefore cannot serve as a shared numerical loss scale. The tutorial uses one height formula for the mesh and point instead. The old comparator also uses forward differences and clamps steps; our central differences and refused boundary are declared changes for this reconstruction.

An optimizer race asks how to move under a chosen score. This table first asks what was scored. Evolution made survival depend on resources; here the loss evaluates a prediction and directs a parameter update. Classification next will group observations by distance. Carry the habit of distinguishing observations, parameters, the measure and the procedure that changes them.


---

<!-- Canonical chapter: commons/maps/ML_Classification/tutorial.md -->

# Classification — a group without a name

## Learning elements

- Observations versus cluster centres
- Squared distance and nearest-centre assignment
- An index is not a supplied class label
- A mean computed with a sum and a count
- Alternating assignment and centre updates
- Chosen K, starting positions, ties and empty groups
- Reusing PointBody in museum-local coordinates

## Keep the point; change its job

In Gradient Landscape you moved the familiar sphere to choose a line's slope and intercept. Here it selects one cluster centre. The little observations remain fixed while their group assignments change. We are still working inside Endless Museum. Start with the existing K-means exhibit: STEP assigns points and moves centres in one action. Our reconstruction separates those actions so you can predict each one.

The hall is called Classification. This particular construction is **unsupervised clustering**: the input contains positions, without correct class names. The SVM and forest elsewhere in the hall use supplied labels. They remain comparisons; we will construct a labelled network in the next lesson, then teach the sphere with our hands in Perception.

Carry `point_body.gd` unchanged from `doc/book/studies/ml-gradient/point_body.gd`. It already constructs the sphere, its collision shape, XR pickup and the desktop grab adapter. Do not paste another sphere constructor or retain Gradient's host. Create a new folder with that carried file and the two complete files below. There is one `_ready()` in the new host. The same PointBody instance survives all controls in this study; changing halls still creates a new scene instance.

**Supplied by Ada:** Godot 4.6, XR Tools, the museum/player rig and `res://commons/audio/rack_templates/RackTemplates.gd`. RackTemplates builds the familiar spatial buttons; their `InteractableAreaButton.button_pressed` signals are connected below. These are declared interface dependencies, not a hidden clustering model.

Run `res://doc/book/studies/ml-classification/Classification.tscn` to enter the actual hall with the study mounted on its clear floor. This supplied scene uses `classification_museum.gd` to open the museum and attach `cluster_study.gd`; the launcher contains no learning algorithm. If working in your own folder, attach your host to a Node3D in the supplied study position, or change the launcher's `LESSON` preload to your host. No camera, light or XR rig needs rebuilding. All observations and parameters here are session-only.

## Predict before pressing

Small pale dots are observations. C1…CK are centres; **CENTRE** makes the black carried sphere stand for another centre. Before ASSIGN, point to the closest centre for one observation. ASSIGN colours the observations and draws thin cylinders to their chosen centres. Positions do not move. Before MEAN, predict where one centre will move: sum the positions assigned to it and divide by their count. MEAN moves centres but keeps the last assignments visible. The next ASSIGN may change those assignments.

The two steps alternate. Pressing the wrong next step does nothing; the readout says which is due. RESET repeats the start for the current K and dataset. K 2, K 3 and K 4 choose a count and restart the centres without changing observations. DATA cycles twelve points in three authored blobs, two twelve-point rings, and a regular five-by-five grid. These are fixed teaching arrangements, not a fresh random draw or measured people.

For fixed centres, each observation chooses the smallest **squared** distance. Squaring a nonnegative distance keeps its ordering. For fixed assignments, the arithmetic mean minimizes the sum of squared distances in that group. This is why the two steps belong together. The readout shows **SSE**, the sum of squared errors for the assignments currently displayed. After MEAN those colours are deliberately retained until the next ASSIGN. Before any assignment there is no score; we display “unassigned,” not a perfect zero.

These operations reuse arrays, indices, loops and vectors from earlier halls. Unlike Gradient, there is no numerical derivative or learning-rate slider: the mean gives the centre update directly. K and initial centre positions still come from us. A settled arrangement can depend on its start; it is not guaranteed to be the best arrangement among all starts.

## 1. The complete clustering model

Save as `cluster_model.gd`. `data[i]` is an observation, `groups[i]` is the integer index of its centre, and `centres[j]` is that centre's current position. A missing assignment array means no grouping has yet been made. The model stores two coordinates; the view maps them to the table's x/z plane.

<!-- student-code:cluster_model.gd -->
```gdscript
extends RefCounted
var data := PackedVector2Array()
var centres := PackedVector2Array()
var groups := PackedInt32Array()
var k := 3
var dataset := 0
var next_assignment := true
var rounds := 0
var status := "ASSIGN NEXT"

func _init() -> void:
    set_data(0)

func set_data(choice: int) -> void:
    dataset = posmod(choice, 3)
    data.clear()
    match dataset:
        0:
            for centre: Vector2 in [Vector2(-0.8,-0.6), Vector2(0.8,-0.6), Vector2(0,0.7)]:
                for offset: Vector2 in [Vector2(-0.1,0),Vector2(0.1,0),Vector2(0,-0.15),Vector2(0,0.15)]:
                    data.append(centre+offset)
        1:
            for radius: float in [0.35, 0.85]:
                for i in 12:
                    var angle := TAU*i/12.0
                    data.append(Vector2(cos(angle),sin(angle))*radius)
        2:
            for z in 5:
                for x in 5: data.append(Vector2(x-2,z-2)*0.4)
    reset(k)

func reset(count: int) -> void:
    k = clampi(count, 2, 4)
    var start := PackedVector2Array([Vector2(-0.6,-0.3), Vector2(0,0.1), Vector2(0.6,0.3), Vector2(0,-0.8)])
    centres = start.slice(0,k)
    invalidate()

func invalidate() -> void:
    groups.clear()
    next_assignment = true
    rounds = 0
    status = "ASSIGN NEXT"

func nearest(p: Vector2) -> int:
    var winner := 0
    var best := p.distance_squared_to(centres[0])
    for j in range(1,centres.size()):
        var distance := p.distance_squared_to(centres[j])
        if distance < best: # Equal distances retain the lower index.
            best = distance
            winner = j
    return winner

func assign() -> bool:
    if not next_assignment: return false
    groups.clear()
    for p in data: groups.append(nearest(p))
    next_assignment = false
    status = "ASSIGNED / MEAN NEXT"
    return true

func move_means() -> bool:
    if next_assignment: return false
    for j in centres.size():
        var sum := Vector2.ZERO
        var count := 0
        for i in data.size():
            if groups[i] == j:
                sum += data[i]
                count += 1
        if count > 0: centres[j] = sum/count
    rounds += 1
    next_assignment = true
    status = "MEANS MOVED / ASSIGN NEXT"
    return true

func score() -> float:
    var total := 0.0
    for i in groups.size():
        total += data[i].distance_squared_to(centres[groups[i]])
    return total

func move_centre(index: int, where: Vector2) -> void:
    centres[index] = Vector2(clampf(where.x,-1,1),clampf(where.y,-1,1))
    invalidate()
```

`nearest()` compares every centre and keeps the current winner. The strict `<` gives an exact tie to the earlier index. That tie policy is a choice, not evidence that a point belongs more strongly to that group. `move_means()` starts a fresh sum and count for each group. An empty group keeps its previous centre, avoiding division by zero. K counts available centres; it does not promise K occupied groups.

`assign()` changes only the indices. `move_means()` changes only centres. `score()` recomputes the current SSE from both arrays. In exact arithmetic, each alternating step cannot increase that score on fixed observations, K and assignments/centres as appropriate. Floating-point comparisons need a small tolerance. Moving a centre by hand, resetting, changing K or switching data interrupts that comparison. A lower SSE alone is also not a reason to prefer more groups: allowing one centre per point could drive it to zero without supplying a useful explanation.

## 2. Put that operation on the museum table

Save as `cluster_study.gd`. The host creates one carried PointBody. Other centre markers and observation dots are display meshes. The dark table and button surfaces use unlit materials so the comparison remains readable under the museum lights.

<!-- student-code:cluster_study.gd -->
```gdscript
extends Node3D
const Model = preload("cluster_model.gd")
const PointBody = preload("point_body.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const COLOURS = [Color("f2799d"),Color("62d8da"),Color("ffd56c"),Color("ad9cf2")]
const DATASETS = ["BLOBS", "RINGS", "GRID"]
var model := Model.new()
var point: PointBody
var selected := 0
var was_held := false
var drawing := Node3D.new()
var readout := Label3D.new()

func _ready() -> void:
    add_child(drawing)
    var backing := MeshInstance3D.new(); var slab := BoxMesh.new()
    slab.size = Vector3(2.7,0.06,2.7); backing.mesh = slab
    backing.position.y = 0.88; backing.material_override = material(Color("18202b")); add_child(backing)
    readout.position = Vector3(0,2.1,-1.45)
    readout.font_size = 27; readout.pixel_size = 0.0025; add_child(readout)
    var header := MeshInstance3D.new(); var plate := BoxMesh.new()
    plate.size = Vector3(3.2,0.65,0.04); header.mesh = plate
    header.position = Vector3(0,2.1,-1.5)
    header.material_override = material(Color("18202b")); add_child(header)
    point = PointBody.new(); add_child(point)
    var words := ["ASSIGN","MEAN","RESET","CENTRE","K 2","K 3","K 4","DATA"]
    var rows: Array = []
    for r in 2:
        var row: Array = []
        for c in 4: row.append({"type":"button","label":words[r*4+c]})
        rows.append(row)
    var panel := Rack.create_panel("K-MEANS",rows)
    panel.position = Vector3(0,1.05,1.7); panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE*2; add_child(panel)
    for mesh in panel.find_children("*","MeshInstance3D",true,false):
        var m := mesh.material_override as BaseMaterial3D
        if m != null:
            m = m.duplicate(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            mesh.material_override = m
    for i in words.size():
        var button = panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(words[i]))
    redraw()

func material(colour: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new(); m.albedo_color = colour
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m

func place(p: Vector2, height: float = 0.98) -> Vector3:
    return Vector3(p.x*1.25,height,p.y*1.25)

func dot(p: Vector3, radius: float, colour: Color) -> void:
    var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius*2
    mesh.radial_segments = 16; mesh.rings = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = p
    node.material_override = material(colour); drawing.add_child(node)

func rod(a: Vector3, b: Vector3, colour: Color) -> void:
    var d := b-a
    if d.length() < 0.00001: return
    var mesh := CylinderMesh.new(); mesh.top_radius = 0.007; mesh.bottom_radius = 0.007
    mesh.height = d.length(); mesh.radial_segments = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = (a+b)*0.5
    node.quaternion = Quaternion(Vector3.UP,d.normalized())
    node.material_override = material(colour); drawing.add_child(node)

func redraw() -> void:
    for child in drawing.get_children(): drawing.remove_child(child); child.queue_free()
    for i in model.data.size():
        var colour := Color("eeeeee")
        if not model.groups.is_empty():
            var j: int = model.groups[i]; colour = COLOURS[j]
            rod(place(model.data[i]),place(model.centres[j],1.12),colour.darkened(0.35))
        dot(place(model.data[i]),0.034,colour)
    for j in model.centres.size():
        var centre: Vector3 = place(model.centres[j],1.12)
        if j != selected: dot(centre,0.07,COLOURS[j])
        var label := Label3D.new(); label.text = "C%d"%(j+1)
        label.position = centre+Vector3(0,0.18,0)
        label.modulate = COLOURS[j]; label.font_size = 25; label.pixel_size = 0.002
        drawing.add_child(label)
    if not point.held(): point.global_position = to_global(place(model.centres[selected],1.12))
    var score := "unassigned"
    if not model.groups.is_empty(): score = "SSE %.4f"%model.score()
    readout.text = "%s / K %d / %d mean updates / %s\n%s\nBlack sphere = C%d. Grab to change its position.\nSmall dots stay fixed. Colour is an index, not a name." % [
        DATASETS[model.dataset],model.k,model.rounds,score,model.status,selected+1]

func command(word: String) -> void:
    if point.held(): return
    match word:
        "ASSIGN": model.assign()
        "MEAN": model.move_means()
        "RESET": model.reset(model.k)
        "CENTRE": selected = (selected+1)%model.k
        "K 2", "K 3", "K 4": model.reset(int(word.right(1))); selected = 0
        "DATA": model.set_data(model.dataset+1); selected = 0
    redraw()

func _physics_process(_delta: float) -> void:
    if not point.held():
        point.global_position = to_global(place(model.centres[selected],1.12))

func _process(_delta: float) -> void:
    if point.held():
        var hand := to_local(point.global_position)
        model.move_centre(selected,Vector2(hand.x,hand.z)/1.25)
        was_held = true; redraw()
    elif was_held:
        was_held = false; redraw()
```

`place()` applies one scale to both coordinate axes: one model unit occupies 1.25 metres. Distance is computed in the two model coordinates, not from a controller's height. During pickup, `to_local()` removes the hall's translation and rotation before x/z are read. We bound hand-chosen centres to the displayed square, [-1, 1] on each axis. Upon release the sphere returns to the centre's display height. `_physics_process()` keeps the unheld rigid body synchronized to its current centre on physics ticks; a one-off visual move could otherwise be overwritten by the physics state. While held, the hand retains control. The table is a diagram, not a cloth or physics simulation.

Moving a centre clears assignments and resets the round counter. We do not leave stale colours pretending to answer a changed question. Put the sphere down, then ASSIGN. Controls are ignored while it is held. CENTRE changes which parameter the existing sphere controls; it does not destroy and recreate the point. No trigger action is added in this lesson.

## Build, then investigate

1. With BLOBS and K 3, alternate ASSIGN and MEAN. Note SSE after each action. Watch a fixed observation near a boundary; explain a colour change using the moving centres.
2. RESET and move C1 before assigning. Keep the same observations and K. Follow the different steps rather than assuming the final colouring must differ. Compare groups as sets of positions: an index or colour can be renamed without changing a partition.
3. Choose RINGS. Follow either ring, then inspect which centres claim its points. Nearest-centre regions need not follow a curved ring. Choose GRID: grouping continues even though you supplied no separated blobs.
4. Change K. State what changed in the question. Return to the same K and DATA to repeat its fixed start; there is no hidden reseeding.
5. Independently check a smaller case in the model: observations `(-0.8, 0), (0, 0), (0.8, 0)` and centres `(-0.8, 0), (0.8, 0)`. ASSIGN gives `[0, 0, 1]`, because the middle point ties. SSE is 0.64. MEAN puts the first centre at `(-0.4, 0)` and retains the second at `(0.8, 0)`; SSE becomes 0.32. Explain both numbers before running it. Then move the middle observation to `(0.2, 0)` and predict the new assignment and means. To display your own fixture, keep its coordinates inside the square and preserve the model's array/index relationship.

**Reconstruction check.** `python tools/test_ml_classification_lesson.py` extracts these two printed blocks, adds only the declared carried PointBody and runs assertions in native Godot. The checks include an independently calculated fixture, the changed middle observation, ties, empty groups, alternating steps, unchanged data, squared-distance descent, real button signals and pickup in a rotated/translated host. The museum probe mounts those extracted files in ML_Classification and checks placement and controls. Synthetic checks cannot establish human headset reach or whether the explanation is clear to a new reader.

## What travels onward

Carry the distinction between observations, parameters, the measure and the update procedure. Keep PointBody as a reusable construction. The indices here have no supplied meanings. In Neural Networks we will fit weights against labelled examples; in Perception you will decide what A, B and C mean for a two-hand pose. Neither a shorter distance nor a smaller training error settles what those names ought to mean.

Algorithm reference: the [scikit-learn clustering guide](https://scikit-learn.org/stable/modules/clustering.html#k-means) describes the squared-distance objective, alternating mean updates and sensitivity to initialization. We implement that small process directly here, without importing scikit-learn. The original museum exhibit has a different readout: it accumulates ordinary distances before moving its centres. Its “Total distance” must not be mistaken for this study's current SSE.

AI-short: Carry Gradient PointBody. Fixed 2D observations; sphere controls selected centre. ASSIGN nearest squared distance → MEAN by sum/count; alternate. Tie lower index; empty centre retained. Hand edit invalidates groups. K 2/3/4; fixed blobs/rings/grid. SSE current displayed assignments; original exhibit reports pre-update unsquared distance. Groups lack supplied names. Print model+host; declare XR/Rack/museum. Test fixture+mutation+controls+native placement. Next learned weights.


---

<!-- Canonical chapter: commons/maps/ML_Neural_Networks/tutorial.md -->

# Neural Networks — what a weight keeps

## Learning elements

- Supplied labels versus a cluster index
- Weighted sums, biases and function composition
- Transient activations versus retained parameters
- A two-input, three-hidden-unit, one-output network
- Binary cross-entropy and the chain rule
- Full-batch gradient descent; numerical gradient checks
- Training examples versus separate check examples
- Target leakage and the limits of a high score

## The same sphere, a different question

Classification kept observations fixed while you moved one centre. Here the familiar PointBody marks **an input**, not a parameter. Moving it changes the activations and output of a network while its weights stay fixed. Press STEP to change weights. This separation is the lesson: trying a new input is not training.

We remain inside Endless Museum. The existing large network is useful for following connections across layers. Its training example needs care, however: it has four inputs, and the last two already encode its two desired outputs in reverse order. That display cannot establish that a network learned the two-input exclusive-or relation without being given the answer. Its own readout and the lower disclosure panel now name that leakage and show which inputs contain which targets. Our reconstruction uses only the two independent coordinates. A familiar sphere or diagram does not imply that the internal model or its evidence has stayed the same.

The four training positions occupy the corners of a square. The supplied labels are 1 at opposite-sign corners and 0 at same-sign corners. A single straight boundary in these two coordinates cannot separate those diagonal pairs. Three tanh units provide a nonlinear intermediate representation. We fit thirteen numbers; we do not write the label rule inside forward(). FLIP reverses the labels and restarts the same initial weights, making the choice of answers visible.

Carry `point_body.gd` unchanged from `doc/book/studies/ml-classification/point_body.gd`. Keep its sphere, collision shape and pickup behaviour. Create the two complete files below beside it. The old clustering host is replaced, not added as another `_ready()`. One PointBody instance remains throughout this lesson; a new hall load still creates a new scene instance.

**Supplied infrastructure:** Godot 4.6, Ada's museum/player rig and XR Tools, plus `res://commons/audio/rack_templates/RackTemplates.gd` for spatial buttons. Their `InteractableAreaButton.button_pressed` signals are connected explicitly. No network helper is supplied or imported.

Run `res://doc/book/studies/ml-network/Network.tscn`. Its supplied `network_museum.gd` opens ML_Neural_Networks and mounts this study on checked floor. The launcher contains no training code. For your own folder, copy the carried file, save the two printed scripts together, and point the launcher's `LESSON` preload to your `network_study.gd`. The museum supplies camera, light and tracking. Model state is session-only.

## First try an input; then fit

1. Before training, move the black sphere across the left table. The two displayed input values, three hidden activations and output change. Inspect w0: it stays fixed. Height is not a feature.
2. EXAMPLE moves the sphere to another training position. The small dots retain their supplied labels. A displayed p(1) of 0.8 means the network's class-1 score is 0.8; it is not evidence that this system is 80 percent reliable.
3. STEP makes one full-batch update using all four training examples. Keep the input still and watch the values change. The readout gives current training loss, w0 and its last update. The other twelve parameters change too, even though one is singled out for inspection.
4. TRAIN toggles repeated fitting, ten updates per rendered frame, up to 1000. This controls viewing speed; each mathematical update still uses rate 0.5. Grabbing the sphere pauses training. Put it down before pressing controls.
5. CHECK evaluates four distinct interior positions, with declared targets, without adding them to training. Compare this check loss with training loss. These fixed check cases informed selection of the starting parameters, so they are development evidence, not an untouched independent test set.
6. RESET repeats the initial parameters while keeping the selected labels and input. FLIP reverses every training/check label and resets the weights. Fit again with the same coordinates. A correct answer here is correct relative to the labels we supplied.

## 1. A complete small learner

Save as `tiny_network.gd`. Each hidden unit multiplies x1 and x2 by its two weights, adds a bias, and applies tanh. The output combines the three hidden values with three more weights and a bias, then applies sigmoid. The output is bounded between zero and one.

| Parameters | Entries | Count |
| --- | --- | --- |
| Input-to-hidden weights, pairs for h0/h1/h2 | 0–5 | 6 |
| Hidden biases | 6–8 | 3 |
| Hidden-to-output weights | 9–11 | 3 |
| Output bias | 12 | 1 |

These initial values are fixed, small and different, not pre-trained. We selected a repeatable start after checking both label conventions: an earlier start fitted one convention but stalled on the reverse. Nonlinear fitting can get stuck, and these four check positions have therefore informed development; they are not an untouched evaluation set. Identical zero initialization would make the hidden units indistinguishable in this symmetric problem. Fixed values let RESET repeat an experiment. START contains parameters; data contains inputs; labels contains desired answers. No target is an input to forward().

<!-- student-code:tiny_network.gd -->
```gdscript
extends RefCounted
const START = [0.69,-0.73,0.91,-0.52,-0.53,0.25,0.59,-0.35,-0.55,-0.07,0.14,-0.1,-0.05]
const RATE := 0.5
const LIMIT := 1000
var weights := PackedFloat64Array(START)
var data := PackedVector2Array([Vector2(-0.8,-0.8),Vector2(-0.8,0.8),Vector2(0.8,-0.8),Vector2(0.8,0.8)])
var labels := PackedInt32Array([0,1,1,0])
var fresh := PackedVector2Array([Vector2(-0.6,-0.7),Vector2(-0.6,0.7),Vector2(0.6,-0.7),Vector2(0.6,0.7)])
var flipped := false
var epoch := 0
var last_change := 0.0

func reset() -> void:
    weights = PackedFloat64Array(START)
    epoch = 0
    last_change = 0.0

func flip_labels() -> void:
    flipped = not flipped
    for i in labels.size(): labels[i] = 1-labels[i]
    reset()

func forward(x: Vector2) -> Dictionary:
    var hidden := PackedFloat64Array()
    for j in 3:
        hidden.append(tanh(weights[2*j]*x.x+weights[2*j+1]*x.y+weights[6+j]))
    var z := weights[12]
    for j in 3: z += weights[9+j]*hidden[j]
    var probability: float
    if z >= 0: probability = 1.0/(1.0+exp(-z))
    else: probability = exp(z)/(1.0+exp(z))
    return {"hidden":hidden,"z":z,"p":probability}

func example_loss(x: Vector2, target: int) -> float:
    var z: float = forward(x).z
    return maxf(z,0.0)-target*z+log(1.0+exp(-absf(z)))

func loss() -> float:
    var total := 0.0
    for i in data.size(): total += example_loss(data[i],labels[i])
    return total/data.size()

func gradient(x: Vector2, target: int) -> PackedFloat64Array:
    var g := PackedFloat64Array(); g.resize(13); g.fill(0.0)
    var f := forward(x)
    var d: float = f.p-target
    g[12] = d
    for j in 3:
        g[9+j] = d*f.hidden[j]
        var dh: float = d*weights[9+j]*(1.0-f.hidden[j]*f.hidden[j])
        g[6+j] = dh
        g[2*j] = dh*x.x
        g[2*j+1] = dh*x.y
    return g

func train_epoch() -> bool:
    if epoch >= LIMIT: return false
    var mean := PackedFloat64Array(); mean.resize(13); mean.fill(0.0)
    for i in data.size():
        var g := gradient(data[i],labels[i])
        for p in 13: mean[p] += g[p]/data.size()
    last_change = -RATE*mean[0]
    for p in 13: weights[p] -= RATE*mean[p]
    epoch += 1
    return true

func check_fresh() -> Dictionary:
    var total := 0.0
    var correct := 0
    var scores: Array = []
    for i in fresh.size():
        var f := forward(fresh[i]); scores.append(f.p)
        total += example_loss(fresh[i],labels[i])
        if int(f.p >= 0.5) == labels[i]: correct += 1
    return {"loss":total/fresh.size(),"correct":correct,"scores":scores}
```

For a target y of 0 or 1 and an output p, binary cross-entropy is `-y*log(p) - (1-y)*log(1-p)`. `example_loss()` computes the equivalent expression from the output sum z, avoiding logarithms of probabilities rounded to zero. The stable sigmoid branches also avoid an overflowing exponential for large negative sums. This numerical arrangement changes neither the task nor its target.

Follow `gradient()` from the output backwards. For sigmoid with this loss, the derivative with respect to z is `p-y`. An output weight's derivative is that error times the hidden activation it multiplies. To reach a hidden unit, multiply by its outgoing weight, then by `1-h*h`, the derivative of tanh. Finally multiply by the corresponding input for each incoming weight. A bias has an implicit input of one. Backpropagation is this chain of derivatives; gradient descent is the subsequent parameter update. They are different operations.

`train_epoch()` averages all four examples' derivatives before changing **any** weight. Thus every derivative refers to the same parameter state. Only after accumulation do we subtract RATE times the mean. Updating outgoing weights before computing hidden derivatives would mix states. The previous manuscript did that and omitted activation derivatives; this complete version replaces the sketch.

One forward calculation returns new hidden values and a score. It does not change the weights. `check_fresh()` also leaves weights, epoch and training data untouched. Its targets come from the matching order of the four supplied check positions and labels, not from the network's answer. No human data enters this exercise.

## 2. Make the calculation visible in the hall

Save as `network_study.gd`. The left table contains the supplied observations and carried input point. The right diagram shows the actual forward calculation for that point. Thin cylinders represent weights: colour shows sign, width shows magnitude with a visual cap. Node numbers show activations. These are separate visual encodings. Biases participate in the printed model but have no separate wire in this compact diagram.

<!-- student-code:network_study.gd -->
```gdscript
extends Node3D
const Model = preload("tiny_network.gd")
const PointBody = preload("point_body.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const ZERO = Color("f18caa")
const ONE = Color("64dad5")
var model := Model.new()
var point: PointBody
var probe := Vector2(-0.8,-0.8)
var example := 0
var running := false
var was_held := false
var check_result: Dictionary = {}
var drawing := Node3D.new()
var readout := Label3D.new()

func _ready() -> void:
    add_child(drawing)
    box(Vector3(-1.05,0.86,0),Vector3(1.8,0.06,1.8))
    box(Vector3(0.8,1.65,-0.8),Vector3(2.2,1.95,0.04))
    box(Vector3(0,2.9,-0.85),Vector3(4,0.6,0.04))
    readout.position = Vector3(0,2.9,-0.8); readout.font_size = 25
    readout.pixel_size = 0.0025; add_child(readout)
    point = PointBody.new(); add_child(point)
    var words := ["STEP","TRAIN","RESET","EXAMPLE","CHECK","FLIP"]
    var rows: Array = []
    for r in 2:
        var row: Array = []
        for c in 3: row.append({"type":"button","label":words[r*3+c]})
        rows.append(row)
    var panel := Rack.create_panel("FIT / PROBE",rows)
    panel.position = Vector3(0,1.05,1.2); panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE*2; add_child(panel)
    for mesh in panel.find_children("*","MeshInstance3D",true,false):
        var m := mesh.material_override as BaseMaterial3D
        if m != null:
            m = m.duplicate(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
            mesh.material_override = m
    for i in words.size():
        var button = panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(words[i]))
    redraw()

func material(colour: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new(); m.albedo_color = colour
    m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return m

func box(where: Vector3, size: Vector3) -> void:
    var node := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size
    node.mesh = mesh; node.position = where
    node.material_override = material(Color("18202b")); add_child(node)

func place(p: Vector2, height: float = 1.03) -> Vector3:
    return Vector3(-1.05+p.x*0.78,height,p.y*0.78)

func label(text: String, where: Vector3, size: int = 22) -> void:
    var node := Label3D.new(); node.text = text; node.position = where
    node.font_size = size; node.pixel_size = 0.002; drawing.add_child(node)

func dot(where: Vector3, colour: Color, radius: float = 0.06) -> void:
    var mesh := SphereMesh.new(); mesh.radius = radius; mesh.height = radius*2
    mesh.radial_segments = 16; mesh.rings = 8
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = where
    node.material_override = material(colour); drawing.add_child(node)

func wire(a: Vector3, b: Vector3, weight: float) -> void:
    var d := b-a
    var mesh := CylinderMesh.new(); mesh.height = d.length(); mesh.radial_segments = 8
    mesh.top_radius = 0.006+0.004*minf(absf(weight),4); mesh.bottom_radius = mesh.top_radius
    var node := MeshInstance3D.new(); node.mesh = mesh; node.position = (a+b)*0.5
    node.quaternion = Quaternion(Vector3.UP,d.normalized())
    node.material_override = material(ONE if weight>=0 else ZERO); drawing.add_child(node)

func redraw() -> void:
    for child in drawing.get_children(): drawing.remove_child(child); child.queue_free()
    for i in model.data.size():
        dot(place(model.data[i],0.94),ONE if model.labels[i]==1 else ZERO,0.032)
        label(str(model.labels[i]),place(model.data[i],1.16))
    label("INPUTS x1 / x2\nSmall dots: supplied labels",Vector3(-1.05,1.5,-0.75))
    var f := model.forward(probe)
    var inputs := [Vector3(0,1.9,-0.7),Vector3(0,1.25,-0.7)]
    var hidden := [Vector3(0.75,2.2,-0.7),Vector3(0.75,1.6,-0.7),Vector3(0.75,1,-0.7)]
    var output := Vector3(1.5,1.6,-0.7)
    for j in 3:
        for i in 2: wire(inputs[i],hidden[j],model.weights[2*j+i])
        wire(hidden[j],output,model.weights[9+j])
    for i in 2:
        var value: float = probe[i]
        dot(inputs[i],ONE if value>=0 else ZERO)
        label("x%d %.2f"%[i+1,value],inputs[i]+Vector3(0,0.17,0.02))
    for j in 3:
        var value: float = f.hidden[j]
        dot(hidden[j],(ONE if value>=0 else ZERO).darkened(0.6*(1-absf(value))))
        label("h%d %.2f"%[j,value],hidden[j]+Vector3(0,0.17,0.02))
    dot(output,ZERO.lerp(ONE,f.p),0.09)
    label("p(1) %.3f"%f.p,output+Vector3(0,0.24,0.02))
    label("Wire colour: sign / width: |weight|\nNode values: this input's activations",Vector3(0.8,0.77,-0.7),18)
    var heldout := "CHECK: four separate positions not yet measured"
    if not check_result.is_empty(): heldout = "CHECK loss %.4f / %d of 4 correct"%[check_result.loss,check_result.correct]
    readout.text = "%s / epoch %d / train loss %.4f / labels flipped %s\nw0 %.4f / last update %+.5f\n%s"%[
        "TRAINING" if running else "PAUSED",model.epoch,model.loss(),model.flipped,model.weights[0],model.last_change,heldout]
    if not point.held(): point.global_position = to_global(place(probe))

func command(word: String) -> void:
    if point.held(): return
    var was_running := running; running = false
    match word:
        "STEP": model.train_epoch(); check_result.clear()
        "TRAIN": running = not was_running and model.epoch<Model.LIMIT
        "RESET": model.reset(); check_result.clear()
        "EXAMPLE": example = (example+1)%model.data.size(); probe = model.data[example]
        "CHECK": check_result = model.check_fresh()
        "FLIP": model.flip_labels(); check_result.clear()
    redraw()

func _physics_process(_delta: float) -> void:
    if not point.held(): point.global_position = to_global(place(probe))

func _process(_delta: float) -> void:
    if point.held():
        running = false; was_held = true
        var hand := to_local(point.global_position)
        probe = Vector2(clampf((hand.x+1.05)/0.78,-1,1),clampf(hand.z/0.78,-1,1))
        redraw()
    elif was_held:
        was_held = false; redraw()
    elif running:
        check_result.clear()
        for i in 10:
            if not model.train_epoch(): running = false; break
        redraw()
```

The host converts the held sphere's world position into its local frame, then reads the table's x/z coordinates. One input unit occupies 0.78 metres; both coordinates are bounded to [-1, 1]. Height, controller rotation and velocity are absent. Upon release, the sphere returns to display height. `_physics_process()` keeps the unheld rigid body's position synchronized across physics ticks, carrying the fix established in Classification.

The held sphere changes `probe`, not `data`, `labels` or `weights`. Buttons are ignored while it is held. STEP, RESET and FLIP clear the previous CHECK readout; TRAIN clears it when updates start. EXAMPLE and hand movement only change the input, so a check of the unchanged model remains valid. The readout never silently presents an old check as evidence for new weights.

## Build, then investigate

Before running the first forward pass at `(-0.8, -0.8)`, calculate h0: `tanh((0.69 * -0.8) + (-0.73 * -0.8) + 0.59) = tanh(0.622)`, about 0.55252. The complete pass gives p(1) about 0.46547, although its supplied target is 0. It happens to fall on the correct side of 0.5. One correct untrained answer does not establish a successful fit.

Now change the input while keeping weights fixed. Explain why activations change and w0 does not. Return to that input and STEP. Explain why the prediction can now change without moving the point. Repeat with a different connection by inspecting its array entry before and after an update.

Our reconstruction tests every analytic derivative against a central difference, returning to Gradient Landscape's numerical method: perturb one parameter by +epsilon and -epsilon, measure that example's loss, and divide the difference by twice epsilon. Restore the parameter each time. This independent check can catch a missing tanh derivative or an update using already-changed weights. It is a code test, not the training method used in the lesson.

After 1000 updates with the printed start and original labels, training loss should be about 0.00504; the four printed check positions give about 0.00740 and four correct thresholded answers. These are reproducible results on eight authored positions. They establish neither a general success rate nor good behaviour everywhere in the square. At the untrained centre `(0,0)`, inspect how decisive the fitted score can look despite having no example there. A smooth field of answers is not a field of equally strong evidence.

As an independent change, FLIP, fit again, and verify the opposite answers at the same corners. Then, in your model copy, change just one corner label and predict which training error should initially increase. Refit before evaluating separate cases whose expected answers you have stated. Do not use the model's own predictions as correct targets for its test.

**Run the reconstruction:** `python tools/test_ml_network_lesson.py` extracts the two marked code blocks, adds the declared PointBody, and runs native Godot assertions. It checks all thirteen derivatives at multiple parameter/input states, an independent forward calculation, one update against numerical derivatives, fitting both label conventions, fixed check cases that never enter training, controls, point identity and delayed physics synchronization. The separate museum probe mounts these extracted files in the actual hall. These synthetic checks do not establish headset comfort or independent-reader comprehension.

## What travels onward

A forward pass changes activations. Fitting changes retained weights. The feature representation and supplied answers come before either operation. In Perception we expand this same structure to six hand coordinates, eight tanh units and three softmax outputs. Its cross-entropy gradient still starts with score minus supplied target, and all parameter derivatives must use the same old weights. The Perception chapter prints the complete larger model; no hidden dependency on this small example is introduced.

The familiar sphere then acquires an authored response to a learned label. This lesson prepares the separation: input representation, fitted mapping, acceptance policy and what the object does with an answer.

References for the calculus and independent checks: Stanford's [backpropagation notes](https://cs231n.github.io/optimization-2/) and [gradient-checking guidance](https://cs231n.github.io/neural-networks-3/). The original museum source is `algorithms/machinelearning/neuralnetworkvisualization/neural_network_visualization.gd`; inspect its `generate_training_data()` to see the extra answer-bearing inputs.

AI-short: Carry Classification PointBody; now query input, not centre/weight. Print 2→3 tanh→1 sigmoid, 13 parameters; four two-coordinate corner inputs, explicit binary targets; fixed asymmetric start. Forward does not fit. BCE stable logits; d=p-y; tanh chain; average gradients before any update. STEP/TRAIN/RESET/EXAMPLE/CHECK/FLIP. No target in input. Fixed check positions excluded from fit; scores not certainty. Test all gradients numerically, independent forward/update, changed labels, signals, native delayed body sync. Original four-input exhibit leaks targets; retain and disclose. Next six-hand-coordinate pose model.


---

<!-- Canonical chapter: commons/maps/ML_Perception/tutorial.md -->

# Perception — teach the same sphere

## Learning elements

- Represent two tracked hands with six coordinates.
- Keep one labelled example from one complete, steady take.
- Fit weights to examples; distinguish fitting from fresh testing.
- Separate a learned answer, an acceptance rule and an authored response.
- Save the model and continue with the same PointBody class.

## Already in the museum

Enter the learning bay to the right of the dance space, across the partition. The sphere, controls and room already exist. First try POSE there. We now reconstruct that capability with the PointBody class carried from the earlier lessons. Its mesh and pickup behaviour remain familiar. A narrow ring makes its rotation visible.

The preceding halls introduced selection, loss, clustering and changing network weights. Here those ideas acquire a task you can teach: decide which of three poses you mean. Positions and arrays return from Point and Trace; translation, rotation, scale and colour give the answer a visible effect. The sphere does not learn those effects. We write FLOAT, SPIN and STRETCH; the network learns which label your hand coordinates resemble.

Keep this lesson to POSE. HEIGHT, movement phrases and CHECK remain available in the full museum station, but are later extensions. A held pose contains no movement order. Sequence Memory will ask what we lose by keeping only a mean.

## Run in the supplied museum

Use the Ada Godot project and its existing XR setup. Open res://doc/book/studies/ml-lineage/Perception.tscn and run that scene. The supplied perception_museum.gd opens the actual Perception hall and mounts the learner script at its existing learning anchor. In this lesson preview it hides the full station; ordinary museum visits retain all modes. It does not alter your museum saves.

Place the three complete files below beside that launcher: point_body.gd, pose_learner.gd and pose_study.gd. PointBody is a revised version of the carried class, printed in full so this chapter can be reconstructed. Its radius grows from 0.085 to 0.14 metres and its collision mask changes from 0 to 196615 for the museum interaction layers; pickup remains XRToolsPickable with a frozen release. This version omits the earlier table's desktop grab adapter: the pose lesson records tracked XR hands. The host gives the surface a metallic finish and adds the orientation ring. These are explicit changes to the same point design, not a claim that the file is unchanged. The host uses the supplied RackTemplates.gd to create ten buttons and explicitly connects their signals. The museum supplies camera, lights, tracking and XR Tools pickup. These are declared infrastructure, not a hidden classifier. Desktop can display the lesson; recording your hands requires tracked XR controllers.

## Teach, test, then let it act

1. Face the console and press ALIGN. This keeps one horizontal reference direction until you align again. Hand positions are measured relative to the current head position in that fixed frame, divided by 0.65 metres. This scale is a design choice, not a measurement of your arm length.
2. In TEACH, choose A. A three-second countdown gives you time to move away from the button. Hold a comfortable pose for 0.65 seconds. The program averages the samples into **one** six-number example. Repeat with separate takes and small natural variation. Teach at least three takes for each of A, B and C. Choose visibly different poses; three examples is a minimum for running the exercise, not proof of sufficient data.
3. Press TRAIN. The same starting weights are fitted for 300 full-batch updates. The screen shows loss on the teaching examples. A falling value means a better fit to that sample.
4. TEST asks you to declare A, B or C before recording a fresh take. It displays what you meant and what the model predicted. No weights change. Try slightly different positions and an unfamiliar pose. A high softmax score is not calibrated certainty. Testing mistakes must remain visible rather than quietly entering training.
5. LIVE lets an accepted answer lasting a quarter-second act on the sphere: A floats, B spins, C stretches the visible mesh. Its pickup collider stays spherical. Losing tracking or moving outside the study's three-metre range idles the response. While you hold the sphere, pickup takes priority over scripted motion.
6. SAVE writes user://ada_student_pose_v1.json, separate from the museum's model files. LOAD starts a fresh evaluation session. A new teaching example invalidates the old fitted model and test records; train again. To begin an empty study, restart the scene; the saved file remains until you overwrite it with SAVE.

## Follow the calculation

The features() function returns six values in this order: left x, y, z; right x, y, z. Moving the whole measured arrangement together does not change these relative coordinates. Turning only your hands, swapping left and right, or changing the reference frame can change them. Finger shape, gaze, torso and intention are absent.

The learner is a **6 → 8 → 3** network. Each hidden unit adds six weighted inputs and a bias, then applies tanh. Each output adds eight weighted hidden values and a bias. Softmax turns the outputs into three scores summing to one. All three labels are choices you supplied.

| Stored parameters | Array entries | Count |
| --- | --- | --- |
| Input-to-hidden weights | 0–47 | 48 |
| Hidden biases | 48–55 | 8 |
| Hidden-to-output weights | 56–79 | 24 |
| Output biases | 80–82 | 3 |

Neural Networks fitted thirteen numbers to two coordinates and two labels. Here the representation has six coordinates and three labels, so we create a new 83-parameter model; we do not load the previous hall's thirteen weights. We carry its calculation and its distinction between querying and fitting. Softmax replaces the single sigmoid because this exercise chooses among three supplied alternatives.

There are 83 trainable numbers. Cross-entropy loss is minus the logarithm of the score for the given label. In gradient(), output error is the score minus the supplied target (one for the named class, zero for the others). Each weight's derivative multiplies that error by its input. Passing error through tanh also multiplies by one minus the squared hidden activation. The train_epoch() function averages those derivatives over the examples and subtracts RATE times the mean from the weights. Every derivative uses the old weights before any are updated.

Read the model in this order: add_example, forward, gradient, train_epoch, predict, test_example. Validation and persistence follow the same data contract; they are included so the printed files run without missing helpers.

Acceptance is a separate authored policy: highest score at least 0.70 **and** RMS distance to a teaching example at most 0.32. It can still accept an unfamiliar case or reject an intended one. The host's respond() then chooses a prewritten action. None of these thresholds is a measure of dance quality.


## Complete carried class

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable

const RADIUS := 0.14

func _init() -> void:
    freeze = true
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
    release_mode = XRToolsPickable.ReleaseMode.FROZEN
    ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    collision_layer = 4
    collision_mask = 196615

    var surface := MeshInstance3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    surface.mesh = sphere
    add_child(surface)

    var boundary := CollisionShape3D.new()
    var shape := SphereShape3D.new()
    shape.radius = RADIUS
    boundary.shape = shape
    add_child(boundary)
```


## Complete learner

<!-- student-code:pose_learner.gd -->
```gdscript
extends RefCounted
## Small real classifier: 6 hand coordinates -> 8 tanh units -> 3 softmax outputs.
## No guide poses, category templates or prerecorded scores enter this model.
const INPUTS := 6
const HIDDEN := 8
const CLASSES := 3
const PARAMETERS := 83
const MAX_PER_CLASS := 20
const EPOCHS := 300
const RATE := 0.20
const SCHEMA := "ada-hand-pose-1"
var weights := PackedFloat64Array()
var examples: Array = []
var tests: Array = []
var epoch := 0
var trained := false
var initial_loss := 0.0
var history: Array = []
var revision := 0

func _init() -> void:
	initialize(417)

func initialize(seed_value: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	weights.resize(PARAMETERS)
	weights.fill(0.0)
	for j in HIDDEN:
		for i in INPUTS: weights[j * INPUTS + i] = rng.randf_range(-0.55, 0.55)
	for k in CLASSES:
		for j in HIDDEN: weights[56 + k * HIDDEN + j] = rng.randf_range(-0.55, 0.55)
	epoch = 0
	trained = false
	tests.clear()
	history.clear()
	initial_loss = loss()
	history.append(initial_loss)

static func valid_input(x: Array) -> bool:
	if x.size() != INPUTS: return false
	for v in x:
		if not (v is float or v is int) or not is_finite(float(v)) or absf(float(v)) > 4.0: return false
	return true

func counts() -> Array:
	var result := [0, 0, 0]
	for e: Dictionary in examples: result[int(e.label)] += 1
	return result

func add_example(x: Array, label: int) -> bool:
	if label < 0 or label >= CLASSES or not valid_input(x) or counts()[label] >= MAX_PER_CLASS: return false
	examples.append({"x": x.duplicate(), "label": label})
	revision += 1
	trained = false
	epoch = 0
	tests.clear()
	history.clear()
	return true

func can_train() -> bool:
	for amount in counts():
		if amount < 3: return false
	return true

func forward(x: Array) -> Dictionary:
	if not valid_input(x): return {}
	var hidden := PackedFloat64Array()
	for j in HIDDEN:
		var z := weights[48 + j]
		for i in INPUTS: z += weights[j * INPUTS + i] * float(x[i])
		hidden.append(tanh(z))
	var scores := PackedFloat64Array()
	for k in CLASSES:
		var z := weights[80 + k]
		for j in HIDDEN: z += weights[56 + k * HIDDEN + j] * hidden[j]
		scores.append(z)
	var largest := scores[0]
	for value in scores: largest = maxf(largest, value)
	var total := 0.0
	for k in CLASSES:
		scores[k] = exp(scores[k] - largest)
		total += scores[k]
	for k in CLASSES: scores[k] /= total
	return {"hidden": hidden, "scores": scores}

func gradient(x: Array, label: int) -> PackedFloat64Array:
	var result := PackedFloat64Array()
	result.resize(PARAMETERS)
	result.fill(0.0)
	var f := forward(x)
	if f.is_empty() or label < 0 or label >= CLASSES: return result
	var delta: PackedFloat64Array = f.scores.duplicate()
	delta[label] -= 1.0 # derivative of softmax + cross entropy
	for k in CLASSES:
		result[80 + k] = delta[k]
		for j in HIDDEN: result[56 + k * HIDDEN + j] = delta[k] * f.hidden[j]
	for j in HIDDEN:
		var hidden_delta := 0.0
		for k in CLASSES: hidden_delta += delta[k] * weights[56 + k * HIDDEN + j]
		hidden_delta *= 1.0 - f.hidden[j] * f.hidden[j] # tanh derivative
		result[48 + j] = hidden_delta
		for i in INPUTS: result[j * INPUTS + i] = hidden_delta * float(x[i])
	return result # all derivatives use the same, not-yet-updated weights

func example_loss(x: Array, label: int) -> float:
	return -log(maxf(1e-12, forward(x).scores[label]))

func loss() -> float:
	if examples.is_empty(): return 0.0
	var value := 0.0
	for e: Dictionary in examples: value += example_loss(e.x, int(e.label))
	return value / examples.size()

func train_epoch() -> void:
	if not can_train() or epoch >= EPOCHS: return
	var mean := PackedFloat64Array()
	mean.resize(PARAMETERS)
	mean.fill(0.0)
	for e: Dictionary in examples:
		var g := gradient(e.x, int(e.label))
		for p in PARAMETERS: mean[p] += g[p] / examples.size()
	for p in PARAMETERS: weights[p] -= RATE * mean[p]
	epoch += 1
	if epoch % 10 == 0: history.append(loss())
	trained = epoch == EPOCHS

func predict(x: Array) -> Dictionary:
	if not trained: return {}
	var f := forward(x)
	if f.is_empty(): return {}
	var best := 0
	for k in CLASSES:
		if f.scores[k] > f.scores[best]: best = k
	# A separate proximity policy. A softmax score alone cannot detect novelty.
	var distance := INF
	for e: Dictionary in examples:
		var squared := 0.0
		for i in INPUTS: squared += pow(float(x[i]) - float(e.x[i]), 2)
		distance = minf(distance, sqrt(squared / INPUTS))
	return {"label": best, "scores": f.scores, "distance": distance,
		"accepted": f.scores[best] >= 0.70 and distance <= 0.32}

func test_example(x: Array, expected: int) -> Dictionary:
	if expected < 0 or expected >= CLASSES: return {}
	var prediction := predict(x)
	if prediction.is_empty(): return {}
	var record := {"x": x.duplicate(), "expected": expected,
		"predicted": prediction.label, "accepted": prediction.accepted,
		"correct": prediction.label == expected, "revision": revision}
	tests.append(record)
	if tests.size() > 90: tests.pop_front()
	return record

func snapshot() -> Dictionary:
	return {"schema": SCHEMA, "weights": Array(weights), "examples": examples.duplicate(true),
		"tests": tests.duplicate(true), "epoch": epoch, "trained": trained,
		"initial_loss": initial_loss, "history": history.duplicate(), "revision": revision}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema") != SCHEMA: return false
	var w: Variant = data.get("weights")
	var rows: Variant = data.get("examples")
	var ep: Variant = data.get("epoch")
	if not w is Array or w.size() != PARAMETERS or not rows is Array or rows.size() > MAX_PER_CLASS * CLASSES: return false
	if not (ep is int or ep is float) or float(ep) != int(ep) or ep < 0 or ep > EPOCHS: return false
	if not data.get("trained") is bool: return false
	for v in w:
		if not (v is int or v is float) or not is_finite(float(v)) or absf(float(v)) > 1000.0: return false
	var amounts := [0, 0, 0]
	for row in rows:
		if not row is Dictionary or not row.get("x") is Array or not valid_input(row.x): return false
		var label: Variant = row.get("label")
		if not (label is int or label is float) or float(label) != int(label) or label < 0 or label >= CLASSES: return false
		amounts[int(label)] += 1
		if amounts[int(label)] > MAX_PER_CLASS: return false
	if data.trained:
		if int(ep) != EPOCHS: return false
		for n in amounts:
			if n < 3: return false
	weights = PackedFloat64Array(w)
	examples = rows.duplicate(true)
	epoch = int(ep)
	trained = data.trained
	# Re-open a saved model as a new evaluation session. Do not import stale claims.
	tests.clear()
	history.clear()
	initial_loss = loss()
	history.append(initial_loss)
	revision += 1
	return true

func save_file(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(), "  ", true, true))
	return file.get_error()

func load_file(path: String) -> bool:
	if not FileAccess.file_exists(path): return false
	return restore(JSON.parse_string(FileAccess.get_file_as_string(path)))
```


## Complete museum study

<!-- student-code:pose_study.gd -->
```gdscript
extends Node3D

const Learner = preload("pose_learner.gd")
const PointBody = preload("point_body.gd")
# Supplied museum interface; it creates and names every button used below.
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const SAVE_PATH := "user://ada_student_pose_v1.json"
var model := Learner.new()
var sphere: PointBody
var surface: MeshInstance3D
var material := StandardMaterial3D.new()
var readout := Label3D.new()
var panel: Node3D
var head: XRCamera3D
var left: XRController3D
var right: XRController3D
var facing := Basis.IDENTITY
var aligned := false
var mode := "TEACH"
var training := false
var capture_label := -1
var capture_time := 0.0
var sample_time := 0.0
var samples: Array = []
var candidate := -1
var dwell := 0.0
var response := -1
var clock := 0.0
var message := "TEACH: choose A, B or C. Hold after the countdown."

func _ready() -> void:
    sphere = PointBody.new()
    sphere.position = Vector3(0, 1.15, 0.15)
    add_child(sphere)
    surface = sphere.get_child(0) as MeshInstance3D
    material.albedo_color = Color(0.75, 0.78, 0.82)
    material.metallic = 0.65
    material.roughness = 0.18
    surface.material_override = material
    # A visible orientation mark: a perfectly plain sphere hides its own spin.
    var ring := MeshInstance3D.new()
    var torus := TorusMesh.new()
    torus.inner_radius = 0.142
    torus.outer_radius = 0.151
    ring.mesh = torus
    var mark := StandardMaterial3D.new()
    mark.albedo_color = Color(0.08, 0.08, 0.1)
    ring.material_override = mark
    surface.add_child(ring)
    var board := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(2.6, 1.5, 0.06)
    board.mesh = box
    board.position = Vector3(0, 1.9, -0.4)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.018, 0.022, 0.035)
    board.material_override = ink
    add_child(board)
    readout.position = Vector3(0, 2.25, -0.35)
    readout.font_size = 26
    readout.pixel_size = 0.002
    readout.width = 1080
    readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    add_child(readout)
    var commands := ["A", "B", "C", "TEACH", "TRAIN", "TEST", "LIVE", "ALIGN", "SAVE", "LOAD"]
    var rows: Array = []
    for names in [["A", "B", "C"], ["TEACH", "TRAIN", "TEST"], ["LIVE", "ALIGN", "SAVE", "LOAD"]]:
        var row: Array = []
        for name in names: row.append({"type":"button", "label":name})
        rows.append(row)
    panel = Rack.create_panel("YOUR POSES / ONE SPHERE", rows)
    panel.position = Vector3(0, 0.85, 0.65)
    panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE * 2
    add_child(panel)
    for i in commands.size():
        var button = panel.find_child("Btn_%d" % i, true, false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area): command(commands[i]))
    bind_tracking()
    refresh()

func bind_tracking() -> void:
    for n in get_tree().root.find_children("*", "XRCamera3D", true, false): head = n; break
    for n in get_tree().root.find_children("*", "XRController3D", true, false):
        if n.tracker == &"left_hand": left = n
        if n.tracker == &"right_hand": right = n

func tracked() -> bool:
    if not is_instance_valid(head) or not is_instance_valid(left) or not is_instance_valid(right): return false
    var tracker := XRServer.get_tracker(&"head") as XRPositionalTracker
    if tracker == null: return false
    var pose := tracker.get_pose(&"default")
    return pose != null and pose.has_tracking_data and left.get_is_active() and right.get_is_active() and left.get_has_tracking_data() and right.get_has_tracking_data() and head.global_position.distance_to(global_position) < 3.0

func align() -> void:
    if not tracked(): return
    var forward := -head.global_basis.z
    forward.y = 0
    if forward.length_squared() < 0.01: return
    facing = Basis.looking_at(forward.normalized(), Vector3.UP)
    aligned = true

static func features(eye: Vector3, l: Vector3, r: Vector3, frame: Basis) -> Array:
    var a := frame.inverse() * (l - eye) / 0.65
    var b := frame.inverse() * (r - eye) / 0.65
    return [a.x, a.y, a.z, b.x, b.y, b.z]

func command(which: String) -> void:
    if training or capture_label >= 0: return
    bind_tracking()
    if which in ["A", "B", "C"]:
        if mode not in ["TEACH", "TEST"] or not tracked():
            message = "Choose TEACH or TEST; head and both hands must be tracked here."
        else:
            if not aligned: align()
            if aligned:
                capture_label = ["A", "B", "C"].find(which)
                capture_time = -3.0
                sample_time = 0
                samples.clear()
    elif which == "TRAIN":
        if model.can_train():
            model.initialize(417)
            training = true
            message = "Training on your examples."
        else: message = "Keep at least three separate takes for each label."
    elif which in ["TEST", "LIVE"]:
        if model.trained:
            mode = which
            if not aligned: align()
            message = "Use a fresh pose."
        else: message = "Teach all three labels, then TRAIN."
    elif which == "TEACH": mode = "TEACH"; message = "A new example requires training again."
    elif which == "ALIGN": align(); message = "Facing aligned." if aligned else "Tracking needed."
    elif which == "SAVE": message = "Saved student model." if model.save_file(SAVE_PATH) == OK else "Save failed."
    elif which == "LOAD":
        if model.load_file(SAVE_PATH):
            mode = "TEST" if model.trained else "TEACH"
            aligned = false
            message = "Loaded. Collect fresh tests."
        else: message = "No valid student save. Current model kept."
    response = -1; candidate = -1; dwell = 0
    refresh()

func _process(delta: float) -> void:
    clock += delta
    if training:
        for _i in 2: model.train_epoch()
        if model.trained:
            training = false; mode = "TEST"
            message = "Training complete. TEST a new take for each label."
    var valid := tracked() and aligned
    var x: Array = features(head.global_position, left.global_position, right.global_position, facing) if valid else []
    advance_capture(delta, x, valid)
    respond(delta, x, valid and mode == "LIVE" and not training)
    refresh()

func advance_capture(delta: float, x: Array, valid: bool) -> void:
    if capture_label < 0: return
    if not valid or not Learner.valid_input(x) or delta > 0.2 or delta < 0:
        capture_label = -1; samples.clear()
        message = "Interrupted take discarded. Choose A/B/C again."
        return
    capture_time += delta
    if capture_time < 0:
        message = "READY %d / arrange both hands" % ceili(-capture_time)
        return
    message = "HOLD / one whole take"
    sample_time += delta
    if sample_time >= 0.05:
        samples.append(x.duplicate()); sample_time = 0
    if capture_time < 0.65: return
    var label := capture_label
    capture_label = -1
    if samples.size() < 8:
        samples.clear(); message = "Too few samples. Repeat the whole take."; return
    var mean := [0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    for row: Array in samples:
        for i in 6: mean[i] += float(row[i]) / samples.size()
    var variance := 0.0
    for row: Array in samples:
        for i in 6: variance += pow(float(row[i]) - mean[i], 2) / (samples.size() * 6)
    samples.clear()
    if sqrt(variance) > 0.12:
        message = "That take moved too much. Hold the pose and try again."; return
    if mode == "TEACH":
        message = "One example kept. Move, then take another." if model.add_example(mean, label) else "Example limit reached."
    else:
        var result: Dictionary = model.test_example(mean, label)
        message = "Meant %s / predicted %s / %s" % [["A","B","C"][label], ["A","B","C"][result.predicted], "accepted" if result.accepted else "withheld"]

func respond(delta: float, x: Array, valid: bool) -> void:
    var prediction: Dictionary = model.predict(x) if valid else {}
    var next := int(prediction.label) if not prediction.is_empty() and prediction.accepted else -1
    if next != candidate: candidate = next; dwell = 0
    dwell += clampf(delta, 0, 0.1)
    response = candidate if candidate >= 0 and dwell >= 0.25 else -1
    if sphere.is_picked_up(): return
    sphere.position = Vector3(0, 1.15, 0.15)
    surface.rotation = Vector3.ZERO
    surface.scale = Vector3.ONE
    if response == 0: sphere.position.y += 0.1 + sin(clock * 2) * 0.08
    elif response == 1: surface.rotation = Vector3(clock * 1.8, clock, 0.3)
    elif response == 2: surface.scale.y = 1.25 + sin(clock * 3) * 0.35
    material.albedo_color = [Color(1,0.24,0.58),Color(0.15,0.84,1),Color(1,0.77,0.25)][response] if response >= 0 else Color(0.75,0.78,0.82)

func refresh() -> void:
    readout.text = "TEACH A SPHERE / %s\n" % mode
    readout.text += "Your takes: A %d / B %d / C %d\n" % model.counts()
    readout.text += "%s\nUpdates %d / loss %.3f\n" % [message, model.epoch, model.loss()]
    readout.text += "Fresh tests: %d / sphere: %s" % [model.tests.size(), ["FLOAT","SPIN","STRETCH"][response] if response >= 0 else "IDLE"]
```

## Change something and account for it

In a fresh session, give the same comfortable pose another label. After retraining, does its response follow the new label? Compare that with changing only FLOAT's height in respond(): one change alters the learned mapping; the other alters what we let its answer do. Explain the difference before running either experiment.

Then test a fresh take without pressing TRAIN. Confirm the number of teaching examples and weights stay fixed. Keep mistakes and withheld responses in your account. The in-memory test list retains only the latest 90 records; this small exercise is not a research evaluation archive. Loading a saved model deliberately starts a fresh list.

## Reconstruction check

Run python tools/test_ml_pose_lesson.py from the project root. It extracts these named code blocks into a separate folder, checks all 83 derivatives against numerical differences, fits synthetic examples, tests unseen fixture takes, permutes labels, checks persistence, constructs the point and label from scratch, and exercises real button signals with supplied XR trackers. It also checks interruption, test/training separation and the three visible responses. No production learner is imported to fill a gap.

Those are real Godot assertions using synthetic data. They establish executable behaviour and some invariants, not recognition accuracy across people, headset comfort or accessibility. This is an author-informed reconstruction, not an independent blind reader. Try your own examples in the museum next.

What travels onward is the same point class, a six-coordinate representation, a labelled dataset and a fitted model. Sequence Memory adds a new question: if both hands pass through the same places in a different order, should the answer stay the same?


---

<!-- Canonical chapter: commons/maps/ML_Sequence_Memory/tutorial.md -->

# Sequence Memory — both hands, in order

## Learning elements

- Carry the point sphere and the same six hand coordinates from Perception.
- Store a complete, timestamped movement instead of one averaged pose.
- Resample takes onto common times; fit a two-hand prototype.
- Test order, timing and each hand separately.
- Compare two taught phrases without forcing every take into A or B.
- Distinguish learned memory, a manual memory cell and replay.

## What we carry

Perception gave the point a learned response to a pose. Its short recording ended as six averages. Make a rising movement with both hands, then the same movement descending. Those averages can be the same. The movement is not.

Keep point_body.gd, pose_learner.gd and pose_study.gd from [Perception](halls/ML_Perception/tutorial.md), unchanged. The new sequence_study.gd **extends pose_study.gd**. Its call to the parent's ready function makes the same pickable PointBody, ring, board and tracking connections. We replace the controls and recording loop; we do not rebuild or explain the sphere again. An existing student pose save is read if present; phrase teaching never alters that model.

The object is continuous as a class and a design. During this study ONE, A/B, tests and replay all use one sphere instance. Reloading a museum hall does not yet transfer the visitor's live node between scenes. The phrase files below preserve learned data locally.

## Where to work

In the ordinary museum, the full phrase station remains in Perception's separate learning bay. In the Sequence Memory hall, inspect the existing gate cell and its transformer diagram. The supplied lesson launcher brings **your printed-code study** into a clear side area in that actual hall; it leaves those exhibits present.

Open res://doc/book/studies/ml-lineage/SequenceMemory.tscn in the Ada project and run it. Its supplied sequence_museum.gd prepares the room. Put the three new files below beside the three carried files. Camera, light, XR tracking, pickup and the RackTemplates button factory remain declared museum infrastructure. Every new learning operation is printed here. Recording needs a tracked head and both controllers; desktop can preview the room.

## Two visits to the same study

On the first visit, keep ONE selected. Your task is to record, fit, replay and test one phrase; leave A/B, label comparison and ambiguity for the second visit. The complete code below supports both visits, so install it once. Read the one-phrase learner and inherited capture first; return to phrase_library.gd when you need two names.

## First visit: one phrase before two

Choose ONE. Invent a comfortable four-second phrase that moves **both** hands. For example: open outward, lift, draw inward and settle. This is your phrase; the model has no supplied dance to copy. Begin from a repeatable arrangement.

Press CAPTURE. Arrange your hands during the three-second count-in. Move on beat 1, continue through eight beats at 120 BPM, and finish at four seconds. A click and the readout mark the time; SOUND toggles the click. STOP discards a pending performance. Lost tracking, a long frame or leaving the station's tracking range discards the whole take.

Each take becomes an array of records. Each record keeps elapsed seconds and the same ordered six values: left x, y, z, then right x, y, z. We still subtract the current head position and divide by 0.65 metres. The horizontal frame is aligned at the start of each take and stays fixed until it ends. This describes hands relative to your moving head; it is not a record of your route across the floor.

Capture at least three separate performances, then TRAIN. Three is an exercise minimum, not evidence of reliable recognition. UNDO removes the latest whole teaching take if you made a mistake. It invalidates the fitted result, so train again.

REPLAY previews the fitted phrase: pink is left, cyan is right. Both paths sit in the air, the tips follow time, and the same sphere follows their midpoint. The display is a bounded miniature; the recogniser uses the unaltered coordinates. The response is authored. It does not mean the system has invented choreography.

Choose TEST, then CAPTURE a **fresh** performance. Testing records an answer without moving the sphere or changing the learned path. TRY records a fresh performance too, but an accepted result then replays the model's path. During capture the learned paths are hidden so the preview does not become the answer you are tracing.

## Why this retains a sequence

The movement learner samples every valid take at 41 common times: 0.0, 0.1, …, 4.0 seconds. When a time falls between recorded samples, sample() interpolates between its two neighbours. A large missing interval is rejected before interpolation.

At each time, fit() averages the six coordinates across the teaching takes. This gives 41 six-number rows. The same mean operation from Perception now happens **separately at each time**. It cannot replace the first moment with the last without changing the model.

This is a learned prototype, not a recurrent neural network. It learns an average path and tolerances directly from examples; there is no backpropagation here. For fixed aligned samples, the coordinate-wise mean minimises summed squared coordinate error. The earlier neural classifier remains available as carried code, but a new kind of observation does not require pretending this prototype has its architecture.

Prediction compares corresponding times and computes a root-mean-square distance **for each hand**, plus its largest single-time error. A good left hand cannot hide a motionless right hand. The code requires a small amount of movement from both hands. That is an explicit two-hand exercise rule, not a universal definition of a phrase.

Limits come from teaching variation. For each take, the code measures its error from the mean of the *other* takes. It widens each hand's limit within fixed bounds, 0.14 to 0.32 coordinate units. Acceptance also caps peak error at 2.5 times that hand's limit. Multiplying distance by 0.65 converts it to metres. Training loss, these limits and the choice to reject are different things.

There is no time warping. The same route at very different moments can be rejected. A deliberate pause is data, not an interruption; missing tracking is an interruption. Conflicting teaching takes can make TRAIN refuse a fit rather than erase the conflict with a huge tolerance.

Before adding another class, demonstrate the first task: record three takes, TRAIN, REPLAY, then TEST a fresh take and its reversal. Explain why order can matter even when the positions or their average look similar. SAVE with ONE selected. Stop here if capture, interpolation or matching still needs work; the next visit reuses this object and file.

## Second visit: then A and B

ONE keeps its own model. Choose A and teach three complete takes; choose B and teach three more. You could teach the rising phrase as A and its reverse as B. TRAIN now fits both.

TEST and TRY compare the new take with **both** models, regardless of which teaching button was last selected. A/B selection tells the program where to store teaching or which model to preview; it never supplies the answer during inference.

- A or B: an accepted choice.
- UNKNOWN: neither prototype accepts the performance.
- AMBIGUOUS: both accept, but their normalised distances are too close to choose.

The comparison uses the worst hand's RMS distance divided by that model's hand limit. Smaller is closer. A difference below 0.20 with both candidates accepted is ambiguous. These scores are distances, not probabilities. Similar teaching under different names is a useful way to produce an ambiguous result deliberately.

Before leaving, save both branches if you want to continue without reteaching: choose ONE and SAVE for Generative, then choose A or B and SAVE for Synthesis. Saving one does not save the other.

SAVE keeps ONE in user://ada_student_phrase_v1.json or both classes in user://ada_student_phrase_ab_v1.json. LOAD validates the saved examples and fitted data before replacing anything; testing starts fresh. The older pose save is separate. Starting an empty scene keeps files on disk until SAVE overwrites the relevant student file. This small study retains only the latest 60 test results in memory; Synthesis will add a richer evaluation record.

## Read the code in this order

Start with valid_take and resample: what counts as a complete observation? Then follow fit, distances and predict: what does the fitted path keep? Read the two-phrase wrapper only after ONE makes sense. Finally trace begin_phrase → advance_phrase → complete_phrase in the host. It carries one whole take into either teaching or testing, and only TRY enables the response.

The three complete new files follow. The reconstruction test also extracts the three declared carried files from Perception's printed text, so no unprinted helper fills a gap.


## One phrase: complete learner

<!-- student-code:movement_learner.gd -->
```gdscript
extends RefCounted
## A learned, time-aligned two-hand prototype. Complete takes are observations.
## Timing is retained: no unordered pose bag and no time warping.
const SCHEMA := "ada-two-hand-phrase-1"
const SECONDS := 4.0
const STEPS := 41
const MAX_TAKES := 12
const MIN_LIMIT := 0.14
const MAX_LIMIT := 0.32
var examples: Array = []
var prototype: Array = []
var limits: Array = []
var tests: Array = []
var trained := false
var fit_error := 0.0
var message := "Record three complete takes of one phrase."

static func number(v: Variant, low: float, high: float) -> bool:
	return (v is float or v is int) and is_finite(float(v)) and float(v)>=low and float(v)<=high

static func valid_x(x: Variant) -> bool:
	if not x is Array or x.size()!=6: return false
	for v in x:
		if not number(v,-4,4): return false
	return true

static func valid_take(take: Variant) -> bool:
	if not take is Array or take.size()<40 or take.size()>100: return false
	var previous := -1.0
	for row in take:
		if not row is Dictionary or not number(row.get("t"),0,SECONDS) or not valid_x(row.get("x")): return false
		if float(row.t)<=previous or (previous>=0 and float(row.t)-previous>0.151): return false
		previous=float(row.t)
	return float(take[0].t)<=0.10 and float(take[-1].t)>=SECONDS-0.05

static func sample(take: Array, t: float) -> Array:
	if take.is_empty(): return []
	if t<=float(take[0].t): return take[0].x.duplicate()
	for i in range(1,take.size()):
		if t<=float(take[i].t):
			var a:Dictionary=take[i-1];var b:Dictionary=take[i]
			var amount:=inverse_lerp(float(a.t),float(b.t),t)
			var x:Array=[]
			for j in 6: x.append(lerpf(float(a.x[j]),float(b.x[j]),amount))
			return x
	return take[-1].x.duplicate()

static func resample(take: Array) -> Array:
	if not valid_take(take): return []
	var rows:Array=[]
	for i in STEPS: rows.append(sample(take,SECONDS*i/(STEPS-1)))
	return rows

static func hand_motion(rows: Array, hand: int) -> float:
	var mean:=Vector3.ZERO
	for x:Array in rows: mean+=Vector3(x[hand*3],x[hand*3+1],x[hand*3+2])/rows.size()
	var variance:=0.0
	for x:Array in rows: variance+=Vector3(x[hand*3],x[hand*3+1],x[hand*3+2]).distance_squared_to(mean)/rows.size()
	return sqrt(variance)

static func distances(a: Array, b: Array) -> Dictionary:
	var rms:=[0.0,0.0];var peak:=[0.0,0.0]
	for i in STEPS:
		for hand in 2:
			var squared:=0.0
			for j in 3: squared+=pow(float(a[i][hand*3+j])-float(b[i][hand*3+j]),2)
			rms[hand]+=squared/STEPS;peak[hand]=maxf(peak[hand],sqrt(squared))
	for hand in 2: rms[hand]=sqrt(rms[hand])
	return {"rms":rms,"peak":peak}

func invalidate() -> void:
	trained=false;prototype.clear();limits.clear();tests.clear();fit_error=0.0

func add_example(take: Array) -> bool:
	var rows:=resample(take)
	if rows.is_empty(): message="Incomplete or invalid take.";return false
	if hand_motion(rows,0)<0.07 or hand_motion(rows,1)<0.07: message="Move BOTH hands through the phrase.";return false
	if examples.size()>=MAX_TAKES: message="Maximum 12 takes. UNDO or RESET first.";return false
	examples.append(take.duplicate(true));invalidate()
	message="One complete phrase kept. Perform it again from the same start."
	return true

func undo() -> bool:
	if examples.is_empty(): return false
	examples.pop_back();invalidate();message="Last teaching take removed. Train again."
	return true

func fit() -> bool:
	invalidate()
	if examples.size()<3: message="Need at least three complete teaching takes.";return false
	var samples:Array=[]
	for take:Array in examples: samples.append(resample(take))
	for i in STEPS:
		var row:=[0.0,0.0,0.0,0.0,0.0,0.0]
		for take:Array in samples:
			for j in 6: row[j]+=float(take[i][j])/samples.size()
		prototype.append(row)
	limits=[MIN_LIMIT,MIN_LIMIT]
	var coherent:=true
	for take:Array in samples:
		var d:=distances(take,prototype)
		for hand in 2:
			# Residual to the average of the OTHER complete takes.
			var leave_one_out:float=d.rms[hand]*samples.size()/(samples.size()-1.0)
			coherent=coherent and leave_one_out<=MAX_LIMIT
			limits[hand]=clampf(maxf(limits[hand],leave_one_out*1.5+0.025),MIN_LIMIT,MAX_LIMIT)
			fit_error+=pow(float(d.rms[hand]),2)/(samples.size()*2)
	if not coherent:
		invalidate();message="Takes differ too much. UNDO an accidental take or RESET; teach one phrase.";return false
	trained=true;message="Timed paths fitted. Test a NEW performance."
	return true

func predict(take: Array) -> Dictionary:
	if not trained: return {}
	var rows:=resample(take)
	if rows.is_empty(): return {}
	var result:=distances(rows,prototype)
	var accepted:=true
	for hand in 2:
		accepted=accepted and result.rms[hand]<=limits[hand] and result.peak[hand]<=float(limits[hand])*2.5 and hand_motion(rows,hand)>=0.07
	result.accepted=accepted
	return result

func test_example(take: Array) -> Dictionary:
	var result:=predict(take)
	if result.is_empty(): return {}
	tests.append(result.duplicate(true))
	if tests.size()>60: tests.pop_front()
	return result

func target(t: float) -> Array:
	if not trained: return []
	var phase:=clampf(t/SECONDS,0,1)*(STEPS-1)
	var a:=mini(int(phase),STEPS-2)
	var result:Array=[]
	for j in 6: result.append(lerpf(prototype[a][j],prototype[a+1][j],phase-a))
	return result

func snapshot() -> Dictionary:
	return {"schema":SCHEMA,"seconds":SECONDS,"examples":examples.duplicate(true),"prototype":prototype.duplicate(true),"limits":limits.duplicate(),"trained":trained}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema")!=SCHEMA or data.get("seconds")!=SECONDS or not data.get("trained") is bool: return false
	if not data.get("examples") is Array or data.examples.size()>MAX_TAKES or not data.get("prototype") is Array or not data.get("limits") is Array: return false
	var candidate:RefCounted=get_script().new()
	for take:Variant in data.examples:
		if not take is Array or not candidate.add_example(take): return false
	if data.trained:
		if not candidate.fit() or data.prototype.size()!=STEPS or data.limits.size()!=2: return false
		for i in STEPS:
			if not valid_x(data.prototype[i]): return false
			for j in 6:
				if absf(float(data.prototype[i][j])-candidate.prototype[i][j])>1e-8: return false
		for hand in 2:
			if not number(data.limits[hand],MIN_LIMIT,MAX_LIMIT) or absf(data.limits[hand]-candidate.limits[hand])>1e-8: return false
	elif not data.prototype.is_empty() or not data.limits.is_empty(): return false
	examples=candidate.examples;prototype=candidate.prototype;limits=candidate.limits
	trained=candidate.trained;fit_error=candidate.fit_error;tests.clear()
	message="Loaded locally. Fresh tests begin here."
	return true

func save_file(path: String) -> Error:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"  ",true,true))
	return file.get_error()

func load_file(path: String) -> bool:
	return restore(JSON.parse_string(FileAccess.get_file_as_string(path))) if FileAccess.file_exists(path) else false
```


## Two phrases: complete comparison

<!-- student-code:phrase_library.gd -->
```gdscript
extends RefCounted
## Two visitor-taught timed prototypes. Labels name examples, not dance quality.
const Learner := preload("movement_learner.gd")
const SCHEMA := "ada-two-hand-phrase-library-1"
const MARGIN := 0.20
var models: Dictionary = {"A": Learner.new(), "B": Learner.new()}
var tests: Array = []
var message := "Teach three whole takes of A and three of B."
var trained: bool:
	get: return models.A.trained and models.B.trained

func add_example(label: String, take: Array) -> bool:
	if not models.has(label): return false
	var kept: bool = models[label].add_example(take)
	message = label + " / " + models[label].message
	if kept: tests.clear()
	return kept

func undo(label: String) -> bool:
	if not models.has(label): return false
	var changed: bool = models[label].undo()
	message = label + " / " + models[label].message
	if changed: tests.clear()
	return changed

func fit() -> bool:
	tests.clear()
	var a: bool = models.A.fit()
	var b: bool = models.B.fit()
	if not a: message = "A / " + models.A.message
	elif not b: message = "B / " + models.B.message
	else: message = "A + B fitted. TEST a NEW whole performance."
	return a and b

func predict(take: Array) -> Dictionary:
	if not trained: return {}
	var a: Dictionary = models.A.predict(take)
	var b: Dictionary = models.B.predict(take)
	if a.is_empty() or b.is_empty(): return {}
	# Worst hand, relative to that prototype's limit. These are distances, not probabilities.
	var sa: float = maxf(a.rms[0]/models.A.limits[0], a.rms[1]/models.A.limits[1])
	var sb: float = maxf(b.rms[0]/models.B.limits[0], b.rms[1]/models.B.limits[1])
	var label := "UNKNOWN"
	if a.accepted and b.accepted:
		label = "AMBIGUOUS" if absf(sa-sb)<MARGIN else ("A" if sa<sb else "B")
	elif a.accepted: label = "A"
	elif b.accepted: label = "B"
	return {"label": label, "accepted": label in ["A", "B"], "scores": [sa,sb], "margin": absf(sa-sb), "candidates": {"A":a,"B":b}}

func test_example(take: Array) -> Dictionary:
	var result := predict(take)
	if result.is_empty(): return {}
	tests.append(result.duplicate(true))
	if tests.size()>60: tests.pop_front()
	return result

func snapshot() -> Dictionary:
	return {"schema":SCHEMA,"margin":MARGIN,"A":models.A.snapshot(),"B":models.B.snapshot()}

func restore(data: Variant) -> bool:
	if not data is Dictionary or data.get("schema")!=SCHEMA or data.get("margin")!=MARGIN: return false
	var a := Learner.new()
	var b := Learner.new()
	if not a.restore(data.get("A")) or not b.restore(data.get("B")): return false
	models={"A":a,"B":b};tests.clear();message="A + B loaded locally. Fresh tests begin here."
	return true

func save_file(path: String) -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"  ",true,true))
	return file.get_error()

func load_file(path: String) -> bool:
	return restore(JSON.parse_string(FileAccess.get_file_as_string(path))) if FileAccess.file_exists(path) else false
```


## The carried sphere: complete extension

<!-- student-code:sequence_study.gd -->
```gdscript
extends "pose_study.gd"
## Keep the PointBody, tracking and coordinate function from Perception.
const Movement = preload("movement_learner.gd")
const Library = preload("phrase_library.gd")
const ONE_FILE := "user://ada_student_phrase_v1.json"
const TWO_FILE := "user://ada_student_phrase_ab_v1.json"
var one := Movement.new()
var library := Library.new()
var selected := "ONE"
var capturing := false
var phrase_time := 0.0
var pending: Array = []
var replay_time := -1.0
var replay_model: RefCounted
var result: Dictionary = {}
var rods: Array[MeshInstance3D] = []
var tips: Array[MeshInstance3D] = []
var click := AudioStreamPlayer3D.new()
var sound := true
var last_beat := -999

func _ready() -> void:
    super._ready() # Creates the same point, ring, collision, board and readout.
    if FileAccess.file_exists(SAVE_PATH): model.load_file(SAVE_PATH)
    remove_child(panel)
    panel.free()
    var rows: Array = []
    var commands: Array = []
    for names in [["ONE","A","B"],["CAPTURE","TEACH","TRAIN"],["TEST","TRY","REPLAY"],["UNDO","SAVE","LOAD"],["SOUND","STOP"]]:
        var row: Array = []
        for word in names:
            row.append({"type":"button","label":word})
            commands.append(word)
        rows.append(row)
    panel = Rack.create_panel("BOTH HANDS / A PHRASE KEPT", rows)
    panel.position = Vector3(0, 0.75, 0.8)
    panel.rotation_degrees.x = -30
    panel.scale = Vector3.ONE * 2
    add_child(panel)
    for i in commands.size():
        var button = panel.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area): command(commands[i]))
    readout.position.y = 2.38
    readout.font_size = 23
    for hand in 2:
        var ink := StandardMaterial3D.new()
        ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        ink.albedo_color = Color(1,0.22,0.55) if hand==0 else Color(0.1,0.8,1)
        for i in Movement.STEPS-1:
            var rod := MeshInstance3D.new()
            var tube := CylinderMesh.new()
            tube.top_radius=0.005; tube.bottom_radius=0.005; tube.height=1
            tube.radial_segments=6
            rod.mesh=tube; rod.material_override=ink; rod.hide()
            add_child(rod); rods.append(rod)
        var tip := MeshInstance3D.new()
        var ball := SphereMesh.new(); ball.radius=0.024; ball.height=0.048
        tip.mesh=ball; tip.material_override=ink; tip.hide()
        add_child(tip); tips.append(tip)
    click.stream=make_click(); click.volume_db=-18
    click.position=Vector3(0,1.4,0.2); click.max_distance=4
    add_child(click)
    mode="TEACH"; message="ONE: record three separate four-second phrases."
    refresh()

func active_model() -> RefCounted:
    return one if selected=="ONE" else library.models[selected]

func ready_to_test() -> bool:
    return one.trained if selected=="ONE" else library.trained

func stop() -> void:
    capturing=false; pending.clear(); replay_time=-1
    click.stop(); last_beat=-999

func command(which: String) -> void:
    if which=="STOP":
        stop(); message="Stopped. No partial take kept."; draw_phrase(); refresh(); return
    if which=="SOUND": sound=not sound; refresh(); return
    if capturing: return # The target cannot change halfway through a take.
    replay_time=-1; result.clear()
    if which in ["ONE","A","B"]:
        selected=which; mode="TEACH"; message="Teach %s. Earlier sets stay." % selected
    elif which=="TEACH": mode="TEACH"; message="CAPTURE a new whole performance."
    elif which=="TRAIN":
        var ok: bool=one.fit() if selected=="ONE" else library.fit()
        if ok: mode="TEST"
        message=one.message if selected=="ONE" else library.message
    elif which in ["TEST","TRY"]:
        if ready_to_test():
            mode=which; message="CAPTURE a fresh phrase; tests never train."
            if which=="TRY": begin_phrase()
        else: message="Teach three takes per set, then TRAIN."
    elif which=="CAPTURE": begin_phrase()
    elif which=="REPLAY":
        if active_model().trained:
            replay_model=active_model(); replay_time=0; last_beat=-999
            message="PREVIEW %s / learned mean, not a recognition result." % selected
        else: message="Train the selected phrase first."
    elif which=="UNDO":
        if selected=="ONE": one.undo(); message=one.message
        else: library.undo(selected); message=library.message
        mode="TEACH"
    elif which in ["SAVE","LOAD"]:
        var store=one if selected=="ONE" else library
        var path:=ONE_FILE if selected=="ONE" else TWO_FILE
        if which=="SAVE":
            message="Saved student phrase." if store.save_file(path)==OK else "Save failed."
        else:
            message="Loaded; collect fresh tests." if store.load_file(path) else "Invalid/missing save; current data kept."
            mode="TEST" if ready_to_test() else "TEACH"
    draw_phrase(); refresh()

func begin_phrase() -> void:
    bind_tracking()
    if not tracked(): message="Head and BOTH tracked hands needed here."; return
    if mode!="TEACH" and not ready_to_test(): message="Train before testing."; return
    align() # Same feature contract; horizontal frame held for this entire take.
    if not aligned: return
    capturing=true; phrase_time=-3.0; sample_time=0; pending.clear()
    replay_time=-1; last_beat=-999
    message="READY 3 / arrange both hands, then move for eight beats."

func _process(delta: float) -> void:
    if capturing:
        var valid:=tracked()
        var x:Array=features(head.global_position,left.global_position,right.global_position,facing) if valid else []
        advance_phrase(delta,x,valid)
    elif replay_time>=0:
        replay_time+=maxf(0,delta)
        if replay_time>Movement.SECONDS: replay_time=-1; click.stop()
        else: beat(replay_time)
    draw_phrase(); refresh()

func beat(t: float) -> void:
    var index:=int(floor(t)) if t<0 else int(floor(t/0.5))
    if index!=last_beat:
        last_beat=index
        if sound and t<Movement.SECONDS:
            click.pitch_scale=1.5 if t<0 else 1.0
            click.play()

func advance_phrase(delta: float, x: Array, valid: bool) -> void:
    if not capturing: return
    if not valid or not Movement.valid_x(x) or delta>0.15 or delta<0:
        stop(); message="Tracking/timing interrupted: WHOLE take discarded."; return
    phrase_time+=delta
    if phrase_time>=Movement.SECONDS-0.000001: phrase_time=Movement.SECONDS
    beat(phrase_time)
    if phrase_time<0:
        message="READY %d / arrange hands" % ceili(-phrase_time); return
    message="%s / BEAT %d OF 8 / move BOTH hands" % [mode,mini(8,int(phrase_time/0.5)+1)]
    sample_time+=delta
    if pending.is_empty() or sample_time>=0.05 or phrase_time>=Movement.SECONDS:
        sample_time=0
        if pending.is_empty() or phrase_time>float(pending[-1].t):
            pending.append({"t":phrase_time,"x":x.duplicate()})
    if phrase_time>=Movement.SECONDS: complete_phrase()

func complete_phrase() -> void:
    var take:=pending.duplicate(true)
    stop()
    if mode=="TEACH":
        if selected=="ONE": one.add_example(take); message=one.message
        else: library.add_example(selected,take); message=library.message
        return
    result=one.test_example(take) if selected=="ONE" else library.test_example(take)
    if result.is_empty(): message="Incomplete take discarded."; return
    if selected=="ONE":
        message="%s / L %.3f / R %.3f (distance)" % ["MATCH" if result.accepted else "UNKNOWN",result.rms[0],result.rms[1]]
        replay_model=one
    else:
        message="%s / distance A %.2f / B %.2f" % [result.label,result.scores[0],result.scores[1]]
        if result.accepted: replay_model=library.models[result.label]
    if mode=="TRY" and result.accepted: replay_time=0; last_beat=-999

func miniature(x: Array, hand: int) -> Vector3:
    # Only the displayed miniature is bounded. Recognition retains full data.
    return Vector3(0,1.65,0.15)+Vector3(x[hand*3],x[hand*3+1],x[hand*3+2]).limit_length(1.8)*0.4

func draw_phrase() -> void:
    var showing:bool=replay_time>=0 and replay_model!=null and replay_model.trained
    for hand in 2:
        for i in Movement.STEPS-1:
            var rod:=rods[hand*(Movement.STEPS-1)+i]
            rod.visible=showing
            if showing:
                var a:=miniature(replay_model.prototype[i],hand)
                var b:=miniature(replay_model.prototype[i+1],hand)
                var direction:=b-a
                rod.position=(a+b)*0.5
                rod.scale=Vector3(1,maxf(direction.length(),0.0001),1)
                rod.quaternion=Quaternion(Vector3.UP,direction.normalized()) if direction.length()>0.0001 else Quaternion.IDENTITY
        tips[hand].visible=showing
        if showing: tips[hand].position=miniature(replay_model.target(replay_time),hand)
    if sphere==null or sphere.is_picked_up(): return
    sphere.position=(tips[0].position+tips[1].position)*0.5 if showing else Vector3(0,1.15,0.15)
    surface.scale=Vector3.ONE
    material.albedo_color=Color(1,0.77,0.25) if showing else Color(0.75,0.78,0.82)

func refresh() -> void:
    # super._ready() calls this before the phrase panel is built.
    readout.text="BOTH HANDS / %s / %s\n" % [selected,mode]
    readout.text+="ONE %d takes / A %d / B %d\n" % [one.examples.size(),library.models.A.examples.size(),library.models.B.examples.size()]
    readout.text+=message+"\n8 BEATS / 120 BPM / 4 SECONDS\n"
    readout.text+="Fresh tests %d / sound %s" % [one.tests.size() if selected=="ONE" else library.tests.size(),"ON" if sound else "OFF"]

static func make_click() -> AudioStreamWAV:
    var wav:=AudioStreamWAV.new()
    wav.format=AudioStreamWAV.FORMAT_16_BITS; wav.mix_rate=22050
    var bytes:=PackedByteArray(); bytes.resize(1102*2)
    for i in 1102:
        var t:=float(i)/wav.mix_rate
        bytes.encode_s16(i*2,int(sin(TAU*880*t)*exp(-t*100)*10000))
    wav.data=bytes
    return wav
```

## Predict a difference, then test it

Before running, predict what happens when you reverse the phrase, exchange the two hands, hold one hand still, or delay a large movement until the final beat. Keep the model fixed and try them as fresh tests. A particular symmetric phrase may survive reversal; rejection is not guaranteed merely because you intended a change. Inspect what actually changed in the recorded coordinates.

Then teach the reverse as B. What was previously unfamiliar can become a taught alternative. The rules of comparison did not change; its examples did. In another fresh experiment, teach near-identical phrases under A and B and inspect the ambiguous result. An independent demonstration of learning is being able to produce and explain both effects without editing the decision rule.

## Compare the room's other kind of memory

The gate cell uses a different representation. Its present state depends on the last state and the new token. Its three gate spheres are set by hand; the current exhibit does not train them. Our prototype keeps a time-indexed path from whole performances. Both involve earlier information, but only the latter fits this visitor's movement examples. Neither exercise implements a trained LSTM.

## Ghost-student reconstruction

Run python tools/test_ml_sequence_lesson.py from the project root. The test writes a fresh learner folder from this chapter's three code blocks plus Perception's three carried blocks. It tests interpolation and the fitted mean with independent calculations, then fresh, reversed, retimed, swapped-hand and stationary-hand fixtures. It checks A/B, unknown and ambiguous results; corrupt saves; whole-take capture with supplied XR trackers; and sphere identity across the controls.

It also mounts the reconstructed code in the actual Sequence Memory hall for a separate spatial/runtime check. Synthetic fixtures can establish that these mechanisms work and catch missing code. They cannot establish recognition across people or headset comfort. This is an author-informed ghost student, not an independent blind reader.

Carry the same point, the six-coordinate contract and a fitted ordered phrase onward. Generative changes the question: would the next result be a replay of what we kept, a sampled variation, or something produced by a trained generator? This chapter establishes the replay we must be able to distinguish from those other operations.


---

<!-- Canonical chapter: commons/maps/ML_Generative/tutorial.md -->

# Generative — another phrase from the same hands

## Learning elements

- Carry PointBody, both hand traces and their shared clock.
- Separate a recorded take, its learned mean and a generated sample.
- Fit variation from whole paired performances.
- Use a seed to repeat a comparison; change the examples to change the model.
- Inspect a generated result without treating it as another teaching observation.

## What we carry into this room

The sphere in Sequence Memory could recognise and replay a phrase. Here it produces a variation. We keep the same PointBody, pickup, head-relative coordinates, four-second capture, beat and airborne paths. The sphere follows their midpoint; that response is still authored.

In the hall, the large generator/discriminator exhibit illustrates an adversarial exchange. Its moving losses are scripted. Our side study fits a small statistical generator from your own performances. It does not implement the diagram's GAN, a VAE or diffusion. Learning a distribution does not require all three.

Keep the six files from [Perception](halls/ML_Perception/tutorial.md) and [Sequence Memory](halls/ML_Sequence_Memory/tutorial.md) in the same folder: point_body.gd, pose_learner.gd, pose_study.gd, movement_learner.gd, phrase_library.gd and sequence_study.gd. Add the two complete files below. generative_study.gd extends sequence_study.gd; its inherited ready function makes the same sphere. The A/B code stays carried, but this lesson uses one family of phrases.

Run res://doc/book/studies/ml-lineage/Generative.tscn inside Ada. The supplied generative_museum.gd mounts the study in the actual Generative hall. Camera, light, XR Tools tracking/pickup and RackTemplates buttons are supplied museum infrastructure. This lesson preview leaves the existing diagram in place. Class and saved data carry across halls; a live node is not yet transferred between hall loads.

## Begin with your saved movement

In Sequence Memory, select ONE and SAVE. Here IMPORT reads that file without altering it. Or CAPTURE at least three separate takes here. The familiar three-second count-in leads into eight beats at 120 BPM. Move both hands for the full four seconds. Tracking loss or a long frame discards the whole take. STOP discards a pending performance; SOUND toggles the click.

Use variations of one recognisable phrase: for example, open outward, lift, draw inward and settle. Change the width or height slightly between takes while keeping their timing comparable. Three takes is an exercise minimum. It gives a very narrow account of possible movement.

FIT reads those complete takes. Now compare:

| Control | What produces the paths? |
| --- | --- |
| SOURCE | Your first recording, interpolated onto the display's 41 times. No new performance is generated. |
| MEAN | The average of the teaching takes at each time. Nobody necessarily performed it exactly. |
| DRAW | The learned mean plus a sampled combination of the differences found in your takes. |

Pink remains left; cyan remains right. The two tips travel together on the same clock. As before, this is a bounded miniature, not a full-size instruction to put your hands there. Capture hides the preview. No generated movement drives the player's body.

Press DRAW twice. With the same fitted data, amount and seed, it repeats the sample. NEXT changes the seed and draws again. LESS and MORE change the variation amount in steps of 0.25, from 0 to 1. At zero the generated result is the mean. The display names the result; randomness alone is not evidence of improvement.

SAVE stores source takes in user://ada_student_generation_takes_v1.json; LOAD restores them. IMPORT reads user://ada_student_phrase_v1.json from the previous hall. A successful load, added take or UNDO invalidates this generator: FIT again. Invalid files leave the current data intact. Generated paths are never added to teaching. The seed/amount and candidate are session controls, not saved in this small version. To repeat a result later, record them along with the source file and Godot version.

## What FIT learns

The resampler from Sequence Memory gives each take 41 rows of six numbers. Average each coordinate separately at each time to obtain the mean. Then subtract the mean from each whole take. The resulting array is that take's **residual**: how both hands differed throughout the phrase.

To generate, draw one normally distributed coefficient per residual. Keep that coefficient fixed across every time and both hands. Multiply each residual by its coefficient, add them, then add the mean. We reuse normal randomness from the earlier sequence; we do not scatter fresh independent noise at every point.

That shared coefficient matters. If the examples associate a wider left-hand arc with a higher right hand, their residuals retain that relationship. Independent jitter would lose it. If every teaching take is identical, all residuals are zero: changing the seed cannot create variation the model never observed.

The amount controls distance from the mean. Dividing the residual sum by the square root of (number of takes minus one) gives a precise statistical construction: before preview filtering, at amount 1 its expected covariance equals the sample covariance of the aligned takes. Covariance records which coordinates vary together, including across hands and times. At amount 0.5 the variance is one quarter as large. You can follow the loops without building a covariance matrix.

This is a fitted Gaussian trajectory model. The Gaussian choice and the amount are our decisions; the mean and correlated directions come from data. It can combine and extrapolate observed differences, but cannot learn a new direction of variation from nothing. Unlike recognition, FIT does not impose the previous matching tolerance. Mixing unrelated phrases can therefore produce an unhelpful average. Start with one family and inspect what happens.

## How large is its possibility space?

Each resampled phrase contains 41 × 6 = 246 numbers. But N teaching takes do not supply N independent residual directions: their deviations from the mean add to zero, so one can be written using the others. The generator can therefore vary in **at most N−1 independent directions** around the mean. Three takes give at most two; twelve give at most eleven. Repeated or dependent examples can give fewer. This is the rank limit of this empirical model, not a limit on every kind of generative system.

Use that fact as an experiment. Teach only wider and narrower versions of one phrase, then change the seed repeatedly. Does a new seed introduce a different order of movements? It cannot invent a direction absent from these residuals. Teach a different timed variation deliberately, refit, and compare again. More randomness and a richer set of examples are different changes.

## What a sample does not establish

A normal distribution has tails. The code retains the raw result and withholds its preview if a coordinate leaves the existing range or either hand lacks the exercise's minimum movement. It does not clip the data or secretly redraw until a pleasant sample appears. These are display policies, not a test of beauty, bodily feasibility or dance quality. Filtering also changes the distribution of the previews you see.

A path that differs from all recordings is evidence of a new numerical sample. It does not settle originality, intention or value. The large adversarial diagram asks a further question: what if another learned model supplies the judgement? Here there is no trained critic; inspect the result yourself.

## Complete new learner

Read fit first: it reuses resample, calculates the mean and keeps each complete residual. Then read compose: one coefficient stays attached to each residual. draw supplies those coefficients with its own seeded random generator, so other museum randomness cannot alter the comparison. Godot documents seeded sequences and normally distributed randfn values; reproducibility across engine versions is not promised. [Godot RandomNumberGenerator](https://docs.godotengine.org/en/4.4/classes/class_randomnumbergenerator.html)

<!-- student-code:phrase_generator.gd -->
```gdscript
extends RefCounted
## Fit a Gaussian distribution over complete, aligned, paired hand paths.
const Movement = preload("movement_learner.gd")
var mean: Array = []
var residuals: Array = []
var trained := false
var message := "Fit at least three whole takes."

func clear() -> void:
    mean.clear(); residuals.clear(); trained=false

func fit(takes: Array) -> bool:
    clear()
    if takes.size()<3 or takes.size()>Movement.MAX_TAKES:
        message="Need 3 to 12 complete takes."; return false
    var aligned: Array=[]
    for take in takes:
        if not Movement.valid_take(take):
            message="Incomplete or invalid take."; return false
        var rows: Array=Movement.resample(take)
        if Movement.hand_motion(rows,0)<0.07 or Movement.hand_motion(rows,1)<0.07:
            message="Each teaching take must move both hands."; return false
        aligned.append(rows)
    for i in Movement.STEPS:
        var row: Array=[0.0,0.0,0.0,0.0,0.0,0.0]
        for take: Array in aligned:
            for j in 6: row[j]+=float(take[i][j])/aligned.size()
        mean.append(row)
    for take: Array in aligned:
        var difference: Array=[]
        for i in Movement.STEPS:
            var row: Array=[]
            for j in 6: row.append(float(take[i][j])-float(mean[i][j]))
            difference.append(row)
        residuals.append(difference)
    trained=true; message="Mean and joint variation fitted."
    return true

func draw(sample_seed: int, amount: float) -> Dictionary:
    if not trained or not is_finite(amount) or amount<0 or amount>1: return {}
    var rng:=RandomNumberGenerator.new()
    rng.seed=sample_seed
    var weights: Array=[]
    for _take in residuals: weights.append(rng.randfn(0,1))
    return compose(weights,amount)

func compose(weights: Array, amount: float) -> Dictionary:
    if not trained or weights.size()!=residuals.size(): return {}
    if not is_finite(amount) or amount<0 or amount>1: return {}
    for value in weights:
        if not (value is int or value is float) or not is_finite(float(value)): return {}
    var rows: Array=mean.duplicate(true)
    var factor:=amount/sqrt(float(residuals.size()-1))
    # ONE coefficient per WHOLE residual, shared by both hands and all times.
    for k in residuals.size():
        for i in Movement.STEPS:
            for j in 6: rows[i][j]+=factor*float(weights[k])*float(residuals[k][i][j])
    var inside:=true
    for row: Array in rows: inside=inside and Movement.valid_x(row)
    var moving:=Movement.hand_motion(rows,0)>=0.07 and Movement.hand_motion(rows,1)>=0.07
    # Keep raw output inspectable; do not clip, retry or call it a dance score.
    return {"rows":rows,"weights":weights.duplicate(),"amount":amount,
        "previewable":inside and moving,
        "reason":"Ready to preview." if inside and moving else "Outside coordinate or two-hand-motion policy; preview withheld."}
```

## Extend the existing study

The host replaces the panel and the meaning of a completed take. Recording, interruption, timing, the sphere and drawing stay inherited. show_rows borrows the old playback format only; setting its display flag does not fit a recogniser.

<!-- student-code:generative_study.gd -->
```gdscript
extends "sequence_study.gd"
## Carry the sphere, tracked capture, beat and two airborne paths.
const Generator=preload("phrase_generator.gd")
const GENERATION_FILE:="user://ada_student_generation_takes_v1.json"
var generator:=Generator.new()
var sample_seed:=1
var amount:=0.5
var generated:Dictionary={}
var display_phrase:=Movement.new()

func _ready() -> void:
    super._ready()
    remove_child(panel); panel.free()
    var rows:Array=[]; var commands:Array=[]
    for names in [["CAPTURE","FIT","SOURCE"],["MEAN","DRAW","NEXT"],["LESS","MORE","IMPORT"],["UNDO","SAVE","LOAD"],["SOUND","STOP"]]:
        var row:Array=[]
        for word in names:
            row.append({"type":"button","label":word}); commands.append(word)
        rows.append(row)
    panel=Rack.create_panel("SAME PHRASE / ANOTHER POSSIBILITY",rows)
    panel.position=Vector3(0,0.75,0.8); panel.rotation_degrees.x=-30
    panel.scale=Vector3.ONE*2; add_child(panel)
    for i in commands.size():
        var button=panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(commands[i]))
    mode="TEACH"; message="IMPORT saved ONE or CAPTURE 3 takes, then FIT."
    refresh()

func invalidate_generation() -> void:
    generator.clear(); generated.clear(); replay_time=-1
    display_phrase.invalidate()

func complete_phrase() -> void:
    var take:=pending.duplicate(true)
    stop()
    if one.add_example(take): invalidate_generation()
    message=one.message

func command(which:String) -> void:
    if which=="STOP": stop(); message="Stopped; no partial take kept."; draw_phrase(); refresh(); return
    if which=="SOUND": sound=not sound; refresh(); return
    if capturing: return
    stop()
    if which=="CAPTURE": mode="TEACH"; begin_phrase()
    elif which=="FIT":
        generated.clear(); generator.fit(one.examples); message=generator.message
    elif which=="SOURCE":
        generated.clear()
        if not one.examples.is_empty():
            show_rows(Movement.resample(one.examples[0]))
            message="SOURCE / first recorded take, resampled for display."
        else: message="Record or import a take first."
    elif which=="MEAN": preview(0.0)
    elif which=="DRAW": preview(amount)
    elif which=="NEXT": sample_seed+=1; preview(amount)
    elif which=="LESS": amount=maxf(0,amount-0.25); preview(amount)
    elif which=="MORE": amount=minf(1,amount+0.25); preview(amount)
    elif which=="UNDO":
        if one.undo(): invalidate_generation()
        message=one.message
    elif which=="SAVE":
        message="Saved source takes separately." if one.save_file(GENERATION_FILE)==OK else "Save failed."
    elif which in ["LOAD","IMPORT"]:
        var path:=ONE_FILE if which=="IMPORT" else GENERATION_FILE
        if one.load_file(path):
            invalidate_generation(); message="Source takes loaded. FIT before generating."
        else: message="Missing/invalid source file; current model kept."
    draw_phrase(); refresh()

func preview(strength:float) -> void:
    generated=generator.draw(sample_seed,strength)
    if generated.is_empty(): message="FIT valid teaching takes first."; return
    message=generated.reason
    if generated.previewable:
        show_rows(generated.rows)
        message="MEAN / no variation" if strength==0 else "GENERATED / seed %d / amount %.2f"%[sample_seed,strength]

func show_rows(rows:Array) -> void:
    display_phrase.prototype=rows.duplicate(true)
    display_phrase.trained=true # Playback adapter, not a fitted recogniser.
    replay_model=display_phrase; replay_time=0; last_beat=-999

func refresh() -> void:
    readout.text="A PHRASE VARIED / %d source takes\n"%one.examples.size()
    readout.text+="Fitted %s / seed %d / amount %.2f\n"%["YES" if generator.trained else "NO",sample_seed,amount]
    readout.text+=message+"\nSOURCE = recording / MEAN = fit / DRAW = sample\n"
    readout.text+="8 beats / 120 BPM / sound "+("ON" if sound else "OFF")
```

## Make an independent comparison

Before changing anything, predict which operation should move the mean and which should only change the sample. Keep the seed fixed, add a deliberately higher version of the same phrase, FIT and DRAW again. Inspect both MEAN and DRAW. Now keep the data fixed and use NEXT: the mean must stay put. Finally try three copies of one take in the test fixture; no seed should produce a different path beyond rounding error.

For a relationship test, use fixtures where every left-hand height difference accompanies twice that difference in the right hand. The generated differences should retain the factor of two at every sampled time. This distinguishes a fitted joint generator from six independent noise sources.

The ghost reconstruction extracts all eight files from the three printed chapters. It tests the numerical construction, data changes, deterministic sampling, invalid input, unchanged teaching during generation, button signals and the same point in the native museum. Synthetic fixtures cannot establish that a person will enjoy or be able to perform the result. Try the phrase yourself and keep that observation separate.

Keep the original recordings and one specific comparison. The next hall returns to the A/B library saved in Sequence Memory; its IMPORT does not read this generator or its ONE file. In Synthesis we will declare an intention before a fresh attempt and examine the answer. A candidate and its evaluation need their own records.


---

<!-- Canonical chapter: commons/maps/ML_Synthesis/tutorial.md -->

# Synthesis — an intention and an answer

## Learning elements

- Carry the sphere, the two-hand capture and the trained A/B phrase library.
- Declare intention before inference; keep it out of the classifier.
- Count A, B, UNKNOWN and AMBIGUOUS separately.
- Keep fresh checks separate from teaching and preview.
- Keep each result beside the exact model and take that produced it.
- Revise teaching deliberately, then evaluate with new performances.

## The same sphere, a different question

Sequence Memory asked which taught phrase a fresh movement resembles. Generative asked how another path could be produced from recorded variation. Here we ask whether the recogniser's answer agrees with what you meant to perform. A plausible generated path does not establish that agreement. We return to the saved A/B recogniser; we do not train it on generated output.

Keep all eight files from [Perception](halls/ML_Perception/tutorial.md), [Sequence Memory](halls/ML_Sequence_Memory/tutorial.md) and [Generative](halls/ML_Generative/tutorial.md). Add the two files printed below. synthesis_study.gd extends sequence_study.gd, where the A/B recogniser and recording loop live. This branch reuses the same PointBody, pickup, beat and both-hand paths. It adds a journal and controls; it does not build a different sphere or a new classifier.

In the ordinary museum the full CHECK station remains in Perception. Run res://doc/book/studies/ml-lineage/Synthesis.tscn to place your printed study in the actual Synthesis hall beside its existing exhibits. synthesis_museum.gd is the supplied room launcher. Camera, lighting, XR tracking, XR Tools pickup and RackTemplates buttons remain declared project infrastructure. Put the new files beside the carried ones in res://doc/book/studies/ml-lineage/. Across hall loads, class and saved data carry; one live node is not yet transported between scenes.

## Bring the model, then declare an intention

In Sequence Memory, select A or B and SAVE the trained library. Here IMPORT reads user://ada_student_phrase_ab_v1.json without overwriting it. If you have no saved library, use TEACH A and CAPTURE at least three takes, then TEACH B and CAPTURE three more. TRAIN fits both and enters CHECK. Teaching target means where examples go; it does not supply an inference answer.

Choose CHECK, then MEANT A, MEANT B or OTHER. OTHER means you intend neither taught phrase. It is your declaration, not a third trained class. Press CAPTURE. Keep the same comfortable phrase timing: a three-second count-in followed by four seconds, eight beats at 120 BPM. Both hands are recorded in the same six head-relative coordinates as before.

During the take, the intention and model are locked. The model sees the measured movement only. After prediction, the journal joins the answer to your declaration. It then clears the intention, so the next take needs a new choice. STOP or lost tracking discards the whole pending take and its intention. Neither counts as UNKNOWN: no valid inference happened.

CHECK does not move the sphere in response to a classification. REPLAY is still a preview of the selected teaching phrase; it adds no check. During capture the preview paths and count table are hidden. SOUND toggles the click. The result is a comparison you can inspect before deciding what to change.

## Read the table

Rows are what you declared: A, B or OTHER. Columns are what the model returned: A, B, UNKNOWN or AMBIGUOUS. Each completed, admissible take adds one to one cell.

- Meant A, answered A: agreement for this take under this model.
- Meant A, answered B: a mismatch to investigate.
- Meant A, answered UNKNOWN: neither prototype accepted it.
- Meant A, answered AMBIGUOUS: both accepted it too similarly to choose.
- Meant OTHER, answered A: something outside your intended labels was accepted as A.

UNKNOWN and AMBIGUOUS are not interchangeable. Neither is a verdict that your movement is bad. Intention is also not unquestionable ground truth: you could press the wrong button, change your mind or perform differently from what you intended. Keep the discrepancy visible before assigning its cause.

The table shows **counts for the current model**, plus the number retained under earlier versions. There is no combined accuracy badge. A few repeated personal checks, performed after seeing the previews, do not establish accuracy for other people or independent performances.

## What the journal keeps

Each row contains the declaration, result with distance scores, whole timed take, take identifier and model identifier. The model snapshot includes both teaching sets, fitted paths, tolerances and ambiguity policy. Its digest is a compact identifier computed from that saved data. It identifies this local snapshot; it does not certify that a model is true, or replace the code version needed to reproduce its behaviour.

The journal refuses an exact teaching take and refuses to count the same exact take twice under the same model, even under another intention. That catches accidental reuse. It cannot prove independence or detect every near-duplicate. A changed model may be compared against a kept take, but that is a repeated comparison, not a new performance. Our normal CHECK flow records a new performance every time.

EXPORT writes the complete journal, including model snapshots and takes, to user://ada_student_synthesis_checks_v1.json. It stays local. A later EXPORT overwrites that file, so copy it if you need several sessions. At 120 records the journal refuses more until you export and clear. CLEAR requires a second press within four seconds; it leaves teaching and exported files alone. Closing the scene loses unexported checks. This small lesson exports evidence; it does not import an old evaluation journal.

## Revise without erasing the question

After a mismatch, EXPORT. Choose TEACH A or TEACH B, record a deliberate **new** teaching performance and TRAIN. This invalidates the old fit before changing it. Return to CHECK and make new performances. The old rows stay linked to their earlier snapshot; the visible table counts the current one. If the full snapshot is identical, it is the same version for this journal.

SAVE writes the revised A/B library to user://ada_student_synthesis_ab_v1.json; LOAD reads that file. The earlier hall's file is only read by IMPORT. A failed load leaves the current model intact. Neither fitting, importing nor previewing changes the journal's earlier observations. Checking never calls fit or add_example.

The existing anomaly exhibit provides a comparison. Its default score sums absolute displacement from the sample mean after scaling each coordinate by its spread. A threshold raises some points. That is a rule relative to a reference population, not a check against a visitor's declared intention. Keep these questions separate when moving between the exhibits.

## Complete journal

Read record first. It checks the declaration and duplicate rules, calls predict with only the take, then stores the declaration alongside the returned result. summary groups recorded outcomes by model identifier. This is an evaluation layer over the learner you already built.

<!-- student-code:phrase_evaluation.gd -->
```gdscript
extends RefCounted
## Visitor-declared intent is evaluation data; it never enters prediction or training.
const MAX_RECORDS := 120
const INTENTS := ["A", "B", "OTHER"]
const OUTCOMES := ["A", "B", "UNKNOWN", "AMBIGUOUS"]
var records: Array = []
var models: Dictionary = {}
var message := "Choose an intention before recording a fresh take."

static func digest(value: Variant) -> String:
	return JSON.stringify(value,"",true,true).sha256_text()

func record(model: RefCounted, take: Array, intent: String) -> Dictionary:
	if intent not in INTENTS: message="Choose A, B or OTHER before capturing.";return {}
	if not model.trained: message="Train both phrases before checking.";return {}
	if records.size()>=MAX_RECORDS: message="120 checks kept. EXPORT, then CLEAR to continue.";return {}
	var data: Dictionary = model.snapshot()
	var version := digest(data)
	var take_id := digest(take)
	for label in ["A","B"]:
		for example: Array in data[label].examples:
			if digest(example)==take_id: message="That exact take was teaching data. Record a fresh performance.";return {}
	for row: Dictionary in records:
		if row.model_id==version and row.take_id==take_id:
			message="That exact take is already counted for this model.";return {}
	# Only measured movement reaches the classifier. Intent is attached afterwards.
	var result: Dictionary = model.predict(take)
	if result.is_empty(): message="Incomplete or invalid take; nothing counted.";return {}
	var row := {"model_id":version,"take_id":take_id,"intent":intent,"result":result.duplicate(true),"take":take.duplicate(true)}
	models[version]=data.duplicate(true)
	records.append(row)
	message="Meant %s / model said %s. One whole take counted."%[intent,result.label]
	return row.duplicate(true)

func summary(model: RefCounted) -> Dictionary:
	var version := digest(model.snapshot())
	var matrix := [[0,0,0,0],[0,0,0,0],[0,0,0,0]]
	var count := 0
	for row: Dictionary in records:
		if row.model_id!=version: continue
		matrix[INTENTS.find(row.intent)][OUTCOMES.find(row.result.label)]+=1
		count+=1
	return {"matrix":matrix,"total":count,"previous":records.size()-count,"model_id":version}

func snapshot() -> Dictionary:
	return {"schema":"ada-phrase-checks-1","intent_labels":INTENTS,"result_labels":OUTCOMES,"models":models.duplicate(true),"records":records.duplicate(true),"scope":"Visitor-declared intent; repeated personal checks, not an independent accuracy estimate. No automatic training."}

func clear() -> void:
	records.clear();models.clear();message="Check history cleared. Teaching data and saved files remain."

func export_file(path: String) -> Error:
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file==null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot(),"  ",true,true))
	return file.get_error()
```

## Extend the museum study

The host locks intention at the start, records the current model identifier and checks it again at completion. A model changed during a take cannot silently become the basis of that check. The inherited capture still discards incomplete tracking.

<!-- student-code:synthesis_study.gd -->
```gdscript
extends "sequence_study.gd"
## The classifier receives a take; only the journal receives an intention.
const Evaluation=preload("phrase_evaluation.gd")
var journal:=Evaluation.new()
var intent:=""
var locked_model:=""
var totals:Dictionary={}
var matrix_display:=Node3D.new()
var matrix_cells:Array[Label3D]=[]
var matrix_footer:=Label3D.new()
var clear_until:=0
var import_path:=TWO_FILE
var model_path:="user://ada_student_synthesis_ab_v1.json"
var export_path:="user://ada_student_synthesis_checks_v1.json"

func _ready() -> void:
    super._ready()
    remove_child(panel);panel.free()
    var rows:Array=[];var commands:Array=[]
    for names in [["TEACH A","TEACH B","CHECK"],["MEANT A","MEANT B","OTHER"],["CAPTURE","TRAIN","IMPORT"],["REPLAY","SAVE","LOAD"],["EXPORT","CLEAR","STOP"],["SOUND"]]:
        var row:Array=[]
        for word in names:
            row.append({"type":"button","label":word});commands.append(word)
        rows.append(row)
    panel=Rack.create_panel("CHECK / AN INTENTION KEPT",rows)
    panel.position=Vector3(-0.75,0.95,0.35);panel.rotation_degrees.x=-30
    panel.scale=Vector3.ONE*2;add_child(panel)
    for i in commands.size():
        var button=panel.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
        button.button_pressed.connect(func(_area):command(commands[i]))
    add_child(matrix_display)
    for row in 4:
        for col in 5:
            var label:=Label3D.new()
            label.position=Vector3([-0.95,-0.52,-0.16,0.30,0.84][col],2.03-row*0.12,-0.35)
            label.font_size=22;label.pixel_size=0.0017
            label.text=["MEANT","A","B","UNKNOWN","AMBIGUOUS"][col] if row==0 else (Evaluation.INTENTS[row-1] if col==0 else "0")
            matrix_display.add_child(label)
            if row>0 and col>0:matrix_cells.append(label)
    matrix_footer.position=Vector3(0,1.50,-0.35)
    matrix_footer.font_size=19;matrix_footer.pixel_size=0.0017
    matrix_display.add_child(matrix_footer)
    readout.position.y=2.39;readout.font_size=21
    selected="A";mode="CHECK"
    message="IMPORT saved A+B, or TEACH A and B here."
    update_totals();refresh()

func update_totals() -> void:
    totals=journal.summary(library)

func stop() -> void:
    super.stop()
    intent="";locked_model=""

func command(which:String) -> void:
    if which=="STOP":stop();message="Stopped; no partial take counted.";draw_phrase();refresh();return
    if which=="SOUND":sound=not sound;refresh();return
    if capturing:return # Intention, data and model stay fixed for this performance.
    replay_time=-1;result.clear()
    if which!="CLEAR":clear_until=0
    if which in ["MEANT A","MEANT B","OTHER"]:
        if mode!="CHECK":message="Choose CHECK before declaring an intention."
        elif not library.trained:message="Train both phrases first."
        else:
            intent=which.trim_prefix("MEANT ")
            message="Next take: %s. This does not enter prediction."%intent
    elif which=="CAPTURE":begin_phrase()
    else:
        intent="";locked_model=""
        if which in ["TEACH A","TEACH B"]:
            selected=which.trim_prefix("TEACH ");mode="TEACH"
            message="CAPTURE a new teaching take for "+selected
        elif which=="CHECK":
            mode="CHECK";message="Choose MEANT A, MEANT B or OTHER, then CAPTURE."
        elif which=="TRAIN":
            if library.fit():mode="CHECK"
            message=library.message
        elif which=="REPLAY":
            if library.models[selected].trained:
                replay_model=library.models[selected];replay_time=0;last_beat=-999
                message="PREVIEW %s. No check counted."%selected
            else:message="Train before previewing."
        elif which=="SAVE":
            message="Saved this revision separately." if library.save_file(model_path)==OK else "Save failed."
        elif which in ["IMPORT","LOAD"]:
            if library.load_file(import_path if which=="IMPORT" else model_path):
                mode="CHECK";message="Model loaded. Earlier checks kept under their own version."
            else:message="Invalid/missing model; current data kept."
        elif which=="EXPORT":
            message="Checks + model snapshots exported locally." if journal.export_file(export_path)==OK else "Export failed; history kept."
        elif which=="CLEAR":
            if Time.get_ticks_msec()<clear_until:
                journal.clear();clear_until=0;message=journal.message
            else:clear_until=Time.get_ticks_msec()+4000;message="Press CLEAR again within four seconds. EXPORT first to retain a file."
    update_totals();draw_phrase();refresh()

func begin_phrase() -> void:
    if mode=="CHECK" and intent not in Evaluation.INTENTS:
        message="Declare your intention BEFORE capture.";return
    super.begin_phrase()
    if capturing:locked_model=Evaluation.digest(library.snapshot())

func complete_phrase() -> void:
    var take:=pending.duplicate(true)
    var declared:=intent;var version:=locked_model
    stop()
    if mode=="TEACH":
        library.add_example(selected,take);message=library.message
    elif version!=Evaluation.digest(library.snapshot()):
        message="Model changed during capture. Nothing counted."
    else:
        var row:Dictionary=journal.record(library,take,declared)
        result={} if row.is_empty() else row.result.duplicate(true)
        message=journal.message
    update_totals()

func refresh() -> void:
    # Parent ready calls this before our panel and matrix are in the tree.
    readout.text="CHECK / %s / teaching target %s\n"%[mode,selected]
    readout.text+="Intention: %s / A %d takes / B %d\n"%[intent if intent!="" else "choose before capture",library.models.A.examples.size(),library.models.B.examples.size()]
    readout.text+=message+"\n8 beats / 120 BPM / no automatic retraining"
    matrix_display.visible=not capturing and replay_time<0
    if totals.is_empty() or matrix_cells.size()!=12:return
    for i in 3:
        for j in 4:matrix_cells[i*4+j].text=str(totals.matrix[i][j])
    matrix_footer.text="%d this model / %d earlier\nColumns = model answer / counts, not a dance score"%[totals.total,totals.previous]
```

## Test the separation

First predict the answer to this experiment. Feed the same held-out fixture to two identical models, once with intention A and once with intention B, using separate empty journals. The prediction must stay the same; only the table row may change. If the answer follows the declared label, the check is leaking its answer into inference.

Then teach deliberately similar A and B phrases and collect a fresh in-between performance. Keep AMBIGUOUS as its own column. Perform a clearly displaced phrase to investigate UNKNOWN. Inspect the per-hand distances in the export; a different intention does not alter them.

Finally keep an earlier journal, change the teaching set, TRAIN and check again. Earlier rows must still reference their own model. No bad result should disappear when a fit improves. The ghost reconstruction tests these boundaries, exact teaching/duplicate rejection, interrupted takes, saving and exporting, real button signals and the same sphere in the native hall. Synthetic tests do not settle human recognition or comfort.

The sequence leaves us with several operations and their evidence: selection, fitting, grouping, recognition, generation and evaluation. For this study, keep the model, source takes, check records and relevant code revision together. Foundations Crisis follows: what has the experiment established, and what have we supplied for it to do so?
