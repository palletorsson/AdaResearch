# A population kept

**Learning elements**

- A recipe and its instances
- Discrete choice and continuous scale
- Dictionaries as named records
- Changing a property while keeping the sampled record

In Random Gaussian you kept numbers and changed their grouping. Here a number chooses a body recipe, another turns it, and another sets its scale. The same record can produce a different comparison without another draw.

Start at the specimen bed already in Endless Museum. SHOW identifies copies of one recipe. Press SIZE and follow a pair: their extra scaling disappears, while their places and recipe identities remain. Two bodies at scale one can still have different dimensions.

Reconstruct that operation on a small table beside the garden. Keep twelve fixed places, two simple mushroom recipes, and the PointBody you already use. The installed meadow has six recipes, scattered candidates, rings, clusters and a separate ground generator. Our table isolates one question: **what changes when we stop using the sampled scale?**

## Set it beside the existing work

Use your prepared museum project with XR Tools and the working player. In a local copy of this hall, add a Node3D for the study, at hall-local **(3, 0, 7), Y rotation 90 degrees**, with unit scale. Its front is local positive Z. The museum supplies the camera, lighting and floor.

Save `09_a_population_kept.gd` and the unchanged `point_body.gd` in the same folder, then attach the first to that Node3D. No scene-child references or prebuilt mushrooms are required. The script creates its table, labels, bodies and hand control. These specimen meshes and the table are visual only; they do not supply collision or eating behaviour.

Hold the point over the left, middle or right third of the front edge and press its trigger:

| Place | Action | What remains |
|---|---|---|
| Left: REPLAY | Rebuild this seeded population | Recipes, seed, count and current SIZE setting |
| Middle: SIZE | Apply sampled scales or scale one | Records, existing body nodes, positions, turns and generator state |
| Right: NEXT SEED | Add one to the seed and rebuild | Recipes, places and current SIZE setting |

Moving or releasing the point does not sample. These are the same pickup and trigger behaviours from the earlier chapters.

## The complete study

Read `regrow()` and `apply_sizes()` first. One samples the records; the other changes how a retained size is used. `make_mushroom()` supplies the two familiar primitive constructions.

<!-- student-code:09_a_population_kept.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")

var population_seed := 42
var count := 12
var size_low := 0.7
var size_high := 1.3
var vary_size := true
var recipes: Array[Dictionary] = [
    {"cap": 0.2, "stem": 0.15, "colour": Color(0.8, 0.6, 0.4)},
    {"cap": 0.15, "stem": 0.1, "colour": Color(0.8, 0.2, 0.2)}
]
var records: Array[Dictionary] = []
var bodies: Array[Node3D] = []
var rng := RandomNumberGenerator.new()
var point: XRToolsPickable
var status: Label3D

func _ready() -> void:
    var table := BoxMesh.new()
    table.size = Vector3(3.2, 0.9, 2.3)
    surface(self, table, Vector3(0, 0.45, 0), Color(0.82, 0.81, 0.76))
    label("REPLAY          SIZE          NEXT SEED", Vector3(0, 0.94, 1.02), 25)
    var board := BoxMesh.new()
    board.size = Vector3(3.2, 0.85, 0.05)
    surface(self, board, Vector3(0, 1.7, -1.12), Color(0.94, 0.93, 0.88))
    status = label("", Vector3(0, 1.7, -1.08), 29)
    point = PointBody.new()
    point.position = Vector3(0, 1.12, 1.0)
    add_child(point)
    point.action_pressed.connect(use_point)
    regrow()

func regrow() -> void:
    rng.seed = population_seed
    records.clear()
    for i in range(clampi(count, 0, 12)):
        var kind := rng.randi_range(0, recipes.size() - 1)
        var yaw := rng.randf() * TAU
        var size := lerpf(size_low, size_high, rng.randf())
        records.append({
            "kind": kind,
            "position": Vector3((i % 4 - 1.5) * 0.7, 0.9, (i / 4 - 1) * 0.65),
            "yaw": yaw,
            "size": size
        })
    rebuild()

func rebuild() -> void:
    for body in bodies:
        body.free()
    bodies.clear()
    for record in records:
        var body := make_mushroom(record.kind)
        add_child(body)
        body.position = record.position
        body.rotation.y = record.yaw
        bodies.append(body)
    apply_sizes()

func make_mushroom(kind: int) -> Node3D:
    var recipe: Dictionary = recipes[kind]
    var body := Node3D.new()
    var stem := CylinderMesh.new()
    stem.top_radius = recipe.cap * 0.2
    stem.bottom_radius = recipe.cap * 0.25
    stem.height = recipe.stem
    stem.radial_segments = 8
    surface(body, stem, Vector3(0, recipe.stem / 2, 0), recipe.colour.lightened(0.3))
    var cap := SphereMesh.new()
    cap.radius = recipe.cap
    cap.height = recipe.cap * 1.2
    cap.radial_segments = 16
    cap.rings = 8
    var top := surface(body, cap, Vector3(0, recipe.stem, 0), recipe.colour)
    top.scale.y = 0.5
    return body

