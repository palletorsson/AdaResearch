# Random_Gaussian

**Active hall 5 in randomness. Batch: R1. 156 desktop checks passed; book aligned; headset pending.**

[Current review, images and listening](/research/possible-bodies/random-gaussian.html)

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## What can many draws reveal that one draw cannot?

Body/layer: A distribution, a finite histogram and its clipped edges.

Proposed primary encounter: `distribution_sampler`.

## Starting evidence

The existing sampler remains the primary. Corrected logarithm guards prevent invalid values; issued draws reserve the cap, CLEAR removes old meshes, and markers land at the drawn bars. The orange shape now stays inside the panel with its own scale labelled. Geometry and secondary artifacts remain.

Current map dimensions: {'width': 14, 'depth': 22, 'max_height': 6}. Current final: 912 words.

Current primaries: distribution_sampler. Book anchors: distribution_sampler.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Preserve the existing cabinet, outboard panels, headline and six-line account.
2. Nine controls: PAUSE toggles issuance while flight lands; CLEAR preserves paused state; BATCH reserves airborne capacity; BINS regroups retained values.
3. Blue and pale counts share a scale; the orange ideal shape has its own peak scale inside the panel.
4. Later: tracked-hand approach, small lettering and headset performance; recorded engine startup diagnostics.

## Revise final.md

1. Compare GAUSS and UNIFORM at N=300 after PAUSE and CLEAR; do not invent exact sparse outcomes or controls.
2. The Gaussian is constructed directly; extra UNIFORM draws do not change its law into a bell.
3. Rebin retained values and read changes in estimates from bin centres; separate edge counts from clipped values.
4. Distinguish clamping from the previous hall's reflection. Carry the choice of varying properties into Random Mushrooms.

**Code to trace and quote after implementation:** distribution_sampler.gd: sample generation, _clear_samples, theoretical curve, clamping and bin assignment. Verify sample_seed and mode-specific formulas.

## Evidence to return

- Independent source, control and desktop checks; final receipt linked from the review.
- Four common-seed samples, deep-copied count snapshots, replay and rebin comparisons; an explicitly selected exponential edge example.
- Injected logarithm endpoint inputs; flight/batch cap; synchronous CLEAR cleanup; actual bar landing; orange curve bounds.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Use colour, falling beads or another trace if it clarifies aggregation. Keep the strange early samples visible rather than smoothing them away.

**Reusable method:** R1 controlled comparison; R2 housed readout; R7 measurement contract.

## Open and inspect

- Map: `commons/maps/Random_Gaussian/map_data.json`
- Book and supporting texts: `commons/maps/Random_Gaussian/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Gaussian&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Gaussian)
- `res://commons/artifacts/distribution_sampler/distribution_sampler.tscn`
- `commons/artifacts/distribution_sampler/distribution_sampler.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
