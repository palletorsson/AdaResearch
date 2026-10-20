# Listen to the gaps

`geiger_counter` is on the west wall of `Random_Definition`, cell `(1,6)`, across the room from the lava wall. It is a normal independently movable/removable registry artifact. Press **PLAY / HOLD** on its rectangular button board to hear the recorded simulation. **SOUND** mutes without changing the events. Sound is spatial, with a six-metre maximum range; the device does not autoplay when the hall loads.

Each electronic click corresponds to one simulated detection. The pulse lamp flashes, the needle follows recent counts, and the cursor crosses the event timeline. The full trace and its derived bits are available for inspection before playback; this is a recorded model, not a claim to be measuring live radiation. Cyan means zero, amber one, and mauve a skipped pair.

1. **RESET 435** establishes seed 435, a mean rate of four detections per second and a one-millisecond measuring clock. **PLAY** it. Describe the clusters and gaps before naming them as random or patterned.
2. **RATE** compares eight detections per second against that baseline, retaining the same pseudorandom draws and clock. Replay and compare the rhythm. The finite trace contains 96 events, so the faster version is shorter. It is not a fixed-duration count comparison.
3. **CLOCK** returns to the baseline seed and rate and changes the clock to 100 milliseconds. Every click and every event timestamp remains identical. Which interval comparisons now become ties? This tests the measuring apparatus, not a changed source.
4. **BASELINE** adopts the current trace if you want a different starting point. Subsequent RATE/CLOCK changes are each relative to that retained baseline. **NEW** changes only its seed, obtaining four bytes from Godot's Crypto API; the result is still labelled a system-seeded simulation.
5. **KEEP** saves both records in `user://geiger_counter/`. **REPLAY** restores and plays that pair. **LOAD** finds the latest valid pair after re-entering the hall. **RESTART** repeats the current trace without needing a kept copy. No replay requests new source data.
6. Reconstruct a saved pair with `python -X utf8 doc/book/experiments/random-definition/geiger-001/reconstruct.py PATH_TO_RECORD.json`. Record any missing instructions. Independent code verification is not a substitute for an independent visitor attempting the tutorial.
7. Propose a change from what you heard or observed. Either this tutorial or `final.md` may start or revise the experiment. For example: conceal the seed, change the clock again, or compare a metronome with the same mean rate. Preserve observations separately from predictions.

## Inspect the recipe

Version `ada-geiger-1` models stationary ideal Poisson detections. Starting from an integer seed, repeat `s = 48271*s mod 2147483647`, take `u = s/2147483647`, and compute the next waiting time as `-ln(1-u)/rate`. Round to microseconds, with a minimum of one microsecond, then accumulate 96 timestamps. This is an idealised short observation: no detector dead time, missed pulses, changing source activity or physical hardware noise is modelled. Rate is not a radiation dose or a calibration.

The HotBits-inspired comparison uses four distinct events: measure the first-to-second and third-to-fourth intervals, quantise each duration to clock ticks, discard equality, otherwise compare their lengths. The ordinary comparison gives zero for the shorter first interval and one for the longer; reverse this rule after each emitted bit. This follows the timing idea described by [Fourmilab](https://www.fourmilab.ch/hotbits/how3.html), without its physical input.

The complete sound is rendered into mono 44.1 kHz, 16-bit PCM before playback. Each timestamp starts a six-millisecond pulse: two damped sine components at 2300 and 6100 Hz, a 0.1 ms attack and 1.1 ms exponential decay. Overlapping pulses mix with bounded headroom. Sound is generated from the event list, independently of rendering frames and the measuring clock. Changing the clock must produce byte-identical audio; frame hitches must not turn a cluster into a single newly scheduled sound.

Saved JSON includes seed, rate, clock resolution, provenance, microsecond event times, interval comparisons and sound recipe. Import validates it against the versioned model. The raw event list remains the record of what this version produced; a changed recipe requires a new model version.
