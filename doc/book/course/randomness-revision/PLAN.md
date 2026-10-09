# Randomness — revision plan

9 October 2026. Editable working plan. Existing Endless Museum; fourteen halls in the current spine. These paragraphs are teaching decisions to test, not claims that the examples already work.

## Agreement

Inspect the installed hall and its primary artifact. Read the current tutorial and reflection. Name what the student brings, one main new operation, what they can build, and a variation that would demonstrate understanding. Write the complete smallest program that performs that operation in the prepared museum. Extract its printed listings into fresh files and run Godot assertions; test a changed version and reject a relevant deliberate fault. Compare the reconstruction with the actual hall and capture it. Report separately what ran, what was visually inspected and what still needs a headset or unfamiliar reader.

The museum supplies the player, floor, camera, light and installed XR Tools. The tutorial declares every other dependency. No dollar references to prepared mesh children; create lesson objects and retain references. Reuse known cube and PointBody constructions where their role fits. A new random mechanism does not require inventing a new protagonist in every room. Complete code remains visible; short prose identifies which function to read first.

`tutorial.md` teaches construction and investigation. `final.md` follows the encounter and its implications, with little code. The two texts need not cover the same artifacts. Keep strong existing passages. Change claims when source or observation contradicts them. Do not rewrite the museum merely to make the manuscript easier to test.

## What arrives from earlier sequences

Points and local coordinates; a carried PointBody; lines and retained traces; arrays, loops and indices; whole-object transformation; materials and colour; conditions and named actions; physical state and timestep; functions, parameters and independent instances. Wavefunctions adds measured history, old/next state, phase, recorded events, independent clocks and weighted contributions. Cage has already used a bounded random choice. Here the generator, selection rule and interpretation become explicit subjects.

## Hall contracts

### 01 · Random_Definition — a seed needs a procedure

**Primary:** seed_replay_demo. **Bring:** the cube, array construction, per-object material and Cage's choose/replay distinction. Reconstruct two small colour grids; reset a local generator before each and then discard one draw only on the right. Teach seed, generator state, draw order and assignment. Predict the first shifted RGB triple and reproduce it. Keep a colour record for later counting, while distinguishing that record from a seed recipe. The reflection can ask what the number naming a picture leaves out. **Status:** revised and tested; see `STATUS.json` and the first-hall report. Remaining hall contracts are still provisional.

### 02 · Random_Entropy — a count loses the neighbours

**Primary:** shannon_entropy_meter. **Bring:** retained values, arrays and loops. Use a small categorical palette with explicit integer symbol IDs; count the same stored list before and after sorting a copy. Introduce relative frequency and the supplied entropy calculation only after the unchanged counts are visible. Show that a different order can have the same marginal entropy. Do not quietly bin arbitrary RGB triples or call this thermodynamic entropy. Carry the original order and counts separately. **Status:** source walkthrough; complete reconstruction needed.

### 03 · Random_Remove — choose from an eligible set

**Primary:** remove_random. **Bring:** array addresses, conditions and local coordinates. Filter a small cube grid, draw an offset into the remaining candidate list, remove that member and retain its original address. Predict what can never be selected and empty the eligible set without an invalid draw. Replay must restore both candidates and generator. Contrast hiding a small cube with withdrawing floor collision in the installed arena. **Status:** source walkthrough; complete reconstruction needed.

### 04 · Randomness_10_PRINT_Algorithm — two marks, many contours

**Primary:** ten_print. **Bring:** line endpoints, grid addresses and binary conditions. Assign one of two diagonals at each cell using one local draw. Change probability while preserving the grid and measure the actual finite counts. Rebuild from a seed. A diagonal pattern is not automatically a navigable maze: connectivity and a path solver would be separate additions. Carry a reproducible arrangement of marks. **Status:** incomplete legacy sketch; replace missing prefab/helpers and unsupported maze claims.

### 05 · Random_Cubes — a throw becomes a record

**Primary:** continuing_die, compared with dice_throw and paired_dice_column. **Bring:** cube, counters and retained outcomes. Start with a six-valued code draw, append every result, and let six mean continue while another face ends a run. Teach an event record and a stopping condition; distinguish a sampled outcome from a physically simulated die. Predict a supplied run, then change the continue rule without changing the available faces. Record the rule with the outcomes. **Status:** current bevel tutorial has the wrong focus; rewrite after checking the installed dice.

### 06 · Random_Rotate_Random_XYZ — assignment or accumulation

**Primary:** Random_Rotate_Random_XYZ. **Bring:** whole-cube rotation and the previous record. Compare setting an orientation with adding bounded increments at a fixed step; replay the same increment list. Change one axis while keeping other decisions fixed. Independent Euler angles do not promise uniform spatial orientations. A mixed clock value is not demonstrated hardware entropy. Carry a state updated by repeated draws. **Status:** incomplete legacy sketch and misleading entropy language.

### 07 · Random_Walk — let the point keep its steps

**Primary:** random_walk_terrarium. **Bring:** PointBody, displacement and Trace's positions list. Return to one point: add a sampled step and retain the accepted position. Begin in a plane; distinguish a newly assigned position from accumulated displacement. Declare timestep and boundary policy. Change step length while leaving the direction rule alone; the trail observes the walk without guiding it. The terrarium's five walkers and bounded long steps remain comparisons. **Status:** accurate source walkthrough; compact learner program needed.

