# Swarm Intelligence — 01 Review

Source-aware editorial and reader-experience review of the **Swarm Intelligence** sequence.

Basis: `swarmintelligence-book.md`, `swarmintelligence-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where the visitor can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. Recurrence is not treated as redundancy when collective-looking motion returns through a changed location of memory, field ownership, perception radius, objective, environmental channel, or population-level support.

The strongest current **book** arc is:

> **self-written environmental memory → externally supplied field → peer-relative steering → parameterised agent/environment model → two-channel stigmergy → objective-dependent collective memory → local ecology plus population-level caretaker**

A second formulation is:

> **Collective-looking order does not tell us where the organising information lives. It may be written into the environment, supplied as infrastructure, calculated from neighbours, retained as personal/shared memory, or imposed by a rule that watches the whole population.**

That is much stronger than the inherited sequence slogan:

> “No leader, yet coordinated. Local rules produce global intelligence.”

The current artifacts include precomputed route fields, shared global-best state, authored objectives, fixed anchors, and an ecosystem referee. The sequence is most interesting when it exposes those supports rather than classifying every coordinated picture as leaderless emergence.

---

# 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **Physarum Colony** | **Carries:** a strong opening because the colony’s field is both record and later input. The automatic triad → ring → pair → scattered anchorage carousel changes the fixed problem geometry every ~20 s **without clearing the existing grid or agents**, so a trace can genuinely outlast the arrangement that helped create it. Agent source supports three-direction sensing and trail deposition. **Gap:** the core `PhysarumGrid` implementation is missing from the bundle, so exact diffusion/decay cannot be source-verified here. Old identity claims shortest-path trees, Steiner networks and a “network smarter than any cell,” while the manuscript correctly refuses optimality. **Next:** preserve the book; include the grid source and clean the optimality/intelligence rhetoric. |
| **Flow Fields** | **Carries:** an important counterexample to Physarum. Here the population does not write its guidance field; route scenarios prepare it externally. Open/block/U-wall/zigzag use a cost-derived field; wind gives direction without destination; noise gives changing local direction without route-to-target. The manuscript correctly asks whether collective movement requires agents to watch one another. **Gap:** arrows are visible by default, so the room answers “where the coordination lives” before the visitor can misattribute the coordinated motion. The source already has `field_display = arrows/hidden`, but no physical toggle. `FlowGrid`, which owns cost propagation/vector construction, is also absent from the bundle. **Next:** begin hidden and add ARROWS reveal; include `FlowGrid`. |
| **Boids Algorithm** | **Carries:** a clean local-social comparison. A highlighted boid exposes weighted separation, alignment and cohesion vectors; RADIUS changes which agents enter those calculations; the whole population can remain flock-like while one local contribution changes. **Gap:** the primary `flocking_controls` artifact sits at `(10,9)` after five secondary boid works between z2–8, although the manuscript begins with the controlled instrument. Also, only positions wrap at the box boundary; neighbour distance uses ordinary Euclidean coordinates, so perception is not toroidal across the seam even though motion is. **Next:** verify/restage the controlled instrument earlier; expose the boundary seam in technical text rather than implying full periodic social neighbourhoods. |
| **Agent-Based Modeling ABM** | **Carries:** a useful move from “a trail looks stable” to manipulating rule/context. EVAPORATE changes how quickly shared trace disappears; ANTS creates a new population while leaving the shared field in place; MODE offers different behaviours in one ant-model family. The text is careful that an agent is a modelling unit, not automatically a person. **Gap:** RESET does **not** establish the controlled baseline the manuscript asks for: `_reset_colony()` clears the pheromone field but `_spawn_food_sources()` and `AntState` use unseeded global `randf()`, so food locations/qualities and ant headings change. Evaporation is also multiplied once per rendered frame (`1-rate`) rather than time-normalised with delta. **Next:** give the lesson a local seeded RNG and time-based decay so “change EVAPORATE, RESET, compare” is actually one-variable. |
| **Ant Colony Optimization** | **Carries:** this is a meaningful return, not a duplicate of the ABM ant hall. `AntColonyV2` uses **two environmental channels**: foraging ants seek food pheromone while depositing home pheromone; returning ants seek home while depositing food. Destination arrival flips internal state and refreshes trail energy. The ground therefore carries directional information without an explicit itinerary. **Gap:** the hall is fully declared/authored but absent from museum map-authored order. The underlying `PheromoneGrid` implementation is also missing, so exact source-emission/diffusion/decay cannot be audited. Old identity calls the result load-balancing/shortest-path intelligence; the manuscript correctly says no optimum has been demonstrated. **Next:** restore the hall and include `PheromoneGrid`. |
| **Particle Swarm Optimization** | **Carries:** one of the sequence’s best critical ideas: the same particle family can gather, disperse or pursue unfamiliarity because the objective changed; INERTIA then changes how much prior motion persists. The manuscript correctly makes “best” relational rather than intrinsic. **Gap:** the NOVELTY mode is currently algorithmically broken. On switch, the archive is cleared, so `_evaluate_fitness()` returns **10.0 everywhere** and those values are stored as every personal best/global best. Once archive entries appear, all possible distances in the 3 m arena are < 10, so no personal/global best can ever improve; the PSO’s social/cognitive memory freezes at switch-time positions. **Next:** repair novelty initialisation/update before using its movement as evidence for novelty search. |
| **Swarm Intelligence Algorithms / ecosystem capstone** | **Carries:** potentially the best ending because it breaks the inherited “no controller” thesis. Prey/predator reproduction, feeding and local behaviour operate alongside a global `balance_ecosystem()` referee that adds prey below 10, damages predators above a prey-ratio threshold, and can restock predators below 2. The manuscript rightly asks what actually caused a population recovery. **Gap:** the hall is absent from museum-authored order, and the referee remains invisible in the display: the only label shows population counts. Registry/QFEP copy still says “Predator and prey with no referee,” directly contradicted by source. **Next:** restore the capstone, mark caretaker interventions in real time, and ideally add CARE ON/OFF as a controlled comparison. |

---

# 2. The largest structural issue: the seven-hall book is currently a five-hall museum route

## Declared/current book order

1. Physarum Colony  
2. Flow Fields  
3. Boids Algorithm  
4. Agent-Based Modeling ABM  
5. **Ant Colony Optimization**  
6. Particle Swarm Optimization  
7. **Swarm Intelligence Algorithms / ecosystem capstone**

## Museum-authored order

1. Physarum Colony  
2. Flow Fields  
3. Boids Algorithm  
4. Agent-Based Modeling ABM  
5. Particle Swarm Optimization

The current museum route omits:

- **SwarmIntelligence_Ant_Colony_Optimization**
- **SwarmIntelligence_Swarm_Intelligence_Algorithms**

This is not just a shorter version of the same argument.

It removes two of the sequence’s strongest distinctions.

## Missing distinction 1 — one environmental trail versus two directional channels

The ABM hall’s compact `AntColonyOptimization` uses one pheromone grid. Returning ants lay strong trail; foraging ants sense that same trail.

The next hall’s `AntColonyV2` is different.

`SimpleAnt.gd` explicitly does:

**FORAGING**
- seek food channel `1`;
- deposit home channel `0`.

**RETURNING**
- seek home channel `0`;
- deposit food channel `1`.

Arrival changes state.

That is an important development of stigmergy:

> the same ground can carry different messages for travellers in different states.

Removing the hall collapses that distinction.

## Missing distinction 2 — local self-organisation versus whole-population maintenance

The capstone source contains:

```gdscript
func balance_ecosystem() -> void:
    if prey_list.size() < 10:
        spawn 5 prey

    if predator_list.size() > prey_list.size() * 0.5:
        weaken predators

    if predator_list.size() < 2 and prey_list.size() > 20:
        spawn predators
