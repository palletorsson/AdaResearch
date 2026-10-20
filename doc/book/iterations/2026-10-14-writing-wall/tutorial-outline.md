# Random_Definition — tutorial planning outline

Draft encounter order shared with the room plan. This is not the authored tutorial.md.

## 1. Seed Study — 48 Values / Five Spatial Assignments

Artifact: seed_study

48 stored values become colour, bars, colour + height, size and rotation.

Question: What is allowed to change when the numbers stay?

Reconstruct the five assignments from one stored sample. Compare one cell; preserve the mapping and version.

## 2. Seed Replay Demo

Artifact: seed_replay_demo

Paired colour windows replay a seeded stream. The right window can change RGB assignment and output range while the left remains a baseline. Discarding one draw is a separate intervention.

Question: Where do the numbers act, and within which range?

Keep the left window as baseline. Compare RGB / red-only / swapped channels and full / narrow range on the right. Keep the seed and draw count fixed.

## 3. Out / Back — the carried point

Artifact: random_return

Hold the sphere to travel out and back. Direction and distance are sampled; returning is prescribed.

Question: How much freedom does the rule permit?

Trace two draws into angle and distance; distinguish a sampled destination from the authored return.

Proposed change: Compare ranges or direction sectors while preserving the same draws; retain collision-aware carrying.

## 4. PRNG Crank Machine

Artifact: prng_crank_machine

Each crank advances a visible deterministic state.

Question: What must we know to predict the next value?

Step, reset and reproduce the state transition. Separate seed, state and output.

## 5. A number has a previous state

Artifact: film_prng_register

A supporting view of a pseudorandom procedure.

Question: Which hidden step becomes visible here?

Use beside the crank as a closer examination of the implementation.

## 6. Time / frame study

Artifact: seed_replay_demo/frame_timing

Measures application frame intervals. Irregular timing is not an entropy estimate.

Question: Does looking irregular tell us where uncertainty came from?

Hold a trace, change display range, and distinguish recorded timing from a seeded sequence.

Note: Distinguish a changing display, an irregular measurement, a seed, a PRNG sequence and a physical entropy source. The frame monitor measures variation; it does not establish entropy.

## 7. Seed movement sphere — MOVE / KEEP

Artifact: seed_replay_demo/movement_sampler

Records movement and derives a seed from the recording.

Question: What survives when a gesture becomes an integer?

Capture, retain the receipt, replay. Separate fresh movement from reuse of its derived seed.

## 8. Seed source console

Artifact: seed_replay_demo/source_console

Chooses among a number, hand recording, clock snapshot, frame intervals, system random and saved atmospheric input.

Question: What changed: source, record, seed or use?

Trace the provenance of one kept seed into separate colour and journey generators.

## 9. Random Number Book Page 1955

Artifact: random_number_book_page_1955

Recalls RAND’s published random-number table through an authored page of falling digits.

Question: How can chance become addressable and reusable?

Distinguish stored outcomes from regenerated ones. Record where reading begins.

## 10. TRNG vs PRNG

Artifact: trng_vs_prng

A comparison exhibit about physical sources and deterministic generation.

Question: What evidence distinguishes origins, beyond appearance?

Compare the declared source and generation procedure. Inspect implementation before treating any simulated stream as physical entropy.

## 11. Lava Wall — What Can You Predict?

Artifact: lava_entropy_wall

Virtual lamps, a synthetic sensor and processing produce a repeatable record. This is a simulation.

Question: How does the observation rule participate in the result?

Hold the lamp model fixed; change the sensor mask; keep and replay the receipt.

## 12. Geiger Counter — Counting the Gaps

Artifact: geiger_counter

Simulated detection times become electronic clicks and interval-comparison bits.

Question: Can the same events say something different through a different clock?

Compare 1 ms and 100 ms clocks on one trace; reconstruct the extracted bits.

## 13. Slot Machine

Artifact: slot_machine

A familiar lever turns sampled symbols into anticipation and counts.

Question: What do counts retain of an individual encounter?

Separate an outcome, its mapping and a histogram. Continue into Random Entropy.

## Unattached notes



## Connections

- Seed Study — 48 Values / Five Spatial Assignments → Seed Replay Demo: same values, another assignment
- Seed Replay Demo → PRNG Crank Machine: open the procedure
- Time / frame study → Seed source console: irregular is not certified entropy
- Seed source console → Seed Replay Demo: a kept number becomes a seed
- Lava Wall — What Can You Predict? → Geiger Counter — Counting the Gaps: change measurement; preserve events
