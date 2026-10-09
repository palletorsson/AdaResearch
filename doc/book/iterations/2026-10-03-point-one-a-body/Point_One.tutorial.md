# Point One — give the point a body

Three labels say “Point one”. Above the first, nothing. Above the next two, a white sphere. Walk towards each. Only the last stops your movement.

We will construct these differences. Point Zero gave us `_ready()`, variables and a way to add a node. Here a variable will keep a position; then we will give that position a surface and a collision boundary.

Open `point_one.tscn` in the [Ada student starter](../../../doc/book/studies/ada-xr-starter/README.md). Use **Run Current Scene** (F6). The room, light and player are the Day Zero setup. The three scripts below are in `studies/point_one/`. Their station nodes and labels are supplied; each script creates everything it needs for its point.

## 1. Keep a position

Open `position.gd`:

```gdscript
extends Node3D

var point_position := Vector3(0.0, 1.12, 0.0)
```

`var` declares a variable. Its name, `point_position`, lets us refer to the value it holds. `:=` gives it a starting value and lets Godot infer the type.

Here the type is `Vector3`: three numbers kept together. We use them as a position relative to this station. The middle number gives its height. Coordinates will examine the three directions in the next hall.

Change `1.12` to `1.7`. Run the scene. Nothing appears above the first label. A stored position draws nothing. Restore `1.12`.

## 2. Give it a surface

Open `visible.gd`:

```gdscript
extends Node3D

var point_position := Vector3(0.0, 1.12, 0.0)
var radius := 0.14

func _ready():
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0

    var marker := MeshInstance3D.new()
    marker.mesh = sphere
    marker.position = point_position
    add_child(marker)
```

`radius` holds a decimal number, a `float`. It measures from the sphere's centre to its surface. `*` multiplies: the full height is twice the radius.

`SphereMesh` is a resource describing the surface. A resource holds data a node can use. `MeshInstance3D` is the node that displays this mesh. `.new()` creates each one. The assignments give `marker` its mesh and position; `add_child(marker)` puts it in the station's scene tree.

Change `radius` to `0.3`. The sphere grows around the same position. Walk through it. A surface can hide part of the room without stopping your movement. Restore `0.14`.

Now change the height in `point_position` to `1.7`. This time something rises: `marker.position` uses the value we stored. Restore `1.12`.

## 3. Give it a boundary

Open `solid.gd`. It contains the same construction, followed by these lines inside `_ready()`:

```gdscript
    var solid := StaticBody3D.new()
    solid.position = point_position

    var sphere_shape := SphereShape3D.new()
    sphere_shape.radius = radius
    var collider := CollisionShape3D.new()
    collider.shape = sphere_shape

    solid.add_child(collider)
    add_child(solid)
```

`StaticBody3D` supplies a physics body that stays in place. `SphereShape3D` describes its collision shape. `CollisionShape3D` attaches that shape to the body. It draws no visible surface.

The marker and the physics body use the same position. Their two shapes use the same radius. Walk towards this sphere: the supplied player's collision body now meets a boundary.

Change `sphere_shape.radius = radius` to `sphere_shape.radius = 0.5`. The visible sphere stays small. Your movement stops farther away. In this version, some empty space has become impassable.

Restore `sphere_shape.radius = radius`. Then change `radius` to `0.3`: both surface and boundary grow because both read that variable.

## Make them disagree

Keep the visible radius at `0.3`, but give `sphere_shape.radius` the value `0.07`. The surface now extends beyond its collision boundary. You can approach closer than the visible edge suggests. The supplied player has a width too; contact depends on both bodies.

Restore the matching `0.14` values when finished. You can now make a marker, resize its surface and decide how its boundary relates to what we see.

The lesson uses the prepared light. The museum's wall switch lets us remove one light source while the solid point still blocks movement. Illumination is another condition; it does not create the collision shape.

The next hall, Point Coordinates, begins with a point we can hold. We will follow the changing position and learn to read its reference frame.
