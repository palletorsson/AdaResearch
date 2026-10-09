# Technical register · Where the Variants Stand

`Boolean_Gallery` is a 17×32 map with six four-cell bands. The interactables layer contains 24 authored placements: four each of `csg_difference_demo`, `csg_union_demo`, `csg_intersection_demo`, `subtraction_suite`, `coincident_face`, and `removal_room`. The central lane stays open between the left and right pairs in each band.

Placement tokens use the museum's axis syntax, for example `csg_union_demo:0:0#fusion:necked`. The suffix selects a declared enum value without changing the artifact scene. The map's utility layer preserves the spawn, intermediate text markers, and the `Boolean_Verbs` return/exit link.

Artifact roles deliberately narrow the book focus: `csg_difference_demo` and `removal_room` are primary; the other four families are secondary comparison material. This keeps the room's thesis legible while retaining the full six-family audit. The role map is stored in `commons/data/artifact_roles.json`.

The pass checks dimensions, six equal bands, four values per family, token resolution, role alignment, and presence of all four registers. It does not reorder the authored variants; that order is itself evidence.
