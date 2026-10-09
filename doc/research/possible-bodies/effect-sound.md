# One wave inside another

[Sine Space](sine-contact.html) → **Effect Sound** → [AirMusic](air-music.html)

[The primary and its book passage](/necklace/thread?map=WaveFunctions_Effect_Sound&role=primary) · [Wavefunctions work plan](/research/waves-chance-noise/index.html#WaveFunctions_Effect_Sound)

In Sine Space, a wave became a contact surface or the shape of a passage. Here it enters another wave's phase. The question changes with the construction: **what does one oscillation let another become?**

Claude built the two-desk encounter and repaired its blocked readout and overlapping names. Astra's independent review keeps that work. Both names and the low readout are visible from the operating area; the surrounding instruments remain further explorations. The book follows one primary, `DualBallFMController`.

![The reviewed standing view: carrier and modulator desks, low comparison readout and scope](effect-sound-operating.png)

## Keep one sound, change one relation

Press BASELINE and let the note end. HOLD saves it as A. Lift the orange ball while keeping its other directions steady, then let it rest and COMPARE. A plays first, followed by a quarter-second gap and the current B. Listen for where the change happens before naming a timbre.

The same comparison is available here for remote listening. These are the exact mono samples rendered by the independent probe. The pairs join two notes with 0.25 seconds of silence; they have no added gain or normalisation. Your playback equipment supplies another part of the encounter.

**1. Add modulation.** First: index 0. Second: index 4. Carrier, envelopes, ratio and modulator decay remain the same. Each note lasts 1.8 seconds.

<audio controls preload="metadata" aria-label="Compare modulation index zero and four"><source src="effect-sound-compare-index.wav" type="audio/wav">Your browser can download the comparison WAV.</audio>

**2. Let the change persist.** First: modulator decay 0.5 seconds. Second: 1.5 seconds. Both use index 4. Listen through the tail; the carrier's decay has not changed.

<audio controls preload="metadata" aria-label="Compare short and long modulator decay"><source src="effect-sound-compare-decay.wav" type="audio/wav">Your browser can download the comparison WAV.</audio>

[Baseline note](effect-sound-audio_A_baseline_unmodulated.wav) · [Index 4, short modulation decay](effect-sound-audio_B_index4_moddecay0.5.wav) · [Index 4, long modulation decay](effect-sound-audio_B_index4_moddecay1.5.wav)

## The picture makes a choice too

The modulator enters the carrier's sine argument. It changes phase rather than joining the output as a second voice. The expression is in the book after the first listening comparison.

There is a small surprise in the scope: its orange lane divides by modulation index. Once the index exceeds the small denominator threshold, raising it can change the sound while leaving that trace's height unchanged. The output lane is magnified twofold. The display selects two carrier periods near the attack, so the whole fading note is absent from the picture. These choices make particular relationships easier to inspect and leave others to uncover.

![The complete comparison readout, now outside the platform that had enclosed it](effect-sound-readout.png)

| Control | What it does |
|---|---|
| BASELINE | Sets the unmodulated 440 Hz reference, with envelope and shaping, and plays it. |
| HOLD | Saves the current six values and rendered note as A, then plays A. |
| PLAY | Renders and plays the current setting B. |
| COMPARE | Replays A, then renders B after A and a 0.25-second gap. Without A, it first holds the current note. |

The `differs:` line helps separate parameter changes; small differences below its reporting tolerances are omitted. Leave the balls still during COMPARE to hear the pair you prepared. Moving continuously can restart the note before its tail is heard.

## Review and next visit

**100 independent desktop checks passed; the engine exited normally.** The run exercised both mapper paths, audition buttons, sample comparisons, the scope, approach routes, local sound activation, cleanup and room rebuilding. The original saved hand and Claude's evidence were preserved. No gameplay code or room geometry changed in this review.

The revised supporting tutorial now teaches this instrument and uses eleven checked production-code excerpts across tutorial and final. It corrects the older unrelated waveform examples and distinguishes sample generation, the finite buffer, scope gains and listening. One primary book artifact remains aligned across the room, roles and text.

Headset reach and a person's listening observations remain open. The ball movement in the probe follows the mapper path; it does not demonstrate a tracked-hand grab. Buttons use the project's desktop input rig. The small targets and labels deserve a headset visit, and the backs of secondary displays still crowd the wider room view.

[Desktop report](effect-sound-check.json) · [Independent run receipt](effect-sound-run.json) · [Tutorial](effect-sound-tutorial.md) · [Technical notes](effect-sound-technical.md) · [Critical text](effect-sound-critical.md)

**Next: [AirMusic](air-music.html).** A strike is brief; the response continues. Keep the habit of listening through an ending before deciding what kind of body answered.

## Book passage

# One wave inside another

In Sine Space, a sampled wave carried spheres and two moving walls suggested a passage. Here the wave enters another rule. Two balls sit in separate cages above desks. Begin with one note.

<!-- @DualBallFMController -->

The blue ball belongs to the carrier, the orange to the modulator. Their desks leave room to approach each separately. Press BASELINE, let the short note end, then press HOLD to keep it as the comparison's A.

Leave the blue ball where it is. Lift the orange one a little and listen again; PLAY sounds the current setting without another movement. While the ball is moving far enough to retrigger, the rig starts fresh notes at most once every 0.3 seconds. A drag can become a run of beginnings. Let the ball rest and give the note time to finish. Before giving the change a name, decide where you heard it: at the beginning, through the middle, or near the end.

COMPARE returns A, leaves a quarter-second gap, then plays the current note B. You do not have to keep the first sound intact in memory. Look at the `differs:` line. If the lift changed only I, the modulation index, we have one change to listen through. If other values moved too, return to BASELINE and try a more deliberate lift.

At index zero, the modulator contributes nothing to the carrier's phase. Raising it gives that contribution more depth. A sound may become brassy, brittle, bell-like, or acquire a quality for which you have no ready name. Keep listening before choosing a familiar object to stand in for it.

The two oscillations meet in this line:

```gdscript
var output = sin(2.0 * PI * carrier_freq * t + modulator) * carrier_env
```

The modulator is inside the sine's argument. Adding it there advances or delays the carrier's phase; the envelope outside controls the note's rise and fading. The room calls this FM synthesis. This expression implements phase modulation, which also changes instantaneous frequency. The orange contribution is not mixed in as a second audible output. It changes how the other oscillation proceeds.

Now keep the height of the orange ball as steady as you can and change its depth along the desk. That direction changes the modulator's decay. Listen through the tail before moving again. Can the altered character persist while the note grows quiet?

The modulator has a fading of its own:

```gdscript
var mod_env = exp(-t / mod_decay)
var modulator_freq = carrier_freq * mod_ratio
var modulator = sin(2.0 * PI * modulator_freq * t) * mod_index * mod_env
```

A longer `mod_decay` keeps the phase disturbance present for more of the note. The carrier's envelope can remain the same. Something we first heard as one fading has separated into two processes we can vary.

Try the orange ball's left-to-right direction last. It changes the ratio between the oscillators' frequencies. Keep a reference and compare. Listen for a relation you want to return to, even if it refuses the name of an instrument you know. A setting that would spoil one imitation may be the beginning of another sound.

BASELINE is a chosen reference too: a 440-hertz carrier, an attack and a decay, index zero. The generator still applies its `tanh` shaping and gain to the output. Calling this the beginning makes a comparison possible; it does not uncover a sound before all decisions.

HOLD can keep a note without knowing what you liked about it. COMPARE gives that decision back to your ear. The rig reports changed parameters, but there is no field in its list for the difference that made you want to listen again.

<!-- @ -->

Look back at the scope. Once the orange contribution is above zero, raising its index need not make the orange trace taller: the display divides that lane by the index to fit it. The output changes while the apparent height of its cause can stay much the same. Even this small window has an arrangement to uncover. It shows two carrier periods near the attack, not the whole fading note. The coloured cube gives some of the settings another appearance. Neither can take over the listening.

In AirMusic, a strike starts a response that continues after contact. Carry this habit to the bar: give a sound time to change before deciding what sort of body has answered.
