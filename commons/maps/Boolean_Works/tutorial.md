# Tutorial · When the Negative Gets Big

**Learning elements**

- Architectural subtraction
- Shared transforms
- Collision and appearance

This is the scale test. In the first hall a subtraction made a cavity in a small solid. Here the negative is enlarged until it claims to be a room. Walk the hall in order and test that claim with your body.

Begin at the compose workbench. Five results turn above a table: union, intersection, both ordered differences and symmetric difference. Look for the promised handoff and notice what the scene actually affords. Then cross to the paired subtraction stations. Compare the cut and its material before you trust the word *same*.

The recursive cube is the hinge. Its holes resemble boolean subtraction, but the code never removes a volume; it declines to build selected cells. Between the visual wall and the SDF cavern, enter Boolean Burrow and return through the same opening. Its cylindrical cutters retain the old seeded centres but make the floor level. Compare the solid wall with the opening; collision is part of what makes that difference matter. At the architectural cavity and the SDF cavern, ask the practical question: where is the floor, and what collides with your body? A rendered hollow is not automatically an inhabitable hollow.

At the Boolean eggs, carry the three operations into a sculptural arrangement. The operands differ between specimens; this is not a controlled comparison of the verbs. In the teal egg, separate the geometric cut from the way its material presents depth.

For a small making exercise, duplicate `commons/artifacts/kapoor_void_studies/boolean_eggs.tscn` in the Day Zero project. In `_add_subtracted_egg`, change only `void_material.shading_mode` from `SHADING_MODE_UNSHADED` to `SHADING_MODE_PER_PIXEL`. Keep the camera, lights and cutter fixed. Compare the curved rim and the interior before touching the shape. The existing CSG construction and lighting are borrowed apparatus; this exercise changes one material decision.

Finish at the boolean variations and coincident face. The room has moved from verb to apparatus: a label, a camera, and a mesh can all claim an inside while the player remains outside it. The next sequence, swarm intelligence, changes the question from carving a body to coordinating many bodies.


<!-- study-spine:conical_sightline -->

## Return: One cut, three rooms

Translate the shared cutter 0.75 metres; keep the three walls. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses coordinates, transform, boolean. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`cut`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-matta-clark-one-cut/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-spine:kapoor_void_studies -->

## Return: The surface that says depth

Change the cavity from unlit black to lit chalk; keep its geometry. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses boolean, shader. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`void`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Earlier study and making notes](/book-review/doc/book/iterations/2026-10-01-kapoor-surface-and-depth/index.html). Geometry controls wait until the exhibit is clear. RESET returns the original comparison.


<!-- study-edit:conical_sightline -->

### One source change: One cut, three rooms

The SHIFT CUT control uses this setter. Try 0.35 metres instead; all six cutter instances share the same offset, including the retained intersections.

```gdscript
set_cut_x(0.75)
```

Source: `commons/artifacts/conical_sightline/conical_sightline.gd`. Use the prepared scene to run and compare.

<!-- study-edit:kapoor_void_studies -->

### One source change: The surface that says depth

The BLACK / CHALK control calls this setter. Compare from one fixed position. It replaces materials without rebuilding the bowl mesh.

```gdscript
set_black_surface(false)
```

Source: `commons/artifacts/kapoor_void_studies/kapoor_void_studies.gd`. Use the prepared scene to run and compare.
