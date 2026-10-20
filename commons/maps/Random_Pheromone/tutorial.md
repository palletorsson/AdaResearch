# A visit enters the next choice

**Learning elements**

- A signal stored at grid addresses
- Deposition and fixed-step decay
- Signal-guided choice mixed with random movement
- Feedback, boundaries and tie-breaking

The Walk point never read its trail; the Monte Carlo board never let a hit guide another sample. Here **a visit can change the next choice**. The point deposits a signal in its grid, then later movement reads that signal. The record enters the mechanism.

At the installed terrain, press ATTRACT, then +1 STEP. The four cyan markers move; places they leave gain scent and height. After several +20 STEPS, select AVOID and advance to the same step count. Each rule starts from the same seeded positions. The caption's 40% means a chance of taking the signal-guided branch on each decision. It does not promise that exactly 40% of a short run used that branch.

## One walker, two records

Build a small study in your local copy of this museum hall. Add a Node3D at hall-local **(10.1, 0, 6.2), Y rotation -90 degrees**, with unit scale. Put the two printed files together and attach `12_a_visit_guides.gd` to it. The prepared museum supplies the working player, camera, light, floor and XR Tools. The study creates all its own geometry. Its front is local positive Z; the table and columns are visual only.

The familiar PointBody supplies four trigger zones along the front: REPLAY, STEP, +20 and RULE. Hold it over the label and press. RULE switches ATTRACT/AVOID and resets the experiment. REPLAY keeps the selected rule. Moving or releasing the point does not advance anything.

There is one simulated walker, shown by a cyan sphere on both grids. Left: current scent, coloured pink. Right: accumulated visits, displayed as column heights. `field`, `visits` and `path` are separate arrays. The grid address is an integer pair; `index()` folds it into the familiar one-dimensional list. Test both coordinates before indexing: a valid flat index alone would not prevent a step from wrapping into another row.

## Follow one update

Press STEP once and read `advance()` in this order:

1. **Fade:** reduce old scent, stopping at zero.
2. **Deposit:** add scent at the point's current address.
3. **Count:** add one visit there. This record does not fade.
4. **Choose:** either consult neighbouring scent or select a random direction.
5. **Move:** keep the destination in `path`, then redraw both views.

The starting position is already in the path. After one step there is one counted visit and two recorded positions; after twenty, twenty visits and twenty-one positions. The destination has not necessarily received a deposit yet. Follow this single update before using +20 or changing ATTRACT to AVOID.

## The complete study

Read `advance()` and `choose()` first. The remaining functions build the display and reuse the point's trigger action.

<!-- student-code:12_a_visit_guides.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const SIDE := 8
const LIMIT := 256
const DT := 0.2
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0),
    Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1),
    Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]

var sample_seed := 42
var guidance := 0.4
var deposit := 0.6
var decay_rate := 0.2
var avoid := false
var at := Vector2i(4, 4)
var field: Array[float] = []
var visits: Array[int] = []
var path: Array[Vector2i] = []
var rng := RandomNumberGenerator.new()
var tiles: Array[MeshInstance3D] = []
var columns: Array[MeshInstance3D] = []
var markers: Array[MeshInstance3D] = []
var point: XRToolsPickable
var status: Label3D

func _ready() -> void:
    box(Vector3(2.8, 0.9, 1.8), Vector3(0, 0.45, 0), Color(0.82, 0.80, 0.76))
    box(Vector3(2.8, 0.6, 0.04), Vector3(0, 1.83, -0.87), Color(0.88, 0.86, 0.81))
    status = label("", Vector3(0, 1.83, -0.83), 25)
    label("SCENT NOW                VISITS KEPT", Vector3(0, 0.97, 0.65), 24)
    label("REPLAY       STEP       +20       RULE", Vector3(0, 0.82, 0.92), 23)
    for y in range(SIDE):
        for x in range(SIDE):
            var cell := Vector2i(x, y)
            tiles.append(box(Vector3(0.12, 0.02, 0.12), place(cell, -0.68), Color.WHITE))
            columns.append(box(Vector3(0.12, 1.0, 0.12), place(cell, 0.68), Color(0.5, 0.5, 0.5)))
    for side in range(2):
        var marker := MeshInstance3D.new()
        var sphere := SphereMesh.new()
        sphere.radius = 0.035
        sphere.height = 0.07
        marker.mesh = sphere
        marker.material_override = material(Color(0.0, 0.75, 0.8))
        add_child(marker)
        markers.append(marker)
    point = PointBody.new()
    point.position = Vector3(0, 1.12, 0.85)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func index(cell: Vector2i) -> int:
    return cell.y * SIDE + cell.x

func valid(cell: Vector2i) -> bool:
    return cell.x >= 0 and cell.x < SIDE and cell.y >= 0 and cell.y < SIDE

func replay() -> void:
    rng.seed = sample_seed
    field.resize(SIDE * SIDE)
    field.fill(0.0)
    visits.resize(SIDE * SIDE)
    visits.fill(0)
    at = Vector2i(4, 4)
    path.assign([at])
    redraw()

func fade(seconds: float) -> void:
    for i in range(field.size()):
        field[i] = maxf(0.0, field[i] - decay_rate * seconds)

func advance(amount: int) -> void:
    for _i in range(mini(amount, LIMIT - (path.size() - 1))):
        fade(DT)
        field[index(at)] += deposit
        visits[index(at)] += 1
        at = choose(at)
        path.append(at)
    redraw()

