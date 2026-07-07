Concept: A cloth grid pinned along its entire top row hangs under gravity as a flat curtain rather than as a catenary. The map is a gallery study presenting one pin-pattern variant; the player walks around the single soft-body marker.

Sequence role: Second cloth-drape study (sb02) in the imported soft-body gallery cluster within the Soft Bodies sequence (13th spine, integration phase). Companion to sb01 (two corners), sb03 (single side edge), and sb04 (tablecloth). Together the four argue that pin topology — not material parameters — is what determines drape signature when the rest of the spring-mass system is held constant.

Technical angle: Spring-mass cloth with structural and shear constraints between adjacent vertices. Top row of vertices fixed to world position; all other vertices integrate freely under gravity with damping. Verlet or position-based dynamics. The flat-hang shape is the steady state because the constraint is a line rather than two points — every potential lateral curve in the middle is suppressed by the rigid row above. Slight side curl at the edges is a finite-grid artifact: the outermost columns have no neighbor on one side, so their structural springs pull inward unopposed.

Critical angle: Sb01 stages the catenary as emergence-from-constraint. Sb02 stages the absence of emergence: pin enough boundary and the shape goes flat. The pair frames the same point from opposite sides — form is determined by where the boundary is allowed to release. Engineering knows this as "degrees of freedom." The cloth knows it as which directions it can fall.

Key artifacts: gallery_marker_soft-body holds the sb02_cloth_drape_top_row configuration as the room's centerpiece; the curtain is the artifact and the demonstration in one piece.

Gap: A pin-pattern overlay artifact would render the constraint set visibly (red dots on pinned vertices, white on free ones) so learners could see the boundary condition without needing to read the JSON. The same overlay would generalize across all four cloth variants.
