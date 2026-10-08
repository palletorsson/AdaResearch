# From source to skirt

Three primary placements: `fabric_shader_studio` (22,26), `super_drag_mirror` (31,27), `drag_catwalk` (58,24). The ordinary museum hall retains the fourteen earlier exhibits as secondary material. RotatingLaser moves from (58,39) to (58,50), with six-metre beams and a four-metre rig. Three older demos opt into `embedded:true`: no scene-wide environment or screen overlay; coloured-line paths are fitted together inside a three-unit source radius before animated sway and shader expansion.

## One recipe, explicit receivers

`fabric_recipe.gd` validates a versioned 4x4 array of palette indices (0..3), repeats (4/8), phase (0/0.125), cut-out, matte/metal finish, static displacement and UV inspection flags. It normalizes JSON numbers before making an RGBA8 nearest-filtered texture and a spatial ShaderMaterial. Both wall and skirt receive new materials from the same recipe, with their own UV coordinates. Repeats are per UV domain, not equal distances in metres.

The console supplies sixteen source cells, four paint choices and twelve pointer-operated actions. Editing updates only the wall and posed preview. SAVE writes `user://ada_studio_fabric_v1.json`; LOAD validates that file (maximum 16 KB). WEAR SAVED and RUNWAY SAVED read the file, not the current preview. Missing/invalid saved recipes leave recipients unchanged.

The garment adapter targets only the named `Skirt` mesh in SuperDragOutfit. It stores the recipe across `dress()` calls and retains the original skirt material for restoration. CostumeWardrobe persists the outfit and skirt recipe together in `user://super_drag_outfit.cfg`; progression data is untouched. Runway recipes are session-only. The mirror shares the live World3D and reflects the actual player geometry through its own SubViewport, with a head-centred rather than stereo-per-eye view.

## Rendering and movement are separate

The wall is a 3x2 metre subdivided QuadMesh with a full rectangular StaticBody collision. Fragment discard removes the last fifth of each horizontal repeat from drawing. Finish changes roughness (0.92/0.22) and metallic (0/0.85). Static vertex displacement is bounded by 0.04 local units along the original normals. CPU meshes, normals and collision are not rebuilt. This is not cloth physics; the skirt's existing UV seam/cap layout and mesh density remain visible limitations.

The studio keeps at most 32 undo entries. They restore edited recipes/look, the wearer's previous outfit/recipe, or each recipient performer's previous recipe. SAVE is not file-version history, and UNDO does not rewind the saved source file. Weak references tolerate a receiver disappearing when its hall unloads.

## Verification

`commons/testing/probe_fabric_studio.gd` loads the actual Ribbon_Patterns_03 museum, sends XRToolsPointerEvent presses/releases, validates source and shader changes, save round trips, garment-only assignment, isolated appearance persistence, undo, live mirror and walking performers. Tests redirect saves to `res://ada_run/probe-fabric-*`; they do not write the player's saved appearance. Desktop captures and the report are linked in the possible-bodies guide. Headset legibility, tracked-hand reach, stereo comfort and continuous gestures remain open.

## Journey-driven garment growth (21 September)

The wardrobe reads all 24 sequences from curriculum_spine.json. Completed sequences restore through the existing progression manager; the endless museum also grants one stage when the visitor enters a new sequence. A revisit cannot grant another stage. Arrival-based stages last within the current visit; no new visit-history save or completion credit is written. Desktop uses its walker wardrobe. VR uses the wardrobe whose costume follows the active origin's camera, so the menu rig cannot receive the visitor's growth.

The base walk dress adds a bounded tier. Selected super-drag looks now receive the same stage: their existing Skirt CylinderMesh lengthens from 0.50 to 0.90 m, while its waist stays at local y=-0.515. Its lower radius grows by a factor of 0.65 to 1.15 of the look's base radius. Pearl hem decorations follow that geometry. New arrivals ease towards their target over 1.4 seconds; waiting creates no additional stages. Quiet restoration and look switching apply the current stage directly. Preview and runway outfits retain their original dimensions unless explicitly given a growth stage.

Growth retains the worn Skirt node, mesh and material instance. The saved recipe and its UV repeat count remain unchanged, so the marks cover a changing physical extent. This is authored geometric growth, not cloth simulation, biological adaptation, new collision or a change to locomotion. The costume's chosen finish and the salon's hand-colour receivers are separate systems.

See the isolated production-code probe, actual rendered studies and manuscript diff in [the growing-dress review](../../../doc/book/iterations/2026-09-21-growing-dress/index.html). Physical headset comfort remains untested.
