# WaveFunctions Effect Sound — Technical

## The primary: two balls, six parameters, one expression

`DualBallFMController` (`algorithms/wavefunctions/mariocontrol/DualBallFMController.gd`) holds two `ValueMapper3D` cages of 0.5 m. Each cage maps its ball's position along x, y and z onto three parameters, and emits `values_changed` every frame; the rig ignores an unchanged triple.

| ball | x | y | z |
|---|---|---|---|
| carrier (blue) | frequency 100–2000 Hz | attack 0.01–0.5 s | decay 0.1–3.0 s |
| modulator (orange) | ratio 0.5–8 | index 0–10 | modulator decay 0.1–2.0 s |

A note is synthesised when a ball has moved more than 1 cm since the last note and at least 0.3 s have passed (`movement_threshold`, `min_play_interval`), or when an audition button is pressed. The whole note is computed on the main thread, at 44,100 samples per second, for 1.2 × the decay and three seconds at most:

```gdscript
	var duration = min(decay_time * 1.2, 3.0)
```

Per sample, the modulator is a decaying sinusoid at `mod_ratio` times the carrier's frequency, and it enters the carrier's phase:

```gdscript
		var mod_env = exp(-t / mod_decay)
		var modulator_freq = carrier_freq * mod_ratio
		var modulator = sin(2.0 * PI * modulator_freq * t) * mod_index * mod_env
		var carrier_env = attack_env * decay_env
		var output = sin(2.0 * PI * carrier_freq * t + modulator) * carrier_env
		output = tanh(output * 0.8) * 0.5
```

`attack_env` ramps linearly from 0 to 1 over `attack_time`; `decay_env` is `exp(-(t - attack_time) / decay_time)` after it. The tanh keeps every sample within ±0.5, so no setting clips. With `mod_index` 0 the modulator term is zero and the note is the bare carrier under its envelope and the tanh — unmodulated, not unprocessed — which is what BASELINE deals: 440 Hz, a 10 ms attack, a 1.5 s decay (a 1.8 s note), ratio 2, index 0, modulator decay 0.5 s.

## The audition

Under the `#stand:desks` staging the rig builds two desks (0.92 m, the cages' floor), a shelf for the colour cube, an AUDITION panel and a cased readout leaning low in front of the desks at 0.66 m (below the hand space, since the visual pass of 12 September; they had stood centred at 1.02 and 1.30 m between the balls), the scope 0.12 m above the cages so a standing eye sees the balls and all four lanes in one view. HOLD stores the six values and the synthesised note itself as A; COMPARE plays A, waits its length plus a quarter second, then plays the current note B; PLAY re-plays B without a move; BASELINE deals the unmodulated note. The readout prints the current six values, the held six, which of them differ (`differs: I 0.00→4.00`), and, on its last line, what is sounding, the note's length, the synthesis time in milliseconds and the count of notes played. `get_audition_state()` and `render_samples()` expose the same facts to a probe as numbers.

## The scope

`#evidence:longhand` builds a plate above the cages with four lanes — the modulator, the bare carrier, a rule, the output — each drawn from `_fm_sample()`, which is the generator's inner loop without the byte packing, over two carrier periods starting at the top of the attack, 1200 points per lane. The captions are the terms as the generator writes them: `m(t) = I · e^(−t/τm) · sin(2π · R · fc · t)` and `out(t) = sin(2π · fc · t + m(t)) · env(t)`.

## Sound locality and cleanup

The shipped player reaches 40 m; on the desks the rig shortens it to 18 m so the note stays in its hall. The `timbre_sculptor` at (9,8), 3.3 m from the desks, hums continuously as shipped; this placement's `#sound:near` (an opt-in word on that artifact, default off) lets its tone sound only while the listener — the viewport's camera — is within 3 m. Everything the staging builds is freed with the rig; the racks' dedicated audio buses are removed in their `_exit_tree`, so the museum's streamer leaves no bus behind when it frees and rebuilds the hall.

## Background: the vocabulary the racks use

### Additive synthesis

Any periodic waveform can be built by adding sinusoids. The Fourier series of a square wave is Σ (1/n) sin(nωt) for odd n; a sawtooth is Σ (1/n) sin(nωt) for all n. Truncating the series to a finite number of harmonics produces band-limited waveforms that avoid aliasing at high pitches. The `timbre_sculptor` stacks integer multiples of one fundamental this way, which is why no bell is reachable from its sliders.

### Sample rate and aliasing

Generating audio at 44,100 Hz restricts the signal's frequency content to half that rate, the Nyquist frequency at 22,050 Hz. Any component above it folds back into the audible range as an alias. Under heavy modulation the FM rig's instantaneous frequency reaches fc·(1 + I·R·e^(−t/τm)); at the highest settings the top of that sweep aliases, which is audible as a metallic edge and is part of the room's offer of awkward timbres.

### Subtractive synthesis

The complementary technique filters a harmonically rich source through lowpass, highpass or bandpass filters; the Moog and 303 racks work this way, a resonant lowpass carving a saw or a square down to a bass or a squelch.

### Envelope generators

An amplitude envelope shapes each note's volume over time. The classical ADSR has four phases: attack, decay, sustain, release. The FM rig uses two of them, a linear attack and an exponential decay, and gives the modulator its own decay, which is what lets the character of a note change independently of its loudness.
