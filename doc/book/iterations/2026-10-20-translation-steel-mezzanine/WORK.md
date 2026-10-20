# Translation steel mezzanine — 2026-10-20

133 editable construction records: 36 deck tiles, 24 truss bays, 24 one-metre post segments, 36 cubes, 12 original wp wedges and one suspended carrier. Deck tops at 3m; two 6x3m banks at Z=5..8 and -8..-5. Two 2m-wide ramps rise 1m per 2m run. The carrier travels 8m at height 3, between Z=4 and -4. Its 2m deck meets each bank. The original shafts and their danger remain.

Shared geometry recipe: commons/void/steel_modules.json. New steel_module.gd builds mesh and per-bar collision; construction_grid.gd batches one mesh per steel kind. Both the API payload and Three preview use this same recipe. Native primitive meshes retain the existing Cube/wp source. Existing room revisions, autosave and Desktop backup remain the save path.

Web changes: api/void-layout/route.ts exposes steelModules; void-model.ts adds truss/deck/support kinds; void-construction-view.ts reads shared boxes/brace angles; void-scene.ts passes the recipe; VoidEditor.tsx adds brushes, centimetre height entry and Match 3 m mezzanine preset. rooms.schema.json accepts the new kinds.

## Editing

Use the new brushes in /voxel-editor?mode=void&trial=transformation&floor=3. Truss is 1m long, .5m deep and .2m thick; deck is 1m square and .12m thick; post is 1m tall. X/Z positions are centres, Y is base height. Match 3 m mezzanine sets deck base2.88 or truss base2.38. Posts stack at 0,1,2. Use 0.5m snap to align with the current half-metre centres and place successive modules 1m apart. The carrier uses deck-top height, 3m. Reopen the trial after autosave to load edits in the game.

## Verification

python -X utf8 tools/test_steel_mezzanine.py: 78 checks passed (desktop plus synthetic XR). Walk both ramps, walk/ride/leave the carrier, confirm body/camera motion, streaming ownership, under-deck clearance, open shaft, diagonal brace collision and empty triangular opening, fatal fall and restart. No physical headset test.
node tools/test_mezzanine_editor.cjs: 8 checks passed, including shared geometry, unit dimensions, layer paint/erase, copy/move/rotate, API validation, save parity and unchanged other floors.
python -X utf8 tools/test_steel_mezzanine.py --capture: three actual native images. Platform paused midway only for photographs.
Live browser: rotated truss + raised deck stamped/autosaved, undone, reloaded; height preset checked. Temporary stamps removed.
Whole-web tsc still has unrelated existing errors; no diagnostics in the changed Void editor/API files. Browser material/lighting remains approximate. The structure is a game construction kit, with no load/stress simulation. Static steel is batched; physics remains per-bar/per-tile collision.

No tutorial.md/final.md changes. No other trial-floor or curated-tower layout changes. before-rooms.json preserves previous Translation crossing.
