# Field note: four chords on the sheet

1 October 2026. Observer: Claude, in two sessions. The first built this kit and was cut off before this note was written. The second ran everything again and wrote it. Both worked from the repository, from stills, and from the numbers of Godot's mixer. Nothing here was heard by an ear. Nothing was walked in a headset. No person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        Which two of the four chords look most alike as figures,
                 and does the tritone fill its square?
Baseline:        chord.tscn of this kit: chord.gd, two tones on 256 Hz at half
                 height each, the figure 5,512 beads of 2 cm; ratio "3:2".
Intervention:    one field, ratio: 1:1, 2:1, 3:2, 45:32.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     from the side 1:1 and 2:1 are the closest pair; 45:32 covers
                 92.43% of its square. From above no pair differs on more
                 than 0.37% of the still. Details below.
Another cause:   what the measure counts; the standpoint; where the faster
                 tone starts; the number of beads. All four were tried.
Decision:        follow once, then settle.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Scene.** `chord.tscn`. Each chord is built by `chord.gd` from a text, `ratio`, and a number, `low_hz`.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer. Headless, the sound is mixed by Godot's Dummy driver at 44,100 samples a second.
- **What I could see.** Stills of 960 by 720 pixels, one chord alone in the plain studio, the eye 2.6 m from a point 0.8 m above the ground, a 40 degree field of view, the body casting no shadow. Two stills differ at a pixel when its three channels together are more than 25 of 255 apart. A second still of each chord in one flat colour says which pixels are body. The figure's square, 1 m by 1 m, takes 21.95% of the still.
- **What stood in for hearing.** The samples in the buffer, decoded. And the mix on the Master bus, kept by an `AudioEffectCapture`: its loudest level in dB over 0.35 s, and how much of each of four tones is in it, by a Goertzel filter under a Hann window.
- **What I could not do.** Listen. No loudspeaker was used.

## The predictions, as the outline stated them

Both were written in the course outline before this kit existed.

1. "2:1 and 3:2 will look most alike: both close into small knots of a few lobes. 45:32 (the tritone) closes only after 32 turns of the slower tone, so in the still it fills its square."
2. "samples written as floats between -1 and 1 into the 16-bit buffer without scaling to 32767: silence".

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

The chord 3:2: 256 and 384 Hz, 88,200 bytes, the loudest sample 31,226 of 32,767. Through a plain player the mixer held 256 Hz at 0.50 and 384 Hz at 0.50 of the full range.

### T1. The silence (parent T0, status: consolidate)

**Intervention.** `data.encode_s16(i * 2, wave)`, the wave between −1 and 1, not stretched.
**Prediction.** The outline's second: silence.
**Observed.** Every one of the 44,100 samples is 0. `playing` is true, the position moves, the bus stays at −200 dB. A run without the debugger logged no error and no warning.
**Observed, first session only.** A run of the main scene with the debugger attached began with `WARNING: Narrowing conversion (float is converted to int and loses precision).` at `chord.gd:11`. The repaired line, with `int()`, ran the same way with no warning. The second session read both in the first session's logs and did not run with the debugger.
**Concluded.** The prediction held for the ear. Godot is not silent about it: the warning is there for whoever opens the Debugger.
**Not run.** `int(wave)` with the debugger attached. Without it: every sample 0, no error.

### T2. The sheet, from the side (parent T0, status: continue)

**Observed.** Share of the still on which two chords differ: 1:1 and 2:1, 3.43%; 1:1 and 3:2, 4.97%; 2:1 and 3:2, 5.97%; 3:2 and 45:32, 16.69%; 2:1 and 45:32, 18.13%; 1:1 and 45:32, 19.65%.
**Observed.** How much of its square each figure covers: 1:1, 4.07%; 2:1, 12.41%; 3:2, 20.08%; 45:32, 92.43%. Read back from the `MultiMesh`, the bead farthest from the rule was 0 m from it in all four.
**Concluded.** The first half of the outline's prediction did not hold by this measure: the closest pair is 1:1 and 2:1, and 2:1 and 3:2 are third of six. The second half held.

### T3. From above (parent T2, status: consolidate)

**Another cause.** One camera.
**Observed.** From straight above no pair differs on more than 0.37% of the still, and all six lie between 0.17% and 0.37%. Each chord covers 24.82% to 24.97% of the still.
**Concluded.** The axis is in one plane. From above every figure is a sheet of beads on edge. I draw no order of pairs from numbers this small.

### T4. What the measure counts (parent T2, status: consolidate)

**Another cause.** Ink. Two thin figures seldom lie on each other, so a count of differing pixels reads about the ink of both.
**Arithmetic, from T2's numbers.** As shares of the still the four figures are 0.89%, 2.72%, 4.41% and 20.29% (the cover times 21.95%). The ink of 1:1 and 2:1 together is 3.62%, measured difference 3.43%. 1:1 and 3:2: 5.30%, measured 4.97%. 2:1 and 3:2: 7.13%, measured 5.97%.
**Observed.** In each of the six pairs nearly all of the difference is outline, where one body is and the other is not: 3.42 of 3.43 for the closest pair.
**Concluded.** By this measure the order of the pairs is the order of their ink. "Most alike" here means "least ink together". The outline meant something else by alike, two knots of a few lobes, and a pixel count cannot see a lobe.

### T5. Where the faster tone starts (parent T4, status: branch)

