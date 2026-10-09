# Cube — the diagonal was already there

A cube has six square faces. Our mesh draws them with twelve triangles. Move one corner and the difference becomes visible.

Open `point_cube.tscn` in the [Ada student starter](../../README.md), using **Run Current Scene** (F6). Edit `studies/point_cube/cube.gd`.

Polyhedra separated positions from connections. We reuse that construction with eight specified positions, rather than selecting them from the saved trace. No recording is needed here; your earlier trace remains available.

## 1. Read the corners

`positions` contains eight `Vector3` values. Corners `0`–`3` form the back square at Z = −0.5. Corners `4`–`7` form the front square at Z = 0.5. Each side is one metre long.

The same PointHandle and Segment components draw the corners and edges. Number labels remain readable through the faces. Find `4`, `5`, `6` and `7` on the front square.

The first two rows of `faces` are:

```gdscript
    [4, 5, 7], [5, 6, 7],
```

Both triangles use `5` and `7`. The amber line marks this shared **diagonal**: an edge across the square between opposite corners. The first triangle is off-white; the second is pink so we can follow it.

## 2. Move only corner 6

Hold corner `6` and pull it a little towards you, out of the front square's plane. Use aim and E on desktop, or near grip in VR. Leave `4`, `5` and `7` where they are.

The white triangle stays fixed. The pink triangle tilts. Their shared diagonal becomes a crease.

Each frame, the script copies the handle positions back into the list:

```gdscript
    for i in range(handles.size()):
        positions[i] = handles[i].position
```

The face-building loop then reads those positions through the unchanged index rows. Only the second front triangle refers to `6`. Other triangles around that corner move too; follow its neighbours around the top and right side.

Release the corner. It stays where you left it. Restarting the scene restores the authored positions. Holding and moving a corner has edited the mesh, not translated or rotated the whole object.

For a repeatable change, set this variable to `0.35`:

```gdscript
var corner_shift := 0.0
```

At startup, the script applies it to corner `6`:

```gdscript
    positions[6].z += corner_shift
```

Run again. The same corner starts 0.35 metres farther along positive Z. Set `corner_shift` back to `0.0` to restore the cube.

## 3. Choose the other diagonal

First use `corner_shift = 0.0`. Replace the two front rows with:

```gdscript
    [4, 5, 6], [4, 6, 7],
```

Change `diagonal_pair` from `[5, 7]` to `[4, 6]` so the amber guide follows the new shared edge. Run again. Two triangles still cover the same flat square.

Now set `corner_shift` to `0.35`. Both front triangles contain `6`, so both tilt. The four corner positions match the previous deformed example, but the crease follows another connection. Changing the triangulation has changed the surface between them.

Restore the original rows, `[5, 7]` and `corner_shift = 0.0` when finished.

## What remains a cube?

Set `show_diagonal` to `false`. The guide disappears; the two triangles remain. Set `show_faces` to `false` to keep just the corner handles and twelve boundary edges. Restore both to `true`.

The initial shape has six geometric square faces. The `faces` list contains twelve rendering triangles. Counting those rows does not prove that the edited result still has equal edges, right angles or flat squares.

The colours and amber guide are supplied display aids. Both sides of each triangle are visible. This study gives the surface no thickness or collider; the handles have pickup colliders. The museum adds replay, folding nets and the prefab collection as separate encounters.

We have used a position list, a connection list and a loop to construct a familiar body. In the next hall, we can ask how a short rule might generate some of that data for us.
