# Colour joins the primitives

17 September 2026. User direction: the opening Color hall should combine familiar primitives and static transformations in a long column gallery; the subsequent halls investigate what colour is.

## Result

- A 23 x 43 m hall, 15 placed study instances, 27 physical columns and a clear central aisle.
- Four studies: colour assignments on identical geometry; different primitive alphabets; fixed Y turns, XZ narrowing and their combination; translations with colour kept, calculated from displacement or assigned by copy index.
- Two primary families: chroma_stack and chroma_translation. Book hero, primary order, core-encounter record and chapter prose agree.
- Spawn moved to (11,2), facing increasing Z; one exit at (11,40). Plates face the entrance. Internal floor obstructions and the crowded rear collection are removed from this version, with the full previous map and texts preserved in before/.
- The new pose axis on chroma_stack is static. The default aligned pose preserves old behaviour. Mesh and collision use the same yaw and horizontal scale; level heights remain constant.
- The opening final.md carries primitives and transformations into colour. Flashlight's handoff now explicitly refers to colour assigned to forms and positions.
- Filter, drum and Life passages remain accepted research material in the archived draft. The former placement brief is superseded: these are no longer pending additions to the opening hall. No artifact implementation was deleted.

## Validation

199 checks passed in the actual endless-museum hall using Godot 4.6 and the compatibility renderer. Verified all 15 instances, 27 columns, the four configured poses, shared mesh/collider transforms, plates facing the entrance, a supporting entrance floor, a 0.5 m wide / 1.6 m high test body's full central route, approach to every plate and circulation around each single column. See runtime-checks.json and probe_color_column_hall.gd.

The map pathfinder returned 1 OK, 0 FAIL. It warns that the standalone teleporter cell is supported at height 1 instead of its preferred void. The supported floor is intentional here, and the museum disarms embedded exits; the measured aisle stays on continuous floor. No global teleport rule was changed.

Entrance, static-transform, translated-column and overhead captures were rendered from the museum and visually checked. No headset comfort, controller reach or frame-time claim is made. Startup diagnostics remain in runtime/render logs.

The primary-room data was also read through the same Python provider used by the necklace page: exactly chroma_stack followed by chroma_translation. Unrelated room records were compared with the before-snapshots and preserved.

## Review

- index.html: rendered hall views and the progression.
- placement-change.json: previous and current placements.
- before/: prior map, manuscript, registry and role/book records.
- revision.json: current source hashes and validation scope.

The full spine order is unchanged. Other Color halls retain their existing encounters. Further work can give the archived Albers, filter, drum and Life material specific homes where each advances the next investigation.
