# Geiger counter / 14 October 2026

Palle requested a HotBits-like simulation with Geiger-style random sound. Built `geiger_counter` in `Random_Definition` at `(1,6)`, yaw 90, opposite the lava wall. It is a regular registry artifact with an attached reach board and ordinary map-editor placement. All pre-existing placements are preserved.

The apparatus generates a versioned ideal Poisson event trace from an explicit seed. It synthesises one six-millisecond electronic click per event into a complete audio buffer, then plays the recording spatially. Rendering-frame timing does not schedule the individual clicks. A pulse lamp, recent-count needle, timeline, interval comparison and bit cells expose the relationships. No physical detector, live radiation measurement or HotBits API connection is claimed. NEW supplies a system seed to the same simulation; it does not change the source classification to radioactive entropy.

Reference: [HotBits](https://www.fourmilab.ch/hotbits/) and its [interval-comparison description](https://www.fourmilab.ch/hotbits/how3.html). The radioactive service was retired at the end of 2022. The oscillator frequencies and envelopes are authored sound-design choices, not measurements of a particular counter. The Ada sound-engineer synthesis workflow was applied to this local instrument; no music genre bank or sequencer was altered.

## Verification

- **35/35** checks in the real isolated museum: `museum.json`, `museum.log`. Final run `ada_run/encounter_pilot/Random_Definition/geiger-04`. Checks cover deterministic events, interval grouping and alternation, tie rejection, real control-area events, clock-only and rate-only comparisons, audio format/headroom, actual playback, settled pause/resume, disk keep/replay and a fresh instance restoring the trace. No script errors. Normal museum portal fallback and shared Jolt warnings remain outside this change.
- Audio-thread startup and mix boundaries are asynchronous. The probe waits for playback startup and lets the already queued mix finish before checking a settled pause; the two recorded paused positions are identical. Transport state now also records that a playback has been started, instead of relying on an immediately queried audio-thread flag.
- `reconstruction.json`: a separate Python implementation reconstructs all 96 timestamps and the bit comparisons. The one-millisecond clock emits 24 bits; the 100-millisecond clock emits 19, with five tied comparisons skipped. Both have the same event trace. This is automated evidence, not an independent visitor reconstruction.
- `audio.json`: the 24.464-second mono WAV has a pulse at every event, no nonzero samples outside the 96 pulse windows, and peak PCM magnitude 11910/32767. The coarse-clock and baseline buffers are byte-identical. Audibility/timbre preference in a headset remains a human check; no listening judgement is fabricated.
- `geiger-preview.wav`: default seed 435, mean rate four per second, 96 events. Raw WAV preview; the museum additionally uses spatial attenuation and -12 dB playback gain.
- `geiger-counter.png`, `geiger-board.png`: inspected desktop renders. The control board is within standing reach and its approach has floor support. No headset comfort or performance acceptance claimed.
- `comparison.json`: preserved baseline/coarse-clock pair. `before/` preserves prior map and registry content. `registration.json` checks the single new cell and unchanged earlier registrations.

The refreshed course inventory resolves all 113 distinct placed artifacts across 31 halls. Broader plan validation passes 71/72: an existing plan receipt for `doc/book/experiments/validate_experiments.py` differs from the current file. That validator was not changed for this instrument; its receipt was left intact. See `verification.json`.

## Research loop

The [tutorial](../../experiments/random-definition/geiger-001/tutorial.md) and [provisional interpretation](../../experiments/random-definition/geiger-001/final.md) can both initiate or revise experiments. The first 48-value seed bench remains in place. This instrument is an additional local study, with no automatic transfer to other halls.

Built: recorded baseline, one-condition comparisons, keep/load/replay, and an independent executable reconstruction. Still open: listening observations, headset usability, a visitor reconstructing from the tutorial, and the resulting decision to revise an apparatus or passage. A useful first question is whether clusters and gaps sound suspicious, deliberate or unhelpful—and whether changing the clock changes that interpretation when the sound itself is unchanged.
