# Arrange — implementation and encounter

The primary artifact is `room_shape_demonstrator`. Its [scene](../../../algorithms/postfoundationscrisis/room_shape_demonstrator.tscn) and [implementation](../../../algorithms/postfoundationscrisis/room_shape_demonstrator.gd) supply the behaviour described here.

The placed default is plan=pair. _build_centralized_room() creates a separate head chair plus a nested 3-by-2 loop of chairs at scale 0.6*s. _build_distributed_room() creates six chairs at scale s. Other implemented author configurations are head, circle, panopticon and vacant. They are map/editor parameters, not visitor buttons in this placement. This primary exhibit is a passive miniature; it runs no classifier or turn-taking simulation.

## Operation to read after the encounter

```gdscript
for i in 6:
    var a: float = TAU * float(i) / 6.0
    var chair := _make_chair(chair_color_distributed)
    chair.scale = Vector3(s, s, s)
    chair.position = origin + Vector3(cos(a) * 0.4 * s, floor_y + 0.1 * s, sin(a) * 0.4 * s)
    _add_part(chair)
```

Six iterations divide a full turn, TAU, into equal angles. cos and sin place each chair on a ring around origin. The little circle carries the arrays, transformations and waves we have already learned. Equal spacing is what this loop guarantees. Equal opportunity to speak would require another kind of evidence.

## What to compare

Walk around the paired miniature rooms. Count every chair in each. Compare the head chair with a side chair, then compare two chairs around the round table. Imagine a participant who needs a clear sightline to an interpreter.

The long-table model has a head chair and six smaller side chairs. The circle has six equally scaled chairs. Count, scale, colour and position change together; the pair is not an experiment that isolates table shape.

## Limits and next test

Build a comparison with equal chair count, scale and colour, changing only the arrangement. Test sightlines and approach routes before claiming the circle is more accessible. Keep the present pair as the openly persuasive first example.

This source audit does not establish headset readability, comfortable reach, collision clearance or frame rate. Those remain runtime observations. Existing supporting artifacts stay in the map; primary status identifies the book's encounter, not the only permitted content.

[Earlier design proposal](../../../doc/space/postcrisis-pass-2026-09-15/before/commons/maps/CriticalAlgorithms_Applied_Ethics/technical.md) preserves the previous text and its proposed systems. It is not a description of the current implementation.
