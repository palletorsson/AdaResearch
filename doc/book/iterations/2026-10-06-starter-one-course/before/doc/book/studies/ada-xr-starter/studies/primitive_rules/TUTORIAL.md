# Primitives — a rule for positions

An octahedron has six corners: two on each axis, equally far from its centre. We can use that regularity to generate its positions.

Open `primitive_rules.tscn` in the [Ada student starter](../../README.md). The left study is the octahedron; the right is a sphere with its triangle edges exposed. Both use the same room and player as Cube.

## 1. Give a rule a name

Open `studies/primitive_rules/octahedron.gd`. Find this function:

```gdscript
func octahedron_positions(radius: float) -> Array[Vector3]:
    var directions: Array[Vector3] = [
        Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1),
    ]
    var points: Array[Vector3] = []
    for direction in directions:
        points.append(direction * radius)
        points.append(-direction * radius)
    return points
```

The three directions point along positive X, Y and Z. The loop scales each by `radius`, then adds its opposite. The minus sign reverses the direction. Six positions enter the list in order: +X, −X, +Y, −Y, +Z, −Z.

`radius` is a **parameter**: a named input to the function. Here it means the distance from the centre to a corner. Use a positive value. `float` declares a number that can have a fractional part. `-> Array[Vector3]` declares the result: a list of positions. `return points` sends that list back to the code that called the function.

The function calculates coordinates around `(0, 0, 0)`. It creates no visible object. The scene places this whole study above the floor, to your left.

## 2. Call it with another value

In `_ready()`, the script asks for the positions:

```gdscript
    positions = octahedron_positions(0.55)
```

`0.55` is the **argument**, the value passed into `radius` for this call. The returned list becomes `positions`.

Godot calls `_ready()` when the node is ready. Our new function runs because we call it there. It is not another automatic callback.

Change `0.55` to `0.75` and run again. All six corners move farther from the centre. Their opposite pairing and equal distances remain. The edge length changes too: this radius measures centre to corner, not corner to corner.

The existing face list connects these positions into eight triangles. Its indices were supplied separately; the function does not discover which corners belong to a face. We reuse Cube's handles, segments and nested face-building loop.

## 3. Move outside the rule

Restore `0.55` and run again. Hold one numbered corner and move it sideways. Use aim and E on desktop, or near grip in VR.

The neighbouring triangles follow. The result still has the same connections, but it is no longer a regular octahedron. The generated list was a starting arrangement, not a constraint on your hand.

`_process()` reads the edited handle positions each frame. It does not call the generator again. Restarting runs `_ready()` and restores the rule's result; temporary edits are not saved.

## 4. Return to the sphere

In Point One, SphereMesh gave a point a visible body. Open `studies/primitive_rules/sphere.gd`:

```gdscript
    sphere_mesh.radius = 0.55
    sphere_mesh.height = 1.1
    sphere_mesh.radial_segments = 8
    sphere_mesh.rings = 4
```

Radius and full height set the dimensions. `radial_segments` divides the turn around the vertical axis; `rings` controls subdivisions along the height.

Change only `radial_segments` to `16` and run again. Follow the additional edges around the sphere. Restore `8`, then change only `rings` to `8`. The subdivision changes in the other direction. The radius and height settings stay fixed in both trials.

SphereMesh generates its own positions and connections. The supplied MeshEdges guide reads that resulting mesh and draws its edges; it does not make a different sphere. The guide and numbered handles are teaching aids. Neither study's surface has a collider.

The museum's pillars, sphere comparisons and capsule extend this investigation. Here we have gained one reusable operation: a function that takes a value and returns data. A short rule can produce a body; its output remains something we can inspect and alter.

Continue with [One column — an outline made of numbers](../primitive_column/TUTORIAL.md). Use the same list, loop and function to separate a profile, its full height and the number of sides. Then carry the question of resolution into Portals.
