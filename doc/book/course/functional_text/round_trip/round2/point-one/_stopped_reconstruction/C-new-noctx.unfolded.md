# Point One: give the point a body

*Unfolded by a blind reader (chapter 1, first-time programmer) from L2v2.md alone. No earlier lesson was available. Passages that fill a gap the compressed text left open start with [guess].*

## What you bring with you

This lesson leans on two earlier lessons that I did not have.

- From **Day Zero**: what a *supplied* part is, what the *base scene* is, how to *play* (run) a scene, and what the *museum* is.
- From **Point Zero**: what `_ready()` is, what `var` does, and what `:=` means.

[guess] A *supplied* part is something the course already built for you, such as a camera, a light, or a test script. You use it and read it, but you do not have to write it, and in this lesson you do not change it. `_ready()` is a function Godot runs once, when the node it belongs to enters the scene. `var name := value` makes a new named variable and gives it a first value. Godot works out the variable's type from that value. Plain `=` changes a value that already exists.

In Point Zero, the code inside `_ready()` printed a greeting. In this lesson the same function places a marker in 3D space.

## The study scene

Open the Point One study (its README sits in `studies/point-one/`), then open the scene `study.tscn`.

The root node of the scene is called `PointStudy`. Below it sit three *stations*, three nodes called `Position`, `Visible` and `Solid`. Each station has its own script and its own *label*, a piece of text reading "Point one".

[guess] The script names match the station names. `Position` runs `position.gd`, `Visible` runs `visible.gd`, and `Solid` runs `solid.gd`. A label is 3D text floating in the scene so you can tell the stations apart.

Run the scene and look:

- At the first label there is nothing to see.
- At the second and third labels there is a white sphere.
- Three pink **feelers** move from left to right, one through each station.
- Two of the feelers pass straight through their stations. The third stops when it reaches the sphere at the `Solid` station.
- The sweep starts again when it ends. Press **Space** to pause it and **R** to restart it.

The feelers come from a supplied script, `contact_probe.gd`. That script decides whether a feeler has touched something. You do not write that test, and you do not change it. It is borrowed, like the camera. [guess] Wherever the lesson writes "enters:", it is pointing at something that comes into the scene from outside your own code.

**What you will do:** you will not change the feeler. You will change the stations, and so change what a feeler is able to pass through.

## Station 1, Position: nothing shows

Open `position.gd`. This is the whole script:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)
```

[guess] `extends Node3D` says the script belongs to a node that has a place in 3D space. `-> void` says that `_ready()` hands no value back when it finishes.

`point_position` is a **`Vector3`**, a value made of three numbers. Here it holds the *position* the course supplies for the point. This lesson does not explain what each of the three numbers means. The next lesson, Point Coordinates, opens them up. [guess] Changing the middle number appears to move the point up and down, as the next station shows.

**Try it.** Change `1.12` to `1.7` and run the scene.

Still nothing appears at the first station. A position on its own is not a thing you can see. The script never attaches a visible **body** to the scene. [guess] A body here means a node that is actually placed in the scene and can be seen, touched, or both.

The editor points out the same fact. It shows an *unused-variable warning* on `point_position`, because the script stores a position and then never uses it for anything.

The feeler also still passes through. Whether a feeler stops is decided by the supplied contact test, and that test finds nothing at this station to touch. Your number reaches nothing the test can feel.

Put the value back to `1.12`.

**So far:** a position alone shows nothing. Next, you give it a mesh.

## Station 2, Visible: the mesh shows

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

Here is what each part does.

- `var radius := 0.14` stores the sphere's size in one place.
- `SphereMesh.new()` makes a new sphere **mesh**. A mesh is the surface you see. [guess] `.new()` creates a fresh object of the named kind. Before this line, no sphere exists.
- `sphere.radius = radius` and `sphere.height = radius * 2.0` set its size. The height is twice the radius, so the sphere is as tall as it is wide.
- `MeshInstance3D.new()` makes a new node, `marker`. A node of this kind displays a mesh in the scene.
- Three lines then place the marker:
  - `marker.mesh = sphere` gives the marker its surface.
  - `marker.position = point_position` gives the marker its place.
  - `add_child(marker)` gives the marker its parent. [guess] `add_child` puts the marker under this station's node in the scene tree. Until that line runs, the marker exists only in memory and is not in the scene.

Notice that `sphere` (the mesh) and `point_position` (the place) are separate. A position is not its body. The body is what you put at the position.

**Try it.**

1. Change `1.12` to `1.7` here and run. This time the sphere rises, because the position is now used. Put it back to `1.12`.
2. Change `radius` to `0.3` and run. The sphere grows, but its centre stays where it was, at `point_position`. Its height grows too, because the height is computed as `radius * 2.0`.

Even the bigger sphere does not stop the feeler. The feeler passes straight through it. Changing the mesh changes what the sphere hides from view, meaning what you can no longer see behind it. It does not change what can pass through.

Put the value back to `radius := 0.14`.

**So far:** being seen is not the same as being touched. Next, you give the point a shape.

## Station 3, Solid: the shape stops things

The third station looks the same as the second, a white sphere, but its feeler stops. Open `solid.gd`. This is the whole script:

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

The first half is `visible.gd` again. The second half adds three new kinds of object:

- **`StaticBody3D`** (`solid`) is a body that takes part in collision. Other things can bump into it. [guess] "Static" means it does not move by itself. It is placed at the same `point_position` as the marker.
- **`SphereShape3D`** (`sphere_shape`) is the body's **shape**, the part that gets touched. It has its own radius, set here to the same `radius` as the mesh.
- **`CollisionShape3D`** (`collider`) carries the shape. `collider.shape = sphere_shape` hands the shape to it. [guess] A collision body cannot hold a shape directly. It needs this in-between node.

They connect like this. `solid.add_child(collider)` puts the collider under the static body, and `add_child(solid)` puts the static body under the station. The chain runs station → `solid` → `collider` → `sphere_shape`. The marker hangs from the station on a separate branch.

As supplied, the white sphere you see and the boundary the feeler meets are exactly the same size, in exactly the same place. Both use the one `radius` variable (0.14) and the one `point_position`. That is why the feeler appears to stop right on the sphere's surface.

### Make the shape larger than the mesh

Change only the line `sphere_shape.radius = radius` to:

```gdscript
    # solid.gd, in _ready(), in place of sphere_shape.radius = radius
    sphere_shape.radius = 0.35
