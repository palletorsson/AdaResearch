# Primitives: findings and decisions

19 September 2026. Three parallel audits, followed by source changes, automated tests and an actual museum render. This is a targeted continuation of the first-pass review, following [the revision principles](../../REVIEW_PRINCIPLES.md).

## Main finding

Primitives is already a developed sequence. The current evidence supports selective repair and observation, not a general rewrite. Several apparent gaps concern access to an existing comparison: how easily someone can see it, operate it or repeat it. Other review suggestions are already answered by the current text or by artifacts beyond the primary filter.

The thread holds: **a point acquires an address → two points make a relation → movement becomes a record → a grid makes return repeatable → edges and faces differ → a moved vertex reveals connectivity → resolution distributes distinctions → approximation needs a stopping rule → correctness leaves aesthetic work unfinished.** The biome recap recomposes that vocabulary before Transformation.

## Completed changes

### One point, two addresses

Point One now has paired **WORLD** and **LOCAL** cards fed by the same `point_one_main`. The existing coloured frame had guides but no numbered ticks or local readout. Reusing the readout artifact makes the chapter's comparison directly observable.

The cards are at map cells `(2,9)` and `(2,11)`, facing +X, centred at 1.4 m. Each is 1.728 × 1.44 m, leaving a 0.272 m gap. The previous WORLD card combined token scale 2 with display scale 2.4; copying it at that size would have overlapped the pair. The new placements use token scale 1, display scale 2.4, no plinth and a placement pin.

![The two coordinate cards in the actual Point One museum hall](point-one-after.png)

The full museum placed all 16 authored artifacts without sliding or refusing a placement. The two cards reported WORLD `(8.50, 0.99, 5.50)` and LOCAL `(2.67, 0.73, -4.67)` for the same point. [Assembly evidence](point-one-after.json).

The check also exposed a real display-lifecycle bug: configuring before `_ready()` built the card twice, leaving blank dashes over the live numbers. `coordinate_readout.gd` now collects its configuration before the first build and batches later rebuilds. Each card has one frame, one card, one value label and one caption. The new regression failed before the fix and passed afterwards.

Only the adjoining staging language in `final.md` changed: an invitation to compare LOCAL with WORLD and the sentence naming the local reference. The rabbit, folding past, invisible point, uncertainty and critical argument remain intact. The cards remain a single encounter in the book.

### Source descriptions that match the artifact

Corrected the trihedron's eight-line identity header. It has three open triangular faces and a closed convex collision hull; it does not have the previously claimed quad base. The alternate material is unassigned in the shipped scene. Executable behavior and the already accurate manuscript were preserved.

Also corrected the coordinate readout's descriptive comments: it can follow an external point, and moving the reference frame around a world-stationary point changes LOCAL while WORLD stays fixed.

The preceding pass's shared snap-release repair remains covered: releasing now detects nearby points at the release position, rather than reusing a target cached before the point was carried elsewhere.

## Decisions across the sequence

| Hall | Decision | What earns further work |
|---|---|---|
| Point One | **Improve the encounter; preserve the chapter.** Paired readouts and display fix completed. | Check physical pickup, reading distance and movement between the cards and frame in VR. |
| Point Lines | **Preserve the developed sequence of encounters.** Shared snap-release repair completed in the preceding pass. | Verify the connection/barrier consequence and walking trace with physical controls. |
| Trace | **Preserve.** Movement thresholds, rounding, retention and whiteboard contact already do different work. | Test a small gesture and a pause; then carry the retained trace into Grid in the same run. |
| Grid | **Preserve the return from Trace.** Shared addresses add repeatability; the reprise is useful. | Inspect the actual contrast between fine/coarse paths and original/re-rounded replay. |
| Triangle | **Preserve the text, two primaries and twelve placed secondaries.** The L experiment already works through retained corners. | Add an optional **SHIFT START** to improve repeatability without demanding exact hand retracing. This is proposed, not implemented. |
| Polyhedra | **Preserve the barrier/sign field and its text.** The architectural return is already explicitly explained. | Observe collision, wedge joins and the open corner in the actual room. Source metadata corrected. |
| Animated cube | **Preserve.** The local face explanation is correct; v6 also affects the top and right faces. | A later invitation to inspect those neighbouring faces could enrich the encounter. No mandatory extra paragraph. |
| Ignorance | **Preserve.** The marked/plain resolution pairs and irregular capsule supply distinct comparisons. | Check whether a visitor can discover the silhouette differences at the staged distances. |
| Portals | **Preserve.** Tolerance and stopping criteria connect the two instruments. | Observe readable labels, reversal and the transition between instruments. |
| Melencolia | **Preserve strongly.** The detector's connectivity-only rule supports the critical argument; the restored court matters. | Check the court, ramps and square as a spatial encounter before adding more explanation. |
| Biome ladder | **Keep the intentional museum recap.** Its inclusion is documented, not an accidental extra map. | Later distinguish museum coda from book chapter in navigation/metadata; do not manufacture an equal-weight eleventh chapter. |

