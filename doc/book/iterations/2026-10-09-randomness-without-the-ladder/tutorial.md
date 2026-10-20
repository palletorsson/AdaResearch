# Randomness — complete tutorial

Current canonical texts, 2026-10-09. Fourteen teaching halls in spine order. Biome Cage remains an unnumbered museum interlude after Mushrooms; the closing Biome Ladder is deferred. Random Game leads directly to Noise Types.



---

## 01 · Random_Definition

# A seed needs a procedure

**Learning elements**

- Local random generator
- Seed and generator state
- Draw order
- Assigning sampled values to colour
- Reconstructing a result versus retaining its data

At the paired colour grids, choose a patch you would keep. Press REPLAY. Then press +1 DRAW: only the right grid changes. The seed stays. Find out what else a repeated picture needs.

## What you bring

Use the cube from Transformation, the grid and list from Arrays, and a separate material for each cube from Colour. Keep the held `PointBody` from the earlier studies. Its role here is a control: the trigger requests an action; the ball's position chooses which action.

In Cage we sampled a score once and replayed the stored events. Here we reconstruct a picture by resetting a generator and repeating its requests. Synthesis kept the amounts in a recipe; this recipe also needs the order in which values are requested and used.

**Build:** two eight-by-eight grids coloured by one local generator, reset before each grid.

**Investigate:** keep the seed and discard one draw before colouring the right grid. Predict where its first red, green and blue values will come from.

## Work inside the museum

Use an upright `PointStudy` Node3D at unit scale in Random Definition. A tested working bay is hall-local `(10.5, 0, 18.5)` metres, beyond the textile panels, with Y rotation −90 degrees. The museum supplies floor, camera, lighting, player and XR Tools. The study's front is its local +Z side; this placement faces it into the room with the east wall behind it. This is a small reconstruction beside existing work; it does not replace the installed table or the room.

Save `01_seed_picture.gd` beside the unchanged `point_body.gd` carried from Wavefunctions. Attach the first file to the study. All three files, including `matrix_slider.gd`, are printed below. No named mesh child, `$Display`, prefab grid or separate scene is required.

In VR, hold the black point above REPLAY, +1 DRAW or NEXT SEED and press its action trigger. The existing desktop pickup/action controls can operate the same point. The choice uses the point's X coordinate relative to the study, as in Cage. Merely moving the point does not draw a number. NEXT SEED adds one to the integer; it is deliberately simpler than the installed table's RANDOM button.

## Complete code — 01_seed_picture.gd

Read `colour_grid` and `replay` first. The construction in `build_grids` reuses the cube/material/grid pattern. The final function reuses the held-point action.

<!-- student-code:01_seed_picture.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const MatrixSlider = preload("matrix_slider.gd")
@export var side := 8
@export var seed_value := 42
var discard_first := false
var rng := RandomNumberGenerator.new()
var grids: Array = []
var samples: Array = []
var point: RigidBody3D
var label := Label3D.new()
var resolution: Node3D

func text_at(words: String, at: Vector3) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = 28
    text.pixel_size = 0.0025
    add_child(text)
    return text

func _ready() -> void:
    assert(side >= 2 and side <= 16)
    build_grids()
    resolution = MatrixSlider.new()
    resolution.side = side
    resolution.position = Vector3(0, 0.98, 0.5)
    add_child(resolution)
    resolution.side_changed.connect(set_side)
    point = PointBody.new()
    point.position = Vector3(-0.8, 0.95, 0.7)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(activate)
    text_at("REPLAY", Vector3(-0.8, 0.65, 0.7))
    text_at("+1 DRAW", Vector3(0, 0.65, 0.7))
    text_at("NEXT SEED", Vector3(0.8, 0.65, 0.7))
    text_at("Hold the point above a label; press trigger", Vector3(0, 0.4, 0.7))
    label.position = Vector3(0, 2.35, 0)
    label.font_size = 30
    label.pixel_size = 0.0025
    add_child(label)
    replay()

func build_grids() -> void:
    for panel in grids:
        for cube in panel:
            remove_child(cube)
            cube.queue_free()
    grids.clear()
    for panel in range(2):
        var cubes: Array[MeshInstance3D] = []
        for row in range(side):
            for column in range(side):
                var cube := MeshInstance3D.new()
                var box := BoxMesh.new()
                box.size = Vector3.ONE * (0.9 / side)
                cube.mesh = box
                cube.material_override = StandardMaterial3D.new()
                cube.position = Vector3(
                    (panel - 0.5) * 1.35 + (column + 0.5) / side - 0.5,
                    1.1 + (row + 0.5) / side, 0)
                add_child(cube)
                cubes.append(cube)
        grids.append(cubes)
func set_side(value: int) -> void:
    var chosen := clampi(value, 2, 16)
    if chosen == side: return
    side = chosen
    resolution.set_side(side)
    build_grids()
    replay()

func colour_grid(cubes: Array, skip: bool) -> Array[Color]:
    rng.seed = seed_value
    if skip:
        rng.randf()
    var colours: Array[Color] = []
    for cube in cubes:
        var a := rng.randf()
        var b := rng.randf()
        var c := rng.randf()
        var colour := Color(a, b, c)
        cube.material_override.albedo_color = colour
        colours.append(colour)
    return colours

func replay() -> void:
    samples = [colour_grid(grids[0], false), colour_grid(grids[1], discard_first)]
    var draws := side * side * 3
    label.text = "%d x %d | Seed %d | LEFT %d draws | RIGHT %d draws\n%s" % [
        side, side, seed_value, draws, draws + int(discard_first),
        "right discards its first draw" if discard_first else "same procedure twice"]

func activate(_body: Variant = null) -> void:
    if point.position.x > 0.4:
        seed_value += 1
    elif point.position.x >= -0.4:
        discard_first = not discard_first
    replay()
```

## Follow the requests

`RandomNumberGenerator.new()` gives this study its own generator. Asking it for a value advances its state. The museum's other artifacts can keep running without spending this generator's next draw.

`rng.seed = seed_value` puts it back at the beginning associated with that seed. We do this once before each grid, not once before each cube. Then `randf()` requests values from zero to one. Three successive requests become the red, green and blue channels of one material. Each cube owns its material, so changing one does not repaint them all.

At eight by eight there are sixty-four cubes per grid. Each needs three draws: 192 in all. The loops store row zero first, left to right, then the next row. Row zero is the bottom row in this vertical display. The seed can only reproduce the assignment while that order and the use of the values remain the same.

`skip` requests one value without using it. It happens before the colour loop. The shifted grid still displays 192 channel values, but consumes 193 draws. Think of the first six values as `a, b, c, d, e, f`: the unshifted first two cubes use `(a, b, c)` and `(d, e, f)`. Predict the shifted first cube before you press the trigger.

The two calls to `colour_grid` return colour lists. `samples[0]` and `samples[1]` keep the values assigned to the left and right grids. The record and the picture can now be inspected separately. These lists live in this study's memory; this lesson does not save them to disk or automatically carry them through a portal.

## Change the matrix, keep the recipe

Drag the pink MATRIX handle. The number of rows and columns changes together, from 2 × 2 to 16 × 16. The panel keeps its place and its one-metre design area. The seed and +1 DRAW setting stay; the readout recomputes `side * side * 3` requests, plus the optional discard. At 16 × 16 that is 768 or 769 requests per grid.

The slider calls `set_side`. It rebuilds only the cube grids, then replays the current recipe. The held point and slider stay available. Returning to 8 × 8 restores its previous colours. A larger grid keeps the same prefix of the colour list, but a different row width puts some entries at different spatial addresses. It is not a zoom into the old picture.

The slider is supplied interaction code, printed below so the example has no hidden scene dependency. Read its wiring here; the new randomness concepts remain seed, request order and assignment.

## Three short investigations

First leave +1 DRAW off. Find corresponding cubes in the two panels. Press REPLAY twice and wait between presses. The lists and colours repeat: this study has no frame callback that requests random values while you wait.

Next switch +1 DRAW on. Compare the first right-hand cube with the first two left-hand cubes. The right red comes from the left green, its green from the left blue, and its blue from the next left red: `(b, c, d)`. Press REPLAY. The mismatch repeats. Switch +1 DRAW off and the match returns. The control toggles one discarded value, rather than accumulating a longer skip on every press.

Finally choose NEXT SEED. Predict what stays fixed before looking at the colours: cube count, positions, sizes and the RGB assignment rule. Replaying this new seed repeats its result. A different seed does not guarantee a different visible result, nor does a neighbouring seed promise a similar palette. Keep the Godot version with a saved seed recipe; do not assume the generator's implementation will remain identical across versions.

## Make another use of the same values

Change the one colour assignment to `Color(a, a, a)`. Keep all three `randf()` calls. Predict the difference, then run it: every cube is grey, but later cubes still begin at the same positions in the random stream. You have changed the use of the draws, not their number.

Now swap red and blue with `Color(c, b, a)`. Check one cube against its previous stored colour. Its green stays the same. Can you produce a different palette without changing the seed or the number of requests?

These are actual code edits, not another control to memorize. Keep one changed version and explain which part of the procedure it alters.

## The inherited point — point_body.gd

This is the same frozen pickable sphere used in Wavefunctions. Its parent class comes from the XR Tools already installed on Day Zero. `_init` creates its mesh and collision; the parent supplies pickup and `action_pressed`. We are using that behaviour here, not teaching it again. Keep this file unchanged beside the new script.

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

## The resolution control — matrix_slider.gd

This helper builds its rail, handle collision and label in code. XR Tools supplies the same grab mechanism already installed on Day Zero. The visible handle follows a constrained track; it stays where released. Fourteen intervals join the fifteen choices from 2 to 16. `side_changed` hands the chosen integer to the study. No new random value is requested by the control itself.

<!-- student-code:matrix_slider.gd -->

```gdscript
extends Node3D

signal side_changed(side: int)
var side := 8
var track: XRToolsInteractableSlider
var caption: Label3D
const TRAVEL := 0.8

class Track extends XRToolsInteractableSlider:
    func _process(_delta: float) -> void:
        if grabbed_handles.is_empty(): return
        var positions: Array[Vector3] = []
        var offset := 0.0
        for handle in grabbed_handles:
            positions.append(handle.global_position)
            offset += to_local(handle.global_position).x - to_local(handle.handle_origin.global_position).x
        move_slider(slider_position + offset / grabbed_handles.size())
        for i in range(grabbed_handles.size()):
            grabbed_handles[i].global_position = positions[i]

func box(parent: Node3D, size: Vector3, colour: Color) -> void:
    var visual := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    visual.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    visual.material_override = material
    parent.add_child(visual)

func _ready() -> void:
    box(self, Vector3(TRAVEL + 0.1, 0.025, 0.025), Color(0.65, 0.65, 0.65))
    var origin := Node3D.new()
    origin.position.x = -TRAVEL / 2
    track = Track.new()
    track.slider_limit_max = TRAVEL
    track.slider_steps = TRAVEL / 14
    track.slider_position = float(side - 2) / 14 * TRAVEL
    track.default_on_release = false
    var grip := Node3D.new()
    var handle := XRToolsInteractableHandle.new()
    handle.freeze = true
    handle.collision_layer = 1 << 18
    handle.collision_mask = 0
    handle.picked_up_layer = 0
    handle.ranged_grab_method = XRToolsPickable.RangedMethod.NONE
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(0.08, 0.12, 0.08)
    collision.shape = shape
    handle.add_child(collision)
    grip.add_child(handle)
    track.add_child(grip)
    box(track, shape.size, Color(0.9, 0.4, 0.6))
    origin.add_child(track)
    add_child(origin)
    caption = Label3D.new()
    caption.position.y = -0.13
    caption.pixel_size = 0.002
    caption.font_size = 24
    add_child(caption)
    set_side(side)
    track.slider_moved.connect(on_slide)