func apply_sizes() -> void:
    for i in range(bodies.size()):
        var size: float = records[i].size if vary_size else 1.0
        bodies[i].scale = Vector3.ONE * size
    status.text = "A POPULATION KEPT\nseed %d | %d bodies | %d recipes\n%s" % [
        population_seed, records.size(), recipes.size(),
        "sampled scale" if vary_size else "scale 1 | recipe sizes kept"
    ]

func toggle_size() -> void:
    vary_size = not vary_size
    apply_sizes()

func next_seed() -> void:
    population_seed += 1
    regrow()

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.4:
        regrow()
    elif x < 0.4:
        toggle_size()
    else:
        next_seed()

func surface(parent: Node3D, mesh: Mesh, at: Vector3, colour: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    view.mesh = mesh
    view.position = at
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    view.material_override = material
    parent.add_child(view)
    return view

func label(text: String, at: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = text
    view.position = at
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.08, 0.08, 0.09)
    view.outline_size = 0
    add_child(view)
    return view
```

## Give each value a name

A dictionary stores values under names. The recipe's `cap`, `stem` and `colour` are authored dimensions and material. Each population record names its chosen `kind`, `position`, `yaw` and `size`. Instead of remembering that the third number means rotation, the next function can ask for `record.yaw`.

`records` is still the one-dimensional list from Trace. An index names one member. Each member now holds several related values. The drawn kind is an integer index into `recipes`; it selects one whole recipe. It does not interpolate a new kind between two entries.

`randi_range()` chooses a valid recipe index. `randf() * TAU` chooses a turn around Y in radians. `lerpf(size_low, size_high, rng.randf())` maps a uniform draw into the scale interval, initially 0.7 to 1.3. These sizes use the previous hall's uniform option. A Gaussian lesson does not require every later number to be Gaussian.

The program makes those calls in that order for each record. The current SIZE switch is absent from the sampling loop: a scale value is stored even when it will not be applied. A seed repeats a population only with the same recipe list, call order, parameters and engine behaviour.

Positions return to the four-column grid from Arrays. Remainder chooses the column; integer division chooses the row. Twelve places make three rows. Positions are fixed so that two comparisons can be read at the same addresses. The code bounds the count to zero through twelve, keeping this table's footprint finite. It does not sample the garden's clearings or place bodies at random.

## Construct the body, then transform it

`make_mushroom()` joins the familiar cylinder and sphere meshes. The stem's centre is half its height above the local origin; its bottom therefore stays at zero. The cap sits at stem height and is flattened along Y. These proportions follow the installed bed's standard tan and red recipes, with gills omitted. They are stylised constructions, not biological species.

`rebuild()` reads the saved records and makes bodies. It consumes no randomness. `apply_sizes()` changes only each body's uniform scale. Both parts inherit the scale through their parent, and the stem stays rooted on the table. With scale one, the red recipe still has a shorter stem and smaller cap than the tan recipe. Equal scale is not equal size.

Yaw is saved and applied even though these rotationally symmetric specimens make it hard to see. The record can retain a distinction that the current shape does not reveal. We do not add a decoration merely to teach rotation again.

SIZE keeps the exact body nodes as well as their records. Switching it back restores every sampled scale. REPLAY is a different operation: it resets the generator, makes the records again and creates new nodes. The installed garden also reconstructs on SIZE, keeping scale draws in the same order so the other decisions return. Our smaller table keeps the record directly. These routes support the same comparison through different storage choices.

## The familiar hand control

The point's position is converted from world coordinates into this table's local coordinates before choosing an action. Turn the whole study and its left, middle and right remain attached to the table. The thresholds divide X; this small control does not test distance to the table or snap the point into a socket. Use the labelled edge to locate its zones.

<details>
<summary>Complete unchanged PointBody dependency</summary>

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

## Change one rule and predict the result

1. Change `size_low` to `0.4` and `size_high` to `1.6`. Restart with seed 42. The same members should occupy the same places with the same kinds and turns. Each scale's distance from one doubles. SIZE still sets every parent scale to one. Check the record as well as the silhouette.
2. Change `count` from twelve to six. The first six records of the old population should return, with no new sample inserted before them. Only part of the second row remains. Returning to twelve recovers the full population.
3. Add a third dictionary to `recipes`: cap `0.12`, stem `0.35`, colour `Color(0.9, 0.9, 0.8)`. Restart. The same construction function can now make a tall, narrow member. The sampler can choose index 2; find those entries in the record and their corresponding bodies. Twelve draws need not include every recipe. Changing the number of choices can change which draw is assigned where; a retained seed is not a promise that the old kinds remain.

For an independent check, take two records of the same kind with sizes 0.7 and 1.3. SIZE must make their dimensions equal without moving their origins; restoring it must recover both sizes. Then compare two different kinds at scale one. Explain why they can remain different heights. Rebuild the display twice from the saved records and check that the generator state does not advance.

Changing the population seed explores the current repertoire. Adding the third recipe changes that repertoire. It still cannot produce a hollow cap or a branch: those need another construction instruction. The arrival wardrobe and couture figures in this hall let you inspect that distinction at another scale; building their interfaces is outside this lesson.

Carry the separation onward: **keep the values; decide what relation will turn them into form.** Random Space Geometry compares independently chosen heights with neighbouring heights related by a field. The garden's separate ground and clearing rules have already made that question visible.
