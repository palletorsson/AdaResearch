# Worked card: different records, the same beginning

**Status:** source-inspected mechanism and synthetic calculation. No new participant recording or Godot runtime trial was performed for this card.

**Encounter:** Random_Definition's MOVE / KEEP instrument records elapsed microseconds, quantized position and orientation, with 30–300 accepted samples and at least one recorded change. It hashes a canonical integer encoding and maps the first uint32 into 0–999. Its receipt retains the sample array as well as the seed.

**Question:** what can a generator receiving only the seed distinguish between two movements? What remains accessible to a researcher who also keeps the full receipt?

**Baseline and one change:** use two explicitly synthetic, valid-format pose records produced by the [calculation script](../../../iterations/2026-10-15-entropy-across-maps/verify.py). Hold source tag, timestamps and orientations fixed; vary the positional progression. Search for a shared seed. These are authored arrays, not claims about a tracked human gesture or a physical entropy source.

**Evidence:** the [fixture report](../../../iterations/2026-10-15-entropy-across-maps/fixtures.json) records two different arrays, their different SHA-256 digests and their shared bounded seed. It uses the current source's encoding and little-endian uint32 reduction. The Python transcription has not been independently executed as this Godot sampler in this pass.

**Measurement contract:** `log2(1000) ≈ 9.966` bits is a maximum over distributions on the seed alphabet. No uniform movement/seed law is assumed and no empirical entropy estimate is claimed. The full receipt is not restricted to this seed alphabet. Replaying a PRNG from the same complete reset state and seed gives the same sequence; it does not reconstruct the source gesture from that seed.

**Next runtime check:** load both records through the sampler's actual digest function and the intended generator receiver. Verify distinct retained samples, equal seed, equal raw output sequence under a fixed reset/configuration, and retained receipt provenance. Then repeat with two separately captured human movements if useful. A successful synthetic collision does not establish how common collisions are in human movement.

**Possible revision:** compare receiver contracts—seed only, or seed plus one explicitly named feature of the retained trajectory. That changes what the later artifact can respond to. Keep the changed rule and its input separate from a new random draw.

**Tutorial consequence:** isolate the integer encoding, reduction and receiver reset. **Final consequence:** develop the tension between a record that remains in the archive and a difference the downstream object never receives. **Spatial consequence:** let both traces remain visible beside the shared output if this comparison is built. Cross-hall transfer is not yet implemented.