func choose(cell: Vector2i) -> Vector2i:
    var direction: Vector2i = DIRS[0]
    if rng.randf() < guidance:
        var best := INF if avoid else -1.0
        for d in DIRS:
            var target := cell + d
            if not valid(target):
                continue
            var scent := field[index(target)]
            var better := scent < best if avoid else scent > best
            if better:
                best = scent
                direction = d
    else:
        direction = DIRS[rng.randi() % DIRS.size()]
    var next := cell + direction
    return Vector2i(clampi(next.x, 0, SIDE - 1), clampi(next.y, 0, SIDE - 1))

func change_rule() -> void:
    avoid = not avoid
    replay()

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.6:
        replay()
    elif x < 0.0:
        advance(1)
    elif x < 0.6:
        advance(20)
    else:
        change_rule()

func place(cell: Vector2i, centre: float) -> Vector3:
    return Vector3(centre + (cell.x - 3.5) * 0.14, 0.92, (cell.y - 3.5) * 0.14)

func redraw() -> void:
    for i in range(field.size()):
        tiles[i].material_override.albedo_color = Color(0.95, 0.94, 0.90).lerp(Color(0.8, 0.02, 0.35), clampf(field[i] / 3.0, 0.0, 1.0))
        var height := 0.02 + minf(visits[i] * 0.06, 0.6)
        columns[i].scale.y = height
        columns[i].position.y = 0.91 + height / 2.0
    markers[0].position = place(at, -0.68) + Vector3.UP * 0.06
    markers[1].position = place(at, 0.68) + Vector3.UP * (0.06 + minf(visits[index(at)] * 0.06, 0.6))
    status.text = "%s | seed %d | step %d / %d\nSignal-guided %.0f%% | height caps at 10 visits\nTwo views of ONE walker" % [
        "AVOID" if avoid else "ATTRACT", sample_seed, path.size() - 1, LIMIT, guidance * 100]

func material(colour: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = colour
    result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return result

func box(size: Vector3, position: Vector3, colour: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = position
    view.material_override = material(colour)
    add_child(view)
    return view

func label(words: String, position: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = words
    view.position = position
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.02, 0.02, 0.02)
    view.outline_size = 0
    add_child(view)
    return view
```

## The carried point

Keep the same `point_body.gd` from earlier lessons. It is repeated here only to make the printed dependency complete. The cyan markers are two visual views of one simulated walker; they do not need separate pickup behaviour.

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

## Read the decision

The walker considers eight directions in the listed order. A random draw selects the branch. With `guidance = 0.4`, the signal-guided branch chooses the strongest sensed neighbour for ATTRACT, or the weakest for AVOID. Otherwise another draw selects a direction. This is not a weighted lottery among scent values: the guided branch takes an extreme value.

On an empty field every neighbour has the same value. The strict comparisons, `>` and `<`, leave a tie with the first valid direction. Away from an edge that is positive X. A preference can therefore come from the order of the list, even before any scent is present. Diagonal steps also travel farther than cardinal steps; these are grid moves, not equal-length physical strides.

The guided branch skips sensed addresses outside the grid. A random move is clamped to the edge; it can stay at the same address. It still counts as a step and can add another visit there. Reversals and revisits are allowed. No goal, nest, food source or shortest-path test is hidden in the program.

`fade(DT)` removes 0.04 scent from each positive cell at the default settings, stopping at zero. A departure then adds 0.6 to its address. Scent is not capped in the data. The colour saturates at 3.0; height saturates after ten visits, while the visit count keeps growing. The display compresses the record without changing what the walker reads. There is no entropy calculation here.

The clock advances only when you request steps. Twenty STEP presses and one +20 request therefore agree under the same seed and rule. Waiting between presses changes neither scent nor movement. One request for twenty steps represents four simulated seconds; it does not require four seconds of waiting.

## What was reduced from the hall

The installed artifact has four walkers and 81 × 81 stored vertices, sensing two addresses ahead. It raises a visual surface as visits accumulate. Our reconstruction has one walker on 8 × 8 addresses, senses one address ahead and shows visits separately. It preserves the source's eight-direction branch rule, strict tie order, deposit-before-choice and linear decay. It uses the same seeded random-call pattern for this reduced configuration.

The hall also has a border band: a walker outside its interior is corrected without depositing or choosing on that turn. The small study uses the edge policy stated above and no such band. A full museum run and this reconstruction should not produce identical paths. Nor should ATTRACT and AVOID be expected to keep spending corresponding random draws in the full terrain once their boundary encounters diverge.

## Try a change, then account for it

1. Keep seed 42. Advance ATTRACT to step 100, replay, then reach 100 with five +20 requests. The field, visits and complete path should match. Switch to AVOID and repeat the same number of steps. Explain which comparison changed; do not call either path optimal.
2. Change `guidance` to 1.0. Every decision now uses the signal. Predict the first move on blank ground from the order of `DIRS`. Then change it to 0.0: movement still deposits scent, but never reads that scent. The marks have returned to observer-only history.
3. Restore 0.4 and change `decay_rate` to 0.0. After 100 steps the total stored scent should be 60, allowing for floating-point rounding: one hundred deposits of 0.6 and no loss. The column heights cannot report that total, because their display saturates.

For a separate intervention, temporarily add these two lines immediately after `path.append(at)`:

```gdscript
        fade(20.0)
        # visits and path are deliberately retained
```

Leave decay at 0.2. Each new 0.6 deposit is then erased before the next decision. What still survives on the right? What no longer survives on the left? The current step already chose its destination before this extra fade. That order matters. This is an edited experiment, not an extra twenty seconds on the study's normal step clock.

## What travels onward

A field can remember a visit without storing its whole story, and its influence can outlast or fade before the visible trace. You now have an explicit feedback loop: movement changes the signal; the signal can change movement. In Random Space, we will return to fields formed by combining contributions at different scales. Those values can look like land without having a history of visits at all.
