# Colour — all eight tutorial drafts

Review collection, 6 October 2026. Read REVIEW.md first. The host is the existing Endless Museum. Follow one question across the halls: **where is the colour held, and what receives it?**


---

<!-- hall:Color_Context_Placed -->

# Colour — the same parts

**Learning elements**

- RGB colour values
- A palette and an assignment to each part
- Independent material resources
- Changing colour while keeping geometry fixed

Find the first four columns in the Colour hall. They have the same five parts. One coat of ochre gathers the first column into a single body. Beside it, red connects three blocks across a blue sphere. Colour gives your eye another way to group what is there.

We bring the `BoxMesh` and `SphereMesh` constructions from Primitives, their positions and sizes from Transformation, and indexed references from Array. This lesson adds a material colour to each part. The construction stays still while we change the assignment.

## Keep the construction

Work in the existing Endless Museum, beside the entrance columns in `Color_Context_Placed`. Attach this complete `lesson.gd` to an empty `Node3D` named `ColourStudy`, with unit scale and its origin on clear floor. It builds one 4.4-metre column, 1.1 metres wide. Leave room to walk around it. The museum supplies the room, camera, player and light. The script creates every part and material; it needs no child nodes or companion scripts. This reduced colour study has no collision or pickup behaviour.

The five construction calls reproduce the opening column's dimensions and order: broad block, block, sphere, block, dome. They gather familiar mesh creation into two small helpers. The last sphere uses Godot's hemisphere option; its origin sits at the dome's base. Those dimensions are already chosen here. Begin by changing only the two lists at the top.

The palette holds the available colour values. The assignment says where they go: `colour_slots` chooses a palette entry for each part. Changing a value and changing its destination are separate decisions.

<!-- student-code:lesson.gd -->
```gdscript
# Five familiar parts; colour changes their grouping without changing their geometry.
extends Node3D

var palette: Array[Color] = [
    Color(0.78, 0.60, 0.30), # 0: ochre
    Color(0.80, 0.16, 0.16), # 1: red
    Color(0.16, 0.36, 0.80), # 2: blue
]
var colour_slots: Array[int] = [0, 0, 0, 0, 0]
var parts: Array[MeshInstance3D] = []

func _ready() -> void:
    add_box(Vector3(1.10, 0.60, 1.10), Vector3(0, 0.30, 0))
    add_box(Vector3(0.95, 0.95, 0.95), Vector3(0, 1.075, 0))
    add_round(0.475, 0.95, Vector3(0, 2.025, 0))
    add_box(Vector3(0.85, 0.95, 0.85), Vector3(0, 2.975, 0))
    add_round(0.425, 0.95, Vector3(0, 3.45, 0), true)
    apply_colours()

func add_box(size: Vector3, at: Vector3) -> void:
    var shape := BoxMesh.new()
    shape.size = size
    add_part(shape, at)

func add_round(radius: float, height: float, at: Vector3, hemisphere := false) -> void:
    var shape := SphereMesh.new()
    shape.radius = radius
    shape.height = height
    shape.is_hemisphere = hemisphere
    add_part(shape, at)

func add_part(shape: Mesh, at: Vector3) -> void:
    var part := MeshInstance3D.new()
    part.mesh = shape
    part.position = at
    var material := StandardMaterial3D.new()
    material.roughness = 0.55
    part.material_override = material
    add_child(part)
    parts.append(part)

func apply_colours() -> void:
    assert(colour_slots.size() == parts.size(), "Give every part a palette index.")
    for i in parts.size():
        var slot: int = colour_slots[i]
        assert(slot >= 0 and slot < palette.size(), "Palette index outside the list.")
        var material: StandardMaterial3D = parts[i].material_override
        material.albedo_color = palette[slot]
```

## Give a surface a colour

Run the study with its five zeroes. Every part receives `palette[0]`, the ochre. Walk around it. Different sides catch different light although their assigned colour is the same.

`Color(r, g, b)` supplies red, green and blue channel values. We use values between zero and one. Alpha is omitted, so these colours are opaque. `StandardMaterial3D` describes how a surface is rendered; `albedo_color` sets its base colour. Here roughness stays at 0.55 and the other material settings keep their defaults.

Each call to `add_part` creates a fresh material and assigns it to that mesh instance. This matters even when all five colours are equal. If all parts shared one material, changing that resource would change every part using it. Independent materials let us address their colours separately, just as independent cube instances let us change one transform in Array.

## Give the parts another company

Replace the five zeroes in `colour_slots` with `[1, 1, 2, 1, 2]` and run again. The three blocks become red; the sphere and dome become blue. Their meshes, sizes and positions are unchanged.

There are two addresses here. `i` selects a part, counting upwards from zero. `colour_slots[i]` selects an entry in the palette for that part. At part 2, the slot is 2, so the sphere receives the blue value in `palette[2]`. At part 3, the slot is 1, so the next block returns to red. Several parts can choose the same palette entry while keeping separate materials.

The list records our choice. It does not inspect a mesh and discover its category. We chose these five indices to make the same grouping as the hall's shape-based rule. An automatic shape rule would need to examine a declared kind; it is a possible extension once this assignment is clear.

`apply_colours()` traverses the existing parts and writes each chosen value into its material. It constructs no new geometry. Its assertions check that every part has an assignment and that each palette index exists. They catch an invalid list, not an unsuccessful composition.

## Change the palette; keep the assignment

Keep `[1, 1, 2, 1, 2]`. Replace the red entry with `Color(0.90, 0.22, 0.48)` and run again. The three blocks become pink together. The blue parts stay blue. One palette edit reaches several independent surfaces through the assignment list.

A `Color` is a value copied into `albedo_color`; the material does not keep a live link to the palette entry. Running again calls `apply_colours()` after construction. If a later control changes the palette while the study is running, it must call that function again to update the surfaces.

Now restore the original red and change the assignment to `[1, 2, 1, 2, 1]`. Colour alternates up the stack. The sphere joins the base and dome in red; the other two blocks become blue. This is an authored alternation, not the hall's calculation of a complementary colour from its neighbour. We can make the comparison without introducing that second algorithm here.

## Compose a grouping

Choose two non-neighbouring parts to share one colour, and give an intervening part another colour. Write your five palette indices and predict the result before running. Explain which list changes a colour value and which list changes where that value goes. Check that the construction itself has stayed the same.

Keep the palette, assignment and `apply_colours()` function. They give later work a way to put a chosen colour on a known surface. The larger stacks elsewhere in this hall develop other compositions; this lesson has selected the smaller operation beneath them.

In the next hall, the surface can keep its material while we change the light reaching it. We have assigned an exact value. We have not fixed everything that makes it look the way it does.


---

<!-- hall:Color_Flashlight -->

# Flashlight — keep the surface

**Learning elements**

- Light colour and material colour
- A spotlight's position, direction and cone
- A local target used by `look_at`
- Comparing separate and overlapping contributions

Take one of the coloured lamps in the museum. Aim it across the pale board, then turn it aside. The patch leaves. The board has kept its material.

