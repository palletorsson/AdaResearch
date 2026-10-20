# What neighbours share

**Learning elements**

- Independent draws and position-based field samples
- Matched grid addresses
- Spatial frequency
- Differences between neighbouring values

In Random Mushrooms you kept each body's record and changed how one property was displayed. Keep that separation here. Build two small grids at matching addresses: independent heights on the left, samples of a Perlin field on the right. Change the field's frequency while keeping every independent height.

First visit the comparison bench already in the second room of Random Space Geometry. Move FREQUENCY without changing SEED. Follow three neighbouring columns on each side. The WHITE NOISE side stays; the PERLIN NOISE side changes. OCTAVES adds another comparison, with finer layers over the broad field. Leave that control at one for the first encounter. We will construct one layer and return to layered noise in the Noise sequence.

## A small study inside the museum

Use the prepared Endless Museum project and its working player, camera, lighting and XR Tools. In a local copy of this hall, add a Node3D at hall-local **(3, 0, 12), Y rotation 90 degrees**, with unit scale. Save the two files below together and attach `10_neighbours_share.gd` to this node. Its front is local positive Z. The script builds a table, labels and two 8 × 8 cube grids; there are no hidden mesh references. The table and columns are visual only. The museum floor supports the player.

The point is the same PointBody used in the earlier lessons. Hold it over a labelled third of the front edge and press its trigger. Left replays the current settings; middle switches frequency between 0.1 and 0.3; right adds one to the seed and rebuilds both grids. Moving or releasing the point does not sample. These actions use local X zones, without a distance check or snapping.

## The complete study

<!-- student-code:10_neighbours_share.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const SIDE := 8

var sample_seed := 42
var frequency := 0.1
var cell_gap := 0.16
var records: Array[Dictionary] = []
var columns: Array[MeshInstance3D] = []
var rng := RandomNumberGenerator.new()
var noise := FastNoiseLite.new()
var point: XRToolsPickable
var status: Label3D

func _ready() -> void:
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.fractal_type = FastNoiseLite.FRACTAL_NONE
    box(Vector3(3.6, 0.9, 2.2), Vector3(0, 0.45, 0), Color(0.34, 0.34, 0.34))
    box(Vector3(3.6, 0.75, 0.05), Vector3(0, 1.75, -1.07), Color(0.65, 0.65, 0.65))
    status = label("", Vector3(0, 1.75, -1.03), 27)
    label("INDEPENDENT                  PERLIN", Vector3(0, 0.97, 0.8), 27)
    label("REPLAY       FREQUENCY       NEXT SEED", Vector3(0, 0.93, 1.03), 23)
    point = PointBody.new()
    point.position = Vector3(0, 1.12, 1.0)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func replay() -> void:
    rng.seed = sample_seed
    records.clear()
    for z in range(SIDE):
        for x in range(SIDE):
            records.append({"at": Vector2i(x, z), "white": rng.randf(), "field": 0.0})
    sample_field()

func sample_field() -> void:
    noise.seed = sample_seed
    noise.frequency = frequency
    for record in records:
        var at: Vector2i = record.at
        record.field = (noise.get_noise_2d(at.x, at.y) + 1.0) * 0.5
    rebuild()

func rebuild() -> void:
    for column in columns:
        column.free()
    columns.clear()
    for side in range(2):
        var key := "white" if side == 0 else "field"
        var centre := -0.86 if side == 0 else 0.86
        for record in records:
            var at: Vector2i = record.at
            var height := maxf(float(record[key]) * 0.65, 0.01)
            var position := Vector3(
                centre + (at.x - 3.5) * cell_gap,
                0.9 + height / 2.0,
                (at.y - 3.5) * cell_gap
            )
            columns.append(box(Vector3(0.13, height, 0.13), position, Color(0.22, 0.22, 0.22)))
    status.text = "WHAT NEIGHBOURS SHARE\nseed %d | frequency %.2f | one layer\nmean neighbour gap: %.3f / %.3f" % [
        sample_seed, frequency, neighbour_gap("white"), neighbour_gap("field")
    ]

func neighbour_gap(key: String) -> float:
    var total := 0.0
    var pairs := 0
    for i in range(records.size()):
        var at: Vector2i = records[i].at
        if at.x < SIDE - 1:
            total += absf(float(records[i][key]) - float(records[i + 1][key]))
            pairs += 1
        if at.y < SIDE - 1:
            total += absf(float(records[i][key]) - float(records[i + SIDE][key]))
            pairs += 1
    return total / pairs if pairs > 0 else 0.0

func toggle_frequency() -> void:
    frequency = 0.3 if is_equal_approx(frequency, 0.1) else 0.1
    sample_field()

func next_seed() -> void:
    sample_seed += 1
    replay()

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.4:
        replay()
    elif x < 0.4:
        toggle_frequency()
    else:
        next_seed()

