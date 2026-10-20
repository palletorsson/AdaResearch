# The delivery opens onto an already running roof

20 October 2026. The player is not Model B, but plays Model B’s body. There is one embodied viewpoint inside the crate.

The curated Point Zero roof now contains a hollow 3.2 × 2.8 × 2.6 m shipping crate, based on the project's existing procedural crate. The camera starts inside. Its north-facing panel is closed; striking it breaks the planks and brace outward and reveals the existing frame counter. The remaining frame, sides and lid stay. A short synthesized wood crack accompanies the break. Visual debris has no collision and clears after 0.75 seconds.

- Desktop: look at the marked panel and left-click from inside. WASD walks through the opening.
- VR: step within reach and strike the panel with a tracked hand. A nearby controller pointer press also uses the same action. No catalyst is required.
- The roof retry keeps the opened panel open for this game session. A fresh Void scene starts closed.
- Lab editor: choose roof / floor 0. The arrival crate is a reusable prop. Its saved position and facing define the roof spawn. The schema prevents scaling it below body size. Moving it may change what its opening frames; the counter is not automatically moved.

The roof work light moves sideways from x=0.75 to x=3.25 to clear the counter sightline. The origin stays at zero; its labels now respect depth when a crate is present. Tower floors, shafts and counter behaviour are retained. The web model is an exported Godot mesh; the break action runs in Godot.

## Verification

The native probe uses the actual Void scene, desktop pointer events, synthetic XR tracking through the museum rig, and character physics. It checks closed-panel occlusion, inside-only interaction, idle hands, actual click and hand-strike opening, clear exit, continued counter updates, walk-through access, retry and moved/rotated editor placement. See checks.json for the result. Screenshots are native Godot Mobile-renderer captures with the desktop help and transient notice hidden for the photographs. No physical headset test is claimed.

The editor API serves the new catalog entry, roof placement and exported model. Editor layout validation passes with no additional spatial warnings compared with the same room data without this change. The stricter whole-tower validator still reports existing overlaps elsewhere and on the roof; those warnings are recorded in layout-validation.json rather than silently removed.

## Literary boundary

The existing first-person final.md is preserved in before-final.md. The revision changes the already-open panel to a strike, and “keep the crate intact” to “keep the rest of the crate.” The split knot, exposed nail, lifting label edge, consignment record and narrator’s thoughts remain literary particulars, not tested game mechanics. There is no second player, character progression system or care score.

## Sources

- commons/void/arrival_crate.gd and .tscn: hollow shell, interaction, break and session state; extends commons/artifacts/crate/crate.gd.
- commons/void/rooms.json, catalog.json, rooms.schema.json, set_dressing.gd: shared editable placement and prefab.
- commons/void/game.gd: spawn follows crate placement.
- commons/void/floor_content.gd: roof annotation occlusion.
- tools/probes/void_arrival_crate_probe.gd: native regression and captures.
- tools/probes/export_arrival_crate.gd: additive export into the existing web model manifest.
- commons/maps/Point_Zero/final.md and doc/book/MODEL_B_WORKING_SPEC.md: corrected opening and player/body distinction.

## Surface finish revision

The timber is now lighter, weathered wood. CARE UNIT — MODEL B, the shipping arrow and STRIKE PANEL are flat textured ink on the boards, clipped at plank seams and lit by the world. The raised label plate and floating text have been removed. Decorative pink rooftop supply cables and artifact leads have also been removed; the underlying service frame and artifact behaviour remain.

The remaining pink electrical risers above the Point Zero roof have also been removed. The main pipes, steel supports and overhead service frame remain in place.

## Point Zero floor grid

The fixed roof now carries a four-by-four-metre grid with one-metre spacing, signed X/Z axes and a central origin ring. Peripheral captions sit within a 5.2 m marking plane. Y = 0 is stated explicitly. Ink renders 8 mm above the slab to avoid depth competition; the mathematical origin and sphere remain at (0, 0, 0). This does not alter the pipe-cap observation in the first field note. The literary passage has not yet been rewritten to include the grid.