In the previous hall, we assigned colours to independent surfaces. Here we keep one surface colour and change a light. The room's handles already let you do this by hand. Our small program reconstructs the light-to-surface relation; we use source edits to hold and compare particular states.

## A familiar box receives light

Work in the existing `Color_Flashlight` hall. Attach this complete `lesson.gd` to an empty `Node3D` named `LightStudy` on clear floor, with unit scale and local Y upright. Allow about five metres across X and three metres along positive Z. Stand on the positive-Z side of the board. The museum supplies your camera, movement, room and existing illumination.

The board is the `BoxMesh` we already know, made wide and shallow. Its material construction returns from the first Colour lesson. The new objects are two `SpotLight3D` nodes, each aimed at a point on the board. They have no visible handles or pickup bodies in this reduced study; the installed lamps provide that wider interaction. No child nodes, scene paths or helper files are required by this script.

<!-- student-code:lesson.gd -->
```gdscript
# Keep the board's material; change one light's colour or aim.
extends Node3D

var beam_colour := Color(1, 0, 0)
var first_target := Vector3(-1, 1.5, 0)
var board: MeshInstance3D
var surface: StandardMaterial3D
var first_light: SpotLight3D
var second_light: SpotLight3D

func _ready() -> void:
    board = MeshInstance3D.new()
    var shape := BoxMesh.new()
    shape.size = Vector3(4.4, 2.4, 0.12)
    board.mesh = shape
    board.position = Vector3(0, 1.5, 0)
    surface = StandardMaterial3D.new()
    surface.albedo_color = Color(0.9, 0.9, 0.9)
    surface.roughness = 1.0
    board.material_override = surface
    add_child(board)

    first_light = make_light(beam_colour, Vector3(-1, 1.5, 2.5), first_target)
    second_light = make_light(Color(0, 1, 0), Vector3(1, 1.5, 2.5), Vector3(1, 1.5, 0))

func make_light(colour: Color, at: Vector3, target: Vector3) -> SpotLight3D:
    var lamp := SpotLight3D.new()
    lamp.light_color = colour
    lamp.light_energy = 2.5
    lamp.spot_range = 6.0
    lamp.spot_angle = 18.0
    lamp.shadow_enabled = true
    lamp.position = at
    add_child(lamp)
    lamp.look_at(to_global(target))
    return lamp
```

## Which object receives the value?

Run the study. The first lamp makes a red pool on the left; the second makes a green pool on the right. Their positions, ranges and angles are fixed. The board receives both lights wherever their cones reach it.

Last time, `material.albedo_color` changed a surface's base colour. Here, `lamp.light_color` changes a light's RGB contribution. Both accept a `Color`, but they belong to different objects and affect the scene differently. Our surface keeps `Color(0.9, 0.9, 0.9)` throughout this lesson.

Change `beam_colour` to `Color(0, 0, 1)` and run again. The left pool becomes blue. The right lamp stays green, and the board's stored material is unchanged. Keep your viewpoint while comparing the two runs.

Other museum lights still contribute. The pool's edge may make the change easier to see than its brightest centre. The assigned RGB value is not a promise that every receiving pixel will display those same three numbers.

## Aim is a transformation

Restore `beam_colour` to `Color(1, 0, 0)`. Change `first_target` to `Vector3(1, 1.5, 0)` and run again. The first lamp now points towards the second lamp's target. Look where red and green meet. Their contributions can produce a yellow region on this pale surface. Neither lamp has been assigned yellow, and no yellow has been written into the board's material.

`make_light` creates a light, adds it to the study and returns its reference. The two variables keep different lights. Their `light_energy`, `spot_range` and `spot_angle` are held fixed so that colour and aim are the choices we compare. Range limits how far the light reaches; angle sets the cone's spread.

A spotlight shines along its local negative-Z direction. `look_at` turns that direction towards a world-space target. Our target is written in the study's local coordinates, so `to_global(target)` converts it before the call. This is the local/world distinction from Point Coordinates doing another job. Placing the study elsewhere in the museum should not make its light aim at an unrelated world origin.

The lamp must already be in the scene tree for this global aiming operation. That is why `add_child(lamp)` comes before `look_at`. This call turns the lamp; it does not move the lamp to the target. In the installed exhibit, turning the grabbable handle turns its child light instead.

## Withdraw one contribution

Keep the first lamp red. Change `first_target` to `Vector3(-1, 1.5, 5)` and run again. This target is behind the lamp, on the positive-Z side. The red cone points away from the board. The green pool remains. The board may still be visible under the room's other lights.

We have not switched off the first lamp: its colour, energy and position remain the same. We have changed where it points. Separating colour from aim lets us name which condition changed.

## Make another comparison

Choose another target on the board: keep X between -2 and 2, Y between 0.4 and 2.6, and Z at zero. Predict which way the first light must turn. Keep its colour and the second lamp fixed, then run your choice. Find what changed without attributing it to a new surface colour.

Keep the references `first_light` and `surface`, and the distinction between their colour properties. Our edits are applied in `_ready`; later controls could write to those same objects while the scene runs. This lesson does not add a colour picker to the museum's handles.

Back at the installed exhibit, carry a beam across the coarse sphere. Its faces meet the light in different directions. The side rooms then hold their lamps still while colour changes with time. Those encounters develop the comparison further. We have reconstructed its smallest working relation: a known surface, a light, and an aim.

In Nails, a hand position will choose a colour for a surface again. Keep asking where the value is written, and what else participates in its appearance.


---

<!-- hall:Color_Nails -->

# Nails — a position becomes a colour

**Learning elements**

- Local coordinates as input
- Function parameters and a returned Color
- Normalising three channels
- Clamping to a range
- Assigning the result to a material

Take the point in the museum's NAILS box. Move sideways, then upwards. One movement changes red; the other changes green. The swatch and the two salon hands answer the same choice.

In Coordinates, we read the point's position. Here we give that position another use. Flashlight changed the light reaching a surface; this lesson changes a surface's assigned colour.

## Continue with the point

