# Point Zero — Already running

**Learning elements**

- Initialization
- Per-frame updates
- Function calls

This tutorial begins on the roof of the **Void Tower**. We learn selected operations from the works we encounter, then carry those operations into the next lesson. Alongside it, `final.md` follows Model B's particular encounter with the same place.

## A number that keeps changing

You begin inside a wooden delivery crate. Breaking its panel opens a view onto the roof, where a counter is already running. Its number changes as the engine processes frames. We will reconstruct the operation behind that display: create a label, then keep updating its text.

Use the working project from Day Zero. Its camera, light and player remain supplied. For this study, attach `counter.gd` to an empty `Node3D` named `CounterStudy`. Place that node where you can see it in your working scene, with its front facing your view. The script creates its own label; there is no child to prepare or fetch through a scene path. The rooftop counter is our reference; this study builds only the changing label.

Here is the **whole script**.

<!-- student-code:counter.gd -->
```gdscript
extends Node3D

var label: Label3D

func _ready() -> void:
    label = Label3D.new()
    label.text = "0"
    label.font_size = 96
    label.pixel_size = 0.005
    add_child(label)

func _process(_delta: float) -> void:
    label.text = str(Engine.get_process_frames())
```

`var label: Label3D` declares a reference that both functions can use. It does **not** create the label. `Label3D.new()` creates it; `add_child(label)` puts it beneath this node in the scene so its text can appear. The two size settings make the text large enough to read.

Godot calls `_ready()` when the node and its children are ready. Here it creates the label and gives it an initial text, `"0"`. That setup finishes before this node's first `_process()` call.

Godot then calls `_process()` each process frame. `Engine.get_process_frames()` returns the engine's running total; `str()` converts the number to text; `label.text =` replaces the displayed text. The supplied `_delta` is the frame's time interval in seconds. We do not use it: this example reads frames, not seconds.

Run it. The number advances. Its first visible value need not be zero—the engine was running before this label existed.

## Read it once

What would happen if we read the same total only in `_ready()`?

<!-- student-edit:read-once -->
Move `label.text = str(Engine.get_process_frames())` into `_ready()`, immediately after `add_child(label)`. Delete the now-empty `_process()` function. Keep everything else.
<!-- /student-edit:read-once -->

Run again. Look away and return. The number stays where it began, while the scene keeps running. The label now holds one reading. Your edit stopped updating the display; it did not stop the engine's count. Undo the move and the number follows the engine again.

The instruction is the same. Its place determines when it runs.

## From a reading to a position

On the roof, a coordinate grid crosses beneath the small black sphere at world origin. That `(0, 0, 0)` names a position. The label's initial `"0"` is text, soon replaced by a frame count. A starting display value and a spatial origin do different work.

Keep `counter.gd` with its per-frame update restored. In [Point One](../Point_One/tutorial.md), we carry forward `_ready()`, `.new()` and `add_child()`: create an object once, keep a reference to it, and attach it to the scene. There we will give a point a position, a visible surface and a collision shape. Its position will be measured relative to the new `PointStudy` node, just as the rooftop grid measures positions from the world's origin.


[Current counter.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Zero/counter.gd) · [Complete working project](../../../doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) · [Verification and changes](../../../doc/book/iterations/2026-10-06-starter-one-course/index.html)

[Complete experiment: counter_once.gd](../../../doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Zero/counter_once.gd)
