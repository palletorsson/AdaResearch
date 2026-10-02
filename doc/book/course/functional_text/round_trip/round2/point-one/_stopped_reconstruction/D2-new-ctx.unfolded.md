# Point One — give the point a body

*Unfolded by a blind reader at the start of Point One, from the compressed lesson L2v2 plus the
earlier content (Day Zero, Point Zero, and the course's list of types). Passages that fill a gap
the compressed text did not carry start with [guess].*

## What you bring with you

From Day Zero you have a project that runs. You can open a scene, change a value, save, run it,
stop it, and come back. You also know that some parts of the course are *supplied*: made for you
and used before anyone teaches you how they work, like the camera and the light in the base
scene. Using them is not cheating. Naming them keeps them from disappearing.

From Point Zero you have your first script. You know that `extends Node3D` says the script is for
a 3D node, that `func` starts a named block of code, that the indented lines under it belong to
it, and that `_ready()` runs once, when the node has arrived in the scene. You know `var` makes a
variable, `:=` lets Godot work out its type from the value you give it, and `=` sets the left side
to the value on the right. You also met the dot: `$Greeting.text = "Hello, world."` reached a
node and set one of its properties.

In Point Zero, `_ready()` greeted. In Point One, `_ready()` places a marker: a small sphere that
stands for a point. The lesson asks one question three times: what does it take for a point to be
there at all, for it to be seen, and for it to be met?

## Open the study and run it

Open the Point One study (its README is in the course's `studies/point-one/` folder), then open
`study.tscn`.

The root node of this scene is called `PointStudy`. Under it are three *stations*. A station is
one small set-up in the row, and each one has its own script and its own *label* reading "Point
one":

| station | script | what it does |
|---|---|---|
| `Position` | `position.gd` | holds a position and nothing else |
| `Visible` | `visible.gd` | holds a position and shows a sphere there |
| `Solid` | `solid.gd` | shows a sphere and gives it something that can be touched |

[guess] A station is most likely a `Node3D` child of `PointStudy`, standing at its own place in
the row, and the label is a supplied text node (probably a `Label3D`) placed above it. The lesson
only says each station has a script and a label.

Run the scene. [guess] Because `study.tscn` may not be the project's main scene, use **Run
Current Scene** (F6) rather than Run Project (F5); Day Zero taught both.

Here is what you should see:

- Above the first label, nothing.
- Above the second and third labels, a small white sphere each. They look the same.
- Three pink *feelers* move from left to right, one past each station.
- The first two feelers pass straight through. The third stops when it reaches the solid sphere.
- The sweep starts over again and again. **Space** pauses it, **R** restarts it.

The feelers are not your code. Their contact test lives in a supplied script, `contact_probe.gd`,
and you borrow it the way you borrow the camera. [guess] A feeler is probably a small moving body
or ray that asks the physics engine "am I touching anything solid?" every frame and stops when the
answer is yes. You never edit it in this lesson.

What you will change is what a feeler is able to cross.

## Station one — Position: nothing shows

Open `position.gd`. This is the whole script:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)
```

Two things are new.

**`-> void`.** [guess] The arrow after the brackets says what the function hands back when it
finishes. `void` means it hands back nothing. `_ready()` only does work; it does not answer with a
value. Point Zero wrote `func _ready():` without the arrow, and that also runs. The arrow is a
note to you and to Godot, not a change in what happens.

**`Vector3`.** A `Vector3` is three numbers held together as one value. Here the variable
`point_position` holds a `Vector3`, and that `Vector3` is a *position*: where something stands.
The position is supplied; you did not choose these numbers.

What each of the three numbers means is left for later. The next hall, Point Coordinates, opens
them. [guess] The course's list of types already says the three are x (how far right), y (how far
up) and z (how far toward you), counted in metres from the origin, so `1.12` is likely a height of
a little over a metre. You can test that guess in the next section.

### Try it

Change `1.12` to `1.7`. Save and run.

Still nothing appears above the first label. There is no visible *body* here: no node has been
placed at this position. A variable is just a value kept for the length of the function; it
draws nothing.

The editor notices this. It shows an **unused-variable warning**: you made `point_position` and
never used it. [guess] The warning appears in the script editor, at the bottom of the window,
with wording close to "The local variable 'point_position' is declared but never used." The
warning is the editor telling you the same thing the empty space tells you.

Watch the first feeler. It still crosses. The contact test is supplied, and it does not look at
your position at all. A number stored in a variable is not something a feeler can meet.

Restore: change `1.7` back to `1.12`.

So a position by itself shows nothing and stops nothing. Next, give it something to show.

## Station two — Visible: a mesh shows it

Open `visible.gd`. This is the whole script:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)

    var radius := 0.14
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0

    var marker := MeshInstance3D.new()
    marker.mesh = sphere
    marker.position = point_position
    add_child(marker)
```

Read it in three groups.

**The same position.** The first line is the one from `position.gd`. This time it gets used.

**The sphere.** `radius` is a number, 0.14. [guess] That is 14 centimetres if the unit is the
metre, so the sphere is 28 centimetres across.

`SphereMesh.new()` makes a new sphere. [guess] `.new()` is how you make a fresh object of a kind
Godot already knows. The object exists in memory, but nothing is in the scene yet.

A *mesh* is what is seen: the surface that gets drawn. `sphere` is that mesh. The next two lines
set its size. `sphere.radius = radius` sets the radius. `sphere.height = radius * 2.0` sets its
height to twice the radius (`*` means multiply). [guess] A `SphereMesh` keeps radius and height as
two separate settings, and only when the height is exactly twice the radius is it round. If the
two disagreed you would get a squashed or stretched ball. Working out the height from `radius`
keeps it round whatever radius you choose.

**The marker.** `MeshInstance3D.new()` makes a second new object, `marker`. A mesh is only the
description of a surface. `marker` is the node that shows that surface at a place. Three lines
fill it in:

- `marker.mesh = sphere` gives the marker its surface, the sphere to draw.
- `marker.position = point_position` gives it its place.
- `add_child(marker)` gives it a parent: this station.

[guess] `add_child` puts a node into the scene tree under the node the script is on. Until that
line runs, the marker exists but is not in the scene, so it is not drawn. Because the marker is a
child of the station, its position is probably counted from the station's own place, not from the
middle of the whole study. That is how three stations can use the same `Vector3` and still stand
in three different places.

So two parts are made with `.new()`: the `SphereMesh` and the `MeshInstance3D`.

Keep in mind: a position is not its body. `point_position` says where. The marker is the body
that stands there.

### Try it

1. Change `1.12` to `1.7` here. Save, run. The sphere rises. (This supports the guess that the
   middle number is height.) Restore: `1.12`.
2. Change `radius := 0.14` to `radius := 0.3`. Save, run. The sphere gets bigger, and its centre
   stays where it was, at `point_position`. It grows outward in every direction. Its height grows
   too, because `sphere.height` is worked out from `radius` (`radius * 2.0`), so one change sets
   both.
3. Watch the second feeler. It still crosses, straight through the bigger sphere.

A bigger visible sphere stops nothing. Changing the mesh changes how much the sphere hides from
view. It does not change what can pass through.

Restore: `radius := 0.14`.

Being seen is not the same as being touched. Next, give the point something that can be met.

## Station three — Solid: a shape stops things

The third station looks just like the second, but its feeler stops. Open `solid.gd`. This is the
whole script:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)

    var radius := 0.14
    var sphere := SphereMesh.new()
    sphere.radius = radius
    sphere.height = radius * 2.0

    var marker := MeshInstance3D.new()
    marker.mesh = sphere
    marker.position = point_position
    add_child(marker)

    var solid := StaticBody3D.new()
    solid.position = point_position

    var sphere_shape := SphereShape3D.new()
    sphere_shape.radius = radius
    var collider := CollisionShape3D.new()
    collider.shape = sphere_shape

    solid.add_child(collider)
    add_child(solid)
