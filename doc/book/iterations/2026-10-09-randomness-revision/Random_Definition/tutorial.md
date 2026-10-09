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

**Build:** two four-by-four grids coloured by one local generator, reset before each grid.

**Investigate:** keep the seed and discard one draw before colouring the right grid. Predict where its first red, green and blue values will come from.

## Work inside the museum

Use an upright `PointStudy` Node3D at unit scale in Random Definition. A tested working bay is hall-local `(10.5, 0, 18.5)` metres, beyond the textile panels, with Y rotation −90 degrees. The museum supplies floor, camera, lighting, player and XR Tools. The study's front is its local +Z side; this placement faces it into the room with the east wall behind it. This is a small reconstruction beside existing work; it does not replace the installed table or the room.

Save `01_seed_picture.gd` beside the unchanged `point_body.gd` carried from Wavefunctions. Attach the first file to the study. Both files are printed below. No named mesh child, `$Display`, prefab grid or separate scene is required.

In VR, hold the black point above REPLAY, +1 DRAW or NEXT SEED and press its action trigger. The existing desktop pickup/action controls can operate the same point. The choice uses the point's X coordinate relative to the study, as in Cage. Merely moving the point does not draw a number. NEXT SEED adds one to the integer; it is deliberately simpler than the installed table's RANDOM button.

## Complete code — 01_seed_picture.gd

Read `colour_grid` and `replay` first. The construction in `_ready` reuses the cube/material/grid pattern. The final function reuses the held-point action.

<!-- student-code:01_seed_picture.gd -->

```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
@export var side := 4
@export var seed_value := 42
var discard_first := false
var rng := RandomNumberGenerator.new()
var grids: Array = []
var samples: Array = []
var point: RigidBody3D
var label := Label3D.new()

func text_at(words: String, at: Vector3) -> Label3D:
    var text := Label3D.new()
    text.text = words
    text.position = at
    text.font_size = 28
    text.pixel_size = 0.0025
    add_child(text)
    return text

func _ready() -> void:
    assert(side > 0 and side <= 8)
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
    label.text = "Seed %d | LEFT %d draws | RIGHT %d draws\n%s" % [
        seed_value, draws, draws + int(discard_first),
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

There are sixteen cubes per grid. Each needs three draws: forty-eight in all. The loops store row zero first, left to right, then the next row. Row zero is the bottom row in this vertical display. The seed can only reproduce the assignment while that order and the use of the values remain the same.

`skip` requests one value without using it. It happens before the colour loop. The shifted grid still displays forty-eight channel values, but consumes forty-nine draws. Think of the first six values as `a, b, c, d, e, f`: the unshifted first two cubes use `(a, b, c)` and `(d, e, f)`. Predict the shifted first cube before you press the trigger.

The two calls to `colour_grid` return colour lists. `samples[0]` and `samples[1]` keep the values assigned to the left and right grids. The record and the picture can now be inspected separately. These lists live in this study's memory; this lesson does not save them to disk or automatically carry them through a portal.

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

## Compare with the installed work

The hall's `seed_replay_demo` has two eight-by-eight grids, a seed slider, RANDOM and draw strips. It uses the same three-requests-per-colour operation: 192 draws per grid, or 193 when the extra request is enabled. Our four-by-four study keeps the operation and reduces the amount to inspect. The black point is our familiar input; the installed instrument uses its own panel.

In the small study, generator state and the picture's recipe are different things. `seed_value` says where to begin. After colouring, `rng.state` is already further along. REPLAY resets the generator before making each list. Cage instead replayed an already retained list without asking the generator again. Both can repeat a result, by different procedures.

The reflection stays with what the seed's apparent name leaves out, and with the other instruments in the room. Not every artifact needs to become another construction exercise.

## What travels onward

Keep the local generator, the repeated procedure and the practice of retaining sampled values. In Random Entropy we will give draws explicit symbol IDs and a small palette so we can count them. Sorting a copy will change neighbours while leaving the counts intact. We will declare that new categorical representation; this RGB record does not silently become a list of ten symbols.
