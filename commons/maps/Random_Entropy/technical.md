# Random Entropy — a sequence, its counts, one number

This chapter builds on Random_Definition's seeded procedure and prepares for Random_Remove's eligible set. The primary is `shannon_entropy_meter:90#stand:ledger#disclosure:ledger` at (5,6), facing east into the corridor. Nine artifact placements remain declared in the 18 × 12 map. The runtime pack and any refusals are recorded separately in the review evidence.

## Data and computation

The local generator is seeded before `_run_measurement` constructs 200 integer symbols in 0–9. `_measure` stores the ordered sequence, tallies it into ten counts, and computes −Σ p log₂(p), p = count/200, skipping zero-count terms. The measured marginal entropy has units bits per symbol. It does not measure the full ordered sequence's entropy rate, semantic value, thermodynamic heat or whether the source is physically random.

The arrival seed is 1342042698, the current result of `hash("shannon_entropy")`. Its counts are [17,11,21,31,17,18,19,24,13,29], giving H ≈ 3.255647. A cached second sample uses seed+1 and normalized weights 2⁻ᵏ; its counts are [109,46,20,17,6,2,0,0,0,0], giving H ≈ 1.817600. These are samples, not exact source probabilities. Replay across different generator implementations or engine versions is not established by this review.

The computation is visible in the actual loop:

```gdscript
for c in counts:
    if c > 0:
        var p: float = float(c) / float(sequence_length)
        entropy -= p * (log(p) / log(2.0))
```

## What moves and what remains

SORT changes the positions of 200 MultiMesh instances over 1.2 seconds. The sample itself retains its order. A stable sorted-index table supplies each tile's target; the readout computes entropy again from `sorted_copy()` and prints the equality. CONTRAST selects the other cached sample and updates tiles, counts, source and expected values. It retains the sorting choice.

The upper panel's disclosure ladder is oracle/tally/ledger/works/origin. The placed arrival is ledger. DISCLOSE rebuilds the upper panel, retaining the desk and chosen built-in sample. Origin ghost bars come from `active_probabilities()` and `expected_counts()`, not an unconditional uniform expectation. `_after_measure` lifts refreshed bars and boards back onto the post; the prior duplicate-build and bar-height regressions remain repaired.

## Display scales and records

The panel is 0.7 × 0.5 m, centred at 1.40 m. The solid desk is 2.30 × 0.45 m with its top at 0.92 m. A two-metre ribbon carries all 200 samples as 0.008 × 0.03 × 0.02 m tiles. Its marked first forty are also spelled out in two upper-panel rows. On the desk's front face they appear as forty 0.026 × 0.08 m tiles, in the active sample's original draw order even while SORT rearranges the top ribbon. The caption now says `first forty · as drawn`; it no longer claims a uniform ×4 scale.

Histogram height is count/max_count × 0.10 m, with a 0.002 m minimum. The largest bar has the same height in both built-in samples. Zero-count marks are still visible. Expected ghosts use the same active-sample denominator, capped at 0.10 m and floored at 0.002 m. The numeric ledger is essential to interpreting these heights. The bar labels and large H have limited display precision; the calculation retains its unrounded value.

The front excerpt's lower edge is 0.832 m; the readout case's top is 0.825 m. Its separation is 7 mm in the local frame, so standing captures are needed alongside geometry checks. The front controls are enlarged 1.4 times. Local dark backing, mid-grey button faces and pale textured tags are unshaded. The readout backing is also unshaded, while the caption uses 22 px type. The source palettes, measurement, sorting, sampling and museum geometry remain unchanged.

## Review limits

The independent review exercises real button signals and the desktop pointer, both source/disclosure orders, sorting, endpoint samples, expected bars, floor routes and hall unload/rebuild. It exports the two complete samples for independent counting and entropy calculation. The review compares the enlarged strip with its original symbols while allowing for the precision of the MultiMesh colour buffer; the measured precision is recorded in the report.

Headset reach and close lettering still need a later visit. Nine placements remain declared; eight instantiate because secondary `replay_casino` has no living scene. The run records an unrecognized audio-bus UID, a root-certificate error, a logger failure and an ObjectDB warning at shutdown; passing assertions do not resolve these diagnostics. There are no script errors. The specific run result, placement ledger, images and remaining limitations are in `doc/space/entropy-review-2026-09-12/` and `/research/possible-bodies/random-entropy.html`.
