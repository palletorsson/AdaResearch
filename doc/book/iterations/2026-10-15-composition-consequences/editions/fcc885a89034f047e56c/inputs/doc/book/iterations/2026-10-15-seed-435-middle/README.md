# A shared beginning: 435

15 October 2026. Palle asked to remove the standalone lava experiment from the final, explain seeds through the Geiger, and distinguish perceived randomness from its production. When the runtime audit found exceptions, he explicitly requested enforcement throughout the hall.

## Editorial result

The final keeps the approved shared “we” voice. Its five tagged encounters follow the room’s full order: moving spheres → RAND book → Geiger → MOVE / KEEP → Out / Back. The window and virtual lamps appear together in the Geiger passage as different uses of 435. The lamp sensor experiment remains optional and Tutorial-tagged. Magnet coordinates, room placements and conceptual links were not rearranged. The 48-value bench remains the first research pilot.

The middle distinguishes a number kept on the page from a beginning kept for generation. A seed establishes initial state; repeated requests advance state without changing that seed. A repeated curve can remain difficult to anticipate. A gesture supplies a new input while subsequent calculation remains pseudorandom. Offline does not imply isolation from physical inputs: the final’s hardware-RNG and NIST references bound the claim to deterministic calculation from fixed state and inputs.

The [previous final](before/final.md), [wall](before/writing_wall.json) and [plan](before/final-plan.md) are preserved. Current plans: [final](../../course/text-plans/Random_Definition/final.md), [tutorial](../../course/text-plans/Random_Definition/tutorial.md). Prose and code counts are separate in [text-counts.json](text-counts.json).

## Runtime contract

- Each new Random Definition scope begins at **435**, using the [original saved receipt](../../../../algorithms/randomness/seed_replay/opening_seed.json). No arrival requests a new atmospheric draw.
- The moving-hand study, colour window, falling page, Geiger, virtual lamps, Out / Back, crank, register film, slot machines, TRNG/PRNG illustration and 48-value bench use the same hall seed. Each owns its stream and draw order. Optional instruments join the current seed when loaded. Another room has independent state.
- Manual selection and SEED +1 are deliberate choices. RESET 435 restores the saved beginning. A completed gesture or explicitly restored record can supply another seed in 0–999. A saved visit can restore its recorded choice. The original 435 receipt remains unchanged.
- The hall’s source console offers NUMBER, HAND, RESET 435 and REPLAY. Clock, frame, system and fresh online acquisition are disabled. Late atmospheric replies cannot replace the seed. The independent frame trace still measures intervals and clearly states that it does not reseed the room.
- Seed changes check every participant first. A held hand/body, active gesture recording or spinning slot blocks the whole change. No instrument silently advances another’s stream. Layout refreshes do not overwrite the selected seed.
- Geiger and lamp rate/clock/sensor settings remain explicit experimental conditions. Replay requires the same conditions and observation time as well as the same seed. The lamp capture retains its tick. Hand paths use a separate Y stream derived from `hall seed + 1`, preserving shared X. The small integer models map seed 0 to internal state 1; distinct seeds are not promised distinct outputs.
- New hand, Geiger and lamp records retain the hall source receipt. Their replay restores that receipt across the hall. The existing 48-value format retains its seed, generator state and authoritative stored values; older records without acquisition receipts are labelled as saved records. Legacy mixed-seed comparisons are refused in this one-seed hall.
- The TRNG illustration’s calculated signals are labelled as models. In this hall both panels display their actual seed; no attached physical sensor is claimed.

The coordinator is [hall_seed.gd](../../../../commons/artifacts/randomness_space/hall_seed.gd). Museum ancestry enables it through `em_map=Random_Definition`; desktop map tokens carry `hall_seed:435`. Existing artifacts outside this hall retain their source controls.

## Task ledger and evidence

- [x] Audit defaults, global draws, fresh acquisition and saved-state paths.
- [x] Connect all eleven instrument types to the shared seed with private streams.
- [x] Replace fresh-source controls in this hall; preserve the measured frame study.
- [x] Verify explicit choices, zero, reset, independent streams, gesture propagation and retained provenance.
- [x] Verify refusal during held hand/body interactions and active recording; verify room isolation and late joining.
- [x] Keep the falling page animated and preserve touched digits while rows flow.
- [x] Update final, tutorial source, wall tags/notes and both current plans. Verify Final-tag order matches chapter markers; preserve magnet positions and conceptual connections.
- [ ] Read the new middle with a person: does keeping digits create a need to ask what a seed keeps? Can they distinguish the seed from advancing state and gesture input from a new kind of generator?
- [ ] Verify headset interaction and performance in the complete room; independently reconstruct the experiment from the tutorial.
- [ ] Find and keep two different gestures with the same derived seed, or record why that is not a useful next experiment. This remains a hypothesis, not a reported result.

Three Godot 4.6 headless runs pass:

| Check | Evidence |
| --- | --- |
| Eleven instrument types, manual/gesture seed changes, replay and provenance, global RNG isolation, held-interaction refusal, late joining and separate scopes | [Hall seed test](hall-seed-test.log) |
| Actual XR Tools hand target, unaffected head/body/controller/other hand, withdrawal and restoration | [Hand test](hand-test.log) |
| Continuous Geiger playback, embedded controls, falling-page selection and Out / Back movement | [Interface test](interfaces-test.log) |

No script errors or test failures were reported. Existing Jolt solver-bias and missing-environment warnings remain; the interface run also reports ObjectDB objects at shutdown. Headless correctness is separate from headset performance, physical sensation, reader comprehension and independent reconstruction.

## Reproduce

Run Godot with `--headless --xr-mode off --audio-driver Dummy --path . --script` and one of:

- `tests/test_random_definition_seed.gd`
- `tests/test_random_touch_hand.gd`
- `tests/test_random_hall_interfaces.gd`

Rebuild the tutorial with `node doc/book/iterations/2026-10-15-seed-435-middle/build-tutorial.mjs`. This iteration’s [tutorial-source.md](tutorial-source.md) contains the prose; the builder embeds the current three hand-study files. The hall controller is an explicitly inherited project dependency. Earlier iteration sources remain historical.
