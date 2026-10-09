# A letter carries its opening

## Learning elements

- A supplied outline with a hole
- Cross-section versus route
- Sampling placements along a path
- Declaring a dependency

## In the museum

An O can become a short hollow passage. Its interior opening is part of the source outline, not a hole we draw afterward. The museum's glyph gallery explores this relation at architectural scale. Here we use its existing outline-and-sweep builder for one small visible body.

Columns gave a generated cross-section a sequence of placements. Now the font supplies the cross-section, and we choose the placements. Font extraction, triangulation and boundary stitching are explicitly supplied work, not concepts you are expected to reconstruct in this lesson.

## Make this study

Put lesson.gd, profile_sweep.gd, JetBrainsMono-Medium.ttf and its OFL licence in one folder. The font and licence are in this lesson's downloadable folder; let Godot import the font. Attach lesson.gd to a Node3D named ProfileStudy in the existing museum.

This small example is a visible hollow mesh, without a collider. Its O has a lower sill, so “opening” does not mean a floor-level walk-through doorway. The museum's larger passage uses its own placement and collision setup.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const Sweep = preload("profile_sweep.gd")
const FONT = preload("JetBrainsMono-Medium.ttf")
const WIDTH := 1.4
const DEPTH := 1.6
const OFFSET := 0.5
var section: Dictionary
var frames: Array[Transform3D] = []
var body := MeshInstance3D.new()

func _ready() -> void:
    section = Sweep.profile(FONT, "O")
    for i in range(5):
        var fraction := i / 4.0
        var at := Vector3(OFFSET * fraction, 1.1, DEPTH * fraction)
        var frame := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * WIDTH), at)
        frames.append(frame)
    body.mesh = Sweep.make(section, frames)
    var finish := StandardMaterial3D.new()
    finish.albedo_color = Color(0.78, 0.62, 0.72)
    finish.roughness = 0.4
    body.material_override = finish
    add_child(body)
```

### Dependency: profile_sweep.gd

<!-- student-code:profile_sweep.gd -->
```gdscript
extends RefCounted
## TextMesh supplies a triangulated 2D region, including holes and components.
## A sequence of section frames turns that region into a body. No font is edited.

static func profile(font: Font, glyph: String) -> Dictionary:
    var flat := TextMesh.new()
    flat.font = font
    flat.text = glyph
    flat.font_size = 48
    flat.pixel_size = .04
    flat.curve_step = .5
    flat.depth = 0
    var arrays := flat.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    var bounds := flat.get_aabb()
    assert(not vertices.is_empty() and bounds.size.y > 0, "No vector glyph")
    var points: Array[Vector2] = []
    var ids: Array[int] = []
    var lookup := {}
    for vertex in vertices:
        var p := Vector2(vertex.x - bounds.get_center().x, vertex.y - bounds.get_center().y) / bounds.size.y
        var key := Vector2i(roundi(p.x * 1000000), roundi(p.y * 1000000))
        if not lookup.has(key):
            lookup[key] = points.size()
            points.append(p)
        ids.append(lookup[key])
    var faces: Array[Vector3i] = []
    var edges := {}
    var count := indices.size() if not indices.is_empty() else vertices.size()
    for i in range(0, count, 3):
        var f := Vector3i(ids[indices[i]] if not indices.is_empty() else ids[i],
            ids[indices[i+1]] if not indices.is_empty() else ids[i+1],
            ids[indices[i+2]] if not indices.is_empty() else ids[i+2])
        faces.append(f)
        for e in [Vector2i(f.x, f.y), Vector2i(f.y, f.z), Vector2i(f.z, f.x)]:
            var key := Vector2i(mini(e.x, e.y), maxi(e.x, e.y))
            if edges.has(key):
                edges[key][0] += 1
            else:
                edges[key] = [1, e]
    var boundary: Array[Vector2i] = []
    for entry in edges.values():
        assert(entry[0] <= 2, "Non-manifold source face")
        if entry[0] == 1:
            boundary.append(entry[1])
    return {"glyph": glyph, "points": points, "faces": faces, "boundary": boundary}

