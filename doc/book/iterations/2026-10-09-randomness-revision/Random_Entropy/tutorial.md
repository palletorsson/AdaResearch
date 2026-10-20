# Keep the counts, change the neighbours

**Learning elements**

- Symbol IDs and a palette
- Frequency counts and relative frequency
- Copying a list before sorting it
- Neighbour comparisons
- Marginal Shannon entropy

Choose two neighbouring tiles on the ledger. Press SORT. The tiles regroup while the bars and large number stay. Which part of the arrangement did the measurement keep?

## What you bring

Keep the cube, its own material, the local generator and the held PointBody from Random Definition. Keep Trace's distinction between a record and a drawing of it. The new work is to count a record without losing its original order.

The previous program drew three floating-point values for every RGB colour. Here each draw is **one integer symbol**, from 0 to 3. `palette[symbol]` gives it a colour. We are making a new categorical sample, not silently converting the old colours or importing them through the portal. The same seed with a different kind of request is a different procedure.

**Build:** an original row, a displayed copy and four frequency bars.

**Investigate:** sort only the copy. Compare counts, neighbouring pairs and entropy before and after.

## Work inside the museum

Place the upright, unit-scale `PointStudy` at hall-local `(14.8, 0, 8.0)` metres with Y rotation −90 degrees in Random Entropy. Its front faces into the entrance chamber with the east wall behind it. The existing ledger remains the main encounter. The museum supplies player, light, camera, floor and XR Tools.

Save `02_counts_and_neighbours.gd` beside the unchanged `point_body.gd` and attach it to the study. The complete new file creates every cube, bar and label. Keep the supplied museum environment; there are no prepared mesh children to find.

Hold the black point above a label and press its action trigger. REPLAY reconstructs the sample from the current seed. SORT / DRAWN changes the copy's order. NEXT SEED increments the seed and reconstructs the sample. Sorting stays selected when you replay or change seed. These are the same local-position choices used in the previous lesson, with SORT replacing +1 DRAW.

## Complete code — 02_counts_and_neighbours.gd

Read `new_sample`, `counts_of` and the first three lines of `draw_state` first. They create the record, count it and protect it with a copy. Then read `neighbour_changes` and `entropy_of`. `box_at`, `text_at` and `_ready` reuse familiar construction to make those operations visible.

<!-- student-code:02_counts_and_neighbours.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
@export var sample_count := 16
@export var seed_value := 42
var palette: Array[Color] = [Color(0.08, 0.08, 0.1), Color(0.9, 0.4, 0.6),
    Color(0.25, 0.65, 0.7), Color(0.95, 0.8, 0.3)]
var rng := RandomNumberGenerator.new()
var record: Array[int] = []
var shown: Array[int] = []
var sorted_view := false
var rows: Array = []
var bars: Array = []
var captions: Array = []
var point: RigidBody3D
var title: Label3D
var view_label: Label3D

func text_at(words: String, at: Vector3, size: int = 26) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = size
    text.pixel_size = 0.0025
    add_child(text)
    return text

