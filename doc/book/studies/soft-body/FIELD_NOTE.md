# Field note: a cloth asked 1, 4, 16 and 64 times

1 October 2026. Observer: Claude, the session that built this kit, working from the repository, from numbers the scripts wrote and from stills. Nothing here was walked by a body in a headset, no hand held the cloth, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        How much of a cloth's stiffness is the number of times a step
                 asks its links to keep their length?
Baseline:        cloth.gd of this kit: 11 by 11 particles, 0.12 m apart, 220 links,
                 hung by its two top corners at 2 m, 4 passes a step, 60 steps a second.
Intervention:    one field, iterations: 1, 4, 16, 64.
Prediction:      the course outline's, written before any run (quoted below).
Observation:     16 and 64 are the closest pair. The cloth is not taut at 64, and
                 from 16 to 64 its lowest point rises 8.62 cm. Details below.
Another cause:   where it is held; the rule for a link with a held end; the net's
                 grain; the solver; how the passes are spread over time. All five tried.
Decision:        follow twice, then settle.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Body.** `cloth.gd`: particles that keep two places and no speed, links relaxed in passes, each pass moving both ends of a link half of its error; a pinned particle does not move.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer.
- **What I could measure.** The cloth is stepped by the script that measures it, 1200 steps of 1/60 s, so every number of our cloth came out the same on every run. Lengths are read from the particles. Stills are 960 by 720 pixels, the cloth alone, seen from the front, 3.2 m away; two stills differ at a pixel when their three channels together are more than a tenth of full scale apart.
- **What I could not.** An eye: "look alike" below is a count of pixels. A hand. The time of a step on any machine but this one, and that time moved from run to run because other programs were running.
- **Taut.** If no link gave, the lowest point would be at 0.80 m. "Below taut" is how far under that it hangs.

## The prediction, as the outline stated it

"16 and 64 will look most alike: the cloth hangs taut, and the extra passes remove less than a centimetre of stretch. 1 sags like rubber."

The outline's planted bug: "the subclass's _init forgets super(), so pinned particles have no position and the cloth hangs from the origin".

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

4 passes: the lowest point at 0.4264 m, 37.36 cm below taut. The longest link is 144.4% of its length; it is on a pinned corner.

### T1. The forgotten super() (parent T0, status: consolidate)

**Observed.** A subclass whose `_init()` does not call `super()` is made with the fields as declared: `position` is (0, 0, 0). Godot printed no error and no warning. `super()` with no argument, where the parent asks for one, did not load: `Parse Error: Too few arguments for "_init()" call. Expected at least 1 but received 0.`
**Observed.** In the scene the nailed corner stayed at the cloth's origin, the middle of its top edge. The corner with a holder was at the origin for one step and at the Hand from then on. The readout: lowest point 0.22 m, longest link 141%.
**Concluded.** The outline's bug is real and silent in Godot 4.6. It is half of what the outline says: a pinned particle that is told where to be at every step recovers.

### T2. The sheet (parent T0, status: continue)

**Observed.** Lowest point at 1, 4, 16 and 64 passes: 0.1162, 0.4264, 0.5603 and 0.6465 m. Below taut: 68.38, 37.36, 23.97 and 15.35 cm. Longest link: 284.7, 144.4, 118.1 and 107.9% of its length. Mean error of a link: 12.57, 3.43, 0.96 and 0.28%.
**Observed.** Share of the still on which two cloths differ: 1 and 4, 7.10%; 1 and 16, 10.93%; 1 and 64, 13.79%; 4 and 16, 4.07%; 4 and 64, 7.08%; 16 and 64, 3.02%. All of it is outline: one cloth is there and the other is not. Between 16 and 64 that is a band 16.27 pixels wide.
**Observed.** A step took 0.18, 0.61, 2.23 and 8.89 ms when the sheet ran.
**Concluded.** The closest pair is 16 and 64: that held. "1 sags like rubber" held. "Hangs taut" is false: at 64 passes it is 15.35 cm below taut. "Less than a centimetre" is false: 8.62 cm.
**Concluded.** A fourfold of passes takes 45%, 36% and 36% off the sag, and the mean error of a link falls faster than the sag does: to 27%, 28% and 29% of what it was.

### T3. Where it is held (parent T2, status: branch)

**Another cause.** Two corners carry everything, and a taut edge that is a little too long sags a lot. The count may matter less than the hanging.
**Intervention.** The whole top row pinned, eleven particles, nothing else changed.
**Observed.** Lowest point at 0.6495, 0.7636, 0.7919 and 0.7988 m. From 16 to 64 it rises 0.69 cm. At 64 it is 0.12 cm below taut.
**Concluded.** The outline's sentence is true of a cloth hung by its edge and false of one hung by its corners. At the same count the corner-hung cloth is 15 cm off and the edge-hung one a millimetre.

### T4. The rule for a held link (parent T2, status: consolidate)

**Another cause.** Our pass moves each end of a link half of the error. A pinned end does not move, so a link on a pin is mended by half.
**Intervention.** The free end of such a link takes the whole error.
**Observed.** Lowest point at 0.2056, 0.4591, 0.5766 and 0.6575 m: 9, 3.3, 1.6 and 1.1 cm higher than ours.
**Concluded.** The rule matters most where the cloth is worst, and explains about a centimetre at 64 passes. It is not why the cloth is slack.

