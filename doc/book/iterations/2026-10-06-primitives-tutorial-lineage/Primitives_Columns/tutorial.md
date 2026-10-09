# One profile, several resolutions

## Learning elements

- A profile as a radius list
- Nested loops over rings and sides
- Independent height and resolution
- Comparing one variable at a time

## In the museum

The colonnade varies outlines, heights and resolution. Begin with a controlled row: the same profile and height at 4, 6, 8, 12 and 16 sides. Once you can identify what resolution changes, give the columns different silhouettes.

The octahedron lesson generated positions with a function. Here another function generates a stack of rings. Circle sampling and the surface stitcher are supplied below so that the new work stays with the profile, the two loops and their indexing.

## Make this study

Attach lesson.gd to a Node3D named ColumnStudy in this hall's working copy. Allow roughly five metres for the row. The program creates its own meshes and pale material. Keep positive radii, at least two profile entries, a positive height and at least three sides. For the first variations stay near the displayed dimensions; more samples consume more memory and drawing work.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const Circle = preload("circle_samples.gd")
const ColumnSurface = preload("column_surface.gd")
const PROFILE: Array[float] = [0.35, 0.35, 0.18, 0.25, 0.4, 0.4]
const HEIGHT := 2.2

func _ready() -> void:
    var choices := [4, 6, 8, 12, 16]
    for i in range(choices.size()):
        var column := MeshInstance3D.new()
        var points := column_positions(PROFILE, HEIGHT, choices[i])
        column.mesh = ColumnSurface.make(points, choices[i])
        column.position.x = (i - 2) * 1.0
        var finish := StandardMaterial3D.new()
        finish.albedo_color = Color(0.92, 0.91, 0.87)
        finish.roughness = 0.7
        column.material_override = finish
        add_child(column)

func column_positions(profile: Array[float], height: float, sides: int) -> Array[Vector3]:
    assert(profile.size() >= 2 and height > 0.0 and sides >= 3)
    var result: Array[Vector3] = []
    for ring in range(profile.size()):
        var y := height * ring / (profile.size() - 1)
        for point in Circle.make(sides, profile[ring]):
            result.append(point + Vector3(0, y, 0))
    return result
```

### Dependency: circle_samples.gd

<!-- student-code:circle_samples.gd -->
```gdscript
extends RefCounted
# Supplied circle sampler. Angles return in the Waves sequence.
static func make(sides: int, radius: float) -> Array[Vector3]:
    assert(sides >= 3 and radius > 0.0)
    var points: Array[Vector3] = []
    for side in range(sides):
        var angle := TAU * side / sides
        points.append(Vector3(cos(angle), 0, sin(angle)) * radius)
    return points
```

### Dependency: column_surface.gd

<!-- student-code:column_surface.gd -->
```gdscript
extends RefCounted
## Supplied renderer. Consecutive rings have the same number and order of samples.
## It joins neighbours, closes the seam, and adds two planar caps. No collider.

static func make(points: Array[Vector3], sides: int) -> ArrayMesh:
    assert(sides >= 3 and points.size() >= 2 * sides and points.size() % sides == 0)
    var rings: int = points.size() / sides
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for ring in range(rings - 1):
        for side in range(sides):
            var next := (side + 1) % sides
            var a := points[ring * sides + side]
            var b := points[(ring + 1) * sides + side]
            var c := points[ring * sides + next]
            var d := points[(ring + 1) * sides + next]
            triangle(builder, a, b, c)
            triangle(builder, c, b, d)
    var bottom := Vector3(0, points[0].y, 0)
    var top := Vector3(0, points[-1].y, 0)
    var last := (rings - 1) * sides
    for side in range(sides):
        var next := (side + 1) % sides
        triangle(builder, bottom, points[side], points[next])
        triangle(builder, top, points[last + next], points[last + side])
    return builder.commit()

static func triangle(builder: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
    # Outward normal from the ordered construction; Godot front faces are clockwise.
    var normal := (b - a).cross(c - a).normalized()
    for point in [a, c, b]:
        builder.set_normal(normal)
        builder.add_vertex(point)
```

## Read the construction

PROFILE stores a radius for each height level. Its entries are spaced evenly from the bottom to the full HEIGHT. The outer loop visits a level; the inner loop visits positions around that level's circle. A profile of six entries at eight sides produces 48 positions.

`height * ring / (profile.size() - 1)` places the last ring exactly at the requested height. Circle.make supplies a ring in the x–z plane. Adding `(0, y, 0)` lifts it to the current level. Its cosine and sine are borrowed circle coordinates here; periodic motion returns to their meaning in Waves.

ColumnSurface joins neighbouring rings, closes the last side to the first, and caps both ends. The side order must match at every ring. It connects samples with straight faces, so this small construction has piecewise straight profiles rather than the museum gallery's more elaborate curves. It adds no collision.

Changing sides changes angular sampling. Changing PROFILE changes the silhouette. Changing HEIGHT stretches the spacing between its levels. A higher resolution is not a better proportion or a more interesting sculpture.

## Make it your own

Keep eight sides and make a new positive-radius profile. Then keep that profile and change only its height. Finally use it for all five resolutions. Explain which differences come from your rule and which come from sampling it.

Carry the profile-and-path distinction into the next hall, where the cross-section is borrowed from a letter rather than written as a radius list.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.

