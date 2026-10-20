# A seed needs a procedure

**Learning elements**

- Pseudorandom numbers: a changing state produces a sequence.
- Seed: choose a repeatable starting state.
- Draw order: each request advances the generator.
- Interpretation: use three successive values as one RGB colour.
- Replay: repeat the requests and their assignment.

Three glass windows now rise above one another in Random Definition. The bottom starts from seed 435. The middle restarts from 435 and matches it pane for pane. The top starts from 436. Beside each window, its seed, first draws and matching-pane count make the comparison inspectable. A seed is the integer that initialises the generator; its role becomes visible through what repeats when we restore it.

Press REPLAY, then +1 DRAW: only the middle window changes while its seed stays. Its colour and range controls also affect only that replay. The bottom and top remain controls. This reconstruction keeps the simpler pair side by side: discard the first value before assigning the right grid's colours. Every RGB group then starts one draw later. After reconstructing that pair, add an independent third generator at seed + 1 and keep it unchanged while testing the replay's procedure.

The museum starts with 435, a saved number received from RANDOM.ORG. The hall's SEED +1 and RESET 435 controls select repeatable inputs; RESET reuses the saved opening without requesting new atmospheric data. Our lesson starts with 42 and runs locally. The subject is how a seed, a sequence of requests and their assignment reconstruct a picture. Matching panes verify this procedure in the current engine; their appearance cannot establish the seed's physical source.

## Bring the objects; add a generator

The cube, grid loops, arrays and individual materials come from Transformation, Arrays and Colour. We use them again. The black point keeps its pickup and trigger behaviour.

Carried unchanged from [Wavefunctions — Synthesis Lab](../WaveFunctions_Synthesis_Lab/tutorial.md): `point_body.gd`.

In [Cage](../WaveFunctions_John_Cage/tutorial.md), we sampled a score once, kept its events and replayed that record. Here we ask a generator to produce its sequence again. This lets us recover an arrangement without storing every colour, provided we keep the procedure that made it.

A **pseudorandom generator** follows a deterministic rule. It has an internal state; each request uses and advances that state to produce a value. The sequence is designed to serve as random samples, even though repeating its starting conditions repeats its results. We can be surprised by an arrangement whose construction is reproducible.

The **seed** is an integer used to initialise that state. The current **state** is where the generator has reached after our requests. Setting the seed again starts its sequence again. It does not remember which picture we liked. Our code must still say what to do with the values.

## Build beside the museum's instrument

Keep the inherited file beside two new files: `01_seed_picture.gd` and `matrix_slider.gd`, printed below. Attach the first to an empty, upright `PointStudy` Node3D at unit scale. Place this learner reconstruction in an available floor bay in a practice scene, with its front accessible; the writing wall and current map determine installed placements. The museum supplies the player, floor, camera, light and XR Tools. The script creates the study's nodes.

We make two 4 × 4 grids. Each cube owns a material. Before colouring either grid, we reset the same local generator to the same seed. The right grid can discard its first draw. The MATRIX slider changes the size of both grids; its construction is a support file after the lesson, so you can follow the randomness operation first.

Read `colour_grid()` and `replay()` first. `build_grids()` repeats the familiar cube-and-material construction. `activate()` gives the carried point three actions.

## The new program — `01_seed_picture.gd`

<!-- student-code:01_seed_picture.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const MatrixSlider = preload("matrix_slider.gd")
@export var side := 4
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

Run it. Two matching grids appear. Hold the black point above a label and press its action trigger: left replays, middle toggles +1 DRAW, right increments the seed. The museum's desktop pickup/action controls operate the same point. The choice uses local X; moving the point alone requests no random values.

## Follow one colour through the code

`RandomNumberGenerator.new()` gives the study a generator of its own. Other museum artifacts cannot consume its next value. In `colour_grid`, `rng.seed = seed_value` resets it **once before the cube loop**. Resetting inside that loop would give every cube the same first colour.

Each `randf()` returns a floating-point value from zero to one. Three successive calls become red, green and blue in `Color(a, b, c)`. The draw does not arrive labelled “red”; that meaning comes from its position in our code.

Use these invented values to trace the assignment; they are not promised outputs of seed 42:

| Request | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Value | 0.2 | 0.8 | 0.4 | 0.9 | 0.1 | 0.6 | 0.3 |

The left grid's first cube receives `(0.2, 0.8, 0.4)`; the second receives `(0.9, 0.1, 0.6)`. With one discarded request, the right grid's first cube receives `(0.8, 0.4, 0.9)`. Its red came from the left cube's green; its blue came from the next cube's red. We shifted the grouping without moving a cube.

At four by four, each grid needs `16 × 3 = 48` displayed values. The shifted procedure consumes 49. `samples[0]` and `samples[1]` retain the assigned colours for inspection. They are records in this study's memory; nothing here saves them to disk or carries them through a portal.

## Predict, change, recover

Leave +1 DRAW off, replay and wait. The panels match. Waiting spends no draws because this program never requests them in a frame callback. Switch +1 DRAW on and check the channel relationship above. REPLAY must reproduce that mismatch. Switch +1 DRAW off to recover the match.

Now change only `Color(a, b, c)` to `Color(c, b, a)`. Predict which channel survives unchanged. Run it: red and blue exchange jobs, green stays, and the generator makes exactly the same requests. Restore the original assignment. Explain why matching seeds were insufficient to preserve the picture after that edit.

Drag MATRIX from four to sixteen, then back. Both grids keep their panel area, seed and discard setting. More cells require more requests: 768 per grid, or 769 with the discard. The colour list keeps its earlier prefix, but a longer row places some entries at different spatial addresses. Returning to four restores the earlier arrangement. Size changes the layout rule; it is not a zoom.

NEXT SEED adds one to the seed integer and replays. Count, positions and the colour-assignment rule stay. A neighbouring seed does not promise a neighbouring-looking picture. Keep the Godot version with any recipe you want to reproduce; its [generator implementation](https://docs.godotengine.org/en/stable/classes/class_randomnumbergenerator.html) is not a permanent file format.

## What we keep

We now have three things we can vary separately: the starting state, the requests, and the use of their results. Keep the local generator and both sampled lists. The installed hall window has three stacked comparisons, START, REPLAY and SEED +1, with seed controls and draw strips. Its explicit SEED +1 control replaces RANDOM in this hall. Our point-operated version reconstructs the paired-grid comparison; adding the third window remains the extension exercise.

In [Random Entropy](../Random_Entropy/tutorial.md), we will request integer symbol IDs and assign colours through a four-entry palette. We can then count each symbol and sort a copy without changing those counts. This RGB record does not silently turn into that new categorical sample.

## Support file — `matrix_slider.gd`

Save this complete new helper beside the study. It builds a constrained XR grab handle and emits `side_changed` when the chosen size changes. The study connects that signal to `set_side()`, rebuilds the grids and replays. The slider itself requests no random values. Fourteen intervals provide the fifteen integer sizes from 2 to 16.

<!-- student-code:matrix_slider.gd -->

```gdscript
extends Node3D

signal side_changed(side: int)
var side := 4
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
