# A six permits another draw

## Learning elements

- Six discrete outcomes.
- An ordered history and a running total.
- A continuation rule.
- A closed chain versus a display limit.
- Separating the source of a result from what the result does.

Find the single die beside the column marked SIX / THROW AGAIN. A three adds three blocks and ends the chain. A six adds six blocks and permits another throw. The die has not changed its number of faces. The rule has changed what a face can do.

In 10 PRINT, one draw chose between two marks. Here it chooses an integer from one to six. We keep the local generator and familiar PointBody action, then return to the cube as a unit of height. Trace taught us to keep a list; Arrays taught us to visit its entries. Now the list grows until its latest value closes a rule.

## Reconstruct the rule in the museum

Work in your copy of the prepared Endless Museum. Add an empty `Node3D` under Random Cubes and attach `05_a_continuing_die.gd`. Keep `point_body.gd` beside it. The player, lighting, camera and XR Tools are already supplied by Day Zero. A tested temporary bay is hall-local `(1.3, 0, 11.8)`, Y rotation **90 degrees**, facing into the room. This small column and its plinth are visual; they add no physical obstacle.

Hold the point above **DRAW** and press the trigger. One action requests one result. **REPLAY** clears the record and restarts the same seed; press DRAW to reproduce its outcomes. **NEXT SEED** clears the record and prepares another stream. These controls use the point's local position, as in the previous lesson.

The label says **CODED DRAW**. Our generator supplies the number directly. The installed die gets its number from a settled physical orientation. Both can feed the same continuation rule, but a seeded number is not a reconstruction of your hand's throw. We are isolating the rule before rebuilding a whole dice simulation.

Read `draw_face()` and `accept_face()` first. One requests an outcome; the other records it and decides whether another draw is allowed.

<!-- student-code:05_a_continuing_die.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const UNIT := 0.065
const INK := Color(0.07, 0.07, 0.09)
const PINK := Color(0.85, 0.25, 0.46)
const BLUE := Color(0.18, 0.63, 0.75)
@export var seed_value := 42
@export var max_draws := 5
var rng := RandomNumberGenerator.new()
var history: Array[int] = []
var total := 0
var closed := false
var limited := false
var units: Array[MeshInstance3D] = []
var joins: Array[MeshInstance3D] = []
var point: RigidBody3D
var status: Label3D

