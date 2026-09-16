# One rule, two surfaces

This is the opening Patterns hall, after Colour. Its three book encounters are `pattern_tile_4x4`, `pattern_tile_mirror` and `pattern_machine_a`. The remaining machines and dressing exhibits stay as supporting material.

The first two encounters separate a finite source motif from its repeated and reflected results. The loom then separates that source from the shape receiving it. Its optional `#lesson:shared_recipe` configuration starts with a deterministic 5 × 5 card under p1 and adds the specimen bench. Other loom placements retain their existing configuration.

## Live comparison

`recipe_study.gd` samples the resolved card with `WallpaperGroups.get_symmetric_color`. Each specimen gets a 120 × 120 nearest-filtered image at 100 pixels per metre: initially four source-card periods per direction under p1. The two 1.2 × 1.2 metre sheets share UV addresses; the curved one is a 48-segment half-cylinder with a 1.2 metre arc. Only vertex positions and normals change between carriers. Each receiver owns its material.

The reachable console offers MARK, SAVE, RESTORE, LINK / HOLD, TARGET, UNDO LINK, REPEAT SIZE and OFFSET +5CM. MARK edits card cell (1,2); the original loom pegs and GROUP control remain available. Updates follow `recipe_changed`, not a per-frame texture rebuild. TARGET cycles CURVE, WALL, FLAT, ALL FIVE, ARCHITECTURE, NORTH and EAST. ARCHITECTURE is exactly WALL + NORTH + EAST; ALL FIVE also includes both specimens. It selects the recipients of LINK / HOLD, not the scope of source edits or saving. Each receiving surface has a mounted label; selection changes its label colour. The loom, carpet and museum continue when a receiver is held. There is no per-copy exception editor.

## An architectural receiver

A 4.8 by 0.9 metre material skin sits 1 cm in front of the existing inner wall at grid x=4.5, centred at z=20.1. It adds no collider and changes no shared grid material. The 480 by 90 pixel field is sampled directly from the same rule as the specimen images. At the initial 30 cm setting under p1 it contains sixteen by three card periods. The larger field is not a stretched thumbnail. The sampling density also stays fixed for other groups; their operation may change the visual period.

The receiver dictionary explicitly registers five owned meshes, metre dimensions and link states. Unregistered meshes, labels, carpet and other artifacts receive no material changes. A source update renders each required image size once and delivers it only to linked receivers. No textures rebuild merely because selection changes or time passes.

LINK / HOLD holds a fully live selection; a held or mixed selection becomes live. Re-linking catches up to the current source. UNDO LINK keeps up to sixteen receiver transactions: restored held links recover their old image; restored live links receive the current source. Undo does not rewind source edits or museum time. The held receiver state and undo history remain local to this visit and are not part of the saved loom recipe.

Two more skins extend this architectural scope. NORTH is 4.8 by 0.9 metres at grid (7, 13.51), facing into the bay from its existing northern wall. EAST is 1.8 by 0.9 metres at (12.51, 16.5), facing east from the clear side of the existing grid block. Each owns its material and mounted state label. Collision rays at three positions across each skin confirm existing support within 1 cm. They add no new wall or collision. A sculpture-clearance rectangle at grid x=13–16, z=15–18 reserves the east approach from automatic decoration. Both new faces have a checked one-metre standing approach.

Scope selection uses an explicit list of registered IDs, so a grouped link transaction preserves individual membership and held images. Undoing a group relink can recover an EAST-held / NORTH-live / WALL-live mixture. Equal-size skins share an image on update, while retaining independent material and subscription state. Surface coordinates restart on each face; this is not a continuous pattern unwrapped around corners.

## Repeat spacing

REPEAT SIZE cycles 30 → 60 → 15 → 30 centimetres per source-card span. It changes a shared `repeat_metres` value, leaving the resolved card, palette, group, band history and physical geometry unchanged. The historical carpet retains its own fixed display spacing.

At each render pixel centre, the surface coordinate in metres is multiplied by `card_size / repeat_metres` and floored to obtain the source address. The receiving image resolution stays fixed. This permits a surface edge to end inside a source cell without rounding the physical repeat size to fit an integer image width. For this five-cell card the three settings give cells 3, 6 or 12 centimetres wide, resolved by the fixed one-centimetre image sampling. Other imported values within the supported range can incur that sampling quantisation.

Held receivers keep both their image and their last accepted spacing value; mounted labels report that local spacing. Undoing a relink restores both. Live receivers follow source spacing changes. Texture generation remains event-driven, with no repeated sampling on idle frames. Target-headset profiling remains open.

## Surface offset

OFFSET +5CM advances the source sampling offset along each sheet's U coordinate through 0, 5, 10, 15, 20, 25 and 30 cm, then returns to zero. The field uses `(surface_x_metres + offset_metres) * card_size / repeat_metres` to obtain its source address. Thus positive offset advances the sampled address; it does not translate the mesh. U follows each receiving surface, not a single world compass axis. Repetition rule, card, palette, repeat spacing, UV geometry and historical carpet stay unchanged.

