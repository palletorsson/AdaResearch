# Point Zero — Already running

This tutorial follows a path through **Endless Museum**. You will walk its halls, encounter works, and learn to build and change selected parts of what you find. Each lesson adds something you can carry into work of your own.

The tutorial track follows particular artifacts and operations. Alongside it, reflective texts explore questions raised by the works: what a form makes possible, what its rules assume, and how we experience it. You can read these texts beside the lessons. Some artifacts take part in both tracks; others belong to only one.

You will also encounter artifacts that appear in neither track. They are part of the field we explore: neighbours, comparisons, experiments and possibilities we have not yet followed. You can stop with them without needing a lesson to tell you what they are for.

The museum is larger than the route we take through it. We begin by choosing where to pay attention.

## The counter is already here

You arrive in front of a number that is already increasing. The museum was processing frames before you could see it. We will use this counter to follow what happens once and what repeats.

Work in your existing Ada project, in Endless Museum's **Point Zero** hall. Open `commons/visualaid/frame_counter/frame_counter_display.gd`. The script already creates the console and its text in code. We will borrow that construction and change how the number is updated.

## Ready

Find this function:

```gdscript
func _ready() -> void:
    _build()
    _arrival_frame = int(Engine.get_process_frames())
    _built = true
    _refresh_caption()
```

`func` defines a function: a named block of instructions. The colon begins its indented body. `-> void` says this function returns no value. Godot calls `_ready()` when this node and its children are ready in the scene.

`_build()` is a supplied function in the same script. It creates the console, including a `Label3D` for the number, and keeps a reference to that label in `label`. The remaining lines record the panel's starting frame and prepare its caption. Leave them in place. Making the housing is work we can return to; here we are following when instructions run.

## Every frame

Find `func _process(delta: float) -> void:` further down the file. Replace that function, including its indented body, with these two lines. Keep the next function, `_count()`, and everything below it.

```gdscript
func _process(_delta: float) -> void:
    label.text = str(Engine.get_process_frames())
```

Save and restart the museum. The existing counter keeps increasing. You have reduced its update to the operation we are studying.

Godot calls `_process()` on each process frame. `Engine.get_process_frames()` reads the engine's total since startup. `str()` turns that number into text; `label.text =` assigns it to the display. Each call reads a new total and replaces the previous text.

Godot also passes the time interval for the frame as `_delta`, measured in seconds. `float` means a number that can have a fractional part. The leading underscore marks an input we do not use here. We are displaying a frame count, not elapsed seconds.

## Read it once

Move the assignment into the end of `_ready()`. Remove the two-line `_process()` function you just added. Your `_ready()` now reads:

```gdscript
func _ready() -> void:
    _build()
    _arrival_frame = int(Engine.get_process_frames())
    _built = true
    _refresh_caption()
    label.text = str(Engine.get_process_frames())
```

Save and restart. The counter shows a number and holds it. Walk around: the museum still runs. You have stopped this display from receiving new readings, not stopped the engine.

The number need not be zero. `_ready()` marks this node's readiness; the engine has already processed frames getting here.

Put the assignment back into `_process()` and remove it from `_ready()`. Restart: the display follows the running total again. The instruction is the same. Its place determines whether it runs once or repeatedly.

These are edits to the existing artifact's shared script in your working copy. When you finish experimenting, restore the original functions to keep its other readout modes available.

In Point One, we will use `_ready()` again, this time to give a point a position.
