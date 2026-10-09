# Current intent: build the pickup, then a small level

Palle's correction, 2026-09-09: Melencolia leaves us with form, primitives, wedges, barriers, decoration and a grid. Introduce transformation by building the behaviour of a pickup cube, then place it in a small level. This replaces the paired-copy itinerary.

Four demonstrations at (4,2), (2,5), (2,8), (2,11): still; vertical oscillation; retain that and add rotation; retain both and add uniform mesh-scale oscillation. Existing pickup modes are still, slide, idle and all, each with hold:demo. No global pickup behaviour changes.

The only primary artifact is pick_up_cube. The first cube is centred on the entrance axis. Secondary markers stand at x4 beside the later demonstrations: y_translation_cube at z5, rotation_oscillation_cube at z8, uniform_scale_marker at z11. They make the operation readable without becoming extra stages. The translation shuttle and rotation rocking have different timing from the pickup; the book names that comparison. Four demonstrations lead to five collectible, fully animated pickups at row 18 on a one-metre-high platform. Three wedge lanes rise from z14.5 to z16.5; the platform spans z16.5 to z19.5; three descending lanes return to floor at z21.5. Entry and exit stay open within the museum frame.

The book follows this order. Repeating height does not reverse time; after collection, returning to a position does not restore the pickup. Other meanings of transformation can follow once this small example is understood.

Point_Line_Grid introduces a walkable five-by-five plan in a side room. This supplies a concrete placement grid before ramps and animated objects become a level.

Verification: 76 checks in probe_trans_pre_build_up.gd, including cumulative channels, persistent demonstrations, five collectible placements, ramp heights, capsule ascent/traversal/descent and all 25 plan cells. The museum capture also checks the plan's full scale and all 25 cell colliders. Headset experience and reader understanding remain to be tested together.
