# Who becomes easy to address before anyone speaks?

**Learning elements**

- Spatial arrangements
- Comparison variables
- Participation conditions

The previous hall moved labels. Here positions, count and scale arrange possible participants.

<!-- @room_shape_demonstrator -->

Select HEAD, then CIRCLE, before choosing PAIR. Count every chair in each model. Compare the head chair with a side chair, then compare two chairs around the round table. Imagine a participant who needs a clear sightline to an interpreter.

The long-table model has a head chair and six smaller side chairs. The circle has six equally scaled chairs. Count, scale and position change between the plans; COLOUR restores the original red/green contrast; the pair is not an experiment that isolates table shape.

The source makes the operation inspectable:

```gdscript
for i in 6:
    var a: float = TAU * float(i) / 6.0
    var chair := _make_chair(chair_color_distributed)
    chair.scale = Vector3(s, s, s)
    chair.position = origin + Vector3(cos(a) * 0.4 * s, floor_y + 0.1 * s, sin(a) * 0.4 * s)
    _add_part(chair)
```

Six iterations divide a full turn, TAU, into equal angles. cos and sin place each chair on a ring around origin. The little circle carries the arrays, transformations and waves we have already learned. Equal spacing is what this loop guarantees. Equal opportunity to speak would require another kind of evidence.

[Implementation](../../../algorithms/postfoundationscrisis/room_shape_demonstrator.gd). This is an excerpt from the artifact, not a standalone program.

Press COLOUR while keeping PAIR selected. The chairs stay in place, but green now recommends the circle. NEUTRAL removes this colour contrast without changing the arrangement. Before accepting that judgement, consider sightlines, hearing, turning and entry. A shared centre can be useful without meeting every body's needs. Geometry sets conditions for participation; it does not contain the participants' agreements or resolve unequal authority. The next design should let those conditions be compared with people using the space.

<!-- @ -->

A place at the table does not make every account agree. The next hall keeps two accounts visible.

## Next experiment — with participants

Build a comparison with equal chair count, scale and colour, changing only the arrangement. Test sightlines and approach routes before claiming the circle is more accessible. Retain the original coloured pair as a comparison visitors can choose after inspecting each plan.
