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
