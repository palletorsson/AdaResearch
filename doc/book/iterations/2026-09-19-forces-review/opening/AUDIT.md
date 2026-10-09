# Forces opening: preserve the relationships, repair the instrument

Local source and runtime review, 19 September 2026. Applies the author's [review principles](../../../REVIEW_PRINCIPLES.md) to the first four halls, alongside the received [Forces review](../../../review-feedback/2026-09-18/forces/01-review.md). The received review is evidence of its frozen package, not a verdict requiring an equal rewrite of every hall.

## Decisions by hall

| Hall | Judgement | Evidence and decision |
|---|---|---|
| Vectors_Act1_WhatAVectorIs | Preserve manuscript; targeted source identity correction | `room_reading.gd` samples world-coordinate endpoint difference, SHIFT moves both pins, SHORT/LONG use 0.25/1.0 metre displacement, ZERO supplies no direction, and a later preset explicitly chooses `(1,1,1).normalized()`. The two projected views have a clipping window while the readout retains measurement. Preserve that discovery order. Normalization source code already uses `magnitude > 0.001`; its source identity overstated “any” direction and tiny input. Corrected three comment lines, no executable changes. |
| VFM_02_Operations | Preserve | Configured `adder_board#lesson:room_sum` uses one sum for wall and carriage; its prescribed route and separate travelled counter make zero displacement compatible with a travelled journey. `room_sum.gd` explicitly resets the trip and homes the carriage on GO/edits. The final already notices this. Its 26 secondary artifacts may compete perceptually, but this is a learner/headset hypothesis, not grounds to prune them. |
| Vectors_Act2_VectorArithmetic | Targeted instrument repair, then narrow text repair | The immediate pad-controlled addition, directed A−B gap, dot threshold, source-connected projection and torque comparison do distinct work. `gap_projection_room.gd` connects the actual same-hall source, computes kept+remainder, and limits SHIFT as a whole. `dot_aligner.gd` applies the stated 0.985 threshold to normalized directions. Torque's rpm was fabricated from a geometric factor; repair the instrument rather than making prose excuse it. Root applied the agreed replacement paragraph and removed only its now-obsolete discrepancy transition. |
| VFM_05_Launch | Preserve | Configured `launch_chamber.gd` uses initial velocity plus uniform downward acceleration, equal launch/landing height and 64 stored segments. The 30°/60° inputs at speed 10 and g=10 imply approximately 8.66 m range, 1/1.732 s flight times; SLOW scales model-clock advancement, not the path. The chapter already distinguishes a visual marker from a collision body and distinguishes retained impact velocity from resting motion. No prose or artifact change warranted in this opening pass. |

The [source chain](source-chain.json) records all **62 placements: 9 primary, 52 secondary and 1 decoration**. All resolve to existing scenes, including one-hop delegates. Anchors and physical primary order agree; the two `#note` entries in the Arithmetic order are prose notes, not missing artifacts. This subtask edited no maps, roles, registry, sequence or manuscripts. Root owns the agreed torque manuscript/registry repairs.

## What changed in the crank

Previously, `round(|r_dir.cross(f_dir)| * 320)` was printed as rpm. The wheel was set to an angle proportional to the same factor; no angular velocity was accumulated. The repaired monitor says **CROSS DIRECTIONS**, `sin θ`, the input angle, the wheel pose and **static diagram**. At the authored leverage 0.78 it reports factor 0.94, input 70° and wheel pose 45°.

The cross product, arrows, wheel geometry, slider, four workings variants and three purchase variants remain. The source identity now calls this a geometric relation. The purchase comparison still trades drawn arm and push lengths while retaining their product. Full torque dynamics remain a possible later comparison, not a feature implied by the monitor.

Exact source diffs: [torque](torque_crank.diff), [normalization comments](vector_normalize_demo.diff). [Before/after hashes](source-manifest.json) accompany raw saved source files.

## Recovery and future comparison candidates

These are present works, not newly commissioned substitutes:

- **Act1:** `CoordinateSystem3M`, `route_vector` and `length_lantern` give frame, travelled-route and magnitude constructions. Preserve them as secondary returns. RouteVector's identity calls displacement a journey; its moving courier can support a later distinction, but that phrasing is not the opening chapter's account.
- **Operations:** `VectorWorkbench`, the XL vector families, projection/reflection, torque and magnitude examples remain available around the primary addition stage. A return changes receiver or scale; it is not automatically duplication. Headset review should examine dominance before any repositioning.
- **Arithmetic:** `vector_dot_product_xl` offers a wider vector arrangement than the limited toy slider; `vector_projection_reflection_xl` introduces a plane rather than this rail; `vector_cross_product_xl` supplies the larger geometric comparison. Laser addition/subtraction change reach and manipulation. Their registry entries have `delegate_to`, not a direct `scene` field; the museum and grid resolve these to existing VectorAddition, VectorSubtraction, VectorDotProduct, VectorCrossProduct and VectorProjectionReflection scenes. No missing-artifact claim follows from a naive direct-scene lookup.
- **Launch:** `force_pad`, `human_catapult`, `VectorThrowing` and launchers can make the difference between prescribing a marker and giving a body velocity bodily consequential. The current final deliberately mentions this without claiming all controls share one physical model. Receiver and safety/comfort tests must precede stronger prose claims.

## Runtime and visual evidence

The [combined verification](verification.json) reports:

- **44/44 isolated checks**, including slider events at 0, 0.5 and 1; static wheel pose through elapsed time; three equal-product purchase settings; four workings variants; and normalization geometry/readout/label across six magnitudes.
- **31/31 saved-source museum replay checks** and **30/30 current-artifact museum checks**, including a standing capsule before the console.
- Identical camera records, torque response and watched source hashes across the accepted pair.

[Before standing view](before-accepted/standing.png) → [after standing view](after-frozen/standing.png). [Before near view](before-accepted/readout.png) → [after near view](after-frozen/readout.png). Both repaired views and the paired before view were inspected: the new text fits the display, the slider remains visible, and the wheel presentation is unchanged.

These are actual `endless_museum.tscn` captures, using the same [frozen shared museum script](frozen-museum.gd), SHA-256 `bb50afe8f7af30953a09d4eb37a7d3206e952e99733edd96c7bf373bba5934ec`. The original torque script is replayed in memory for the before image; production files are never swapped. Each accepted run explicitly verifies that the scene loaded the frozen script bytes. `em_detail.gd`, console base, map and artifact sources remain stable. The museum was frozen because external edits changed its live script during the first two captures; those diagnostic runs are retained under `before/` and `before-final/`, but are not the accepted comparison.

An initial normalization test expected decimal `Vector3(0.001,0,0)` to be exactly at the threshold. The standard Godot Vector3 stores that value as approximately `0.00100000004749745`, which is above the comparison threshold; it correctly normalizes. The corrected probe records the requested decimal and stored length separately. It also verifies genuinely smaller inputs become zero. The predicate and chapter remain unchanged. The initial failed expectation is retained under `headless/`; the accepted result is `headless-final/`.

Tests invoke `set_normalized_value` and the canonical `slider_moved` signal. They do not simulate a physical hand dragging the control. Other preserved opening encounters were source-audited, not rerun here. No headset or learner verification is claimed. Logs retain unrelated UID/root-certificate, environment/renderer, empty registry and viewport-font errors/warnings; no GDScript parse/runtime error occurred in the accepted opening runs.

## Finish condition

The verified numerical falsehood is repaired in the artifact, source identity follows implementation, the mature chapters retain their argument, and the actual museum display has matching visual evidence. Further work belongs to learner/headset observation and optional dynamics comparisons, not another general rewrite of these four halls.
