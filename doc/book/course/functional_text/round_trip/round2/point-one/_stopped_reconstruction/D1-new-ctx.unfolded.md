# Point One: give the point a body

*Unfolded by a blind reader, chapter 1, from L2v2.md plus the earlier content (context_lessons.md, context_types.md). Passages marked [guess] fill a gap the compressed text left open.*

You arrive here from Day Zero and Point Zero. Day Zero gave you a project that runs: you can open a scene, change a value, save, run, stop and come back. It also named the *supplied* parts, the things others built that you use before you can explain them, such as the camera and the base scene. Point Zero gave you your first script. In it, `_ready()` ran once when the node entered the scene, and it set a greeting's text. You also met `var`, which makes a variable, and `:=`, which works out the variable's type from the value you give it.

In Point Zero, `_ready()` said hello. In Point One, the same function places a marker: a small sphere that shows where a point is. Before the lesson ends, that sphere can also stop something that moves into it. The lesson builds the marker in three steps, and each step adds one thing:

1. a position, which on its own shows nothing,
2. a mesh, which can be seen,
3. a shape, which can be touched.

## Open the study

Open the Point One study (its README is in `studies/point-one/`) and then open `study.tscn`.

The root node of this scene is called `PointStudy`. Under it are three *stations*, named `Position`, `Visible` and `Solid`. A station is one small set-up in the row: a node with its own script and its own *label*. Every label reads "Point one". [guess] A label here is a piece of 3D text, like the `Greeting` display from Point Zero. It sits at the station so you can tell which station is which.

Each station runs its own script:

- `Position` runs `position.gd`
- `Visible` runs `visible.gd`
- `Solid` runs `solid.gd`

[guess] The study reuses the base scene from Day Zero, with its floor, sky, sun and fixed camera, and hides the greeting.

Run the scene. Run Current Scene (F6) starts the scene you have open.

Here is what you should see:

- Above the first label there is nothing.
- Above the second and third labels there is a white sphere. The two look the same.
- Three pink *feelers* move from left to right, one through each station.
- The first two feelers pass straight through their stations. The third stops when it reaches the solid sphere.
- The sweep starts over again and again. **Space** pauses it and **R** restarts it.

The feelers are supplied, like the camera. Their script is `contact_probe.gd`. That script decides when a feeler has touched something, and it is not your code. [guess] Each feeler moves along a straight line and checks at every step whether it has met anything solid. When it has, it stops, and its own little label says "stopped".

You will not edit the feeler at all. What you change is the station: what is there for the feeler to cross or to hit.

## Step 1. Position: nothing shows

