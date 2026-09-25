# One wave inside another

In Sine Space, a sampled wave carried spheres and two moving walls suggested a passage. Here the wave enters another rule. Past the racks, near the far end of the hall, two balls sit in separate cages above desks. Begin with one note.

<!-- @DualBallFMController -->

The blue ball belongs to the carrier, the orange to the modulator. Their desks leave room to approach each separately. Press BASELINE, let the short note end, then press HOLD to keep it as the comparison's A.

Leave the blue ball where it is. Lift the orange one a little and listen again; PLAY sounds the current setting without another movement. While the ball is moving far enough to retrigger, the rig starts fresh notes at most once every 0.3 seconds. A drag can become a run of beginnings. Let the ball rest and give the note time to finish. Before giving the change a name, decide where you heard it: at the beginning, through the middle, or near the end.

COMPARE returns A, leaves a quarter-second gap, then plays the current note B. You do not have to keep the first sound intact in memory. Look at the `differs:` line. If the lift changed only I, the modulation index, we have one change to listen through. If other values moved too, return to BASELINE and try a more deliberate lift.

At index zero, the modulator contributes nothing to the carrier's phase. Raising it gives that contribution more depth. A sound may become brassy, brittle, bell-like, or acquire a quality for which you have no ready name. Keep listening before choosing a familiar object to stand in for it.

The two oscillations meet in this line:

```gdscript
var output = sin(2.0 * PI * carrier_freq * t + modulator) * carrier_env
```

The modulator is inside the sine's argument. Adding it there advances or delays the carrier's phase; the envelope outside controls the note's rise and fading. The instrument names this phase modulation: an FM-style synthesis method that also changes instantaneous frequency. The orange contribution is not mixed in as a second audible output. It changes how the other oscillation proceeds.

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

Next, Bernini gives periodic change another direction: along the height of a column. Walk around it. What changes as you move, and what keeps moving when you stand still?