At 100 render pixels per metre, a 5 cm offset shifts the sampled image by exactly five pixels. For p1 at 30 cm repetition, offsets zero and 30 cm render identically while remaining different stored states. This full-period equivalence is not claimed for every wallpaper group.

Each receiver retains its accepted offset alongside its image and spacing. Holding a receiver declines offset updates, and undoing a relink restores its previous offset and image together. The panel reads the shared source offset as Uxx; mounted labels read each receiver's own accepted value. Continuous held-hand control remains the next input adapter.

## Recipe boundary

`loom_recipe.gd` validates the versioned `ada.loom.recipe` state before any mutation. The recipe contains the resolved card, six RGBA colours, repetition group, paint selection, seed and density, up to six historical bands, scroll speed, animation phase and surface repeat spacing and offset. The optional version-one `offset_metres` field defaults to zero for earlier saves; values outside 0–0.3 metres or non-finite values are rejected before mutation. Version-one files lacking the optional `repeat_metres` field import at 0.3 metres; invalid or non-finite spacing outside 0.15–0.6 metres is rejected before mutation. Import requires a matching card size and valid bounded numbers and colour indices. It recreates state rather than rerunning the random generator.

SAVE writes full-precision JSON to `user://pattern_recipes/foundry.json`; RESTORE reads that same local slot. A later SAVE replaces it. This is a source recipe, not a saved outfit or a record of the curved receiver's temporary held image. Invalid or missing files leave the source unchanged and update the readout. The historical carpet and the current-rule specimens are deliberately different outputs.

## Verification and next adapter

`commons/testing/probe_pattern_recipe.gd` runs the actual museum, exercises a pointer press and release, checks source and historical carpet pixels after restoration, validates malformed-input rejection, compares UVs and metre dimensions, and verifies unchanged supporting geometry and an independent loom. Its file target is a test-only path under `ada_run`.

The next input experiment is explicit held-hand control of the verified bounded offset. The architectural scope currently comprises these three inner-wall faces. Whole-hall control, gesture ownership, garment-region transfer and shader teaching remain planned upgrades. The existing mirror/catwalk do not yet receive this recipe. Reach and performance still need a headset walkthrough.


### Supporting workshop: Pattern Studio

The secondary `pattern_studio_plate` is now a physical source editor at grid (30,11), inside the curved room, with a 42 cm paint grid and a shader preview beside it. Its previous/next controls choose motif, group, resolution and palette; MIRROR, ROTATE, CLEAR and UNDO operate on the source. Motifs load at their authored resolution. All group names map to the engine enum by the corrected order (CM before PMM).

WEB NEXT reads compatible web packages from `res://commons/patterns`. The supported source sizes are 2, 4, 6 and 8, with up to 9 colours; unsupported dense packages are rejected without cropping. The existing wallpaper shader renders saved shape and finish values on the preview and floor. SAVE/RESTORE use a separate `user://pattern_recipes/studio.json`. The studio package remains distinct from the primary loom's historical recipe. Its new surface adapter explicitly applies the studio shader to the hall's five existing receivers. PREV/NEXT select a surface, ARCHITECTURE or ALL FIVE. APPLY LIVE changes ownership, HOLD retains the accepted material, LOOM returns ownership, and the shared UNDO LINK history restores source and image together. A weak source reference prevents the receiver from keeping a departed studio alive; source departure holds the last image. Web repeats are interpreted across a 1.2 m reference square for these receivers, keeping physical repeat size across differing wall dimensions. The studio preview and its own carpet retain their existing normalized mapping. No wardrobe or neighbouring hall is searched. See studio-workshop.html for the remaining editor adapters.


### Inhabitable curved receiver

The room is opt-in through `pattern_studio_plate:0:0#room:curved`. It extends the northern part of the runway annex into previously unused cells. A three-cell doorway at row 18 connects the bays. The room centre is grid (30,10), radius 4 m, height 3.2 m, with a 300-degree wall (about 20.94 m along its arc), a 4 m mouth, and a roof with a 3.3 m diameter opening. Eighty wall segments have physical collision. A separate plaster backing frames the print. The shell and roof do not cast shadows: the coarse museum sun-shadow edge obscured the printed field. A fixed local fill complements the museum lighting; this is a material study, not a daylight simulation.

ROOM WALL and ROOM FLOOR are two additional registered receivers. ROOM selects both. ALL FIVE retains exactly its original five members, and ARCHITECTURE retains its original three wall faces. The studio begins with two card repeats across its 1.2 m reference square, giving a 60 cm card span on the room. Wall U follows arc length and V follows height; floor UVs use planar x/z coordinates. This preserves repeat size while making no claim of seamless alignment where floor and wall meet. The studio shader operates on these surfaces without rebuilding geometry. Returning the room to the loom uses a bounded 30 pixels/metre CPU image instead of the small specimens' 100 pixels/metre.

The studio remains the editable source; its controls, held images and undo work in the room. Avatar clothing and the rest of the museum remain separate receivers to develop later.
