# 1 Point One: give the point a body

*Unfolded by a blind reader at the start of Point One, from L2.md plus the earlier content (Day Zero, Point Zero, and the chapter 1 type list). Passages that fill a gap begin with [guess].*

In Point Zero you met `_ready()`: a function that runs once, when its node and children have entered the scene tree. Point Zero used it to set a greeting. Point One uses it to do two things in order: place a point, then give that point a body.

"Body" turns out to mean two different things, and the lesson is built so you meet them one at a time: something you can **see**, and something that can be **touched**. You begin with neither.

---

## 1.1 Three stations

*[Picture: three "Point one" labels in a row. Above the first, empty air. Above the second, a white sphere. Above the third, a white sphere. Pink feelers sweep past all three.]*

Open the [Point One study](../../../../studies/point-one/README.md), then open `study.tscn` in the editor.

Look at the Scene tree. The root node is `PointStudy`. Under it stand three **stations**, named `Position`, `Visible` and `Solid`.

A *station* is a node with a script and a label. Each station's script decides what stands above its label. The script names follow the station names: `Position` runs `position.gd`, `Visible` runs `visible.gd`, `Solid` runs `solid.gd`.

[guess] The label is a floating text display like Point Zero's `Greeting`, and each reads "Point one".

Run the scene (F6, **Run Current Scene**, runs the scene you have open). You should see:

- above the first label: nothing;
- above the second: a white sphere;
- above the third: a white sphere that looks the same as the second.

Three pink **feelers** move across, one through each station. The first two pass straight through. The third stops.

Two keys control the sweep: **Space** pauses it, **R** restarts it.

The feelers (their code is `contact_probe.gd`), the floor, the light and the camera are *supplied*: made for you, used before they are taught. This study reuses the desktop base from Day Zero, with the greeting hidden. You do not edit the feelers.

[guess] Why feelers at all: the desktop base has no player, no walking and no hands. Nothing of yours can move through the stations to test them, so the study supplies a moving thing that does it for you, again and again, the same way each time.

What you do change is the three station scripts. By changing them you decide what a feeler can cross and what stops it.

---

## 1.2 A position, then a mesh

*[Picture: empty air above the first label, a white sphere above the second. The feelers pass through both.]*

### position.gd: a place with nothing in it

This is all of `position.gd`:

```gdscript
extends Node3D

func _ready() -> void:
    var point_position := Vector3(0.0, 1.12, 0.0)
```

[guess] The lesson shows only the function. The `extends Node3D` line at the top is assumed from Point Zero, where every script began that way, and because a station has a position.

Read it line by line.

- `func _ready() -> void:` starts the function that runs once when the station is ready. `-> void` is new. It says the function returns nothing. [guess] A function can hand a value back to the code that called it. `void` means "this one hands back nothing". `_ready` never needs to hand anything back, so the arrow just states that.
- `var point_position := ...` makes a **variable**: a name for a value. You met `var` and `:=` in Point Zero's counter. `:=` lets Godot work out the kind of value from the right-hand side.
- `Vector3(0.0, 1.12, 0.0)` is the value: a `Vector3`, three numbers held as one value. From the chapter's earlier sections, the three numbers are coordinates counted in metres from the origin: x (right), y (up), z (toward you). This one says: no distance right, 1.12 metres up, no distance toward you.

So the variable `point_position` holds a **position**: *where*, as a `Vector3`. The **point** is the place that position marks. A point has no size.

**Try it.** Change `1.12` to `1.7` and run.

Nothing appears at the first station, just as before. The editor shows a warning, "unused variable". The script made the name `point_position` and gave it a value, but no line ever reads it, so nothing in the scene uses it.

That is the lesson of the first station: **a position gives the point no body.** It is a place with nothing standing in it. That is why the first feeler crosses empty air whatever numbers you put in. Nothing is there to see or to meet.

Put `1.12` back.

### visible.gd: something you can see

`visible.gd` starts the same way, then adds a **mesh**, the thing that is seen. The whole script:

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

[guess] The lesson shows only the added lines, indented. I take them to sit inside `_ready()`, after the `point_position` line, because they use `point_position`.

Two things are made here with `.new()`. [guess] `.new()` makes a fresh object of the kind named before the dot.

1. `SphereMesh.new()` makes a sphere mesh: a description of a round surface to draw. It is not a node, and on its own it is not in the scene.
   - `sphere.radius = radius` sets how far the surface is from its centre: 0.14 metres.
   - `sphere.height = radius * 2.0` sets its height to twice the radius, 0.28 metres. [guess] A `SphereMesh` keeps its height as a separate setting from its radius. If the height did not match twice the radius, the sphere would be squashed or stretched. Working the height out from `radius` keeps it round whatever radius you choose.

2. `MeshInstance3D.new()` makes a node that can draw a mesh. The variable `marker` holds it.

Three lines then give the marker what it needs:

- `marker.mesh = sphere`: its **surface**, the sphere to draw;
- `marker.position = point_position`: its **place**, at the point;
- `add_child(marker)`: its **parent**. This puts `marker` into the scene tree under the station that runs the script. [guess] Without this line the marker exists only inside the running script. It is never in the scene, so nothing is drawn.

`marker` is a **body**: a node you place. Notice that position and body are two things. `point_position` is only a value. `marker` is a node, and its own `position` is *set from* that value.

**Try it.**