```

The top half is `visible.gd` again, line for line. The bottom half adds three new kinds of thing:

- **`StaticBody3D`** is the body that takes part in collision. `solid` is one, and it is placed
  at the same `point_position` as the marker. [guess] "Static" means it does not move by itself;
  other things bump into it.
- **`SphereShape3D`** is its *shape*: what is touched. `sphere_shape.radius = radius` gives it the
  same radius as the visible sphere.
- **`CollisionShape3D`** is the node `collider`. [guess] A shape on its own is only a description,
  like a mesh. The `CollisionShape3D` is the node that carries it and hands it to the body.
  `collider.shape = sphere_shape` puts the shape in it.

The parenting runs in two steps:

- `solid.add_child(collider)`: the collider goes under the static body.
- `add_child(solid)`: the static body goes under the station.

So the station has two children, `marker` (seen) and `solid` (touched), and `solid` has one child,
`collider`, which holds the shape. The sphere shape itself is not a node; it is held by the
collider.

Why do the white sphere and its boundary line up exactly as supplied? Because both are built from
the same two variables. The mesh and the shape both use `radius`, and the marker and the static
body both use `point_position`. Same centre, same size.

### Try it: a boundary bigger than the sphere

Change only one line. Replace `sphere_shape.radius = radius` with:

```gdscript
    # solid.gd, in _ready(), in place of sphere_shape.radius = radius
    sphere_shape.radius = 0.35
