# Point One — follow the point

Point Zero let us recognise an instruction that begins, and one that continues. Now we follow the corridor. Each label says “Point one”, but something different happens above it.

The [supplied study](../../../doc/book/studies/point-one/README.md) lets us inspect the first three conditions together: an absent point, a visible sphere and a solid sphere. Its three scripts are already complete. We will change a few lines as we encounter what they do. The black point and the wider room continue in the museum.

## At the first label, nothing appears

There is a place to look, but no visible object. A mathematical point has a position and no extent. How can we keep its position before giving it a surface?

Open `position.gd`. This is the whole script:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)
```

We know `_ready()` from Point Zero; `-> void` says it returns no value. Here it keeps a different kind of value: a `Vector3`, containing three numbers. Used as a position, these numbers are X, Y and Z coordinates relative to an origin.

For this station, they mean no shift along X, 1.12 metres up Y, and no shift along Z. We name that value `point_position`. Change `1.12` to `1.7` and run. Nothing appears. We have changed a value without attaching any visible body to it. The editor's unused-variable warning describes that condition.

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

## At the fourth label, the point can leave

The sphere is black. Take hold of it in the museum. It follows your hand while “Point one” stays at the station.

Its small size is familiar. Its new behavior comes from the supplied pickup system. A position alone could not make it follow a hand, just as a visible sphere alone could not stop a body.

Here we borrow the working interaction. The desktop study contains the first three comparisons; it does not contain a simulated hand or the museum's pickup system. We do not need to write that system before recognising the relation it adds.

Keep the black point and carry it into the next room. Now the coordinates have something moving to describe.

## The corridor opens into coordinates

Move the point up, sideways and towards you. Watch the guides separate that gesture into X, Y and Z. The point we held at a station now has an address that changes.

For a desktop comparison, open the supplied `coordinates.tscn` and use Run Current Scene, introduced in Day Zero. Its `points.gd` places two prepared sphere markers. Begin with the position named `a`: change one coordinate at a time and watch marker A. The red guide marks X, green Y and blue Z. The guides help us read the movement; constructing the arrows is outside this lesson.

The museum's WORLD and LOCAL cards describe the same held point from different references. Rounded numbers can remain still through a small movement. We can notice those limits without writing the reporting system here.

A point needs coordinates to be located in this scene. The coordinates need a reference to be understood. Neither tells us whether its visible body will resist or follow a hand.

## Carry it to “here”

The target asks for the point. Carry it into the marked place and watch the balls fall. Leave and return.

“Here” allows a little room. The target supplies a distance test and remembers whether the point has already entered. We keep this as an encounter for now. Its machinery will not become another task before we have finished learning the point.

## Before leaving, the point is larger than your hand

A sphere stands on a pedestal, still called “Point one”. Its centre can be described in the same way as the small sphere's. Its size changes what we can do around it.

Return to the radius change we made earlier. That choice gave a position more visible space without changing its address. Here the room lets us feel how far that choice can go.

We have followed a position through absence, surface, resistance and holding, then read it through coordinates. We have changed the point's position, its visible radius and its physical boundary without having to construct every system attached to it.

The prepared two-marker study keeps positions `a` and `b` for the next lesson. Change B while leaving A in place. Point Lines will begin by connecting them. We reach that relation after meeting what each point has been given.
