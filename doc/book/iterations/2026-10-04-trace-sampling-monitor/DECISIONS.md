# One hand, three records

The Trace monitor films a private three-dimensional comparison of the gesture made with an existing Draw Dot pen. It observes the same writing tip and held-state that Draw Dot uses. It does not replace the pen, alter its settings, edit its trail or write to TraceData.

## Two different meanings of resolution

**Grain** compares a minimum displacement of 5, 20 and 80 mm from the previous accepted raw position. This matches Draw Dot's distance gate. It is neither a fixed samples-per-second rate nor equal spacing along the travelled curve. The monitor does not invent interpolated samples when a frame crosses a threshold. The three records have no grid snapping in this view.

**Grid** keeps the selected pen's sampling distance, captured when the gesture begins, and compares 10, 40 and 80 mm grid pitches. Each accepted position is snapped using the same component-wise rounding as Draw Dot. Consecutive duplicate positions are omitted. Near a whiteboard, projection, snapping and clamping happen in that board's frame, matching the pen's operation.

The white moving point and faint underlying path show the observed input. The coloured points and straight joins show the retained record. Joins connect samples; they do not recover movement between observations. All three displays use the same centre and scale, with world coordinates and metres retained in the source record. The private camera can orbit these spatial paths.

## Recording and looking

The monitor discovers Draw Dot objects in its own museum hall, or can be connected explicitly through `draw_dot_path`. The first actively held pen supplies the gesture. It stays with that pen until release; it never combines concurrent hands into one trace. A new pickup starts a fresh comparison.

Observation continues during the held gesture even while the visitor looks away. Only the filmed playback and rendering are gaze-gated. After release, the monitor replays the recorded timing, then holds the result before looping. The explicit Pause button remains authoritative. Each private record is capped at 4,096 observed positions; reaching that limit is labelled. The original Draw Dot record and its persistence are independent.

## Placement and preview

The monitor is registered as `trace_sampling_monitor` and placed in Point_Trace at map cell (1, 5), turned 90 degrees to face into the hall from its side wall. This leaves the three pen plinths and their readouts accessible. Its four controls were checked by rays from the front inside the real hall.

The active museum plan still contained an older four-pen arrangement. Only the Point_Trace row was re-derived from the current authored map, in both the live plan and its shipped fallback. Previous row snapshots and the map before this addition are saved here. No other hall was regenerated. The existing pen code, trace storage, tutorials and manuscript were not edited.

Desktop scene: `commons/artifacts/concept_monitor/trace_sampling_preview.tscn`.

- Hold Space and move the mouse to draw with the actual Draw Dot pen. Use the wheel while drawing to move in depth.
- Release Space to keep the gesture and watch its replay.
- Click Grain / Grid to compare the two operations.
- Right-drag looks away; Home returns. Left/right arrows orbit the filmed traces.
- D drives a clearly labelled demonstration gesture through the pen. It does not represent a captured human hand.

In the museum, use the existing pen's normal desktop or XR grab instead of the preview's Space shortcut.

## Evidence

`python tools/run_trace_sampling_monitor.py` drives a known spatial trajectory through an actual Draw Dot scene and compares each monitor output to the artifact's own output. All six comparisons match, including the retained count and positions. A separate rotated-board check verifies the projection and snap. Tests also cover stationary input, private buffer bounds, new-gesture separation, control isolation and actual museum placement.

The screenshots use that labelled test trajectory: 228, 93 and 26 kept positions in Grain; 207, 74 and 41 in Grid. They are Godot renders, not image-generated illustrations or headset recordings. Physical headset use and sustained headset performance still need testing.

The surrounding museum run reports existing material warnings and an entrance fallback warning for Point_Trace. Those are recorded in its log; this pass does not claim to repair them.
