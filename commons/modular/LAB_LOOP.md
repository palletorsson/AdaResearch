# Spatial research lab

The lab binds three recipes in `commons/modular/terms.json` to an existing prefab. Godot and Three.js use the same expression, arguments and transforms. The blue barrier and warehouse crate are original scenes, not replacement footprint boxes.

Open http://localhost:3003/spatial-lab. Select an arrangement, change its source or relations, then **Save variation + native check**. Each save creates a separate registered trial. Saved settings can seed another experiment; hand edits live in that trial's `rooms.json` and remain editable in the lab editor.

## Recipes

- `lab_packed`: centred row; copy count, spacing, initial size and scale ratio.
- `lab_radial`: horizontal circumference; copy count, turn per copy, radius, initial size and scale ratio.
- `lab_growing`: nine staged sizes from table to two lower supports to the floor; source is interchangeable. Its authored poses are ordinary assemblage data.

A term declares default `parameters`. A reference supplies `with` values. A one-key `{"arg":"source"}` object in the expression is replaced by that bound value. This is data substitution, not code evaluation. The existing repeat operator gained a horizontal `radial` layout, an optional `scale_ratio` and stable copy IDs. Existing `ring` and vertical `circle` meanings are unchanged.

```json
{"t":"lab_packed","with":{"source":"crate","count":10,"gap":0.24,"ratio":1,"size":0.3}}
```

`editor_adapter: recipe_area` routes these terms through the generic editable-member adapter when generated into the catalogue. The adapter promotes explicitly tagged static recipe members to `Table`, `Copy01` etc. Part scale stays inside each member, so exported geometry and saved member poses agree. It is deliberately for static arrangements; joint/animation hierarchies keep their own adapters.

## Inspect, save, return

The reference trial `spatial_lab` has barriers on floor 1 and crates on floor 2. The curated main floor 15 is unchanged. Variations use their own `spatial_lab_<id>` trial and a `recipe.json` record of bindings and recipe/source fingerprints. The UI recalls saved recipe settings and links to the exact editable trial. Receipt freshness compares current saved layout files with those actually tested.

The preview reports bounding-box overlap candidates and tabletop overhang after the actual source GLBs load. It never silently changes the arrangement to make a fit. The native check loads the saved trial, verifies real source scenes, editable members, slab/shaft bounds and static collision presence, then takes screenshots. Three.js/Godot pose parity and editor copy/move/rotate/save checks live in `tools/test_spatial_lab_editor.cjs`.

The crate has no original physics body. The lab explicitly adds a fitted static box for copies at least half size. Smaller specimens are non-blocking tabletop studies. Large barriers retain the original full rectangular blocker. There is no claim of dynamic crate physics, hand interaction or physical-headset acceptance from these checks.

## Timing evidence

Measured 2026-10-27: a crate row changed from 16 cm spacing (nine AABB overlap candidates) to 24 cm (none, no tabletop overhang). The saved recipe took 0.038 seconds to write; real model export/startup took 12.770 seconds; the native probe process took 12.339 seconds. End to end: 25.488 seconds. A warm browser preview took about 59 ms. These are one observed variation after the lab infrastructure existed, not a general performance benchmark.

Evidence: `ada_run/spatial-lab-2026-10-27/`. Background native work uses the existing OS mutex. The API rejects stale recipe definitions and invalid argument ranges. Original trials, manual layouts, curation and chapter text are preserved.

Recheck a saved experiment:

```powershell
python tools/spatial_lab.py check spatial_lab_<id>
node tools/test_spatial_lab_editor.cjs spatial_lab_<id>
```

## Interchangeable prefab inputs — 2026-10-27

The searchable input selector now has 15 ready prefab sources: barriers, shipping crate, three plank lengths, three panels, Trace ball, traffic pyramid, bipyramid, building cube, walkable wedge and tetrahedron. New scene-backed inputs are enabled by catalogue ID in `commons/modular/lab.json`; their scenes and labels resolve from the shared `primitive-prefabs.json` catalogue. A new source does not require another arrangement script.

