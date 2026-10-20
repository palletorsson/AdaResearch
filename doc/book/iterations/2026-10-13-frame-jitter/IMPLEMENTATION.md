# The time between frames

The existing linked Random Definition exhibit now creates `frame_jitter_scope.gd` beside its source console. Other seed benches remain unchanged. The existing map and museum plan already place the linked bench and travelling sphere; no new map token or registry entry is needed. The linked sphere's visibility bounds now include this side instrument.

## Measurement and display

- LIVE calls `Time.get_ticks_usec()` once per application process callback. It observes intervals between these callbacks, not raw CPU timing or a sensor stream. The first callback anchors the measurement.
- A rolling buffer keeps at most 240 intervals. Plot x is frame index, not uniformly spaced physical time. The display gives the summed interval duration.
- The initial reference is the mean of the first 30 intervals, then remains fixed. REBASE uses the current buffer's mean. The reference is never described as an ideal refresh rate.
- A kept recording's reference is its own mean. The input intervals remain unchanged when the display range or reference changes.
- Automatic range starts at ±0.25 ms and doubles to include the largest deviation. Fixed ranges are ±0.25, ±1, ±5 and ±20 ms. Out-of-range samples are counted and their incoming segments marked amber.
- LIVE samples every callback but redraws at most 10 times per second. Graph rendering, labels, the probe and the rest of the scene can themselves influence timing. This is not an isolated hardware benchmark.
- HOLD stops live sampling. Returning to LIVE clears the buffer and resets the timestamp anchor so the pause does not become a spurious long interval. REBASE and HOLD do not interrupt a seed recording.

## Seed integration

FRAMES retains the existing 120-interval, `frame-intervals-v1` seed recipe. The first process callback establishes the start, avoiding a partial button-to-frame sample. Every accepted interval goes both into the receipt and into the graph. After the 120th interval, the receipt is hashed, the seed supplies the grids and journey, and the graph holds that exact recording. A source switch or replay cancels unfinished collection.

Selecting a kept FRAMES source or replaying it restores the recorded trace. Watching LIVE afterwards is an independent observation: it does not resample the seed or advance the journey RNG. If another source is selected while an old frame recording is displayed, the scope still explicitly labels that retained recording and its own seed. Its label is distinct from the active source console.

The encoding is `frame-intervals-v1\n` followed by comma-separated integer microsecond intervals. SHA-256 hashes this string; the first four digest bytes are decoded as a little-endian unsigned integer and reduced modulo 1000. The small exhibit range allows collisions and is not a cryptographic seed service. Even perfectly constant intervals yield a hash.

## Reproduce

```powershell
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-frame-jitter/museum_probe.gd --output-tag frame-jitter-20261013
```

The probe retains the previous source bank, movement, grid, carry and replay checks. It adds constant timing, a controlled spike, range clipping, baseline calculation, hold/resume, bounded history, actual live sampling, exact capture-to-graph correspondence and independent hash reproduction. The screenshots use an actual desktop frame recording, not the synthetic timing fixtures used for numerical tests. The magnified image shows the same recording at another scale.

No physical Quest run, entropy estimate, network request, APK replacement or canonical tutorial/final edit is claimed. Existing museum startup warnings include unused registries and effects unsupported by compatibility rendering; the isolated loader also reports its existing safe entry fallback. The focused report records the successful runtime checks separately.

## Sources

- [Godot 4.6 Time](https://docs.godotengine.org/en/4.6/classes/class_time.html): elapsed monotonic ticks in microseconds. The unit is not an entropy claim.
- [Godot 4.6 Crypto](https://docs.godotengine.org/en/4.6/classes/class_crypto.html): the local random-byte API remains a separate source.
- [NIST entropy source definition](https://csrc.nist.gov/glossary/term/entropy_source): an entropy source involves a noise source and health testing; this display has not established one.
