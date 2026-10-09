# Polyhedra — which faces make an inside?

**Learning elements — proposed focus**

*The labels below set the revision focus; the existing lesson still needs alignment.*

- Shared vertices
- Face indices
- Nested traversal
- Enclosure

Three faces meet at one point. Look into the opening opposite it. What would close this little room?

Open `point_polyhedra.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md), using **Run Current Scene** (F6). Edit `studies/point_polyhedra/polyhedra.gd`.

The script reads the same saved trace as Triangle and selects the same three original positions. Edits to Triangle's handles were temporary; they did not change that record. If no record is available, draw a bend in Trace and release to save it first.

We reuse the handles, segments and face material. The new construction separates **where vertices are** from **which vertices a face connects**.

## 1. Add a fourth position

The three selected positions are `a`, `b` and `c`. The script adds them and divides by three to find their centre:

```gdscript
    var centre := (a + b + c) / 3.0
    positions = [centre + Vector3(0.0, 0.0, -0.7), a, b, c]
```

`positions` is an `Array[Vector3]`. Entry `0` is the new point, placed 0.7 metres along negative Z from that centre. Entries `1`, `2` and `3` keep the earlier corners. The saved trace is unchanged.

Four pink handles carry these numbers. Their labels stay readable through the faces. Hold one and move it. We chose a depth direction in the room, not a direction calculated from your triangle. If all four points lie in one plane, move point `0` out of it. If the three earlier corners lie along one line, separate one as you did in Triangle.

## 2. Keep connections in a list

```gdscript
var faces := [
    [0, 1, 2],
    [0, 2, 3],
    [0, 3, 1],
]
```

`faces` is an array containing three smaller arrays. Each row gives three **indices into `positions`**. The numbers refer to vertices; they are not coordinates.

Read the first row: connect position `0`, then `1`, then `2`. Follow that triangle on the object. All three rows include `0`, so all three faces meet there. None joins `1`, `2` and `3` across the opening.

## 3. Reuse the triangle operation

Triangle submitted three positions directly. This version reads them from the face list:

```gdscript
        face_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
        for triangle in faces:
            for index in triangle:
                face_mesh.surface_add_vertex(positions[index])
        face_mesh.surface_end()
```

The outer `for` loop takes one face row. The inner loop takes each index in that row and adds its position to the mesh. It completes those three vertices before the outer loop takes the next face.

This is a **nested loop**: one loop runs inside another. Three rows submit nine vertices. Some positions are submitted more than once because neighbouring faces share corners.

As before, the script clears the old surface each frame. Before rebuilding, it copies the current handle positions into `positions`. Moving a corner changes every face that refers to its index. The face list stays the same.

## 4. Close the opening

Add one row to `faces`:

```gdscript
    [1, 3, 2],
```

Keep the comma and place the row before the array's closing `]`. Run again. The four positions remain where they started; the new row adds a face across the opening.

With four non-coplanar positions, these four faces enclose a **tetrahedron**. Non-coplanar means the positions do not all lie in one plane. Its edges need not have equal lengths; equal edges would make it regular.

Remove the row and run again. You recover the opening without deleting any position. In code, a hole can be an omitted connection.

## Keep two boundaries distinct

The mesh displays a surface. It adds no collision or material filling the interior. Only the small handles have colliders for pickup.

The museum's open trihedron makes a different choice: its convex collision hull closes the missing side even while the rendering leaves it open. The museum's barriers and slopes extend that investigation to the moving body.

For now, you can change a surface by moving its vertices or by changing its face list. The next hall carries those two decisions into a cube.
