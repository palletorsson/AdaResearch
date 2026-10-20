# Triangle museum return — 19 October 2026

Request: compare old Point_Triangle_Context museum map and final.md; retain its interactions in Void floor 5; fix the plinth blocking the shaft; keep lab-editor placement; show native screenshots.

Read the original map, final.md, tutorial context and production artifact scripts. Original map_data.json, final.md and tutorial.md are unchanged (hashes in layout-change.json). Do not rewrite those texts to match an accidental adaptation.

Changes:
- Shared saved rooms.json: move only drawing/LiveTwin from world (-9.75,-30,0) to (-16,-30,0). Keep its 90-degree rotation. Move five existing captions beside their curator-placed exhibits. Receipt records exact before/after and API save result; Desktop backup agrees.
- triangle_area.gd enables show_local_fill only on the Void drawing. Workbench and twin honor it. Source emits both windings, so its material uses back-face culling; enlargement emits one winding and remains double-sided.
- Restore existing parasol_triangle as surfaces/FacingTriangle at world (-16,-30,4.6), height1.4/size.85. Preserve all directional signs and copied sign. Fix source size/height configuration rebuilding; clockwise face winding, back-face culling and unshaded painted colours make pink/blue orientation visible without pink emission washing out the back.
- No replacement triangulation or archive format. Source Trace is copied, reduced to at most six corners and flattened by the original tool; it remains open until CLOSE FACE. Grid keeps its own view of the unchanged archive.

Checks/tools:
- tools/test_triangle_museum_return.py, optionally --capture. Isolated Godot stage; real desktop and synthetic XR grabs; boundary/fill, corner collapse/recovery, concave fan, shared quad, strip, proof walls, assembly, mesh threshold, shaft rays and return persistence.
- tools/test_triangle_museum_return_editor.cjs: nine real model parts, copy/move/rotate and validation; source preservation; shared layout and Desktop backup. Never saves test copies.
- tools/export_void_editor.py refreshes real editor GLBs and line_parts.json. It replaces the isolated project's configuration: restage before subsequent game tests. Do not run it concurrently with a Godot test.

Limits and next context:
- Synthetic controllers are not a headset usability/performance trial.
- Fixture replacement waits one second after release for XRTools' delayed collision-exception cleanup. Rapid deletion of a just-released body can still provoke the existing addon's stale-RID warning; this pass does not change the XRTools addon.
- The curator has the folded strip beyond the south slab edge (world z9.75). Preserved deliberately. The saved 23-stop route guide still contains older poses. Interaction tests and the nine shaft rays are not a complete circulation certification. Never use the old timber-descent probe as proof of the current corner-pad route.
- The next sequence review is Polyhedra if the user continues. Re-read its original museum map and final.md before adapting. Wedges and six-vertex constructions belong there; cubes begin on Cube.