func box_at(at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
    var box := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    box.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    box.material_override = material
    box.position = at
    add_child(box)
    return box

func text_at(words: String, at: Vector3, size: int = 25) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0025
    add_child(text)
    return text

func _ready() -> void:
    assert(max_draws >= 1 and max_draws <= 8)
    box_at(Vector3(0.65, 0.15, 0), Vector3(0.55, 0.3, 0.55), Color(0.88, 0.87, 0.83))
    for i in range(max_draws * 6):
        units.append(box_at(Vector3(0.65, 0.3 + (i + 0.5) * UNIT, 0),
            Vector3(0.34, UNIT - 0.004, 0.34), PINK))
    for i in range(max_draws):
        joins.append(box_at(Vector3.ZERO, Vector3(0.36, 0.004, 0.36), INK))
    var ceiling := 0.3 + max_draws * 6 * UNIT
    box_at(Vector3(0.65, ceiling + 0.04, 0), Vector3(0.56, 0.02, 0.56), Color(0.9, 0.65, 0.2))
    text_at("%d-DRAW DISPLAY LIMIT" % max_draws, Vector3(0.65, ceiling + 0.17, 0), 21)
    box_at(Vector3(-0.65, 1.5, -0.03), Vector3(1.2, 0.85, 0.05), INK)
    status = text_at("", Vector3(-0.65, 1.5, 0.01))
    point = PointBody.new()
    point.position = Vector3(-0.85, 0.85, 0.7)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = INK
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(activate)
    text_at("REPLAY", Vector3(-0.85, 0.5, 0.7))
    text_at("DRAW", Vector3(0, 0.5, 0.7))
    text_at("NEXT SEED", Vector3(0.85, 0.5, 0.7))
    text_at("Hold point above a label; press trigger", Vector3(0, 0.26, 0.7), 20)
    reset_run()

func continues(face: int) -> bool:
    return face == 6

func reset_run() -> void:
    rng.seed = seed_value
    history.clear()
    total = 0
    closed = false
    limited = false
    draw_record()

func draw_face() -> int:
    if closed or limited:
        return 0
    var face := rng.randi_range(1, 6)
    accept_face(face)
    return face

func accept_face(face: int) -> bool:
    if closed or limited or face < 1 or face > 6:
        return false
    history.append(face)
    total += face
    closed = not continues(face)
    limited = not closed and history.size() >= max_draws
    draw_record()
    return true

func draw_record() -> void:
    for unit in units:
        unit.visible = false
    for join in joins:
        join.visible = false
    var offset := 0
    var terms := PackedStringArray()
    for i in range(history.size()):
        var face := history[i]
        terms.append(str(face))
        joins[i].position = Vector3(0.65, 0.3 + offset * UNIT, 0)
        joins[i].visible = true
        for j in range(face):
            units[offset + j].visible = true
            units[offset + j].material_override.albedo_color = PINK if i % 2 == 0 else BLUE
        offset += face
    var condition := "DRAW TO BEGIN" if history.is_empty() else "CONTINUE / DRAW AGAIN"
    if closed:
        condition = "CLOSED / REPLAY TO BEGIN"
    elif limited:
        condition = "DISPLAY LIMIT / UNFINISHED"
    var equation := "?" if history.is_empty() else " + ".join(terms) + " = " + str(total)
    status.text = "CODED DRAW / Seed %d\n%d of %d draws\n%s\n%s" % [
        seed_value, history.size(), max_draws, equation, condition]

func activate(_body: Variant = null) -> void:
    if point.position.x < -0.4:
        reset_run()
    elif point.position.x > 0.4:
        seed_value += 1
        reset_run()
    else:
        draw_face()
```

## Read one event

`draw_face()` first checks whether the chain is closed or limited. If so, it returns zero without asking the generator for another number. Zero means **no draw** here; it is not a seventh face. Otherwise `randi_range(1, 6)` includes both endpoints and returns one of the six integers. [Godot: RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html)

`accept_face()` is the boundary between an outcome and its consequences. It rejects values outside one through six. For an accepted value, it appends to `history`, adds to `total`, then asks `continues(face)`. Six leaves the chain open; any other face closes it. This function also lets us test the rule with known inputs without pretending those inputs were random throws.

Follow six, six, three on paper. The record becomes `[6, 6, 3]`; the running total becomes six, twelve, fifteen. The third event closes the chain. Fifteen alone cannot tell you how it was made. Keeping the ordered values lets the column show its sections and the label retain its equation.

`draw_record()` makes that record visible. The cubes are already built, so it only changes visibility and colour. `offset` locates the first free unit after each section. Alternating colours and dark joins distinguish successive events, including two sixes in a row. Redrawing consumes no random numbers and adds nothing to the total.

## Two different reasons to stop

The display has room for five draws. Five sixes occupy thirty units, but the continuation rule still says again. The label therefore reads **DISPLAY LIMIT / UNFINISHED**. If the fifth result is three instead, the chain is **CLOSED**. Reaching the apparatus's budget is not the same event as satisfying the stopping rule.

The order of the assignments matters: determine `closed` first, then set `limited` only if the chain remains open. The next press must leave the record and generator unchanged in either terminal state. Nothing waits inside a long `while` loop; another draw needs another action.

## Change one decision

First change only `continues(face)` to return `face >= 5`. Five and six now permit another draw. Keep the seed and replay. The outcomes agree up to the first place where the old rule would have stopped; the changed rule may reveal more of the same stream. This gives more opportunities to continue, not a promise that every run becomes longer. With known inputs six, five, two, the original rule closes at eleven; the changed rule reaches thirteen and then closes.

Next restore the six-only rule and set `max_draws` to `3`. Three sixes now leave an unfinished chain of eighteen units. Six, six, three closes at fifteen even though it uses the final place. The script builds the corresponding number of units and moves the amber limit with it. Explain these two endings before increasing the display again.

For a direct rule check in the running scene, call `reset_run()`, then `accept_face(6)`, `accept_face(6)` and `accept_face(3)` in that order. The expected record is exactly `[6, 6, 3]`, total fifteen, closed true and limited false. A following `accept_face(4)` must return false. These are supplied test inputs. Use `draw_face()` for the generator experiment.

The physical exhibit has one further responsibility: only a fresh release followed by a settled result may enter its record. It ignores repeated readings of the same landing and distinguishes RETURN DIE from NEW CHAIN. That event handling stays with the existing exhibit in this lesson; our point action provides one clearly identified request at a time.

## The inherited point

Keep the same file from the previous hall. It builds its own sphere and collider; XR Tools supplies its pickup, release and action signal. The complete dependency is printed here so no mesh or helper is hidden in a scene.

<details>
<summary>Complete inherited PointBody — keep this file beside the lesson</summary>

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

</details>

You leave with a small procedure: request an outcome, retain it, add its contribution, decide whether another event is allowed. Next, the retained change becomes a turn. A cube's orientation can accumulate increments even when no column remains to show their order.