```

Run the scene. The feeler now stops in empty air, leaving a gap before it reaches the sphere. The white sphere stays small. You can see this without any extra tool: the gap itself shows that the touched shape is bigger than the seen mesh.

The editor can also draw the hidden shape for you. Turn on **Debug → Visible Collision Shapes** in the editor's menu. [guess] Turn it on before you run, and the collision shape is drawn as an outline in the running scene.

What you have just done is choose whether the mesh you see and the shape something meets are the same. In the museum, the thing that meets these shapes is your own movement, your body walking into them. The study scene has a fixed camera and you do not walk in it, so it supplies a different moving body to do the meeting: the feeler.

Put it back to `sphere_shape.radius = radius`.

### Make the shape smaller than the mesh

Now reverse it. Set `radius` to `0.3`, so the mesh is big, and set `sphere_shape.radius` to `0.07`, so the shape is small.

Run the scene. The feeler pushes into the white sphere and has gone partway inside before its label says "stopped". [guess] The feeler carries a label of its own that reports whether it is moving or stopped. That label belongs to the feeler, not to the station's "Point one" label. The touched shape now sits inside the seen body.

Then restore both values: `radius := 0.14` and `sphere_shape.radius = radius`.

**So far:** what is seen and what is touched can be pulled apart. Next, light.

## Light off, body kept

In the museum, find the wall switch and use it. The shadows disappear, but a dim fill light keeps the spheres visible.

One line in the museum decides this:

```gdscript
# read from the museum's switch; visible.gd has no sun: do not paste it there
sun.visible = false
```

`sun` is the museum's directional light. [guess] A directional light shines from one direction across the whole scene, like the sun. You only read this line here (that is what the lesson's "[read]" mark means). `visible.gd` has no `sun` variable, so if you paste the line into it, the script will fail.

The study keeps its own supplied light, so nothing in the study changes. Building the switch and the lighting rig behind it is not part of this lesson.

Turning the light off changes how things look. It does not change their shape. The collision shapes are still there, and a feeler or your body still meets them.

## Forward

At the end of the museum's *corridor* stands a large sphere that still says "Point one". [guess] The corridor is the museum's long walkway. The sphere invites you back to the choices you made in this lesson: does what you see match what you meet? Now that you know how such a sphere is built (position, mesh, shape), you have another way to change how someone meets it.

When you finish, leave the three scripts exactly as printed above.

**Next:** Point Coordinates (`commons/maps/Point_Coordinates/tutorial.md`) hands you a supplied point and then reads how it moves. It will also prepare two positions, which together make a line.

**Optional:** the roles of the supplied parts (the feeler, the camera, the labels) are described in the construction reference, `studies/point-one/CONSTRUCTION.md`. You do not need it to finish this lesson.

## Why the lesson goes nothing → surface → boundary

The three stations add one layer each:

1. **Position**: a place, with nothing at it. Nothing is seen and nothing is touched.
2. **Mesh**: a surface at that place. It is seen but not touched.
3. **Shape**: a boundary at that place. It is touched, and it is seen only because a mesh happens to sit at the same spot.

The order teaches one distinction. Where a thing is, how it looks, and what meets it are three separate choices. Making them match is a decision you take, and you can just as well decide to make them differ.

## Words from this lesson

- **station**: one of the three nodes under `PointStudy`, each with a script and a label.
- **label**: the text "Point one" at each station. Each feeler also has a label of its own.
- **position**: where something is, held as a `Vector3`.
- **Vector3**: a value made of three numbers.
- **body**: a node actually placed in the scene, which can be seen, touched, or both.
- **mesh**: the surface that is seen (`SphereMesh`, displayed by a `MeshInstance3D`).
- **shape**: the boundary that is touched (`SphereShape3D`, carried by a `CollisionShape3D` under a `StaticBody3D`).
- **corridor**: the museum walkway that ends at the large "Point one" sphere.
- **feeler** (supplied): the pink moving probe from `contact_probe.gd`. It stops when it touches a shape.
