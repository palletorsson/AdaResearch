# Point Lines — implementation reference

The beginner exercise is [tutorial.md](tutorial.md). This file records the hall’s working attachments.

## Segment and connection

`commons/artifacts/line_black_box/line_black_box.gd` builds the entrance, two held endpoints, a live readout and a reset. It uses `commons/primitives/line/line.gd` to draw their segment. `LineStudy` is the breakable target; the box, approach and reset remain outside that target.

`commons/primitives/snappoint/demos/line_demo.gd` listens to `SnapConnectionManager.connection_created`, recognises its own two points, and finds the nearest unbroken `DoNotCrossBarrier` in the same hall. The callback is deferred out of the physics flush. Disconnecting rearms the demonstration, so a rebuilt barrier can be opened again.

The barrier's visible body and collision boundary are suspended together by the shared reaction component. Restoration checks player occupancy before restoring physical collision. Its old permanent-destruction fallback remains for placements without a reaction component.

## A tool that reaches the study

Explicit `#reactive:break#rebuild:8` placements use `commons/interactables/artifact_reactions/router.gd` and `reaction.gd`. Tool-only surface proxies occupy physics layer 24; the original pickup and player shapes remain. The gallery exposes separate rods and fixed mesh studies. A strike does not erase all four views.

`laser_measure` raycasts bodies, reports the first hit, and accumulates 1.2 seconds of dwell on one target. An opt-in reaction requires a held laser. Desktop carry uses `desktop_hook_target` and grab/drop callbacks; XR uses the existing `is_picked_up()` state. Looking away or dropping cancels accumulated dwell. A placed instrument continues measuring.

The hammer takes three accepted strikes; the pink gun and catalyst tint. Breaks disable visibility, processing and collision, then restore the same instance after eight seconds. Architecture, reset controls and health services are kept usable.

## The exit corridor

Map cells x=12, z=29..34 hold × + × + × +. Their trigger depths are 0.42 m, separated by one-metre centres, so a body encounters them in order. `#passage:1` opts into corridor behavior without changing ordinary pickups elsewhere.

X composes DangerZone and accepts both the museum Walker and XR bodies. It takes 7 health on entry, then 14 every 0.6 seconds while occupied. This uses GameManager's direct damage operation: the generic museum route converts damage into a shared 33-point creature bite and can suppress the next gate with its cooldown. The passage keeps its own timing and uses the existing damage flash and health beep.

+ offers up to 21 health whenever the visitor is below full. It remains if no recovery can be delivered. A taken plus emits a generated spatial chime and twelve expanding strokes, and returns after eight seconds. No imported sound file or new audio service is needed.

## Portable construction

`doc/book/studies/point-lines/line.gd` places two markers once and reads them each frame. `segment.gd` owns cylinder length, midpoint and local-Y alignment; coincident endpoints hide the cylinder. Every node used by the lesson is supplied in `line.tscn` or the Day Zero base. It includes no XR rig.
