# Translation pillar frame — 2026-10-20

User requested beams connected to the tower's large pillars, integrated like scaffolding.

Shared steel_modules.json adds collar: four plates around the .9m pillar, seats and diagonal knee braces. Native construction_grid.gd, rooms.schema.json, web void-model.ts and VoidEditor.tsx accept collar. Both engines use the same geometry recipe. The Pillar collar brush uses base2.38 with the Match 3m mezzanine preset.

Translation floor3: removed 24 generated NearPost/FarPost segments. Added four collars at X=-14/-5, Z=+/-7, Y=2.38; 18 one-metre ledger trusses between pillars; eight transverse trusses to connect perimeter rows. Existing deck trusses retained. Generated ramps and landings shifted .5m inward (new centreline Z=+/-6) after the native walk test found bracket clearance insufficient.

146 records: truss50, cube39, deck36, wedge13, collar4, slab2, platform1, support1. The seven user-painted pieces cube-1/2/3, slab-1/3, wedge-1, support-1 remain exact. Other trial floors untouched. before-rooms.json captures the prior layout; save-receipt.json records the final revision-checked save and Desktop backup.

Validation:
- python -X utf8 tools/test_pillar_mezzanine.py — 86 passing desktop/synthetic-XR assertions.
- node tools/test_pillar_mezzanine_editor.cjs — 10 passing editor/API checks.
- python -X utf8 tools/test_pillar_mezzanine.py --capture — four actual Godot images, platform paused midway for photographs.
- Browser inspection: collar palette present, saved desktop+VR state, select NearPillar-5 and focus, capture editor.png. No geometry edits through this inspection.

Physical headset not tested. Browser lighting is approximate. No structural load simulation. No tutorial.md or final.md changes.