Open `position.gd`. This is the whole script:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)
```

Line by line:

- `extends Node3D` says this script is for a 3D node, the same as in Point Zero.
- `func _ready() -> void:` starts the function that runs once when the scene starts. [guess] The new part is `-> void`. It says the function hands no value back when it finishes. It is a note about the function and changes nothing about what the function does. In Point Zero you wrote `func _ready():` without it, and that works too.
- `var point_position := Vector3(0.0, 1.12, 0.0)` makes a variable called `point_position`. Its value is a `Vector3`: three numbers kept together as one value. The variable holds the *position* of the point, the place where it should be.

[guess] In Point Zero, `var count` was written outside the functions, so it kept its value from one call to the next. This `var` is written inside `_ready()`, so it only exists while `_ready()` is running. For a value that is used once, at the start, that is enough.

The lesson does not yet explain the three numbers one by one. That is the next hall's job, Point Coordinates. [guess] From the course's word list, a position is counted in metres from the origin: x to the right, y up, z toward you. That would make `1.12` a height, 1.12 metres up. The experiment below agrees with this, because a bigger middle number makes the sphere rise.

### Try it

Change `1.12` to `1.7` and run.

Nothing appears at the first station, not even at the new height. The reason is that a position is only a number the script holds. No *body* (a node placed in the scene that can be seen or touched) has been attached to it. Nothing in the scene reads `point_position`, so nothing is drawn.

The editor tells you so. It shows a warning that the variable is declared but never used. [guess] You will see this warning in the script editor, near the bottom of the window, as a yellow notice beside the line or in the warnings list.

The first feeler still crosses. The feeler's contact test is supplied. It looks for solid things in the scene, and it never reads your variable. With no body at this station, there is nothing for it to meet.

Change `1.7` back to `1.12`.

So far, a position on its own shows nothing. The next step adds a mesh.

## Step 2. Mesh: it shows

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

The first line inside `_ready()` is the same position as in Step 1. After it, the script makes two new things.

**The sphere, which is a mesh.** A *mesh* is the surface that can be seen: the shape that gets drawn.

- `var radius := 0.14` keeps the size in a variable so the script can use it more than once. [guess] It is in metres, so the sphere is 14 cm from its centre to its surface.
- `SphereMesh.new()` makes a new sphere mesh. [guess] `.new()` is how you make a fresh object of a kind Godot knows about. `SphereMesh` is the kind, and `.new()` gives you one of it, newly made, which you store in the variable `sphere`.
- `sphere.radius = radius` sets how far the surface is from the centre.
- `sphere.height = radius * 2.0` sets the height from top to bottom. `*` means multiply, so the height is twice the radius. [guess] A sphere mesh has its height set separately from its radius. If the height were not exactly twice the radius, you would get a squashed or stretched ball instead of a round one. This line keeps the two in step.

**The marker, which shows the mesh.** A mesh by itself is only a description of a surface. Something in the scene has to show it.

- `MeshInstance3D.new()` makes a new node whose job is to display a mesh. It is stored in `marker`.
- `marker.mesh = sphere` gives the marker its surface: the sphere.
- `marker.position = point_position` gives it its place: the position from Step 1.
- `add_child(marker)` gives it a parent, the station node this script is on. [guess] With nothing written in front of it, `add_child` acts on the node the script belongs to. A node made with `.new()` only exists in memory until it is added to the scene tree. Once added, it is drawn. [guess] Because the marker is a child of the station, its position is counted from the station's own spot, and that is why it appears above this station's label.

Two of these things come from `.new()`: the `SphereMesh` and the `MeshInstance3D`. The three `marker.` lines and `add_child` connect them: surface, place, parent.

The position itself has not changed. What changed is that something now uses it. A position is not a body: the body is the marker that is placed there.

### Try it

Change `1.12` to `1.7` in this script and run. Now the sphere rises, because the marker reads the position. Change it back to `1.12`.

Change `radius := 0.14` to `radius := 0.3` and run. The sphere gets bigger, but its centre stays in the same place, because the position did not change. The height grows along with it, because the height line is `radius * 2.0`, so changing the radius changes both.

The second feeler still passes straight through, even through the bigger sphere. Making the mesh larger changes how much the sphere hides from view. It does not change what can pass through. A mesh is only something to see.

Change it back to `radius := 0.14`.

So being seen is not the same as being touched. The next step adds a shape.

## Step 3. Shape: it stops things

The third station looks just like the second, but its feeler stops. Open `solid.gd`. This is the whole script:

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

Everything down to `add_child(marker)` is the same as `visible.gd`. The new part has three kinds of thing:

- **`StaticBody3D`** is a body that takes part in collision, meaning other things can bump into it. [guess] "Static" means it stays where it is put: it does not fall or get pushed. The script puts it at the same `point_position` as the marker.
- **`SphereShape3D`** is its *shape*: what can be touched. It is a sphere with a radius, and here it uses the same `radius` as the mesh. [guess] A shape is never drawn. It is only the boundary that collisions are tested against.
- **`CollisionShape3D`** [guess] is the node that carries the shape into the body. The body cannot hold a shape directly. It needs a `CollisionShape3D` child, and the shape goes inside that child through `collider.shape = sphere_shape`.

How they fit together:

- `sphere_shape` is not added as a child. It is set as the collider's `shape`.
- `collider` is a child of `solid`: `solid.add_child(collider)`.
- `solid` is a child of the station: `add_child(solid)`.

As the script is supplied, the white sphere and its boundary are in exactly the same place and are exactly the same size. Both use the same `point_position` and the same `radius`, 0.14. That is why the third station looks like the second, and why its feeler stops right at the white surface.

### Try it: a boundary bigger than the sphere

Change only the line `sphere_shape.radius = radius`:

```gdscript
    # solid.gd, in _ready(), in place of sphere_shape.radius = radius
    sphere_shape.radius = 0.35