## Verification and limits

`python -X utf8 tests/museum/run.py --timeout 45` passes all three cases: **19 Point One, 18 Point Lines and 26 snap-release Godot assertions**, plus the authored Python checks. Tests use the real scenes and current Point One instrument configurations. They exercise identity/channel binding, reference translation/rotation/scale, display lifecycle, release behavior and the existing basin/trace contracts. [Test report](../../../../ada_run/test-results/museum/20260919T110403Z-69c474fe/report.md).

The Point One observation separately loaded the actual endless museum with an isolated control file and current map source, retaining museum overrides. Headless and Vulkan/mobile runs exited successfully. The final image was inspected for caption/value legibility, duplication and overlap. The observer is at `(5.5,1.65,10.5)`, above an empty walkable floor cell. This is a verified viewing position, not a complete accessibility or headset test.

The full-museum logs retain the project UID/certificate startup notices and a `Viewport Texture must be set to use it` error during `_stamp_inner`. The viewport error also appears in the before-run. It remains a separate renderer/assembly investigation; the successful coordinate-pair observation is not a clean bill of health for every artifact in the hall.

One useful result would have escaped code inspection: the farther camera position was obscured by the large red target arrow even though physics sightlines were clear. Moving closer along the available floor makes the cards readable without removing the target. [Earlier obstructed view and duplicated labels](point-one-after-before-display-fix.png). Collision rays cannot certify visual visibility.

**Still untested:** physical controller operation, haptics, headset comfort, unassisted learner understanding and the complete walk through every audited hall. The later-hall decisions are based on current manuscript/source inspection and specifically identified prior evidence, not fresh runtime certification.

## Next actionable improvement

**Subsequently completed:** the [triangle SHIFT START pass](../2026-09-19-triangle-shift-start/SUMMARY.md) implements and verifies the proposal below, with narrow chapter/reference updates and real Godot images. The combined suite now passes 123 Godot assertions plus 9 authored checks; museum/headset observation remains separate.

Prototype optional **SHIFT START** on the triangle drawing artifact's most recently completed outline. Keep the stored corners and boundary fixed, make the selected starting corner explicit, and replace that loop's fan rather than accumulating invisible extra copies. Keep NEW OUTLINE and manual free drawing. Verify the known six-corner L in both start positions, then return to the original start. Adapt only the necessary instructions and counts after the behavior is established.

A separate documentation issue remains: Point One's older `artifacts.md` lists a nine-artifact catalog, including items that do not describe the current placement. Current map/roles and the updated encounter reference are the evidence for this pass. That derived inventory should be refreshed later, rather than being used to justify manuscript cuts.

## Detailed audits

- [Point One comparison](point-one-audit.md): source findings and the initial placement proposal, before runtime verification.
- [Triangle encounter](triangle-audit.md): existing evidence, secondary artifacts and the proposed controlled comparison.
- [Later halls and biome recap](sequence-audit.md): per-hall evidence and preservation decisions.
- [Decision ledger](../../review-feedback/2026-09-18/primitives/DECISIONS.md): updates to the external review's findings.

Four scoped before-files and their [SHA-256 manifest](before-sha256.json) preserve the earlier Point One text/configuration/readout implementation. Original external reviews and frozen review packages were not edited.
