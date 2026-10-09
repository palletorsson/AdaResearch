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
