# Field note: one throw at four lengths of step

1 October 2026. Observer: Claude, the session that built this kit, working from the repository, from printed lines and from stills. Nothing here was walked by a body in a headset, and no person looked at the stills to say which two look alike.

This is the kit's own note, in the form of [the decision and the field note](../../course/opening/FIELD_NOTE.md). It is an example of the form. Your note will have another decision in it.

## The note

```
Question:        How long may a step be before the stepped path stops being the curve?
                 And which two of four steps give the most alike paths?
Baseline:        launch.tscn of this kit: a ball thrown at (4, 6, 0) m/s from 0.1 m,
                 gravity 9.8 m/s2, stepped by velocity += pull() * dt; at += velocity * dt.
Intervention:    one field, steps_per_second: 10, 30, 60, 240 (dt = 1 / it).
Prediction:      the course outline's, written before any run (quoted below).
Observation:     which pair is closest depends on the measure. Details below.
Another cause:   the ink of the drawing; the step a flight happens to end on;
                 the order of the two lines; the frame's length. All four were tried.
Decision:        follow twice, then settle.
Reason:          below.
Run it again:    the two commands at the end.
```

## The apparatus

- **Scene.** `bullet.tscn`, alone in the kit base's studio for the stills; `launch.tscn` for the flights in time and for the Walker; `orbit.tscn` for the field trip.
- **Engine.** Godot 4.6.stable.official.89cea1439, Windows, an NVIDIA GeForce RTX 3070, the Compatibility renderer, a screen of 59.95 Hz.
- **What I could see.** Printed lines; the bullet's own fields after every step; stills of 960 by 720 pixels, the flight seen level from 6.6 m with a 40 degree field of view. Two stills differ at a pixel when their three channels together are more than a tenth of full scale apart.
- **What I could not see.** An eye. A hand on the keys. The editor's windows.

## The predictions, as the outline stated them

1. "1/60 and 1/240 will look most alike: their landing points are a few centimetres apart. 1/10 is visibly a polygon and lands somewhere else."
2. "planted bug: the two update lines swapped (explicit against semi-implicit Euler), so the orbit in the field trip spirals outward".

## The trajectory

Each state names its parent. Status is one of continue, consolidate, branch, unresolved, stop.

### T0. Baseline

At 60 steps a second the flight takes 73 steps and lands 4.867 m from the launch. The formula x = 2 · 4 · 6 / 9.8 gives 4.898 m.

### T1. The sheet (parent T0, status: branch)

**Observed.** Steps: 12, 36, 73, 293. Landing: 4.8000, 4.8000, 4.8667, 4.8833 m. Highest place: 1.642, 1.838, 1.887, 1.924 m; the formula's is 1.937 m. Sharpest corner of the path: 13.85, 4.68, 2.34, 0.59 degrees.
**Observed.** Share of the still on which two flights differ: 1/10 and 1/30, 0.49%; 1/10 and 1/60, 0.83%; 1/30 and 1/60, 0.85%; 1/60 and 1/240, 1.19%; 1/10 and 1/240, 1.36%; 1/30 and 1/240, 1.40%.
**Concluded.** By this count the closest pair is 1/10 and 1/30, and 1/60 and 1/240 are fourth of six. The outline's first prediction is false by the measure every earlier kit used.
**Decision.** Follow. **Reason.** The result contradicts the eye's first impression of the sheet, where the two fine steps both read as a solid curve.

### T2. Is it the ink? (parent T1, status: consolidate)