`python tools/spatial_lab.py inputs` builds the original scenes, checks bottom alignment, exercises every input with all three recipes and exports actual source GLBs. An input is selectable only when its original preview exists and its source fingerprints match. Missing models produce an explicit unavailable state, never a footprint stand-in. Preview cache URLs include the source fingerprint.

Source dimensions stay authored. The static input adapter shifts the base to the insertion plane, holds rigid bodies still and suspends autonomous processing. This changes the local research copy, not the source scene. Large inputs can extend off the tabletop or slab; the native receipt reports that finding and keeps the arrangement available for inspection.

Validation: 60 native build checks across 15 inputs × 3 recipes, plus actual base/source checks. A saved two-metre plank feather passed 15 native arrangement checks and editor/Three.js pose and save parity; that observed full variation loop took 35.459 seconds. This timing is a separate run from the earlier 25.488-second crate trial.

## Warehouse field

`lab_warehouse` adds columns/rows, spacing, source size, deck height and a `holes` list of zero-based `[column,row]` coordinates. These feed the shared rectangular array operator; grid members keep address-based IDs. The same expressions compute the bed and staging dimensions. The lab exposes a clickable hole matrix. Bounds/overlap findings do not resize inputs.

The electrical floor is a reusable primitive backed by the existing live bed script. The web builder draws its geometry; the native scene supplies electrical contact. The accepted crate reference has production-walker jump/contact evidence, while arbitrary source/gap changes receive layout checks and need their own gameplay evaluation. Initial spawn is on the safe entry deck.

## S descent / model-first study

`s_descent_model` is now a shared recipe and an independent editable Void trial. Open `/lab-editor?mode=void&trial=s_descent_model&floor=1` or `/modular-studio?term=s_descent_model`.

```json
{"t":"s_descent_model","with":{"model_scale":0.1,"cutaway_alpha":0.12,"yaw":18}}
```

The 1:10 model represents a 12 m descent: two curved slides joined by a level turning landing. Twenty-five tagged members retain insertion points and independent editor poses. The reusable `sweep` primitive carries a solid polygonal profile along an explicit 3D path using horizontal width and world-up height frames. Separate floor, wall and roof strips compose the hollow profile. Native owns collision; Three.js mirrors the geometry. No runtime CSG subtraction or full tower placement is claimed.

Twelve native checks passed, including both Jolt ball drops, the production walker on the level landing, all 171 route support rays and conservative capsule clearance. Five editor checks passed, including native/Three.js pose and swept bounds parity, real GLBs, independent copy/move/rotate and isolated save/reload/Desktop mirror/conflict handling. This does not replace a full-size desktop/VR traversal after the shaft/slab openings are authored.

Evidence: `doc/book/iterations/2026-10-27-s-descent-model/`. Re-run targeted native checks with `python tools/run_s_descent_model.py`, then `node tools/test_s_descent_editor.cjs`. Export geometry with `python tools/export_void_trial.py s_descent_model` after a source change. All native jobs use the shared OS lock. Main tower and actual saved user arrangements were unchanged by these tests.


## Boolean Tunnel / continuous S model

The new `boolean_s_descent_model` recipe is an independent model-first continuation of Boolean Tunnel. One swept outer mass minus one continuous swept bore produces one native CSG result with matching collision. Eight editable members retain the passage as a unit and keep staging separate. The earlier S model remains available.

Editor: `/lab-editor?mode=void&trial=s_descent_boolean&floor=1`. Shared term preview: `/modular-studio?term=boolean_s_descent_model`. Evidence and recipe bindings: `doc/book/iterations/2026-10-27-boolean-s-descent/`. Eighteen native checks and five editor checks passed; full tower/headset acceptance remains later work. Three.js is an analytical boundary preview; lab-editor GLBs contain the actual native Boolean result.
