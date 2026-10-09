# One wave enters another rule

In Sine Space we applied sine to a position and asked what the resulting surface let a body do. Effect Sound keeps the oscillation and changes its destination: one sine enters the phase of another. AirMusic will carry this listening into a struck body whose response continues after contact.

Begin at the two desks. Press BASELINE, wait for the note, then HOLD. Lift only the orange ball, let it settle and press COMPARE. A is the held note; B is the current setting, played after A and a quarter-second gap. Decide where the change happens before reading the formula: near the onset, through the middle, or in the tail.

## A position becomes three values

The primary artifact is `DualBallFMController`. Each ball belongs to a `ValueMapper3D` cage with a half-metre span. Its three local axes supply three numbers.

| Ball | Local x | Local y | Local z |
|---|---|---|---|
| Blue carrier | Frequency, 100–2000 Hz | Attack, 0.01–0.5 s | Decay, 0.1–3 s |
| Orange modulator | Frequency ratio, 0.5–8 | Phase depth / index, 0–10 | Modulator decay, 0.1–2 s |

These are the cage's axes. The whole instrument faces north in this room, so follow its arrows rather than assuming screen-right is positive world x. Translation supplies a parameter here; it does not carry the sound to the ball's new location. The rig's audio player stays with the instrument.

The orange cage's signal reaches this assignment in `_on_modulator_changed`:

```gdscript
mod_ratio = x
mod_index = y
mod_decay = z
```

A hand can change several values at once. The `differs:` line compares the six current values with the held reference. Use it to make a deliberate one-variable comparison. It has a reporting tolerance: changes up to 1 Hz for carrier frequency, or 0.005 for another value, are not listed. An empty list is agreement within those tolerances.

## The other wave goes inside the sine

The generator computes a time for each sample:

```gdscript
var t = float(i) / SAMPLE_RATE
```

`SAMPLE_RATE` is 44,100. This is an index into the note being generated, not the running museum clock. All the samples are calculated before that note begins playback. The baseline's 1.8 seconds contain 79,380 samples.

The orange values make a decaying contribution to phase:

```gdscript
var mod_env = exp(-t / mod_decay)
```

```gdscript
var modulator_freq = carrier_freq * mod_ratio
var modulator = sin(2.0 * PI * modulator_freq * t) * mod_index * mod_env
```

The ratio gives the modulator frequency relative to the carrier. Index sets how far it displaces the carrier's phase; its unit here is radians. The decay controls how quickly that displacement fades. At index zero the entire contribution is zero, whatever its frequency or decay.

Now read the carrier's line:

```gdscript
var carrier_env = attack_env * decay_env
var output = sin(2.0 * PI * carrier_freq * t + modulator) * carrier_env
```

The modulator is added inside the argument. It advances and delays the carrier's phase. It is not added to the final signal as a separate voice. The instrument is called FM; this expression implements phase modulation, whose changing phase also changes instantaneous frequency.

Return to the orange ball. Keep its height and left-to-right position steady while changing depth. COMPARE again. A longer modulator decay can keep changing the character while the carrier's own envelope grows quiet. One apparent fading contains two adjustable processes.

## An envelope is another rule

Before the carrier line, the actual generator constructs its amplitude envelope:

```gdscript
var attack_env = 1.0
if t < attack_time:
    attack_env = t / attack_time
```

```gdscript
var decay_env = 1.0
if t > attack_time:
    decay_env = exp(-(t - attack_time) / decay_time)
```

The attack ramps to one; the subsequent decay falls exponentially. The generator later applies:

```gdscript
output = tanh(output * 0.8) * 0.5
```

Even BASELINE has an envelope, this nonlinear shaping, gain and 16-bit quantisation. Index zero gives an unmodulated reference, not a sound before processing.

The note's file ends according to a separate rule:

```gdscript
var duration = min(decay_time * 1.2, 3.0)
```

An exponential has not mathematically reached zero when this finite buffer ends. Listen to the tail as an ending the implementation chose. PLAY lets the whole buffer run if another action does not replace it. During a drag the movement threshold and 0.3-second minimum interval can repeatedly restart playback, so moving continuously does not audition the same thing as letting one note finish.

## What HOLD saves, and what the scope selects

HOLD captures both parameters and a rendered sample buffer. Changing B does not regenerate A. COMPARE replays A, waits its duration plus 0.25 seconds, then renders the current B. Leave the controls alone during that pair if you want the comparison you prepared.

The scope is computed from the synthesis expression. It is a selected window, two carrier periods beginning at `attack_time`, with 1,200 points in each waveform lane. The orange lane is divided by index; the output lane is magnified twofold. The carrier lane is shown without its amplitude envelope. These choices make shapes inspectable, but equal screen heights do not mean equal signal amplitudes. The scope is neither a microphone recording nor the whole note.

Keep one sound because you want to hear it again. Change one relation that made it, then listen. This is the capability we carry to AirMusic: a body can answer a brief contact over time, and the way we inspect that answer can reveal one difference while hiding another.
