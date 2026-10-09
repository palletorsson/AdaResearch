# Point Zero — Hello, world

Day Zero gave you a running project. Here you decide what happens once and what keeps happening.

Open `hello_world.gd` in [the Point Zero study](README.md). Its script is attached to the scene's root node. Two supplied text displays, `Greeting` and `Counter`, are children of that node. Replace the script with each complete example below.

## Once

```gdscript
extends Node3D

func _ready():
    $Greeting.text = "Hello, world."
```

Run the study. “Hello, world.” appears above the floor.

A node is a building block of a Godot scene. `extends Node3D` adds our script's behaviour to a node in 3D space.

`func` defines a function: a named block of code. The colon begins the block; the indentation groups its instructions. Godot calls `_ready()` when this node and its children are ready. Here, it sets the greeting once.

`$Greeting` finds the child named `Greeting`. Its `text` property holds the displayed words. `=` assigns the quoted text to that property.

Change the words and run again. The display uses your new greeting.

## Repeatedly

```gdscript
extends Node3D

var count := 0

func _ready():
    $Greeting.text = "Hello, world."

func _process(_delta):
    count += 1
    $Counter.text = str(count)
```

The greeting stays. Beneath it, a number increases.

`var count := 0` declares a variable named `count`, starting at zero. `:=` lets Godot infer its type from that value: an integer, or whole number. Declared outside the functions, it keeps its value between calls.

Godot calls `_process` on each process frame. `count += 1` adds one to the stored count. `str(count)` converts the number to text for the `Counter` display.

Godot passes the frame's time interval, in seconds, as `_delta`. The underscore marks an unused input. This example counts calls, not seconds; its speed depends on how often processing runs.

Change `count += 1` to `count += 2`. Each call now adds two. Restore one before continuing.

## Change when it happens

Move the counting and display instructions into `_ready()`:

```gdscript
extends Node3D

var count := 0

func _ready():
    $Greeting.text = "Hello, world."
    count += 1
    $Counter.text = str(count)
```

The display reaches one and stays there. The scene keeps running. The counting instruction happens once because of where you placed it.

Restore the version with `_process` to keep counting.

Our counter begins with this node. The museum panel reads `Engine.get_process_frames()`: the engine's process-frame total since startup. Its count includes work done before the panel appeared. The two counts have different beginnings.

In Point One, we will reuse `_ready()` and a variable to give a point a position.
