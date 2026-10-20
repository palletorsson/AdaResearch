# Point Trace in The Void

User requested: short card first; next floor with existing artifacts; retain trace for Grid; editable in Lab Editor; thin planks / black steel beams in a shaft corner instead of another balcony.

Delivered floor 04 (y=-24), map Point_Trace. Card: `2026-10-18-void-point-trace-card.md`. Report: `doc/book/iterations/2026-10-18-void-point-trace/index.html`. Editor: http://localhost:3003/lab-editor?mode=void&floor=4 . Save then restart The Void. No physical headset test.

Existing artifacts in four placement adapters (`commons/void/trace_area.gd`, trace_surface/record/release/descent.tscn): glass painting wall; three DrawDot beads at 10/40/80mm with 0.9m plinths/readouts; original sampling monitor; replenishing ball ramp; shaft B timber landings. Adapters extend the existing Lines area placement helpers, preserve original artifact logic and support `config.parts`, `only_parts`, copy/paste. All earlier floor records, including user edits and copies, were preserved (compared with `ada_run/void-before-trace-rooms.json`). No final.md or tutorial.md edits.

Record lineage: actual DrawDot dropped signal calls existing TraceData.add_trace, copying world Vector3 positions. Existing grid_lines.gd is tested consuming these exact positions, retaining original while its view changes. Full project already autoloads TraceData; isolated test/export now do too. Floor roots have `em_map` so the monitor discovers all beads on its floor. Archive survives death/retry during the session; no disk persistence; Grid floor is NOT added yet. Glass/ramp traces remain local.

Descent: only Lines→Trace uses the new shaft corner, configured by `descent.shaft_corner_floors:[4]`. JSON numbers are floats in Godot: compare float(level) for membership. From east slab at (13.3,-18,-1.65), drop onto first landing centred (11,-21,-1.65), then jump south to (11,-24,1.85), exit to z=4. Earlier three balconies remain. Two three-metre falls need no magical cushion; missing the open shaft still kills. Fixed reused line_body planks are 0.06m thick with matching collision, beam material is black metallic. Landing parts flagged `void_floor_surface` acquire their actual authored floor index in floor_content; checkpoint only triggers at the floor elevation, not on the intermediate landing. Steel hangers anchor upper platform to the slab above. User may rearrange all parts; custom routes need another walkthrough.

Lab uses same rooms.json. Exported 129 GLB files total (~2.7MB). Exporter now supports any artifact with `part_defaults`, updates shared line_parts.json for native editor/validator, renders live viewport textures into static previews, skips private SubViewport stages, exports only visible MultiMesh instances and omits zero-scale geometry. Run stage builder before exporter to resolve newly added dependencies. One optional-global fix in grab_sphere.gd resolves TextManager through get_node_or_null, preserving full-project behavior without requiring that autoload for the isolated scene. TagSystem actual class included in test stage.

Validation:
- `python tools/test_void_game.py --reuse --trace --out=doc/book/iterations/2026-10-18-void-point-trace`: 34/34 actual Godot assertions, including synthetic XR grip, same-point monitor, record→Grid, retry, replenishing balls, two descents, physical full waypoint walk for desktop + synthetic XR.
- Add `--capture` for Mobile screenshots.
- `python tools/test_void_trace_editor.py`: five shared save checks + two native assertions. Edited monitor and copied steel beam load from an actual saved draft. Live layout untouched.
- `python tools/validate_void_rooms.py`: valid. Existing browser model contract suite: 7/7.
- Broad old suite: 204/219. The 15 remaining failures also occur in isolated pre-Trace four-floor layout. Do NOT reset user placements to satisfy them. Comparison in report. Four added timing failures were fixed by changing old probe to await recovery state, not fixed flight duration. Baseline paths: `ada_run/void-trace-baseline`, `ada_run/void-trace-regression`.

Next: user arranges Trace and tests headset comfort. Add Point_Line_Grid later with the existing TraceData consumer; discuss disk persistence if drawings should survive closing/relaunching Godot. Keep tutorial and reflection separate and use current source artifacts as evidence.

## Shadow Game objects added

Same-day follow-up: existing `commons/shadow_game/point.gd` reused at radius .07, with matching mesh/collider and unchanged original class. `commons/void/shadow_trace_point.gd` keeps strokes separate and archives copies of world positions on release. Visual segments bounded at 2048; record persists for session, not disk. Recovery recalls only an escaped point without clearing its drawing.

Shared `commons/shadow_game/socket_frame.gd` extracts the original twelve-edge outline geometry; Shadow Game and Trace both use it. Three 48cm outline cubes sit on .98m pedestals. Individual names in Record work area: ShadowPoint, ShadowPointPlinth, OutlineBox0–2, OutlinePlinth0–2. Defaults in west bay; each is exported, editable and copyable. No new primary station. Route goes around the point stand.

User edited GlassWall, SamplingMonitor and third bead/plinth while this work ran. Those placements were preserved. Monitor observation range set to50m on this floor only, because moved screen was14m from first bead. Discovery still scoped to floor.

Latest validation:48/48 Trace native checks, including synthetic XR ball grip, stationary sampling, two distinct strokes, Grid original, lost-ball recall, isolated copy, actual desktop/XR floor walks.5 shared editor checks +6 native saved-draft assertions include point and outline moves/copies.7 browser contracts.137 GLBs exported, no errors. Actual Mobile image trace-shadow.png in report. No headset test. Void walker has no desktop pickup UI: desktop hooks were tested directly, not via pointer. Preserve that distinction.
