# Fields add

**Learning elements**

- A finite sum of spatial contributions
- Layer count, frequency ratio and amplitude ratio
- Seeded offsets kept between edits
- Raw values and display normalization

Synthesis added weighted waves; Space Geometry sampled a field at neighbouring addresses. Here **fields combine at each address**. Sample several contributions and add them. Pheromone changed its field through visits; this construction returns the same value whenever the address and settings return.

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
