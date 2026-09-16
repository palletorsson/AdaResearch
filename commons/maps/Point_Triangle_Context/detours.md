# Return visits in Point_Triangle_Context

The [first passage](final.md) follows `triangle_line_puzzle` and `draw_triangle_faces`. The following works remain in the room. Choose a question to return with; these are extensions of the encounter, not prerequisites for reaching the next hall. Grid positions and roles are in [artifacts.md](artifacts.md).

## triangle

Move a corner toward the line through the other two. Compare the narrowing face with an edge-on view of an unchanged triangle. One changes the area; the other changes its projection. For three positions, half the length of `(b - a).cross(c - a)` gives triangle area. The calculation explains the distinction; it is not a promised live readout on this artifact.

Source: [triangle.gd](../../primitives/triangle/triangle.gd).

## interactivetriangle

Use its handles to change a face and compare the sides. Which distances changed with the vertex? This is an editor that moves positions. It does not resist the hand as three fixed rods would. Fixed side lengths constrain a nondegenerate triangle's shape; freely editable coordinates permit different lengths.

Source: [interactivetriangle.gd](../../primitives/interactivetriangle/interactivetriangle.gd).

## quad

Lift one corner out of the initial plane and inspect the two triangles meeting at the diagonal. Four corners need not share one plane. The chosen diagonal gives the patch a particular fold. This artifact has no installed diagonal-flip button; comparing the alternate diagonal is a useful later implementation exercise.

Source: [quad.gd](../../primitives/quad/quad.gd).

## quad_line_puzzle

Fit its four-edge target after the three-edge puzzle. Identify what makes the target a square rather than any closed quadrilateral. As a separate construction, four rods with hinges can lean while retaining side lengths; the installed endpoint puzzle does not simulate that linkage. Its current token does not request the old fillhole reveal described in the historical map summary.

Source: [quad_line_puzzle.gd](../../primitives/line/puzzles/quad_line_puzzle.gd).

## folded_strip

The installed study starts flat. Watch one shared edge become a hinge, return to flat, then watch paired folds gather the same twenty-four triangles. Follow an edge rather than only the silhouette. The rotations preserve its length.

Pick up a corner to pause the study. Moving it can now change edge lengths as well as angles. Release and the edit stays; let go of every handle before pressing REPLAY. This free edit and the programmed hinge rotation are different operations on the same connected source geometry.

Twenty-four strip triangles use twenty-six shared source positions. That does not promise only twenty-six submitted rendering vertices: colours and normals can require separate copies. The present study cycles through a 70-degree single hinge and 40-degree paired hinges over 48 seconds. These are configured values, not a visitor angle panel.

Source: [folded_strip.gd](../../primitives/folded_strip/folded_strip.gd).

## triangleprofiles

Follow a shared corner through the pleated profile, then move a handle and inspect the neighbouring faces. Ask which connections persist while the silhouette changes. The source also offers different finishes as configuration; the placed artifact does not supply a visitor slider for every appearance mode. A pleat can be studied as mesh geometry and desired as an ornament.

Source: [triangleprofiles.gd](../../primitives/triangleprofiles/triangleprofiles.gd).

## pythagorean_triangle_angles

Look at the squares grown from the sides. Find the right-angle condition before interpreting their area relationship. For a right triangle, the two leg-square areas sum to the hypotenuse-square area. Moving freely to another triangle does not make that equality a theorem about the new shape. Read what the geometry and numerical labels actually show rather than treating a printed formula as an enforced constraint.

Source: [pythagorean_triangle_angles.gd](../../primitives/triangle/pythagorean_triangle_angles.gd).

## pink_triangle

Stand before this triangle as a symbol. Its geometry cannot explain what happened to the people made to wear it or why others later chose it. Men imprisoned as homosexual offenders in Nazi concentration camps were typically marked with a pink triangle. [United States Holocaust Memorial Museum](https://encyclopedia.ushmm.org/content/en/article/gay-men-under-the-nazi-regime?series=200).

Gay activists reclaimed the symbol before the AIDS crisis. The Silence=Death Project's 1987 poster, subsequently used by ACT UP, carried a pink triangle on black. That history involves collective work and changing purposes, not a half-turn of geometry acting alone. [Wellcome Collection's poster record](https://wellcomecollection.org/works/d2mxjdkb).

The placed artifact holds still with its default point-up orientation. Its `inverted` setting is configuration, not an installed player button. A return visit can give the history its own attention without requiring the first construction lesson to contain it all.

Source: [pink_triangle.gd](../../primitives/pink_triangle/pink_triangle.gd).

## science_screen

Compare a visible object with what this nearby-data screen selects to display. Its source supports several modes and can lock a mode after discovery. The placement has no explicit mode binding; do not assume it mirrors the primary fan or diagnoses overspill. Confirm its actual selected subject in the running room before using it for a taught comparison. An explicit triangle binding is a possible follow-up, not part of this revision.

Source: [science_screen.gd](../../artifacts/science_screen/science_screen.gd).

## wireframe_threshold

Step into the ring, inspect the rendering, then step out. Its area requests a viewport debug mode and restores the prior mode after occupancy ends. This changes rendering, not the floor collider. Test the effect on the target renderer before teaching it as an all-surface view; the source records a prior Forward+ check, not universal headset support. This editorial pass does not repeat that rendering test.

Source: [wireframe_threshold.gd](../../artifacts/wireframe_threshold/wireframe_threshold.gd).

## silhouette_gate

Bring its drawing point to each target corner. The default task tests visits to checkpoints in any order, then opens its door. It does not validate the entire traced boundary or run the fan-filling algorithm. Compare what counts as “making a triangle” for a door-opening task with what counts for a filled mesh.

Source: [silhouette_gate.gd](../../artifacts/silhouette_gate/silhouette_gate.gd).

## fetish_portal

Look at the low-segment ring and its finish as a completed object. How much of the invitation comes from its shape, how much from its colour and sheen? A coarse surface can be an intentional object of desire. The placed token colours it pink. The default scene builds a triangular ring without the optional solid collider; its name does not promise teleportation.

Source: [fetish_portal.gd](../../artifacts/fetish_portal/fetish_portal.gd).

## A way back into the book

Choose one of these encounters and name its operation before extending the interpretation. What changed in the data, the rendering, the interaction or the use? Then return to the first distinction: a boundary, a visible face and a body that blocks or supports movement need not be the same construction.

Earlier versions of the room's texts are preserved [here](../../../doc/space/point-triangle-focus-2026-09-16/README.md). Their wider arguments remain research material; their old controls and placements should not override the current sources.
