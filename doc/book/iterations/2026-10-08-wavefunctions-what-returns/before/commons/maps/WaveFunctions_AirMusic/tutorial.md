# A strike gives a note its own beginning

**Learning elements**

- Event-driven voices
- Independent clocks
- Decay envelopes
- Signal addition

Effect Sound let us keep a reference while changing the parameters of another note. In AirMusic, the comparison concerns events: one strike, a repeated strike on the same bar, and a second bar struck while the first continues. Synthesis Lab will build on the sum that appears here.

Take the striker from its cradle at the table's left end. Strike the longest bar, lift the stick away, and listen. Read the frequency and age above the row. Make the same contact again before the sound ends: the age restarts. Now use a different bar. Two ages continue together.

## One player belongs to each bar

`ResonatingMetallophone` creates eight `ResonatingBar` bodies for this room. Their notes are C4, D4, E4, G4, A4, C5, D5 and E5. Each owns its own `AudioStreamPlayer3D`. Starting one player again replaces that bar's current playback; starting a different player's note leaves the first one running.

The length is assigned from the chosen frequency:

```gdscript
return BAR_LENGTH * sqrt(root / maxf(1.0, freq))
```

The lowest note keeps a length of 0.30 m. Higher notes get shorter bars. This is a mapping from frequency to visible form, not a simulation deriving sound from the material. Other tunings exist as source configurations; this hall has no visitor tuning selector.

## A recognised contact starts the response

The rigid body's contact signal and its `StrikeZone` area feed `_on_body_hit`. The handler follows the hitting node's ancestors to recognise the striker's tip, which is a child collider rather than the stick's root. It ignores the stick while it is returning to its cradle and suppresses closely spaced duplicate notifications.

Strike strength comes from velocity, including the speed measured from a held stick's changing position. The handler applies:

```gdscript
hit_velocity = clamp(velocity_magnitude * 2.0, 0.1, 1.0)
```

Try a slow and a quick contact on the same bar. Above 0.5 m/s this mapping has already reached its ceiling of one. Below it, strength changes without changing the chosen frequency. The bar then starts its response:

```gdscript
is_resonating = true
resonance_time = 0.0
current_amplitude = impact_strength * max_amplitude
```

```gdscript
audio_player.volume_db = -6.0 + (impact_strength * 6.0)
audio_player.play()
```

The visible response starts from strength times `max_amplitude`. Playback volume uses a decibel mapping. At strength 0.1, glow starts at one tenth of its full-strength value, while the player's gain is about 0.54 of its full-strength gain. These are different representations of the same strike, not equal measurements of loudness.

## The buffer was made before you touched it

Each bar generates its mono PCM note once during setup, at 44,100 samples per second. Inside that loop:

```gdscript
var envelope = exp(-t / decay_time)
```

```gdscript
var wave = sin(2.0 * PI * frequency * t)
```

```gdscript
var sample_value = wave * envelope * max_amplitude
var sample_int = int(sample_value * 32767.0)
```

The sine and envelope are multiplied, then encoded as a signed 16-bit sample. The collision does not solve a metal bar's vibration or regenerate this buffer. It chooses when the stored note starts and at what player gain.

The default decay constant is three seconds. After three seconds the exponential is `exp(-1)`, about 0.368 of its initial amplitude. Its mathematical tail has no finite end. The implementation makes a finite buffer:

```gdscript
return maxf(1.0, decay_time * 2.5)
```

For this room that is 7.5 seconds. The last 0.1 seconds receive an additional fade. The bar clears its resonance state when the player stops, so the glow cannot remain as a claim that the note still plays. The final audio fade and the glow's exponential are not identical curves.

## Two notes, two clocks, one picture

Strike C4, wait a little, then strike A4. Each audio player has its own playback position. The table's scope reads a 12 ms window near each position using 512 points. For every point it decodes that bar's PCM and includes the player's gain:

```gdscript
samples[i] = float(pcm.decode_s16(frame * 2)) / 32768.0 * gain
```

The visualiser adds the windows:

```gdscript
_summed_samples[i] += values[i]
```

The gain is fixed: one signal unit becomes 0.15 m of height. The drawn range is limited to ±1 and the readout reports `display limit` if the sampled sum exceeds it. The stored sum remains available for inspection. The picture does not automatically enlarge a fading signal.

This display follows source playback positions, which advance with audio mixing. It is not a microphone at the listener's head and does not include spatial attenuation, bus effects or the output device. The reported ages can differ slightly from the frame-updated glow ages. Watching the ribbon does not replace listening to the overlap.

The striker returns when left more than 0.5 m from its rest, unheld, for three seconds. Its three-part return takes another 0.75 seconds and is excluded from striking. A returning tool should not compose extra notes on its way across the row.

Try the same pair far apart and then overlapping. The pitches can stay fixed while the relation changes through their starting times. That is what the Synthesis Lab inherits: a sum depends on the terms, their levels and where they are in their cycles.