**Another cause.** The count compares pixels, and the four drawings do not have the same number of them.
**Observed.** The four flights cover 0.29%, 0.44%, 0.66% and 1.19% of the still. Two drawings that share nothing differ on the sum of what they cover: for 1/10 and 1/30 that would be 0.73%, and they differ on 0.49%; for 1/60 and 1/240 it would be 1.85%, and they differ on 1.19%.
**Concluded.** The pixel count ranks these pairs mostly by how much ink they hold. It is the wrong ruler for a drawing made of dots. The ball lying on the same spot in two stills also lowers the count.
**Observed, with other rulers.** Landings apart: 1/10 and 1/30, 0.00 cm; 1/60 and 1/240, 1.66 cm; the other four pairs 6.67 or 8.33 cm. Highest places apart: 1/60 and 1/240, 3.7 cm; 1/30 and 1/60, 4.9 cm; 1/10 and 1/30, 19.6 cm.
**Concluded.** The prediction held by the height of the path, and for the phrase "a few centimetres apart" (1.66 cm). It did not hold for the landing: 1/10 does not land "somewhere else", it lands where 1/30 lands. Both flights end on the step that ends at 1.2 s. That is a coincidence of this launch and these two steps; I did not try another launch.
**Decision.** Settle on three rulers in the lesson, and say which one the outline wins.

### T3. Under the formula (parent T1, status: consolidate)

**Observed.** In the air the stepped ball is under the formula's ball of the same moment by at most 53.9, 19.1, 9.8 and 2.5 cm. At 120 steps a second 4.9 cm, at 1,000 steps 0.6 cm.
**Concluded.** The gap is proportional to the step: g/2 times the time flown times dt, which the checks confirm to 1.5 mm. There is no step at which it becomes zero, and no step at which it jumps.
**Concluded.** The outline's claim, "below some step size it is the curve", is true of the drawing (at 1/240 the dots touch in the still, at 1/60 they stand apart) and not of the numbers.

### T4. The swap (parent T0, status: branch)

**Intervention.** The two lines of `step()` the other way round.
**Observed.** Landings 5.6000, 5.0667, 5.0000, 4.9167 m; 14, 38, 75, 295 steps; at 1/10 the highest place is 2.242 m. Godot logged no error and no warning.
**Concluded.** A silent fault, as planned: the flight is another flight and nothing says so.
**Observed.** The orbit of `orbit.tscn`, stepped 60 s at 60 steps a second with the lines swapped: never nearer the centre than 0.984 m, never further than 1.017 m, 19.08 turns. In the right order: the same three numbers.
**Concluded.** The outline's second prediction is false. The swap does not open the orbit.
**Decision.** Follow. **Reason.** The lesson's debt section rests on an orbit that leaks. It needs a fault that is real.

### T5. Both lines from the old state (parent T4, status: consolidate)

**Intervention.** Three lines: keep the old velocity, change the velocity by the pull at the old place, move the ball by the old velocity.
**Observed.** At 60 steps a second: 1.377 m from the centre after one turn; on the floor after 479 steps, 7.98 s, 1.67 turns. At 240: 1.102 m after one turn; on the floor after 25.97 s, 5.71 turns. At 10: on the floor after 4.1 s, before one turn.
**Observed.** On the launch these three lines give the same four flights as the swap.
**Concluded.** What holds the orbit is that the second update reads what the first has just written, in either order. With constant gravity the swap and the three lines cannot be told apart, because the pull does not read the place.
**Not measured.** Energy. The spec says explicit Euler "owes energy". I measured the distance from the centre and wrote that.

### T6. By the frame (parent T0, status: unresolved)

**Intervention.** The step is the frame's own `delta`, once for each drawn frame.
**Observed, in `sheet.gd`.** Five flights: 74, 73, 73, 73, 73 steps; landings 4.8708, 4.8695, 4.8339, 4.8667, 4.8667 m. In the last two every frame was 0.01667 s, and the flight is the tick's flight.
**Observed, in scratch, not in the kit's files.** The lesson's `_process` script run six times as the project, in a window: 73 steps and 4.888 m; 71 and 4.831; 73 and 4.887; 71 and 4.842; 71 and 4.852; 70 and 4.864. With `_physics_process`: 73 steps and 4.867 m, four times of four.
**Concluded.** The flights differ where the frames are uneven, which here was the start of a run. Once the frames are even at 60 a second, the frame's step is the tick's step.
**Guessed.** That on a screen of 144 Hz the same script lands near the 1/144 flight. I have no such screen.

### T7. The engine's own (parent T0, status: consolidate)

