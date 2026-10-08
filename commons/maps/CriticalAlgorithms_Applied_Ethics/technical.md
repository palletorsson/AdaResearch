# Arrange — choose a plan, then examine its terms

The previous hall moved word positions. Here an array gives possible participants positions. The source is [room_shape_demonstrator.gd](../../../algorithms/postfoundationscrisis/room_shape_demonstrator.gd).

This map opts into interactive=true, plan=head and palette=neutral. HEAD and CIRCLE show one miniature at 1.5 times the paired model scale. PAIR returns to the original side-by-side comparison. WATCH selects the existing panopticon plan: the long-table model beside a ring of eight outward-facing backed seats and a taller central block. VACANT removes the furniture from both rectangular rooms. These remain miniature studies, not full-size occupied meeting rooms.

```gdscript
for i in 6:
    var a: float = TAU * float(i) / 6.0
    var chair := _make_chair(chair_color_distributed)
    chair.scale = Vector3(s, s, s)
    chair.position = origin + Vector3(cos(a) * 0.4 * s, floor_y + 0.1 * s, sin(a) * 0.4 * s)
    _add_part(chair)
```

Six iterations divide a full turn, TAU, into equal angles. cos and sin place each chair on a ring around origin. The little circle carries the arrays, transformations and waves we have already learned. Equal spacing is what this loop guarantees. Equal opportunity to speak would require another kind of evidence.

The long-table model contains seven chairs: one at scale s and six at 0.6*s. The circle contains six at scale s. The WATCH pair contains seven plus nine; VACANT contains none. Chair count, scale and geometry therefore vary across the plans. The console presents choices, not an isolated test of table shape.

NEUTRAL and COLOUR are separate from PLAN. The palette applies a shared material colour or restores the original red/tan/green scheme without changing any chair transform. Neutral colour does not make the arrangement itself neutral. The unconfigured scene retains plan=pair, palette=authored and no visitor console, preserving other placements.

The compact panel remains outside the rebuild list. Only the model's own parts are replaced, so the controls and externally attached labels survive. Interactive pedestals have box collisions. The panopticon wall segments now follow the circle's tangent; their former radial orientation left a ring of fins.

The hall retains its six artifact families. The primary moves to (6,5), faces the entry and reserves space for both model widths. The arrival gate stays at the boundary; a local clear rectangle keeps a decorative plinth off the exit approach. The authored structure layer is preserved.

Compare actual sightlines and turn-taking with people in a later experiment. These models contain neither a speaking process nor measured accessibility. The next hall keeps conflicting requirements visible after participants have found a place.
