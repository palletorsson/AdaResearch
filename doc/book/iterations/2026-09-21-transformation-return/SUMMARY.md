# Transformation: what survives the turn?

21 September 2026. Applied after the author accepted the [Claude feedback assessment](../../review-feedback/2026-09-21/transformation/DECISIONS.md). [Read the chapter comparisons and actual museum images](index.html).

## Decision

Keep the mature seven-hall arc. Reduce implementation bookkeeping where it interrupts looking and moving. Restore an existing encounter when it gives a strong question something to work through. This is a light editorial pass with one placement, not a redesign of Transformation.

- **Trans_Pre:** retain the opening from Melencolia and all cube demonstrations. Its closing now names what translation, rotation and uniform scale preserve, then asks which changes can give the visitor somewhere to stand.
- **Trans_Introduction:** preserved in full. No crab restored.
- **Trans_Translation:** replace the deck/socket setup inventory with the relation between coordinates and usable floor. Existing technical material retains setup details. Rides, attention and permissions remain.
- **Trans_Rotation:** place the existing `axial_sweep` at source cell (14,39), after the arrays and before the tunnel. It becomes the third primary encounter. The new passage follows the turning cube, its cylindrical outer boundary, and the triangular face whose turn describes a cone. Remove the old production-status footnote with its localhost link. All earlier works and the five carousel profiles remain.
- **Trans_Scale:** change one heading level only. Preserve Alice, the instantaneous room-scale change and the witness frame.
- **Trans_Body:** preserved in full.
- **Trans_Pit:** shorten exact travel-time inventories and repeated operation descriptions. Preserve different pusher rhythms, the shared grower clock, bodily clearance, the argument about insufficiency and the complete final airlock passage. Change “matrices” to “transformations” in that argument. The moved implementation details are in [the encounter reference](/book-review/commons/maps/Trans_Pit/encounter-reference.md).

The larger four-drum `transformation_sampling` study remains in its separate research scene. The compact axial study earns this placement without expanding the hall or moving its other works. Its source is unchanged: the plate is at 1.7 m, the motion begins with the boundary hidden, and its existing shape, pause and boundary controls remain. The optional boundary is a guide, not a new solid wall or proof of perceptual fusion.

## Evidence

[Runtime results](museum-runtime.json): fourteen controlled assertions passed in the actual generated museum hall. They cover the nested artifact's presence and scale, continuing rotation, actual pointer-button events for pause/boundary/shape, contour geometry and absence of solid collision in the rotating geometry/guide. Seven connected walking segments passed, approaching from the arrays, going around the study and proceeding to the tunnel. The walker was positioned once at the start; museum input and catch logic were paused for controlled locomotion. This does not claim complete gameplay acceptance, headset reach, comfort, Quest performance or learner understanding.

Four actual Godot images were saved. The comparison page uses the inspected cube-boundary, triangle-boundary and museum-context views. The rendered process exited 0. No live game restart, live bake replacement, visitor-save change or commit was performed.

[Content checks](content-checks.json): 58 preservation, placement and manuscript checks passed. All previous map layers are identical except the one new artifact cell. Unrelated role/core records remain unchanged; the five changed chapters' hashes and primary markers match the current registry. Introduction, Body, six other Transformation maps, the sequence order, all three relevant artifact scripts and the frozen Claude book export match their preserved hashes.

The first probe used the museum's edit-record inventory, which stops at the nested simulation grid, and consequently failed to find the study. Its output is retained under `first-inventory-*`. The corrected probe inspects the actual nested scene descendants. No placement or game-code change was needed for that correction.

## Open runtime issue

The passing run also logged `GridSystem._update_player_bounds` calling `find_child` on null at `commons/grid/GridSystem.gd:508`, during nested grid generation. The museum has its own walker and the study/walking checks passed, but this is not an error-free startup. A focused follow-up is to guard the missing grid-local player in nested museum builds. This unrelated engine repair is outside the accepted editorial/placement pass.

Other startup notices include an unresolved UID, renderer/environment notices, empty auxiliary registry notices, and an unrelated dressing-build timing notice. Full logs are retained in [museum-engine.log](museum-engine.log) and [museum-process.log](museum-process.log).

## Next

Continue to Arrays: the cube introduced in Transformation is now kept in an addressable collection. Read the current opening and the recent array/tiling changes before deciding what needs attention. Preserve settled work and use the outside review where it identifies a particular gap. The parked Collective Knowledge work and frozen full-book snapshot remain untouched.