### 08 · Random_Gaussian — change the law, keep the sample

**Primary:** distribution_sampler. **Bring:** the walk's step values and the entropy hall's counts. Compare uniform and Gaussian samples, retain the values, then rebin without drawing again. Teach distribution, clipping and counting as separate operations. Keep the first required contrast to two laws; Poisson and exponential remain named extensions. Predict which actions spend draws and test that rebinning preserves RNG state. **Status:** source walkthrough; control the density of the reconstruction.

### 09 · Random_Mushrooms — a draw within a repertoire

**Primary:** mushrooms. **Bring:** primitive constructors, scale and bounded sampling. Sample template ID, position and size as separate choices; keep the resulting specimen record. A small student population can reuse known primitive forms instead of rebuilding every mushroom. Change size while retaining template choices, then add a genuinely different construction. A larger parameter range is not a new kind of body. Carry records that can regenerate a population. **Status:** preserve source precision; fix old tutorial handoff that skips ahead to Game.

### 10 · Random_Space_Geometry — neighbours share a rule

**Primary:** inspect random_transformations_geometric and its current comparison before choosing the learner carrier. **Bring:** sampled grid heights and Wavefunctions' spatial functions. Compare independently sampled heights with nearby samples of a declared continuous field. Keep the grid fixed; compare neighbouring differences and distinguish spatial correlation from a histogram. Introduce only the field interface needed here; reserve noise internals for Noise. **Status:** existing ceiling sketch does not yet teach the proposed comparison; verify artifact fit first.

### 11 · Randomness_Examples_of_Randomness — a draw estimates

**Primary:** monte_carlo_dartboard. **Bring:** points, conditions, retained samples and ratios. Place points in a square, test membership in the circle and retain hit/total counts. Plot a running area estimate; change sample count and inspect fluctuation without promising monotonic improvement. Reuse point markers and keep the other artistic applications as gallery comparisons. Carry the distinction between one run and the quantity being estimated. **Status:** source survey; nominate this one reconstruction and repair the next-hall handoff.

### 12 · Random_Pheromone — the trace enters the next choice

**Primary:** pheromone_terrain. **Bring:** the walker, grid addresses and retained traces. A small scalar grid now feeds back into weighted local choices; deposit and decay change its state. Declare boundary handling and tie policy. Compare follow and avoid at equal step counts. Neither behaviour proves an optimal route. Do not label mean field intensity as entropy. Carry a feedback mechanism, with visible history and sensed field distinguished. **Status:** substantial new mechanism; incomplete sketch needs replacement.

### 13 · Random_Space — combine fields at different scales

**Primary:** noise_mixer. **Bring:** Synthesis's weighted sum and the spatial comparison. Add a finite list of declared spatial contributions; store offsets and inspect each contribution before the sum. Change layer count without resampling earlier layers. With one layer, spacing between layers has no effect. Keep raw values available beside any display normalization; a terrain palette is not erosion. This is a return to composition preparing Noise. **Status:** current scatter sketch misses the mixer; rewrite around the actual operation.

### 14 · Random_Game — a decision and its disclosure

**Primary:** one cycling stone from r_c. **Bring:** cube, states, timers, collision and local generator. Draw a wait once, retain its deadline and reveal or hide a cue without redrawing. Make replay cancel the previous schedule and restore support. Begin with one stone and a safe museum floor; the larger crossing remains the encounter. Test that cue changes do not change the event and that stopping a source does not erase released bodies. **Status:** source walkthrough; define the smallest complete state machine.

## Order and pressure points

Keep the current order provisionally. It moves from repeatability, counts and eligibility to marks, events, accumulated motion, distributions, populations, spatial relations, estimation, feedback, composition and timed consequence. This is a teaching route through distinct uses of chance, not a single ever-growing script. Where data actually travels, state the format and ownership; where a construction returns, say so without inventing save/load continuity.

Entropy is early: keep counting primary and introduce the formula as a named calculation whose limits the student can inspect. Rotation before Walk gives a useful assignment/accumulation contrast. Space Geometry and Space anticipate Noise through already-known grids and sums; avoid importing the entire noise course. Pheromone is the largest new state mechanism. Inspect its smallest useful version before deciding whether an additional bridge is needed. The two biome interludes stay museum encounters, not extra compulsory tutorials.

## Delivery and evidence

One completed hall at a time. Each delivery contains: before snapshot; revised canonical tutorial and reflection where needed; exact printed code extraction; native Godot assertions; an independently chosen parameter variation; a conceptual mutation test; a current museum capture; a short change report. A passing checker is evidence about that construction, not proof of comprehension. Preserve failed attempts when they expose a text, code or checker error.

After all fourteen, read both tracks in order, reconstruct the full packet as an author-informed ghost student, check the Noise handoff, and export separate tutorial/reflection files plus a review ZIP. A new reader and a headset visit remain distinct evidence. Do not call an old capture a new test.

Edit this file to change teaching choices. `STATUS.json` beside it tracks completed evidence; iteration reports show each reviewed result. No spine reorder or production artifact change is implied by this plan.