```

This is not a small implementation detail.

It changes the sequence’s thesis.

The model’s continuing population is made through:

- local movement;
- feeding;
- predation;
- reproduction;
- mutation;

**and**

- a global population-level caretaker.

That is exactly the kind of hidden support the current Ada method wants to expose.

## Manuscript transitions already assume the seven-hall route

ABM ends by explicitly preparing:

> home/food channels.

Ant Colony Optimization ends by explicitly preparing:

> personal/shared-best memory.

PSO explicitly prepares:

> quieter rules that keep an apparently self-organising system alive.

The ecosystem capstone then hands the book to Machine Learning.

The **book** is coherent.

The museum route is lagging.

## Recommendation

If the seven-hall curriculum is definitive:

1. restore Ant Colony Optimization between ABM and PSO;
2. restore ecosystem capstone after PSO;
3. verify `next_in_sequence` through the museum utility layer;
4. perform a complete seven-hall walk;
5. only then revise any transitions.

Do not cut the missing halls merely to match `map_authored`.

---

# 3. Sequence structure

## 1. Physarum — memory outside the agent

The sequence opens well because memory is materially locatable.

The source agents carry:

- position;
- heading/RNG state;

and sense:

- left;
- centre;
- right

in a shared grid.

They deposit back into that grid.

The colony-level source changes anchor arrangements every twenty seconds **without clearing the field**.

That makes old pathways genuine historical state available to a later configuration.

The chapter’s central question is therefore precise:

> can a medium remember something no current individual internally stores?

Yes, in this model.

## 2. Flow Fields — coordinated movement from supplied infrastructure

This is the correct immediate contrast.

Agents do not collaboratively construct the field.

The field is already there.

For route scenarios, a target/obstacle configuration is converted into local directional advice.

For wind/noise, the field can contain advice without a destination.

Thus:

> collective movement can look socially coordinated even when each agent is consulting a shared external infrastructure rather than another agent.

## 3. Boids — coordination moves into peer relations

Now the environment is no longer supplying a route field.

Each boid computes local contributions from neighbouring boids:

- separation;
- alignment;
- cohesion.

RADIUS changes **who counts as a neighbour**.

The same three formulas therefore operate on another social set.

That is the right third step.

## 4. ABM — internal state + shared environment + parameter intervention

The compact ant model broadens the unit:

- agent state;
- food encounter;
- environmental trail;
- mode;
- population count;
- evaporation.

This is less a generic definition of ABM than a manipulable example of one agent-based system.

That is enough.

## 5. Ant Colony Optimization — state determines which environmental message matters

The two-channel system introduces a richer relation:

> the same location can contain a home signal and a food signal, and the ant’s current state decides which one it seeks and which one it contributes.

This is a strong bridge from environmental memory to internal state.

## 6. Particle Swarm Optimization — memory becomes evaluated position

The environmental trace disappears.

Each particle carries:

- personal best position;
- personal best score.

The population also retains:

- global best position;
- global best score.

This makes memory explicit and non-spatial in a new way.

Then the chapter asks the key question:

> best according to what?

Excellent preparation for Machine Learning.

## 7. Ecosystem capstone — support can operate at another scale

The final model contains several scales of causation:

- individual steering;
- food/predator encounter;
- mating;
- crossover/mutation;
- population counts;
- global stabilisation.

This is the right conclusion because it resists the sequence’s easiest myth:

> if the picture looks self-organised, all important causation must be local.

The capstone says no.

Some care is global and explicit.

The problem is only that the artifact currently hides it.

---

# 4. Reader-experience lens

## Physarum Colony — Remembering in the ground

### Curiosity

The opening is strong because it asks the visitor to follow **one bright connection** through an environmental change.

The automatic anchorage carousel does useful work here.

The source sequence is:

> triad → ring → pair → scattered

at twenty seconds per arrangement.

Importantly, `_build_anchorage()` changes:

- emission centres;
- visual markers;

but does **not** reset:

- the grid;
- agents.

So a route can genuinely remain visible after the anchors that helped establish it have changed.

That gives the manuscript’s memory question operational force.

### Discovery

Following a **junction** rather than one agent is an excellent second observation.

Individual identity becomes difficult.

Environmental persistence remains readable.

The field therefore operates on a slower timescale than a particular agent movement.

### Timing

Good.

The term **environmental memory** arrives after the visitor has had a chance to notice persistent traces.

The manuscript also correctly resists optimality:

> bright/economical-looking route ≠ proven shortest/Steiner solution.

### Source gap

The missing `PhysarumGrid` owns:

- attractor influence;
- slime diffusion/decay;
- image state.

`PhysarumColony.gd` proves that those methods are called.

It does not show their equations.

The package therefore cannot fully source-verify:

> “field spreads and decays”

even though that is very likely the intended grid behaviour.

Include the global class.

### Source rhetoric

Old identity says:

> “shortest-path trees, Steiner networks, load-balanced branching”

and:

> “the network is smarter than any individual cell.”

The current manuscript is substantially better.

Use source identity to describe the mechanism, not infer mathematical optimum or intelligence.

### Return

Random Pheromone returns, but with a richer field/agent feedback loop.

---

## Flow Fields — Directions already in the ground

### Curiosity

The opening question is excellent:

> if many agents turn together, must they be watching one another?

But the artifact immediately displays the answer.

`FlowFieldMain` defaults:

```gdscript
field_display = "arrows"
```

so the organising infrastructure is visible from frame one.

The manuscript begins:

> “Find an arrow near an agent…”

This makes the room a **diagram-first** explanation.

The question could produce more curiosity if the cause were temporarily withheld.

### Artifact opportunity already in source

The source has a promoted axis:

```gdscript
@export_enum("arrows", "hidden") var field_display
```

and the comments themselves say:

> with arrows hidden the agents look like they want something; same simulation, opposite claim about where purpose lives.

That is almost exactly the experiment the manuscript proposes for a “future version.”

### Proposed reader order

1. start `field_display:hidden`;
2. watch open/block/U-wall movement;
3. ask where the apparent coordination could live;
4. press **ARROWS**;
5. reveal the field without changing the agents/scenario;
6. continue to wind/noise.

This would be a major reader-experience improvement for very little conceptual change.

### Source nuance

The identity says:

> “entire decision is a lookup.”

The actual `FlowAgent.gd` also carries:

- velocity;
- velocity interpolation/steering;
- off-map return rule;
- random wandering when field direction is zero.

The field supplies the directional target.

It does not fully determine one-frame movement by lookup alone.

The manuscript’s wording:

> “reads the direction at its present position and steers towards it”

is better.

### Source gap

`FlowGrid` is absent.

So the exact:

- Dijkstra/cost propagation;
- obstacle weighting;
- generated vector rule

cannot be inspected from this bundle.

### Return

Forces’ field/receiver distinction returns at population scale.

---

## Boids — Three ways to be near

### Curiosity

The highlighted boid is a good choice.

It prevents the flock silhouette from swallowing the local rule.

The visitor can follow:

- red separation;
- blue alignment;
- green cohesion

on one agent while changing one parameter.

### Discovery

The source confirms that these are not merely decorative arrows.

The highlighted boid stores the actual weighted contributions used in its acceleration.

RADIUS is particularly important.

The rule stays numerically the same.

The set of included neighbours changes.

This is exactly the sequence’s question:

> who is locally available to influence whom?

### Timing

Good.

The three classic names arrive early, but the real discovery is in their **disagreement** at one instant.

The manuscript wisely asks the visitor to describe that disagreement in ordinary terms.

### Boundary seam

The source wraps positions at the box boundaries.

But neighbour distance is computed as:

```gdscript
boid.position.distance_to(other.position)
```

with no periodic/toroidal correction.

Thus:

- an agent leaving +X reappears at −X;
- but agents near opposite boundaries do not perceive one another as nearby across the wrap.

Motion topology is periodic.

Social/perception topology is not.

The manuscript’s sentence:

> “leaving one side does not mean leaving the population”

is true.

But the stronger interpretation:

> “the neighbourhood itself wraps”

would be false.

This is worth one technical-layer sentence.

### Spatial timing

The primary controlled artifact is at `(10,9)`.

Five secondary boid works occupy z2–8.

The manuscript begins directly with the primary.

A walkthrough should check whether the visitor reaches older boid demonstrations first and has already formed a “flocking spectacle” reading before the controlled instrument.

If so, move `flocking_controls` forward rather than rewriting the chapter.

### Return

Flow field gives way to social field:

> nearby agents become the changing reference.

---

## Agent-Based Modeling ABM — Change a rule, watch a population

### Curiosity

The opening instruction is methodologically good:

> hold ANTS steady, change EVAPORATE, RESET, compare.

That is exactly the controlled experiment the room should provide.

### Major artifact problem: RESET is not a repeatable baseline

`_reset_colony()` does:

```gdscript
_init_pheromone_grid()
_spawn_food_sources()
_spawn_ants()
```

But food creation uses unseeded global `randf()` for:

- source angle/distance;
- quality.

And `AntState._init()` uses global `randf()` for:

- initial velocity;
- wander angle.

So RESET clears the shared field but gives the next run:

- new food geometry;
- new food quality;
- new initial ant headings/velocities.

That directly undermines the manuscript’s proposed one-variable evaporation comparison.

### Artifact fix

Use a local `RandomNumberGenerator` with a fixed lesson seed.

On RESET:

- reseed local generator;
- reproduce same food sources/qualities;
- reproduce same ant initial headings.

Then change only EVAPORATE.

Optional:

- **NEW SEED** as a separate control.

This would align Randomness’ reproducibility lessons with Swarm.

### Second source issue: evaporation is frame-based

`_evaporate_pheromones()` does:

```gdscript
decay = 1.0 - evaporation_rate
grid[x][y] *= decay
```

once per `_process()` frame.

So `evaporation_rate` is not currently a per-second rate.

The same setting will produce different decay over wall-clock time at different frame rates.

For a tutorial comparing trail persistence, this matters.

Prefer a delta-aware exponential/continuous decay or clearly label it as per-update.

### ANTS is conceptually richer than the manuscript currently notes

Changing ANTS calls:

> `_spawn_ants()`

but it does **not** clear the pheromone field.

So a completely new population inherits the environmental memory created by the old population.

That is excellent material.

The chapter currently says:

> treat it as a new population rather than continuous observation of old individuals.

Add:

> **the population is new; the field is not.**

That would make the memory location even clearer.

### MODE

MODE changes current behavioural mode without resetting colony state.

That is fine.

It means this is not a clean three-mode controlled comparison unless manually RESET between modes.

The manuscript does not overclaim it.

### Return

Physarum’s environmental memory returns in a more instrumented, parameterised model.

---

## Ant Colony Optimization — Directions left for someone else

### Curiosity

This is a meaningful second ant chapter because the mechanism changes.

The visitor can follow:

- outbound traffic;
- inbound traffic

on one route and ask how the two directions help each other.

### Source support

`SimpleAnt.gd` makes the two-channel logic explicit.

**FORAGING**

```gdscript
target_type = FOOD
drop_type = HOME
```

**RETURNING**

```gdscript
target_type = HOME
drop_type = FOOD
```

Trail energy:

- decays with travel;
- resets at food/home.

The destination therefore changes both:

- internal state;
- environmental contribution.

That is exactly what the manuscript says.

### Important source gap

`AntColonyV2.gd` calls:

- `PheromoneGrid.process_source_emission()`
- `process_diffusion()`
- `process_decay()`.

`PheromoneGrid` is not bundled.

Thus the two-channel agent logic is source-supported.

The exact field evolution is not.

### Title caution

The room is named Ant Colony Optimization.

But the manuscript correctly says:

> attractive trail ≠ proof of shortest route or travelling-salesman optimum.

Keep that caution.

The source identity says:

> emergent load-balancer;
> paths existed as pure probability;
> territory and route emerge together.

Those are stronger metaphors than the source can establish.

### Future interaction

Moving food is indeed the natural next experiment.

Unlike Physarum’s automatic carousel, this scene currently fixes its anchorage.

A movable FOOD control would make adaptation/history directly comparable.

But route restoration is more urgent.

### Return

This hall is where internal state and environmental memory meet cleanly.

---

## Particle Swarm Optimization — Better according to which score?

### Curiosity

This is conceptually one of the best chapters.

The same swarm can receive another criterion without changing its current positions.

The visitor therefore experiences:

> value changed before body changed.

That is powerful.

### CONVERGE / SPREAD

These two objectives are source-clear.

**CONVERGE**

> maximize negative distance to centre.

**SPREAD**

> maximize distance from centre.

The manuscript correctly avoids calling either universally successful.

### Major NOVELTY bug

The current source does not produce the intended novelty-search PSO.

On `_switch_landscape(NOVELTY)`:

1. archive is cleared;
2. `_evaluate_fitness()` sees empty archive and returns `10.0` for every particle;
3. each personal best is set to 10;
4. global best becomes 10 at whichever equal-scoring particle is encountered first.

Then the archive begins receiving positions.

The arena is 3 m across.

The largest ordinary Euclidean distance between two in-bounds positions is about:

> `sqrt(3² + 3²) ≈ 4.24`

which is far below 10.

Therefore:

```gdscript
if fit > p["best_fitness"]:
```

can never succeed in normal novelty mode after the switch.

Likewise global best cannot improve.

The PSO memory is frozen at the switch-time positions while the archive changes underneath it.

The particles may still move because:

- inertia retains velocity;
- cognitive pull points to switch-time personal position;
- social pull points to an arbitrary switch-time global position.

But that movement is not evidence that the swarm is continually optimising novelty.

### Preferred fix

Do not initialise empty-archive novelty fitness to a value larger than any possible later novelty.

Options:

- if archive is empty, initialise best fitness to `-INF`;
- seed archive first, then evaluate;
- re-evaluate/reset personal/global best after first archive sample;
- or formulate novelty fitness consistently from the beginning.

Then verify the resulting behaviour.

### Label rhetoric

Source labels say:

- CONVERGE — Corporate
- SPREAD — Ecological
- NOVELTY — Artistic
- RIDGE — Meritocratic.

The manuscript wisely does **not** repeat those equivalences as facts.

Keep them as authored provocations if desired, but they should be explicitly framed as metaphors, not properties of objective functions.

### INERTIA

The source supports the manuscript’s interpretation:

```gdscript
vel = inertia * vel + cognitive + social
```

Good.

### Archive

The archive is capped at 200 positions.

So:

> new relative to what?

is exactly the right question.

### Return

Genetic Evolution’s score politics returns with collective memory.

This is the correct bridge to Machine Learning.

---

## Ecosystem capstone — Who keeps the ecosystem going?

### Curiosity

This is the right final question for the sequence.

The visitor is asked to compare:

- one local encounter;
- population count.

This already creates caution about causal attribution.

### Local model

The source supports:

- prey eat food;
- prey flee sensed predators;
- predators seek/eat prey;
- both can reproduce;
- offspring combine DNA keys and mutate;
- food can be added over time.

That is one causal layer.

### Global caretaker

`balance_ecosystem()` adds another.

If prey <10:

> spawn 5 prey.

If predators > half the prey count:

> subtract health from every predator.

If predators <2 and prey >20:

> spawn 2 predators, unless the special fallow quota disables restocking.

This is not a hidden minor patch.

It is a second-scale control system.

The manuscript is excellent to call it a caretaker.

### Reader-timing problem

The visitor cannot currently see **when** the caretaker acts.

The only label reports:

> prey count / predator count / food count.

A population recovery is therefore ambiguous by design—but there is no instrument for resolving the ambiguity.

### Artifact proposal

Add small transient markers/counters:

- **CARE +5 PREY**
- **CARE PREDATOR PRESSURE**
- **CARE +2 PREDATORS**

or a separate caretaker trace.

Then add:

> **CARE ON / OFF**

under one seeded opening state.

This would let the visitor compare:

- local rules alone;
- local rules + global maintenance.

That is the sequence’s strongest possible ending.

### Registry contradiction

Current registry/QFEP copy says:

> “Predator and prey with no referee.”

The source itself literally comments:

> “The referee.”

That metadata should be repaired immediately.

### Return

The whole sequence turns back on itself.

The visual signature of “self-organisation” is no longer sufficient evidence of local-only causation.

Excellent.

---

# 5. Five high-value changes

## 5.1 Restore Ant Colony Optimization and the ecosystem capstone to the museum route

**Evidence type:** ROUTE / CURATION

Declared:

> Physarum → FlowFields → Boids → ABM → **ACO** → PSO → **Ecosystem**

Museum-authored:

> Physarum → FlowFields → Boids → ABM → PSO

### Proposal

Restore:

1. `SwarmIntelligence_Ant_Colony_Optimization`
2. `SwarmIntelligence_Swarm_Intelligence_Algorithms`

Then verify the real `next_in_sequence` path through the museum.

### Reason

Without ACO, the sequence loses:

> environmental memory split into state-dependent home/food channels.

Without Ecosystem, it loses:

> explicit global maintenance as a counterexample to “all collective order came from local rules.”

Those are major conceptual steps.

---

## 5.2 ABM — make RESET genuinely reproducible and evaporation time-based

**Hall:** `SwarmIntelligence_Agent_Based_Modeling_ABM`  
**Artifact:** `ant_colony_optimization`

### Original manuscript task

> “Raise EVAPORATE… Use RESET before making a second comparison. Keep ANTS steady at first…”

### SOURCE problem 1 — RESET changes the starting problem

`_reset_colony()` clears the field, then respawns food and ants.

Food positions/qualities use global `randf()`.

Ant initial direction/velocity use global `randf()`.

So one RESET does not recreate the prior baseline.

### SOURCE problem 2 — evaporation depends on frame count

```gdscript
var decay := 1.0 - evaporation_rate
grid *= decay
```

runs once per `_process()`.

The parameter is therefore per-frame, not per-second.

### Artifact proposal

Use a local RNG:

```text
lesson_seed = 1337
```

RESET:

- reset RNG seed;
- recreate identical food;
- recreate identical ants;
- clear field.

Add **NEW SEED** later if desired.

Make evaporation delta-aware, e.g. an exponential decay defined per second.

### Manuscript bonus

When ANTS changes, highlight:

> **new population / old field**

because `_spawn_ants()` does not clear pheromone.

### Reason

The prose already asks for controlled comparison.

The artifact currently cannot supply it.

---

## 5.3 PSO — repair NOVELTY before treating its motion as novelty optimisation

**Hall:** `SwarmIntelligence_Particle_Swarm_Optimization`  
**Artifact:** `fitness_landscape_politics`

### SOURCE

Empty novelty archive:

```gdscript
return 10.0
```

Switching modes:

```gdscript
_novelty_archive.clear()
for p:
    fit = _evaluate_fitness(p["pos"])
    p["best_fitness"] = fit
