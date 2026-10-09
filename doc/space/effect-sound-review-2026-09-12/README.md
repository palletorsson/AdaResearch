# Effect Sound — independent review and book alignment

12 September 2026. Continue the Wavefunctions halls from Claude's implemented and repaired baseline, after completing the Sine Space contact tray. Review the final Effect Sound visual follow-up rather than rebuild the instrument.

Review and remote listening: http://localhost:3003/research/possible-bodies/effect-sound.html

Primary/book: http://localhost:3003/necklace/thread?map=WaveFunctions_Effect_Sound&role=primary

## Decision

Keep Claude's Effect Sound implementation and accept the bounded follow-up to the labels and blocked readout. The operating capture shows both desk names below the scope; the close capture shows the complete readout outside the pedestal that previously enclosed it. Small hand targets and button captions still need a headset visit. The crowded backs of secondary displays remain a later visual task. This is not a listening judgement or blanket acceptance of every WCN room.

The independent run used the current live probe in a separate output directory, with a snapshot of the saved hand. It passed 100 checks and exited 0 in 47 seconds. It produced no GDScript parse/runtime errors. Existing nonfatal UID/viewport-texture warnings remain in the engine log. Original probe reports, production source, map geometry and saved hand remained unchanged.

## What changed in this review

- The book opening connects the new Sine Space tray and corridor to phase modulation. Most of the existing discovery prose is retained.
- The scope's normalisation becomes a further discovery: its orange trace divides by index, and the output trace uses twice the generator's gain. The displayed window covers two carrier periods near the attack, not the whole note.
- `tutorial.md` now teaches the actual primary with production-code excerpts. The previous sine-shaping examples did not generate the claimed saw/triangle waveforms; its DFT and octave claims also belonged to a different, incomplete example. `technical.md` now records the actual mapper, buffer, comparison, scope and sampling behaviour. Eleven excerpts across final and tutorial were verified against production code, allowing omitted comments/blank lines.
- Supporting prose corrects sample/scope distinctions, latency measurement, held-note replay and the categorical claim that a harmonic instrument cannot be described as bell-like.
- The primary note now describes one book encounter. Stale removed test artifacts were removed from the book's secondary list and inventory; no placed artifact was removed. All 21 artifact types / 33 placements remain.
- Both museum plan copies were refreshed from the current map. The stale plans described the moved synth and one pickup cube incorrectly. Only the row's `artifacts` and `_ruling` fields changed. The derived museum index now matches all 33 placements, with zero extra or refused placements in this hall. This synchronizes the plan with the already-tested geometry.
- The review page includes two comparisons made from the exact three probe-rendered WAVs, joined with 0.25 seconds of zero PCM samples. No amplitude changes or normalisation. The page and work cards are published locally; the WCN source audit reports zero primary/book mismatches across its 35 maps.

## Evidence

- Run and source fingerprints: `ada_run/effect-sound-review-2026-09-12/run.json`.
- Engine log, raw report, images and WAVs: `ada_run/effect-sound-review-2026-09-12/WaveFunctions_Effect_Sound/`.
- `verification.json`: exact published bytes, PCM comparison integrity, primary/book agreement, current placement index and next hall.
- `plan-sync.json`: fields refreshed in both plan copies.
- `before/`: bounded backups of edited text, book/role data and plans.
- `publish-targets.json`, `publication-manifest.json`, `publication-hashes.json`: local encyclopedia publication.

The browser loaded both figures and both audio comparisons, reported no audio error or horizontal overflow, and opened the book disclosure. Audio readiness is not a listening assessment. The probe moves balls through the mapper and clicks buttons through the project's desktop rig; it does not establish tracked-hand grabbing or the museum walker's complete control path. General index warnings about other maps remain outside this review.

## Continue with AirMusic

The next effective hall is `WaveFunctions_AirMusic`. Claude has already staged the striker cradle and repaired the shared synth shutdown; inspect current handbacks before changing it. Carry the thread from a held sound and changing envelope to a brief strike and a persisting response. Retain its good artifact and prose, then close a specific remaining mismatch if the current evidence reveals one.

Helpers: `ada_run/review_effect_sound.py` (launch only after a successful Godot process inventory), `ada_run/finish_effect_sound_text.py`, `ada_run/align_effect_sound_records.py`, `tools/build_effect_sound_review.py`. No commit was made and no message was sent to Claude or a forum.
