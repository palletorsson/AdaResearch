# Point One — give the point a body

Three labels say “Point one”. Above the first, nothing. Above the next two, a white sphere. Walk towards each. Only the last stops your movement.

Point Zero followed when an instruction runs. Here we follow what has to be made for a point to appear and resist us.

In your working Ada project, open `commons/primitives/point/point_condition.gd`. This is the script already used by the corridor’s points. Work in the museum’s **Point One** hall. The excerpts below identify parts of this file; make only the specified edits. After each edit, save and restart the scene.

## A position before a surface

Near the top of the script:

```gdscript
const CENTRE := Vector3(0, 1.12, 0)
```

`Vector3` holds three numbers. Here they locate a position relative to each station. The middle number places it 1.12 metres above that station’s origin. The next hall will examine the three directions and their reference frame.

`CENTRE` names this value. `const` makes it a constant: the script cannot reassign it while running. You can edit its starting value and run again. `:=` lets Godot infer its type from that value: here, `Vector3`.

Change `1.12` to `1.7`. The small white spheres rise. The first station remains empty: its code finishes after creating the label. A position does not draw a surface by itself. Restore `1.12`.

The large sphere on the final pedestal stays where it is. The same script gives that condition a separate centre and radius. We will leave its arrangement in place.

## A surface at that position

Further down, the script creates the visible sphere:

```gdscript
var sphere := SphereMesh.new()
sphere.radius = radius
sphere.height = radius * 2.0
```

`var` declares a variable. `sphere` keeps a reference to the object made by `.new()`. `SphereMesh` is a resource: it holds the surface data that a scene node can display.

The station setup has already chosen a value for `radius` and a position called `centre`. For the small spheres these come from `RADIUS` and `CENTRE` near the top of the file. A radius measures from centre to surface; `* 2.0` makes the sphere’s full height twice that distance.

Look around these assignments in `_ready()`:

```gdscript
var body := MeshInstance3D.new()
```

```gdscript
body.mesh = sphere
```

```gdscript
body.position = centre
add_child(body)
```

`MeshInstance3D` displays the mesh. The dot selects a property of that node: its mesh, then its position. `add_child(body)` adds the new node beneath this station in the scene tree. The script creates both resource and node; it does not fetch a hidden sphere from a scene file.

Change `const RADIUS := 0.14` to `const RADIUS := 0.3`. Both small spheres grow around their unchanged centres. Walk towards the first white sphere. You can still cross its surface. Restore `0.14`.

## A boundary made separately

Find the part that creates `PointCollision`. It runs for the solid and pedestal conditions. These are its construction lines, with the naming and collision-layer setting left out:

```gdscript
var solid := StaticBody3D.new()
solid.position = centre
var collider := CollisionShape3D.new()
var sphere_shape := SphereShape3D.new()
sphere_shape.radius = radius
collider.shape = sphere_shape
solid.add_child(collider)
add_child(solid)
```

`StaticBody3D` is a fixed physics body. `SphereShape3D` describes its boundary; `CollisionShape3D` attaches that shape to the body. These lines draw nothing. The visible surface was made above them.

Both constructions use `centre` and `radius`, so their positions and sizes agree.

Change only `sphere_shape.radius = radius` to `sphere_shape.radius = radius * 2.0`. The small solid sphere looks unchanged, but your movement stops farther away. Its invisible radius has doubled. Your player has a width too, so the stopping distance depends on both bodies. The pedestal sphere’s boundary doubles too: this part of the shared script serves both.

Restore the line. Now change `RADIUS` to `0.3` again. The small solid sphere’s surface and boundary grow together because both use that value. Restore `0.14` when finished.

## The light remains another condition

Use the wall switch. The long shadows disappear; the solid sphere still stops your movement. The light is another existing artifact, and its code can wait. We have enough here to distinguish a position, a visible surface and a physical boundary.

In Point Coordinates, the point can move with your hand. We will follow the position as it changes.