```

Therefore every initial personal best becomes 10.

Later novelty is distance to nearest archived position.

Within the 3 m arena, this cannot exceed ~4.24.

So:

```gdscript
fit > best_fitness
```

will never become true.

### Consequence

The terrain visual can become a novelty-distance field.

The particles’ stored PSO bests do **not** update as novelty changes.

The social/cognitive memory therefore remains anchored to the switch moment.

### Artifact proposal

Make empty-archive initialisation neutral for maximisation:

- `-INF` bests until archive has evidence;
- or seed the archive first and then initialise personal/global best;
- or reset bests when the first archive point is created.

Then verify behaviour under the same seeded particle start.

### Reason

This is not a stylistic issue.

It breaks the mechanism the chapter is teaching.

The manuscript’s objective-relative argument is strong and deserves a working novelty mode.

---

## 5.4 Flow Fields — let collective-looking motion appear before revealing the infrastructure

**Hall:** `SwarmIntelligence_FlowFields`  
**Artifact:** `FlowFieldMain`

### Current source

```gdscript
@export_enum("arrows", "hidden")
var field_display = "arrows"
```

The source comment already understands the artistic difference:

> arrows visible → diagram of a cause  
> arrows hidden → agents look like they want something.

### Current manuscript

Immediately:

> “Find an arrow near an agent…”

So the explanation is present from the beginning.

### Artifact proposal

Place this lesson as:

> `#field_display:hidden`

