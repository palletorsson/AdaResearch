# Batch 17 / coordinator review

Codex transferred Pattern Foundry (17 placements). Claude Opus delivered Tutorial Pattern (12 placements) and its dependency review. All 29 source IDs, scenes, scales, yaws and token configs are retained on two standard 42 x 32 m floors with six-metre storeys. Curation and chapter texts are deferred.

## Claude review

Claude's complete floor fragment is preserved in floor-2.json. The integrated rooms.json raises Studio Plate by 0.85 m: its source origin is above part of its geometry, so nonnegative token height alone did not guarantee clearance. Its measured underside was 0.82 m below the slab. The remaining placement positions/yaws/configs are retained from Claude.

His grid_model and panel-bridge dependency findings were verified in source and addressed in Void adapters. All three bare p4m flags are retained as {"p4m":"true"}, matching the original grid parser. The original mirror alias uses registry repeat_mode 3, not the scene's default 0.

## Integration

- Pattern tile aliases receive their original registry defaults before ready. Both Void hands use XRTools; the original cube pickup handler unfreezes carried cubes, so a local listener keeps them frozen while the grab driver moves them. Palette detection includes pickup layer 3. Original snapping, colours and repeat calculations remain.
- Dress the Architecture receives the current Void floor and pillar faces instead of searching for a missing SimGrid ancestor. The skins are fixed to the structure and omit both shafts. The four original machine textures and all controls remain.
- Grid Model keeps its original miniature, array panel, spawner cubes and grab/stack logic. A floor-local facade supplies the Void's one-metre grid. Fixed slab, pillars and shafts are protected; spawner cubes add actual metre supports, and those added supports can be moved/removed. These are runtime edits and reset with the floor, as in the original play interaction. They do not write a new editor layout. No global grid_system is introduced. Half-cell shaft boundaries are conservatively protected on the metre grid.
- The loom's shafts:8 token selects its original complete eight-shaft overshot example. The standalone capture-data path previously emptied the draft and called look_at before parenting a camera. The Void adapter uses the existing example loader and suppresses the standalone HUD/R shortcut; the original three 3D panels remain.

The loom builds the selected example once: replacing a just-created default set before its viewport injection finished retained old draft resources. Miniature cube replacement waits 0.6 seconds after release so XRTools can finish its hand-collision cleanup while the released rigid body's RID still exists.

## Fit and presentation

No floor enlargement, added walls or omissions. Foundry's three documented mount lifts and Tutorial's Studio Plate lift expose the controls above the slab. The source recipe-study wall skins remain floating samples because the old room walls are not transferred. Arrangement, circulation, lighting refinement and tiny-control usability remain curation work.

Native acceptance, export and editor-save receipts are in evidence. Physical-headset testing is pending. Web GLBs are static geometry snapshots; live pattern textures, animations and manipulation run in Godot. Focused tests are not exhaustive interaction coverage.

## Verified receipts

147 source checks, 227 native checks and 32 editor checks passed. Native exit 0; no script or engine errors. Mouse and synthetic tracked-XR pickup/drop, miniature-to-world support, fixed motif buttons, recipe and architecture controls, drawing squares, runway pause, shafts, streaming and retry were exercised. Grid protections also have explicitly labelled API checks. No measured artifact bounds exceed the slab footprint or intersect either shaft footprint; all measured vertical bounds now fit.

64 GLBs exported with no failures. The editor loaded 17 Foundry and 12 Tutorial artifact entries plus fixed structure, with per-object position/rotation controls. The reversible real save test reached the native layout and Desktop mirror, rejected a stale revision, then restored the layout. Browser screenshots are editor-foundry.png and editor-tutorial.png; four numbered screenshots are native Godot. Source pending-timer shutdown warning remains; physical headset play and curation are pending.
