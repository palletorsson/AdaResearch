# Two diagonals, one field

## Learning elements

- Binary choice from a probability threshold.
- One random draw per grid address.
- Reusing a line through rotation and length.
- Seeded replay with a changed rule.
- Observed count versus expected count.

Stand by the printer in the 10 PRINT hall. Each cell receives one of two diagonal marks. A small decision repeats until it becomes a field. In Random Remove, the draw selected an address and took its member away. Here every address stays occupied; the draw chooses what it holds.

We carry forward the grid, a local random-number generator and the familiar pickable point. Lines supplied the endpoints; Transformation supplied rotation. The new operation is a threshold: put the same random number on one side or the other of a probability, then turn the rod accordingly.

## Make a small comparison beside the exhibit

Work in your copy of the prepared Endless Museum. Its player, camera, lights and XR Tools are already running. Add one empty `Node3D` beneath this hall and attach `04_two_diagonals.gd`. Keep `point_body.gd` beside it. No prepared mesh children are needed. A tested temporary bay is hall-local `(3.5, 0, 10)`, with Y rotation **90 degrees**; face its front from the centre of the room. The board and guides are visual geometry, not new walls or a maze with collision.

The complete script builds an eight-by-eight board. Hold the point above a label and press its inherited trigger action:

- **REPLAY:** repeat this seed and probability.
- **BIAS + 0.25:** raise the probability of a pink backslash. After one, return to zero.
- **NEXT SEED:** start another reproducible sequence.

These zones use the point's position **relative to the study**, so they still work when the whole display is turned. This is the same point class and action learned earlier; the lesson adds what that action changes.

Read `choose_backslash()` and `build_pattern()` first. They turn one threshold test into a record of marks. `draw_pattern()` gives that record its lines.

<!-- student-code:04_two_diagonals.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const INK := Color(0.07, 0.07, 0.09)
const PINK := Color(0.72, 0.12, 0.34)
@export var columns := 8
@export var rows := 8
@export var cell_size := 0.22
@export var seed_value := 42
@export var probability := 0.5
var rng := RandomNumberGenerator.new()
var samples: Array[float] = []
var marks: Array[bool] = []
var rods: Array[MeshInstance3D] = []
var point: RigidBody3D
var status: Label3D

func text_at(words: String, at: Vector3, size: int = 26) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0025
    add_child(text)
    return text

func box_at(at: Vector3, size: Vector3, colour: Color) -> void:
    var box := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    box.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    box.material_override = material
    box.position = at
    add_child(box)

func _ready() -> void:
    assert(columns > 0 and rows > 0 and columns <= 16 and rows <= 16)
    assert(cell_size > 0.0 and probability >= 0.0 and probability <= 1.0)
    var width := columns * cell_size
    var height := rows * cell_size
    box_at(Vector3(0, 1.9, -0.045), Vector3(width + 0.12, height + 0.12, 0.05), Color(0.88, 0.87, 0.83))
    for column in range(columns + 1):
        box_at(Vector3(column * cell_size - width / 2, 1.9, -0.01),
            Vector3(0.004, height, 0.004), Color(0.5, 0.5, 0.5))
    for row in range(rows + 1):
        box_at(Vector3(0, 1.9 + height / 2 - row * cell_size, -0.01),
            Vector3(width, 0.004, 0.004), Color(0.5, 0.5, 0.5))
    for row in range(rows):
        for column in range(columns):
            var rod := MeshInstance3D.new()
            var mesh := CylinderMesh.new()
            mesh.top_radius = 0.009
            mesh.bottom_radius = 0.009
            mesh.height = cell_size * sqrt(2.0)
            mesh.radial_segments = 8
            rod.mesh = mesh
            rod.material_override = StandardMaterial3D.new()
            rod.position = Vector3((column + 0.5) * cell_size - width / 2,
                1.9 + height / 2 - (row + 0.5) * cell_size, 0)
            add_child(rod)
            rods.append(rod)
    status = text_at("", Vector3(0, 2.17 + height / 2, 0), 25)
    point = PointBody.new()
    point.position = Vector3(-0.75, 0.85, 0.65)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = INK
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(activate)
    text_at("REPLAY", Vector3(-0.75, 0.5, 0.65))
    text_at("BIAS + 0.25", Vector3(0, 0.5, 0.65))
    text_at("NEXT SEED", Vector3(0.75, 0.5, 0.65))
    text_at("Hold point above a label; press trigger", Vector3(0, 0.26, 0.65), 20)
    build_pattern()

func choose_backslash(sample: float) -> bool:
    return probability >= 1.0 or sample < probability

func build_pattern() -> void:
    rng.seed = seed_value
    samples.clear()
    marks.clear()
    for i in range(rods.size()):
        var sample := rng.randf()
        samples.append(sample)
        marks.append(choose_backslash(sample))
    draw_pattern()

func draw_pattern() -> void:
    var backslashes := 0
    for i in range(marks.size()):
        rods[i].rotation.z = PI / 4 if marks[i] else -PI / 4
        rods[i].material_override.albedo_color = PINK if marks[i] else INK
        if marks[i]:
            backslashes += 1
    status.text = "Seed %d | P(backslash) %.2f\nActual: %d of %d | expected mean: %.2f" % [
        seed_value, probability, backslashes, marks.size(), probability * marks.size()]

func activate(_body: Variant = null) -> void:
    if point.position.x > 0.4:
        seed_value += 1
    elif point.position.x >= -0.4:
        probability += 0.25
        if probability > 1.0:
            probability = 0.0
    build_pattern()
