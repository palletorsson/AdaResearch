# Triangle encounter audit — 19 September 2026

Read-only investigation using the Ada Navigator and Auditor workflows. This note recommends decisions; no map, artifact, manuscript, role or shared decision file was changed. Sources were inspected, and earlier runtime records were read. No new Godot or headset run was performed for this audit.

## Judgment

**This is a developed hall with one useful apparatus improvement, not a chapter needing replacement.** Its two primary artifacts already support the chapter's first distinction: connecting edges, submitting faces and making those faces visible are separate operations. The more demanding L experiment is implemented through manual reuse of corners. What remains uncertain is whether a beginner can reliably carry out that controlled comparison in VR.

The critical question follows an actual implementation decision: the fan grants its first vertex a special role. Keep the measured L recipe, the observation of overspill, and the possibility of using that excess for another purpose. They are supported by the code and a prior supplied-input probe; simplifying the prose would not solve the hand-precision problem.

## Verified current situation

| Finding | Evidence | Recommended decision |
| --- | --- | --- |
| Two primary encounters agree across book, placed tokens and room roles. | `final.md` orders `triangle_line_puzzle` before `draw_triangle_faces`; `map_data.json` places them at `(8,2)` and `(6,13)` with `#discovery:1`; `commons/data/artifact_roles.json` places both in `boundary-and-face` in that order. | Preserve the order and both primaries. |
| The triangle puzzle waits for completion before creating its fill. | `triangle_line_puzzle.gd:228`, `toggle_discovery_face()`, returns while incomplete; the face is an explicitly added ImmediateMesh with double-sided transparent material and no new collider. | Preserve the prose's boundary/face/visibility distinction. |
| Free drawing already supports the specified two-start comparison. | `draw_triangle_faces.gd:173` preserves stored points and completed meshes on NEW OUTLINE; `:341` accepts new or existing corners; `:504` extracts the cycle and `:549` chooses the first vertex for its fan. The panel numbers corners and marks START (`triangle_experiment_panel.gd:68`). | This is a usability-development candidate, not a false text claim. |
| No dedicated SHIFT START or L guide was found in the relevant primitives, UI and registry sources. | Current drawing panel has NEW OUTLINE and SHOW / HIDE FILL only. The tool requires manual retracing to change start. | If improving the experiment, add a small optional control to this existing artifact. Do not replace free drawing or add a second general-purpose triangulation exhibit. |
| Twelve secondary works remain physically placed. | Current map has 15 nonempty interactable tokens: 2 primary, 12 secondary and the `3t` text marker. `artifacts.md` and `detours.md` match the placements. | Preserve the secondary ecology. No artifact recovery is necessary to justify the book's closing invitation to folds, symbols and surfaces. |
| Other registered triangulation examples ask different questions. | `triangulation_fail_demo` and `triangulation_pass_demo` are hinged-frame/diagonal rigidity examples; `delaunay_triangulation_3d_cell` addresses a different construction. The current secondary quad and folded strip concern diagonals and shared edges. | These are potential later comparisons, not substitutes for changing the start of an unchanged concave outline. No promotion is necessary for this repair. |
| The room still displays “everything triangle.” | `map_data.json:107` has `3t#text:everything triangle`; `artifacts.md` explicitly treats this as a provocation. | Retain for this pass. Evaluate its effect in the room before altering an intentional slogan merely to match technical prose. |

## Existing evidence and its limits

The record in `doc/space/point-triangle-focus-2026-09-16/fan-checks.json` reports a passing Godot 4.6 run of the real drawing scene with supplied hand positions and the actual NEW OUTLINE pointer callback. Both starts preserve six points and make four logical triangles. Start A has summed triangle area approximately 0.80 m²; start B approximately 1.44 m², with two triangle centroids inside the excluded notch. Both outlines bound 0.80 m². The larger sum includes overlap; it is not union area and must not be presented as a measured entropy or freedom quantity.

The separate prior primary probe reports 23 checks. These are dated engine-behavior records, not evidence that an unassisted person can draw six coplanar corners, manage the one-second sampling interval, or recognize the overspill in a headset. The source hashes below still match that dated source record and the review package, but not all engine dependencies were compared.

## Minimum next implementation, if selected

An optional **SHIFT START** action can cyclically reorder the most recently completed loop while retaining exactly its stored corner indices and geometry. It should operate only after completing a loop and releasing the drawing tool. A visitor should be able to step back to the original start, read which stored corner is the fan anchor, and compare the fill with its unchanged boundary.

Prefer replacing the selected loop's fan in place, with an explicit start marker, over silently adding unlimited overlapping fills. If that choice is implemented, update the few manuscript lines that currently describe adding a second loop and counting eight triangles; those counts remain accurate for the existing manual route. Keep that manual route and NEW OUTLINE available. The exact behavior and accounting must be decided together, not added as a generic extra button.

Scope of acceptance: same stored points and cyclic boundary before/after; exactly four logical triangles for a six-point loop; the known A/B L produces the existing inside/overspill distinction; returning to A restores the original mesh; arbitrary user-drawn loops remain usable; NEW OUTLINE and free drawing remain unchanged. A later headset observation must check reach, readability and whether the control isolates the intended question.

**No prose cut or new primary artifact is justified by this audit alone.** The minimum completed action for this pass is to preserve the mature hall and record this narrow apparatus option for the next targeted implementation.

## Current source fingerprints

These five files are byte-identical to their 18 September review-package copies:

| File | SHA-256 |
| --- | --- |
| `commons/maps/Point_Triangle_Context/map_data.json` | `3abcccc1ae0abe8df5516804f9fad5e37fd02d3a53b0c562503a9028957fafba` |
| `commons/maps/Point_Triangle_Context/final.md` | `13ab860a3d58a06ee4d7f5153196d770163b6c66d8e489981dd54e3ed281dc5a` |
| `commons/primitives/point/draw_triangle_faces.gd` | `db9682fa83b22450e7b02b0e8443c1c0181c0cb52a2cbef5ed316775ed0d2f82` |
| `commons/ui/triangle_experiment_panel.gd` | `b1fc4c56ac0858f477df0d2bca095ec7c744edd1dd5b1a1663eaf65dea8ae48a` |
| `commons/primitives/line/puzzles/triangle_line_puzzle.gd` | `f2ba6f333c928a3e327fa1a3baba001efd329a91871d891372c83b036741a1bc` |
