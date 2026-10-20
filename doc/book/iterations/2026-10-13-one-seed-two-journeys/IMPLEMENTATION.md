# One seed, two journeys

Implemented in the existing Random Definition hall, 13 October 2026.

## Current behaviour

The colour bench and random_return carry the explicit placement key `route_link:random_definition` in both map_data.json and the museum plan. The bench owns a seed_journey coordinator and the source receipts. The travelling sphere subscribes through that matching key. Ordinary seed benches do not acquire the console.

A source receipt publishes the seed to both outputs. Each output has its own Godot RandomNumberGenerator: grid resizing, +1 DRAW and colour sampling cannot consume the travelling sphere's sequence. The sphere draws an angle in [0, TAU] and a radius in [1.1, 2.2] metres once per trip. The radius is sampled uniformly; this is not uniform area sampling. Travel uses the existing eased horizontal out/back motion and collision-aware carry.

The coordinator moves the original movement sampler beside the journey console while retaining ownership under the colour bench. Recalling HAND restores the corresponding kept trace and its sample count. No new seed is emitted by trace restoration.

Source buttons recall existing receipts. A missing CLOCK, FRAMES or SYSTEM receipt is collected on first selection. HAND waits for a gesture. NUMBER begins at 42 and remembers subsequent local choices. AIR begins with the archived atmospheric draw 435. NEW SAMPLE is explicit: only AIR requests the network; HAND instructs a new gesture; NUMBER points to the existing seed slider.

FRAMES measures 120 successive application callback intervals with Time.get_ticks_usec(), not the supplied frame delta. It is an observation of application timing, not a CPU-jitter entropy extractor or a Quest entropy claim. A regular sequence still yields a hash and seed. Collection is bounded and cancels on a source switch, replay or new hand recording.

SYSTEM uses Crypto.generate_random_bytes(4). The exhibit reduces its 32-bit value modulo 1000; the small range and modulo mapping are presentation choices, not a cryptographic seed service or a uniformity guarantee.

REPLAY returns the route to trip one and reconstructs the current colour comparison. It never samples a source. It invalidates pending HTTP requests and cancels unfinished frame/gesture captures. Source receipts persist with museum visit state. A held travelling sphere queues the newest kept seed; release applies it without snapping a carried body to a new route.

## Reproduction

```powershell
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-one-seed-two-journeys/museum_probe.gd --output-tag seed-journey-20261013
```

98 checks passed with Godot 4.6 compatibility rendering. Includes earlier movement/grid regression checks, live clock/system/frame collection, controlled timing and movement fixtures, source bank save/restore, direction/distance against an independent RNG, queued changes while held and a colliding CharacterBody carried by the existing callback. XR poses are synthetic; no physical headset test or APK replacement.

The images are direct Godot captures, not generated illustrations. Hand seed 880 uses the deterministic movement fixture. Clock seed 456 is a controlled timing fixture (123456 milliseconds); the actual clock button was tested separately using the live clock. The AIR example recalls the archived response 435. Photographs freeze the same phase of the first excursion to make the changed destination legible.

## Source references

- [Godot 4.6 RandomNumberGenerator](https://docs.godotengine.org/en/4.6/classes/class_randomnumbergenerator.html)
- [Godot 4.6 Time](https://docs.godotengine.org/en/4.6/classes/class_time.html)
- [Godot 4.6 Crypto](https://docs.godotengine.org/en/4.6/classes/class_crypto.html)
- [Existing movement encoding and limitations](../../../../algorithms/randomness/seed_replay/MOVEMENT.md)

The canonical tutorial and final texts were not rewritten in this implementation pass.