Add one physical/runtime control:

> **ARROWS**

which toggles the visualizer without rebuilding the field.

Reorder the opening slightly:

1. watch coordinated movement;
2. form an explanation;
3. reveal arrows;
4. follow one surprising local direction;
5. continue with obstacle/wind/noise comparisons.

### Reason

This is exactly the sequence’s main epistemic question:

> collective appearance does not identify the source of coordination.

Let the visitor make that mistake once.

---

## 5.5 Make support scale explicit: revise the “no leader” thesis and expose the ecosystem caretaker

This is a linked **editorial + artifact** revision.

### Current sequence truth/objectives

> “No leader, yet coordinated.”

> “Collective behavior from local rules: no central controller needed.”

The current sequence itself contains counterexamples/qualifications:

- Flow Fields: a globally prepared route field;
- PSO: a shared global-best record;
- ABM/ACO: authored anchors/objectives/modes;
- Ecosystem: `balance_ecosystem()` watches total population and intervenes.

### Proposed sequence intention

> **Locate where collective coordination is stored and updated: in a shared field, in neighbour relations, in agent state, in an objective and shared memory, or in rules that watch the population as a whole. Ask which supports remain invisible when the result is called self-organising.**

### Proposed objectives

- Compare an environment written by agents with an environment prepared for them.
- Vary local social weights and perception radius in a boid model.
- Distinguish a new agent population from the environmental memory it inherits.
- Compare one-channel pheromone reinforcement with state-dependent home/food channels.
- Distinguish personal-best, global-best and archive memory in a particle swarm.
- Change an objective without treating “best” as intrinsic to a position.
- Identify population-level maintenance rules that operate above individual agents.
- Avoid inferring optimality, autonomy or leaderlessness from collective appearance alone.