func box(size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = at
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    view.material_override = material
    add_child(view)
    return view

func label(text: String, at: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = text
    view.position = at
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.02, 0.02, 0.02)
    view.outline_size = 0
    add_child(view)
    return view
```

## Drawing a value; asking for a value

`replay()` resets the independent generator and visits the grid in row order. Each dictionary retains an address, a `white` draw and a `field` sample. The inner loop advances X. The outer loop advances the second grid coordinate, which becomes Z in the room. The array is still one-dimensional: a row contains eight entries.

The independent generator advances once per cell. Its next value does not consult the preceding height or its distance from another cell. That is the procedure called white noise on the installed bench; the values here have a uniform distribution between zero and one.

The field works differently. `get_noise_2d(x, z)` asks a function for its value at a position. Asking twice at the same position returns the same value under the same settings. Asking another position in between does not consume or change the first answer. Nearby positions can have related values because of the field's construction.

`TYPE_PERLIN` selects a gradient-noise algorithm supplied by Godot's FastNoiseLite. `FRACTAL_NONE` explicitly keeps one layer. We use this interface now; constructing gradient noise is a later lesson. The installed bench starts with three layers of fractal Brownian motion and offers an OCTAVES slider. Our single layer deliberately isolates the spatial relation. [Godot: FastNoiseLite](https://docs.godotengine.org/en/stable/classes/class_fastnoiselite.html)

The Perlin sample is signed. Adding one and multiplying by one half maps its nominal −1…1 interval into 0…1. This does not make its distribution uniform. Both sides can use the same height scale without having the same histogram. A shared seed number also does not mean the two algorithms use the same random choices internally.

## Frequency belongs to space here

`sample_field()` sets the seed and frequency, then replaces only the `field` member of each record. It does not call the independent generator. Frequency sets the scale at which the algorithm reads the coordinates. At 0.1, neighbouring grid addresses are separated by 0.1 in its noise domain; at 0.3 they are separated by 0.3. This is spatial frequency. No clock advances in this study.

Wavefunctions already used a function evaluated across space. Here the seed selects another gradient field rather than merely shifting the phase of a repeating sine. Keep the distinction between a field and its samples: the field can be queried between these addresses, but our visible grid contains only sixty-four samples. Raising frequency does not add columns or guarantee an ever more jagged result. A coarse grid can miss variation between its samples.

`cell_gap` belongs to the display instead. It sets the physical spacing of the cubes in metres. Field lookup uses the integer address, so spreading the display does not sample the field again. You can change a view without changing its record, as in Mushrooms and Gaussian.

## Read a relation, then count it

Both grids use dark grey columns and the same height rule. A value of one gives a 0.65-metre column. A value of zero gets a 0.01-metre marker so its position remains visible. Each centre sits half its height above the table. The records retain the original values, including those hidden by this minimum height. There is no separate stretching of each grid to fill its available height.

The board reports a mean neighbour gap. For each record, `neighbour_gap()` compares its value with the entry immediately right and the entry one row below, when they exist. `i + 1` moves right; `i + SIDE` moves down. The boundary checks prevent the end of a row being joined to the start of the next. Each edge is counted once: an 8 × 8 grid has 56 horizontal and 56 vertical pairs.

`absf()` keeps the size of a difference regardless of which value is higher. Dividing their total by 112 gives the mean absolute gap, in the record's value units. It is a description of these samples, not a correlation coefficient or a proof that one procedure always produces a smaller gap. Their different value distributions also affect the result. Inspect a row as well as the number.

Entropy counted categories without retaining their arrangement. This measurement uses arrangement. An alternating grid of zeros and ones has a gap of one across every neighbour edge. A grid with zeros in its left half and ones in its right half has only eight differing edges, giving a mean of 8/112, or 1/14. Both contain thirty-two zeros and thirty-two ones.

## The point you bring

The control converts the point's world position into the study's local frame. Turning the table therefore keeps its actions attached to its own left, middle and right. Pickup and trigger handling are inherited, not taught again here.

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

## Predict, change, check

1. Change the initial `frequency` from `0.1` to `0.3`. Before running, predict which record fields will change. Compare at seed 42: addresses and every independent value should remain identical; the Perlin values change. Switching back must restore their earlier values. No independent draw is spent by that switch.
2. Change `cell_gap` from `0.16` to `0.20`. Both grids spread out, while all values and both reported gaps stay the same. The cubes still fit the table. Explain why moving the display is different from changing where the function is sampled.
3. Change the initial `sample_seed` from `42` to `43`. Both procedures receive another seed. Compare them, then return to 42. Replay repeats the result under the same code, parameters and engine behaviour; it does not promise that two different engines or algorithms agree.

For an independent check, replace both value fields of every record with `(record.at.x + record.at.y) % 2`, then call `rebuild()`. Both gaps should be one. Next use `0.0 if record.at.x < 4 else 1.0`. Both gaps should be 1/14 despite unchanged category counts. These fixtures are authored patterns, not noise. REPLAY restores the sampled grids. `neighbour_gap()` assumes the complete row-ordered 8 × 8 record; removing individual records requires a different neighbour lookup.

The installed bench's height colours invite a terrain reading. Our neutral display lets the relationship carry more of the comparison. Neither version simulates erosion or proves what a landscape ought to look like.

Carry this question to the dartboard: **which sampling rule is an estimate relying on?** Related samples and independent samples are useful for different purposes. A field that makes plausible neighbouring heights is not automatically the right source for uniformly sampling a square.