func box_at(at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
    var cube := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    cube.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    cube.material_override = material
    cube.position = at
    add_child(cube)
    return cube

func _ready() -> void:
    assert(sample_count > 0 and sample_count <= 64 and palette.size() > 0)
    for row in range(2):
        var cubes: Array = []
        for i in range(sample_count):
            var x := (float(i) + 0.5) / sample_count * 3.2 - 1.6
            cubes.append(box_at(Vector3(x, 2.5 - row * 0.45, 0),
                Vector3(2.9 / sample_count, 0.16, 0.12), Color.WHITE))
        rows.append(cubes)
    for symbol in range(palette.size()):
        var x := (float(symbol) + 0.5) / palette.size() * 3.2 - 1.6
        bars.append(box_at(Vector3(x, 0.95, 0), Vector3(2.2 / palette.size(), 1, 0.12), palette[symbol]))
        captions.append(text_at("", Vector3(x, 0.8, 0)))
    title = text_at("", Vector3(0, 3.05, 0), 30)
    text_at("ORIGINAL: as drawn", Vector3(0, 2.72, 0))
    view_label = text_at("", Vector3(0, 2.27, 0))
    text_at("Bars: fraction of all draws | full height = 100%", Vector3(0, 1.77, 0), 22)
    point = PointBody.new()
    point.position = Vector3(-1.2, 0.9, 0.75)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(activate)
    text_at("REPLAY", Vector3(-1.2, 0.5, 0.75))
    text_at("SORT / DRAWN", Vector3(0, 0.5, 0.75))
    text_at("NEXT SEED", Vector3(1.2, 0.5, 0.75))
    text_at("Hold point above a label; press trigger", Vector3(0, 0.27, 0.75), 22)
    new_sample()

func new_sample() -> void:
    rng.seed = seed_value
    record.clear()
    for i in range(sample_count):
        record.append(rng.randi_range(0, palette.size() - 1))
    draw_state()

func counts_of(values: Array[int]) -> Array[int]:
    var counts: Array[int] = []
    counts.resize(palette.size())
    counts.fill(0)
    for symbol in values:
        assert(symbol >= 0 and symbol < counts.size())
        counts[symbol] += 1
    return counts

func entropy_of(counts: Array[int]) -> float:
    var total := 0
    for count in counts:
        total += count
    assert(total > 0)
    var entropy := 0.0
    for count in counts:
        if count > 0:
            var p := float(count) / total
            entropy -= p * log(p) / log(2.0)
    return entropy

func neighbour_changes(values: Array[int]) -> int:
    var changes := 0
    for i in range(1, values.size()):
        if values[i] != values[i - 1]:
            changes += 1
    return changes

func draw_state() -> void:
    shown = record.duplicate()
    if sorted_view:
        shown.sort()
    var counts := counts_of(shown)
    for i in range(sample_count):
        rows[0][i].material_override.albedo_color = palette[record[i]]
        rows[1][i].material_override.albedo_color = palette[shown[i]]
    for symbol in range(palette.size()):
        var fraction := float(counts[symbol]) / record.size()
        bars[symbol].visible = counts[symbol] > 0
        bars[symbol].scale.y = maxf(0.001, 0.7 * fraction)
        bars[symbol].position.y = 0.95 + 0.35 * fraction
        captions[symbol].text = "%d: %d" % [symbol, counts[symbol]]
    title.text = "Seed %d | N %d | H %.3f bits/symbol\nOriginal neighbours %d | shown %d" % [
        seed_value, record.size(), entropy_of(counts), neighbour_changes(record), neighbour_changes(shown)]
    view_label.text = "COPY: sorted" if sorted_view else "COPY: as drawn"

func activate(_body: Variant = null) -> void:
    if point.position.x > 0.4:
        seed_value += 1
        new_sample()
    elif point.position.x >= -0.4:
        sorted_view = not sorted_view
        draw_state()
    else:
        new_sample()
```

## A symbol is an address, not a colour value

`randi_range(0, palette.size() - 1)` includes both ends. With four palette entries, the possible IDs are 0, 1, 2 and 3. A draw of 2 selects `palette[2]`. The number 2 does not mean twice as much colour as 1. It names a category.

`record` keeps those IDs in draw order. `counts_of` creates four zero counters and uses each ID as an index: `counts[symbol] += 1`. The loop visits sixteen entries, so the counts must add to sixteen. An even drawing rule does not promise four occurrences of each symbol in this particular sample.

The bars divide each count by the **total number of draws**. Their full height is always 0.7 metres at 100%; one quarter gives 0.175 metres. Zero has a printed count but no visible bar. This fixed scale differs from the installed ledger, which fits its tallest bar to the available height. Read the labels before comparing displays.

## Keep one list; change another

`shown = record.duplicate()` creates a separate array with the same integers. `shown.sort()` puts only that copy in ascending order. No random request occurs during sorting. The upper row still shows `record`; the lower row shows `shown`. Press SORT / DRAWN again to recover the original arrangement below too.

With `shown = record`, both names would refer to one array. Sorting through either name would lose the original order. The copy matters because it lets the two versions remain available together.

`neighbour_changes` reads pairs instead of individual symbols. It begins at index 1 and compares each entry with the one before it. Sixteen entries have fifteen such pairs. The last entry is not connected back to the first. This is one small measure of order, not a complete account of a pattern or its meaning.

## What the entropy function reads

The function receives **counts**, with no positions or neighbouring pairs. It first adds them to find the sample size. For each positive count, `p` is its share of that sample. `-log(p) / log(2.0)` is the information value associated with that share; multiplying by `p` weights it. Adding those terms gives the empirical marginal Shannon entropy, H, in **bits per symbol**.

Skip zero counts before taking a logarithm. Their contribution is zero; evaluating `log(0)` is not how we obtain it. The program requires a nonempty sample.

For four equally frequent symbols, each share is one quarter. Each contributes half a bit, giving H = 2. With just one symbol occurring, its share is 1 and H = 0. The calculation does not multiply by the record length, predict from the preceding entry or measure physical heat. You can use these two cases to check the function before treating a less familiar number as evidence.

## Predict, then change the copy

Before pressing SORT, write down the four counts and choose a neighbouring pair in the upper row. Predict which readouts can change. Now press it. The lower row regroups; the counts and H remain. The original row and its neighbour count remain too. The copy's number of unlike neighbours may change. If the original happened to be sorted already, the operation would have no visible difference.

Press REPLAY with sorting still selected. The generator reconstructs the same original, and the copy is sorted again. Waiting and moving the point without triggering do not request values. Compare this with Cage: there REPLAY read the stored score; here REPLAY rebuilds the seeded record.

## Give the gauge a perfectly regular pattern

In `new_sample`, replace the append line with `record.append(i % palette.size())`. Keep sixteen entries and the four colours. This cycles through 0, 1, 2, 3 four times; `%` gives the remainder after division. It uses no random draw.

Predict the counts, H and number of unlike neighbours before running. Then compare the original with the sorted copy. The regular cycle has counts `[4, 4, 4, 4]` and H = 2, the largest marginal value for four symbols. It has fifteen unlike neighbouring pairs; the sorted copy has three. The maximum reading did not make the sequence difficult to predict once you knew its cycle.

Make another version with `record.append(0)`. Predict which bars disappear and what the readouts become. Its counts are `[16, 0, 0, 0]`, H = 0, and both neighbour counts are zero. Zero-count categories remain in the declared palette even though this sample does not use them.

Keep one edited version and make a further pattern of your own. Can you change the neighbours while keeping all four counts? Explain why the gauge cannot distinguish those arrangements. Restore the sampled append line before using NEXT SEED to investigate random draws again.

## The carried point — point_body.gd

This file is unchanged from Random Definition and Wavefunctions. It creates the sphere and its collision, and inherits pickup and `action_pressed` from the XR Tools installed on Day Zero. Keep it beside the lesson. Its behaviour is already known; the counting operation is the subject here.

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

## Compare with the hall

The installed `shannon_entropy_meter` has 200 draws and ten symbols. Its upper ribbon animates a sort while its front excerpt keeps the beginning in draw order. Our smaller program keeps all sixteen original entries visible and recolours a second row immediately. Both preserve the original sample and measure symbol shares independently of order.

The ledger's CONTRAST action selects another cached sample drawn from unequal source probabilities; it does not sort the first sample into unequal counts. Its maximum is log₂(10), about 3.322 bits per symbol. Our four-symbol ceiling is 2. Those different alphabets must be named with their readings.

The ruin, jar and large black-and-white room offer other encounters with arrangement. Visit them with the reflective text. They are not missing construction steps in this lesson, and their different uses of entropy should not be treated as interchangeable.

## What travels onward

Keep the distinction between an address and a value, between an original and its copy, and between an arrangement and its counts. Random Remove uses a list with another role: it contains the addresses that may still be chosen. Before randomness selects a member, a rule decides who enters that list.
