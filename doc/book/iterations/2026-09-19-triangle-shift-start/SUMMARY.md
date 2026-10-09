# Triangle: change the start, keep the outline

19 September 2026. A targeted continuation of the [Primitives audit](../2026-09-19-primitives-review/SUMMARY.md).

The existing manuscript's L experiment works. Its difficulty was asking a learner to reproduce the same six corners while changing only their order. We strengthened that encounter with **SHIFT START** in the existing `draw_triangle_faces` artifact in `Point_Triangle_Context`. The primary roles, map placement and secondary works remain intact.

## What the visitor can do

Draw and close an outline, then release the pen. SHIFT START advances the fan's start to the next stored corner. It replaces the last completed loop's fill without moving the points, changing the boundary, adding another mesh instance or increasing the triangle count. Earlier loops remain available. After a complete circuit of the corners the original fan returns.

The side instrument identifies the selected loop and **START**. **DRAW START** distinguishes the first point of a new unfinished outline. Three buttons fit in the existing 90 cm panel: NEW OUTLINE, SHIFT START and SHOW / HIDE FILL. The middle button dims and explains its unavailable state while the pen or a corner is held, while an outline is unfinished, or before any loop has been completed. The single continuation anchor retained immediately after closure is allowed.

Free drawing, corner editing, hidden fill and manual retracing remain working paths. A manual second L still adds four triangles; shifting the existing L keeps its four. The book instructions now distinguish these two experiments.

The live encyclopedia's `/api/compose-docs?map=Point_Triangle_Context` was checked after editing: it serves the new SHIFT START and replacement instructions to the composing page.

## What we observed

| Same six-corner L | Start A | Start B |
|---|---|---|
| Stored corner positions | Identical | Identical |
| Boundary edges | Identical | Identical |
| Completed loops in this isolated comparison | 1 | 1 |
| Logical triangles | 4 | 4 |
| Summed triangle areas | Approximately 0.80 m² | Approximately 1.44 m² |
| Triangle centroids in the excluded notch | 0 | 2 |

The larger area sum includes overlapping triangles. It is not a union-area, entropy or freedom measure. The visible finding is that the fan from B covers part of the notch left open by the same boundary.

![Starting at A leaves the notch empty](triangle-start-a-plan.png)

![Starting at B sends the fill across the notch](triangle-start-b-plan.png)

These are real Godot renders of the production artifact, with supplied hand positions and its actual pointer-button callback. They are **isolated encounter views**, not screenshots of a freshly assembled museum hall. [Overview and controls](triangle-start-b-overview.png), [panel closeup](triangle-start-b-panel.png), [observation data](triangle-shift-observation.json).

The first probe drawing overlapped the panel. That staging is preserved in `initial-probe-overlap/`. Moving the isolated artifact stage 0.5 m to the right placed its controls beside the unchanged world-space drawing. No map was repositioned on that evidence. The near-vertical images are for inspecting the fill; the overview and closeup are the evidence for panel legibility.

## Verification

`python -X utf8 tests/museum/run.py --timeout 45`

The [complete run](../../../../ada_run/test-results/museum/20260919T114824Z-3f7651db/report.md) passes **123 Godot assertions and 9 authored Python checks** across four cases. Triangle contributes 60 Godot assertions and 2 authored checks. The Python total includes the existing Point Lines checks reused by the snap-release case.

The new [regression](../../../../tests/museum/triangle_shift_check.gd) uses the real scene, XRTools pickup/release methods and pointer buttons. It checks emitted geometry; exact points and boundary; full cyclic restoration; mesh/material identity; earlier-loop isolation; visibility; held-tool, held-corner and unfinished-outline guards; distinct markers; manual retracing; clearing and redrawing; and loops with three, four and five corners. The shared panel still leaves the preceding boundary puzzle's controls and closure-before-fill behavior intact.

An intermediate run passed its behavioral assertions but failed because the new test freed that neighbouring puzzle during deferred initialization. The fixture now waits for all three lines to finish. No production workaround or extra error exemption was added. The final run retains the already documented project UID/certificate notices.

Headless and Vulkan/mobile observation runs exited successfully. No real controller input, headset comfort, unassisted learning, or current full-hall reach/clearance is certified by these runs.

## Decisions and why they matter

- **Keep the argument; improve the comparison.** The existing text was supported by the fan implementation. It needed a more controllable encounter, not a weaker claim.
- **Hold the shape still and expose the choice.** The control changes one source-level decision: which index begins the fan. The visitor can find the mismatch before reading its explanation.
- **Preserve more than one route.** Manual retracing still allows accumulated comparisons; SHIFT START allows replacement. The text names the difference instead of silently changing what the counter means.
- **Keep the failure visible.** This remains a first-vertex fan. We did not install a different triangulator or an automatic correctness warning. Its limits are the material of the encounter.
- **Generalize the method selectively.** Other artifacts can expose a consequential choice while holding their other inputs fixed. Each needs its own meaningful variable and observation; this is not a new control quota for every hall.

Three agents handled implementation, narrow text alignment and rendered observation; the main agent independently wrote the behavioral regression and reviewed the evidence. This pass changes two production scripts and aligns the chapter plus its two references. Before copies and version hashes live in [before](before/); original external reviews were not edited. No commit was made.

## Next work

The automated triangle improvement is complete. The remaining triangle task is to observe a learner drawing the initial six corners and reading the result in the museum, including control reach and overlap with their own drawing. That can wait for headset access. The broader editorial pass can proceed to Transformation with the same selective approach: inspect the current encounter before acting on a frozen review's proposed cut.

[Read the updated chapter](http://localhost:3003/compose/sources?map=Point_Triangle_Context&doc=final) · [Encounter map](http://localhost:3003/long-museum/encounters?map=Point_Triangle_Context) · [Decision ledger](../../review-feedback/2026-09-18/primitives/DECISIONS.md)