Keep `point_body.gd` and `line_skin.gd` from Lines and Trace. Their construction and pickup behaviour are unchanged. [PointBody](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-nails-a-position-to-colour/point_body.gd) and [LineSkin](http://localhost:3003/book-review/doc/book/iterations/2026-10-06-nails-a-position-to-colour/line_skin.gd) are included here as the exact inherited files; [their first explanation](http://localhost:3003/book-review/doc/book/iterations/2026-10-05-primitives-facing-pages/Point_Lines.html) remains available.

Save `lesson.gd` below beside those two files. Attach it to a Node3D named `ColourStudy` in your working copy of the Endless Museum Nails hall. Place its origin about one metre above an open patch of floor: this is the lower corner of our colour box. Keep the study and its parents at unit scale. The museum supplies its room, camera, light, configured XR hands and XR Tools. Run only this study instance at the chosen place.

The script creates one familiar point, one preview tile, a readout and three guides. The guides show the positive X, Y and Z extents from the corner. The point begins within their 0.6-metre ranges. On desktop you can change `start` and run again; in the prepared VR scene, grip and carry the point.

This study sends its result directly to its preview. The installed salon already distributes colours to nail and skin materials and keeps them through GameManager. Those connections remain supplied museum infrastructure; this script does not attach itself to the salon hands.

## The complete continuation — lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const LineSkin = preload("line_skin.gd")

var box_size := Vector3(0.6, 0.6, 0.6)
var start := Vector3(0.48, 0.12, 0.36)
var point: XRToolsPickable
var preview: MeshInstance3D
var swatch: StandardMaterial3D
var readout: Label3D

func _ready() -> void:
    point = PointBody.new()
    point.position = start
    add_child(point)

    preview = MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.32, 0.32, 0.04)
    preview.mesh = box
    preview.position = Vector3(-0.35, 0.3, 0)
    swatch = StandardMaterial3D.new()
    swatch.roughness = 0.35
    preview.material_override = swatch
    add_child(preview)

    readout = Label3D.new()
    readout.position = Vector3(0.3, 0.85, 0)
    readout.font_size = 32
    readout.pixel_size = 0.003
    add_child(readout)

    for end in [Vector3(box_size.x, 0, 0), Vector3(0, box_size.y, 0), Vector3(0, 0, box_size.z)]:
        var guide := LineSkin.new()
        add_child(guide)
        guide.show_segment(Vector3.ZERO, end, end.length())

func _process(_delta: float) -> void:
    var local_position := to_local(point.global_position)
    var chosen := colour_at(local_position, box_size)
    swatch.albedo_color = chosen
    readout.text = "RGB %.2f  %.2f  %.2f" % [chosen.r, chosen.g, chosen.b]

func colour_at(p: Vector3, size: Vector3) -> Color:
    assert(size.x > 0 and size.y > 0 and size.z > 0)
    var channels := (p / size).clamp(Vector3.ZERO, Vector3.ONE)
    return Color(channels.x, channels.y, channels.z)
```

At the starting position, the readout should show `RGB 0.80  0.20  0.60`. Move along local X while keeping Y and Z still. Only the red number should change. Return to the same local position and the same three numbers return.

## A position goes in; a colour comes back

`colour_at(p: Vector3, size: Vector3) -> Color` names a function with two inputs and one output. `p` is a position measured from the study's corner. `size` gives the positive distance from that corner to the far boundary on each axis. These are parameters: names for the values supplied by a particular call.

Our call supplies `local_position` and `box_size`. The function has no hand, light or material reference. It calculates and returns a colour. `var chosen := ...` keeps that returned value; `swatch.albedo_color = chosen` gives it to the preview's material. Calculating a colour and deciding where to apply it are separate operations.

The assertion states the input requirement: all three dimensions must be greater than zero. A zero dimension cannot be a divisor. Keep positive dimensions; the assertion catches a broken requirement while running with Godot's debugging checks.

`p / size` divides each position component by its corresponding dimension. At X = 0.3 in a box 0.6 metres wide, red is 0.5. Doubling the box's width while keeping that position halves the red value. The same operation runs independently for green and blue.

`clamp(Vector3.ZERO, Vector3.ONE)` limits each resulting component to the interval 0–1. Below zero it returns zero; above one it returns one. Values already inside the range stay unchanged. `Color(channels.x, channels.y, channels.z)` uses them as red, green and blue, with alpha defaulting to one.

For the original box, predict these before trying them as `start`:

| Local position | Returned RGB |
|---|---|
| (0, 0, 0) | (0, 0, 0) |
| (0.6, 0.6, 0.6) | (1, 1, 1) |
| (0.6, 0, 0) | (1, 0, 0) |
| (-0.2, 0.9, 0.3) | (0, 1, 0.5) |

The function bounds the **colour**, not the body. Our point can move beyond the guides; the affected channel then stops changing. The installed salon also constrains its point to the box. This smaller example keeps that difference visible.

## Keep the frame explicit

`point.global_position` belongs to the world. `to_local(...)` expresses it in ColourStudy's frame before the mapping runs. Translate or turn the study: its starting point should still give the same colour. A world X value would describe a different input.

The point remains a pickup body. Its mesh, collider and release behaviour come from the inherited class. The three lines are only guides. Carrying the point does not change their lengths, move the preview or rebuild its geometry.

The numbers describe an assignment. Illumination, gloss and surrounding colours affect what you see. Equal numerical steps need not look equally different.

## Change one relation

1. Set `start` to `Vector3(0.6, 0, 0)`. Predict the readout, then run: red reaches one.
2. Restore the original start. Change only `box_size` to `Vector3(1.2, 0.6, 0.6)`. The X guide doubles; the initial red value becomes 0.40. Green and blue stay at 0.20 and 0.60.
3. Restore the original box. Set `start` to `Vector3(-0.2, 0.9, 0.3)`. The point is outside two boundaries; the readout is `0.00  1.00  0.50`.

Restore the original values. Choose another colour and work backwards to its position. With this box, multiply each desired channel by 0.6. Then check your prediction by moving the point or changing `start`.

For an independent continuation, make a second preview using the BoxMesh and separate material construction you already know. Give that material the same `chosen` value each frame, without changing `colour_at`. Both receivers should follow the point; changing one material's roughness must leave the other's settings alone. This is the small operation behind one choice reaching several surfaces.

Write down a chosen RGB triple. You can place that value in Rainbow's palette; there is no automatic transfer from this study. Keep `colour_at` too. Pillar will return to position-to-colour, with a different coordinate rule.



---

<!-- hall:Color_Rainbow -->

# Rainbow — keep the opening

**Learning elements**

- A palette as an ordered list of colours
- An index connecting a colour to a band
- Dividing a fixed extent among a changing number of parts

Walk through the museum's arches. Their arrangements differ, but each leaves an opening for a body. In Nails you chose a colour with a point. Here a colour joins a list, and the list changes the division of an arch.

This is a short, optional making lesson. The celebration, pickups and banner belong to the installed encounter. We will make one small arch to examine how its parts share an extent.

## Bring a chosen colour

Copy the RGB value you recorded in Nails into the first entry of `palette`. The starting example uses `Color(0.8, 0.2, 0.6)`. This is a deliberate transfer of a recorded value; the script does not retrieve it from the preceding hall.

Save `lesson.gd` and the supplied `arc_strip.gd` together. Attach `lesson.gd` to a Node3D in your working copy of the Rainbow hall, with its origin at the centre of an open display surface. Keep unit scale. The museum supplies the camera, light and player. This small arch stands in the local XY plane and has no collider.

`ArcStrip` builds one coloured semicircular band between two radii. Its complete implementation is printed below. Mesh construction returns from Primitives; the new decision here is how many bands share the available thickness.

## The complete study — lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const ArcStrip = preload("arc_strip.gd")
const INNER_RADIUS := 0.7
const TOTAL_THICKNESS := 0.6

var palette: Array[Color] = [Color(0.8, 0.2, 0.6), Color(0.15, 0.55, 0.9), Color(1, 0.8, 0.15)]
var bands: Array[MeshInstance3D] = []

func _ready() -> void:
    assert(not palette.is_empty())
    var width := TOTAL_THICKNESS / float(palette.size())
    for i in range(palette.size()):
        var inner := INNER_RADIUS + i * width
        var band := ArcStrip.new()
        band.build(inner, inner + width, palette[i])
        add_child(band)
        bands.append(band)
```

