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
