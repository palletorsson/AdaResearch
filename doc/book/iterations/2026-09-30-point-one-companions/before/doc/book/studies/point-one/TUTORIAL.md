# Point One — give the point a body

Point Zero let us recognise an instruction that begins, and one that continues. Now we follow the corridor. Each label says “Point one”, but something different happens above it.

The [supplied study](README.md) lets us inspect the first three conditions together: an absent point, a visible sphere and a solid sphere. Its three scripts are already complete. We will change a few lines as we encounter what they do. The held point and coordinate frame have their own next chapter, Point Coordinates.

## At the first label, nothing appears

There is a place to look, but no visible object. A mathematical point has a position and no extent. How can we keep its position before giving it a surface?

Open `position.gd`. This is the whole script:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)
```

We know `_ready()` from Point Zero; `-> void` says it returns no value. Here it keeps a different kind of value: a `Vector3`, containing three numbers. For now, this is the supplied position at our station. Point Coordinates will make its three components the subject of a lesson.

We name that value `point_position`. The middle number places it above the floor. Change `1.12` to `1.7` and run. Nothing appears. We have changed a value without attaching any visible body to it. The editor's unused-variable warning describes that condition.

The other stations in the study still show their spheres. This change belongs only to the empty station. Restore `1.12` before continuing.

## Further along, the point has a surface

The next label has a small white sphere above it. Its centre gives our eyes a place to find.

Open `visible.gd`. The same position is there, now used by a visible object:

```gdscript
visible_point.position = point_position
```

This line is already inside `_ready()`. `visible_point` names the mesh node created by the supplied script; assigning its `position` puts its centre at our coordinates. We have given the point a body through which it can appear.

Change `1.12` to `1.7` in this script. This time the white sphere rises. Restore the height, then change the radius:

```gdscript
var radius := 0.14
```

Try `0.3`. The sphere becomes larger while its centre stays where it was. The supplied `SphereMesh` uses this radius and a height twice as large. We can inspect its construction later; for now, we can change a position and a surface separately.

In the museum, try crossing that surface. It is visible, but it does not stop you. Restore the radius to `0.14` before meeting the next sphere.

## The next point stops us

The next white sphere looks the same. In the museum, approaching it produces a different result: a body meets resistance.

Open `solid.gd`. It keeps the visible construction and adds a separate physics body and collision shape. Both are placed at `point_position`. The boundary's size is set here:

```gdscript
sphere_shape.radius = radius
```

Change only that line to:

```gdscript
sphere_shape.radius = 0.35
```

The visible sphere stays small. Its collision boundary grows. In the desktop study, turn on **Debug → Visible Collision Shapes** to see the boundary; the fixed camera does not let you walk into it. In the museum, the distinction is something your movement meets.

We have chosen whether the surface we see and the boundary we encounter coincide. The full physics construction is supplied; changing this one relation already gives us something consequential to author. Restore the matching radius.

## Remove the light, keep the body

Use the museum's wall switch. The long shadows disappear, while a dim fill leaves the spheres visible. The collision boundary stays where it was.

The decision in the switch is one line:

```gdscript
sun.visible = false
```

Here `sun` is the supplied directional light. This is a reading of the museum source, not a line to paste into `visible.gd`, which has no variable named `sun`. We borrow the switch and lighting rig for this encounter. Building shadows is not another task hidden inside learning the point.

## Before leaving

The large sphere repeats the same name. Return to the radius we changed: giving a position more surface did not require a new kind of position.

We can now change appearance and resistance separately. [Point Coordinates](../point-coordinates/TUTORIAL.md) begins with a point we can hold, then reads its movement. It will prepare two positions for the line.
