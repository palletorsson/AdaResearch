# AirMusic — contact, independent voices and a sampled sum

Builds on Effect Sound's phase and envelope comparison; prepares Synthesis Lab's additive construction. The primary remains `resonating_metallophone:0#stand:table` at (5,9). The walkway, basin, other nine placements and eight-note tuning are preserved.

## Implementation

- `ResonatingMetallophone.gd` creates the bars, striker, table and cradle. The table is 1.50 × 0.56 m, top at 0.85 m; bars sit at 0.875 m, 0.16 m apart. Locked axes keep the bars in their row; they remain awake for contact monitoring.
- `ResonatingBar.gd` recognises stick ancestry through rigid and area contacts. A 60 ms debounce suppresses duplicate notifications. Held-stick speed comes from per-physics-frame position differences. The trigger's strength is clamped to 0.1–1 after multiplying speed by two. This is a configured response, not an impact-energy calculation.
- The bar generates a mono 44.1 kHz, 16-bit sine buffer once, multiplied by `max_amplitude = 0.5` and `exp(-t/decay_time)`. The default decay is three seconds; the buffer lasts 7.5 seconds and fades over its final 0.1 s. Strike strength maps to player gain with `-6 + 6 * strength` dB. Audio generation and strike behavior are unchanged by this scope revision.
- Different bars have different players. A repeat on one bar restarts that player; another bar can overlap. The visible response uses frame age and strength-scaled exponential amplitude. The waveform uses source PCM and player gain, so those levels should not be described as identical.

## Table scope

The table enables `sample_audio` on `CombinedWaveVisualizer`, a 0.012 s window and 512 points. Other placements retain the existing schematic mode by default. `ResonatingBar.get_audio_window()` reads the signed PCM near that bar's reported playback position and multiplies by `db_to_linear(audio_player.volume_db)`. The sample buffers are not changed. Samples beyond the end of a note contribute zero.

The scope sums each contributor at the same window offset, preserving their different note ages. Its fixed scale is 0.15 m per unit. Display values are clamped to ±1 with `display limit` in the readout when needed; the summed source samples are retained without that clamp. The readout names the selected window and lists frequencies with source playback ages, two voices per line. The expanded casing has room for this hall's eight voices.

The former schematic displayed half a second across 100 points at these pitches, using a shared clock and visual amplitudes. The revised table display uses the generated buffers, including quantisation and final fade. It remains source evidence before spatial attenuation, bus processing and the output device. Audio playback positions update with mixing; the curve is not a sample-accurate capture at the listener's ear.

## Return and route

The striker rests front-to-back at the left end. When unheld more than 0.5 m away for three seconds, it returns in three tweened legs over 0.75 s. The `returning` flag prevents its tip from triggering notes on that journey. The table keeps a pale front rail and dark rear kerb. Perimeter access and the south operating strip are checked by the existing museum probe.

## Validation and limits

The independent live probe retains Claude's strike, overlap, repeated-note, return, access, desktop approach and streaming checks. New checks independently decode PCM, apply player gain, sum the two source windows, and compare the result with actual ribbon vertices. Captured playback ages differ, so a common global phase cannot substitute for each note's own beginning. Two bar buffers are exported for remote listening comparisons.

The run has 67 checks, zero failures and exit 0. This is synthetic movement through the striker's collision path, not a verified tracked-hand strike. A listener and headset visit remain pending. `doc/space/air-music-review-2026-09-12/` records the run, source fingerprints and publication. Geometry and tuning were retained; the primary/book alignment and supporting text were reconciled.
