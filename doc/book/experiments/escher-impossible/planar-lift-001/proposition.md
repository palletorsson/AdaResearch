# Contact in the picture, coincidence in space

**Proposed; nothing has run under this record; the artifact stands in the hall as an uncommitted working-tree placement of 2026-10-13.** This companion belongs to Escher_Impossible and follows the [pilot's conventions](../../random-definition/seed-bench-001/proposition.md) under the [recursive architecture](../../../RECURSIVE_ARCHITECTURE.md) and the [experiments contract](../../README.md). Source bindings live in [the record](./experiment.json). Both hall texts predate the artifact and never mention it; the placement token `planar_lift:0:0.95` sits in the hall's interactables layer as an uncommitted fact about the working tree, and [planar_lift.gd](../../../../../commons/artifacts/planar_lift/planar_lift.gd) itself is untracked.

Two passages initiate this record. The [tutorial](../../../../../commons/maps/Escher_Impossible/tutorial.md) (`escher-impossible.picture-vs-space.v1`) says:

> Walk around the installation's separate perspective work. Apparent contact in an image and coincidence in three-dimensional coordinates require different evidence.

It initiates a construction question: can one instrument hold both kinds of evidence at once — contact in a picture and coincidence in three-dimensional coordinates — and can we predict, before granting the figure its third dimension, which of the two readings must change and which cannot?

The [final](../../../../../commons/maps/Escher_Impossible/final.md) (`escher-impossible.coincident-images.v1`) says:

> Here, two points at different depths lie on the same ray from the marked eye position. Their images coincide. Their positions do not.

It initiates an encounter question: when images coincide without the things coinciding, can every coincidence of positions be dissolved while the coincidence of images stands exactly where it was — and what is the surviving coincidence then a fact about?

The proposition is conditional: **if the `lift` export is stepped from `"flat"` to `"lifted"` at `graph = "k5"` with everything else held, then `crossings_in_plane()` returns the identical value in both arms, `collisions_in_space()` falls to 0 in the lifted arm, and `min_clearance_m()` moves from non-positive to positive.** That is a prediction, labelled a prediction. The mappings below are readings of the passages, not their definitive literary meaning.

## Competing interpretations

- **planar-lift.interp.two-counters** (tutorial + final). *Mapping:* the two kinds of evidence are the artifact's two probe-readable counters on one configuration — `crossings_in_plane()` is contact-in-the-picture (straight-chord intersections in the table's XZ projection, computed lift-blind in `_count_crossings()`), `collisions_in_space()` is coincidence-in-3D (non-adjacent tube pairs closer than `edge_radius * 2.0 + TOUCH`, from `_measure_space()`). At `graph = "k5"`, step `lift` from `"flat"` to `"lifted"` via `apply_grid_config` and read both counters plus `min_clearance_m()` in each arm; the prediction above belongs to this interpretation. *Assumptions:* the table's top-down XZ projection stands in for "an image" — a hall visitor's eye is a different projection and is not what this counter measures; tube contact within `edge_radius * 2.0 + TOUCH` stands in for coincidence in three-dimensional coordinates; the capped resolve pass (`_resolve_space`, `RESOLVE_ROUNDS = 10`, `RESOLVE_BUMP = 0.013`) clears k5 at `lift = "lifted"` within its cap — predicted, never observed under this record. *Exclusions:* no claim about any flat drawing other than the one `_shape()` draws (Kuratowski's generality is cited in the code comments, not measured by this instrument); no claim about what a human perceives from the approach cell — only the two computed numbers; graph values `"k33"`, `"wheel"` and `"chain"` are out of scope here.
- **planar-lift.interp.control-graph** (tutorial). *Mapping:* the "different evidence" claim is genuine only if picture-contact is a fact about the pressed graph rather than about flatness itself. Hold `lift = "flat"` and compare `graph = "k5"` against `graph = "wheel"` on both counters. Prediction, labelled: the wheel reads 0 on both counters flat — its hub-and-rim drawing in `_shape()` (hub node 0, rim nodes 1..6, spoke edges `[0, i+1]` and rim edges `[i+1, 1+((i+1) % 6)]`) has no non-adjacent chord intersections — so any nonzero at k5 is evidence about k5. *Assumptions:* the wheel drawing is crossing-free as drawn — hand-checkable convex geometry, not yet run under this record; edge pairs sharing an endpoint are excluded symmetrically by both `_count_crossings()` and `_measure_space()`, so the two counters exclude the same pairs. *Exclusions:* does not exercise the lift axis at all; cannot distinguish "some crossing is necessary for k5 in every flat drawing" (the theorem) from "this drawing crosses" (what the instrument measures).
- **planar-lift.interp.clearance-threshold** (final). *Mapping:* the encounter question becomes a threshold question — where does coincidence stop being coincidence? Read `min_clearance_m()` across `lift = "flat"`, `"slight"`, `"lifted"` at `graph = "k5"`. The collision boundary is `edge_radius * 2.0 + TOUCH` centre-to-centre, and `min_clearance_m()` reports closest approach minus `edge_radius * 2.0`, so a pair counts as colliding when its clearance is below `TOUCH`. Prediction, labelled: flat reads −0.0090 m for a truly intersecting chord pair; `"lifted"` reads a positive clearance whose magnitude this record does NOT predict, because `_resolve_space()` finds the working lift rather than asserting it. *Assumptions:* clearance is computed over sampled polylines (`ARC_SAMPLES = 12`) with exact segment-to-segment distance (`_seg_seg`), so the flat case — straight chords — is exact, not sampling-dependent; the positive lifted clearance is apparatus-found, its magnitude explicitly outside this record's predictions. *Exclusions:* no numeric clearance is claimed for any non-flat lift value; `lift = "spread"` is excluded, since `_shape()` then moves node heights by `(float((i * 7) % 3) - 1.0) * LIFTS["spread"] * 0.35`, so the nodes leave the table and the comparison would no longer change one thing.

## Bounded comparison

**Baseline:** `graph = "k5"`, `lift = "flat"`, `span = 0.36`, `node_radius = 0.011`, `edge_radius = 0.0045`, `show_readout = true` — every export at its planar_lift.gd default — standing in Escher_Impossible as the map token `planar_lift:0:0.95`.

**Single change:** `lift: "flat" -> "lifted"` (`LIFTS["lifted"] = 0.07`), set through `apply_grid_config({"lift": "lifted"})`; nothing else is touched.

**Held fixed:** `graph = "k5"`; `span = 0.36`; `node_radius = 0.011`; `edge_radius = 0.0045`; `show_readout = true`; `clear_color`, `collide_color`, `node_color`, `table_color` at export defaults; the hall placement `planar_lift:0:0.95` and its host transform in Escher_Impossible; the measured projection — the table's XZ plane, since `_count_crossings()` is lift-blind by construction, which is the point of the comparison. No RNG exists anywhere in planar_lift.gd, so there is no seed to hold.

## Invented arithmetic fixture

An invented calculation, not output: peak ladder, collision threshold and resolve ceiling at `graph = "k5"`, `lift = "lifted"`, computed by hand from planar_lift.gd constants alone — `LIFTS["lifted"] = 0.07`, `edge_radius = 0.0045`, `TOUCH = 0.001`, `RESOLVE_ROUNDS = 10`, `RESOLVE_BUMP = 0.013`, and the ladder from `_rebuild()`: `peak(e) = base_h * (0.4 + 0.6 * float(e) / maxf(float(_edges.size() - 1), 1.0))`.

- Edges of k5: 5 × 4 / 2 = 10; ladder denominator 10 − 1 = 9.
- peak(e=0) = 0.07 × 0.4 = **0.0280 m**; peak(e=9) = 0.07 × (0.4 + 0.6) = **0.0700 m**.
- Collision threshold `touch_at` = 0.0045 × 2.0 + 0.001 = **0.0100 m** centre-to-centre.
- If two flat chords truly intersect, their polyline distance is 0 and `_measure_space()` records 0 − 0.0090 = **−0.0090 m** as the clearance — conditional: whether flat k5 chords do intersect is left to the run.
- Resolve ceiling: `_resolve_space()` bumps `_peaks[maxi(pair[0], pair[1])]` once per colliding pair per round, so one edge can take several bumps in a single round. A k5 edge has exactly 3 non-adjacent partners (10 minus itself minus the 6 edges sharing one of its endpoints); edge 9 (`[3, 4]`) is the higher index in all 3 of its pairs (edge indices 0, 1, 4), so its peak can rise at most 10 × 3 × 0.013 = 0.3900 m above its ladder start: 0.0700 + 0.3900 = **0.4600 m**. No other edge exceeds this, since every k5 edge has 3 non-adjacent partners and edge 9 carries both the highest ladder start and the maximal higher-index count.

Every value is a pen-and-paper consequence of the quoted constants; none is a measured output. The registry description's build-campaign measurements and the dna block's predicted_degeneracy numbers are deliberately unused, and the 0.0100 m threshold is a different quantity from the registry's "10 mm" anecdote despite the numeric coincidence.

## What could change the work

- The placement is uncommitted: if `planar_lift:0:0.95` leaves Escher_Impossible/map_data.json, or the untracked `commons/artifacts/planar_lift/` never lands, before anything runs under this record, the hall binding dissolves and both passages must be re-selected.
- Both hall texts are dirty in the working tree; if a revision changes either bound excerpt's bytes, the record must re-bind to the new text before running — the excerpts were verified against today's working-tree bytes, not a commit.
- If a flat k5 run reads `crossings_in_plane() != collisions_in_space()`, the script's own premise "Flat, the two numbers agree" fails and the two-counters interpretation is measuring a different pair of things than the passages ask about — stop and re-interpret before any lift comparison.
- If `graph = "wheel"` reads nonzero `crossings_in_plane()` at `lift = "flat"`, the control fails and red marks can no longer be read as facts about k5 rather than about flatness itself.
- If `lift = "lifted"` still reports collisions after the capped resolve pass (the plate printing FORCED FLAT at a non-flat lift), the "possibility lives in the third dimension" reading fails for this apparatus, and the question moves from the hall texts to the `RESOLVE_ROUNDS` / `RESOLVE_BUMP` caps.

## Complete cycle — planned future work, none of it begun

1. Probe the baseline: a watchdog-wrapped headless run instantiates planar_lift.tscn, sets `graph = "k5"`, `lift = "flat"`, and records both counters and the clearance. The flat-agreement debt — do the two counters in fact agree at a nonzero value? — gates everything after it.
2. Run the control: `graph = "wheel"` flat must read 0 on both counters, or the comparison stops.
3. Switch only `lift` to `"lifted"` through `apply_grid_config`, touching no other export, and read the same triple.
4. Compare against the predictions and the invented fixture; record what changed, did not change, or failed. A counter moving the wrong way and a resolve pass failing its cap are different findings.
5. Keep receipts — probe script, raw printed triples, tree state — bound to this record beside [experiment.json](./experiment.json).
6. Walk Escher_Impossible to the placement's approach cell and compare the plate's printed count against what a standing eye reports; the final's passage is standpoint-relative while the counter is one fixed projection, and that gap is held open, not smoothed over.
7. Review tutorial and final independently against the evidence — revise, retain with reasons, or keep a question open — then choose the next experiment from the observed result or difficulty.

## What remains open

Everything: execution (no probe, capture or walk has run under this record's identity); observation (the [observation log](observations.md) is empty); the tutorial review and the final review (both [pending](revision.md)); the human encounter at the approach cell; and independent reconstruction of the instrument or comparison from this written record. The [text simulation](text-simulation.md) is a hypothesis, not a head start on any of these.
