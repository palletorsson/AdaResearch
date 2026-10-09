# Transformation experiments · 16 September 2026

Two existing textual claims now have physical experiments.

## Introduction: the destination moves

`adjustable_landing` is a new primary after tc/sc/rc. It occupies a recessed slot after the third crossing. Its compact slider translates a 3 × 3 m landing by up to 1 m at 0.25 m/s. The 3.6 m rotating plank is unchanged. RESET restores overlap. Both side aisles remain permanent. The source grid expands from 13 × 20 to 13 × 23; existing artifacts remain.

A peer review caught an extra gap behind the first 2 m-deep landing. The final slab is 3 m deep and the regression now walks from the near bank through to source z22+, beyond the slab. A 3 mm visual lift prevents coplanar flicker against the exit deck; the physical top remains exactly at deck height.

Actual-museum probe: `commons/testing/probe_adjustable_landing.gd`. **28 checks pass**, including the original two crossing poses, native slider and RESET signals, unchanged plank transform, level bank, 0.70 m surface gap at the far setting, real capsule loss of support, bypass and full forward exit after reset. The held plank pose isolates the bank variable; ordinary play retains the plank timer.

## Rotation: the body changes

The existing `rotation_array_compare` now owns `array_body_comparison.gd`: four 0.44 m-wide capsules, then four 1.20 m-wide capsules. All use height1.6m, speed2m/s, gravity9.8m/s², slope45° and snap0.15m. Results record forward progress, lateral drift and stop reason. They repeat automatically and have a physical REPLAY button. Layer-zero witnesses remain intangible to the player; world geometry still constrains them.

**40 source-grid checks pass**, including all bands and both widths in the zero-angle control, unchanged array geometry, real replay and desktop-player collision exceptions. An additional rendered actual-museum run reproduces the qualitative outcomes; 33 existing hall checks also pass after the change. The wide Z witness arrives after sliding about1.15m sideways; the narrow witness stops at4.66m. The capsules do not jump or plan a route, so a failed attempt is not proof of universal impassability.

## Text and publication

Introduction final.md includes the bank encounter and exact motion code; critical.md corrects the old ramp description and removes claims that inherently identify translation as normative. Rotation final.md describes the witnesses and the Z surprise. Tutorials document the implemented rules. Introduction summary/artifacts inventory now match the source grid.

Primary order, core encounter hashes, sequence, book captions, runtime plan and generated necklace are synchronized. The existing seven-hall review links to `experiments.html`. Its photographs are actual Godot museum captures, not generated illustrations.

Long-museum and museum-necklace consistency checks pass. Existing unrelated warnings for Tutorial_Disco's ragged layer and Noise_Inside_Noise's layer mismatch remain.

## Limits and next review

Headset comfort and actual hand reach remain unverified. Browser UI automation is unavailable in this environment; publication is checked with local HTTP/API responses and source hashes, and rendered Godot images were inspected directly.

Before changing more prose, try the movable bank and the width comparison in the headset. Later candidates include a reachable carve_grid tolerance control in Trans_Body, and reconciling older technical/critical supporting documents elsewhere in Transformation. These are outside this two-experiment pass.

## Reproduction

Run Godot4.6 with --headless --path . --xr-mode off --audio-driver Dummy and --script res://commons/testing/probe_adjustable_landing.gd. For the rotation comparison, use ada_run/probe_rotation_body_comparison.gd. Reports and captures are retained beside this note. Run tools/long_museum.py --check and tools/museum_necklace.py --check for derived-view consistency.