- Change `1.12` to `1.7`: the sphere rises, because the y number (up) grew.
- Change `radius` from `0.14` to `0.3`: the sphere grows about one centre. Its centre stays at `point_position`, and the surface now reaches 0.3 metres out in every direction instead of 0.14. Its height grows too, to 0.6, because the height line is worked out from `radius` (`radius * 2.0`). One variable feeds both settings.

Watch the second feeler. However large you make the sphere, **the feeler still crosses.** A mesh is only drawn. Nothing in it can be touched, so a bigger visible sphere does not stop anything.

[guess] Put `1.12` and `0.14` back before going on.

---

## 1.3 A shape, set apart

*[Picture: on one side, the feeler stopped short of a small sphere. On the other, the feeler sunk into a large one.]*

`solid.gd` builds the same `marker` as `visible.gd`, then adds a **shape**, the thing that is touched. The whole script:

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

[guess] The lesson says "builds the same marker, then adds" and shows only the new lines. I take the new lines to follow the marker lines inside `_ready()`.

Three new kinds of thing:

- **`StaticBody3D`**: a body that stops things. [guess] "Static" means it stays where it is put and is not pushed around. `solid.position = point_position` puts it at the point.
- **`SphereShape3D`**: a round boundary for touching, with its own `radius`. Like `SphereMesh`, it is a description, not a node.
- **`CollisionShape3D`**: a node that carries a shape for its body. `collider.shape = sphere_shape` hands it the sphere shape.

How they are parented:

- `solid.add_child(collider)` puts the collider under the static body;
- `add_child(solid)` puts the static body under the station.

The sphere shape is not parented. It is assigned to the collider's `shape`. So the tree under the `Solid` station reads: station, then `marker`, and beside it `solid`, then `collider` under `solid`, carrying the sphere shape.

Run it, and the third feeler stops at the shape.

**Why the white sphere and its boundary coincide.** As supplied, both are built from the same two values. Both centres come from `point_position`: the marker's position and the static body's position. Both radii come from the one variable `radius`: `sphere.radius = radius` and `sphere_shape.radius = radius`. [guess] The collider sits at its body's centre, since its own position is never changed. So what you see and what you touch are the same size in the same place. That is a choice made in the code, not something Godot does for you.

**Try it: break the agreement.**

1. Change only the shape line to `sphere_shape.radius = 0.35` and run. The white sphere looks the same, but the feeler **stops short**, in empty air before it reaches anything visible. Empty space resists. [guess] You do not need any overlay to know this. The feeler halting before it touches the drawn sphere already shows that the boundary is larger than the surface.
2. Now set `var radius := 0.3` (the mesh) and `sphere_shape.radius = 0.07` (the shape). The drawn sphere is large and the boundary is tiny, so the feeler **sinks into** the white sphere before its label says "stopped". [guess] The "stopped" label belongs to the feeler and appears when it makes contact.

To see the boundary itself, turn on **Debug → Visible Collision Shapes**. [guess] That is in the editor's Debug menu, switched on before you run. The running scene then draws each shape as an outline you can compare with the mesh.

When you have finished, restore `0.14`: set `var radius := 0.14` and put the shape line back to `sphere_shape.radius = radius`, so the two agree again.

**What this section teaches:** seen and touched are set apart. The mesh decides what is seen and the shape decides what is touched. Whether they agree is your choice.

In the museum there is no feeler. Your own movement meets the shapes. [guess] That means the supplied player, its walking and its hands, in the headset. The study supplies a feeler because the desktop base has no player to do that meeting. You never change the feeler itself. You change the station scripts, and the feeler shows what they built.

---

## 1.4 Light off, body kept

*[Picture: the museum after the wall switch. Shadows gone, spheres dim, shapes still in place.]*

In the museum, a switch on the wall runs a line like this one:

```gdscript
sun.visible = false
```

It turns the museum's light off. Shadows go and the spheres dim, but the shapes stay where they are and still stop what meets them. Light belongs to seeing. It has nothing to do with touching.

This line is for **reading, not pasting**. `sun` is the museum's light. `visible.gd` has no `sun`, so there is nothing in your script for that name to reach. [guess] Pasted in, the editor would report that it does not know the name `sun`.

In the museum corridor, the last sphere still says "Point one". [guess] It is the museum's version of the third station: a body seen and touched at a point. Meeting it asks you to remember the choices you made here, about where the point is, what is drawn and what stops you. You know how to rebuild it. [guess] You do not need to work through how the museum itself was built. As Day Zero said, the construction of the supplied parts is not an entrance examination.

What this lesson leaves open: [guess] `point_position` was set once, in `_ready()`, and never moves. You cannot hold it, and the lesson used its three numbers without taking them apart.

Next is [Point Coordinates](../../../../../../commons/maps/Point_Coordinates/tutorial.md): a point you can hold, and two positions for a line. [guess] There the point becomes something you pick up, and two positions together mark out a line.

---

> **Types** · *station*: a node with a script and a label · *point*: the place a position marks · *position*: where, as a `Vector3` · *variable*: a name for a value · *mesh*: what is seen · *body*: a node you place · *shape*: what is touched
>
> **Code** · `-> void` · `var` · `:=` · `Vector3` · `.new()` · `SphereMesh` · `MeshInstance3D` · `add_child()` · `StaticBody3D` · `SphereShape3D` · `CollisionShape3D`
>
> **Supplied** · *feeler* (`contact_probe.gd`) · floor, light, camera · the museum's `sun`
>
> **Needs** (Point Zero) · scene · node · script · `func` · `_ready()`
