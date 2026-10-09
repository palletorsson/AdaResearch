# Point Zero — Already running

**Learning elements**

- Initialization
- Per-frame updates
- Function calls

This tutorial follows a path through **Endless Museum**. We learn selected operations from the works we encounter. Alongside it, `final.md` follows their critical and poetic questions. Some artifacts belong to both tracks; others remain part of the wider field we explore.

## A number that keeps changing

In Point Zero, the counter is already running. Its number changes as the engine processes frames. We will make the smallest working version of that operation: create a label, then keep updating its text.

Use the working project from Day Zero. Its camera, light and player remain supplied. For this study, attach `counter.gd` to an empty `Node3D` named `CounterStudy`. Place that node where you can see it in your working scene, with its front facing your view. The script creates its own label; there is no child to prepare or fetch through a scene path. The existing museum console is the reference for this study.

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

Replace the script with this complete version. Creation stays in `_ready()`. The reading moves there too, and `_process()` is removed.

<!-- student-code:counter_once.gd -->
```gdscript
extends Node3D

var label: Label3D

func _ready() -> void:
    label = Label3D.new()
    label.text = "0"
    label.font_size = 96
    label.pixel_size = 0.005
    add_child(label)
    label.text = str(Engine.get_process_frames())
```

Run again. The number stays where it began, while the room keeps running. The label now holds one reading. Restore the first script and the number follows the engine again.

The instruction is the same. Its place determines when it runs. In Point One, `_ready()` will construct a point's visible body.

[Download the running version](../../../doc/book/iterations/2026-10-05-point-zero-complete-example/counter.gd) · [Download the once-only version](../../../doc/book/iterations/2026-10-05-point-zero-complete-example/counter_once.gd)