func set_side(value: int) -> void:
    side = clampi(value, 2, 16)
    if track: track.slider_position = float(side - 2) / 14 * TRAVEL
    if caption: caption.text = "MATRIX %d x %d | drag handle" % [side, side]

func on_slide(metres: float) -> void:
    set_side(2 + roundi(metres / TRAVEL * 14))
    side_changed.emit(side)
```

## Compare with the installed work

The hall's `seed_replay_demo` has two eight-by-eight grids, a seed slider, a MATRIX slider, RANDOM and draw strips. It uses the same three-requests-per-colour operation: 192 draws per grid, or 193 when the extra request is enabled. Both displays start at eight by eight and have a MATRIX slider for two through sixteen rows and columns. The larger panel keeps its footprint; the cells get smaller as the count increases. The black point is our familiar input; the installed instrument uses its own panel.

In the small study, generator state and the picture's recipe are different things. `seed_value` says where to begin. After colouring, `rng.state` is already further along. REPLAY resets the generator before making each list. Cage instead replayed an already retained list without asking the generator again. Both can repeat a result, by different procedures.

The reflection stays with what the seed's apparent name leaves out, and with the other instruments in the room. Not every artifact needs to become another construction exercise.

## What travels onward

Keep the local generator, the repeated procedure and the practice of retaining sampled values. In Random Entropy we will give draws explicit symbol IDs and a small palette so we can count them. Sorting a copy will change neighbours while leaving the counts intact. We will declare that new categorical representation; this RGB record does not silently become a list of ten symbols.


---

## 02 · Random_Entropy

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


---

## 03 · Random_Remove

# The set before the choice

## Learning elements

- Eligibility: a condition defines the possible choices.
- Candidate lists: a list offset refers to a stored grid address.
- Sampling without replacement: remove the chosen address from the list.
- Empty-set guard: stop before requesting an invalid draw.
- Replay: restore both the candidates and the generator.

## Start in the museum

Find the eight-by-eight removal board. Sixteen cubes are amber and forty-eight are grey. Before pressing REMOVE ONE, point to a cube that cannot be chosen. Then empty the amber square. Its final outline was fixed before the first draw; the order was not visible yet.

We return to the cube grid from Random Definition and the array work from Random Entropy. There, sorting preserved every member. Here, a choice changes what can be chosen next. The PointBody is the same class used in those lessons. We reuse its construction and trigger action; we do not import the previous hall's sample or pretend that a new node is the object carried through a portal.

The student study is one small board. The hoppers and walkable removal floor remain other encounters in this hall. They do not require two more implementations in this lesson.

## Make the small version

Use your prepared Endless Museum project with XR Tools installed. Save `03_eligible_addresses.gd` beside the existing `point_body.gd`. Add an empty Node3D named `RemovalStudy` under the Random Remove hall and attach the first script. Use hall-local position `(13.2, 0, 8)` and Y rotation `-90` degrees. The museum supplies the floor, player, camera and light. The script builds every cube, slot, label and the familiar point; no prepared mesh children are needed.

This study hides display cubes immediately. Its visual plinth has no collider; the museum floor still supports the player. The installed board has a brief red warning, while the arena also removes collision. Those are additional behaviours, not hidden parts of this listing. Keep this reconstruction separate from the existing exhibits.

The board stays eight by eight here so the new subject is eligibility. Random Definition's resolution slider is not needed to explain removal. Hold the point above a label and press the trigger: left resets, middle removes one, right increments the seed and resets. The positions are local to the study, so turning the whole board does not exchange its controls. Only the point's local x position chooses the action.

### `03_eligible_addresses.gd`

<!-- student-code:03_eligible_addresses.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const AMBER := Color(1.0, 0.68, 0.18)
const GREY := Color(0.28, 0.35, 0.42)
@export var side := 8
@export var seed_value := 42
var rng := RandomNumberGenerator.new()
var candidates: Array[int] = []
var history: Array[int] = []
var cubes: Array[MeshInstance3D] = []
var slots: Array[MeshInstance3D] = []
var point: RigidBody3D
var status: Label3D
var last_offset := -1
var last_address := -1

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
    assert(side >= 2 and side <= 16)
    var pitch := 2.0 / side
    for row in range(side):
        for column in range(side):
            var at := Vector3((column + 0.5) * pitch - 1.0, 0.976 + pitch * 0.36,
                (row + 0.5) * pitch - 1.0)
            cubes.append(box_at(at, Vector3.ONE * pitch * 0.72, GREY))
            slots.append(box_at(Vector3(at.x, 0.96, at.z),
                Vector3(pitch * 0.88, 0.015, pitch * 0.88), Color(0.65, 0.65, 0.65)))
    for i in range(side):
        var across := (i + 0.5) * pitch - 1.0
        var column_label := text_at(str(i), Vector3(across, 0.99, 1.12), 20)
        column_label.rotation_degrees.x = -90
        var row_label := text_at(str(i), Vector3(-1.12, 0.99, across), 20)
        row_label.rotation_degrees.x = -90
    box_at(Vector3(0, 0.47, 0), Vector3(2.4, 0.93, 2.4), Color(0.09, 0.1, 0.12))
    status = text_at("", Vector3(0, 1.9, -1.0), 26)
    point = PointBody.new()
    point.position = Vector3(0, 1.1, 1.45)
    add_child(point)
    var ink := StandardMaterial3D.new()
    ink.albedo_color = Color(0.04, 0.04, 0.045)
    ink.roughness = 0.2
    point.get_child(0).material_override = ink
    point.action_pressed.connect(activate)
    text_at("RESET", Vector3(-0.9, 0.65, 1.45))
    text_at("REMOVE ONE", Vector3(0, 0.65, 1.45))
    text_at("NEXT SEED", Vector3(0.9, 0.65, 1.45))
    text_at("Hold point above a label; press trigger", Vector3(0, 0.38, 1.45), 22)
    reset_run()

func eligible(column: int, row: int) -> bool:
    return column >= 2 and column <= 5 and row >= 2 and row <= 5

func reset_run() -> void:
    rng.seed = seed_value
    candidates.clear()
    history.clear()
    last_offset = -1
    last_address = -1
    for address in range(cubes.size()):
        var column := address % side
        var row := floori(float(address) / side)
        var allowed := eligible(column, row)
        cubes[address].visible = true
        cubes[address].material_override.albedo_color = AMBER if allowed else GREY
        if allowed:
            candidates.append(address)
    show_status()

func remove_one() -> int:
    if candidates.is_empty():
        return -1
    last_offset = rng.randi_range(0, candidates.size() - 1)
    last_address = candidates[last_offset]
    cubes[last_address].visible = false
    candidates.remove_at(last_offset)
    history.append(last_address)
    show_status()
    return last_address

func show_status() -> void:
    status.text = "Seed %d | eligible at start %d\nRemaining %d | removed %d" % [
        seed_value, candidates.size() + history.size(), candidates.size(), history.size()]
    if last_address >= 0:
        status.text += "\nOffset %d chose address %d (column %d, row %d)" % [
            last_offset, last_address, last_address % side, floori(float(last_address) / side)]
    if candidates.is_empty():
        status.text += "\nNo eligible cubes remain. RESET restores the set."

func activate(_body: Variant = null) -> void:
    if point.position.x > 0.4:
        seed_value += 1
        reset_run()
    elif point.position.x >= -0.4:
        remove_one()
    else:
        reset_run()
```

### `point_body.gd` — unchanged

Keep your existing file if you have it. This is the complete dependency for a reader joining here; its geometry and pickup behaviour are not another task to rebuild.

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

## Follow one removal

`eligible()` is a question with a Boolean answer. It admits columns 2–5 and rows 2–5, including both ends. This is where you decide the set. Moving the pedestal does not change the column and row stored for a cube.

The nested construction loops store the cubes row by row. A cell's address is `row * side + column`. With eight columns, column 2 in row 2 has address 18. `address % side` recovers its column; division rounded down recovers its row. This is the grid addressing learned earlier, now used to keep track of an absence.

`reset_run()` visits all 64 addresses and collects the sixteen allowed ones. The candidate list begins `[18, 19, 20, 21, 26, …]`. **Offset 0 in that list means address 18 in the cube array.** These are two different indices. After a removal, list offsets shift; grid addresses keep their meanings.

`remove_one()` first checks whether the list is empty. If so, it returns `-1` without requesting randomness. Otherwise it draws an offset into the current list, looks up the address, hides that cube, and removes the offset from the candidate list. The return value is the removed address; `-1` means that no removal happened.

We leave `cubes` and `slots` intact. Hiding a cube changes its visibility, not its array address, and the slot remains visible underneath. `history` appends the removed addresses in order. Removing from `candidates` is what makes this sampling **without replacement**. Merely hiding a cube would still allow it to be chosen again.

The next draw is uniform over the remaining candidate offsets. No grey cube can be drawn. The condition governs eligibility; the random request chooses within it. In the previous hall a measurement ignored the arrangement. Here, counting sixteen candidates alone does not tell us which sixteen positions they occupy.

## Predict, change, check

First predict the original version: sixteen successful removals, no repeated address, forty-eight grey cubes still visible. A seventeenth press must do nothing. Save the first few addresses on paper, reset, and compare them. The same seed, candidate order and requests reproduce the order; waiting between presses makes no requests.

Now change only the return line in `eligible()` to `return (column + row) % 2 == 0`. Predict the count before running: half of an eight-by-eight board, thirty-two cubes. Remove them all. Every removed address must belong to that checkerboard, and no excluded cube should disappear. This changes the eligible shape without changing the selection algorithm.

Next use `return row == 3`, then `return column == 3`. Each offers eight choices. Keep the same seed and compare the complete orders. A draw at column 5, row 3 in the first becomes column 3, row 5 in the second: equal list lengths and ordering give corresponding offsets. The spatial meanings differ.

Finally use `return false`. The board must open with no eligible cubes, show that it is empty, and accept repeated trigger presses without an error. RESET should preserve that empty rule. An empty selection is a valid outcome; it is not permission to select from all cubes instead.

Restore the range rule when finished. Change `seed_value` or use NEXT SEED to compare orders, but do not require two seeds to produce different results. Replay is a claim you can test; guaranteed novelty is not.

## What travels onward

Keep the grid, the local generator and the distinction between a rule and a draw. The next hall, 10 PRINT, gives each cell two possible diagonals. Here a draw withdrew a member; there it will assign a mark whose neighbours help make a pattern.


---

## 04 · Randomness_10_PRINT_Algorithm

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

## The point we already know

Keep your existing `point_body.gd` if it matches this listing. It creates its own sphere and collider and inherits pickup, release and trigger dispatch from the XR Tools supplied on Day Zero. It has no scene-path dependency. This is a dependency of the example, not a second lesson in making a sphere.

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

