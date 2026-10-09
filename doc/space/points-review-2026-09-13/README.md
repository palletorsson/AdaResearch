# Noise Types — which rules keep acting?

Independent review of Fable's N1 work, completed 13 September 2026.

Review: http://localhost:3003/research/possible-bodies/random-noise-types.html

Primary encounters: http://localhost:3003/necklace/thread?map=Random_Noise_Types&role=primary

## What the room now argues

`randompoint` and `randompoints` are primary, in that order, with matching final.md anchors and book hero. One repeatedly clips local coordinates to a bounded plane. The other applies minimum spacing when generating points, then lets a visitor carry them into previously refused relations. Two artifacts earn their place through the difference between them. Both spectrum galleries remain secondary, placed and explicitly described as displays rather than measurements of the bench or audio.

The first point now has an optional `stand:bounds` frame, a cased invitation, and legible moving coordinates. It moved from (5,1) to (3,2), faces 90°, and has its origin raised 1.25 m. A clear rectangle reserves its approach. The map's structure and utilities are unchanged. All four named artifacts are matched and placed; none is refused or added by the museum pack.

The bench retains its matched 0.90 × 0.90 × 0.12 m slabs, shells and four controls. LOAD x1 / x4 is a fifth local button. It changes 24 to 96 without changing the 0.130 m spacing or volume. The plate now fits all its text within its casing.

## Corrections to the earlier handoff

- The ghost cap is not a refusal count. Every candidate is counted; only the first 220 refusals are drawn.
- Exhausting 100 attempts per requested slot does not establish maximal packing or prove that no admissible position remains. The plate now states the finite budget.
- Three coincident points make three pairs. The observer previously estimated pair count from the number of red points; it now counts each pair.
- Gaussian candidates count as candidates, with zero spacing refusals. Its readout never claims it applied the spacing rule. RESTORE immediately recomputes its naturally close pairs.
- The two clouds consume consecutive parts of one RNG stream. They are not identical proposals with different filters. The book says so.
- The single point's dropped callback clips; it does not resample. Its identity comment and book account now agree on that action.
- The old technical chapter's spatial-hash/active-list sampler and generic pink-noise pseudo-code did not describe this artifact. The replacement uses six verified source excerpts across final/tutorial/technical.

## Evidence

Final run: **84 checks, 0 failures, engine exit 0**, PID 37904, 07:56:54–07:57:39 +02:00. The runner inventories processes before launch, owns its hidden offscreen Godot window and logs, and uses an isolated snapshot of the saved necklace hand. Source hashes were stable during the run and the original hand was unchanged.

The actual project desktop pointer presses the controls, carries a bench point and picks up/releases the single point. Deliberate direct-coordinate interventions are separately identified: clipping outside all bounds and a three-point pair-count stress case. This is a test rig in the real museum, not a claim about input in the museum's default walker or tracked headset.

Seed 31415, request 96: 5,507 candidates, 49 accepted, 5,458 refused, 47 unfilled slots and 220 ghost instances. Independent Python calculations check bounds, all retained rejected candidates against accepted centres, closest-pair distances and exact accounting. The review's interactive front/top views use captured coordinates, not a browser reimplementation of the generator.

Returning LOAD repeats generated home coordinates exactly. Live point coordinates differ by at most 0.000000476837158203125 m after engine transform updates. The first run incorrectly compared live positions for bitwise equality and is retained in `first-run/`. The following 83-check pass is retained in `passed-before-readout-fit/`; it exposed a last line outside the enlarged readout. The final run adds a measured text-bounds check and verified capture.

`verification.json` contains counts, geometry calculations, map changes and diagnostics. `publication-manifest.json`, `publish-targets.json` and `publish-hashes.json` describe the local review publication. HTTP and browser records are saved alongside them. The final runtime evidence is in `ada_run/points-review-2026-09-13/Random_Noise_Types/`.

## Remaining boundaries and next work

Headset reach, comfort and Quest performance remain deferred while the user is remote. The secondary galleries need their own audio/control/spectral review. Existing engine startup diagnostics include a missing UID, certificate-store and logger failures, unsupported compatibility-renderer features and shutdown object leakage; there are no script or shader errors in the accepted run. Their exact lines are retained in verification.json.

One unrelated WCN role/book mismatch remains in Noise_Voxel (two primaries, one anchor); see `other-hall-mismatches.json`. No claim is made that all later halls are reconciled.

**Next: Noise_Columns.** A field acts on an already formed column. Carry the distinction between a field, the form that receives it, and the rule that turns sampled values into displacement. Inspect Fable's existing hall before changing it.

Reusable repair: whenever an artifact reports failed construction, distinguish attempted candidates, accepted objects, refused proposals, unfilled requests and the visible evidence budget. Whenever it shows a rule, ask whether that rule runs at generation, on every update, on interaction, or only in the observer.

Browser verification: seven recorded states cover the three constructions, front/top projection, ghost visibility, the review chapter and both primary cards. The live cards contain 271 and 616 words respectively and both passages open. A space after `@` in the initial anchors prevented the site parser from recognizing them; the anchors now use the site's exact `<!-- @token -->` syntax, and the validator matches its token grammar. All 57 published files return HTTP 200 with matching source hashes.
