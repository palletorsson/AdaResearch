# The tutorial lineage against The Nature of Code

29 September 2026. A read-only comparison of `doc/book/tutorial-lineage/curriculum.json` (another session's uncommitted work, not edited) with the twelve chapters of Daniel Shiffman's The Nature of Code, https://natureofcode.com, Creative Commons. Four agents read three chapters each and mapped them onto the graph; one drafted a synthesis; three others tried to refute it, one per lens: the book's facts against the site, the lineage's facts against the data file, and the inferences. Raw output: `evidence.json`.

Of 159 checks on the draft, 87 were confirmed, 52 overstated, 11 refuted and 9 unverifiable. Every graph figure reproduced. The draft's headline did not. What follows is only what survived.

## The rate node

The book does name accumulation. Chapter 1 says acceleration values accumulate in velocity; Chapter 2 has a Force Accumulation section that sums forces and clears acceleration each frame; Chapter 6 has an interlude that names Euler integration. The update appears in code in Chapters 1 to 6 and 9. The book sets no exercise on the time step.

The lineage's `rate` node plans one: transfer "Change the sampling interval". It is proposed and untested. In node text only `rate` uses the word accumulation, `motion` says "identify the time step", and only `descent.transfer` varies a step size. Hall texts (VFM_03_Motion, Flow_Field, Change_Choreography) name accumulation more often, so node text under-describes the halls. Summing forces and clearing them has no home in node text; the halls searched did not show one either, so it is unsettled.

## Lessons that held, with the confidence the checkers left them

1. **The vector to field edge looks like a route artefact (medium).** `vector.requires` lists `field`, `vector.learn` never uses a field, and `field.learn` already says "vector-valued". The book teaches vectors first. All 167 edges point to the same or an earlier sequence, so reversing this one would create the first forward edge. Reword `field` or drop the edge.
2. **`random` and `noise` carry requirements their own text never uses (medium).** `random` requires array, transform and loop across seven halls; `noise` requires `wave` with no wave in its text. The book's Chapter 0 gets a walker and a noise offset going without them, though its surrounding text uses an array. That the edges are the union of what each hall needs is an inference.
3. **The schema has no field for what the student carries (medium).** The agreement states the carried-work principle but only tabulates it for the primitives chain. Of its five per-passage questions, only Q2, Q3 and Q4 have fields; Q1 and Q5 survive only as `requires`. One object can span the graph: `point` is an ancestor of 64 of 68 nodes, `mesh` of 57. A moving body cannot: `random`, `cell`, `recursion` and `grammar` have no `rate` ancestor. The book carries the Mover through Chapter 5 as a template, and the Ecosystem Project prompt appears in at least nine of twelve chapters.
4. **`borrow` has no `assumes` beside it (medium).** The agreement says a supplied component's assumptions must be explained. Chapter 6 states most engine defaults where they are used: gravity down, air friction, pixel units, convex clockwise polygons, the engine owning position. It names its integrator rather than hiding it.
5. **The who-chooses question is the lineage's own, within limits (medium).** The book treats the distribution and the fitness function as the designer's decision and enacts human-supplied fitness; Chapter 10 discusses labels at length. It never asks whose interests a choice serves, and Chapters 10 and 11 never ask who supplies the labels or the reward. The lineage asks it in 25 sequence questions. This is not like for like: the lineage includes foundations and critical sequences a creative-coding book has no counterpart for.
6. **The criterion swap sits on a leaf (low to medium).** Only `search_cost.transfer` changes the criterion, and `search_cost` is required by nothing, while `descent` has six children. Six of the ten leaves are compare nodes, which are defined as varying an operation, so the placement follows the kind scheme.

## What fell

- "The book never names accumulation" and "the lineage names it once": both refuted.
- "One carried object cannot span the graph": refuted.
- Exercise 9.8 swaps the criterion: it rescales one fitness score.
- The reader builds the Turtle in Chapter 8: it is supplied, as in `grammar.borrow`.
- Chapter 6 hides Euler: it names it.
- The lineage lacks polar-to-Cartesian, rule numbering or a perceptron update: WaveFunctions_Unit_Circle, CA_Introduction and ML_Perception carry them.
- "Ten recorded bridges": four of the ten issues are bridges; three record current tutorials falling short of the agreement.
- The book meets array removal by accident: Chapter 4 teaches it deliberately, with two fixes.

## Discounts to apply

- Order contrasts partly compare the museum corridor with the book's chapter order; the README says encounter order comes from the spine, so `requires` edges are prerequisites given that route.
- The lineage's transfers on all 68 nodes are plans, untested, set against a shipped book's exercises.
- Book-side readings came through a summarising fetch tool; exact wording is unverified. Three chapter pages were truncated before their ends.
- Forty per cent of the 167 edges (67) are implied by another prerequisite of the same node; the README says further requirements stay visible as cross-connections, so this is not necessarily a fault.
- The data file holds 68 nodes, two of them preparation nodes with no halls; the page and DECISIONS.md say 67.

Nothing in the lineage was changed. Its owner decides which of these become edits.

## Added on a second reading: the book's time step does not survive a headset

The book's model is one frame, one time step. Its pendulum (Example 3.11) multiplies the angular velocity by 0.99 once per frame, calls it a damping trick and arbitrary, and the chapter never mentions frame rate (fetched 2026-09-29). Euler integration is named only in the Chapter 6 interlude, and no exercise varies the step.

In Ada the step is not fixed. XR Tools' `start_xr.gd` sets `Engine.physics_ticks_per_second` to the headset's refresh rate (times `physics_rate_multiplier`, default 1), so a per-tick rule runs 60 times a second on the desktop and 90 on a Quest at 90 Hz. `control_pendulum` shipped the same per-tick idiom (0.995), and `probe_wave_tick_rate.gd` measured it on 25 September:

| physics rate | velocity kept per second | amplitude kept over 6 s |
|---|---|---|
| 60 Hz | 0.740 | 0.451 |
| 90 Hz | 0.637 | 0.294 |

The lineage's `rate` node already plans the right experiment (transfer: change the sampling interval), but only as a plot study in Change_Intro, and `motion` says "identify the time step" without varying it. The lesson: move the interval experiment onto the moving body at `motion`, run the same swing at 60 and 90 ticks, then rewrite the damping per second. The book's platform hides this; a headset makes it unavoidable. It also bears on `borrow`: the physics rate is set silently by a supplied component, which is the case for an `assumes` line.
