# Random_Definition — tutorial planning outline

Only artifacts tagged tutorial, in shared room order. Numbers are room stops. This is not the authored tutorial.md.

## 1. Seed Study — 48 Values / Five Spatial Assignments

Artifact: seed_study

48 stored values become colour, bars, colour + height, size and rotation.

Question: What is allowed to change when the numbers stay?

First pilot: keep the 48 values, seed, mapping parameters and version. Compare one cell across colour and height; change only its assignment. Preserve the comparison and replay it. Rebuild the mapping independently, then use the observation to propose one further change. These 48 scalar values are a different experiment from the paired RGB grids.

## 2. Seed Replay Demo

Artifact: seed_replay_demo

Paired colour windows replay a seeded stream. The right window can change RGB assignment and output range while the left remains a baseline. Discarding one draw is a separate intervention.

Question: Where do the numbers act, and within which range?

Carry the assignment question into paired RGB grids. Keep the left window as baseline; change only channel assignment or range on the right, with seed and draw count fixed. Test +1 DRAW separately. Record seed, request order and mapping so a reconstruction can distinguish these interventions.

## 4. PRNG Crank Machine

Artifact: prng_crank_machine

Each crank advances a visible deterministic state.

Question: What must we know to predict the next value?

Open the procedure behind the two benches: step, reset and reproduce a state transition. Separate initial seed, current state, draw count and displayed output. Use the adjacent register as optional close inspection rather than a second lesson.

## 6. Time / frame study

Artifact: seed_replay_demo/frame_timing

Measures application frame intervals. Irregular timing is not an entropy estimate.

Question: Does looking irregular tell us where uncertainty came from?

Compare the stepped generator with a held frame-interval trace. Keep the trace and change only display range. Distinguish a frame count, a measured interval and a pseudorandom draw; none establishes physical entropy by appearance.

Note: Distinguish a changing display, an irregular measurement, a seed, a PRNG sequence and a physical entropy source. The frame monitor measures variation; it does not establish entropy.

## 7. Seed source console

Artifact: seed_replay_demo/source_console

Chooses among a number, hand recording, clock snapshot, frame intervals, system random and saved atmospheric input.

Question: What changed: source, record, seed or use?

Record the provenance of one kept number: source mode, captured input or receipt, conversion and resulting seed. Trace it into the colour and journey generators. Reusing the number replays a deterministic procedure; a fresh request is a separate operation.

## 8. TRNG vs PRNG

Artifact: trng_vs_prng

A comparison exhibit about physical sources and deterministic generation.

Question: What evidence distinguishes origins, beyond appearance?

Compare the declared source and generation procedure. Inspect implementation before treating any simulated stream as physical entropy.

## 9. Seed movement sphere — MOVE / KEEP

Artifact: seed_replay_demo/movement_sampler

Records movement and derives a seed from the recording.

Question: What survives when a gesture becomes an integer?

Capture, retain the receipt, replay. Separate fresh movement from reuse of its derived seed.

## 11. Lava Wall — What Can You Predict?

Artifact: lava_entropy_wall

Virtual lamps, a synthetic sensor and processing produce a repeatable record. This is a simulation.

Question: How does the observation rule participate in the result?

Hold the lamp model fixed; change the sensor mask; keep and replay the receipt.

## 12. Geiger Counter — Counting the Gaps

Artifact: geiger_counter

Simulated detection times become electronic clicks and interval-comparison bits.

Question: Can the same events say something different through a different clock?

After changing the lava sensor mask, test a different measurement rule: compare 1 ms and 100 ms clocks on one simulated event trace. Reconstruct the interval-comparison bits. Keep the trace, clock and extraction rule, record an observable difference or a failed hypothesis, then propose one apparatus revision.

## Other notes (retained outside this text path)



## Conceptual connections (may refer beyond this text path)

- Seed Study — 48 Values / Five Spatial Assignments → Seed Replay Demo: same values, another assignment
- Seed Replay Demo → PRNG Crank Machine: open the procedure
- Time / frame study → Seed source console: irregular is not certified entropy
- Seed source console → Seed Replay Demo: a kept number becomes a seed
- Lava Wall — What Can You Predict? → Geiger Counter — Counting the Gaps: change measurement; preserve events
