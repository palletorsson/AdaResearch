# Late arrival — implementation

The native museum arrival remains governed by gravity and its existing arrival drop. The new open shaft surrounds that route without a cap. At map (7,1) it faces the frame counter at (7,4). Folding Past remains the configured lobby window. The origin at source cell (0,0) owns the Point zero beam label. Its offset (−0.5, +2, −0.5) cancels the cell-centre shift and two-metre basin seating, placing the marker at world (0,0,0) in the first museum hall. The restored glass-covered basin spans x/z −2..2, including the negative-coordinate entrance annex. Engine.get_process_frames counts process frames, not elapsed seconds or software revisions. Software change, inherited work and the death-drive question are distinct historical and critical registers in final.md.

## A number before our beginning

Watch `frame_counter_display`. Its default reading is a count, with the engine's start as its epoch. The installed panel reads `Engine.get_process_frames()`; it does not count seconds and offers no visitor stop button here.

The book first introduces a smaller example:

```gdscript
extends Node3D

var _count := 0

func _process(delta: float) -> void:
    _count += 1
```

Godot supplies the repeated calls. `_count` retains its value between them. `delta` is the interval supplied for this update; this example receives it without adding it. A count and an elapsed duration answer different questions. The panel's engine total also began before this local example would begin.

Through the entrance window, `folding_past` repeats ten frames. Its `frame_count`, `scale_ratio` and animation cycle arrange that recession. It records no visitor history. The museum creates this work through its configured lobby view, so an inventory that reads only the interactable cells will miss it.

Sources: [counter](../../visualaid/frame_counter/frame_counter_display.gd), [folding frames](../../primitives/temporal/animated_folding_past.gd), [museum lobby](../../scenes/endless_museum.gd).


## A spatial zero

The origin marker now owns the label “Point zero”, configured through its existing beam label. `Vector3.ZERO` specifies a coordinate-system origin; it does not reset the process counter. The existing removable “you” is retained beside that encounter.


## Hello-world making passage — 29 September 2026

tutorial.md supplies an executable first exercise after Day Zero. doc/book/studies/point-zero/hello_world.tscn inherits the unchanged base and adds Greeting and Counter Label3D children. hello_world.gd assigns the greeting in _ready(); a node-level integer begins at zero and increases in _process(_delta), which assigns str(count) to the counter.

The lesson checks a greeting-only script, repeated counting, moving the same update into _ready(), and incrementing by two. Readiness is the node's lifecycle event, not a declaration that the entire world has begun. The inherited base greeting is hidden, so its script produces no duplicate hello.

The production artifact still reads the engine's process-frame count by default. Its source _ready() builds the console and records its arrival reference; the tutorial borrows the display and simplifies the running count. It is not a reproduction of the artifact's shader, geometry or selectable reading/epoch system.

Frame counts are not elapsed seconds. Process callbacks are also not a guarantee that a particular image was presented to a headset. The lesson's evidence is native lifecycle and display-state behavior, not a headset or learner trial.
