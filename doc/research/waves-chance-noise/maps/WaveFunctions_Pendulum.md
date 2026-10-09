# WaveFunctions_Pendulum

**Active hall 2 in wavefunctions. Batch: W1. Runtime report reviewed; actual input and headset pending.**

[Read the shared handoff](../HANDOFF.md) · [All maps](../all-maps.md)

## Where does a movement put its past?

Body/layer: A moving bob and a finite spatial record.

Proposed primary encounter: `PendulumWave`.

## Starting evidence

W1 now integrates on physics ticks and records timestamped positions under 300-mark and 10-second limits. FINE requests 25 ms; actual gaps at 60 Hz alternate around 16.7/33.3 ms and are visible on the housed readout. COARSE requests 200 ms; STROBE follows the measured period. Frame, panel and history lane are staged in the open south half. Map-controlled placement and recovered platforms retained. See w1-review.html; reach, collision and rendered appearance are unverified.

Current map dimensions: {'width': 13, 'depth': 21, 'max_height': 4}. Current final: 656 words.

Current primaries: PendulumWave. Book anchors: PendulumWave.

Source agreement is not proof of runtime reachability or lesson quality.

## Build the encounter

1. Stage the bob and trace side-on with an unobstructed view along history. Place the numerical display beside the trace, not over it.
2. Show retained samples, sampling policy and retained duration. Prefer a bounded fixed-time sampler independent of render frequency, or make the current frame-based sampling explicit; record that decision and preserve the original version in the before snapshot.
3. Add a local trace reset/replay only if implemented and reachable. Reset this experiment's buffer and time, never the game clock. Compare two sampling intervals while keeping the motion driver fixed.

## Revise final.md

1. Begin with the apparent second body behind the bob; ask what direction the record is travelling.
2. Let the reader locate two equivalent crossings and count intervening samples.
3. Show the actual append/evict code and explain that depth encodes elapsed history.
4. Let the oldest mark disappear in the prose. Relate this chosen memory to Point_Trace, then hand the periodic value to Sine Space.

**Code to trace and quote after implementation:** PendulumWave.gd: _physics_process, _draw_trail, recorded_interval_range, _update_readout. Source the append/evict block; distinguish target timing, actual timestamps and finite history.

## Evidence to return

- At two render rates, record sample count and time span under the chosen policy.
- Verify old samples are evicted and memory use stabilises.
- Capture the bob, whole trail and readable cased count in the museum.

Also return the shared handoff report: source fingerprints, actual control path, museum captures, changed files and remaining limitations.

## Room for a better solution

Use a conveyor, ribbon, scored sheet or another legible carrier of history. The count and finite retention must remain discoverable.

**Reusable method:** R2 housed readout; R3 explicit time; R8 bounded simulation.

## Open and inspect

- Map: `commons/maps/WaveFunctions_Pendulum/map_data.json`
- Book and supporting texts: `commons/maps/WaveFunctions_Pendulum/`
- [Primary view](http://localhost:3003/necklace/thread?map=WaveFunctions_Pendulum&role=primary)
- [Museum Progress](http://localhost:3003/museum-progress?sequence=wavefunctions&room=WaveFunctions_Pendulum)
- `res://algorithms/wavefunctions/oscillation_driver/PendulumWave.tscn`
- `algorithms/wavefunctions/oscillation_driver/PendulumWave.gd`

Direct scene resources are entry points. Read inherited scripts, child scenes and shader bindings needed to establish the actual behaviour.
