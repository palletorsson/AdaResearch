# A wall that can return to the same moment

Find **Lava Wall — What Can You Predict?** in `Random_Definition`, on the east wall of the first room. In the web editor its key is `lava_entropy_wall`; it has the ordinary move, rotate, scale and remove controls. The 48-value seed bench remains the first pilot. This wall is an adjacent experiment about where a seed comes from and what a sensor admits.

Twelve virtual lamps move above two comparison cards. Each card shows a synthetic monochrome sensor image and 48 bars derived from that image. These are snapshots, even while the lamps continue moving. The source, seed, tick, heat and changed-pixel count appear above the shared rectangular button board.

## Make a comparison

1. Press **RESET 435** for the documented starting configuration: seed 435, tick 300, heat 1.00, open sensor. Or let the lamps move and press **CAPTURE** to hold your own baseline.
2. Press **HEAT +**. It returns to the baseline seed and tick and changes only the motion-rate parameter. “Heat” is a model control, not a calibrated temperature or a fluid simulation. Compare both sensor images and their output bars.
3. Press **COVER** for a separate comparison against the same baseline. It covers the left half of the synthetic sensor, leaving the underlying lamp state unchanged. Observe how this changes the hash and the output. The cover does not measure a loss of entropy.
4. Press **KEEP**. This saves the displayed baseline **and** current capture, their model configuration, raw sensor bytes, hash, reduced seed, output values and source receipt. Keeping while the lamps run saves the displayed capture, not an unrecorded later frame.
5. Change the model, then **REPLAY**. Both saved cards return. **LOAD** restores the latest valid saved comparison after leaving and returning to the room. Files live in Godot's `user://lava_entropy_wall/` folder; locate the project's user-data folder from Godot's project menu.
6. Reconstruct the saved record using the independent Python program below. Compare every sensor byte and the full hash, not just whether the bars look similar.
7. Record what became visible, what remained confusing, and one reason to change the apparatus. Either this tutorial or `final.md` may supply the next question. A technical pass does not complete this visitor step.

**SYSTEM** requests 16 bytes from Godot's `Crypto.generate_random_bytes`, hashes them, and uses the first seven hexadecimal digits as a new model seed. It holds the baseline tick, heat and cover fixed. Its receipt is labelled system RNG input. This is external to the lamp model; it is neither a camera measurement nor a measured physical TRNG. **REPLAY** never requests new bytes. **RUN / HOLD** controls animation; **CAPTURE** deliberately replaces the comparison baseline.

## Reconstruct the apparatus

Run from the repository root with Python 3:

```powershell
python -X utf8 doc/book/experiments/random-definition/lava-wall-001/reconstruct.py "PATH_TO_SAVED_COMPARISON.json"
```

The program does not import Godot code. It rebuilds the model and synthetic sensor from this recipe:

- Version `ada-lava-1`, 30 model ticks per second. Twelve lamps, four blobs per lamp. Initial parameters use the integer recurrence `s = (48271 * s) mod 2147483647`.
- Each blob consumes three recurrence outputs: phase modulo 2000, speed `2 + s mod 4`, then horizontal/vertical radii. A triangular wave moves the blobs. All sensor positions are integers. The implementation is deliberately bounded and inspectable; it does not model turbulent fluid dynamics or demonstrate physical chaos.
- The synthetic sensor has 96 × 48 grayscale bytes: six columns of 16 pixels, two rows of 24. Blob ellipses contribute brightness; overlapping contributions are clamped to 255. `reconstruct.py` gives the complete integer sampling formula. The visible 3D forms are a stylised view of these same blob parameters; the sensor is not a screenshot of the Godot renderer.
- SHA-256 hashes exactly those 4608 bytes, without a timestamp or hidden system input. The first seven hexadecimal digits form a 28-bit seed, replacing zero with one. The same recurrence generates 48 values divided by 2147483647. A changed hash does not certify extra entropy, and the small, public seed and ordinary PRNG are unsuitable for encryption.

Stored sensor bytes and hashes must match exactly. Output fractions are checked within `1e-14` to allow JSON number conversion. A version mismatch, inconsistent body state, changed hash or wrong output rejects a record. Keep old receipts when revising the model; give a changed recipe a new version.

## Next investigation

Try making a prediction before uncovering the changed card. Which information would make that prediction easier: the seed, the complete state, the sensor recipe, or a previous frame? Reconstruct one chosen result without looking at the runtime script, document any missing tutorial information, and propose a revision. A real camera observing physical lamps is a future apparatus with its own source, privacy, sensor-health and entropy-assessment questions; the current version makes no claim to have built it.