### Artifact proposal for capstone

Show caretaker events in the room:

> **CARE +5 PREY**  
> **CARE − predator health**  
> **CARE +2 PREDATORS**

Then add a controlled:

> **CARE ON / OFF**

comparison under a seeded opening population.

### Reason

This does not weaken the swarm sequence.

It makes it much more interesting:

> distributed organisation can coexist with infrastructure, objectives and care at other scales.

---

# 6. Source / artifact discrepancies

## 6.1 Physarum core grid implementation is missing

`PhysarumColony.gd` constructs:

> `PhysarumGrid.new(...)`

and calls:

- `process_attractors`
- `process_step`
- `get_image`.

`PhysarumGrid` is not included.

The source package therefore verifies:

- agent sensing/deposition;
- anchorage geometry;
- persistence across anchor changes;

but not the exact field diffusion/decay law.

Exporter should include global classes instantiated by primary source.

---

## 6.2 Physarum identity overclaims mathematical optimality

Source identity claims:

- shortest-path trees;
- Steiner networks;
- load-balanced branching.

The manuscript correctly says:

> an economical-looking network is not evidence that the shortest possible network was found.

Keep the manuscript.

If optimality becomes a lesson, define:

- objective;
- comparator;
- metric;
- competing solutions.

---

## 6.3 Physarum’s automatic anchor change does not reset environmental memory

