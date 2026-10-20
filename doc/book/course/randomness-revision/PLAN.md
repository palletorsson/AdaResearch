# Randomness — revision plan

9 October 2026. Editable working plan. Existing Endless Museum; fourteen teaching halls in the current spine. All fourteen have revised readings and executable examples; the evidence and remaining limits are recorded in STATUS.json. The editorial pass below prepares the chapter for external review.

## Current review packet

[Tightened readings and change report](../../iterations/2026-10-09-randomness-review-ready/index.html) · [Complete review ZIP](../../iterations/2026-10-09-randomness-review-ready/randomness-review.zip).

Entropy now begins with counts and known inputs, with its calculation explained in a second reading. Pheromone follows one update before batching. Later openings name the change of purpose. Repeated inherited code remains complete in expandable sections; the complete-code reading is available for printing. Longer reflections retain their exact qualifications in notes. No teaching hall was reordered and no artifact algorithm changed. Fresh extraction of all fourteen current baseline programs passed 420 native Godot assertions. Prior variations and fault tests remain dated hall evidence; this pass does not establish independent student comprehension or headset traversal.

## Agreement

Inspect the installed hall and its primary artifact. Read the current tutorial and reflection. Name what the student brings, one main new operation, what they can build, and a variation that would demonstrate understanding. Write the complete smallest program that performs that operation in the prepared museum. Extract its printed listings into fresh files and run Godot assertions; test a changed version and reject a relevant deliberate fault. Compare the reconstruction with the actual hall and capture it. Report separately what ran, what was visually inspected and what still needs a headset or unfamiliar reader.

The museum supplies the player, floor, camera, light and installed XR Tools. The tutorial declares every other dependency. No dollar references to prepared mesh children; create lesson objects and retain references. Reuse known cube and PointBody constructions where their role fits. A new random mechanism does not require inventing a new protagonist in every room. Complete code remains visible; short prose identifies which function to read first.

`tutorial.md` teaches construction and investigation. `final.md` follows the encounter and its implications, with little code. The two texts need not cover the same artifacts. Keep strong existing passages. Change claims when source or observation contradicts them. Do not rewrite the museum merely to make the manuscript easier to test.

## What arrives from earlier sequences

Points and local coordinates; a carried PointBody; lines and retained traces; arrays, loops and indices; whole-object transformation; materials and colour; conditions and named actions; physical state and timestep; functions, parameters and independent instances. Wavefunctions adds measured history, old/next state, phase, recorded events, independent clocks and weighted contributions. Cage has already used a bounded random choice. Here the generator, selection rule and interpretation become explicit subjects.

## Hall contracts

### 01 · Random_Definition — a seed needs a procedure

**Primary:** seed_replay_demo. **Bring:** the cube, array construction, per-object material and Cage's choose/replay distinction. Reconstruct two colour grids, initially 8 × 8 with a supplied 2–16 resolution slider; reset a local generator before each and then discard one draw only on the right. Teach seed, generator state, draw order and assignment. Predict the first shifted RGB triple and reproduce it. Keep a colour record for later counting, while distinguishing that record from a seed recipe. The reflection can ask what the number naming a picture leaves out. **Status:** revised and tested; see `STATUS.json` and the first-hall report. All fourteen contracts are revised; external review remains pending.

### 02 · Random_Entropy — a count loses the neighbours

**Primary:** shannon_entropy_meter. **Bring:** retained values, arrays and loops. Use a small categorical palette with explicit integer symbol IDs; count the same stored list before and after sorting a copy. Introduce relative frequency and the supplied entropy calculation only after the unchanged counts are visible. Show that a different order can have the same marginal entropy. Do not quietly bin arbitrary RGB triples or call this thermodynamic entropy. Carry the original order and counts separately. **Status:** revised and tested; 31 checks for each of three programs, three faults rejected, 26 museum checks. See `STATUS.json` and the second-hall report.

### 03 · Random_Remove — choose from an eligible set

**Primary:** remove_random. **Bring:** array addresses, conditions and local coordinates. Filter a small cube grid, draw an offset into the remaining candidate list, remove that member and retain its original address. Predict what can never be selected and empty the eligible set without an invalid draw. Replay must restore both candidates and generator. Contrast hiding a small cube with withdrawing floor collision in the installed arena. **Status:** revised and tested; five programs with 30 checks each, three faults rejected, 34 museum checks. See `STATUS.json` and the third-hall report.

### 04 · Randomness_10_PRINT_Algorithm — two marks, many contours

**Primary:** ten_print. **Bring:** line endpoints, grid addresses and binary conditions. Assign one of two diagonals at each cell using one local draw. Change probability while preserving the grid and measure the actual finite counts. Rebuild from a seed. A diagonal pattern is not automatically a navigable maze: connectivity and a path solver would be separate additions. Carry a reproducible arrangement of marks. **Status:** revised and tested; three programs with 25 checks each, three faults rejected, 36 museum checks. See `STATUS.json` and the fourth-hall report.

