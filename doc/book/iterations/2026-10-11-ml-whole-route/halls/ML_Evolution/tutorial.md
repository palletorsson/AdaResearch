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
