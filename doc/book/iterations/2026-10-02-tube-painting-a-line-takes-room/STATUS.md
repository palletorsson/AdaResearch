# Pipe, cable and tube upgrade — 2 October 2026

## Latest pass: the full form catalogue

The user's follow-up “all forms” is implemented in the same museum workbench. PARTS cycles four groups containing all sixteen existing GlassRack forms: straight, corner45, corner, ubend, sbend; junction, ypipe, cross, reducer; spiral, wobbly, flask, beaker; cap, drip, condenser. CABLES shows the five CableBuilder arrangements: chord, spline, catenary (labelled authored sag), festoon and truss. `part_library.gd` adapts the existing factories, caches mesh resources and transforms in undo records, and positions named free ports. Cap and condenser port metadata now match their mouths. The supplied parts stay fixed while a free grip starts a new run; up to four grips per part are supported. Drawn runs connect separate pieces on release. Stock parts accept connections at their declared ports only. Stock forms are not all hollow or watertight. Parts and drawn runs share the eight-record budget.

Native result: **114/114** checks passed, including all 21 forms, extension and exact undo at every free port, XR-tools pickup on a cross's third port, a run joining the cross and Y-junction, and restoration of both free ports. The capture runner now rejects script errors even if the test scene reaches its final report. Seven catalogue views (`tube-parts-0` through `tube-parts-4`, `tube-parts-extended`, `tube-parts-connected`) were captured in the actual endless museum and visually inspected. The connected image is deterministic sampled-input replay; the separate extended image follows automated XR-tools pickup. Browser selectors and rendered review were checked. Physical headset testing is still pending.

Canonical tutorial and technical companion, registry interactions, source views, L-systems book export and lineage are current. The first sweep exercise and critical-poetic reading remain focused; the catalogue is a later optional making section. Integration verification passed: **420 native checks / 706 publication checks**, including HTTP links. No new capability prerequisite was added for the catalogue. Existing lineage inventory still reports 10 missing tutorials and 11 previously known issues elsewhere.

Current review: http://localhost:3003/book-review/doc/book/iterations/2026-10-02-tube-painting-a-line-takes-room/index.html?v=all-forms#forms

## Earlier system upgrade

Latest user direction: upgrade the existing pipe/cable/tube system; all forms matter. Implemented in the existing LSystems_Grammars_And_Curves museum workbench. FORM cycles solid retained tube, hollow pipe and cable drape. NETWORK loads a connected three-form example. SAG changes a cable between fixed endpoints and joined supports. Endpoints snap on release; pen gestures beginning on a run make branches. Silver fittings mark explicit shared port IDs. Crossing alone never joins. Connected ends become fixed sockets. Undo restores shapes and socket records together.

Shared implementation: commons/primitives/pipes/swept_tube.gd, run_network.gd and swept_run.gd. The previous study surface file is a compatibility shim. PipeLayout no longer assumes incompatible TurtlePipeBase APIs: actual glass/drain builders are adapted, direct and sampled runs support named anchors, moving anchors rebuilds dependents, deletion and IDs are fixed. layouts/three_forms.json is the reusable example. The original cable builder shares the default sweep, retains shader UVs, uses span-aligned handles, avoids idle rebuilding and clears a collapsed mesh. Glass material uses Godot 4 metallic_specular.

Default suspended starters and the original first sweep exercise remain. The new network operations are an optional next exercise. Canonical final/tutorial/technical/critical, registry interactions, source views, book export and review now include them. No additional prerequisite or early Point_Trace lesson added.

Verification is recorded in evidence.json and the integration verification.json. Current captures come from the actual endless museum in an isolated runtime, including tube-network.png and tube-network-joined.png. Joined-state image uses deterministic sampled-input replay; separate native tests exercise XR pickup and desktop trigger routes. Browser selectors were checked and the new frames inspected. Physical headset comfort and Quest performance remain unverified.

Limits: authored parabolic sag, not dynamic rope physics; visual skins, not body colliders; logical sockets with separate cover meshes, not welded fluid passages; no fluid/audio/electrical routing. Workbench edits remain local to a hall instance. Eight runs, 256 samples each, sixteen undo states. The reusable layout is JSON-loadable, but the interactive workbench has no disk-save UI.

Review: http://localhost:3003/book-review/doc/book/iterations/2026-10-02-tube-painting-a-line-takes-room/index.html?v=pipe-cable-tube#museum

Saved locally; not committed. Keep unrelated existing workspace changes. Reproduction commands are in README.md.


## 2 October: patch and motion application

The existing Eurorack has physical desktop/XR sockets again, swept cords, reliable unplug cleanup and a focused live oscillator/filter/amplifier/speaker preset. A separate gate cord and shared physical power lever control three original coloured kinetic figures after Tinguely and Saint Phalle. The application sits beside the existing tube workbench, inside its later geometry bay. Drawn pipe/tube networks remain geometry with logical joins; they have not silently acquired DSP.

139 native checks pass, including sampled audio attenuation, independent stopping, actual desktop ray pickup, native XR-tools pickup, held-cord protection and side-aisle clearance. See [the native review](../2026-10-02-patch-and-motion/index.html). Canonical final/tutorial/technical/critical and the L-systems book export are synchronized. The section publisher now replaces owned sections by their markers, so a wording change cannot duplicate the old passage. 708 publication checks pass. Physical Quest/headset validation is pending; no commit was made.
