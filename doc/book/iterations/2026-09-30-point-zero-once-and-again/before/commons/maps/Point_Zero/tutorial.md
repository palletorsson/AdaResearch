# Point Zero — Hello, world. We are here.

Day Zero gave us somewhere to run a project. Now we will make an instruction happen when our scene is ready, and another keep happening while it runs.

Open `hello_world.gd` in [the Point Zero study](../../../doc/book/studies/point-zero/README.md). The project uses the same `base.tscn`, with two supplied text displays named `Greeting` and `Counter`. The download contains the finished counter. Begin by replacing its script with the short greeting below.

We borrow the displays, floor, light and camera. Here we are attending to when something happens.

## Say hello

```gdscript
extends Node3D

func _ready():
    $Greeting.text = "Hello, world."
```

Run it. “Hello, world.” appears above the floor.

`extends Node3D` lets this script belong to the supplied 3D scene. `func` introduces a function: a named group of instructions. The colon begins its body; the indented line belongs inside it.

`_ready()` has a particular meaning to Godot. It is called when this node and its children have entered the scene tree and are ready. In this study, that is where our greeting is set. It is not called again on every frame.

`$Greeting` finds the supplied child named `Greeting`. Its `text` property holds the words it displays. The equals sign assigns our quoted text to that property. We are changing an existing display, not constructing its letters.

Change the words and run again. You have chosen what this arrival says.

Our node becoming ready does not mean that the world has just begun. The engine has already been working to bring it here.

## Let a number continue

Replace the script with this complete version:

```gdscript
extends Node3D

var count := 0

func _ready():
    $Greeting.text = "Hello, world."

func _process(_delta):
    count += 1
    $Counter.text = str(count)
```

The greeting stays. Beneath it, a number keeps changing.

`var count := 0` gives a value a name and begins it at zero. `:=` lets Godot infer its type from that value: an integer, a whole number. This line sits outside the functions, so the scene node keeps `count` between their calls.

Godot calls `_process` on each process frame while processing is enabled. `count += 1` adds one to the value already there. `str(count)` turns that number into text, which we give to the supplied `Counter` display.

Each call begins with what the previous call left behind. The number can continue while our attention goes somewhere else.

Godot also supplies the elapsed time for that update, in seconds. We receive it as `_delta`. The leading underscore says we are deliberately leaving this input unused. Our script counts calls; it does not measure seconds. A hundred updates add a hundred, however long they took.

## Once, or repeatedly?

Move the two indented lines from `_process` into `_ready`, beneath the greeting. Remove the now-empty `_process` function. The script becomes:

```gdscript
extends Node3D

var count := 0

func _ready():
    $Greeting.text = "Hello, world."
    count += 1
    $Counter.text = str(count)
```

Run it. The number reaches one and stays there. The engine continues running; our counting instruction now happens only when this node becomes ready.

Restore the version with both functions. Change `count += 1` to `count += 2`. The display advances two at a time. You have changed what happens on each call, without choosing when those calls arrive. Return it to one when you finish.

## Whose beginning?

Our small count begins with this node. Restarting the study creates a fresh instance and begins its count again.

The museum's panel asks for `Engine.get_process_frames()` instead: the engine's process-frame total since startup. That total can include work done before the panel entered the room. Our exercise and the museum panel can therefore show different numbers without either being broken. Their beginnings differ.

A zero does not tell us where its counting began. We have to know what is being counted and when that count was started.

In Point One, we will return to `_ready()` to place a marker. We will recognise the moment in which that instruction runs, and can give our attention to its new material: a position.