You leave with a reusable distinction: a draw, a rule for reading it, and a place for its result. Next, two possible marks become six possible die outcomes. Keep the generator and the record; change the available outcomes and ask what ends a run.

The historical starting point is the single-line program discussed in [*10 PRINT*](https://10print.org/). Our rods are a spatial interpretation of its two character choices.


---

## 05 · Random_Cubes

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

You leave with a small procedure: request an outcome, retain it, add its contribution, decide whether another event is allowed. Next, the retained change becomes a turn. A cube's orientation can accumulate increments even when no column remains to show their order.


---

## 06 · Random_Rotate_Random_XYZ

# Keep the turn

## Learning elements

- Assigning an angle and accumulating a turn.
- Signed increments: a later turn can undo an earlier one.
- One recorded input, two interpretations.
- A timed step, independent of the drawing frame.
- Replaying a record without drawing again.

Find the two upright stacks. Wait after RESET. Their pieces keep their places while small turns build on previous turns. The shapes have not become different meshes. Their orientations carry a history.

In Random Cubes, each result added to a total. Here the cube returns, but the contribution is a signed angle. Transformation taught us to turn a whole body. We will give two identical cubes the same list of angles: one takes the latest value, and the other keeps the sum. The PointBody you already made operates the comparison.

## Build the comparison in the hall

Work in your copy of the prepared Endless Museum. Add an empty `Node3D` under Random Rotate and attach `06_turns_kept.gd`. Keep the unchanged `point_body.gd` beside it. Day Zero supplies the player, camera, light and XR Tools. The script creates both cubes, their marks, plinths and labels; these display meshes have no collision. A tested temporary position is hall-local `(3, 0, 7.5)`, Y rotation **90 degrees**, facing into the room.

Hold the point above **STEP** and press the trigger. Both cubes receive the next recorded angle. Over **PLAY / PAUSE**, the same action starts or pauses timed stepping. **REPLAY** returns both cubes to zero and the cursor to the start; STEP then reads the same turns again. At the end, PLAY starts that record again. These controls read the point's position relative to the lesson root.

Read `step()` first. The remaining functions make that short operation visible and repeatable.

<!-- student-code:06_turns_kept.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const TURN_AXIS := Vector3.BACK
@export var seed_value := 42
@export_range(1, 60) var step_count := 24
@export_range(1.0, 45.0) var limit_degrees := 20.0
@export_range(0.1, 5.0) var seconds_per_step := 0.8
var rng := RandomNumberGenerator.new()
var turns: Array[float] = []
var cursor := 0
var latest := 0.0
var total := 0.0
var elapsed := 0.0
var playing := false
var assigned: MeshInstance3D
var accumulated: MeshInstance3D
var status: Label3D
var point: XRToolsPickable

func _ready() -> void:
    for x in [-0.7, 0.7]:
        box(self, Vector3(x, 0.55, 0), Vector3(0.7, 1.1, 0.7), Color(0.88, 0.86, 0.82))
    assigned = cube(-0.7)
    accumulated = cube(0.7)
    label("LATEST ANGLE", Vector3(-0.7, 0.99, 0.4))
    label("SUM OF TURNS", Vector3(0.7, 0.99, 0.4))
    status = label("", Vector3(0, 2.3, 0))
    box(self, Vector3(0, 0.78, 0.8), Vector3(2.4, 0.05, 0.55), Color(0.88, 0.86, 0.82))
    label("REPLAY          STEP          PLAY / PAUSE", Vector3(0, 0.7, 1.1))
    point = PointBody.new()
    point.position = Vector3(0, 0.96, 0.8)
    add_child(point)
    point.action_pressed.connect(point_action)
    make_record()

func make_record() -> void:
    rng.seed = seed_value
    turns.clear()
    for i in range(step_count):
        turns.append(deg_to_rad(rng.randf_range(-limit_degrees, limit_degrees)))
    replay()

func replay() -> void:
    cursor = 0
    latest = 0.0
    total = 0.0
    elapsed = 0.0
    playing = false
    show_angles()

func step() -> void:
    if cursor >= turns.size():
        return
    latest = turns[cursor]
    total += latest
    cursor += 1
    if cursor == turns.size():
        playing = false
    show_angles()

func _process(delta: float) -> void:
    if not playing:
        return
    elapsed += delta
    while elapsed >= seconds_per_step and cursor < turns.size():
        elapsed -= seconds_per_step
        step()

func point_action(_body: XRToolsPickable) -> void:
    if point.position.x < -0.4:
        replay()
    elif point.position.x > 0.4:
        if cursor == turns.size():
            replay()
        playing = not playing
    else:
        playing = false
        elapsed = 0.0
        step()
    show_angles()

func show_angles() -> void:
    assigned.basis = Basis(TURN_AXIS, latest)
    accumulated.basis = Basis(TURN_AXIS, total)
    var state := "PLAYING" if playing else "PAUSED"
    if cursor == turns.size():
        state = "RECORD COMPLETE"
    status.text = "Seed %d | %d / %d | %s\nLatest %.1f deg | Sum %.1f deg" % [seed_value, cursor, turns.size(), state, rad_to_deg(latest), rad_to_deg(total)]

func cube(x: float) -> MeshInstance3D:
    var body := box(self, Vector3(x, 1.53, 0), Vector3.ONE * 0.6, Color(0.18, 0.18, 0.18))
    # An off-centre mark makes the cube's orientation distinguishable.
    box(body, Vector3(0.14, 0.23, 0.307), Vector3(0.22, 0.065, 0.025), Color(1.0, 0.35, 0.58))
    return body

func box(parent: Node3D, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    body.material_override = material
    body.position = at
    parent.add_child(body)
    return body

func label(words: String, at: Vector3) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = 28
    text.pixel_size = 0.0025
    text.modulate = Color(0.12, 0.12, 0.12)
    text.outline_size = 0
    add_child(text)
    return text
```

## One value, two operations

`make_record()` prepares a finite list of 24 angles. Each draw lies between −20 and +20 degrees; `deg_to_rad()` converts it to the radians the rotation uses. The list is already complete before either cube turns. The seed identifies this generator procedure; it is not a promise of the same numbers in every future engine version.

`cursor` is the next unread address. In `step()`, `latest = turns[cursor]` replaces one value. `total += latest` retains the preceding total and adds the new value. Both operations use the **same** entry; a second draw would make the comparison harder to interpret.

Suppose the list begins **+10°, +10°, −5°**. The left cube takes orientations **10°, 10°, −5°**. The right reaches **10°, 20°, 15°**. A bounded increment does not impose the same bound on the sum. Negative increments can cancel positive ones, so accumulated turning need not move steadily farther from zero.

`Basis(TURN_AXIS, angle)` gives the whole cube an orientation around one unit axis. `Vector3.BACK` is local positive Z: the cube turns in the plane facing you. Its position and mesh stay unchanged. The off-centre pink mark lets you distinguish orientations that an unmarked cube's symmetry could conceal. [Godot: Basis](https://docs.godotengine.org/en/stable/classes/class_basis.html)

The sum is retained separately from the rendered orientation. After a full turn the cube can look unchanged while the stored total has increased by 360°. The displayed body alone cannot recover all the turns that led to it.

## Time reads the record

`_process(delta)` receives elapsed seconds. It accumulates that time, then uses `while` to consume every complete 0.8-second interval. A slow drawing frame may contain several lesson steps. A faster monitor does not create extra random draws: playback only reads the saved list.

Pause keeps a partly completed interval. REPLAY clears it. Manual STEP also clears it and pauses playback, so your press is the next event rather than an extra step immediately before a timed one. The last entry stops playback. The guard at the start of `step()` prevents reading past the list.

REPLAY never calls the generator. `make_record()` does: it resets the seed, replaces the list, then resets playback. This distinction matters in the installed stack, whose RESET aligns the pieces but does **not** rewind its generator.

## The point is still your point

This is the existing PointBody dependency. Keep your copy; it is printed here so the complete example can be reconstructed without a prepared mesh child. Its inherited pickup behaviour stays the same. What its action does belongs to this lesson.

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

## Change one thing and predict it

1. Step once. Predict why the orientations agree. Step again and explain why they can separate even though their inputs remain identical.
2. Change `limit_degrees` from `20.0` to `40.0`, leaving the seed and entry count alone. In this generator implementation the signed entries double. At the same cursor, both numeric angles double; the visible pose can wrap around a full turn. Compare the labels as well as the cubes.
3. Change `TURN_AXIS` from `Vector3.BACK` to `Vector3.RIGHT`. Keep the original angle record. The same values now pitch the cubes around local X. What changed is the axis of interpretation, not the random numbers. This does not sample all spatial orientations: that is a different problem.
4. Before running it, predict a record containing **+10°, +10°, −5°**. For a controlled exercise, replace the drawing loop in `make_record()` with `turns.assign([deg_to_rad(10.0), deg_to_rad(10.0), deg_to_rad(-5.0)])`. Keep its final `replay()` call. Explain both labels after the third step, then replay and check again.

The code checks reconstruct the printed files, compare the amplitude and axis edits, test this supplied record, and deliberately break accumulation, replay and timing. Passing those checks establishes what the program does. Your own explanation of a new record is the further test of understanding.

## Return to the larger stack

Our two cubes isolate addition. The installed display also keeps angular velocity and an authored wear value; random kicks alter that state before it updates the angle. It currently updates per rendered frame, so a seed alone does not make its timing or trajectory match across frame rates. The learner comparison deliberately uses fixed record-reading intervals. It is a reconstruction of the central relation, not a replacement implementation of the full exhibit.

The nearby weathering rig reacts to movement without drawing random numbers. Neither that input nor mixing values from a software clock establishes a hardware random source. Keep the source of a change separate from how the change looks.

Carry the distinction into Random Walk. The cube has kept a sum of turns; the point will keep a sum of displacements. Trace's list returns so you can see where those steps have taken it.


---

## 07 · Random_Walk

# A point keeps its steps

## Learning elements

- A sampled heading becomes a displacement.
- Position accumulates steps.
- A boundary changes a proposed endpoint.
- A trail records accepted positions without steering the walk.
- Repeating a walk requires its start, rule and generator state.

Find the glass terrarium. Follow the red bead in 2D mode. Its direction keeps changing, yet it stays on one level. The other four beads still move. ONE changes what is easy to follow; it does not remove the rest.

Random Rotate kept adding turns. Now our familiar PointBody adds displacements. Coordinates supplies the local frame, Lines the connecting cylinder, and Trace the list of retained positions. We will build one planar walker. The cabinet's 3D and LONG STEP modes remain comparisons to visit afterwards.

## Give the point a rule

Work in your copy of Endless Museum. Add an empty `Node3D` under Random Walk and attach `07_a_point_keeps_steps.gd`. Place `point_body.gd` and `line_skin.gd` beside it. They are the existing point and Trace renderer, printed below without changes. Day Zero supplies the player, camera, lighting and XR Tools. The new script constructs its own table, boundary and labels. These display meshes add no collision.

The reconstruction was checked at hall-local position `(4, 0, 7)`, with no rotation. Leave room on its positive-Z side for your body to approach. This is a temporary work station in your copy of the museum; the installed terrarium remains beside it.

The point begins at the centre and takes one step every quarter-second. **Pick it up to pause.** Ordinary release projects your chosen starting place onto the tabletop plane, clamps that start inside the square, clears the previous trail and restarts the seeded walk. To repeat the last run from its previous start, **press the trigger while holding the point, then release it**. That combination ignores the new hand position. The label shows which release is pending.

This deliberately changes the role of the hand. In Trace, we recorded where you carried the point. Here holding pauses the generator; release supplies a start. The program then chooses the steps. The point remains the same class.

Read `step()` first. It draws, adds, folds and records.

<!-- student-code:07_a_point_keeps_steps.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")
const HALF := 0.85
const HEIGHT := 1.26
@export var seed_value := 42
@export_range(0.01, 0.4) var step_size := 0.12
@export_range(0.05, 1.0) var seconds_per_step := 0.25
@export_range(1, 256) var max_steps := 128
var rng := RandomNumberGenerator.new()
var point: XRToolsPickable
var trail := Node3D.new()
var status: Label3D
var origin := Vector3(0, HEIGHT, 0)
var current := Vector3(0, HEIGHT, 0)
var positions: Array[Vector3] = []
var steps := 0
var elapsed := 0.0
var held := false
var replay_requested := false
var proposed := Vector3.ZERO

func _ready() -> void:
    box(Vector3(0, 0.5, 0), Vector3(0.8, 1, 0.8))
    box(Vector3(0, 1.05, 0), Vector3(2.2, 0.1, 2.2))
    var corners: Array[Vector3] = [Vector3(-HALF, HEIGHT, -HALF), Vector3(HALF, HEIGHT, -HALF), Vector3(HALF, HEIGHT, HALF), Vector3(-HALF, HEIGHT, HALF)]
    for i in range(4):
        var edge = join(self, corners[i], corners[(i + 1) % 4])
        edge.material_override.albedo_color = Color(0.3, 0.3, 0.3)
    add_child(trail)
    point = PointBody.new()
    add_child(point)
    point.picked_up.connect(on_pickup)
    point.dropped.connect(on_drop)
    point.action_pressed.connect(on_action)
    box(Vector3(0, 1.95, -0.80), Vector3(1.5, 0.34, 0.05))
    status = label("", Vector3(0, 1.95, -0.75))
    label("HOLD: pause | RELEASE: start here\nTRIGGER + RELEASE: replay", Vector3(0, 0.86, 1.12))
    restart(origin)

func restart(at: Vector3) -> void:
    origin = Vector3(clampf(at.x, -HALF, HALF), HEIGHT, clampf(at.z, -HALF, HALF))
    current = origin
    point.position = current
    rng.seed = seed_value
    steps = 0
    elapsed = 0.0
    proposed = current
    positions.assign([current])
    for line in trail.get_children():
        trail.remove_child(line)
        line.queue_free()
    show_status()

func _process(delta: float) -> void:
    if held or steps >= max_steps:
        return
    elapsed += delta
    while elapsed >= seconds_per_step and steps < max_steps:
        elapsed -= seconds_per_step
        step()
    point.position = current

func _physics_process(_delta: float) -> void:
    if not held:
        point.position = current

func step() -> void:
    if steps >= max_steps:
        return
    var angle := rng.randf() * TAU
    var displacement := Vector3(cos(angle), 0, sin(angle)) * step_size
    proposed = current + displacement
    var accepted := reflect_endpoint(proposed)
    join(trail, current, accepted)
    current = accepted
    point.position = current
    positions.append(current)
    steps += 1
    show_status()

func reflect_endpoint(p: Vector3) -> Vector3:
    if p.x < -HALF: p.x = -2.0 * HALF - p.x
    if p.x > HALF: p.x = 2.0 * HALF - p.x
    if p.z < -HALF: p.z = -2.0 * HALF - p.z
    if p.z > HALF: p.z = 2.0 * HALF - p.z
    return Vector3(p.x, HEIGHT, p.z)

func on_pickup(_body: XRToolsPickable) -> void:
    held = true
    replay_requested = false
    show_status()

func on_action(_body: XRToolsPickable) -> void:
    if held:
        replay_requested = true
        show_status()

func on_drop(_body: XRToolsPickable) -> void:
    var start := origin if replay_requested else to_local(point.global_position)
    held = false
    replay_requested = false
    restart(start)

func show_status() -> void:
    var state := "WALKING" if steps < max_steps else "COMPLETE"
    if held: state = "REPLAY ON RELEASE" if replay_requested else "HELD / PAUSED"
    status.text = "Seed %d | %d / %d | %s\nx %.2f   z %.2f | %d positions" % [seed_value, steps, max_steps, state, current.x, current.z, positions.size()]

func join(parent: Node3D, a: Vector3, b: Vector3) -> MeshInstance3D:
    var line = LineSkin.new()
    parent.add_child(line)
    var displacement := b - a
    line.show_segment(a, displacement, displacement.length())
    return line

func box(at: Vector3, size: Vector3) -> void:
    var body := MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = size
    body.mesh = shape
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.88, 0.86, 0.82)
    body.material_override = finish
    body.position = at
    add_child(body)

func label(words: String, at: Vector3) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = 28
    text.pixel_size = 0.0025
    text.modulate = Color(0.12, 0.12, 0.12)
    text.outline_size = 0
    add_child(text)
    return text
```

## Follow one step

`rng.randf() * TAU` chooses an angle around the circle. Sine and cosine return from Wavefunctions: together they turn that angle into a unit heading in XZ. Multiplying by `step_size` makes a 12-centimetre displacement. The Y component is zero.

`proposed = current + displacement` starts from the position already reached. Assigning only the displacement would instead keep placing the point near the origin. One random number chooses the new heading; the preceding heading and the drawn trail do not enter that choice.

`reflect_endpoint()` folds any overshoot back into the square. At the right boundary, `x = 0.85`, a proposal of `0.90` becomes `0.80`. Clamping it to `0.85` would be a different rule. The four tests act on X and Z independently, so a proposal can fold at a corner too. This small implementation assumes each step is shorter than the square's width; the supplied step-size range stays within that assumption.

We connect the old position to the accepted endpoint, then store that endpoint. The line does **not** include a wall-contact point. Near an edge, a displayed segment may therefore be shorter than the proposal. The bounds apply to the point's centre; this is a geometric rule, not a rigid-body collision with a glass wall.

## Keep the record separate

`positions` begins with the starting position. Every event appends one accepted position. After 64 steps it contains 65 entries, and the trail contains 64 segments. The point sits at the latest entry. Unlike the cabinet's rolling window of older samples, this small study keeps the whole run, up to 128 steps.

`current` is the state used by the next step. The `positions` list is its account. Neither the list nor the segment nodes are consulted when drawing another heading. Clear those records while retaining `current` and the generator state: the next position remains the same. A self-avoiding walk would need to read its history when choosing where it may go.

The record and all segment endpoints use the lesson root's local coordinates. Turning or moving the whole station carries the drawing with it. Ordinary release converts the point's global hand position back into that local frame before choosing a new start.

## Keep time and replay explicit

The timer comes from Random Rotate. Each complete interval produces an event; `while` lets a slow frame contain several. The finite step budget bounds the work. Holding the point consumes no steps or random draws. Release resets the timer along with the run.

The point still has the frozen physics body introduced for pickup. `_physics_process()` keeps that body at `current` while it is free, including after the run completes. It stops assigning the position while you hold the point, so the hand can carry it. This display update draws no random number and takes no new step.

Here replay rebuilds the path from the same **origin, seed, step size, boundary rule and draw order**. It does not play an already stored path, as the previous lesson played its saved angles. The seed alone is insufficient: starting near an edge changes where the same proposals are folded. This comparison uses the same Godot version; a seed is not a promise of identical results across engine versions.

The installed cabinet also uses a step timer, but accepts at most five batches per drawing frame and discards excess time. Its RESET retains a partial timer. Compare its replays by step count, not by assuming the same wall-clock history. The learner study keeps a simpler finite run and clears its timer on restart.

## The constructions you already have

Keep these two files unchanged. PointBody supplies the sphere, collision shape and inherited pickup signals. LineSkin turns two endpoints into a visible cylinder; it does not make a wall or a physical string.

<details>
<summary>Complete PointBody and LineSkin dependencies</summary>

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

<!-- student-code:line_skin.gd -->
```gdscript
# Supplied renderer, adapted from commons/primitives/line/line.gd.
# This finite cylinder gives the segment a visible thickness. It is not a collider.
# Inputs share the parent station's local frame; that station has unit scale.
extends MeshInstance3D

func _init() -> void:
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.012
	cylinder.bottom_radius = 0.012
	cylinder.radial_segments = 16
	cylinder.rings = 0
	mesh = cylinder
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color(0.98, 0.70, 0.82)
	finish.roughness = 0.3
	material_override = finish
	visible = false

func show_segment(start: Vector3, displacement: Vector3, distance: float) -> void:
	# A zero-length segment has no direction. Do not normalize it.
	visible = distance > 0.0001
	if not visible:
		return
	(mesh as CylinderMesh).height = distance
	position = start + displacement * 0.5
	# CylinderMesh runs along local Y. This borrowed basis aligns it to the ends.
	var direction := displacement / distance
	var right := direction.cross(Vector3.UP).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth := right.cross(direction).normalized()
	basis = Basis(right, direction, depth)
```

</details>

## Make a change you can explain

1. Change `step_size` from `0.12` to `0.24`, leaving the seed and start at the centre. Before either path reaches an edge, its displacement from the start doubles. After a reflection the paths need not be scaled copies. Predict the first two endpoints, then compare the runs.
2. Change `seconds_per_step` from `0.25` to `0.5`. At an equal step count the path is unchanged; reaching that count takes longer. Separate changing the rule from changing its pace.
3. In `step()`, replace the call to `reflect_endpoint(proposed)` with `Vector3(clampf(proposed.x, -HALF, HALF), HEIGHT, clampf(proposed.z, -HALF, HALF))`. A proposal at x = 0.90 now ends at 0.85. The draws have not changed; their treatment at the boundary has. Restore reflection afterwards.

For an independent check, put the start near one corner. Choose a proposed displacement that exceeds both edges. Work out the folded endpoint before running the program, and explain why the visible connecting segment does not show a bounce. The code checks exercise that corner case, source edits, replay, held time and the distinction between a record and a steering rule.

## Return to the hall

The terrarium's five walkers share a generator. One planar step consumes one draw per walker. Its 3D direction consumes two, and LONG STEP adds another to choose a bounded length. Switching modes therefore changes both the geometry and how the stream is consumed. Its trail keeps previous positions and omits the bead's current one; our list includes the current endpoint. Both conventions are explicit choices about what a trail retains.

Visit the two rails next: a new position and an accumulated displacement are given the same input. Then try the held drawing dot, where the hand carries an origin and chance moves a tip around it. Across the basin, revisited cells raise the ground. These artifacts extend the question without adding three more required programs to this lesson.

Next is Random Gaussian. Keep the sampled values long enough to ask how they are distributed. A tangle shows an order of visits; a histogram will group values and leave that order out.


---

## 08 · Random_Gaussian

# Keep the values, change the bins

## Learning elements

- Uniform and Gaussian sampling rules.
- Mean and standard deviation as parameters.
- Retaining a sample before displaying it.
- Clipping a value and assigning a bin.
- Recounting without drawing again.

Find the distribution cabinet. Press PAUSE, let the airborne beads land, then CLEAR. Press BATCH three times. You have three hundred values. Press BINS: the bars change, but the total does not. Return to the original number of bins. What returned with it?

Random Walk kept positions in their order of arrival. Here we keep a list of numbers and group them into intervals. Entropy supplied counts; Arrays supplied the list and loop. The familiar PointBody returns as the control you hold. The new work is the relation between **drawing, keeping and counting**.

## Rebuild a small comparison

Work in your copy of Endless Museum. Attach `08_values_and_bins.gd` to an empty `Node3D` under Random Gaussian; keep the unchanged `point_body.gd` beside it. Day Zero already supplies the player, camera, lighting and XR Tools. This script builds its own display and labels. Its boxes are display meshes, not colliders.

The tested temporary station sits at hall-local `(3, 0, 7)`, turned 90° about Y. Leave room on its local positive-Z side to approach. The installed distribution cabinet remains in the hall.

Use the point as in Random Rotate: hold it over a labelled position and press the trigger. Moving it alone changes nothing. From left to right:

- **REPLAY** regenerates the present number of values from the seed, under the same law and parameters. It keeps the current bins.
- **+100** adds up to one hundred values, stopping at the run's limit of three hundred.
- **BINS** switches between ten and twenty intervals using the stored values.
- **LAW** switches GAUSS / UNIFORM and clears the sample. Press +100 three times to compare at equal count.

The display starts empty. There is no falling animation or automatic timer in this reconstruction: all samples count immediately. Start by reading `sample_value()`, `batch()` and `rebin()`; the remaining code constructs the display and connects the inherited action.

<!-- student-code:08_values_and_bins.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const WIDTH := 2.2
const BOTTOM := 1.3
@export var seed_value := 42
@export var gaussian := true
@export_range(0.0, 1.0) var mean := 0.5
@export_range(0.01, 0.5) var deviation := 0.15
@export_range(1, 1000) var sample_limit := 300
var rng := RandomNumberGenerator.new()
var values: Array[float] = []
var counts: Array[int] = []
var bin_count := 10
var clipped := 0
var bars := Node3D.new()
var status: Label3D
var peak_label: Label3D
var point: XRToolsPickable

func _ready() -> void:
    box(self, Vector3(0, 0.5, 0), Vector3(1, 1, 0.6), Color(0.88, 0.86, 0.82))
    box(self, Vector3(0, 1.93, -0.08), Vector3(2.65, 1.75, 0.08), Color(0.88, 0.86, 0.82))
    box(self, Vector3(0, 0.9, 0.6), Vector3(2.5, 0.06, 0.55), Color(0.88, 0.86, 0.82))
    add_child(bars)
    status = label("", Vector3(0, 2.62, 0))
    peak_label = label("", Vector3(-0.8, 2.39, 0))
    for i in range(3):
        label(str(i * 0.5), Vector3((i * 0.5 - 0.5) * WIDTH, 1.17, 0))
    var names := ["REPLAY", "+100", "BINS", "LAW"]
    for i in range(4):
        label(names[i], Vector3(-0.9 + i * 0.6, 0.8, 0.9))
    point = PointBody.new()
    point.position = Vector3(-0.3, 1.1, 0.6)
    add_child(point)
    point.action_pressed.connect(point_action)
    clear()

func sample_value() -> float:
    if not gaussian:
        return rng.randf()
    var u1 := maxf(rng.randf(), 0.0001)
    var u2 := rng.randf()
    var z := sqrt(-2.0 * log(u1)) * cos(TAU * u2)
    return mean + deviation * z

func batch(n: int = 100) -> void:
    for i in range(clampi(n, 0, sample_limit - values.size())):
        values.append(sample_value())
    rebin(bin_count)

func rebin(n: int) -> void:
    bin_count = clampi(n, 2, 60)
    counts.resize(bin_count)
    counts.fill(0)
    clipped = 0
    for raw in values:
        if raw < 0.0 or raw > 1.0:
            clipped += 1
        var value := clampf(raw, 0.0, 1.0)
        var index := mini(int(value * bin_count), bin_count - 1)
        counts[index] += 1
    redraw()

func clear() -> void:
    rng.seed = seed_value
    values.clear()
    rebin(bin_count)

func replay() -> void:
    var amount := values.size()
    clear()
    batch(amount)

func switch_law() -> void:
    gaussian = not gaussian
    clear()

func cycle_bins() -> void:
    rebin(20 if bin_count == 10 else 10)

func point_action(_body: XRToolsPickable) -> void:
    var x := to_local(point.global_position).x
    if x < -0.6:
        replay()
    elif x < 0.0:
        batch()
    elif x < 0.6:
        cycle_bins()
    else:
        switch_law()

func redraw() -> void:
    for bar in bars.get_children():
        bars.remove_child(bar)
        bar.queue_free()
    var peak := 0
    for count in counts:
        peak = maxi(peak, count)
    var width := WIDTH / bin_count
    var colour := Color(0.98, 0.55, 0.72) if gaussian else Color(0.18, 0.18, 0.18)
    for i in range(bin_count):
        if counts[i] == 0:
            continue
        var height := float(counts[i]) / maxi(1, peak)
        box(bars, Vector3(-WIDTH / 2 + (i + 0.5) * width, BOTTOM + height / 2, 0.04), Vector3(width * 0.85, height, 0.08), colour)
    var law := "GAUSS" if gaussian else "UNIFORM"
    status.text = "%s | seed %d | N %d / %d\n%d bins | %d values clipped for display" % [law, seed_value, values.size(), sample_limit, bin_count, clipped]
    peak_label.text = "TOP = %d COUNTS" % peak

func box(parent: Node3D, at: Vector3, size: Vector3, colour: Color) -> void:
    var body := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    body.mesh = mesh
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    body.material_override = material
    body.position = at
    parent.add_child(body)

func label(words: String, at: Vector3) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = 28
    text.pixel_size = 0.0025
    text.modulate = Color(0.12, 0.12, 0.12)
    text.outline_size = 0
    add_child(text)
    return text
```

## Give a draw a law

UNIFORM returns one `randf()` value in the interval from zero to one. GAUSS transforms two such draws. It uses the same guarded Box–Muller recipe as the installed cabinet. The logarithm and square root set a radius; the cosine takes one component. We use that recipe here without deriving it or adding a second sampler implementation.

The intermediate `z` approximates a normal variable centred at zero with standard deviation one. `mean + deviation * z` moves its centre and changes its spread. With our defaults, the mean parameter is 0.5 and the standard-deviation parameter is 0.15. Those describe the generating rule; this particular finite sample need not have exactly that mean or deviation.

`log(0)` is outside the recipe's domain. `maxf(..., 0.0001)` supplies a lower guard without shifting every valid draw. Together with the finite generator it makes an approximation, not a source of arbitrarily distant tails. The computed `z` cannot exceed about 4.29 in magnitude. More UNIFORM draws do not turn their law into GAUSS.

The two laws also spend the seeded stream differently: one draw per uniform sample, two per Gaussian sample. Equal seeds do not mean the two lists contain paired observations of the same value.

## Keep first, count second

`batch()` appends each raw result to `values`. The loop stops at the remaining capacity. Its job is sampling. `rebin()` makes a fresh list of zero counts, then reads the saved values. Its job is grouping. There is no random call inside it.

For ten bins, 0.23 belongs to index 2: multiply by ten, then take the integer part. Internal boundaries belong to the bin on their right. One needs special treatment: multiplying 1.0 by ten gives ten, but the last valid index is nine. `mini()` keeps that endpoint in the final bin.

Values outside zero to one are counted at the nearest display edge. This is clipping, not the reflection from Random Walk. The `clipped` counter records how many raw values crossed those edges. The first and last bins also contain values already inside the interval, so their total is not the clipped count.

Our `values` list keeps the **raw** number. Only the temporary `value` used for indexing is clamped. That makes the lost distance beyond an edge available to inspect. The installed cabinet keeps the already-clamped landed values and a separate clipped counter. This small reconstruction deliberately keeps more of the sample; the difference is part of the lesson.

After BINS, every raw value, its order, the clipped total and the generator state remain. The counts change because the partition changes. Returning to ten bins restores their earlier counts. No new observation was needed.

## Read the height carefully

The bars are made from the cube mesh you already know, changing only size and position. Zero counts have no bar. Each positive count is divided by the highest count, making the tallest bar one metre high. The label names that changing top count.

A single observation can therefore make a full-height bar. N tells you how much evidence is present; height alone does not. Unlike the cabinet, this study has no theoretical curve or expected-count bars. It shows the sample's counts, not a guarantee about what the next sample should look like.

## The point you already have

The point's pickup, release and trigger signal come from the same class. Converting its global position into the station's local frame keeps the four action zones attached to the station if it turns. Release does not make a new draw.

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

## Make a change you can explain

1. Keep GAUSS and the seed. Change `deviation` from `0.15` to `0.30`, then restart the scene and collect the same number of values. Each raw distance from 0.5 doubles. The displayed histogram need not double its width: the screen still clips at zero and one. Check both the raw record and the clipped count.
2. Change `sample_limit` from `300` to `150`. The first +100 adds one hundred; the next adds fifty; further presses draw nothing. The first hundred values remain the prefix of the same seeded run. A taller-looking picture is not necessarily a larger sample.
3. In `cycle_bins()`, change twenty to forty. Keep the saved values and compare ten with forty bins. The number of bins changes, not the generator or the number of observations.

For an independent check, set `values` to `[-0.2, 0.0, 0.05, 0.49, 0.5, 0.99, 1.0, 1.3]`, then call `rebin(2)`. Predict both counts and the clipped total before running it. Two bins should each contain four values; only two values were outside the screen. Rebin to ten and explain each occupied interval. This uses deliberately supplied data, not another random run.

To repeat a sampled run, preserve the seed, law, parameters, amount and draw order in the same engine version. REPLAY regenerates that many values; BINS simply rereads the existing ones. They are different kinds of return.

## Return to the cabinet

The installed BINS cycles 30 → 60 → 10 → 30. PAUSE stops issuing new samples, while existing beads can still land. BATCH counts immediately, reserving capacity for those in flight. CLEAR empties both and resets the named generator while preserving paused/running state. WIDTH changes the Gaussian deviation and clears the sample; it is not a way to stretch the same stored values.

Blue and pale model bars share a count scale there. The orange line has a separate shape scale. Leave Poisson, exponential and their additional mathematics as comparisons for now. At the paint-splatter plate, a central region rejects some drawn positions altogether: another rule intervenes between sampling and what you see.

In Random Mushrooms the retained number becomes a parameter of a body. Keep this distinction with you: choose a value, decide what it may change, then construct the form.


---

## 09 · Random_Mushrooms

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


---

## 10 · Random_Space_Geometry

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


---

## 11 · Randomness_Examples_of_Randomness

# A draw estimates

**Learning elements**

- Uniform samples in a square
- Circle membership and hit counts
- A running Monte Carlo estimate
- Finite-sample fluctuation and sampling bias

In Space Geometry you compared independent heights with values from a spatial field. Here the sampling rule has a different responsibility: it supplies evidence for an estimate. Keep the point, arrays and counters. Draw two coordinates, record the position, and ask whether it falls inside a circle.

First visit the Monte Carlo board already in this gallery. Press REPLAY, then THROW. A mark inside the circle increases both the inside count and the total; an outside mark increases only the total. Predict how the estimate will change before requesting another point. THROW requests a generated position; you are not aiming a physical dart. The BUDGET dial chooses 100, 500, 2000 or 8000 samples and restarts the same seed; FILL reaches that count. +100 extends the current run. NEXT SEED starts another run; 8 SEEDS compares eight runs without changing the displayed one.

## Reconstruct the counting rule

In your local copy of the prepared Endless Museum, add a Node3D at hall-local **(10.5, 0, 13), Y rotation 180 degrees**, with unit scale. Save the two files below together and attach `11_a_draw_estimates.gd` to it. The museum supplies the player, camera, floor, lighting and installed XR Tools. This temporary learner board creates its own geometry and labels beside the existing works. Its front is local positive Z; the geometry is visual only, and the museum floor supports you.

Reuse PointBody from the earlier lessons. Hold it over a labelled third of the board and press its trigger: REPLAY clears the record and rewinds the seed; ONE adds a sample; BATCH adds sixteen. Moving or releasing the point changes no samples. These are the familiar local-X zones, not touch buttons or snapping. The installed board uses rectangular buttons and a budget dial; our reconstruction keeps the counting lesson small.

Read `add_samples()` first. Each position lies in a square from −1 to 1 on both axes. The circle has radius 1 and area π; the square has area 4. With uniform sampling over this square, the proportion inside estimates π/4. Multiplying by four estimates π. The squared-distance test avoids a square root; it makes the same inside/outside decision.

The left panel retains every sample: teal inside, pink outside. Its circle outline uses 64 short cylinders; the equation decides membership, not collisions with that drawn edge. On the right, each black dot records the estimate after that sample. Horizontal position is sample number, vertical position is the estimate from 0 to 4. The gold line marks π for comparison; it never enters the counting calculation. Before any sample, the label shows `--` because there is no ratio yet.

## The complete study

<!-- student-code:11_a_draw_estimates.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LIMIT := 256
const BATCH := 16

var sample_seed := 42
var x_span := 1.0
var samples: Array[Vector2] = []
var estimates: Array[float] = []
var inside := 0
var marks: Array[MeshInstance3D] = []
var rng := RandomNumberGenerator.new()
var point: XRToolsPickable
var status: Label3D

func _ready() -> void:
    box(Vector3(2.8, 0.65, 0.8), Vector3(0, 0.325, 0.0), Color(0.25, 0.25, 0.25))
    box(Vector3(2.8, 2.1, 0.05), Vector3(0, 1.6, 0), Color(0.88, 0.86, 0.81))
    box(Vector3(1.2, 1.2, 0.01), Vector3(-0.65, 1.7, 0.03), Color(0.98, 0.97, 0.93))
    for i in range(64):
        var a := TAU * i / 64.0
        var b := TAU * (i + 1) / 64.0
        line(Vector3(-0.65 + cos(a) * 0.6, 1.7 + sin(a) * 0.6, 0.045),
            Vector3(-0.65 + cos(b) * 0.6, 1.7 + sin(b) * 0.6, 0.045), Color.BLACK)
    line(Vector3(0.15, 1.1, 0.045), Vector3(1.25, 1.1, 0.045), Color.BLACK)
    line(Vector3(0.15, 1.1, 0.045), Vector3(0.15, 2.1, 0.045), Color.BLACK)
    line(Vector3(0.15, 1.1 + PI * 0.25, 0.045), Vector3(1.25, 1.1 + PI * 0.25, 0.045), Color(0.65, 0.38, 0.05))
    label("ESTIMATE 0..4\nstep 1..%d | gold: pi" % LIMIT, Vector3(0.7, 2.3, 0.05), 22)
    status = label("", Vector3(0, 2.52, 0.05), 25)
    label("REPLAY           ONE           BATCH", Vector3(0, 0.83, 0.43), 24)
    point = PointBody.new()
    point.position = Vector3(0, 1.04, 0.55)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func replay() -> void:
    rng.seed = sample_seed
    samples.clear()
    estimates.clear()
    inside = 0
    for mark in marks:
        mark.free()
    marks.clear()
    update_status()

func add_samples(amount: int) -> void:
    for _i in range(mini(amount, LIMIT - samples.size())):
        var p := Vector2(rng.randf_range(-x_span, x_span), rng.randf_range(-1.0, 1.0))
        samples.append(p)
        var hit := p.length_squared() <= 1.0
        if hit:
            inside += 1
        var estimate := 4.0 * inside / samples.size()
        estimates.append(estimate)
        var colour := Color(0.04, 0.42, 0.37) if hit else Color(0.8, 0.12, 0.23)
        marks.append(dot(Vector3(-0.65 + p.x * 0.6, 1.7 + p.y * 0.6, 0.06), colour))
        var x := 0.15 + (samples.size() - 1) * 1.1 / (LIMIT - 1)
        marks.append(dot(Vector3(x, 1.1 + estimate * 0.25, 0.06), Color(0.08, 0.08, 0.08)))
    update_status()

func update_status() -> void:
    var value := "--" if estimates.is_empty() else "%.4f" % estimates[-1]
    status.text = "seed %d | %d / %d inside | estimate %s" % [sample_seed, inside, samples.size(), value]

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.4:
        replay()
    elif x < 0.4:
        add_samples(1)
    else:
        add_samples(BATCH)

func material(colour: Color) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = colour
    result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return result

func dot(at: Vector3, colour: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = 0.009
    mesh.height = 0.018
    mesh.radial_segments = 8
    mesh.rings = 4
    view.mesh = mesh
    view.position = at
    view.material_override = material(colour)
    add_child(view)
    return view

func line(a: Vector3, b: Vector3, colour: Color) -> void:
    var view := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = 0.003
    mesh.bottom_radius = 0.003
    mesh.height = a.distance_to(b)
    mesh.radial_segments = 6
    view.mesh = mesh
    view.position = (a + b) / 2.0
    view.quaternion = Quaternion(Vector3.UP, (b - a).normalized())
    view.material_override = material(colour)
    add_child(view)

func box(size: Vector3, at: Vector3, colour: Color) -> void:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = at
    view.material_override = material(colour)
    add_child(view)

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

## The carried point

Keep your existing `point_body.gd` beside the study. This is the unchanged class, included so the printed lesson has no missing code dependency beyond the declared XR Tools installation. The small sample marks are visual spheres; they do not each need pickup behaviour.

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

## Follow the record

`samples` keeps the positions. `inside` counts those accepted by the circle test. `estimates` keeps one ratio per position, so the graph retains how the answer changed. The expression starts with `4.0` to produce a floating-point ratio. Display helpers build familiar spheres, cylinders, boxes and labels; none of them draws a random value.

Add sixteen points individually. REPLAY, then request one BATCH. The positions, counts and estimate history should match exactly in this engine version. The loop groups requests; it does not choose a different sampling procedure. A new seed can produce a different run, but resetting only the counters would not replay the old one.

There is room for 256 samples. At that limit another request does nothing and spends no random draws. All 256 samples remain visible. The installed artwork has a selectable budget up to 8000 and shows only its latest 300 marks; its counts include the whole run. Both versions rewind their local generator on REPLAY. The same seed with the same sampling procedure lets you compare the same finite sample; a seed alone does not specify the whole experiment.

## Test a change you can explain

1. Change `BATCH` from 16 to 32. After replay, eight batches should reproduce the same 256 positions as sixteen batches did before. Predict the whole record, not only a number close to π.
2. Change `sample_seed` from 42 to 43. Fill the board again. A different estimate is not a failed program. Watch the history: a later point can move the estimate farther from π. A larger independent uniform sample reduces sampling uncertainty in general; it does not guarantee a better answer at every step.
3. Restore seed 42 and change `x_span` from 1.0 to 0.2. Leave the circle test and factor four alone. The points now occupy only a central strip. The program still runs, but `4 × inside / total` no longer estimates π under the original square-area argument. The source of the error is visible before you inspect the final number. More draws from the same strip do not restore the missing coverage. Restore 1.0 afterward.

For a calculation you can check by hand, imagine the first four records are `(0,0)`, `(1,1)`, `(0.5,0.5)` and `(-1,-1)`. Two are inside. The estimates after each record would be 4, 2, 8/3 and 2. More samples did not make this particular history steadily more accurate. This fixture checks the arithmetic; it is not itself a random experiment.

## What travels onward

You have separated drawing, classification and interpretation. The seed can replay the evidence; it cannot certify that the evidence suits the question. Keep that distinction as you inspect the painting, pipes and particle study: their random choices serve different purposes and do not all need to estimate an area.

In Pheromone, a recorded visit will enter a later choice. Samples there will depend on a changing field. We will follow that feedback explicitly instead of assuming each new position was drawn independently from the same square.


---

## 12 · Random_Pheromone

# A visit enters the next choice

**Learning elements**

- A signal stored at grid addresses
- Deposition and fixed-step decay
- Signal-guided choice mixed with random movement
- Feedback, boundaries and tie-breaking

The Random Walk point kept a trail, but never read it. The Monte Carlo board counted samples without letting a previous hit choose the next position. Here a visit changes a field that later movement reads. The record becomes part of the mechanism.

At the installed terrain, press ATTRACT, then +1 STEP. The four cyan markers move; places they leave gain scent and height. After several +20 STEPS, select AVOID and advance to the same step count. Each rule starts from the same seeded positions. The caption's 40% means a chance of taking the signal-guided branch on each decision. It does not promise that exactly 40% of a short run used that branch.

## One walker, two records

Build a small study in your local copy of this museum hall. Add a Node3D at hall-local **(10.1, 0, 6.2), Y rotation -90 degrees**, with unit scale. Put the two printed files together and attach `12_a_visit_guides.gd` to it. The prepared museum supplies the working player, camera, light, floor and XR Tools. The study creates all its own geometry. Its front is local positive Z; the table and columns are visual only.

The familiar PointBody supplies four trigger zones along the front: REPLAY, STEP, +20 and RULE. Hold it over the label and press. RULE switches ATTRACT/AVOID and resets the experiment. REPLAY keeps the selected rule. Moving or releasing the point does not advance anything.

There is one simulated walker, shown by a cyan sphere on both grids. Left: current scent, coloured pink. Right: accumulated visits, displayed as column heights. `field`, `visits` and `path` are separate arrays. The grid address is an integer pair; `index()` folds it into the familiar one-dimensional list. Test both coordinates before indexing: a valid flat index alone would not prevent a step from wrapping into another row.

Each step takes this order: **fade → deposit at the current address → count the visit → choose → move**. The starting position enters `path` immediately. A completed step adds one departure visit and one destination to the path, so after twenty steps there are twenty visits and twenty-one recorded positions. The latest position has not necessarily received a deposit yet.

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


---

## 13 · Random_Space

# Fields add

**Learning elements**

- A finite sum of spatial contributions
- Layer count, frequency ratio and amplitude ratio
- Seeded offsets kept between edits
- Raw values and display normalization

In Synthesis, several weighted waves made one result. In Space Geometry, neighbouring addresses sampled one field. Here those operations meet: sample several fields at the same address and add their contributions. Unlike Pheromone, a visit changes nothing. The same address and settings give the same value regardless of the route you took through the room.

At the noise mixer, reduce OCT to one. Change LAC and PER separately: neither affects the first layer. Add a second layer and try again. LAC now changes the next frequency; PER changes its weight. SEED selects a new arrangement of offsets. The violet ground and blue cellular field remain comparisons; this lesson rebuilds the mixer.

## Keep the parts of the sum

Add a Node3D to your local copy of the prepared museum hall, at hall-local **(9.5, 0.232, 12), Y rotation -90 degrees**, with unit scale. This tested position sits on the existing violet surface; recheck its support if you change that surface. Put the two printed files together and attach `13_fields_add.gd`. The museum supplies the player, XR Tools, camera and light. This script creates its own table, screens and point. The table and screens are visual only. The front is local positive Z.

The familiar PointBody selects four actions by its local horizontal position. Hold it over a label and press the trigger. REPLAY recreates the same eight offsets from the current seed, keeping the other settings. OCT cycles through one to four layers. WEIGHT switches PER between 0.3 and 0.7. SEED increments the seed and rebuilds. Moving or releasing the point changes no values.

Each entry in `parts` is a list of weighted samples from one layer. `raw` keeps their sum at each address. The first screen shows the last included contribution. The middle screen shows the sum using the same fixed grey scale. The third shows that identical sum stretched between its own minimum and maximum. It is a different view, not another field.

## The complete study

Start with `replay()`, `wave()` and `sample_fields()`. `picture()` turns retained values into pixels. The remaining functions supply the familiar control and display.

<!-- student-code:13_fields_add.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const SIDE := 32
const MAX_LAYERS := 4
const FIXED_BOUND := 3.0

var sample_seed := 42
var layer_count := 1
var lacunarity := 2.0
var persistence := 0.5
var base_frequency := 4.0
var rng := RandomNumberGenerator.new()
var offsets: Array[Vector2] = []
var parts: Array[Array] = []
var raw: Array[float] = []
var screens: Array[MeshInstance3D] = []
var point: XRToolsPickable
var status: Label3D

func _ready() -> void:
    box(Vector3(4.0, 0.9, 1.0), Vector3(0, 0.45, 0.0))
    box(Vector3(4.0, 1.9, 0.05), Vector3(0, 1.85, -0.36))
    for i in range(3):
        var screen := MeshInstance3D.new()
        var quad := QuadMesh.new()
        quad.size = Vector2(1.12, 1.12)
        screen.mesh = quad
        screen.position = Vector3((i - 1) * 1.3, 1.77, -0.3)
        var finish := StandardMaterial3D.new()
        finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
        finish.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
        screen.material_override = finish
        add_child(screen)
        screens.append(screen)
        var caption: String = ["LAST LAYER", "SUM: FIXED", "SUM: STRETCHED"][i]
        label(caption, Vector3((i - 1) * 1.3, 2.4, -0.29), 23)
    status = label("", Vector3(0, 2.65, -0.29), 21)
    for i in range(4):
        var action: String = ["REPLAY", "OCT", "WEIGHT", "SEED"][i]
        label(action, Vector3((i - 1.5) * 0.65, 0.77, 0.52), 24)
    point = PointBody.new()
    point.position = Vector3(0, 1.05, 0.3)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func replay() -> void:
    rng.seed = sample_seed
    offsets.clear()
    for i in range(8):
        offsets.append(Vector2(rng.randf_range(-100.0, 100.0), rng.randf_range(-100.0, 100.0)))
    sample_fields()

func wave(x: float, y: float) -> float:
    var value := sin(x + y * 1.7)
    value += sin(x * 2.3 - y * 0.9)
    value += sin((x + y) * 1.3 + 0.5)
    value += sin((x - y) * 1.8 - 0.3)
    value += sin(x * 0.7 + y * 2.1 + x * y * 0.15)
    return value / 5.0

func sample_fields() -> void:
    parts.clear()
    raw.clear()
    for i in range(layer_count):
        parts.append([])
    for y in range(SIDE):
        for x in range(SIDE):
            var uv := Vector2(float(x) / SIDE, float(y) / SIDE)
            var amplitude := 1.0
            var frequency := base_frequency
            var total := 0.0
            for i in range(layer_count):
                var contribution := amplitude * wave(
                    uv.x * frequency + offsets[i].x, uv.y * frequency + offsets[i].y)
                parts[i].append(contribution)
                total += contribution
                amplitude *= persistence
                frequency *= lacunarity
            raw.append(total)
    redraw()

func picture(values: Array, stretch: bool) -> Image:
    var low := -FIXED_BOUND
    var width := FIXED_BOUND * 2.0
    if stretch:
        low = values.min()
        width = float(values.max()) - low
        if width < 0.0001:
            width = 1.0
    var image := Image.create(SIDE, SIDE, false, Image.FORMAT_RGBA8)
    for y in range(SIDE):
        for x in range(SIDE):
            var t := clampf((float(values[y * SIDE + x]) - low) / width, 0.0, 1.0)
            image.set_pixel(x, y, Color(t, t, t))
    return image

func redraw() -> void:
    screens[0].material_override.albedo_texture = ImageTexture.create_from_image(picture(parts.back(), false))
    screens[1].material_override.albedo_texture = ImageTexture.create_from_image(picture(raw, false))
    screens[2].material_override.albedo_texture = ImageTexture.create_from_image(picture(raw, true))
    var centre := (SIDE / 2) * SIDE + SIDE / 2
    status.text = "seed %d | OCT %d | LAC %.1f | PER %.2f | %d x %d samples\nAt the centre: last %.3f | sum %.3f | raw range %.3f to %.3f\nFirst two screens: -3 black, 0 grey, +3 white" % [
        sample_seed, layer_count, lacunarity, persistence, SIDE, SIDE,
        parts.back()[centre], raw[centre], raw.min(), raw.max()]

func next_layer() -> void:
    layer_count = layer_count % MAX_LAYERS + 1
    sample_fields()

func change_weight() -> void:
    persistence = 0.3 if persistence > 0.4 else 0.7
    sample_fields()

func next_seed() -> void:
    sample_seed += 1
    replay()

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.65:
        replay()
    elif x < 0.0:
        next_layer()
    elif x < 0.65:
        change_weight()
    else:
        next_seed()

func box(size: Vector3, at: Vector3) -> void:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = at
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.84, 0.82, 0.78)
    finish.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    view.material_override = finish
    add_child(view)

func label(words: String, at: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = words
    view.position = at
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.02, 0.02, 0.02)
    view.outline_size = 0
    add_child(view)
    return view
```

## The carried point

Use the unchanged `point_body.gd` from earlier rooms. It is printed here so the complete dependency is available together.

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

## Read one address

The nested grid loops visit 32 × 32 sample addresses. Dividing by SIDE gives coordinates from 0 up to, but not including, 1. The inner layer loop begins with amplitude 1 and frequency 4. It samples the function after applying that frequency and the layer's saved offset. Then it adds the weighted value and prepares the next amplitude and frequency.

With LAC 2 and PER 0.5, four layers use frequencies **4, 8, 16, 32** and weights **1, 0.5, 0.25, 0.125**. OCT decides how far along that list to go. Removing a layer removes its contribution; it does not draw a replacement for what remains. Changing PER keeps the offsets but recomputes the weighted contributions. Changing LAC keeps them too, while changing where later layers sample.

The museum's base function is the five sine expressions in `wave()`. One layer already contains all five; it is not one simple sine and it is not the Perlin function from Space Geometry. The product `x * y` also makes this more than a sum of straight repeating stripes. We retain the actual function so that the reconstruction has a specific source. This is a finite construction, not a simulation of geological history or an infinite fractal.

Eight offsets are prepared once per replay even though this study uses at most four. That follows the installed mixer's offset list and keeps earlier entries available unchanged. `sample_fields()` makes no random draws. Parameter edits revisit a function; they do not accumulate marks as Pheromone did.

## A scale belongs to the picture

The first two screens map -3 to black, zero to grey and +3 to white. With up to four layers and PER at most 0.7, the absolute sum cannot exceed 1 + 0.7 + 0.49 + 0.343, because each base sample is an average of five sine values. Those settings fit inside the shared display bounds.

The last screen instead maps this sample set's lowest value to black and its highest to white. A small numerical range can therefore fill the whole contrast range. If the range is smaller than 0.0001, the code uses width 1 to avoid division by zero; a constant field becomes black. The arrays are not normalized in place. The centre readout and raw range remain available beside the pictures.

The installed mixer shows a 128 × 128 image through an earth-toned palette. Our study uses 32 × 32 samples, a grey scale, and exposes both scales. At shared sample coordinates the underlying sum agrees. The images need not match: resolution, range and palette affect what is visible. Adding layers does not add pixels, and a coarse image may miss or misrepresent fine variations.

## Make a change you can explain

1. Start with one layer and record the centre value. Change WEIGHT: it should stay the same. Add a layer; now changing WEIGHT can matter. Return to one layer and recover the earlier result. No new seed is needed.
2. Change `lacunarity` from 2.0 to 3.0 in the code. Predict frequencies 4, 12, 36, 108 for four layers. At one layer the field remains unchanged; later contributions change. The offset record should stay exactly the same.
3. Change SIDE from 32 to 64. You have added sample addresses, not layers. Every former address occurs at an even row and column in the new grid, with the same raw value. The stretched image's extrema may change because it now includes additional samples.

For one further comparison, keep four layers and temporarily put this loop immediately before `redraw()` in `sample_fields()`:

```gdscript
    for i in range(raw.size()):
        raw[i] *= 0.25
```

This scales the completed sum, leaving the stored parts unchanged. The fixed-scale middle screen becomes quieter. The stretched screen remains the same apart from numerical rounding, provided its range stays above the small-range guard. A quarter of the values can occupy the same contrast. Remove this intervention before continuing.

## What travels onward

Keep the distinction between a construction, its retained values and the view used to read them. This room used a seed to arrange offsets; the next room draws a wait and retains a deadline. There, revealing more about a decision should not secretly make a different decision.


---

## 14 · Random_Game

# A wait kept

**Learning elements**

- A fixed order of states with sampled waits
- Drawing once and retaining a deadline
- Updating a clock without redrawing the decision
- Separating a warning, a movement and collision support
- Replaying local state

At the crossing, watch one stone. It stands, leaves, stays below, then returns. The order repeats; the pauses vary. Look at the tablet: the current wait has already been drawn. The next wait is not yet stored. Turn CUE off. The ring disappears, but the stone keeps its appointment.

Random Space separated a value from the picture that disclosed it. Here we separate a scheduled event from its warning. Bring the cube's translation from Transformation, the clock from Point Zero, seeded draws and the carried PointBody. We rebuild one stone beside the existing crossing. The doors, removal floor and falling cubes remain other encounters in the hall.

## Keep a clock and a stone

In your local copy of the prepared museum, add a Node3D at hall-local **(3.5, 0, 10.5), Y rotation 90 degrees**, with unit scale. Place the three printed files together; attach `14_a_wait_kept.gd`. The museum already supplies its player, XR Tools, light and floor. The script makes its own stone, collider, display and PointBody. This is a small working model beside the crossing: stand on the museum floor to inspect it. The displayed cube and its travel are 60% of the installed stone's size. The backdrop and base are visual, without collision.

Hold the point over a label and press the trigger. REPLAY restores the current seed, clock, first wait, height and support, and pauses. RUN / STOP advances or holds the lesson's clock. CUE changes the advance ring. While paused, +0.25 s advances the clock by a quarter-second. Moving or dropping the point does not choose an action. The tablet stays readable when the ring is off.

There are two small programs. `wait_cycle.gd` stores the schedule without drawing geometry. The Node3D script gives that schedule a body. Keeping the clock separate lets us inspect an exact instant without waiting for it in a headset.

## The schedule: wait_cycle.gd

`replay()` initializes the generator and enters STANDS. `enter()` draws only when the stone begins a standing or hidden wait. It stores the phase's end in `until_ms`. `advance_to()` reads the time and crosses any boundaries already reached. It never draws merely because another frame arrived.

<!-- student-code:wait_cycle.gd -->
```gdscript
extends RefCounted

enum State { STANDS, LEAVES, GONE, RETURNS }
const NAMES := ["STANDS", "LEAVES", "GONE", "RETURNS"]
var run_seed := 42
var stand_band := Vector2(2.4, 4.6)
var gone_band := Vector2(1.1, 2.2)
var notice_ms := 1200
var cue_enabled := true
var rng := RandomNumberGenerator.new()
var state := State.STANDS
var now_ms := 0
var began_ms := 0
var until_ms := 0
var drawn_seconds := 0.0
var draws := 0

func replay() -> void:
    rng.seed = run_seed
    now_ms = 0
    draws = 0
    enter(State.STANDS, 0)

func enter(next_state: int, at_ms: int) -> void:
    state = next_state
    began_ms = at_ms
    var duration_ms := 700 if state == State.LEAVES else 400
    if state == State.STANDS or state == State.GONE:
        var band := stand_band if state == State.STANDS else gone_band
        var low := maxf(0.1, band.x)
        var high := maxf(low, band.y)
        drawn_seconds = low if is_equal_approx(low, high) else rng.randf_range(low, high)
        draws += 1
        duration_ms = int(round(drawn_seconds * 1000.0))
    until_ms = at_ms + duration_ms

func advance_to(target_ms: int) -> void:
    if target_ms < now_ms:
        return
    while target_ms >= until_ms:
        enter((state + 1) % 4, until_ms)
    now_ms = target_ms

func wait_left_ms() -> int:
    if state == State.STANDS or state == State.GONE:
        return maxi(0, until_ms - now_ms)
    return 0

func cue_visible() -> bool:
    return cue_enabled and state == State.STANDS and wait_left_ms() > 0 and wait_left_ms() <= notice_ms

func supports() -> bool:
    return state != State.GONE and (state != State.RETURNS or now_ms - began_ms >= 200)

func height() -> float:
    var elapsed := float(now_ms - began_ms)
    if state == State.LEAVES:
        var fraction := clampf(elapsed / 500.0, 0.0, 1.0)
        return -1.22 * (1.0 - cos(PI * fraction)) / 2.0
    if state == State.GONE:
        return -1.22
    if state == State.RETURNS:
        var fraction := clampf((elapsed - 200.0) / 200.0, 0.0, 1.0)
        return -1.22 * (1.0 + cos(PI * fraction)) / 2.0
    return 0.0
```

## The complete body: 14_a_wait_kept.gd

`_physics_process()` supplies elapsed time. `redraw()` asks the schedule for height, support and warning; it does not make another decision. Notice that the cube's collider is explicitly created alongside its BoxMesh. A visible body does not supply collision by itself.

<!-- student-code:14_a_wait_kept.gd -->
```gdscript
extends Node3D

const WaitCycle = preload("wait_cycle.gd")
const PointBody = preload("point_body.gd")
var cycle := WaitCycle.new()
var clock_ms := 0.0
var running := false
var point: XRToolsPickable
var stone: AnimatableBody3D
var collision: CollisionShape3D
var surface: MeshInstance3D
var crown: MeshInstance3D
var beacon: MeshInstance3D
var status: Label3D

func _ready() -> void:
    box(Vector3(3, 0.14, 1.8), Vector3(0, 0.07, 0), Color(0.12, 0.12, 0.14))
    box(Vector3(3, 2.5, 0.06), Vector3(0, 1.25, -0.8), Color(0.84, 0.82, 0.78))
    label("ONE STONE / ONE CLOCK", Vector3(0, 2.3, -0.75), 30)
    status = label("", Vector3(0, 1.96, -0.74), 21)
    stone = AnimatableBody3D.new()
    stone.sync_to_physics = false
    stone.collision_layer = 1
    stone.collision_mask = 0
    add_child(stone)
    surface = box(Vector3.ONE * 0.6, Vector3.ZERO, Color.WHITE)
    remove_child(surface)
    stone.add_child(surface)
    collision = CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3.ONE * 0.6
    collision.shape = shape
    stone.add_child(collision)
    crown = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 0.31
    ring.outer_radius = 0.37
    crown.mesh = ring
    crown.material_override = finish(Color(1, 0.78, 0.13))
    crown.position.y = 0.33
    stone.add_child(crown)
    beacon = MeshInstance3D.new()
    var bulb := SphereMesh.new()
    bulb.radius = 0.05
    bulb.height = 0.1
    beacon.mesh = bulb
    beacon.position.y = 0.43
    beacon.material_override = finish(Color.WHITE)
    stone.add_child(beacon)
    for i in range(4):
        label(["REPLAY", "RUN / STOP", "CUE", "+0.25 s"][i], Vector3((i - 1.5) * 0.7, 0.35, 0.91), 22)
    point = PointBody.new()
    point.position = Vector3(0, 0.6, 0.7)
    add_child(point)
    point.action_pressed.connect(use_point)
    replay()

func replay() -> void:
    running = false
    clock_ms = 0.0
    cycle.replay()
    redraw()

func _physics_process(delta: float) -> void:
    if running:
        clock_ms += delta * 1000.0
        cycle.advance_to(int(clock_ms))
    redraw()

func use_point(_held) -> void:
    var x := to_local(point.global_position).x
    if x < -0.7:
        replay()
    elif x < 0.0:
        running = not running
    elif x < 0.7:
        cycle.cue_enabled = not cycle.cue_enabled
    elif not running:
        clock_ms += 250.0
        cycle.advance_to(int(clock_ms))
    redraw()

func redraw() -> void:
    stone.position = Vector3(0, 1.35 + cycle.height() * 0.6, 0)
    collision.disabled = not cycle.supports()
    surface.material_override.albedo_color = [Color.CYAN, Color.CORAL, Color(0.15, 0.16, 0.2), Color.GREEN][cycle.state]
    crown.visible = cycle.cue_visible()
    beacon.visible = cycle.state == WaitCycle.State.LEAVES or cycle.state == WaitCycle.State.RETURNS
    status.text = "%s | %s | seed %d | draw %d\nwait %.3f s | left %.3f s | support %s\nclock %.3f s | phase ends %.3f s" % [
        WaitCycle.NAMES[cycle.state], "RUNNING" if running else "PAUSED", cycle.run_seed, cycle.draws,
        cycle.drawn_seconds, cycle.wait_left_ms() / 1000.0, "ON" if cycle.supports() else "OFF",
        cycle.now_ms / 1000.0, cycle.until_ms / 1000.0]

func finish(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    return mat

func box(size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
    var view := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    view.mesh = mesh
    view.position = at
    view.material_override = finish(color)
    add_child(view)
    return view

func label(words: String, at: Vector3, font_size: int) -> Label3D:
    var view := Label3D.new()
    view.text = words
    view.position = at
    view.font_size = font_size
    view.pixel_size = 0.0025
    view.modulate = Color(0.02, 0.02, 0.02) if at.z < 0 else Color.WHITE
    view.outline_size = 0
    add_child(view)
    return view
```

## The same point: point_body.gd

This is the unchanged control from the earlier rooms. Its code is included so the example has every script it needs; the existing XR Tools installation supplies `XRToolsPickable`.

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

## Follow one cycle

`State` names four integers. Adding one and taking `% 4` moves through their fixed order. A random draw chooses a duration within the standing band, 2.4–4.6 seconds, or the hidden band, 1.1–2.2 seconds. These are endpoints, not a minimum plus a width. With equal endpoints the duration is fixed and no random number is consumed. The readout's draw count counts assigned waits, including fixed ones.

The deadline is **phase start + duration**. It is stored once. During a wait, subtracting the current clock gives time left. LEAVES and RETURNS use fixed durations; the tablet keeps the preceding drawn wait and shows zero wait remaining. The phase-end value still tells you when the movement phase finishes.

| State | Height | Collision support | Duration |
|---|---|---|---|
| STANDS | At the top | On | One sampled wait |
| LEAVES | Sinks for 0.5 s, then stays down for 0.2 s | On throughout | 0.7 s |
| GONE | Down | Off | One sampled wait |
| RETURNS | Stays down for 0.2 s, then rises for 0.2 s | Off for the first 0.2 s, then on | 0.4 s |

The cosine expressions reproduce the installed stone's smooth sine easing. They control travel, not the wait distribution. The colour marks the state; the white beacon marks either movement phase. The gold ring appears only during the last 1.2 seconds of STANDS, while the stone can still support a body. At the exact deadline the state becomes LEAVES and that ring is off.

The museum crossing uses asynchronous timers and tweens, with a ticket that invalidates an old loop on replay. This reconstruction uses one explicit clock instead. Replay replaces that clock and state, so no old timer or tween survives to move the stone later. Waits are rounded to milliseconds, matching the installed deadline display; production timers use the original fractional seconds. We are reproducing the draw rule and phase structure, not claiming frame-identical synchronization with the live crossing. The lesson's pause is local too: the museum around it keeps running.

`advance_to()` handles a frame that crosses more than one boundary. The next phase begins at the previous deadline, rather than at the late frame's arrival. Splitting the same elapsed time into smaller updates therefore keeps the same schedule. A long stall can skip displaying intermediate poses; physics cannot retroactively reproduce contacts that were never simulated. Replay is the only operation here that moves the clock backward.

## Change the notice, keep the event

Replay, then use +0.25 s until the ring appears. Record the deadline. Toggle CUE twice. The deadline, drawn duration and generator state stay the same. The number on the tablet still gives notice even when the stone does not.

Now change `notice_ms := 1200` to `notice_ms := 300` in the schedule and replay the same seed. Predict which will change: the first drawn duration, the moment of sinking, or the warning's duration. The ring now offers only 0.3 seconds of notice. The scheduled states remain identical. Explain where the player would have to look to compensate.

For a second variation, change `stand_band` to `Vector2(3.0, 3.0)`. Every standing wait becomes three seconds. The hidden waits still vary, so the whole cycle is not yet periodic. Because the fixed standing wait consumes no random value, the next hidden wait reads an earlier value from the seeded stream. Fixed and variable waits cannot be swapped while assuming every later duration will stay unchanged.

Finally change `run_seed` from 42 to 43. The order of states stays; the waits change. That number seeds this one learner stone. The full crossing has a separate seed that supplies different seeds to its three stones.

## What this room adds

You can now point to the moment when a decision enters the world, the state that keeps it, the view that reveals it, and the consequence attached to it. A random future can contain an already determined next event. A warning can change what a visitor knows without changing that event.

This closes the fourteen teaching halls of Randomness. Noise now returns to the relation between neighbouring samples. Keep this question available: which part is sampled, which part is retained, and which part is only being shown?
