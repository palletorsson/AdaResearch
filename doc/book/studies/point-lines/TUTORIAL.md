# Point Lines — keep two ends in relation

In the black box, take one endpoint. The other stays where it is. Between them, the pale segment turns and changes length. The number on the wall follows.

Coordinates gave us two positions in the same frame. Here we use them together. Day Zero has already supplied the running project; Point One supplied the visible markers. The new work is a relation between their positions.

## Two positions, one distance

Open the supplied [line study](README.md). It contains A, B, a thin cylinder and a readout. This is a small desktop construction study. The museum keeps the XR pickup we borrowed in Coordinates; this download does not include that player.

In `line.gd`, A starts at `(-0.75, 1.12, 0.0)` and B at `(0.75, 1.12, 0.0)`. Their height and depth agree. Only X differs.

```gdscript
var displacement := b - a
var distance := displacement.length()
```

Subtract the start from the end: the displacement is `(1.5, 0, 0)`. Its length is `1.5`. We use one scene unit as one metre. Change B's X to `0.25`. The distance becomes one metre. You have changed one endpoint; the line and readout agree without editing either of them.

## Turn without lengthening

Keep A at its original position. Give B the position `Vector3(-0.75, 2.62, 0.0)`. The segment now stands upright. Its length is still 1.5 metres. Return B to its first position, then change its Z component instead. You have moved out of the first plane.

Reverse the subtraction to `a - b`. The direction reverses; the length does not. A distance alone cannot tell us which end we chose as the start.

## Read again as the endpoints move

Here is the complete lesson script in the download:

```gdscript
extends Node3D

func _ready() -> void:
    $A.position = Vector3(-0.75, 1.12, 0.0)
    $B.position = Vector3(0.75, 1.12, 0.0)

func _process(_delta: float) -> void:
    var a: Vector3 = $A.position
    var b: Vector3 = $B.position
    var displacement := b - a
    var distance := displacement.length()
    $Segment.show_between(a, b)
    $Readout.text = "%.2f m" % distance
```

`_ready()` places the two markers once. `_process()` reads their positions again each frame. While running in the editor, use the Remote scene tree to change B's position: both the segment and the number follow. This borrows the editor as our moving hand. In the museum, the grab system moves the endpoint instead. The relation needs the positions, whichever tool changes them.

`show_between()` is our supplied drawing helper, in `segment.gd`. It places the cylinder halfway between A and B, gives it their distance as its height, then turns its long axis towards B. Its thickness is a choice made for visibility. If both ends coincide, the helper hides the cylinder rather than trying to point it in an undefined direction. Its rotation code can stay borrowed for now.

`%.2f` rounds the readout to two decimal places. The underlying positions keep more precision. A hand can move without changing the displayed number.

## A connection can do something else

The next museum encounter asks **CAN YOU CONNECT THE DOTS?** Bring the points close and release. Their connection draws a line and breaks the nearby **DO NOT CROSS** barrier. The passage opens because an additional instruction connects those events. Distance alone cannot decide whether you are allowed through.

The hammer and laser use the same reversible break response. The laser reads the first body its ray reaches; holding its beam on a study for 1.2 seconds breaks that study. Eight seconds later it returns. We leave that pickup, collision and reset machinery in the supplied museum. Implementing it is not a prerequisite for making our first segment.

## What have the two ends left out?

Walk the black stripe, then take a detour. Compare the recorded trail with the straight line. The same starting and ending positions give the same displacement, however you travel between them. Our script replaces its reading every frame. It keeps no journey.

In the open room, two lines can make a plus or a cross; moving one away from the other reveals the depth hidden by the first view. In the exit corridor, those signs have been given different consequences: × damages, + restores. Their meanings are attachments to their geometry.

Keep the two positions, subtraction, length and the supplied segment renderer. In Trace, we will begin keeping the positions in between.
