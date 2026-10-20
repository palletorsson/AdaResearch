# Movement becomes a seed

Random Definition opts into `movement_seed:true` in its map token and museum
plan. The inherited PointBody on the stand beside the paired 4 × 4 colour grids
is a movement sampler. With the linked journey enabled, this stand is moved
beside the travelling sphere's source console. Hold, move and release it. Desktop uses the existing
right-click carry gesture; VR uses the existing XRTools pickup and drop.

Collection shows six traces: change in X, Y and Z position, then the three
components of relative rotation. These are measurements, not an entropy meter.
Release after at least 30 valid samples and at least one quantized pose change
to derive a seed. The previous seed stays if the sample is too short or constant.
The large display identifies the resulting source as Desktop movement or XR
tracking. The small board identifies its last sample, which may differ from a
seed subsequently selected on the main console.

The grids then use their existing Godot generator and RGB assignment. REPLAY
repeats their colours locally; +1 DRAW still discards a value on the right. The
saved atmospheric arrival 435 and ATMOSPHERE button remain available. Neither
replay nor movement collection sends a network request. A late atmospheric reply
cannot overwrite a gesture begun after the request.

## Linked travelling sphere

The current Random Definition map and museum plan give the bench and
`random_return` the same `route_link:random_definition`. `seed_journey.gd`
keeps a receipt per source and sends the active seed to the travelling sphere.
It uses a separate generator: colour requests never advance the journey.
The source console recalls NUMBER, HAND, CLOCK, FRAMES, SYSTEM and AIR;
NEW SAMPLE is the explicit request for another result. AIR recalls its saved
number offline, and only AIR + NEW SAMPLE asks the network.

The floor arrow shows the chosen destination; the board gives local direction
and distance. Replay resets trip one without resampling. If the traveller is
held, a new seed waits until release. The hand's recorded path is not the path
the travelling sphere follows: it supplies an initial seed for new destinations.

FRAMES records 120 application frame intervals. Its labels distinguish timing
variation from measured entropy. SYSTEM uses Godot's cryptographic random byte
API. Every source is reduced to the exhibit's 0–999 range. See the
[linked room and runtime checks](../../../doc/book/iterations/2026-10-13-one-seed-two-journeys/index.html).

## What is measured

- During VR pickup, the holding controller's original `XRPose.transform` supplies
  position and orientation in tracking space. Moving the virtual XROrigin does
  not count as bodily motion. Missing, stale and low-confidence poses are skipped.
- During desktop carry, the point's local transform supplies position and
  orientation. This is explicitly labelled desktop movement.
- A monotonic elapsed timestamp accompanies each accepted pose. Sampling is
  capped at 60 times per second, with no fabricated catch-up samples, and stops
  at 300 records. At lower frame rates it takes longer to fill.
- Position is rounded to 0.00001 metres and quaternion components to 0.000001.
  This encoding resolution is not a claim about tracking accuracy. At least one
  changed pose is required; timing variation alone is insufficient here.

`pose-sample-v1` hashes a deterministic UTF-8 encoding with SHA-256: version,
source, then timestamp and seven pose integers per record. The first four digest
bytes, interpreted as an unsigned little-endian integer, are reduced modulo 1000.
This retains the bench's 0–999 slider range. Distinct recordings can yield the
same seed. This is not a uniformity guarantee, entropy estimate or key generator.

The museum visit state keeps the seed, source, recording, encoding version,
digest and sample counts. No controller recording is uploaded. Reproducing the
same grid requires the same generator, seed, grid size and draw procedure; it
does not promise identical physics simulation or matching behaviour across
future engine versions.

## Why this belongs in the room

VeraCrypt's documented pool combines mouse input with other sources, including
operating-system random output. That is a useful precedent for physical input
contributing to generation. This exhibit is a small, inspectable artistic
experiment, not an implementation of VeraCrypt's security design. Hashing does
not supply unpredictability missing from the input. Quest pose entropy has not
been measured. Being offline does not make a headset closed to physical events.

The tutorial can explain **sample → seed → sequence → colour** through the
already-known point and grid. The reflection can follow what happens when a
present movement becomes an object that can be kept and returned to. Neither
text needs to call a tracking fluctuation certified true randomness.

Sources:

- [VeraCrypt: Random Number Generator](https://veracrypt.io/en/Random%20Number%20Generator.html)
- [Godot 4.6: XRPose and tracking validity](https://docs.godotengine.org/en/4.6/classes/class_xrpose.html)
- [X41: mouse entropy study, 25 September 2025](https://x41-dsec.de/security/research/news/2025/09/25/mouse-entropy/), which does not measure Quest tracking.

## Verification

```powershell
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-movement-becomes-a-seed/museum_probe.gd --output-tag movement-seed-20261013
```

The probe loads the real isolated museum, exercises desktop carry and sampler
updates, uses a deterministic movement fixture for photographed comparisons,
checks save/replay, tracking confidence and loss, virtual-origin exclusion,
record limits, seed edits, mocked HTTP races and existing matrix controls.
Synthetic XR poses test the API path; physical Quest handling remains to be
tested. The installed museum APK has not been replaced.

## Frame timing beside the gesture

The linked Random Definition exhibit also has a live frame timing scope. It
subtracts successive `Time.get_ticks_usec()` readings at process callbacks and
plots their differences from a measured reference. This is application timing,
not raw sensor noise or an entropy estimate. Its graph observes at most 240
intervals and redraws at most 10 times per second; its own workload can affect
what it measures.

FRAMES records 120 whole callback-to-callback intervals, shows exactly those
values on the scope, and keeps them with their derived seed. REPLAY restores
that trace and journey. HOLD/LIVE, REBASE and RANGE affect only the observation
and display. A new LIVE view never silently replaces the seed. See the
[frame timing implementation and runtime probe](../../../doc/book/iterations/2026-10-13-frame-jitter/IMPLEMENTATION.md).