### 05 · Random_Cubes — a throw becomes a record

**Primary:** continuing_die, compared with dice_throw and paired_dice_column. **Bring:** cube, counters and retained outcomes. Start with a six-valued code draw, append every result, and let six mean continue while another face ends a run. Teach an event record and a stopping condition; distinguish a sampled outcome from a physically simulated die. Predict a supplied run, then change the continue rule without changing the available faces. Record the rule with the outcomes. **Status:** revised and tested; three programs with 32 checks each, four faults rejected, 32 museum checks. See `STATUS.json` and the fifth-hall report.

### 06 · Random_Rotate_Random_XYZ — assignment or accumulation

**Primary:** random_decay_multimesh#study:rotation, isolated in a two-cube learner comparison. The namesake floor rotator has no GridMultiMesh target in the current museum. **Bring:** whole-cube rotation and the previous record. Compare setting an orientation with adding bounded increments at a fixed step; replay the same increment list. Change one axis while keeping other decisions fixed. Independent Euler angles do not promise uniform spatial orientations. A mixed clock value is not demonstrated hardware entropy. Carry a state updated by repeated draws. **Status:** revised and tested; four programs with 29 checks each, four faults rejected, 26 museum checks. See `STATUS.json` and the sixth-hall report.

### 07 · Random_Walk — let the point keep its steps

**Primary:** random_walk_terrarium. **Bring:** PointBody, displacement and Trace's positions list. Return to one point: add a sampled step and retain the accepted position. Begin in a plane; distinguish a newly assigned position from accumulated displacement. Declare timestep and boundary policy. Change step length while leaving the direction rule alone; the trail observes the walk without guiding it. The terrarium's five walkers and bounded long steps remain comparisons. **Status:** revised and tested; four programs with 30 checks each, four faults rejected, 32 museum checks. See `STATUS.json` and the seventh-hall report.

### 08 · Random_Gaussian — change the law, keep the sample

**Primary:** distribution_sampler. **Bring:** the walk's step values and the entropy hall's counts. Compare uniform and Gaussian samples, retain the values, then rebin without drawing again. Teach distribution, clipping and counting as separate operations. Keep the first required contrast to two laws; Poisson and exponential remain named extensions. Predict which actions spend draws and test that rebinning preserves RNG state. **Status:** revised and tested; four programs with 30 checks each, four faults rejected, 28 museum checks. Learner keeps raw samples; cabinet retains clamped values. See `STATUS.json` and the eighth-hall report.

### 09 · Random_Mushrooms — a draw within a repertoire

**Primary:** mushrooms. **Bring:** primitive constructors, scale, bounded sampling and retained values. Keep twelve fixed grid places, sample recipe ID, yaw and size, and store named fields in a dictionary per member. SIZE changes only scales; records and RNG stay. Reuse PointBody for REPLAY/SIZE/NEXT SEED. Two cylinder-and-sphere recipes carry the required comparison; add a third tall recipe, widen the scale range, and recover the six-member prefix. Distinguish retained-record intervention from the garden's seeded rebuild. Rings, clearings, garments and eating remain museum comparisons. **Status:** revised and tested; four printed programs with 32 checks each, four faults rejected, 32 museum checks. Next teaching hall: Random Space Geometry; native route also shows the existing Biome Cage interlude. See `STATUS.json` and the ninth-hall report.

### 10 · Random_Space_Geometry — what neighbours share

**Primary:** perlin_noise_bridge; surrounding kitbash remains a museum comparison. **Bring:** fixed cube grids, named population records, retained values and Wavefunctions' spatial functions. Reconstruct two 8 × 8 grids: uniform draws and one FastNoiseLite Perlin layer at matched addresses. Frequency changes only field values; physical spacing changes neither record. Reuse PointBody for replay/frequency/next seed. Mean absolute neighbour gap counts 112 edges without wrapping; checkerboard and split fixtures return to Entropy's unchanged counts/different arrangement. Same value bounds do not imply identical distributions. Field query order differs from RNG draw order; noise internals and layers remain for Noise. **Status:** revised; four printed programs pass 27 checks each, four faults rejected,29 native museum checks. Initial views were obstructed; accepted close images inspected. Existing bright lighting and overflowing backdrop remain spatial limits. See `STATUS.json` and the tenth-hall report.

### 11 · Randomness_Examples_of_Randomness — a draw estimates

**Primary:** monte_carlo_dartboard. **Bring:** PointBody, retained samples, counts, ratios and seeds. Reconstruct a bounded square/circle sampler with a retained estimate history, reusing the point for replay/one/batch actions. Batch size changes grouping, not the sample sequence. A central-strip edit keeps code executable while breaking the original area argument; distinguish finite-sample fluctuation from sampling bias. Other artworks remain reflective encounters. Installed console now offers budget/replay/seed comparisons; learner keeps every one of 256 samples. Carry sampling assumptions into Pheromone's history-dependent choices. **Status:** revised; four printed programs pass 21 checks each, four faults rejected, 28 native checks. Concurrent console changes and failed initial probes retained in the report.

