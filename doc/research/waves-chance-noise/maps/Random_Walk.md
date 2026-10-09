# Random_Walk

**Active hall 4 in randomness. Batch: R1. 129 desktop checks passed; terrarium preserved; text aligned; headset pending.**

[Current review, images and listening](/research/possible-bodies/random-walk.html)

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## What does a trail remember that the next step does not use?

Body/layer: An agent, its accumulated position and a bounded enclosure.

Proposed primary encounter: `random_walk_terrarium`.

## Starting evidence

The existing logbook terrarium remains the one primary. Three complete 300-step, five-walker histories at seed 31415 replay after deleting trail memory and selecting ALL. The trail keeps previous positions and omits wall contacts. The lab observation-window string parser is repaired. All twelve placements and recovered museum geometry remain.

Current map dimensions: {'width': 13, 'depth': 14, 'max_height': 3}. Current final: 958 words.

Current primaries: random_walk_terrarium. Book anchors: random_walk_terrarium.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Preserve the dark backboard, enlarged red bead, keypad and logbook wing at the existing cell (4,1).
2. Seven controls checked: 2D/3D/LEVY/RESET and ONE/ALL/NEW SEED. There is no visitor pause or seed-entry field.
3. Use the existing boolean parser for the pavilion window token; preserve floor, raised cells and clearance.
4. Later: tracked-hand reach, fine trail/lettering visibility and headset performance; recorded startup diagnostics.

## Revise final.md

1. Let a suggestive trail invite a prediction without declaring every prediction a failure.
2. Compare attempted movement, reflected endpoint and the previous-position drawing; wall contacts and the current bead are omitted from that line.
3. At equal step counts the named procedure replays. ONE/ALL changes observation while all five continue; the generator still has state.
4. Read a two-second frame against five accepted steps. Distinguish bounded five-body MSD from history, path length and entropy; continue to Random Gaussian.

**Code to trace and quote after implementation:** random_walk_terrarium.gd: mode/step generation, boundary reflection, trail retention and timestep accumulator. Verify RESET's seed policy instead of promising replay from its label.

## Evidence to return

- 129 independent desktop checks, zero assertion failures, exit 0. No headset test.
- Three 300-step histories, five walkers each, seed 31415. Every frame replayed after clearing trails at step 60 and selecting ALL.
- Actual proposed steps exported without consuming extra draws; three mode images share a camera.
- Existing controls, desktop pointer, reflection, catch-up, bounds, reach, museum routes and unload/rebuild exercised.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Keep the creatures suggestive enough to invite misreading. A readable trace should let the reader test that affection rather than being told it is wrong.

**Reusable method:** R2 housed readout; R3 explicit time; R6 local state/seed.

## Open and inspect

- Map: `commons/maps/Random_Walk/map_data.json`
- Book and supporting texts: `commons/maps/Random_Walk/`
- [Primary view](http://localhost:3003/necklace/thread?map=Random_Walk&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=randomness&room=Random_Walk)
- `res://commons/artifacts/random_walk_terrarium/random_walk_terrarium.tscn`
- `commons/artifacts/random_walk_terrarium/random_walk_terrarium.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
