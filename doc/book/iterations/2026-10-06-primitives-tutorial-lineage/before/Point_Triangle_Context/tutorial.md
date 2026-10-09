# Triangle — three corners, then a face

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Corners and edges
- Closed boundaries
- Triangular faces
- Vertex order

Your trace has already become a grid drawing. Now choose three of its stored positions. Join them into a closed boundary. Then give that boundary a visible face.

Open `point_triangle.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md), using **Run Current Scene** (F6). Edit `studies/point_triangle/triangle.gd`. If the room asks for a trace, draw a bend in `point_trace.tscn` and release to save it first.

The lesson reuses Trace's original record, as Grid did. It does not read Grid's rounded display or replace your gesture with an example. `PointHandle`, `Segment` and `TraceMemory` are the supplied components we already use. The room and two appearance materials are supplied too.

## 1. Choose three positions

The script reads the saved list into `source_points`. With at least three entries, it selects these:

```gdscript
    var third := source_points.size() / 3
    a.position = source_points[0]
    b.position = source_points[third]
    c.position = source_points[third * 2]
```

Both values in the division are integers, so the result is an integer: any fractional part is discarded. With ten entries, `third` is `3`. We select entries `0`, `3` and `6`.

These are three places in the list, not three equal distances along the drawing. The rule does not recognise corners. Each selected `Vector3` becomes the position of a new grabbable handle. Moving a handle changes that copy; the saved trace stays intact.

## 2. Close the boundary

Each frame, reuse Lines' `show_between()`:

```gdscript
    ab.show_between(a.position, b.position)
    bc.show_between(b.position, c.position)
    ca.show_between(c.position, a.position)
```

The third segment returns from C to A. Hold a pink corner and move it. The two segments meeting there follow. On desktop, aim and press E; in VR, use the near grip.

Look through the centre. The boundary is closed, but we have made no face. If your selected positions lie along one line, move a corner away from it.

## 3. Add the face

Point One used `SphereMesh` to supply a surface. Here we specify its vertices ourselves. A **vertex** is a position used to construct a mesh.

```gdscript
var face_mesh := ImmediateMesh.new()
var face := MeshInstance3D.new()
```

`ImmediateMesh` is a mesh resource we can build by adding vertices. `MeshInstance3D` displays it. The script assigns `face_mesh` to `face.mesh` and adds the node to the room.

Change `show_face` from `false` to `true` and run again. These lines now execute each frame:

```gdscript
    face_mesh.clear_surfaces()
    if show_face:
        face_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
        face_mesh.surface_add_vertex(a.position)
        face_mesh.surface_add_vertex(b.position)
        face_mesh.surface_add_vertex(c.position)
        face_mesh.surface_end()
```

`clear_surfaces()` removes the previous mesh surfaces. `surface_begin()` starts a surface; `Mesh.PRIMITIVE_TRIANGLES` tells Godot to interpret each group of three vertices as a triangle. We add our three positions, then `surface_end()` finishes it.

The face and segments read the same corners. Hold one again: both follow. Setting `show_face` back to `false` leaves the boundary available without the face.

## 4. Change the view, then the shape

Leave the corners still and walk towards an edge-on view. The visible face narrows. Walk back: it returns.

Now move one corner onto the line between the other two. The triangle has zero area. Another viewpoint cannot recover it; move the corner away to open the face again.

The supplied off-white material shows both sides without lighting variation, so this comparison does not depend on a dark back or back-face culling. It adds neither thickness nor collision. The handles have colliders; the face does not.

Three non-collinear positions define one triangular face. They do not fill the whole trace we selected them from. Longer outlines need another decision about how to connect their corners.

Next, Polyhedra asks how these faces can meet to enclose a volume.