### 12 · Random_Pheromone — a visit enters the next choice

**Primary:** pheromone_terrain. **Bring:** PointBody, walker, grid addresses and retained records. One walker deposits and reads scent on an 8 × 8 field. Compare current scent with accumulated visits; fade only the signal. A random branch selects the strongest/weakest neighbour, otherwise a random direction; this is not a scent-weighted lottery. Declare strict first-tie order and edge policy. Follow/avoid at equal steps; neither proves an optimal route. Keep source border, walker-count and sensor differences explicit. **Status:** revised; six complete programs pass 31 checks each, each agrees with reduced production methods for 100 steps per rule. Four faults rejected; 28 native checks. Two visually obstructed placements rejected; final view inspected. Carry feedback into a comparison with Random Space's history-independent field composition.

### 13 · Random_Space — fields add

**Primary:** noise_mixer. **Bring:** PointBody, Synthesis's weighted sum and Space Geometry's sample addresses. Preserve the actual five-sine base and eight seeded offsets; sum one to four weighted contributions. OCT chooses count, LAC multiplies frequencies, PER multiplies amplitudes. One layer ignores both ratios; returning settings recovers the same raw field without random draws. Show last contribution, fixed-scale sum and its independently stretched view. A quarter-sum edit reduces values while keeping stretched contrast; SIDE64 adds addresses, not layers. Other fields remain comparisons. **Status:** revised; six printed programs pass33checks each and match source sums at all addresses for1..4layers. Four faults rejected;27native checks, images inspected. Label layout corrected. Existing unsupported entrance/fallback remains an open room issue. Carry raw/view separation into Random Game's event and warning.

### 14 · Random_Game — a wait kept

**Primary:** one cycling stone from r_c. **Bring:** cube translation, states, clocks, collision, seeded draws and PointBody. Full schedule class plus self-built model inside existing museum. Draw standing/hidden waits once, retain deadlines; fixed movement phases keep support and appearance distinct. One clock avoids stale timers on replay. Pause/quarter-step inspect exact instants. Shorten notice from1.2s to0.3s without changing events; fixed3s standing consumes no draw, shifting later stream use. Explicit clock differs from production timers/tweens; no frame-identical synchronization or skipped-contact guarantee. **Status:** revised;33 assertions ×4 complete programs,200 source wait comparisons each,4 faults rejected;30 native checks, images inspected. First probe assumed old button parent, corrected to actual compact console without production edits. Whole fourteen-hall reading, Noise handoff and combined review packet are now complete; see the current review link above. Headset/unfamiliar learner remain separate.

## Order and pressure points

Keep the current order provisionally. It moves from repeatability, counts and eligibility to marks, events, accumulated motion, distributions, populations, spatial relations, estimation, feedback, composition and timed consequence. This is a teaching route through distinct uses of chance, not a single ever-growing script. Where data actually travels, state the format and ownership; where a construction returns, say so without inventing save/load continuity.

Entropy is early: keep counting primary and introduce the formula as a named calculation whose limits the student can inspect. Rotation before Walk gives a useful assignment/accumulation contrast. Space Geometry and Space anticipate Noise through already-known grids and sums; avoid importing the entire noise course. Pheromone is the largest new state mechanism. Inspect its smallest useful version before deciding whether an additional bridge is needed. Biome Cage remains a museum encounter after Mushrooms, not an extra compulsory tutorial. At Palle's request on 2026-10-09, the closing Biome Ladder is deferred: Random Game now leads directly to Noise Types. Its authored files and restoration data remain available.

[Whole-sequence reading and revised route](../../iterations/2026-10-09-randomness-without-the-ladder/index.html). Fourteen teaching halls; fifteen museum spaces including Biome Cage. No teaching hall has been removed or reordered.

## Delivery and evidence

One completed hall at a time. Each delivery contains: before snapshot; revised canonical tutorial and reflection where needed; exact printed code extraction; native Godot assertions; an independently chosen parameter variation; a conceptual mutation test; a current museum capture; a short change report. A passing checker is evidence about that construction, not proof of comprehension. Preserve failed attempts when they expose a text, code or checker error.

After all fourteen, read both tracks in order, reconstruct the full packet as an author-informed ghost student, check the Noise handoff, and export separate tutorial/reflection files plus a review ZIP. A new reader and a headset visit remain distinct evidence. Do not call an old capture a new test.

Edit this file to change teaching choices. `STATUS.json` beside it tracks completed evidence; iteration reports show each reviewed result. No spine reorder or production artifact change is implied by this plan.