Run it. Three bands surround the same opening. The innermost radius is 0.7 metres; the outermost radius is 1.3 metres. `TOTAL_THICKNESS` is the radial thickness of all the bands together, not the diameter of the whole arch.

`palette.size()` is the number of entries. Dividing 0.6 by three gives each band a width of 0.2. The loop visits each index `i`: it advances that band's inner radius by `i * width`, then uses `palette[i]` for its colour. Each outer radius meets the next inner radius.

The assertion requires a nonempty palette. We cannot divide the thickness among zero bands. Every nonempty palette keeps the same inner and outer boundaries; only their internal division changes.

## Change the division

Replace the three-entry palette with `[Color(0.8, 0.2, 0.6), Color.WHITE]`. Predict the width, then run. Each band is 0.3 metres thick. Restore the original palette and append `Color.BLACK`: four bands now share the same 0.6 metres, each taking 0.15.

Change one colour without adding or removing an entry. The geometry should stay still. Band count and colour assignment are separate decisions. This example couples them by making one band per palette entry. Another arrangement could repeat two colours across six bands; the number of available colours would then differ from the number of parts, as it did in the opening Colour lesson.

Choose your own nonempty palette. Before running, state how many bands will appear, their individual width, and the outer radius. As a boundary case, use one colour: it occupies the full thickness without closing the opening.

The museum's arches are larger and use their own palettes and arrangement. This study retains their fixed-extent construction. Its colours are assigned surface values; it does not simulate wavelengths or the optics of a rainbow.

## Supplied band builder — arc_strip.gd

<!-- student-code:arc_strip.gd -->
```gdscript
# Supplied renderer: a reduced version of rainbow.gd's concentric half-strips.
extends MeshInstance3D

const STEPS := 32
var inner_radius: float
var outer_radius: float

func build(inner: float, outer: float, colour: Color) -> void:
    inner_radius = inner
    outer_radius = outer
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    var indices := PackedInt32Array()
    for i in range(STEPS + 1):
        var angle := PI * float(i) / STEPS
        var direction := Vector3(cos(angle), sin(angle), 0)
        vertices.append(direction * inner)
        vertices.append(direction * outer)
        normals.append(Vector3.BACK)
        normals.append(Vector3.BACK)
    for i in range(STEPS):
        var n := i * 2
        indices.append_array([n, n + 1, n + 2, n + 1, n + 3, n + 2])
    var data := []
    data.resize(Mesh.ARRAY_MAX)
    data[Mesh.ARRAY_VERTEX] = vertices
    data[Mesh.ARRAY_NORMAL] = normals
    data[Mesh.ARRAY_INDEX] = indices
    var result := ArrayMesh.new()
    result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
    mesh = result
    var material := StandardMaterial3D.new()
    material.albedo_color = colour
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material_override = material
```

The builder samples a semicircle, storing an inner and an outer vertex at each angle. Two triangles join each neighbouring pair. The material is independent for each band and unshaded so the palette remains easy to compare. Changing the palette does not change this renderer.

Keep the chosen list. Pillar will ask how a function can produce colours between selected values, instead of choosing only among entries.


---

<!-- hall:Color_Pillar -->

# Pillar — colour has a height

**Learning elements**

- Hue, saturation and value as a coordinate model
- A function returning a colour from a position
- Mapping a reachable height to a taller field
- Distinguishing a colour value from illumination

Stand among the museum's columns. Colour rises towards the ceiling; near their tops, a column and its surrounding colour can become hard to separate. The dark floor gives that ascent a beginning.

Return to the point from Nails. Its position still supplies three numbers, but the numbers now control hue, saturation and value. Y becomes a way to move from dark to light while X and Z stay still.

## Continue with PointBody

Keep the unchanged `point_body.gd` from Lines, Coordinates and Nails. Save `lesson.gd` beside it. Attach the script to a Node3D in your working copy of the Pillar hall. Its local origin is the floor-level corner of a 12.8 by 19.2 metre colour field, with X across and Z along the field. Keep the study and its parents at unit scale. These extents match the museum's colour rule; they are not inferred from room walls.

The point starts halfway across that field, 1.25 metres above its floor. The small preview and readout travel with it. Walk to it and grip it using the prepared XR hands. On desktop, change `start` and run again. The existing columns and ceiling remain the large illustration; this study adds a sampler and does not rebuild them or attach itself to their materials.

## The complete continuation — lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const VALUE_BOTTOM := 0.46
const VALUE_TOP := 4.6

var start := Vector3(6.4, 1.25, 9.6)
var point: XRToolsPickable
var swatch: StandardMaterial3D
var readout: Label3D

func _ready() -> void:
    point = PointBody.new()
    point.position = start
    add_child(point)
    var preview := MeshInstance3D.new()
    var tile := BoxMesh.new()
    tile.size = Vector3(0.28, 0.28, 0.025)
    preview.mesh = tile
    preview.position = Vector3(0.35, 0, 0)
    swatch = StandardMaterial3D.new()
    swatch.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    preview.material_override = swatch
    point.add_child(preview)
    readout = Label3D.new()
    readout.position = Vector3(0.35, 0.35, 0)
    readout.font_size = 28
    readout.pixel_size = 0.002
    point.add_child(readout)

func _process(_delta: float) -> void:
    var hand := to_local(point.global_position)
    var field := hand_to_field(hand)
    var hsv := hsv_at(field)
    var colour := colour_at(field)
    swatch.albedo_color = colour
    readout.text = "HSV %.3f %.3f %.3f\nRGB %.3f %.3f %.3f" % [hsv.x, hsv.y, hsv.z, colour.r, colour.g, colour.b]

func hand_to_field(hand: Vector3) -> Vector3:
    var fraction := clampf((hand.y - 0.65) / 1.2, 0, 1)
    return Vector3(hand.x, lerpf(VALUE_BOTTOM, VALUE_TOP, fraction), hand.z)

func hsv_at(p: Vector3) -> Vector3:
    var hue := clampf(p.x / 12.8, 0, 1) * 0.85
    var saturation := lerpf(0.25, 1.0, clampf(p.z / 19.2, 0, 1))
    var value := clampf((p.y - VALUE_BOTTOM) / (VALUE_TOP - VALUE_BOTTOM), 0, 1)
    return Vector3(hue, saturation, value)

func colour_at(p: Vector3) -> Color:
    var hsv := hsv_at(p)
    return Color.from_hsv(hsv.x, hsv.y, hsv.z)
