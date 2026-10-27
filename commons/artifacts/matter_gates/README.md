# Matter / AND tabletop

Floor 7 and the canonical `matter_and` inventory recipe use a 1.8 × 0.85 m timber
top, 0.84 m above the floor, on two concrete supports. The original construction
vocabulary remains: cubes, wedge, planks, white gravity sphere and retained lever.
The running cubes are 12 cm models; the ball is a 3.36 cm marble. Buttons and the
lever grip retain hand-sized targets. Physics shapes have actual metre dimensions;
dynamic bodies are not scaled miniature parents.

The miniature frame stands behind the track. Two arms suspend the input cubes
without blocking the ball. Visible guide rods explain their constrained vertical
drop: rotation and horizontal movement are locked, with gravity driving Y.
Small timber curbs keep the marble centred on the fixed decks and stop at each
input opening. Each deck still has visible cube supports. A missing
input lets the marble fall onto the tabletop. Only its actual arrival at the
receiver records 1; the input flags never move the ball or fabricate success.
Gravity, friction and collisions remain active. The retained gate is constrained
by XR Tools, rather than a simulated rope or pulley.

Observe all four correct cases to emit the existing completion signal and earn
the reusable AND assembly. Reset preserves the earned inventory item. The same
catalogue supplies the tree, editor and player inventory; its footprint and
placement bounds now describe the tabletop. Existing named part anchors remain
editable, with new independent table/support parts.

`tools/run_matter_tabletop.py` tests the actual saved main floor, real desktop mouse
and supplied XR tracker input, hand release, physical truth table, moved/rotated
placement and isolated inventory reward. `tools/check_matter_tabletop_editor.cjs`
checks native GLBs and the shared editor save contract without saving test edits.
Synthetic XR is not a physical-headset test. Historical metre-scale Matter probes
describe the previous geometry and their dimensional assertions are superseded.
The lab editor also offers 1 cm and 5 cm snapping for assembling the small parts;
its existing default stays unchanged. The legacy trial's four saved part offsets
were converted to the new unit system, preserving their relative arrangement and
its independent copies.
