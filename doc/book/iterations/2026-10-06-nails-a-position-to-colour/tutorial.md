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

Keep `point_body.gd` and `line_skin.gd` from Lines and Trace. Their construction and pickup behaviour are unchanged. [PointBody](point_body.gd) and [LineSkin](line_skin.gd) are included here as the exact inherited files; [their first explanation](../2026-10-05-primitives-facing-pages/Point_Lines.html) remains available.

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

