# Chance becomes a place

24 September 2026 · Encounter proposal, not a deployed museum change.

The same die can make a number, a height, a movement, or permission to continue. This is the strongest thread to carry from the video into Ada: chance acquires consequences through a rule and a body. I read the video's English automatic captions, including the passage around 9:10, and checked the current Randomness maps and relevant source. The proposals below build on the recent encounter return; they do not replace it.

## What the video contributes

[The Game Overanalyser, *Uncertainty in Games*](https://www.youtube.com/watch?v=Srgva9gEJDw): 8:18–8:42 distinguishes randomness before and after a decision; 8:43–9:05 discusses temporal correlation; 9:05–9:36 introduces dice combinations and exceptional outcomes. After 10:14, uncertainty broadens to performance, problem solving, other players and information. Those are useful distinctions, not interchangeable random-number generators. Automatic captions are imperfect; the paper trail below links the cited primary talk.

[Geoff Engelstein's GDC slides](https://media.gdcvault.com/gdc2018/presentations/Engelstein_Geoffrey_White_Brown_Pink.pdf), slides 8–9, 15–19 and 26–27, give the decision diagrams, correlation comparison and dice mechanisms. We can borrow the distinctions while making our own spatial experiments.

## Six encounters to develop within the existing order

### 1. Two dice, one piece of architecture — Random_Cubes → Random_Gaussian

**Existing:** the grabbable die and coin in Random_Cubes read settled physical orientation. Random_Gaussian already has a Galton board, sampler and distribution comparator.

**Add:** a paired-dice extension beside the current die. Two shallow trays retain the separate outcomes. Their sum builds a short column from unit blocks; a wall of retained results slowly records which heights returned. Leave the two source values visible. Compare one die with the sum of two before opening the Gaussian cabinet. This supplies a bodily object behind the later distribution.

**Discover:** seven can be assembled in six ordered ways; two in only one. A middle can become common through combination, without anyone aiming for it. Two dice produce a discrete triangular distribution, not a Gaussian. Fair independent faces are the comparison model; hand-thrown simulated dice must earn that approximation through observation.

**First build:** this extension. Preserve the original die's current behaviour in other placements. Publish raw throws separately from the model; count a pair only when both dice have settled after release. A cockpit full of probability settings is unnecessary: throw, watch the column, compare its two ingredients.

### 2. The bag remembers — Random_Remove

**Existing:** remove_random samples from active_instances and removes the selected entry. It already implements drawing without replacement.

**Extend:** two transparent hoppers contain matching numbered blocks. In one, the drawn block returns before the next draw. In the other, each draw leaves an empty slot. Keep the finished rows beside both machines. Let the visitor pull the release rather than select a distribution from a menu.

**Discover:** another copy can arrive from one machine; the other can run out. Chance can retain a promise through the changing eligible set. This develops the existing removal encounter instead of replacing its floor.

### 3. A place that remembers its last place — Random_Walk

**Existing:** the terrarium accumulates sampled steps, reflects them at its glass boundary, and retains a finite trail.

**Add a comparison:** two large carriages travel across equal rails at the same cadence. The first selects an absolute target afresh; the second adds a small left/right displacement to its current position. A pointer the visitor moves beside the rails lets them anticipate the next landing. Use identical travel easing and display targets so the motor's smoothing cannot masquerade as correlation. Keep the visitor on stationary ground.

**Discover:** an unpredictable increment can still leave the next position near the last. The position remembers, even when the next increment does not consult the trail. Mark rail reflection as an added rule; this finite mechanism is a bounded walk, not unrestricted Brownian motion.

### 4. The six that asks for another throw — Random_Cubes, with a return in Random_Game

**Add after the ordinary die comparison:** a second output chute whose rule is explicit: add each die value; a six permits another throw in the same chain. Every throw leaves one labelled block. A rare chain raises a much taller temporary column. The visitor can walk around the same rule after it has produced a surprisingly different structure.

**Discover:** the exceptional height was possible within the rule all along. The six does not itself explode; an instruction grants continuation. The current reward rain is proportional to one face and is not this mechanism. This is our additive variant of exploding dice, not a claim to reproduce a particular commercial game's scoring.

**Boundary:** display the retained chain. If geometry or throw count has a cap, show that limit and label an unfinished chain rather than silently treating it as complete. Keep a separate labelled recorded example for rare cases; never secretly force a lucky result. An exploding die is not, by itself, evidence of pink noise or a power-law tail.

### 5. Before you choose / after you choose / already chosen — Random_Game

**Existing:** random_doors selects safe_door in replay(), before choose() opens anything. It is a hidden assignment. The stepping stones already compare a scheduled event with the warning available to the visitor.

**Extend the doors into three small matched trials:** one reveals its drawn passage before your choice; one makes the draw only after you choose; one keeps the current preselected passage hidden until you choose. Use a short route versus a longer return route for this comparison, so the first question concerns planning rather than punishment. An exposed mechanical flag records when the draw occurred. Keep each round's result until the next round.

**Discover:** learning something late and having it decided late can feel alike. In the hidden and post-choice versions, matching probabilities can even make the visible results statistically indistinguishable. We need the exposed mechanism to investigate the difference. Revealing before choice gives the visitor knowledge they can use; it need not demonstrate a universal claim about skill.

**Check:** no reroll on repeated presses; draw and reveal recorded as different events; seed replay repeats machine choices without pretending to rewind the visitor.

### 6. Related weather — Random_Space_Geometry → Noise

**Existing:** perlin_noise_bridge compares independent heights with a coherent field. The later Noise sequence is already responsible for sustained spatial correlation.

**Develop there:** three banks of large shutters frame openings at different heights. Their targets follow independent draws, accumulated increments, or an explicit approximate pink-noise process. Stand among them, look along their history, and try to anticipate the next opening. Hold clock and visible travel law constant. Shared rendering bounds must be reported separately from the raw signal.

**Discover:** similar ranges of values can carry different histories. Reserve the name pink noise for a process checked for approximately 1/f power over a stated frequency range. [Julius O. Smith's signal-processing treatment](https://www.dsprelated.com/freebooks/sasp/Example_Synthesis_1_F_Noise.html) gives an explicit approximation and its analysis. Frequent small changes with occasional large ones is a useful game-design description; it does not establish that spectrum. Dice sums describe value frequencies; noise colour describes relationships across time/frequency. Keep both available without merging them.

## A source problem to resolve before promotion

The existing trng_vs_prng scene labels one side as physical entropy. Its script's quantum_fluctuation() returns randf(); thermal_fluctuation() combines sine and cosine; atmospheric_fluctuation() combines sine and randf(). It is not measuring the named physical phenomena. Preserve it as a comparison of constructed sources, but relabel it before using it to teach a physical entropy source. The present die and coin genuinely use the physics engine to obtain outcomes; this does not make them measurements of quantum randomness either.

The Galton board has two distinct paths: live RigidBody beads with small sampled release jitter, and optional preseeded binomial evidence. Its current map token does not request preseeded evidence. A visible bell-shaped model is a hypothesis to compare with the live landings, not proof that every collision is an independent fair coin.

## Writing after an encounter exists

Draft direction for the paired-dice addition, not inserted into final.md:

> Two dice lie beside the column. One shows three, the other four. Seven blocks stand between you and the wall. Throw again. Five and two: the column comes back, though its ingredients have changed. How many different throws could bring you to the same height?
>
> The middle begins to fill. Nothing has been told to prefer it. There are simply more ways to arrive.

Keep that last sentence conditional on the fair independent-dice model when the chapter explains the mechanism. Let physical results disagree with the model where they do. The critical question follows the object: which outcomes did the rule admit, which did the record merge, and what did that make possible for a body?

## Decision

Keep the fourteen-hall order. Start with the paired-dice extension, carry its result into the existing Gaussian/Galton comparison, and then develop the door trial. The hopper and carriage comparisons are subsequent candidates. Reserve the full noise-colour study for the transition into Noise. No canonical prose, map placements, artifacts, live museum bake or current review pass have been changed by this research note.
