# Technical register · When the Negative Gets Big

`Boolean_Works` is a 17×36 museum map. It contains eight authored interactable tokens: `csg_compose_workbench`, `subtraction_suite`, `sphere_splitting_showcase`, `recursive_boolean_cube`, `csg_architecture_cavity`, `boolean_burrow`, `sdf_cavern_room`, and `booleanvariations`, plus the retained `coincident_face` comparison. The map keeps an open central route between the workstations.

The book focus is two primary artifacts: `csg_compose_workbench` and `sdf_cavern_room`. The remaining bodies are secondary evidence, because the hall's claim is about scale and inhabitation rather than a complete catalogue. Roles are recorded in `commons/data/artifact_roles.json`.

The authored dimensions and placement rows are preserved. This pass adds the missing tutorial and critical registers without rewriting the geometry. The technical audit checks the 17×36 dimensions, eight unique authored tokens, primary-role alignment, register presence, and registry resolution with `tools/check_map_tokens.py`.

An interior requires both a visible boundary and a collision agreement. The map deliberately retains scenes where one or both systems are absent; their failure is part of the measured result.