This is source-supported and conceptually important.

`set_distribution()` only rebuilds anchorage markers/emission centres.

It does not rebuild grid or respawn agents.

Thus the book’s “trace outlasts arrangement” observation is grounded.

---

## 6.4 FlowGrid implementation is missing

`FlowFieldMain` constructs:

> `FlowGrid.new(40,40,1.0)`.

`FlowGrid` is not included.

Therefore exact:

- cost propagation;
- obstacle treatment;
- vector derivation

cannot be independently verified.

---

## 6.5 FlowField agent behaviour is more than a lookup

Source identity:

> “the entire decision is a lookup.”

Actual agent:

- looks up desired direction;
- lerps retained velocity toward it;
- enforces max map return outside bounds;
- wanders on zero vector.

The manuscript’s “reads and steers” wording is more accurate.

---

## 6.6 FlowField tour stops at noise

The source enters modes every 10 seconds.

When mode 5/noise is reached:

```gdscript
return
```

and the sequence stays there.

The manuscript’s:

> “eventually remains with the noise field”

is source-supported.

---

## 6.7 Boid force arrows represent the actual weighted local contributions

Source computes:

- inverse-square separation × separation weight;
- mean-neighbour velocity correction × alignment weight;
- mean-neighbour position correction × cohesion weight.

The highlighted boid stores those contributions and the renderer draws them.

Good source/text match.

---

## 6.8 Boid boundary wrapping does not wrap neighbour distance

Positions wrap.

Perception distance does not use minimum-image/toroidal distance.

Thus the spatial boundary is still a seam in social neighbourhood calculation.

If periodic social space is ever claimed, fix the metric or state the limitation.

---

## 6.9 Boid RESET is not seeded

Reset simply calls `_spawn_boids()` using global `randf()`.

The manuscript does not claim deterministic replay.

Good.

If a controlled parameter study later needs exact initial replay, a local seed/reset would help.

---

## 6.10 ABM RESET is not deterministic

As detailed above.

This directly conflicts with the manuscript’s intended control strategy.

---

## 6.11 ABM evaporation is frame-rate dependent

As above.

Calling it a rate without a time unit is misleading.

---

## 6.12 ABM ANTS replaces agents but preserves the pheromone field

This is a strong, currently underused distinction.

Changing ANTS calls `_spawn_ants()`.

It does not call `_init_pheromone_grid()`.

A new population therefore inherits old environmental memory.

This is excellent sequence material.

---

## 6.13 ABM MODE does not reset state

Switching:

- COLONY
- COMMUNICATION
- MULTI_SOURCE

changes mode in the running system.

The field/food/ant population continues unless RESET is separately pressed.

So mode comparison is not automatically a controlled fresh-start comparison.

The manuscript does not claim otherwise.

---

## 6.14 `PheromoneGrid` for AntColonyV2 is missing

`AntColonyV2` calls:

- source emission;
- diffusion;
- decay.

The helper is absent.

The two-channel agent logic is still inspectable through `SimpleAnt.gd`.

---

## 6.15 AntColonyV2’s two channels are source-supported

Foraging:

- reads food signal;
- deposits home.

Returning:

- reads home;
- deposits food.

Destination encounter flips state and renews trail energy.

The manuscript is accurate.

---

## 6.16 AntColonyV2 identity overclaims load-balancing/optimality

The source identity says:

> route ants toward less depleted food;
> emergent load-balancer;
> probability becomes path.

Those interpretations require more evidence than current fixed-anchor scene provides.

The manuscript’s careful foraging/stigmergy account is stronger.

---

## 6.17 PSO objective labels are political metaphors, not properties of the mathematics

Source UI literally labels:

- Corporate
- Ecological
- Artistic
- Meritocratic.

The manuscript wisely translates the actual objective functions:

- distance to centre;
- distance from centre;
- distance from archive;
- distance from diagonal ridge.

Keep the operational definition primary.

---

## 6.18 PSO novelty is currently broken by its empty-archive score

As detailed above.

This should be fixed before runtime conclusions are drawn from NOVELTY.

---

## 6.19 PSO personal/global “best” scores are historical records

Even after novelty is repaired, the best record means:

> value when the position was evaluated under the state of the objective/archive at that time.

For a changing novelty archive, that is not the same as:

> current score of that old position.

This is conceptually rich and may deserve exposure if novelty remains dynamic.

---

## 6.20 Ecosystem source directly contradicts “no referee” registry copy

Registry/QFEP:

> “Predator and prey with no referee.”

Source comment above `balance_ecosystem()`:

> “The referee.”

The manuscript is correct to expose the caretaker.

Fix registry metadata.

---

## 6.21 Ecosystem food addition is also a global process

Each `_process()` frame has:

```gdscript
if rng.randf() < 0.01:
    spawn_food(1)
```

This probability is frame-step based, not delta-based.

So food replenishment is another maintenance input whose wall-clock rate can vary with frame rate.

The manuscript says food/maintenance exists but does not quantify it.

If cross-hardware comparison matters, time-normalise this too.

---

## 6.22 Ecosystem stabiliser acts at population scale and can dominate interpretation

Prey restocking, predator weakening and predator restocking occur after local prey/predator updates each process frame.

Thus a population recovery may come from:

- reproduction;
- survival;
- food;
- or explicit global intervention.

The current display gives no event provenance.

That motivates the proposed caretaker markers.

---

# 7. Spatial / curation findings

## Physarum

Primary `(5,3)` is near the front.

Good.

The science screen at `(1,1)` may visually compete on arrival, but no change is justified without a walkthrough.

## Flow Fields

Primary `(6,4)` is clearly early.

Good.

The best change is within the artifact: hide/reveal field arrows.

## Boids

Primary controlled instrument `(10,9)` is late.

Secondary boid works occupy:

- `(2,2)`
- `(10,2)`
- `(4,6)`
- `(2,8)`
- `(5,8)`.

This is a likely reader-order problem.

The chapter asks for one highlighted boid and one slider.

The room may first present a broad boid spectacle.

