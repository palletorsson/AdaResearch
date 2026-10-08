# The order is in your hands

The large tower in VFM_07_Gravity now carries a miniature companion at local
`(0, 0, -3.7)`, inside its existing footprint. `stacking_table.tscn` is a component
of `tower.tscn`, instantiated by `encounter.gd`; it does not add another map token.

Nine loose shapes: three cubes, three rectangular bricks, two cylinders and the
familiar PointBody sphere. The initial centre stack is cube → cylinder → brick;
six alternatives wait on flat marks to either side. The table surface is 0.94 m
above the artifact origin; pieces are 8–30 cm across. Grip, move, rotate and let
go using the existing XRTools or museum desktop pickup. Marks do not snap or
constrain anything. Released pieces balance, slide and fall through Jolt contact.

The adjacent RESET restores only this table, and refuses while a piece is held.
The miniature does not remotely arrange the large tower. It is a comparison in
the same hall, not an extra required tutorial. Changing an arrangement changes
what the support can carry; there is no preferred or scored order.

`tools/probes/mini_stacking_table.gd` visits the actual museum, moves/rotates
shapes through a supplied XRTools controller, reverses the cube/cylinder order,
checks the released stack, desktop pickup and reset isolation. Evidence and
images: `doc/book/iterations/2026-10-07-mini-stacking-table/`. Physical headset
reach and grip comfort still need a visit.
