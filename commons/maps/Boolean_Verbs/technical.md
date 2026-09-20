# Technical register · The Three Verbs

`Boolean_Verbs` is a 13×26 museum map with a continuous central walking lane and three raised sills. The authored interactables are one instance each of `csg_union_demo`, `csg_intersection_demo`, and `csg_difference_demo`, followed by `the_argument_of_solids` as a closing secondary exhibit. The map keeps the same box and sphere vocabulary across all three primary artifacts.

Each primary scene builds a `CSGCombiner3D` and assigns `operation` to `OPERATION_UNION`, `OPERATION_INTERSECTION`, or `OPERATION_SUBTRACTION`. The combiner re-derives a boundary from its operands; it does not expose a stored volume for later editing. Placement tokens use explicit axis values where a comparison needs a named rung, so the map remains readable by the museum compiler and by the book index.

The first primary sits at row 4, column 7; the second at row 12, column 7; the third at row 19, column 7. The closing argument sits at row 22, column 4. Utilities retain spawn, text, and the `Boolean_Gallery` exit link. `commons/data/artifact_roles.json` marks the three verbs `primary` and the closing argument `secondary`, matching the tutorial's order.

The technical check for this pass resolves every map token against the registry, confirms the three primary roles, and checks that the authored map dimensions and token coordinates remain unchanged while the register files are added.