```

At the start, expect `HSV 0.425 0.625 0.500` and approximately `RGB 0.188 0.500 0.359`. The displayed RGB numbers are rounded; their unrounded values are `(0.1875, 0.5, 0.359375)`.

## Two mappings, two scales

`to_local(point.global_position)` expresses the carried point in this study's frame. `hand_to_field` then maps reachable hand heights from 0.65 to 1.85 metres onto field heights from 0.46 to 4.6 metres. You can inspect the whole vertical colour range without reaching the ceiling. `clampf` stops the returned fraction at zero and one; it does not stop your hand.

`hsv_at` gives each field coordinate a role. X chooses hue from 0 to 0.85. Z chooses saturation from 0.25 to 1. Y chooses value from 0 to 1. These ranges are authored decisions, including the omitted end of the hue cycle and the absence of zero saturation.

`colour_at` passes those three values to `Color.from_hsv` and returns a Color. The receiving material needs RGB channels; Godot performs the conversion. `hsv_at` also returns the original parameters for the readout, so a hue remains visible as a number even when value is zero and the swatch is black.

In Nails, moving up changed green. Here it changes value. The axis has acquired a different function. Neither coordinate arrangement is inherent in colour.

## Hold two coordinates still

1. Keep X = 6.4 and Z = 9.6. Set the starting Y to 0.65. Value reaches zero and the preview is black.
2. Set Y to 1.85. Value reaches one. Hue and saturation keep their previous values; all three RGB channels are twice their middle-height values.
3. Set Y to 2.5. The point is above the mapped hand range, but value stays at one.

Restore the starting height. Choose another X or Z and predict which HSV parameter will change. Then choose two different positions with the same Y. Their colours can differ while their value parameter stays equal.

The preview uses an unshaded material for comparison. Raising value does not add a light, and equal value does not guarantee equal perceived brightness for different hues. The columns' lighting and the ceiling's apparent fog belong to the larger encounter.

Write down one RGB result with enough precision to use again. Grid begins with the middle sample above as an entry in a palette. That record is the handoff; no automatic save between these study scripts is assumed.

## Inherited point — point_body.gd

The exact earlier class is included for a complete runnable folder. Its sphere, collider and pickup behaviour remain unchanged.

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


---

<!-- hall:Color_Grid_Pallet -->

# Grid — a colour left at an address

**Learning elements**

- An address selecting stored instance colour
- A small class holding a palette and its current index
- Independent instances of the same class
- A local edit beside a rule over the whole grid

In the museum's grid, select a place and leave a colour there. Move to another place. The first choice remains. An address keeps the colour after your attention has moved on.

Arrays gave us indexed parts. Nails and Pillar returned a colour from a position. Now one of those returned colours becomes stored data. The new class keeps an ordered palette and remembers which entry comes next.

## Make two palettes

Save the four files printed here together. Attach `lesson.gd` to a Node3D on a clear display surface in your working copy of the Grid hall. The museum supplies your view and movement. This compact 5 by 5 model reconstructs the addressed colour operation; the installed floor and its interaction console remain in place.

`GridSurface` supplies 25 visible tiles and a dictionary connecting each `Vector2i(x, z)` address to a MultiMesh instance. Its `read`, `write` and `mark` methods are printed below. The second component of a Vector2i is called `y` in code; here we use it for the floor's Z address.

## The complete continuation — lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const Palette = preload("palette.gd")
const GridSurface = preload("grid_surface.gd")
const Controls = preload("controls.gd")

var selected := Vector2i(2, 2)
var palette_index := 0
var palettes: Array = []
var grid: Node3D

func _ready() -> void:
    var sample := Color(0.1875, 0.5, 0.359375)
    palettes = [
        Palette.new([sample, Color.WHITE, Color.BLACK]),
        Palette.new([Color(0.8, 0.2, 0.6), Color(1, 0.8, 0.15)])
    ]
    grid = GridSurface.new()
    add_child(grid)
    add_child(Controls.new())
    apply_rule()
    select_address(selected)

func select_address(address: Vector2i) -> void:
    if not grid.cells.has(address):
        return
    selected = address
    grid.mark(selected)

func paint_selected() -> void:
    var palette = palettes[palette_index]
    grid.write(selected, palette.current_colour())
    palette.next_colour()
    grid.mark(selected)

func next_palette() -> void:
    palette_index = (palette_index + 1) % palettes.size()

func apply_rule() -> void:
    var colours: Array[Color] = palettes[palette_index].colours
    for address: Vector2i in grid.cells:
        var i := (address.x + address.y) % colours.size()
        grid.write(address, colours[i])
    grid.mark(selected)
```

## The state we keep — palette.gd

<!-- student-code:palette.gd -->
```gdscript
extends RefCounted

var colours: Array[Color] = []
var index := 0

func _init(choices: Array[Color]) -> void:
    assert(not choices.is_empty())
    colours.assign(choices)

func current_colour() -> Color:
    return colours[index]

func next_colour() -> Color:
    index = (index + 1) % colours.size()
    return current_colour()
```

`Palette.new(choices)` creates an instance. Its `_init` copies the chosen list with `assign`, so changing the caller's list later will not quietly change this palette. Colour values are copied; this is not a general deep-copy rule for objects.

`current_colour` returns the entry at `index`. `next_colour` advances the index, wraps it with `%`, and returns the new current entry. `paint_selected` first writes the current colour, then advances. The next press therefore uses the next entry. An empty palette violates the constructor's assertion.

We already used a PointBody class. This class has no mesh or position: its useful behaviour is remembering an ordered choice. The two instances have separate lists and indices. Advancing the first cannot advance the second.

The first palette includes the RGB sample recorded in Pillar. The second includes our earlier Nails choice. Those are explicit recorded values, not an automatic connection to either previous hall.

## Leave one mark

Run. Press **X** or **Z** to advance the selected address along that axis, wrapping after four. Press **C** to write the active palette's current colour there. Move the selection: the colour remains at the old address. Press **P** to select the other palette; this alone changes no tile. Press **C** again to use it.

Selection and painting are separate functions. `select_address` first checks that the address exists, then moves the marker. `paint_selected` changes the stored instance colour. Neither operation changes tile positions.

Press **R**. `apply_rule` visits every address and chooses `(x + z) % colours.size()` from the active palette. The sum advances along either axis, producing diagonal repetition. This replaces individual edits in the study's 25 tiles. A local memory can be overwritten by a later rule.

## Check what remains independent

Paint twice with the first palette. Switch to the second and paint once. Switch back: the first should continue at its third entry. Selecting another tile should neither consume an entry nor recolour it.

Try a one-entry first palette: replace its choices with `[sample]`. Every index wraps to zero. Then try four entries, `[sample, Color.WHITE, Color.BLACK, Color(0.8, 0.2, 0.6)]`. Predict how the diagonals change when you press R. The address dictionary and tile geometry stay unchanged.

For your own continuation, choose a new palette and make a small arrangement by painting selected addresses. Record one address and its colour. Predict which entry the rule will put there, then press R and compare. Explain the difference between the address, the instance index and the palette index.

## Supplied display — grid_surface.gd