**RUNTIME / SPACE TEST:** if so, move `flocking_controls` forward toward the entrance.

## ABM

Primary `(4,4)` is early.

Good.

Catalyst/hazard objects near entrance/later route should not be allowed to redefine the ant study as game pressure during controlled EVAPORATE comparisons.

Runtime observation needed.

## ACO

Single primary `(5,3)`.

Clean.

## PSO

Primary `(4,4)` is early, but secondary `self_organizing_patterns` is at `(3,3)` and `tick_flock` at `(11,1)`.

The fitness landscape is likely visually dominant enough to remain primary.

No restage yet.

## Ecosystem

Single primary `(3,6)` in a small 10×10 hall.

Once restored to route, intervention markers should be positioned near the population count rather than over individual agents.

---

# 8. Runtime questions

No repository code was executed. Every hall still records `learner_verified: false`.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Whole sequence** | Does the assembled museum currently route ABM directly to PSO and PSO directly out of the sequence, omitting ACO and Ecosystem as `map_authored` reports? |
| **Whole sequence** | After restoring both halls, verify all seven `next_in_sequence` transitions in order. |
| **Physarum — persistence** | When anchorage changes after ~20 s, how long are old trail relations visibly legible before the new arrangement dominates? |
| **Physarum — grid** | Include `PhysarumGrid`; verify diffusion/decay/source-emission rules and whether field updates are frame- or time-based. |
| **Physarum — optimality** | Do not claim shortest/Steiner behaviour unless a measured network-length comparator is added. |
| **Flow — hidden arrows** | Start with `field_display:hidden`. Can visitors form a social/intention explanation before ARROWS reveal? |
| **Flow — cost field** | Include `FlowGrid`; verify target-cost spread and local vector selection in block/U-wall/zigzag scenarios. |
| **Flow — wind/noise** | Does the final noise mode continue indefinitely as source says? Is zero-vector wandering visibly distinct from field following? |
| **Boids — route** | Does a visitor encounter several secondary flock artworks before reaching `flocking_controls`? Test moving the controlled instrument forward. |
| **Boids — sliders** | Can SEP/ALIGN/COH effects be read first on the highlighted boid’s arrows before looking at the whole flock? |
| **Boids — radius** | Does RADIUS change neighbour-set behaviour clearly enough at the current 30-boid density? |
| **Boids — wrap seam** | Place two boids visually near opposite faces and confirm they do not count as close neighbours until coordinates wrap. |
| **ABM — RESET** | Before fix, record how food geometry/quality and ant headings change across RESET. After fix, confirm exact lesson baseline replay. |
| **ABM — EVAPORATE** | Compare equal wall-clock persistence at different frame rates; verify/update to delta-aware decay. |
| **ABM — ANTS** | Does changing population preserve the existing pheromone heatmap exactly as source predicts? Make that inheritance visible. |
| **ABM — MODE** | Does changing MODE preserve current food/field/agent state? If so, treat it as a running intervention, not a fresh matched comparison. |
| **ACO — field helper** | Include `PheromoneGrid`; verify independent home/food layers, diffusion and decay. |
| **ACO — state reversal** | Can a visitor follow one ant’s FORAGING→RETURNING change and see the sought/deposited channel reverse? |
| **ACO — fixed food** | Are the two food directions stable/visible enough to compare reinforcement history during a normal visit? |
| **PSO — CONVERGE/SPREAD** | Under one switch, do personal/global bests reinitialise to current positions and then update under the new objective as intended? |
| **PSO — NOVELTY** | Reproduce the source-derived failure: after switch, best fitness =10 everywhere and no later archive-distance can exceed it. |
| **PSO — novelty fix** | After repair, verify particles actually update personal/global best under evolving archive rather than merely following switch-time memories. |
| **PSO — INERTIA** | Within one working objective, does inertia visibly alter overshoot/persistence without changing score definition? |
| **Ecosystem — route** | Restore the capstone and verify it is reached after PSO before Machine Learning. |
| **Ecosystem — caretaker** | Add event markers and confirm each restock/weakening intervention is logged at the moment it occurs. |
| **Ecosystem — CARE OFF** | Under identical seeded opening state, compare population survival with and without `balance_ecosystem()`. |
| **Ecosystem — frame rates** | Food spawning currently uses per-frame probability; test/replace with time-based rate before comparing runs across hardware. |

---

# 9. What I would not cut

## Do not cut Physarum’s automatic anchor carousel

Its lack of reset is what makes old environmental traces available to the new problem.

That is a strong memory experiment.

## Do not cut the fading-path observation

The strongest route is not the only informative route.

Decay makes abandoned possibilities visible for a while.

That supports the chapter’s memory argument better than another optimisation claim.

## Do not call the Physarum result shortest or Steiner without a comparator

The current manuscript is right to resist this.

Keep that caution.

## Do not cut the Flow Field route/no-destination distinction

Route field, wind and noise are not one continuum of “more randomness.”

They demonstrate different meanings of a spatial direction field.

## Do not cut field arrows

They are essential evidence.

Change **when** they are revealed, not whether they exist.

## Do not cut the boid force arrows as debug UI

They turn a flock from spectacle into a local arithmetic experiment.

They are epistemic instruments.

## Do not cut perception RADIUS

Weights are only half the relation.

Who enters the neighbourhood is equally important.

Keep it central.

## Do not over-politicise “alignment” or “cohesion” as if the equations already model consent

The manuscript’s caution is appropriate:

> these are geometric relations with many omitted social capacities.

Keep that boundary.

## Do not cut ABM’s EVAPORATE / ANTS distinction

They act on different layers:

- environmental persistence;
- population size.

After RESET is fixed, this will be a very strong controlled pair.

## Do not clear the field automatically when ANTS changes

A new population inheriting old environmental memory is conceptually valuable.

Expose it.

## Do not cut MODE even though it is not a clean fresh-start comparison

It shows that one model family can switch behavioural programs while state persists.

Just do not confuse it with controlled independent trials.

## Do not cut the second ant hall

One pheromone field and two directional channels are not the same lesson.

The state-dependent channel switch deserves its own hall.

## Do not call ACO optimal because the title says optimisation

The current manuscript’s caveat is exactly right.

Keep it.

## Do not cut personal/global best from PSO

