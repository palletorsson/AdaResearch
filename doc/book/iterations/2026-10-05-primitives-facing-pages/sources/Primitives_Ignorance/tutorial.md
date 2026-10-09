# A rule produces positions

## Learning elements

- Functions and typed return values
- Parameters and arguments
- Symmetry as a construction rule
- Independent generated results

## In the museum

Among the Platonic solids, the octahedron offers a compact rule: put a position at each end of three perpendicular axes. Six positions replace a long list of coordinates. The geometry courtyard gives the result a place; this lesson makes its construction available to you.

The hanging black point near the exit previews the next lesson: holding it reduces its rings and segments, and the trigger sends its current form. You can try it here; this tutorial stays with the rule that produces positions. Primitives_Godot returns to the same point to explain its resolution parameters.

In Cube, you wrote the corner positions into a list. Here you write a rule that returns a list for each radius you give it. Arrays, loops and the face renderer return; a named function makes their work reusable. We supply the eight face triples so that the lesson stays with generating positions.

You can still work out every coordinate. What changes is where you make the decision: choose the rule and its input, then inspect the positions they produce. Later generators can produce more than you would want to place one point at a time.

## Make this study

Attach lesson.gd to a Node3D named GeneratorStudy in this museum hall. FaceBody and LineSkin are unchanged. The two calls deliberately use different radii and store their results separately.

Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.

### The program

<!-- student-code:lesson.gd -->
```gdscript
extends Node3D
const FaceBody = preload("face_body.gd")
# Connectivity is supplied; this lesson generates the positions.
const FACES: Array[Vector3i] = [
    Vector3i(2, 0, 4), Vector3i(2, 4, 1),
    Vector3i(2, 1, 5), Vector3i(2, 5, 0),
    Vector3i(3, 4, 0), Vector3i(3, 1, 4),
    Vector3i(3, 5, 1), Vector3i(3, 0, 5)]
var small_points: Array[Vector3] = []
var large_points: Array[Vector3] = []

func _ready() -> void:
    small_points = octahedron_positions(0.3)
    large_points = octahedron_positions(0.6)
    var small := FaceBody.new()
    var large := FaceBody.new()
    small.position = Vector3(-0.7, 1.1, 0)
    large.position = Vector3(0.7, 1.1, 0)
    add_child(small)
    add_child(large)
    small.show_faces(small_points, FACES)
    large.show_faces(large_points, FACES)

func octahedron_positions(radius: float) -> Array[Vector3]:
    assert(radius > 0.0)
    var result: Array[Vector3] = []
    for axis in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
        result.append(axis * radius)
        result.append(-axis * radius)
    return result
```

### Dependency: face_body.gd

<!-- student-code:face_body.gd -->
```gdscript
extends Node3D
## Visible triangular faces and their edges. This class adds no collision.
const LineSkin = preload("line_skin.gd")
var surface := MeshInstance3D.new()
var edges := Node3D.new()

func _init() -> void:
    add_child(surface)
    add_child(edges)
    var paper := StandardMaterial3D.new()
    paper.albedo_color = Color(0.92, 0.91, 0.87)
    paper.roughness = 0.75
    surface.material_override = paper

func show_faces(points: Array[Vector3], faces: Array[Vector3i]) -> bool:
    surface.mesh = null
    for edge in edges.get_children():
        edge.free()
    if faces.is_empty():
        return false
    for face in faces:
        for index in [face.x, face.y, face.z]:
            if index < 0 or index >= points.size():
                return false
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        if (c - a).cross(b - a).length() < 0.00001:
            return false
    var builder := SurfaceTool.new()
    builder.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in faces:
        var a := points[face.x]
        var b := points[face.y]
        var c := points[face.z]
        # Godot's front faces use clockwise winding.
        var normal := (c - a).cross(b - a).normalized()
        for point in [a, b, c]:
            builder.set_normal(normal)
            builder.add_vertex(point)
        for pair in [[a, b], [b, c], [c, a]]:
            var edge := LineSkin.new()
            edge.material_override.albedo_color = Color(0.04, 0.04, 0.045)
            edges.add_child(edge)
            var difference: Vector3 = pair[1] - pair[0]
            edge.show_segment(pair[0], difference, difference.length())
    surface.mesh = builder.commit()
    return true
```

### Dependency: line_skin.gd

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

## Read the construction

`radius` is the function's parameter. The numbers 0.3 and 0.6 are arguments supplied by two calls. `-> Array[Vector3]` names the kind of value returned: a list of positions. The positive-radius assertion states the function's domain.

For each positive axis, the loop appends one position and its opposite. The order is +X, −X, +Y, −Y, +Z, −Z. The supplied face list depends on that order. Rearranging the list without changing the faces would make a different set of connections.

The function builds a fresh `result` on every call and returns it. It does not place a body in the room or draw anything. FaceBody takes the returned data and renders it. This separates generating positions from displaying them without introducing a general-purpose factory.

Changing a returned position changes one result. Changing the rule changes future results. Neither operation makes a claim about which sculpture is better. Radius, geometric relationship and aesthetic judgment are different decisions.

## Make it your own

Call the function with 0.45. Use the returned array to display a third body. Move one entry in that array, redraw only that body, and verify that the other two remain unchanged. Describe the symmetry your edit broke.

Carry the idea of a parameter controlling a construction. In Godot Primitives, return to your original sphere and make two of the engine's construction parameters available while holding it.

## Source and scope

The runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.


[Current lesson.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Primitives_Ignorance/lesson.gd) · [Complete working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)
