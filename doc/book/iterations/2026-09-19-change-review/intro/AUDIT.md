# Change_Intro: staged comparison, 2026-09-19

Targeted spatial improvement. The two workbench implementations already support the manuscript's investigations and are preserved. The first-pass route concern is supported by actual museum captures: the two benches originally occupied the same depth, and neither small plot was visible through the forward threshold framing. The bridge was the strongest forward landmark.

## Purpose and decision

The manuscript moves from “Walk to the accumulation workbench” to “Before leaving this hall, visit the bridge.” The technical dependency is finite rate → gathered contributions → signed net change. The strong writing and all three primary encounters remain. Existing secondary artifacts also remain available for comparison and return.

Changed only five cells in `commons/maps/Change_Intro/map_data.json`:

| Artifact | Before cell | After cell | Decision |
|---|---|---|---|
| tangent_slope_workbench | (6,5) | (9,5) | Bring the first bench into the entrance view, keeping its inward-facing 90° rotation. |
| riemann_sum_workbench | (20,5) | (20,9) | Place accumulation farther into the bay, keeping its 270° rotation and space for the held panel. |
| ftc_bridge | (6,12) | (6,12) | Add `#reveal_on_request:true` to activate the bridge agent's separate comparison control; preserve `#evidence:longhand`. |

These positions establish depths 5 → 9 → 12 without enclosing the learner in a forced route. All 17 authored artifacts remain. The other 15 artifact positions, structure, utilities, map metadata, orientation, and scale are unchanged. Workbench source and comparison adapters are byte-identical to this pass's snapshots. Source change evidence is in [changes.json](changes.json), [map_data.diff](map_data.diff), [before-source-sha256.json](before-source-sha256.json), and [after-source-sha256.json](after-source-sha256.json).

## Actual museum verification

Executed the real `endless_museum.tscn` with the authored Change_Intro map, Vulkan/mobile rendering, XR off, Dummy audio, isolated control files, and hidden owned subprocesses. This hall is an ordinary authored museum transplant; it is not a simulation-grid hall. Evidence probes adapt the existing `probe_change_intro.gd` and `probe_accumulation.gd` only for isolated outputs and captures.

| Probe | Before | After | Observation |
|---|---:|---:|---|
| Staging | 27/27 | 27/27 | All 17 authored objects present; central standing-capsule route and lateral/standing approaches to all three primary encounters clear. |
| Tangent | 21/21 | 21/21 | Pointer controls, four finite intervals, signed backward difference, analytic reveal, slider, reset, invariant curve, and legacy mode work. |
| Accumulation | 26/26 | 26/26 | Height × width contributions, three rules, held geometry, independent integral/endpoint checks, reference reveal, slider flush, reset, standing reach, held-panel sightlines, and legacy mode work. |

All 74 checks pass in each phase. Full results are in [verification.json](verification.json); each phase retains JSON results, process/engine logs, exact command, elapsed time, camera coordinates, and hashes of relevant source before and after each run. No watched source changed during any accepted run. The shared museum and detail scripts remained unchanged across both phases. The separately developed bridge source changed between phases and is identified by the run hashes; bridge interaction acceptance belongs to `../bridge/`.

The entry pair uses exactly the same camera. The after view visibly includes the nearer tangent bench and the deeper accumulation bench. The plan pair confirms their increasing depths. The moved accumulation bench's held midpoint image remains separate and unobstructed beside the live rule comparison.

| View | Before | After |
|---|---|---|
| Entrance | [entry.png](before/entry.png) | [entry.png](after/entry.png) |
| Hall plan | [plan.png](before/plan.png) | [plan.png](after/plan.png) |
| Held sum comparison | [accumulation_rules.png](before/accumulation_rules.png) | [accumulation_rules.png](after/accumulation_rules.png) |
| Tangent samples | [change_samples.png](before/change_samples.png) | [change_samples.png](after/change_samples.png) |

## Evidence boundaries

- **TEXT/SOURCE:** read the current manuscript, tutorial, map, workbench sources/adapters, original review, and REVIEW_PRINCIPLES. A stale tutorial reference to the former Accumulation_Riemann hall was passed to the root agent, who owns manuscript/tutorial changes.
- **CAPTURE/RUNTIME:** tested desktop museum geometry, mathematical state changes and injected XR pointer events. These support placement, visibility and implementation claims, not a claim that a learner must choose this order.
- **NOT TESTED:** headset readability, tracked-hand operation, comfort, actual visitor gaze/route, or comprehension. The three-metre central route remains freely traversable; a visitor can still choose another exhibit first.
- **BRIDGE:** after captures show numeric endpoint comparison hidden while the theorem title remains above the arch. This is the root agent's accepted scope; the stronger option of hiding that title was raised but not applied here.
- **RUNTIME CONTEXT:** normal procedural museum dressing can differ between runs. Neither it nor the secondary artifact ecology was removed for photography. Existing UID/certificate/shader-cache and shutdown warnings are retained in logs; the focused assertions pass. An initial probe incorrectly expected Tiling's SimGrid node, then an intermediate census counted normal museum dressing as authored artifacts. Both harness assumptions were corrected before the accepted before/after results; `baseline/` retains the intermediate capture/check record.

Pass complete at the targeted gap: a clearer, reachable order with both mature workbench encounters intact. No workbench capability repair or further spatial expansion was justified by these checks.