This is the hall where memory becomes explicit evaluated position.

Fix novelty; keep the memory architecture.

## Do not cut NOVELTY because it is broken

The objective is conceptually valuable.

Repair the implementation.

## Do not cut the political/metaphorical landscape names automatically

They can be provocations.

But always keep the actual mathematical objective visible and primary.

## Do not cut the ecosystem caretaker

It is the capstone.

The hidden support is more interesting than an idealised “pure self-organisation” story.

Make it visible.

## Do not frame care/intervention as contamination of the experiment

The manuscript’s line is strong:

> care, repair and replenishment can be necessary; the question is whether they remain visible when the result is described as autonomous.

Protect it.

---

# 10. Reader-experience strengths to protect

## Discovery before naming

**Physarum**  
trace persists before “environmental memory” is named.

**Flow Fields**  
collective steering can precede infrastructure explanation once arrows are hidden.

**Boids**  
one local force disagreement before judging the whole flock.

**ABM**  
trail persistence changes before generic “agent-based model” abstraction.

**ACO**  
outbound/return traffic difference before stigmergy terminology.

**PSO**  
objective switch changes value before particles visibly reorganise.

**Ecosystem**  
population recovery appears before caretaker provenance—then the instrument should reveal it.

---

## Prediction before explanation

- Which old Physarum path will persist after anchor change?
- Are Flow Field agents following each other?
- Which boid force will dominate this instant?
- Will faster evaporation erase a route before traffic renews it?
- Which channel is this ant seeking and which is it leaving?
- What becomes best when the score changes?
- Did local reproduction or the caretaker cause this recovery?

These are excellent questions.

---

## Productive distinctions to protect

- environmental memory ≠ internal map
- persistent trace ≠ optimal route
- self-written field ≠ externally prepared field
- coordinated motion ≠ peer interaction
- field direction ≠ destination
- separation/alignment/cohesion weight ≠ perception set
- wrapped motion ≠ wrapped social metric
- new population ≠ new environment
- frame-based decay ≠ time-normalised decay
- one pheromone channel ≠ state-dependent home/food channels
- attractive route ≠ demonstrated optimum
- personal best ≠ global best
- best position ≠ intrinsic goodness
- novelty ≠ unfamiliarity to the whole world
- local ecology ≠ autonomous population persistence
- reproduction ≠ restocking
- self-organisation ≠ absence of support at another scale.

This list is the real Swarm Intelligence curriculum.

---

# 11. Questions for the author

## 11.1 Are ACO and the ecosystem capstone definitively part of the current spine?

The declared book and transitions say yes.

`map_authored` says no.

I strongly recommend restoring both.

## 11.2 Do you want Flow Fields to begin as an explanatory diagram or as a perceptual puzzle?

The source already supports hidden arrows.

I prefer:

> coordinated movement first, infrastructure reveal second.

That better serves the sequence thesis.

## 11.3 Should the ABM RESET become deterministic?

For the manuscript’s stated controlled comparison, yes.

A separate NEW SEED action can preserve variation without sacrificing experimental clarity.

## 11.4 Is NOVELTY intended to be a genuine working PSO objective or primarily a conceptual provocation?

If genuine, the current best-initialisation bug needs repair.

If conceptual only, it should not be described as the swarm seeking the unvisited.

I recommend repairing it.

## 11.5 Do you want the ecosystem caretaker to remain hidden?

The manuscript’s critical point argues against hiding it.

I would make intervention provenance visible and then optionally allow CARE OFF.

## 11.6 Should the sequence still be titled around “intelligence”?

The current book often does something more specific and stronger:

> locate coordination and memory.

If the title remains Swarm Intelligence, keep asking:

> **what evidence supports calling this intelligence rather than coordinated behaviour under an authored apparatus?**

The manuscripts already move in that direction.

---

# 12. Overall conclusion

Swarm Intelligence is becoming a strong sequence precisely where it stops celebrating “emergence” as an explanation.

The current book asks a more demanding question:

> **Where is the coordination actually stored?**

Across the seven chapters, the answer keeps moving.

In Physarum:

> in an environmental trail partly written by the agents themselves.

In Flow Fields:

> in infrastructure prepared before the agents arrive.

In Boids:

> in repeated calculations over a local neighbour set.

In the compact ABM:

> in internal state plus a shared fading field and authored mode.

In the two-channel ant colony:

> in environmental signals whose meaning depends on the traveller’s state.

In PSO:

> in an objective, personal bests, a shared best and a finite archive.

In the ecosystem:

> in local interactions **and** a population-level caretaker.

That progression is much more interesting than:

> “simple agents, no leader, global intelligence.”

The strongest reader moments are where coordinated appearance turns out to have another support:

- a Physarum path persists after its anchor arrangement changed;
- a crowd appears purposeful until arrows reveal a prepared field;
- a flock’s relation changes because its perception radius changed, not because its social rules changed;
- a new ant population inherits an old pheromone world;
- outbound and returning ants use opposite environmental channels;
- the same position becomes good or bad when the objective changes;
- a population “recovers” and only later reveals that a global rule may have inserted bodies.

Those are excellent Ada moments.

The highest-value work now is therefore:

1. **restore Ant Colony Optimization and the ecosystem capstone to the museum route;**
2. **make ABM RESET reproducible and evaporation time-based so the chapter can perform the comparison it already asks for;**
3. **repair PSO NOVELTY’s personal/global-best initialisation;**
4. **start Flow Fields with arrows hidden and let the visitor reveal the shared infrastructure;**
5. **rewrite the inherited “no leader / local rules produce intelligence” thesis around the location and scale of coordination, and make ecosystem caretaker interventions visible;**
6. **include the missing global field classes (`PhysarumGrid`, `FlowGrid`, `PheromoneGrid`) in future source-review bundles;**
7. **headset-test the observation scale: Physarum trail persistence, boid force-arrow legibility, ABM trace comparison, ACO state/channel reading and capstone intervention provenance.**

The reader-experience principle I would carry forward from Swarm Intelligence is:

> **Let the crowd look coordinated before revealing where the coordination was stored.**

And the structural principle is:

> **Collective order does not identify its cause. Coordination may live in a field, a neighbourhood, a memory, an objective or a caretaker operating at another scale.**