<!-- student-code:grid_surface.gd -->
```gdscript
# Supplied addressed receiver; a compact model of address_lesson.gd's floor.
extends Node3D

var cells: Dictionary = {}
var instances: MultiMesh
var marker: MeshInstance3D
var readout: Label3D

func _ready() -> void:
    var tile := BoxMesh.new()
    tile.size = Vector3(0.28, 0.06, 0.28)
    var material := StandardMaterial3D.new()
    material.vertex_color_use_as_albedo = true
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    tile.material = material
    instances = MultiMesh.new()
    instances.transform_format = MultiMesh.TRANSFORM_3D
    instances.use_colors = true
    instances.mesh = tile
    instances.instance_count = 25
    var view := MultiMeshInstance3D.new()
    view.multimesh = instances
    add_child(view)
    var index := 0
    for z in range(5):
        for x in range(5):
            var address := Vector2i(x, z)
            cells[address] = index
            instances.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(x * 0.32, 0, z * 0.32)))
            instances.set_instance_color(index, Color.WHITE)
            index += 1
    marker = MeshInstance3D.new()
    var ring := TorusMesh.new()
    ring.inner_radius = 0.19
    ring.outer_radius = 0.205
    marker.mesh = ring
    add_child(marker)
    readout = Label3D.new()
    readout.position = Vector3(0.64, 0.65, 0.2)
    readout.font_size = 24
    readout.pixel_size = 0.003
    add_child(readout)

func write(address: Vector2i, colour: Color) -> bool:
    if not cells.has(address):
        return false
    instances.set_instance_color(cells[address], colour)
    return true

func read(address: Vector2i) -> Color:
    assert(cells.has(address))
    return instances.get_instance_color(cells[address])

func mark(address: Vector2i) -> void:
    marker.position = instances.get_instance_transform(cells[address]).origin + Vector3(0, 0.06, 0)
    readout.text = "(%d, %d) #%s\nX / Z: select   C: colour   P: palette   R: rule" % [address.x, address.y, read(address).to_html(false)]
```

`use_colors` is enabled before the instance count is assigned. The shared mesh material reads each instance's colour through `vertex_color_use_as_albedo`. The tiles share a material; they do not require 25 separate materials. The dictionary declares the address-to-index connection rather than assuming that every museum floor uses the same ordering.

## Supplied desktop adapter — controls.gd

<!-- student-code:controls.gd -->
```gdscript
# Supplied desktop test adapter. Museum console bindings call the same methods.
extends Node

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    var study := get_parent()
    match event.keycode:
        KEY_X:
            study.select_address(Vector2i((study.selected.x + 1) % 5, study.selected.y))
        KEY_Z:
            study.select_address(Vector2i(study.selected.x, (study.selected.y + 1) % 5))
        KEY_C:
            study.paint_selected()
        KEY_P:
            study.next_palette()
        KEY_R:
            study.apply_rule()
```

These keys call the same named operations as a console could. The installed museum console and larger, irregularly addressed floor remain supplied infrastructure. The small study has no walking-floor collider or VR console of its own.

Keep `Palette`. Walls will give two surfaces their own instances. Paint first changes the scale of the stored mark: from one tile to a region of a surface.


---

<!-- hall:Color_Paint -->

# Paint — a mark stays on the surface

**Learning elements**

- Held, active and valid-hit states
- A named action carried from input to an operation
- A ray selecting the first surface it meets
- A world hit converted to a surface address
- Repeated marks accumulating in one image

Take a spray can in the museum. Colour arrives where the nozzle meets a surface; it remains when you turn away. Grid kept one colour at a cell address. Paint keeps many small deposits in a surface image.

We return to PointBody as a small study brush. Its pickup behaviour is already built. The lesson adds the path from a held object and an action to a retained mark. The museum's can shell, mist, wetness, elongated deposits and paint runs are richer than this study's circular soft stamps.

The first goal is one mark you can account for: **hold → request spray → aim → accepted hit → surface address → retained colour**. Keep `automatic` set to `false`. The automatic caller is included in the complete script for an optional continuation after your own brush works.

## Continue with the point

Save the four files below together. Keep the exact `point_body.gd` from Lines and Coordinates. Attach `lesson.gd` to a Node3D in an open part of your working museum hall. Keep unit scale throughout. Its local origin is on the floor; the white canvas is centred at Y = 1.5, faces positive Z and measures 4 by 2.5 metres. The point begins 1.5 metres in front of it. The museum supplies the camera, player and configured XR Tools.

Grip the point in VR. Its forward direction is local negative Z, indicated by the small stem. The prepared pickup driver calls its action methods when you press and release the controller trigger. In this study we name that action `spray`. On desktop, press **H** to attach the study brush to the mouse ray, then hold the left mouse button to paint. Press H again to put it down. This adapter is included; it is not a new input-map setup lesson.

## The complete continuation — lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const PointBody = preload("point_body.gd")
const Canvas = preload("canvas.gd")
const Controls = preload("controls.gd")

@export var ink := Color(0.8, 0.2, 0.6)
var radius := 0.06
var max_distance := 3.0
var automatic := false
var elapsed := 0.0
var held := false
var active := false
var spraying := false
var painting := false
var point: XRToolsPickable
var canvas: MeshInstance3D
var readout: Label3D

func _ready() -> void:
    canvas = Canvas.new()
    canvas.position = Vector3(0, 1.5, 0)
    canvas.rotation.x = PI / 2.0
    add_child(canvas)
    point = PointBody.new()
    point.position = Vector3(0, 1.5, 1.5)
    add_child(point)
    var stem := MeshInstance3D.new()
    var nozzle := BoxMesh.new()
    nozzle.size = Vector3(0.035, 0.035, 0.22)
    stem.mesh = nozzle
    stem.position.z = -0.2
    point.add_child(stem)
    point.picked_up.connect(func(_body): set_held(true))
    point.dropped.connect(func(_body): set_held(false))
    point.action_pressed.connect(func(_body): set_action("spray", true))
    point.action_released.connect(func(_body): set_action("spray", false))
    readout = Label3D.new()
    readout.position = Vector3(0, 2.95, 0)
    readout.font_size = 30
    readout.pixel_size = 0.004
    add_child(readout)
    add_child(Controls.new())

func set_held(value: bool) -> void:
    held = value
    if not held:
        active = false

func set_action(action_name: String, pressed: bool) -> void:
    if action_name == "spray":
        active = pressed and held

func _physics_process(delta: float) -> void:
    elapsed += delta
    manual_step(delta)
    if automatic:
        automatic_step(elapsed, delta)
    readout.text = "MARK" if painting else ("SPRAY / MISS" if spraying else "READY")

func manual_step(delta: float) -> void:
    painting = false
    spraying = held and active
    if not spraying:
        return
    var origin := point.global_position
    var direction := -point.global_basis.z.normalized()
    var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * max_distance, 1, [point.get_rid()])
    query.collide_with_areas = true
    var hit := get_world_3d().direct_space_state.intersect_ray(query)
    if hit.get("collider") != canvas.receiver:
        return
    painting = canvas.draw_spray(hit.position, direction, radius, ink, 1.0 - exp(-7.0 * delta))