**Observed.** The supplied marble thrown with the same launch, its damping replaced by zero, rose to 1.887, 1.642, 1.838 and 1.924 m at 60, 10, 30 and 240 ticks a second. As shipped: 1.814, 1.561, 1.763 and 1.852 m.
**Concluded.** The engine steps a rigid body the way our two lines do, in the same order. I infer this from four equal heights; I did not read the engine's source.
**Another cause, found.** The project setting `default_linear_damp` is 0.1. It lowers the highest place by 7.3 cm at 60 ticks.

### T8. A body (parent T0, status: consolidate)

**Observed.** The Walker's autopilot stopped 4.84 m from the launch when sent to the formula's point, 4.898 m: it stops within 0.1 m of where it is sent. Hit there at 0.69, 0.60, 0.42 and 0.10 m above the feet at 1/240, 1/60, 1/30 and 1/10 s. Not hit at 1/4 s, which lands 4.0 m from the launch. Moved there: hit, 0.10 m.
**Observed.** Standing 3.57 m from the launch: hit at 1/60 s (1.70 m up) and at 1/10 s (1.37 m up), not hit at 1/4 s.
**Observed.** Through the five flights at the formula's point the Walker's position did not change by a millimetre.
**Concluded.** A coarse step moves the place of the hit, and at 1/4 s it removes the hit.

## What was observed, what was concluded, what is guessed

- **Observed.** Steps, landings, heights and corners of every flight. The share of pixels on which each pair of stills differs, and what each still covers. The orbit's nearest and farthest distance, its turns, and when it reached the floor. The marble's highest place at four tick rates. Where the Walker stood and how high it was hit.
- **Concluded.** The stepped path is under the true one by an amount proportional to the step. The pixel count is a poor ruler for dots. The swap is silent and changes the throw; it does not open an orbit. Explicit Euler does. The engine's rigid body is stepped like ours.
- **Guessed.** That a person would call 1/60 and 1/240 the most alike. That a faster screen gives another flight by the frame. Neither was tested.

## Unresolved

- **No eye was asked.**
- **1/10 and 1/30 on one spot.** I explained it by the step that ends at 1.2 s and did not try a second launch to see how often two steps share a landing.
- **Energy.** Not computed.
- **The average of the two velocities.** The lesson offers it under Decide. I did not run it.
- **At 1/10 s the orbit wobbles between 0.920 and 1.120 m** and does not leak in 60 s. Why the band has that width, I did not work out.

## The decisions, in one place

| at | decision | reason |
|---|---|---|
| T1 | follow | the count said the opposite of the sheet's first impression |
| T2 | settle | the ink explains the count; three rulers are shown, and the outline wins one |
| T4 | follow | the planned fault did not do what the lesson needed it to do |
| T5 | settle | the fault that opens the orbit is found, and it says why the swap did not |
| T6 | leave open | one screen, one refresh rate |

**The decision of this note: follow twice, then settle.** Both follows began where a prediction failed: the pixel count against the outline, and the swap against the orbit. Each ended in a plain cause. I settle on the two lines in the order velocity, then place, at 60 steps a second, because at that step the path is 9.8 cm at most from the formula's, the dots still show that it is made of steps, and it is the engine's own step.

## Replay

Run on 1 October 2026, from this folder, with Godot 4.6.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --path . --xr-mode off --script res://sheet.gd
```

The first runs 53 checks, among them every number of T0, T3, T4, T5, T7 and T8, and exits 0. The second needs a window: it photographs the flights, writes `sheet.json`, `sheet.png`, `orbit.png` and `process.png`, and prints every number of T1, T2 and T6. The five flights of T6 come out differently in every run.

## Evidence

- `verification.json`: the checks, and under `measured` the flights, the swapped flights, the orbits, the marble, the Walker.
- `sheet.json`: every pair, what each still covers, the five flights by the frame, the strip.
- `sheet.png`, `orbit.png`, `process.png`. `stills/` is not tracked; `sheet.gd` makes it again.
- `room_trial.json`: the room's own test of the guest.
