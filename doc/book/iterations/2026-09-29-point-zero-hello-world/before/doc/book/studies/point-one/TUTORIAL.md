# Point One — give a position a place

Day Zero has prepared the environment. Open `points.gd` in [the Point One study](README.md). The supplied `coordinates.tscn` uses the same base and adds two small white markers, named `A` and `B`, and three coloured coordinate guides. The downloaded script shows both markers; we will build up to it.

The guides and markers are supplied objects. Here we learn to place them. The first change is deliberately invisible.

## Keep a position

Replace the contents of `points.gd` with:

```gdscript
extends Node3D

func _ready() -> void:
    var a := Vector3(-0.75, 1.12, 0.0)
```

Run it. The floor and guides remain; neither white marker appears. We have kept three numbers without giving either marker that position.

`extends Node3D` gives this script a place in the 3D scene. Godot calls `_ready()` when the scene is ready; our instructions go inside it, indented. `var` gives a value a name. `:=` lets Godot infer its type: here, `Vector3`, which holds three numbers. Used as a position, those numbers are X, Y and Z coordinates relative to an origin.

The origin is where the three supplied guides meet. From there, `a` is 0.75 metres along negative X, 1.12 metres up Y, and zero along Z. The editor may warn that `a` is unused. That describes exactly what we have done so far: keep a value without using it.

## Let a marker show it

Add these two lines beneath the position, with the same indentation:

```gdscript
    $A.position = a
    $A.visible = true
```

`$A` refers to the existing marker named `A` in this scene. The first line puts its centre at `a`; the second makes it visible.

A small sphere now marks the position. Its surface helps us find a centre that has no surface of its own. The sphere has a radius; the position has three coordinates. Changing one need not change the other. We borrow the sphere's construction for this first exercise.

Change only `-0.75` to `0.75`. The marker crosses to the other side of the Y guide. Restore X, then change `1.12` to `1.7`. It rises. Restore Y, then change the last number from `0.0` to `0.7`. It moves along positive Z, towards the camera in this prepared view.

The red guide marks X, green Y and blue Z. Their labels identify the positive directions. Follow one change at a time. The marker moves between runs because the saved coordinates changed; we have not yet written movement over time.

## Keep another position

Restore `a` and add a second position and its marker. The complete script is now:

```gdscript
extends Node3D

func _ready() -> void:
    var a := Vector3(-0.75, 1.12, 0.0)
    var b := Vector3(0.75, 1.12, 0.0)

    $A.position = a
    $A.visible = true
    $B.position = b
    $B.visible = true
```

Both markers use the same supplied sphere. Their different coordinates put them on opposite sides of the origin. Change only `b`: `a` stays where it was.

Try putting B above A. Try putting it behind A. Finally give `b` the same coordinates as `a`. The two objects occupy the same place, so this view can show one sphere where the script still names two. Separate them again.

You can now make an arrangement by choosing two positions. The markers and coordinate guides help you see that choice. Their construction is available to inspect, but neither the distance arrow nor the coordinate labels need to become a programming task here.

The museum's solid and held points ask further questions about what a visible body permits. We keep those encounters in the main text. Their physics and pickup systems are outside this first exercise; [the optional construction study](CONSTRUCTION.md) retains the earlier mesh and collision examples.

We leave with `a` and `b` expressed in the same coordinate frame. Point Lines can begin by connecting them. The relation has two ends before we give it a visible body.
