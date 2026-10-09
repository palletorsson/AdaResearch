# Synthesis Lab — a finite sum made inspectable

Builds on AirMusic's separate voices and leads to Random_Definition's question of replay. `additive_wave_demo:0#stand:bench#waveform:sawtooth` at (4,2) is the sole primary. It is a visual sum, not an audio synthesizer. The other 24 placements remain supporting laboratory material; their states are not controlled by this bench.

## State and computation

Five sliders supply nonnegative amplitudes in [0,1]. Harmonic h uses `amplitude[h] * sin((h + 1) * phase)`. All components share a phase, with no separate phase offsets, signed coefficients, constant term or harmonics above five. The arrival coefficients are [1, 0.5, 0.333, 0.25, 0.2]. These are rounded 1/n values, a finite sawtooth approximation.

The sum and components use 256 samples spanning four cycles across two metres. `_time` advances by `delta * base_frequency` (default 1) and wraps at 1000; HOLD pauses this display clock. The sum's scale is 0.30 m per unit. Ladder rows use 0.20 m per unit, with axes separated by 0.15 m. Their vertical offsets must be removed before comparing geometry with the sum.

The slider signal reads the handle's normalized value back into exactly one coefficient. BASELINE writes the saved arrival table to all sliders. H1 ALONE preserves H1 (or sets it to one if below 0.01), and zeroes the rest. Neither resets `_time`. The readout updates on changes and ten times per second while scrolling.

## Recipe recognition revised

The former detector ignored H4/H5 in several classifications and could call a lower-amplitude lone sine a triangle. The new detector recognizes zero and a single sine first, then compares all five coefficients relative to H1, with a per-coefficient tolerance of 0.025. Matching is skipped if H1 is below 0.01. A match describes proximity to a recipe, not equality to an ideal discontinuous waveform.

The legacy `triangle` preset ID retains its positive odd 1/n² table to preserve existing configurations. Its label is now `Odd 1/n² mix (positive terms)`. A triangle in this sine orientation requires alternating signs. No new control or change to the five-term waveform calculation is introduced. The label repair applies to other placements of this shared artifact too.

## What the display leaves out

Rows below 0.01 disappear, while the total still includes their coefficients. The formula uses one decimal place; the plate uses two. The marker is sample 159, local x ≈ 0.247 m. `display_values()` reports each row, the sum of drawn rows and the complete total; the readout uses an equality threshold of 0.005. Thus an invisible small contribution can produce a visible disagreement. There is no automatic normalization of the sum.

The sampled baseline peaks around ±1.582, with an approximately 0.086 m rounded rise in its 0.5 m cycle. Other coefficient settings can exceed this amplitude. High sums extend beyond the dark backing and can approach the upper lettering; the current staging has not been enlarged in this review.

## Preserved staging and route

Claude's bench is 2.90 × 0.50 m, top at 0.92 m. The sum's axis is at 1.75 m; ladder axes are 1.40, 1.25, 1.10, 0.95 and 0.80 m. The lowest axis is below the bench top in height, but the checked standing sight line clears its rear edge. The five slider handles sit roughly 0.99–1.36 m high at the right end. A three-button panel and tilted five-line readout occupy the front.

Retain the recovered platform/wall contract, clear approach rectangles, miniature hallway on the synthesis stand and the synth shutdown repair. All map layers are preserved. `coloredlines` was removed by Claude's prior pass because it changed the visitor's camera; this review only removes its stale book/role references.

## Evidence and remaining visit

The independent live run passed 110 checks with zero failures and engine exit 0. The retained tests exercise the five real slider paths, desktop pointer drag and buttons, readout versus ribbon vertices, finite-corner comparison, access, room cleanup and rebuilding. Ten new coefficient settings verify label regressions and independently compare all 256 drawn sum samples with arithmetic; the worst discrepancy is below 9e-8. The clear-rectangle assertion now matches the already-authored corridor and operating strip.

No tracked-hand or human listening observation is claimed. Verify headset reach and lettering, particularly at higher amplitudes. The radio rack was playing during the probe, 7.7 m from the bench; this does not establish how it sounds at a listener's head. See `doc/space/synthesis-lab-review-2026-09-12/` and `/research/possible-bodies/synthesis-lab.html`.