func automatic_step(time: float, delta: float) -> void:
    var uv := Vector2(0.5 + 0.3 * sin(time), 0.5 + 0.3 * sin(time * 1.3))
    var hit: Vector3 = canvas.world_at(uv)
    canvas.draw_spray(hit, -canvas.global_basis.y.normalized(), radius, ink, 1.0 - exp(-7.0 * delta))
```

Run and aim at the canvas. **READY** means the manual brush is not active. **SPRAY / MISS** means it is active but has no accepted canvas hit. **MARK** means the current step reached the receiver and deposited colour. These are state readouts; the reduced study has no particle mist.

## Permission, aim, address

Picking up the point sets `held`. An action press can set `active` only while held. Releasing the action clears it; dropping the point clears it too. Calling `set_action` with another name does nothing. Those conditions decide whether `manual_step` may attempt a mark.

The ray begins at the point and travels along its forward axis, up to `max_distance`. It excludes the point's own physics body. `collide_with_areas` lets it find the canvas receiver, which is an Area3D. The first hit must be that receiver. A miss or another object in front of the canvas leaves the image unchanged.

The hit position belongs to the world. The canvas converts it with `to_local`, then divides local X and Z by its width and height to obtain a UV address between zero and one. The canvas was turned upright as a whole; its local drawing plane is still XZ. This lets the same address calculation work when the study is moved or turned.

`draw_spray` blends the ink into existing pixels near that address. Closer pixels receive more. The amount `1 - exp(-7 * delta)` describes an accumulation rate: with a stationary brush and the same soft weight, shorter time steps approach the colour in smaller increments. Rasterisation and pixel rounding still affect the result. This is a simple deposit model, not a physical aerosol simulation.

## Make and keep a mark

1. Paint briefly at the centre. Hold still longer: the same region grows closer to the ink colour. Move away and release. The earlier mark remains.
2. Change `radius` from 0.06 to 0.12. The physical radius doubles. Width and height are converted separately, so the 4 by 2.5 metre canvas does not stretch a circular stamp into an oval.
3. Restore the radius. Set `max_distance` to 1.0. At the initial point position the surface is out of reach; pressing produces no mark. Restore 3.0 and it is reachable again.

Choose another ink colour and use it over an existing mark while the study is running, through the inspector's Remote view. `@export` exposes `ink` there: select the running study node and edit its Ink property. The image keeps its previous contents and the new deposits blend into them. Restarting this study creates a fresh white image; saving it across sessions is not part of this lesson.

## Know when the manual lesson works

With the automatic caller still off, choose a new ink colour and a clear part of the canvas. Before pressing, predict where the mark will appear. Aim away while holding the action: the readout should become **SPRAY / MISS** and deposits should stop. Aim back: **MARK** returns. Release the action or put down the point: **READY** returns and the earlier marks remain.

You have completed the core lesson when you can make that mark, interrupt it, and explain where its colour is kept. The image holds the accumulated result. The point supplies an aim and a request; it does not keep the painted marks.

## Supplied receiver — canvas.gd

<!-- student-code:canvas.gd -->
```gdscript
# Supplied small image receiver. Shares the museum's XZ-plane coordinate convention.
# Soft circular stamps accumulate; aerosol grains, oblique stretching, runs and fading are omitted.
extends MeshInstance3D

const SIZE := Vector2(4, 2.5)
const PIXELS := Vector2i(512, 320)
var receiver: Area3D
var image: Image
var texture: ImageTexture
var deposits := 0

func _ready() -> void:
    var plane := PlaneMesh.new()
    plane.size = SIZE
    mesh = plane
    image = Image.create(PIXELS.x, PIXELS.y, false, Image.FORMAT_RGBA8)
    image.fill(Color.WHITE)
    texture = ImageTexture.create_from_image(image)
    var surface := StandardMaterial3D.new()
    surface.albedo_texture = texture
    surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material_override = surface
    receiver = Area3D.new()
    receiver.collision_layer = 1
    receiver.collision_mask = 0
    var boundary := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = Vector3(SIZE.x, 0.02, SIZE.y)
    boundary.shape = box
    receiver.add_child(boundary)
    add_child(receiver)

func uv_at(world_hit: Vector3) -> Vector2:
    var p := to_local(world_hit)
    return Vector2(p.x / SIZE.x + 0.5, p.z / SIZE.y + 0.5)

func world_at(uv: Vector2) -> Vector3:
    return to_global(Vector3((uv.x - 0.5) * SIZE.x, 0, (uv.y - 0.5) * SIZE.y))

func draw_spray(world_hit: Vector3, direction: Vector3, radius_m: float, colour: Color, opacity: float) -> bool:
    if radius_m <= 0 or opacity <= 0:
        return false
    var normal := global_basis.y.normalized()
    if -normal.dot(direction.normalized()) < 0.22:
        return false
    var uv := uv_at(world_hit)
    if uv.x < 0 or uv.x > 1 or uv.y < 0 or uv.y > 1:
        return false
    var centre := uv * Vector2(PIXELS)
    var extent := Vector2(radius_m / SIZE.x, radius_m / SIZE.y) * Vector2(PIXELS)
    var wrote := false
    for y in range(maxi(0, floori(centre.y - extent.y)), mini(PIXELS.y, ceili(centre.y + extent.y))):
        for x in range(maxi(0, floori(centre.x - extent.x)), mini(PIXELS.x, ceili(centre.x + extent.x))):
            var offset := (Vector2(x + 0.5, y + 0.5) / Vector2(PIXELS) - uv) * SIZE
            var weight := clampf(1.0 - offset.length() / radius_m, 0, 1)
            var amount := clampf(opacity, 0, 1) * weight
            if amount > 0:
                image.set_pixel(x, y, image.get_pixel(x, y).lerp(colour, amount))
                wrote = true
    if not wrote:
        return false
    texture.update(image)
    deposits += 1
    return true
```

The receiver rejects invalid radii, empty deposits, outside addresses and rays facing away or too obliquely. It allocates the image once, blends into its pixels, then updates the texture shown by the material. Its support code is visible so the mark has no hidden implementation. The lesson's focus is connecting the known body and action to this surface operation; GPU feedback, wet-paint chemistry and drip motion remain outside this reduced model.

## Supplied desktop adapter — controls.gd

<!-- student-code:controls.gd -->
```gdscript
# Supplied desktop adapter. H engages/releases a mouse-aimed study brush.
# XR uses the inherited body's pickup and action signals instead.
extends Node

var engaged := false

func _unhandled_input(event: InputEvent) -> void:
    var study := get_parent()
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_H:
        engaged = not engaged
        study.set_held(engaged)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and engaged:
        study.set_action("spray", event.pressed)

func _process(_delta: float) -> void:
    if not engaged:
        return
    var camera := get_viewport().get_camera_3d()
    if camera == null:
        return
    var mouse := get_viewport().get_mouse_position()
    var direction := camera.project_ray_normal(mouse)
    var at := camera.project_ray_origin(mouse) + direction * 0.5
    var point: Node3D = get_parent().point
    point.global_position = at
    point.look_at(at + direction)