```

Save and run.

The third feeler now stops short, with a gap of empty air between it and the white sphere. The
sphere still looks small, because the mesh still uses `radius`, 0.14. The feeler is being stopped
by an invisible boundary of 0.35.

You do not need anything extra to know this. The feeler stopping in mid-air already shows it.
But the editor can also draw the boundary: turn on **Debug → Visible Collision Shapes** in the
editor's menu and run again. [guess] Collision shapes are then drawn as thin wireframe outlines
in the running scene, so you can see the bigger sphere around the small white one.

You have just chosen whether the seen mesh and the encountered shape coincide. Until now they did
only because the script made them from the same numbers.

Where does this matter? In the museum, it is your own movement that meets the shape: [guess] the
player's body walks into the boundary, not into the drawn surface. The study has a fixed camera
and nobody walks, so it supplies another moving body to do the meeting: the feeler. You change
nothing in the feeler. You change the station, and the feeler reports what you made.

Restore: `sphere_shape.radius = radius`.

### Try it: a boundary smaller than the sphere

Now reverse it. Set `radius := 0.3` (a big visible sphere) and `sphere_shape.radius = 0.07` (a
small boundary). Save and run.

The feeler goes into the visible sphere before its label says "stopped". This label is the
feeler's own, not the station's "Point one" label. [guess] Each feeler carries a small readout
that changes to "stopped" when its contact test finds something solid. The feeler sinks in because
the shape sits deep inside the seen body: the surface is at 0.3, but the boundary is at 0.07.

Restore both: `radius := 0.14` and `sphere_shape.radius = radius`.

Seen and touched can part either way: the boundary can stand out in the air, or hide inside.

## Light off, body kept

In the museum, there is a switch on the wall. Use it: the shadows go, and a dim fill light keeps
the spheres visible.

One line decides it:

```gdscript
# read from the museum's switch; visible.gd has no sun: do not paste it there
sun.visible = false
```

`sun` is the museum's directional light (the light that acts like sunlight). This line is for
reading, not for copying. `visible.gd` has no variable called `sun`, so pasting the line there
would not work. [guess] Godot would refuse to run the script, because it does not know the name
`sun`.

The study keeps its own supplied light. How the museum builds the switch and the rig around it is
not part of this lesson.

Turning the light off changes the look. It does not change the shape: the sphere's mesh is still
there and still faintly lit by the fill, and its collision boundary is exactly where it was.
Light belongs with what is seen, not with what is met.

## Forward

At the end of the museum's *corridor* there is a large sphere, and it too says "Point one". It
asks you back to the choices in this lesson: what is placed, what is seen, and what is met. Now
that you know how such a sphere is built, you have another way to change how it is met: change
its shape, not only its look.

State to keep: the three scripts exactly as printed above, with every change restored.

Next comes **Point Coordinates**. It hands you a supplied point and then reads how it moves. It
also opens the three numbers inside a `Vector3`, which this lesson left closed, and prepares two
positions for the line that comes later. [guess] "The line" is probably the next object in the
course, drawn between two points.

If you want to know what each supplied part of the study does (the feelers, the labels, the
camera), there is a construction reference beside the study (`CONSTRUCTION.md`). It is optional.
You do not need it to finish this lesson.

## Why the lesson runs in this order

The three stations go from nothing, to a surface, to a boundary.

- `Position` has only a place: a position is not a body, so nothing shows and nothing stops.
- `Visible` adds a mesh: now something is seen, but a feeler passes through, however big it is.
- `Solid` adds a static body with a collision shape: now something is met.

[guess] The order teaches one distinction. Where a thing is, how it looks, and what it does when
something reaches it are three separate decisions in code. They only agree because a script makes
them agree, here by sharing `point_position` and `radius`. Seen is not touched.

> **Types** · *station* · *label* · *position* · *body* · *mesh* · *shape* · *corridor*
>
> **Code** · `-> void` · `Vector3` · `.new()` · `add_child` · `SphereMesh` · `MeshInstance3D` ·
> `StaticBody3D` · `SphereShape3D` · `CollisionShape3D`
>
> **Supplied** · the *feeler* (`contact_probe.gd`) · the study's camera and light · the museum's
> `sun` and switch