**Another cause.** Both tones start at zero together. The unison is a line only because of that.
**Intervention.** The faster tone an eighth and a quarter of a turn ahead, on 1:1 and on 3:2, built bead by bead in `sheet.gd`. No prediction was written before this trial.
**Observed.** 1:1, an eighth ahead: an ellipse, 2.65% from the plain one, covering 8.39% of the square; the loudest sample falls from 1.00 to 0.92 of the range. A quarter ahead: a circle, 2.73%, 8.71%, the loudest 0.71.
**Observed.** 3:2, an eighth ahead: a curve that runs to an end and back over itself, 6.12% from the plain one, covering 10.37% in place of 20.08%; the loudest sample rises from 0.95 to 1.00. A quarter ahead: 0.15% from the plain one, covering 20.06%, the loudest 0.95.
**Concluded.** One ratio has more than one figure, and the sound's loudest sample changes with it. The fifth an eighth ahead has less ink than the plain octave.
**Not measured.** The turned figures against the other ratios.

### T6. The beads (parent T2, status: consolidate)

**Another cause.** The bead. "Fills its square" might be a statement about 2 cm and 5,512.
**Intervention.** 45:32 with one bead in eight, 689 beads.
**Observed.** It covers 28.12% of its square in place of 92.43% and differs from the full figure on 14.78% of the still. In the still it is separate dots.
**Observed, by the rule.** The beads of 45:32 fall in 2,166 of the 2,500 cells of a 50 by 50 grid over the square; those of 3:2 in 464, of 2:1 in 273, of 1:1 in 50.
**Concluded.** "Fills its square" is true of this bead and this count from 2.6 m. The curve is a line that has closed after 32 turns of the slower tone.

### T7. A body (parent T0, status: consolidate)

**Observed.** By keys pressed from the script: W for 45 steps and the Chord sounded alone; D for 18 and both sounded; D for 22 more and the neighbour alone.
**Observed.** By the autopilot, the mixer read at each stop. Outside both reaches: −200 dB. In the left reach: 256 and 384 Hz, −7.1 dB. The same from the fixed camera, after C: −16.9 dB. Where the two reaches overlap: 256, 384 and 512 Hz, −2.4 dB. At the neighbour's box the walker was stopped, 0.46 m from its middle, and only the neighbour sounded. It walked through both figures.
**Observed.** A marble dropped over the middle rested on the box at 0.50 m, having passed through the figure. Dropped 0.35 m to the side it lay on the floor at 0.10 m. It did not start the sound.
**Observed.** In its first steps the reach is entered by two bodies, both a `StaticBody3D`: the floor's and the chord's own box.
**Observed.** The voice with `unit_size` 1: −3.4 dB from 1 m, −9.4 from 2 m, −15.3 from 4 m. With Godot's default of 10: −0.4 dB from 1 m and from 4 m.
**Observed, in the room.** In a scratch copy of the room the guest stood at place 2. The walker was stopped by its box, 0.45 m from the middle of the place, and the room printed `Sound sounds`.
**Concluded.** The chord is three things to a body: a box that stops it, a reach that notices it, and a figure that does neither.

## What was observed, what was concluded, what is guessed

- **Observed.** The samples in each buffer. The levels and tones in the mixer at each stop. The share of pixels on which each pair differs, from two standpoints. How much of its square each figure covers, plain, turned and thinned. Where the walker stopped and where the marble came to rest.
- **Concluded.** 1:1 and 2:1 are the closest pair by this measure, and the measure is a measure of ink. 45:32 fills its square, with these beads. One ratio has more than one figure. The unscaled buffer is silence, with a warning.
- **Guessed.** That an eye would pair 2:1 and 3:2, as the outline did, and not the line and the bow. That with the unison drawn as a circle, 8.71% of its square, 1:1 and 2:1 would still be the closest pair by ink. That two chords at once are heard as one chord of three tones. None of these was tested.

## Unresolved

- **No ear was asked.** Every level is the mixer's. Whether the small figures are the ones that sound at rest, nothing here says.
- **The quarter turn of the fifth.** 0.15% from the plain figure, while an eighth of a turn gives another curve. I take it to be the same curve traced from another starting point. I did not check that beyond the still.
- **The swell in the room task differs between runs.** Over four runs the lowest of six short listenings was −17.4, −22.2, −22.2 and −15.6 dB, the highest −5.9, −5.9, −5.5 and −5.9. The cause is ordinary: each listening is 80 thousandths of a second of a swell that takes half a second, taken in real time.
- **`AudioStreamGenerator`** was read in the script of the Bernini columns and not run.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | settle | the planned fault is real; the warning was added to the page |
| T2 | follow | the outline's closest pair was not the measured one |
| T4 | consolidate | the order of the pairs is explained: it is the order of ink |
| T5 | follow once | the unison's line depends on one thing, where the faster tone starts |
| T5 | settle | a second axis, and a listener, are another study |
| T6 | consolidate | "fills" is tied to the bead and said so |

**The decision of this note: follow once, then settle.** I followed the start of the faster tone, because the figure with the least ink was a line only by that choice, and the closest pair hung on it. It showed that a ratio has more than one figure. I settle there. The kit claims that a ratio has a shape and that 45:32 fills its square, and says what the closest pair is made of. What the next step needs is an ear, and I do not have one.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6. No import is needed.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --audio-driver Dummy --script res://sheet.gd
```

The first runs 52 checks in about 30 seconds, among them T1, the walk and the drops of T7, and exits 0. The second needs a window: it photographs the chords, writes `sheet.json`, `sheet.png`, `process.png` and `scene.png`, and prints every number in T2 to T6. Run twice on this machine, it wrote the same four files byte for byte.

## Evidence

- `sheet.json`: every pair from both standpoints, the cover of each square, the turned figures, the thinned one, the strip.
- `verification.json`: the checks, with what each measured.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