static func make(section: Dictionary, frames: Array[Transform3D], loop: bool = false) -> ArrayMesh:
    assert(frames.size() >= 2)
    var points: Array[Vector2] = section.points
    var vertices := PackedVector3Array()
    var normals := PackedVector3Array()
    if not loop:
        for f: Vector3i in section.faces:
            _tri(vertices, normals, _at(points[f.x], frames[-1]), _at(points[f.y], frames[-1]), _at(points[f.z], frames[-1]))
            _tri(vertices, normals, _at(points[f.z], frames[0]), _at(points[f.y], frames[0]), _at(points[f.x], frames[0]))
    # Smooth only side walls. Cap normals remain distinct at the rim.
    var side_start := vertices.size()
    var smooth := {}
    for e: Vector2i in section.boundary:
        for i in range(frames.size() if loop else frames.size()-1):
            var j := (i+1) % frames.size()
            var a := _at(points[e.x], frames[i])
            var b := _at(points[e.y], frames[i])
            var c := _at(points[e.y], frames[j])
            var d := _at(points[e.x], frames[j])
            _tri(vertices, normals, a, b, c)
            _tri(vertices, normals, a, c, d)
    for i in range(side_start, vertices.size(), 3):
        var normal := (vertices[i+2]-vertices[i]).cross(vertices[i+1]-vertices[i])
        for j in 3:
            var key := Vector3i((vertices[i+j]*100000).round())
            smooth[key] = smooth.get(key, Vector3.ZERO) + normal
    for i in range(side_start, vertices.size()):
        normals[i] = (smooth[Vector3i((vertices[i]*100000).round())] as Vector3).normalized()
    var arrays := []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    var mesh := ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mesh.set_meta("glyph", section.glyph)
    mesh.set_meta("loop", loop)
    return mesh

static func _at(point: Vector2, frame: Transform3D) -> Vector3:
    return frame * Vector3(point.x, point.y, 0)

static func _tri(v: PackedVector3Array, n: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
    var normal := (c-a).cross(b-a).normalized() # Godot's clockwise front faces.
    v.append_array(PackedVector3Array([a,b,c]))
    n.append_array(PackedVector3Array([normal,normal,normal]))
```

## Read the construction

`Sweep.profile(FONT, "O")` returns a Dictionary: named entries containing the outline positions, cap triangles and boundary edges. You borrow that record intact. Its inner boundary matters as much as its outside edge.

Each Transform3D is a placement for one copy of that cross-section. The supplied expression uses a uniform WIDTH and the position `at`; it leaves all sections parallel. Transformation will examine the basis more closely. The loop creates five placements from fraction zero to one. DEPTH sets their z travel and OFFSET their total sideways travel. This version shears along a straight route; it does not solve arbitrary curved-path orientation.

`Sweep.make(section, frames)` connects corresponding boundary edges between placements and caps the material at the ends. It preserves the O's opening through those caps. The full helper is printed below as a declared dependency. The student-owned decisions are the chosen glyph, size and route—not a claim to have rebuilt font triangulation.

## Make it your own

Set OFFSET to zero; then give it the opposite sign. Keep the O and WIDTH unchanged. Predict the direction of the passage and verify that the opening survives. Next try C and explain why an open contour changes what you would call the resulting space. Some glyphs have disconnected components; one character need not make one connected solid.

Carry the distinction between a rule you write and a structure you borrow. Portals asks how a finite construction can answer a question about an ideal form.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.

The supplied sweep is copied from `commons/artifacts/glyph_profile_gallery/profile_sweep.gd`; JetBrains Mono is distributed with its OFL licence. Font geometry uses [Godot TextMesh](https://docs.godotengine.org/en/4.6/classes/class_textmesh.html).
