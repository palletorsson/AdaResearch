# Trans_AxisDecomposition — field notes

> Field notes hold what the wall text cannot carry. `final.md` is for the
> visitor. This is for us.

## Exactness decisions

- **The tutorial's `reconstruct` flips z.** `Vector3.FORWARD` is (0,0,-1), so
  `RIGHT*cx + UP*cy + FORWARD*cz` returns (x, y, -z). Probe item 4 measured
  (2.5, -1.25, 0.75) → (2.5, -1.25, -0.75). The tutorial says "matches the
  original exactly"; the text now says decomposition is exact and
  reconstruction has to agree about the axes. The tutorial should be fixed
  (`Vector3.BACK * cz`, or say so).
- **One cube, gate 6.** One `pick_up_cube` is placed; the gate wants six on the
  running score (see Trans_Translation notes). The first draft said six cubes.
- **The room is mostly void**: rows 16–21 are all `0`; `cube_scene:0:3` and the
  axis cubes stand at y offsets over it. Transport cubes on three separate
  axes: `tc:3:z`, `tc:2:x`, `tc:4:y:auto`.
- **translation_cube_demo** default course `lift_lateral`: "up, then apart.
  Two freedoms, gated" (its own header).
- **toruscylinder**: torus rotates 0.5 rad/s, cylinder oscillates ±1.5 with a
  trail (exports).
- The `3t` text on the wall reads "Translation produces space as navigable
  extent" (map utilities r10 c3).
