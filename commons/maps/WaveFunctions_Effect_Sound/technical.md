# Effect Sound — parameters, samples and comparison

This chapter builds on Sine Space's distinction between an expression, its sampled representation and its physical consequence. Its primary is the existing `DualBallFMController` at (8,11), rotated 180 degrees, with `#stand:desks#evidence:longhand`. AirMusic follows on the effective museum route. `tutorial.md` walks through the encounter with verified excerpts; this file records the implementation and limits.

## Mapping and generation

Source: `algorithms/wavefunctions/mariocontrol/DualBallFMController.gd`.

| Cage axis | Carrier | Modulator |
|---|---|---|
| Local x | `carrier_freq`: 100–2000 Hz | `mod_ratio`: 0.5–8 |
| Local y | `attack_time`: 0.01–0.5 s | `mod_index`: 0–10 radians |
| Local z | `decay_time`: 0.1–3 s | `mod_decay`: 0.1–2 s |

Each half-metre ValueMapper3D cage emits its values. The controller ignores an unchanged triple. A movement exceeding 1 cm since the last recorded movement can request a note; `min_play_interval = 0.3` bounds movement-triggered playback. It is a minimum interval, not a promise of an exact periodic trigger. Explicit audition buttons can trigger notes separately.

`_generate_fm_sound()` computes a whole mono note on the main thread. Sample time is `i / 44100.0`. Duration is `min(decay_time * 1.2, 3.0)`; the optional `drag_note_cap` is zero in this placement. The modulator is `m(t) = I exp(-t / tau_m) sin(2 pi R fc t)`. The output before shaping is `sin(2 pi fc t + m(t)) * env(t)`, a phase-modulated carrier. Its envelope has a linear attack and exponential decay after the attack. The sample is then shaped by `tanh(output * 0.8) * 0.5` and packed as signed 16-bit PCM. This bounds this generator's samples; it does not certify the headroom of every sound mixed on the output bus.

BASELINE sets carrier `(440, 0.01, 1.5)` and modulator `(2, 0, 0.5)`. It generates 79,380 samples / 1.8 seconds. The zero index removes modulation while preserving envelope, shaping and quantisation. The finite buffer cuts off the exponential tail; a new trigger replaces the current stream and restarts playback.

## Held comparison

HOLD stores a six-value dictionary, a generated `AudioStreamWAV`, and its length. COMPARE replays the saved stream, starts a timer for that length plus 0.25 seconds, then renders B from the values current at the timer callback. Without a held reference COMPARE first holds the current note and returns. PLAY renders the current B. Do not move controls during the comparison when testing a prepared pair.

The readout reports current and held values, changed parameters, playback state, buffer duration, synthesis milliseconds and note count. `differences_from_reference()` lists differences greater than 1 Hz for carrier frequency and greater than 0.005 for the other values. It is a tolerance-based comparison. Synthesis milliseconds measure generating the buffer; they do not include every contribution to hand-to-ear latency.

## Visible evidence

The scope uses `_fm_sample()` to evaluate the same synthesis rule without PCM packing. It displays two carrier periods beginning at the end of the attack, 1,200 points per waveform lane. The modulator lane divides by `max(mod_index, 0.001)`; above that threshold a change in index is normalised out of that lane's height. The carrier lane has no amplitude envelope. The output lane is twice the generator's floating-point output. A rule line separates operands and result. It is a constructed view, not an audio-input measurement or an equal-gain overlay.

The desks support the cages at 0.92 m. The low front panel and readout leave the hand space visible. CARRIER and MODULATOR labels are pinned to the desk fronts at 0.86 m; the scope's bottom is 1.50 m. Claude's last repair changed the empty structure cell (9,10) from a raised block to floor because the block enclosed the readout. The protected rectangle `[6,9,11,13]` excludes procedural plinths around the operating area.

The scope's selected interval cannot show how the full tail changes. Nor can sample differences alone establish a perceptual difference. Use the recorded A/B notes for listening alongside the numbers.

## Sampling and limits

At 44,100 Hz, 22,050 Hz is the Nyquist frequency. This generator does not explicitly band-limit its phase modulation or nonlinear shaping. To see why an instantaneous-frequency estimate needs care, differentiate its phase:

`f_inst(t) = fc + I exp(-t/tau_m) [R fc cos(2 pi R fc t) - sin(2 pi R fc t)/(2 pi tau_m)]`.

This is the derivative of the implemented phase before its final shaping, not a bound on every spectral component. The earlier shorthand omitted the derivative of the fading modulator envelope. Neither this expression nor a scope image proves which aliasing a listener notices.

## Local sound and evidence

Desk staging reduces the audio player's maximum distance to 18 m. Distance attenuation and that range are not architectural soundproofing. The nearby timbre sculptor's `#sound:near` enables its continuous tone only when the viewport's current camera is within 3 m. This is a camera-distance rule, not acoustic occlusion.

The existing live probe exercises mapper paths, audition buttons, sample comparisons, scope relationships, approach routes, nearby sound activation, audio-bus cleanup and room rebuild. Its desktop rig clicks actual buttons; ball movement is probe-driven through the mapper and is not a verified desktop grab or tracked-hand interaction. Independent review evidence is in `doc/space/effect-sound-review-2026-09-12/`. Listening and headset reach remain separate observations.