```

## Read the operation

The nested loops build the addresses row by row. `rods[0]` belongs to the top-left cell; `rods[columns]` starts the next row. Each rod is a thin cylinder. A square of side `cell_size` has diagonal length `cell_size * sqrt(2.0)`. Rotating the cylinder by a quarter of a right angle lets its centreline meet the cell's opposite corners. Seen from the board's front, positive `PI / 4` makes a backslash; negative `PI / 4` makes a slash.

`build_pattern()` resets the local generator, then draws once per address. `samples` retains the numbers. `marks` retains their interpretation as `true` or `false`. The chosen rule is `sample < probability`: a threshold of 0.30 assigns roughly thirty percent of future draws to the backslash. Godot's `randf()` can return either endpoint of its interval, so the explicit `probability >= 1.0` case makes probability one mean every mark, including a sample equal to one. Probability zero admits none. [Godot: RandomNumberGenerator](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html)

`draw_pattern()` only reads that record. It changes the rods' rotation and colour, then counts the backslashes. It makes no random request. A redraw therefore cannot quietly become another pattern.

At probability 0.5, sixty-four draws have an expected mean count of thirty-two backslashes. A particular field need not contain thirty-two, and equal odds do not make its arrangement symmetrical. Read **Actual** beside **expected mean**. The neighbouring four-grid exhibit fixes its counts in advance; our program leaves the count to the draws.

## Change the rule and keep the evidence

Press REPLAY. Every number and every mark should return. Press BIAS once. The seed has not changed: the same numbers now meet a higher threshold. Some slashes can become backslashes; none can change in the opposite direction. At one all are pink; at zero all are dark. Return to 0.5 and the first field returns.

For an independent edit, set `probability` to `0.30`. Predict what the label will call the expected mean, then run: it is **19.20**, not a promise of nineteen marks. Keep the seed while comparing other thresholds. Changing the seed is a separate experiment; it does not guarantee a visibly new field, especially when the threshold allows only one mark.

Next set `columns` to `4` and `rows` to `3`. The program now uses the first twelve draws of the same stream. They wrap four to a row. Change the row width again while keeping twelve cells: the ordered choices stay the same, but different cells become neighbours. Use that distinction to explain why rearranging records can change a pattern without changing their values.

Our small board completes a static field at once. The installed printer also has timing, scrolling, a breathing bias and a link to the floor. Its seeded implementation derives a draw from each address; this example reads a sequential generator. Each can replay itself, but the same seed is **not** a claim that these two implementations print the same picture. We are reconstructing the two-mark operation, not replacing the exhibit's full program.

Nor have we written a maze solver. Diagonals can enclose regions or suggest passages. A navigable world additionally needs a definition of connection, boundaries, collision and the body's width. The reflection follows those differences in the hall; this lesson keeps the smaller operation inspectable.

## From the board to a printed dress

The installed **textile_comparison** is now a small studio at the end of the hall. Three draped mesh swatches and the fitting read one retained record. This extends the tiling sequence's distinction between a source, its repeating addresses and its receiving surface. It reuses the wardrobe and dress shapes from the loom's cutting table, with a printed pattern as the material source.

1. Start at **RESET**: seed 41, RIBBON, one repeat. Compare RIBBON, STITCH and PIXEL. These reinterpret the same 14 × 18 addresses as diagonal rails, horizontal/vertical bars, or large/small squares. Selecting one changes the fitting, not the stored draws.
2. Change only **PALETTE**, then only **REPEAT**. Repeats cycle 1×, 2× and 3× in both texture directions. The marks become smaller on the same panel; neither action draws more numbers. **SEED +** is the separate operation that supplies a new record.
3. **KEEP** saves the seed, all 252 draws, mark, palette and repeat count. Make another version, then **REPLAY**. Compare the swatches and fitting with the kept version. The wardrobe's worn snapshot is separate: changing the studio does not silently repaint a dress already worn.
4. Step into the open changing alcove. **SHAPE** previews A-LINE, GOWN or PLEATED; **WEAR** puts the selected fabric and shape on the active desktop or VR avatar. Look down, move a hand and use the full-length mirror. **TAKE OFF** restores the previous outfit.

To reconstruct the smaller operation, keep the board's stored samples and replace `draw_pattern()`'s marks while retaining their addresses. Then put its image on a flat mesh and on a curved mesh with the same texture coordinates. Texture coordinates, or UVs, give each surface point an address in the image. Keep the image fixed and change the surface: where do lines stretch, meet a seam or become harder to follow? Save the values as well as the seed if the generator might change in a later revision.

The studio stores 16-bit integer draws from 0 to 65,535 and compares them with 32,768. That makes its binary choice explicit and its disk replay exact. Its generator is independent of the screen printer and of the small student board; equal seed numbers across these implementations do not promise equal patterns. The cloth's folds are a fixed mesh, and the dresses use the existing geometric panels. Neither simulates yarn crossings, sewing tension or flowing fabric. The mirror uses one head-centred reflection in VR, rather than a different reflection for each eye.

Implementation: `commons/artifacts/ten_print_textile/print_record.gd` keeps the values and makes the image; `textile_studio.gd` supplies the comparison, fitting and wardrobe handoff. The reconstruction above remains a small learner experiment; it does not require rebuilding that whole studio.

## The point we already know

Keep your existing `point_body.gd` if it matches this listing. It creates its own sphere and collider and inherits pickup, release and trigger dispatch from the XR Tools supplied on Day Zero. It has no scene-path dependency. This is a dependency of the example, not a second lesson in making a sphere.

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

You leave with a reusable distinction: a draw, a rule for reading it, and a place for its result. Next, two possible marks become six possible die outcomes. Keep the generator and the record; change the available outcomes and ask what ends a run.

The historical starting point is the single-line program discussed in [*10 PRINT*](https://10print.org/). Our rods are a spatial interpretation of its two character choices.
