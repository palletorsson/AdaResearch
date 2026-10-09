# A cube that moves, turns and grows

**Learning elements**

- Translation: changing position
- Rotation: changing orientation
- Uniform scale: changing size
- Elapsed time and a returning fraction
- Collection: overlap detection and a signal

In Trans_Pre, one cube rises. The next rises and turns. Another adds a pulse in size. Follow one corner: each example keeps the earlier movement and adds another operation.

We continue with the cube shape from Primitives. Here Godot's `BoxMesh` supplies it; we change the whole object's transform. The construction of faces has already done its work. This lesson makes one animated pickup that you collect by walking into it.

## The complete study

The Endless Museum is already running. Its room, light, camera and player are supplied. Put an empty `Node3D` named `TransformStudy` in clear floor space beside the exhibits and attach `lesson.gd`. Use floor level as its origin, zero rotation and unit scale. Each coordinate below is in this study's local frame. The script creates every part of the pickup.

Read the complete result once, then use the small edits below to build up its behaviour.

{{CODE}}

`BoxMesh.new()` describes a one-metre cube centred on its origin. The `MeshInstance3D` holds its position, orientation and size. The same mesh remains throughout.

## Add one movement at a time

First set `turn_speed` and `pulse` to `0.0`. Keep `rise` at `0.35`. The cube moves 35 centimetres above and below `start`, keeping its size and facing.

`elapsed += delta` counts seconds. `pingpong` makes `t` travel between zero and one at a steady rate, reversing at each end. The factor `2.0 / period` gives one outward-and-return journey per period. Adding `0.5` starts halfway up, moving upward. With `period = 4.0`, `t` is 0.5 at the start, 1 after a second, 0.5 after two, 0 after three, and 0.5 after four.

`lerpf(-rise, rise, t)` chooses a height offset between the lower and upper limits. At `t = 0.5` it gives zero: the cube is back at `start`. This is the steady rise and fall of the museum example. It changes direction immediately at the ends; a softened turn would be a different timing choice.

Restore `turn_speed` to `45.0`. The cube now rises **and** turns 45 degrees per second around Y. Its mesh has not changed. After eight seconds it completes one turn.

Restore `pulse` to `0.2`. The second `lerpf` now chooses a size factor between `0.8` and `1.2`. Multiplying `Vector3.ONE` gives all three axes the same factor, so the cube keeps its proportions. Rise and pulse share the returning fraction; the turn continues at its own steady rate. The assertion keeps the period positive and prevents the pulse from collapsing the cube to zero size. The installed specimen uses a larger pulse, from 0.7 to 1.3; this study keeps the same operation with a smaller range.

Each update assigns a pose from the starting values and elapsed time. Adding that whole pose repeatedly would make the cube drift. `elapsed` is kept between updates; `t` is calculated afresh from that clock, and the three transform properties are assigned from those values.

## Walk into it

An `Area3D` detects overlap. Its `BoxShape3D` describes the detection box; it does not provide a solid wall. Because the area belongs to the cube, the box follows its movement, turning and uniform scale.

`body_entered` is a signal announcing that a physics body entered the area. `connect` names the function to call. The museum supplies the desktop walker in group `em_walker` on layer 1, and the XR body in group `player_body` on layer 20. The mask listens to both layers; the group check accepts the player. These are the declared connections to the existing museum.

Walk into the cube. `queue_free()` removes the study at the end of the frame, and Output prints `Collected`. A passing ordinary prop does not collect it. The installed pickup's score and flourish remain outside this small reconstruction.

## Make another version

Set `period` to `8.0`. Predict which movements slow down. The rise and pulse take twice as long; the turn still advances at 45 degrees per second. Explain why. Then choose a different rise while preserving the cube's proportions.

Carry these three operations into the next hall. There, a transformed surface offers somewhere to stand.