```

Run. The feeler now stops in empty air, leaving a gap before the white sphere. The sphere itself stays small, because its mesh still uses `radius`, which is 0.14. You can tell from the feeler alone, so you do not need any extra tool to know the shape is larger.

If you want to see the boundary as well, turn on **Debug → Visible Collision Shapes** in the editor's menu bar. [guess] Then the next time the scene runs, Godot draws an outline of every collision shape, and you will see a larger outline around the small white sphere.

You have now chosen something new: whether the mesh you see and the shape you run into are the same, or not.

Why use a feeler at all? In the museum there is no feeler. There, it is your own movement, your player body walking through the hall, that meets the shape. If the shape is bigger than the sphere, you stop before you reach what you see. The study has a fixed camera and no walking player, so it supplies a different moving body to do the meeting: the feeler. You never change the feeler. You change the station's shape and watch what the feeler does.

Change it back: `sphere_shape.radius = radius`.

### Try it: a sphere bigger than the boundary

Now reverse it. Set `radius := 0.3` (so the mesh is big) and `sphere_shape.radius = 0.07` (so the shape is small).

Run. The feeler goes into the white sphere and keeps going for a while. Only when it reaches the small hidden shape does it stop and its own label say "stopped". That label belongs to the feeler and comes with it. It is not the station's "Point one" label. [guess] (`radius` now also sets the mesh height, so the white ball is bigger in every direction, but the shape inside it is tiny.)

The shape is sitting inside the body you can see.

Change both back: `radius := 0.14` and `sphere_shape.radius = radius`.

So the seen surface and the touched shape can come apart. Next comes light.

## Light off, body kept

This part happens in the museum, not in the study. In the museum hall there is a switch on the wall. Use it, and the shadows disappear. [guess] A weaker light that comes from all around, a "fill", stays on, so the spheres are still visible, only dimmer and flat.

One line in the museum's code makes this happen:

```gdscript
# read from the museum's switch; visible.gd has no sun: do not paste it there
sun.visible = false
```

`sun` is the museum's directional light, the light that shines from one direction like the sun. You only read this line here; you do not write it. Do not paste it into `visible.gd`. That script has nothing called `sun`. [guess] Godot would report an error that it does not know the name `sun`, and the script would not run. The study keeps its own supplied light, and you leave it alone.

Building the switch and the machinery behind it is not part of this lesson.

What the switch shows is that light changes how the spheres look, and nothing else. The mesh is still there, and so is the shape. Turning off the light does not make anything less solid.

## Forward

At the end of the museum's *corridor* (the long passage through the museum) stands a large sphere that also says "Point one". It is there to send you back to the choices in this lesson: where the point is, whether it can be seen, and whether it can be touched. Now that you know how such a sphere is built, from a position, a mesh and a shape, you have another way to change what happens when someone meets it.

State to keep: the three scripts exactly as printed above, with every experiment undone.

What this lesson leaves open: the three numbers inside `point_position`. You have changed the middle one and watched the sphere move, but the lesson has not explained what each number counts.

Next: **Point Coordinates** gives you a supplied point and then reads how it moves. That is where the three numbers are opened up. It will also prepare two positions, which [guess] later become the two ends of a line.

The study's construction reference (`studies/point-one/CONSTRUCTION.md`) explains what the supplied parts do: the feeler, the labels, the stations. Reading it is optional. You do not need it to finish this lesson.

---

> **New words** · *station*: one set-up in the study's row, a node with a script and a label · *label*: the text "Point one" at a station · *position*: where a node stands, as a `Vector3` · *body*: a placed node that can be seen or touched · *mesh*: the surface that is seen · *shape*: the boundary that is touched · *corridor*: the museum's long passage
>
> **New code** · `-> void` · `Vector3(...)` · `.new()` · `SphereMesh` · `MeshInstance3D` · `add_child()` · `StaticBody3D` · `SphereShape3D` · `CollisionShape3D` · `*`
>
> **Supplied** · the *feeler* (`contact_probe.gd`) and its "stopped" label · the camera and light · the museum's switch and `sun`