### T5. The grain (parent T2, status: consolidate)

**Intervention.** The same 1.2 m as 6 by 6, 11 by 11 and 21 by 21 particles, at 16 passes.
**Observed.** Lowest point at 0.6739, 0.5603 and 0.4037 m. A step took 0.54, 2.08 and 8.07 ms.
**Concluded.** At one count a finer net is a softer cloth. A count is stiff or slack only for a net of a given size.

### T6. The same passes as smaller steps (parent T2, status: branch)

**Intervention.** Four steps of 1/240 s with four passes each, in place of one step of 1/60 s with sixteen.
**Observed.** Lowest point at 0.6452 m. Sixteen passes in one step: 0.5603 m. Sixty-four in one step: 0.6465 m. It took 2.19 ms for 1/60 s, where 16 passes took 2.08 and 64 took 8.29 in the same run.
**Concluded.** How the passes are spread over time mattered as much as a fourfold of them.
**Guessed.** That a short step lets gravity pull each particle a sixteenth as far before the links are asked. I did not take the step apart to see.

### T7. Another solver (parent T2, status: unresolved)

**Intervention.** Godot's `SoftBody3D` on a plane of the same 11 by 11 points, pinned at the same two corners, Linear Stiffness 0.5, at Simulation Precision 1, 4, 16 and 64.
**Observed, with a window, in `sheet.gd`.** Lowest point at 0.5730, 0.7007, 0.7708 and 0.7952 m. Closest pair 16 and 64, 0.86% of the still. From 16 to 64: 2.44 cm. Twice the same to the last pixel.
**Observed, without a window, in `verify.gd`.** 0.6432, 0.7505, 0.7872 and 0.7975 m. From 16 to 64: 1.03 cm.
**Observed.** In scratch probes, which are not in this kit, it rested at 0.72 to 0.74 m at precision 4, and what had stood in the scene before it changed where it rested.
**Concluded.** It is tighter than ours at every count, and the outline's centimetre is false for it too, by a little or by a lot.
**Unresolved.** Why the same body with the same settings rests at different heights in different runs. I did not find the cause.

### T8. A body in it (parent T0, status: stop)

**Observed.** A walker sent into the cloth arrived; the cloth stopped nobody. Told where the walker is, the cloth was pushed 0.29 m out of its plane; ten seconds after the walker walked on it was 0.023 m out and swinging back.
**Observed.** A walker sent into Godot's soft body arrived, and the soft body moved 0.0000 m. Unpinned, it fell through the supplied floor.
**Observed.** With its nail gone the cloth hung from the Hand as a rope: 100 particles in the air, none more than 0.013 m from the line under the Hand. Dragged over a capsule of the walker's size and let go, none of the 121 stayed above 0.5 m, at 4 passes or at 16.
**Concluded.** The place asked for a cloth draped over a body. This one cannot do it: its particles pass through each other, so held by one corner it has no width.

## What was observed, what was concluded, what is guessed

- **Observed.** Every height, length and share of pixels above. The silence of the forgotten `super()`. How each walk ended.
- **Concluded.** 16 and 64 are the closest pair. The cloth is not taut at any count we tried. Where it is held and how the passes are spread over time each move it more than a fourfold of passes does.
- **Guessed.** That the sag falls more slowly than the stretch because a taut edge sags with something like the square root of its extra length. That a person at 3 m would call 16 and 64 the most alike. Neither was tested.

## Unresolved

- **Godot's soft body is not the same in every run** (T7).
- **No eye was asked.** A band of 16 pixels is easy to see in a still; whether two swinging cloths are told apart was not tried.
- **The times.** A step at 64 passes took 8.89 ms when the sheet ran and 8.29 ms when the checks ran, and more in runs made while other programs were busy.
- **The headset.** A soft body is stepped once and drawn for two eyes. Nothing here was drawn for two.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T2 | follow | the prediction was false by a factor of eight, and the sheet could not say why |
| T3 | follow once more | one cause, the hanging, explained it; it left open what to do for a cloth that must hang by its corners |
| T6 | settle | the same passes as four small steps do what four times the passes do |
| T7 | leave open | a body that rests differently from run to run needs a session of its own |
| T8 | stop | a cloth that folds into a line needs particles that keep out of each other: another chapter's work |

**The decision of this note: follow twice, then settle.** I followed the hanging because the prediction failed by so much, and the timing of the passes because the hanging could not be changed for a cloth that is carried by a corner. I settle on this: the count of passes is a budget, and where the cloth is held and how the budget is spread over time decide what it buys.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --path . --xr-mode off --script res://sheet.gd
godot --headless --path . --xr-mode off --script res://verify.gd
```

The first needs a window: it writes `sheet.json`, `sheet.png` and `process.png`, and prints every number in T2 and the windowed half of T7. The second prints T1, T3 to T6, the other half of T7, and T8, and writes them to `verification.json`.

## Evidence

- `sheet.json`: both rows, every pair, the strip. `sheet.png`, `process.png`.
- `verification.json`: the checks, and under `measured` every number of T1 and T3 to T8.
- `stills/`: the single stills. The folder is not tracked; `sheet.gd` makes it again.
