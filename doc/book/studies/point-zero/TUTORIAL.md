# Point Zero — Hello, world

Day Zero gave you a running project. Here you decide what happens once and what keeps happening.

Open `hello_world.gd` in [the Point Zero study](README.md). The room supplies the floor, camera and light. The script creates its own text display. Each example can also be attached to an empty `Node3D` in your prepared scene.

This download is a desktop study. The script also gives us a counter to place in Ada's world. Day Zero prepares that world and its XR tools; this example needs no controller input.

## Once

```gdscript
extends Node3D

var display := Label3D.new()

func _ready():
    display.position.y = 1.5
    display.text = "Hello, world."
    add_child(display)
```

Run the study. “Hello, world.” appears above the floor.

A node is a building block of a Godot scene. `extends Node3D` adds our script's behaviour to a node in 3D space.

`Label3D` is Godot's class for text in 3D space. `.new()` creates one. The variable `display` keeps a reference to that node, so we can change it.

`func` defines a function: a named block of code. The colon begins the block; the indentation groups its instructions. Godot calls `_ready()` when this node is ready.

Inside `_ready()`, we set the display's height to 1.5 units above its parent and assign its text. `add_child(display)` adds it beneath our node in the scene. Change the quoted words and run again.

## The view and the light

The display exists in 3D space. A `Camera3D` chooses the view shown on screen. In the study's `base.tscn`, select the camera and change its z position from 4.7 to 3.0. Run again: the text appears larger, although the text object has not grown. Restore 4.7.

This is the desktop camera. In XR, the tracked view follows your head; do this position-editing exercise in the desktop study.

A `DirectionalLight3D` sends parallel light through the scene, like sunlight. Select it and change its `light_energy` from 1.2 to 0.0. Run again: the floor goes dark. This study uses no ambient fill light.

The text stays bright. By default, `Label3D` is *unshaded*: its appearance ignores lighting. Being visible and being illuminated are separate conditions here. Restore the light's energy to 1.2.

## Repeatedly

Replace the script with this version:

```gdscript
extends Node3D

var display := Label3D.new()
var count := 0

func _ready():
    display.position.y = 1.5
    display.text = str(count)
    add_child(display)

func _process(_delta):
    count += 1
    display.text = str(count)
```

The display now shows a number that increases.

`var count := 0` declares a variable starting at zero. `:=` lets Godot infer its type from the starting value: here, an integer, or whole number. Declared outside the functions, `count` keeps its value between calls.

Godot calls `_process` on each process frame. `count += 1` adds one to the stored count. `str(count)` converts the number to text for the display.

Godot passes the frame's time interval, in seconds, as `_delta`. The underscore marks an unused input. This example counts calls, not seconds; its speed depends on how often processing runs.

Change `count += 1` to `count += 2`. Each call now adds two. Restore one before continuing.

## Change when it happens

Move the counting instruction into `_ready()`:

```gdscript
extends Node3D

var display := Label3D.new()
var count := 0

func _ready():
    display.position.y = 1.5
    count += 1
    display.text = str(count)
    add_child(display)
```

The display reaches one and stays there. The scene keeps running. The counting instruction happens once because of where you placed it.

Restore the version with `_process` to keep counting.

Our counter begins with this node. The museum panel reads `Engine.get_process_frames()`: the engine's process-frame total since startup. Its count includes work done before the panel appeared. The two counts have different beginnings.

In Point One, we will reuse `_ready()` and a variable to give a point a position.