```

## Inherited body — point_body.gd

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

## Optional continuation — another caller, the same receiver

Continue here after the manual lesson works. You can also leave the automatic painter as an encounter in the museum and proceed to Walls.

Set `automatic` to true and run. `automatic_step` supplies a moving UV address through two sine functions, maps it back to the canvas and calls the same `draw_spray` method. It does not require the manual brush to be held. Manual and automatic callers accumulate in the same image. The addition demonstrates reuse of the receiver; it is not required to complete the manual painting lesson.

Change the second sine rate from 1.3 to 2.0. Predict how its repeated path differs. Keep the manual controls working while the path runs. The canvas should not need a second renderer for another source of marks.

Paint leaves state on a surface. Walls next asks what happens when a surface changes the view through it while its physical boundary stays put.


---

<!-- hall:Color_Walls -->

# Walls — a view through two colours

**Learning elements**

- Alpha and the material's transparency mode
- Independent palettes and materials
- Rendered appearance beside a persistent collider
- Position and rotation changing the overlap of coloured surfaces

Walk beside the museum's coloured partitions. Two panes overlap from one place, then separate as you move. A view changes without either wall moving. Try to pass through one: being able to see through it has not made a passage.

Transformation supplied position and rotation. Grid gave each Palette its own remembered index. Bring both back. We will give two panes independent colours and switch their appearance between translucent and opaque.

## Two surfaces, two choices

Keep `palette.gd` from Grid unchanged. Save it beside `lesson.gd`, `pane.gd` and `controls.gd` below. Attach `lesson.gd` to a Node3D at floor level in an open patch of your working Walls hall. Keep unit scale. Approach from positive local Z. The museum supplies the view, movement, light and surrounding architecture.

`Pane` makes one 2 by 2.5 metre sheet and one thin box collider. The two panes are offset and the second is turned by 15 degrees. Each has its own material and Palette. This reconstructs a small part of the installed office's larger composition.

## The complete continuation — lesson.gd

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D

const Palette = preload("palette.gd")
const Pane = preload("pane.gd")
const Controls = preload("controls.gd")

var filter_mode := true
var opacity := 0.52
var positions: Array[Vector3] = [Vector3(-0.4, 1.25, 0), Vector3(0.4, 1.25, -0.8)]
var turns: Array[float] = [0.0, 15.0]
var palettes: Array = []
var panes: Array[StaticBody3D] = []

func _ready() -> void:
    palettes = [
        Palette.new([Color(0.2, 0.9, 0.9), Color(1, 0.8, 0.15)]),
        Palette.new([Color(0.8, 0.2, 0.6), Color(0.15, 0.55, 0.9)])
    ]
    for i in range(positions.size()):
        var pane := Pane.new()
        pane.position = positions[i]
        pane.rotation_degrees.y = turns[i]
        add_child(pane)
        panes.append(pane)
    add_child(Controls.new())
    apply_colours()

func surface_colour(colour: Color, filtered: bool) -> Color:
    colour.a = clampf(opacity, 0, 1) if filtered else 1.0
    return colour

func apply_colours() -> void:
    for i in range(panes.size()):
        var material: StandardMaterial3D = panes[i].surface
        material.albedo_color = surface_colour(palettes[i].current_colour(), filter_mode)
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if filter_mode else BaseMaterial3D.TRANSPARENCY_DISABLED

func toggle_filter() -> void:
    filter_mode = not filter_mode
    apply_colours()

func change_first() -> void:
    palettes[0].next_colour()
    apply_colours()
```

Run. Press **F** to switch between filter and opaque modes. Press **C** to advance the first pane's palette. Move sideways to change which parts overlap. The second pane's colour should remain unchanged when you advance the first.

`surface_colour` takes a Color value and returns one with an assigned alpha. It preserves RGB. In filter mode it bounds `opacity` to 0–1; opaque mode uses one. Because Color is a value, this local change does not alter the stored palette entry.

The material also needs the matching transparency mode. Alpha alone is insufficient when the material is configured to render as opaque. `apply_colours` sets both properties. It never moves a pane, resizes its collider or changes collision layers.

## Separate what changes

Set `opacity` to 0.2 and run. More of the view behind the sheet contributes to the composite. Then try 1.0. Switch with F: at full alpha the visible difference may disappear even though the selected mode changes. In both cases the same collider remains.

Restore 0.52. Change only the second value in `turns` from 15 to 45 degrees. The overlap changes through geometry. Change only a palette entry: its colour changes through material state. These are different ways to compose with the same panes.

For your own continuation, arrange the two panes so one chosen view has a large overlap and a nearby view has none. Keep both palettes independently changeable. Explain which values you changed and why the route around the panes remains open while the panes themselves still block passage.

This is ordinary alpha compositing, not spectral transmission through glass. It depends on the colours and order of rendered surfaces and on the view behind them. It does not guarantee physically accurate mixing. The unshaded sheets make those assigned colours easier to inspect; they do not illuminate the room.

## Supplied pane — pane.gd

<!-- student-code:pane.gd -->
```gdscript
# Supplied pane: one rendered sheet, one persistent physical boundary.
extends StaticBody3D

var surface: StandardMaterial3D
var boundary: CollisionShape3D

func _ready() -> void:
    var view := MeshInstance3D.new()
    var sheet := QuadMesh.new()
    sheet.size = Vector2(2, 2.5)
    view.mesh = sheet
    surface = StandardMaterial3D.new()
    surface.cull_mode = BaseMaterial3D.CULL_DISABLED
    surface.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    view.material_override = surface
    add_child(view)
    boundary = CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = Vector3(2, 2.5, 0.04)
    boundary.shape = shape
    add_child(boundary)
```

The sheet and boundary are separate children of one body. The boundary's size stays `(2, 2.5, 0.04)` in both modes. Disabling it would be a different operation with a different effect on movement.

## Inherited palette — palette.gd

<!-- student-code:palette.gd -->
```gdscript
extends RefCounted

var colours: Array[Color] = []
var index := 0

func _init(choices: Array[Color]) -> void:
    assert(not choices.is_empty())
    colours.assign(choices)

func current_colour() -> Color:
    return colours[index]

func next_colour() -> Color:
    index = (index + 1) % colours.size()
    return current_colour()
```

## Supplied controls — controls.gd

<!-- student-code:controls.gd -->
```gdscript
# Supplied desktop test adapter; these methods can also receive museum buttons.
extends Node

func _unhandled_key_input(event: InputEvent) -> void:
    if not event is InputEventKey or not event.pressed or event.echo:
        return
    if event.keycode == KEY_F:
        get_parent().toggle_filter()
    elif event.keycode == KEY_C:
        get_parent().change_first()
```

Keep the distinction at the end of Colour: a choice can change a surface, a light, a stored address or the composite seen through several layers. State where the colour is held and which operation receives it. The same three channel values do not make those operations interchangeable.
