# Form Finding — 01 Review

Source-aware editorial and reader-experience review of the **Form Finding** sequence.

Basis: `formfinding-book.md`, `formfinding-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where the visitor can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. Recurrence is not treated as redundancy when the objective, constraint, solver, stopping rule, carrier, or body changes.

The current sequence has a strong underlying arc:

> **local descent → boundary-defined form → iterative relaxation → encoded equilibrium → controlled escape from local minima → authored success criterion**

A second formulation is:

> **A form does not simply “emerge.” Someone has chosen what can vary, what stays fixed, what quantity is reduced or balanced, how the update proceeds, and what condition is allowed to count as finished.**

That is the sequence’s real strength.

The main issue is unevenness of epistemic mode. **Descent** and **Forge** largely follow the newer Ada method: encounter → comparison → mechanism → limit. The four retained middle chapters often speak in a more declarative “hero object” voice and sometimes attribute physical solving, structural performance, optimisation or scientific status that the current artifacts do not actually perform.

---

# 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **FormFinding Descent** | **Carries:** the cleanest tutorial in the sequence. A point takes a local step before “gradient descent” needs to become a concept; two beginnings reveal local minima; STOP, LEFT FRAME and STEP LIMIT separate three reasons a search can end; rendered surface and sampled objective are explicitly different representations. **Gap:** the manuscript cites exact “recorded desktop” final costs, but this bundle contains no dated runtime capture/check. The source formula supports those outcomes, but the recorded run itself is not attached. **Next:** preserve almost all prose; attach the runtime check for the quoted numbers and headset-test whether the three stopping conditions are legible before adding explanation. |
| **FormFinding Catenary** | **Carries:** potentially a very strong distinction between a curve that is **drafted to look right**, analytic constructions that satisfy equations, and physical variational problems that motivate those equations. The manuscript’s admission that `cable_builder` is a Bezier convention rather than a catenary solver is excellent. **Gap:** the opening and closing repeatedly collapse those distinctions again, describing the room as matter “computing continuously,” the answer as exact, and the objects as if they were physical chain/soap-film solvers. Several historical/mathematical claims are also unsupported or internally inconsistent. **Next:** reorganise the room around the representation ladder—drafted spline → analytic catenary → analytic catenoid/helicoid → physical variational principle as reference—and restage the artifacts to support that order. |
| **FormFinding Relaxation** | **Carries:** a useful shift from closed-form/constructed shape to iterative state: the cloth keeps two positions rather than a separately stored velocity state; constraint passes alter the relaxed result; the mass-spring lattice and vessel preserve outputs of finite-duration processes. “A fossil of forces” is a strong sequence idea. **Gap:** the current “dial” looks like an adjustable control but has no interaction; the cloth is also continuously driven by sinusoidal gusts, so it is not simply converging while watched. The manuscript claims a “worst spring gets worse” measurement that is not present in the supplied source evidence. The mass-spring artifact shares the spawn cell and is narrated as an overhead placement accident. **Next:** make the pass control real (or unmistakably a gauge), move the mass-spring object off the spawn, and distinguish live driven cloth from frozen relaxation outputs. |
| **FormFinding Equilibrium** | **Carries:** the intended move is excellent: settling stops because dissipation/time ends; equilibrium instead asks what relations can hold a form still. The mobile’s recursive lever arithmetic is inspectable, and the manuscript correctly catches two stale object identities: the “tensegrity triangle” is not tensegrity, and the truss recursion is storey recursion rather than a strut made of struts. **Gap:** the room repeatedly treats generated geometry/animation as physical evidence. The mobile is statically constructed to satisfy moment equations, not dynamically hanging under gravity; the triangle’s “load” is direct node scaling, not structural mechanics; the truss has no strength/material analysis. “The mobile does not represent a balance, it is one,” “the triangle refuses a load,” and “max strength, min material” therefore outrun implementation. **Next:** either add one real physical comparison (e.g. pin-jointed triangle vs square under the same load) or recast the room explicitly as **encoded equilibrium and structural hypotheses**, not demonstrated mechanics. |
| **FormFinding Annealing** | **Carries:** the core algorithmic contrast is strong: local descent refuses uphill moves; annealing sometimes accepts them; an additional basin-hop mechanism explicitly admits that the search can stagnate. The final caveat about the shallow/deep Q comparison is good: this is a choice about the model’s purpose, not a test separating life from death. **Gap:** several earlier statements are technically too strong. Cold Metropolis-style search is not “gradient descent”; a ΔE=0.05 uphill move at T=0.002 is astronomically unlikely, not literally impossible, and the default run terminates at T=0.1 anyway. The algorithm also includes adaptive cooling **and separate unconditional basin hopping**, so the cabinet is more than the textbook acceptance rule described at the opening. The `max_q_basin_room` labels wells DEAD/ALIVE and declares the thesis before the visitor can compare them, and it shares the spawn cell, producing the ceiling-placement accident narrated in the text. **Next:** correct the algorithm description, neutralise the Q labels until after comparison, and move the basin installation onto the floor. |
| **FormFinding Forge** | **Carries:** an excellent ending because success becomes explicitly authored. The balance puzzle can be physically stable yet fail the height criterion; passing requires both a height threshold and a low-motion interval; the later walker animation is correctly described as acknowledgment of the detector rather than proof of life. The neighbouring optimiser returns Descent as a history rather than a destination. **Gap:** the optimizer itself still carries visitor-facing source rhetoric such as “TRAINING IS SETTLING — THE WALK DOWNHILL” and “(= a net training),” although no neural network is present and the manuscript wisely avoids that identification. **Next:** clean the artifact label to describe the implemented optimiser, keep the manuscript’s refusal of the success criterion, and runtime-test whether stacking/grabbing is usable enough in headset for the refusal experiment to happen. |

---

# 2. Sequence structure

The six-hall order is conceptually good.

## 1. Descent — a chosen local rule

The first hall establishes:

- an authored objective;
- a locally sampled direction;
- a step size;
- multiple beginnings;
- multiple stopping conditions.

It immediately prevents “minimum” from meaning “the minimum.”

## 2. Catenary — constraints can determine a family of form

The intended next move is:

> the point no longer searches alone; fixed boundaries constrain a connected shape.

This is exactly the right structural progression.

The current room becomes confused only because it moves too quickly between:

- physical chain/soap film;
- analytic catenary/catenoid;
- precomputed parametric meshes;
- a hand-authored Bezier approximation.

Those distinctions should become the room’s subject rather than being repeatedly crossed.

## 3. Relaxation — finite procedure leaves a form

Now a form has:

- many points;
- local distance constraints;
- finite update passes;
- finite duration.

The result can depend on solver settings and when the process is stopped.

That is the chapter’s key progression from **constraint** to **computational history**.

## 4. Equilibrium — stillness need not mean “the solver stopped”

The intended conceptual move is strong:

> a form can be still because relations cancel, not merely because motion was damped or the clock was stopped.

But the current artifacts mostly **encode or illustrate** balance instead of physically negotiating it.

The hall’s role is therefore structurally correct while its evidence is weaker than its prose.

## 5. Annealing — sometimes “downhill” is the trap

This is the right return to Descent.

The first hall established that local descent can stop in different valleys. Annealing changes the **search policy**, not the objective.

Then the Q installation introduces a second question:

> even if an objective has a lower value, is that necessarily what the author wants?

The final caveat is crucial.

## 6. Forge — success criterion becomes explicit authorship

Forge is the correct ending.

The puzzle makes the hall’s implicit question executable:

> gravity can produce a stable arrangement; the detector still decides whether that result counts.

The sequence therefore ends not with “nature finds the form,” but with:

> **which physical outcomes are permitted to count as success?**

That is much stronger.

---

# 3. Reader-experience lens

## FormFinding Descent

### Curiosity

The opening is exemplary:

> “Before pressing it, choose where you think the point will go.”

Nothing is named yet.

STEP gives the visitor a local action before RUN gives it rhythm.

The difference from Forces is also well timed:

> “There is no stored velocity here.”

That sentence only matters because the visitor has just come from a sequence where retained velocity was central.

### Discovery

The strongest sequence is:

1. STEP several times;
2. observe shrinking/altering steps;
3. reveal PARTS;
4. reveal RULE;
5. change SURFACE;
6. use two START positions;
7. change STOP;
8. change RATE enough to make cost rise / leave frame.

The three stopping states are especially good:

- SMALL SLOPE
- LEFT FRAME
- STEP LIMIT

They stop “the algorithm finished” from becoming one undifferentiated event.

### Timing

Very good.

The mathematical name “sampled gradient” arrives after the arrow is visible.

The statement that a small slope is not a global answer arrives after two starts have shown different accepted endpoints.

The global/local distinction is embodied rather than asserted.

### Return

Forces returns through a negative-gradient vector, but the receiver has changed completely:

> a vector no longer changes velocity; it changes an address in a search.

That is a productive return.

---

## FormFinding Catenary

### Curiosity

The best reader encounter is not actually the opening paragraph.

It is the cable builder:

> take a bead, move it, watch the curve update.

Then the book says:

> this is not a chain finding a catenary; it is a Bezier convention that someone authored.

That is an excellent Ada moment.

A convincing form is unmasked by reading its construction.

### Discovery

The room could support a very good sequence:

1. **Drafted cable:** move boundary/control points and notice the plausible sag.
2. **Analytic laundry line:** compare a curve generated from `cosh`.
3. **Catenoid:** see the catenary become a surface of revolution.
4. **Helicoid:** compare another minimal-surface construction.
5. **Physical reference:** ask which of these objects actually lets matter solve anything.

At present the text has these ingredients but tells the variational conclusion first.

### Timing

The opening currently pre-explains too much:

> “A hanging chain finds the catenary... A soap film finds the minimal surface... Nobody drew either. They are computed, continuously, by matter... Here there is no solver at all, and the answer is exact.”

Before the visitor has touched anything, the room has already supplied:

- the physical interpretation;
- the optimisation principle;
- the answer;
- the historical grandeur.

Then the first actual interactive object contradicts the framing:

> it is a drafted spline, not a physical solver.

That contradiction can be productive, but only if intentionally staged.

### Return

This hall should return Descent’s question at a larger scale:

> what changes when the endpoint constraints are fixed and the unknown is an entire curve/surface?

That is enough. It does not need to prove that the museum contains literal physical variational solvers.

---

## FormFinding Relaxation

### Curiosity

The “fossil” idea is very strong.

A visitor can encounter:

- one live cloth;
- one frozen mass-spring result;
- one frozen vessel.

The central question becomes:

> which of these forms contains an ongoing process, and which contains only its remainder?

That is more interesting than a generic soft-body tutorial.

### Discovery

The live cloth can reveal:

- motion implied by current/previous positions;
- constraint correction passes;
- persistent driving;
- no exact constraint solve.

The frozen objects can reveal something else:

> the result is still here after the process is gone.

The vessel is particularly good for asking which parameters were effectively “design variables”:

- pinned region;
- stiffness;
- preinflation;
- gravity;
- number of steps.

### Timing

The text again begins with conclusion/code rather than encounter.

More importantly, the apparent pass-count dial invites a physical action and refuses it.

This can become a critical object, but at the moment the visitor must learn from prose that it is furniture.

If “constraint passes” is the room’s main experimental variable, the artifact should allow the visitor to change it.

### Return

Trace returns through stored previous position.

Change returns through finite repeated updates.

Form Finding adds the crucial new idea:

> stopping time becomes part of what the form is.

Keep that.

---

## FormFinding Equilibrium

### Curiosity

There is good material here, especially the mobile.

The small mass tags create an invitation:

> can you see why the heavier side has the shorter arm?

That could become a genuine prediction.

The triangle also has a useful role if paired with a quadrilateral:

> why does one linkage resist racking while another has a degree of freedom?

### Discovery

The current implementation provides less discovery than the prose implies.

The mobile is generated already “solved.”

The triangle deforms because its whole node is directly rescaled.

The truss is generated geometry with no structural load computation.

The visitor can inspect **relationships that have been encoded**, but cannot currently discover the claimed mechanics by applying comparable loads and watching them respond.

### Timing

The opening formula arrives before a reader has been asked to inspect a branch.

Then declarative sentences repeatedly close interpretation:

> “It is genuinely balanced.”  
> “The triangle... refuses a load.”  
> “MAX STRENGTH, MIN MATERIAL.”

The room would be stronger if it asked the visitor to predict one arm length, or if one unsolved branch existed beside the solved one.

### Return

The correction of the name `tensegrity_triangle` is excellent.

The room can legitimately teach:

> names and visual resemblance do not establish mechanism.

But that same principle should be applied to its own claims about balance and strength.

---

## FormFinding Annealing

### Curiosity

The core question is excellent:

> what if becoming temporarily worse lets you reach something better?

The algorithmic acceptance branch is simple enough to be conceptually graspable.

The hot/cold idea is also intuitive provided it is described accurately.

### Discovery

The best available reader sequence is:

1. watch a local landscape body get stuck;
2. watch annealing accept some uphill proposals;
3. cool and see acceptance fall;
4. inspect basin hops as an additional intervention;
5. compare two stable wells with different properties;
6. ask whether lower objective value is the only thing that matters.

This is strong.

### Timing

The `max_q_basin_room` currently sabotages the last comparison by labelling the wells:

- DEAD WELL
- ALIVE WELL

and printing:

> MAX Q IS THE LIVELIEST MINIMUM, NOT THE DEEPEST

before the visitor has compared them.

The manuscript eventually becomes more careful:

> “That comparison is a choice about this model’s purpose, not a test that separates living matter from dead matter.”

That caveat should govern the artifact from the beginning.

### Return

Descent returns exactly where it should:

> same problem family, different policy.

The Q installation should then be framed as a **second problem**:

> what if the objective itself is not the criterion you want?

Do not let those two questions collapse.

---

## FormFinding Forge

### Curiosity

This is one of the strongest short halls in the sequence.

The puzzle gives a very concrete challenge:

> make something that stays up.

Then the detector can refuse a physically quiet result because it is too low.

The visitor discovers immediately that “stable” and “successful” are different predicates.

### Discovery

The balance puzzle source genuinely checks:

- maximum stack height;
- linear velocity;
- angular velocity;
- time below thresholds.

Only after both height and stability conditions remain satisfied long enough does the transformation sequence trigger.

This supports the manuscript very well.

The best line is:

> “Build a low arrangement that you find useful and the puzzle refuses. Describe its usefulness without pretending it passed.”

That is the entire Form Finding sequence returning as agency.

### Timing

Good.

The one artifact problem is the neighbouring optimiser’s visitor-facing ML slogan.

The book itself wisely keeps the optimisation local:

- slope estimate;
- small downhill step;
- short retained history;
- restart.

### Return

Descent returns in the optimiser.

Annealing returns by contrast.

Equilibrium returns in the stack.

But Forge changes the key question:

> not “where does the system settle?”  
> but “which settled systems does the author recognise as success?”

That is the right ending.

---

# 4. Five high-value changes

## 4.1 Catenary — make the room distinguish analytic construction, physical variational principle and drafted imitation

**Hall / instances**

`FormFinding_Catenary`

- A1 `(5,3)` `cable_builder`
- A2 `(9,5)` `catenoid`
- A3 `(4,7)` `helicoid`
- A5 `(2,9)` `laundry_line_cathedral`

### Work performed by the current passages

The room wants to establish a powerful idea:

> form can be constrained by boundary conditions and an objective rather than explicitly drawn.

It also contains an unusually good internal critique:

> `cable_builder` looks catenary-like but its sag is authored with Bezier handles.

That critique should remain.

### SOURCE

`cable_builder.gd::_update_cable()`:

```gdscript
var handle_length = distance * 0.3
curve.set_point_out(i, Vector3(handle_length,
    -gravity_sag * distance * 0.5, 0))
```

The source comments themselves now admit:

> “weight drawn rather than derived.”

`laundry_line_cathedral.gd::_cat_y()` computes an analytic `cosh` curve.

`catenoid.gd` computes a parametric catenoid from `c * cosh(u/c)`.

`helicoid.gd` computes a parametric helicoid once at construction.

None of these latter three artifacts is a physical rope/soap-film simulation solving itself in the museum.

### Current text that overreaches

> “Nobody drew either. They are computed, continuously, by matter obeying one instruction: spend the least.”

and later:

> “The chain does not iterate... It is already in the shape that costs least, at every instant...”

The room’s actual chain-like objects are analytic or drafted constructions.

### Proposal

Change the opening from **matter already solving in this room** to **three ways a variational form can enter a program**.

For example:

> Two famous variational forms are waiting in this room, but the museum reaches them in different ways. One cable is drafted to resemble a hanging curve. The washing lines evaluate a catenary formula directly. The hourglass is a catenoid generated from another formula. Physical chains and films motivated these forms; these exhibits let us inspect what has been retained when the physical process is replaced by a construction.

Then let the visitor handle the cable **before** receiving the larger variational account.

### Mathematical/source corrections required

Several claims should be removed or sourced before publication:

- “two of the oldest solved minimisations in the world” — unsupported historical ranking;
- “soap film between two rings makes this surface and no other” — uniqueness is not established by the artifact/source;
- “Apart from a flat plane, the helicoid and the catenoid are the only ruled minimal surfaces” — internally inconsistent with `helicoid.gd`, whose own header calls the **helicoid** “the only ruled minimal surface besides the plane”; this sentence should not remain;
- the isometric deformation claim between catenoid/helicoid needs a mathematical source if retained;
- the Gaudí historical account needs a source rather than being treated as self-evident.

### Spatial proposal

The authored spatial order from spawn is roughly:

> cable → catenoid → helicoid → laundry

while the conceptual manuscript order is:

> cable → laundry catenary → catenoid → helicoid.

If that conceptual order is intended, restage the laundry lines earlier rather than sending the reader to the far end and back.

### Reason

This is not about reducing poetry.

It is about making the room’s strongest distinction—**how a form is produced**—the thing the visitor can actually discover.

---

## 4.2 Relaxation — make constraint passes an actual experiment, and stop preserving spawn-placement accidents

**Hall / instances**

`FormFinding_Relaxation`

- A1 `(2,2)` `mass_spring_bench:270`
- A2 `(6,2)` `verlet_workbench:90`
- A3 `(9,2)` `frozen_glass_vessel:90`

Spawn is also at `(2,2)`.

### Work performed

The chapter wants to show:

- one live iterative cloth;
- one frozen mass-spring output;
- one frozen vessel;
- finite pass count and finite step count as design variables.

This is strong.

### SOURCE — the dial

`verlet_workbench.gd` maps:

```text
nudged = 1
worked = 4
pressed = 8
held = 12
```

constraint passes.

But the visible dial is just a Node3D cylinder whose rotation is driven by:

```gdscript
_dial.rotation.y = sin(_t * 0.3) * 0.6
```

There is no collider, grab callback or input connection.

The manuscript correctly calls it furniture.

### Artifact proposal

Make the main variable experimentally accessible.

A simple four-position control could:

1. select 1 / 4 / 8 / 12 passes;
2. reset the cloth to the same deterministic starting condition;
3. run a fixed comparison interval;
4. show one small metric (mean spring error or hanging height).

If interactive comparison is not desired, replace the rotating “dial” with an unmistakable fixed gauge labelled:

> **4 constraint passes / frame**

so it no longer promises control.

### Source/text correction

Current manuscript:

> “There is no velocity in that code.”

But the shown code literally contains:

```gdscript
var vel: Vector3 = (pos - prev) * damping
```

The correct distinction is:

> **There is no separately stored velocity state. Motion is reconstructed from current and previous positions.**

Also, the manuscript says:

> going from one pass to four makes the whole cloth tauter and makes the single worst spring worse.

The source comments contain detailed measurements of mean signed spring stretch and vertex displacement, but this “single worst spring gets worse” result is not included anywhere in the supplied evidence/source record.

Attach the check that supports it or remove that specific claim.

### Placement proposal

The mass-spring bench shares `(2,2)` with the spawn. The text has absorbed the assembly consequence into the chapter:

> it was bumped upward and hangs above you.

That is not conceptually useful enough to preserve as curriculum.

Move the mass-spring bench off the spawn to a normal inspectable position and revise the prose accordingly.

The same principle applies later to Annealing’s Q basin.

### Reason

Here the better fix is clearly the artifact.

Constraint-pass count is the chapter’s most interesting controlled variable. Let the visitor change it rather than explaining a decorative dial’s failure.

---

## 4.3 Equilibrium — distinguish arithmetic/geometric construction from physically demonstrated equilibrium

**Hall / instances**

`FormFinding_Equilibrium`

- A1 `(5,3)` `calder_mobile`
- A3 `(4,6)` `tensegrity_triangle`
- A2 `(9,4)` `fractal_truss_tower`

### Work performed

The intended chapter question is excellent:

> when a form is still, is it still because motion ended—or because relations are balanced?

The current objects can support several useful claims:

- the mobile’s arm lengths are **computed** to satisfy equal moments;
- the “tensegrity triangle” is actually a triangular strut frame;
- the truss is recursively braced geometry.

### SOURCE

#### Mobile

`calder_mobile.gd::_build_subtree()` computes:

```gdscript
dl = arm * wr / total
dr = arm * wl / total
```

so `wl * dl = wr * dr`.

But the mobile is procedurally placed and frozen. There is no gravity/hinge simulation making it seek equilibrium.

The source identity itself admits the geometry is generated as a solved mobile.

#### Triangle

`tensegrity_triangle.gd::_process()` does **not** apply a mechanical load.

It directly prescribes:

```gdscript
scale = Vector3(1.0 + load * 0.4, 1.0 - load, 1.0)
```

from a sine wave.

There are no tension cables and no comparative four-bar frame.

#### Truss

`fractal_truss_tower.gd` recursively builds legs and X-bracing.

It contains no structural load, stress, buckling or material-efficiency analysis.

The visitor-facing label nevertheless says:

> MAX STRENGTH, MIN MATERIAL

### Current claims that exceed evidence

> “It is genuinely balanced, not balanced-looking.”

> “The triangle... refuses a load in front of you.”

> “The truss does not illustrate efficiency, it is what is left after everything unnecessary was removed.”

These statements treat encoded geometry as measured mechanics.

### Proposal

Choose explicitly between two versions of the hall.

#### Preferred artifact route

Add one genuinely mechanical controlled comparison:

> **pin-jointed triangle versus pin-jointed square under the same lateral/compressive load**

with joints allowed to rotate.

Then the visitor can actually see:

- triangle shape constrained by member lengths;
- quadrilateral racking without diagonal bracing.

Keep the mobile as a **computed equilibrium construction** and the truss as a **structural hypothesis / bracing study**.

#### Lower-cost editorial route

Change the chapter language to:

- “arithmetically balanced” rather than “genuinely balanced”;
- “the animation depicts a compressed triangular frame” rather than “refuses a load”;
- “braced geometry intended to suggest material efficiency” rather than proven max-strength/min-material.

### Source cleanup

The `tensegrity_triangle` source identity is substantially more sweeping than its implementation and should be rewritten.

The `fractal_truss_tower` identity similarly claims more strength/material performance than it computes.

### Reason

This hall can still be excellent without pretending the code has performed engineering analysis.

Its real critical strength would then be:

> **which forms are solved by equations, which are demonstrated by mechanics, and which are only hypotheses encoded as geometry?**

---

## 4.4 Annealing — separate simulated annealing, basin hopping and the Q argument; let the wells be compared before they are judged

**Hall / instances**

`FormFinding_Annealing`

- A2 `(6,2)` `energy_landscape_bench:90`
- A3 `(10,2)` `simulated_annealing:90`
- A1 `(2,2)` `max_q_basin_room:270`
- A4 `(9,5)` `impossible_end_table`

Spawn is also `(2,2)`.

### Work performed

The chapter has two genuinely different questions:

1. **How can a search escape a local minimum?**
2. **Is the lowest objective value necessarily the outcome we want?**

Both deserve to remain.

### SOURCE — annealing is a hybrid

The core acceptance rule is accurately shown:

```gdscript
if delta_energy < 0:
    accept = true
else:
    probability = exp(-delta_energy / current_temperature)
    accept = randf() < probability
```

But the shipped artifact also includes:

- adaptive cooling toward a target acceptance rate;
- `stagnation_threshold = 80`;
- a separate `_perform_basin_hop()` that unconditionally jumps to a random nearby position;
- reheating to at least 30% of the initial temperature after a hop.

So the cabinet is not only the textbook Metropolis acceptance rule.

### Editorial corrections

Current:

> “Run it cold and it is gradient descent again, refusing every backward step.”

Proposed:

> **Run it cold and worse proposals become increasingly unlikely. The search approaches a greedy downhill random walk; it still proposes random neighbours rather than following the gradient.**

Current:

> “A move costing five hundredths... is accepted about four times in five at a temperature of a fifth, and never at all at two thousandths.”

The first calculation is approximately right:

`exp(-0.05 / 0.2) ≈ 0.78`.

The second is not literally zero:

`exp(-0.05 / 0.002) = exp(-25)`, extremely small but nonzero.

Also, the default run terminates at `T = 0.1`, so `0.002` is not a state this configured default reaches.

Proposed:

> **At T = 0.2, a +0.05 proposal is accepted with probability about 0.78. At very low temperature that probability becomes negligible. The configured run itself stops cooling at 0.1.**

Then name basin hopping separately:

> **If the search goes 80 steps without improvement, this cabinet adds another mechanism: it jumps to a new basin and reheats. That is an extra escape policy layered on top of the annealing acceptance rule.**

### Q installation — reader timing

`max_q_basin_room.gd` labels the two sides:

- `DEAD WELL`
- `ALIVE WELL`

and displays:

> `MAX Q IS THE LIVELIEST MINIMUM, NOT THE DEEPEST`

before the visitor can compare them.

The manuscript later gives the necessary caveat:

> this comparison is a choice about the model’s purpose, not a test separating living matter from dead matter.

The artifact should follow that caution.

### Artifact proposal

Initial labels:

- **DEEP / NARROW**
- **SHALLOW / WIDE**

or simply:

- **WELL A**
- **WELL B**

Let the visitor first notice:

- one static rigid cube;
- one periodically jostled soft body.

Only later introduce the authored interpretive proposition:

> **For this model, suppose responsiveness is part of what we value.**

This is much stronger than labelling one well alive by fiat.

### Placement proposal

A1 shares the exact spawn cell `(2,2)`.

The manuscript narrates the resulting museum placement accident as an overhead seven-metre plate.

Move it off the spawn and put the comparison at a deliberate bodily height.

### Impossible table correction

The table is a static procedural model of a tensegrity-style furniture arrangement.

Its source builds bars and cable-like cylinders; it does not simulate tension or the teacup’s load.

Therefore:

> “the proof that this is not a metaphor”

is too strong.

Call it a **structural diagram/model** unless a constraint/force simulation is added.

### Reason

The chapter already contains the right caveat. The code and staging should let that caveat govern the whole encounter rather than arriving after “DEAD / ALIVE” has already decided the interpretation.

---

## 4.5 Forge — remove the unearned machine-learning equivalence from the artifact, not the manuscript

**Hall / instance**

`FormFinding_Forge`

A3 `(4,7)` `gradient_descent_optimizer`

### Work performed

The neighbouring optimiser is useful because it returns Descent in a different form:

- automatic steps;
- trail;
- energy readout;
- restart from another beginning.

It gives the balance puzzle a numerical neighbour without replacing the physical stack.

### SOURCE

`gradient_descent_optimizer.gd` labels itself:

> “Settling: gradient descent toward max Q”

and its visitor-facing title is:

> `TRAINING IS SETTLING — THE WALK DOWNHILL`

The readout ends:

> `(= a net training)`

The source identity further claims:

> “settling a soft body and training a model are one algorithm”

although this artifact contains no neural network, dataset, loss from a model or training process.

It is simply gradient descent on an authored scalar energy function.

### Artifact/source proposal

Visitor-facing label:

> **GRADIENT DESCENT — LOCAL DOWNHILL STEPS**

Readout:

> step / objective / learning rate

Remove:

- “TRAINING IS SETTLING”
- “= a net training”

unless a later explicit comparison actually uses the same optimiser to train a model.

The Machine Learning sequence can make that bridge when the necessary receiver exists.

### Reason

The manuscript is already more precise than the artifact.

Do not let a source slogan force an ontological identification into an otherwise careful sequence.

---

# 5. Source / artifact discrepancies

## 5.1 Catenary source identity still calls the drafted spline a natural gravity result

`cable_builder.gd` opens with:

> “emerges: natural catenary sag from gravity acting on flexible curves between fixed points”

but its default `catenary` path is authored Bezier handles proportional to span.

The newer comments later in the same source correctly admit:

> “weight drawn rather than derived.”

The manuscript is right to expose this contradiction.

Clean the identity header.

---

## 5.2 Catenoid is a rigid/pickable parametric mesh with an enclosing cylinder collision, not a live soap film

`catenoid.gd` procedurally creates the mesh from the catenoid equation once, then creates a **cylinder collision shape** around it.

This collision is not the catenoid surface itself.

The scene root is a `RigidBody3D` / `XRToolsPickable`.

Whether current museum hands can actually grab it depends on collision-layer/tool configuration not fully established by this bundle.

Therefore the manuscript’s claim that it looks pickable but cannot be picked up requires runtime/XR confirmation.

The source does support a different important point:

> rendered catenoid and collision body are different geometries.

That could itself become an Ada comparison.

---

## 5.3 The catenoid/helicoid mathematical paragraph contains an internally inconsistent claim

The manuscript says:

> “Apart from a flat plane, the helicoid and the catenoid are the only ruled minimal surfaces there are...”

But `helicoid.gd` itself says:

> “The only ruled minimal surface besides the plane.”

The bundle therefore does not support the manuscript sentence even internally.

Do not publish that sentence without correction and a mathematical source.

---

## 5.4 `verlet_workbench` source identity promises an adjustable dial that does not exist as interaction

Header:

> “a dial sets the number of constraint passes per frame”

Implementation:

- creates a cylinder/notch;
- rotates it from wall-clock sine;
- contains no collider/input signal;
- configured pass count comes from export/config.

The manuscript correctly identifies the dial as furniture.

The artifact should catch up with its own identity.

---

## 5.5 The Relaxation “worst spring gets worse” measurement is not supplied

The source header contains extensive offline measurements:

- hanging heights for 1/4/8/12 passes;
- mean signed spring stretch;
- vertex displacement between configurations.

But no supplied source/evidence records the manuscript’s specific claim:

> one pass → four makes the single worst spring worse.

Attach the measurement script/result before keeping that sentence as a factual claim.

---

## 5.6 `frozen_glass_vessel` calls itself “walkable” but creates no collider

The source header begins:

> “Walkable vessel whose shape came from physics.”

The implementation generates a mesh and label, but no collision shape/body is built around the result.

The manuscript correctly says the visitor can walk through it.

Update the source identity.

---

## 5.7 The frozen vessel’s “pressure” is an initial geometric inflation, not continuing internal pressure

The code applies:

```gdscript
v = v * (1.0 + preinflate)
```

to unpinned vertices before simulation.

No pressure force is applied during the 200-step relaxation.

So phrases such as “pressure pulse” are acceptable if understood as an initial displacement, but “forces that acted” should not imply a continuing pressure term.

---

## 5.8 Calder mobile is arithmetically balanced but statically generated

The source computes leaf mass from assumed virtual aluminium:

```text
π r² × 0.003 m × 2700 kg/m³
```

and places pivots so equal moments follow algebraically.

There is no free hinge/gravity simulation causing the mobile to find that position.

The source identity saying:

> “while they drift”

is stale.

The manuscript catches the lack of movement but still occasionally calls the object physical proof.

Use **computed/arithmetic equilibrium** unless dynamic balance is implemented.

---

## 5.9 `tensegrity_triangle` is neither tensegrity nor a mechanical rigidity test

There are:

- three mesh struts;
- three mesh joints;
- no cables;
- no physics joints;
- no load transfer;
- no square comparison.

The “compression pulse” is direct root scaling.

The manuscript’s correction that this is not tensegrity is necessary.

The remaining rigidity claims should also be reduced or the artifact improved.

---

## 5.10 `fractal_truss_tower` performs no strength/material optimisation

It builds recursive stacked X-braced geometry and labels it:

> MAX STRENGTH, MIN MATERIAL

There is no structural calculation establishing either maximum strength or minimum material.

The manuscript partially catches the recursion mismatch but still adopts efficiency language.

Treat the label as a design proposition unless analysis is added.

---

## 5.11 Simulated annealing includes adaptive cooling and basin hopping beyond the displayed acceptance equation

The manuscript shows the Metropolis-style accept/reject branch correctly.

The actual instrument also:

- adapts cooling rate toward a target recent acceptance rate;
- performs random basin hops after 80 steps without improvement;
- reheats after a hop.

Those mechanisms should be visible in the explanation if their effects are part of what the visitor sees.

---

## 5.12 Max-Q source rhetoric is much stronger than the sequence’s methodological caveat

Source identity says:

> “lowest energy, zero life”  
> “MAX Q IS THE LIVELIEST MINIMUM”  
> “width beats depth for life”

The actual artifact creates:

- a static cube in one well;
- a soft body in the other;
- a **programmed jostle every 2.5 seconds** that keeps the second body moving.

Its “aliveness” is therefore authored by an explicit recurrent perturbation.

The final manuscript caveat is the correct level of claim.

Clean the source rhetoric or make its constructedness visible.

---

## 5.13 The “impossible end table” is a static model, not a force simulation

The source procedurally draws:

- two rigid bracket shapes;
- one central cable-like cylinder;
- three perimeter cable-like cylinders;
- tabletop and teacup.

No tension, cable constraints, gravity or load transfer are simulated.

It can illustrate the geometry of a tensegrity-style table.

It cannot by itself prove that the teacup is supported by continuously balanced forces.

---

## 5.14 Forge’s balance puzzle does genuinely test an authored criterion

Unlike several middle-hall “hero” objects, this one supports its manuscript claims.

`balance_puzzle.gd`:

- computes highest piece;
- requires height ≥ threshold;
- checks linear and angular velocities;
- requires stability for `stability_time`;
- only then triggers the transformation sequence.

The manuscript is appropriately careful that the walker animation is a reward/acknowledgment, not biological emergence.

Protect this accuracy.

---

# 6. Spatial / route findings

## Catenary

Spawn `(2,2)` → cable `(5,3)` → catenoid `(9,5)` → helicoid `(4,7)` → laundry `(2,9)` → exit `(11,9)`.

The manuscript conceptually wants:

> cable imitation → true catenary → catenoid → helicoid.

The physical order does not naturally support that.

Restaging is preferable to a prose route that sends the reader back and forth across a small hall.

---

## Relaxation

Spawn and `mass_spring_bench` both occupy `(2,2)`.

The manuscript has incorporated the resulting vertical placement into its description.

This is an implementation accident becoming curriculum.

Move the artifact.

The primary conceptual first encounter is `verlet_workbench` at `(6,2)`, but the mass-spring object occupies the arrival cell.

---

## Equilibrium

Natural increasing-z order from spawn:

> mobile `(5,3)` → truss `(9,4)` → triangle `(4,6)`.

Manuscript order:

> mobile → triangle → truss.

If the chapter keeps that conceptual order, swap/restage triangle and truss.

---

## Annealing

`max_q_basin_room` and spawn both occupy `(2,2)`.

Again, the manuscript describes the resulting elevated placement as part of the artwork.

Because this comparison is central to the chapter’s second argument, it should be deliberately placed where bodies can inspect it, not preserved as a spawn-resolution accident.

---

## Forge

A secondary `self_shaping_forge` at `(5,3)` precedes the manuscript’s first primary `balance_puzzle` `(9,5)`.

If the balance puzzle is intended to carry the chapter opening, check whether the secondary object diverts attention first.

---

# 7. Unsupported historical/scientific claims needing sources or revision

The bundle does not supply references for the following claims. Some are broad enough that they should be either sourced carefully or rewritten more narrowly.

## Catenary

- “two of the oldest solved minimisations in the world”
- Gaudí hung chains, photographed them and turned the photograph upside down in the exact manner described
- “the curve that costs least to hang is the curve that costs least to stand”
- “the shapes nobody could calculate in 1890”
- catenoid/helicoid classification and continuous no-stretch deformation
- uniqueness claims about soap film between rings

## Relaxation

- historical priority/details of “Loup Verlet’s idea, from 1967”
- broad D’Arcy Thompson claim that the vessel is a “real claim about glass” and his “whole argument”

The computational artifact can support a process/form relation without claiming historical or material universality.

## Equilibrium

- broad Fuller historical/structural claims
- Eiffel “span the most with the least” / “everything unnecessary removed”
- Gaudí historical claims repeated from Catenary

## Annealing

- “Rastrigin... the standard cruelty of this field” is rhetorical rather than sourced;
- if retaining it, make it clearly playful rather than a factual ranking.

The algorithm itself can be taught without historical superlatives.

---

# 8. Runtime questions

No repository code was executed. Every hall still records `learner_verified: false`.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Descent — STEP/RUN** | Can a visitor predict and then visually track individual downhill steps at the current plot scale? Does RUN’s presentation interval read as observational rhythm rather than physical time? |
| **Descent — two starts** | Reproduce/attach the quoted desktop results near `-0.304` and `0.295` under RATE 0.7 / STOP 0.01 on TWO VALLEYS. |
| **Descent — stopping states** | Can a learner deliberately produce SMALL SLOPE, LEFT FRAME and STEP LIMIT and distinguish them without the prose? |
| **Descent — rate** | At RATE 5.0 on the bowl, is rising cost / leaving frame visually evident before the status appears? |
| **Catenary — cable** | Are all four cable points actually grabbable in XR? Does moving an interior point versus endpoint make the authored Bezier nature perceptually obvious? |
| **Catenary — spatial route** | Which object does a visitor naturally reach after the cable: catenoid or laundry line? Does the text route require backtracking? |
| **Catenary — catenoid** | Can the object be grabbed with current XR hand collision masks? Does its enclosing cylindrical collider produce bodily/grab behaviour noticeably different from its hourglass mesh? |
| **Catenary — helicoid** | Is the 0.2 m-scale object visible enough to inspect, or is the manuscript correct that visitors can step over it unnoticed? |
| **Catenary — science screen** | Does the science screen actually fail to match the laundry line because of its 8 m search radius and current placement? If so, is that failure useful to a beginner or merely internal debugging history? |
| **Relaxation — pass control** | Do visitors try to grab/turn the visible dial? If yes, the current furniture-control mismatch is real reader friction. |
| **Relaxation — cloth** | Under the live sinusoidal gust, can a visitor distinguish continued relaxation from ongoing external driving? |
| **Relaxation — passes** | Attach/reproduce the measurement supporting any claim about the worst individual spring becoming worse from 1→4 passes. |
| **Relaxation — mass spring** | Where does the museum actually place the `(2,2)` artifact relative to spawn? Can it be comfortably viewed, or is it overhead as the manuscript states? |
| **Relaxation — vessel** | Does the vessel truly have no collision in the assembled map, allowing a visitor to walk through it? |
| **Equilibrium — mobile** | Can the arm-length / mass relation be visually checked from the tags? Does the frozen geometry read as computed balance rather than a freely hanging mobile? |
| **Equilibrium — triangle** | What does a learner think the rhythmic whole-node scaling represents? Without a comparison object, do they interpret it as measured rigidity? |
| **Equilibrium — truss** | Is there any runtime load/strength behaviour outside the included script? If not, keep efficiency claims explicitly hypothetical. |
| **Equilibrium — route** | Do visitors naturally encounter truss before triangle despite the manuscript’s opposite order? |
| **Annealing — TEMP control** | Does moving TEMP during a running search change only `initial_temperature` and proposal scaling until RESET? Verify what a learner actually experiences; the slider may not mean “current temperature.” |
| **Annealing — cooling** | Does the adaptive schedule override the simple cooling-rate interpretation visibly? Can a visitor tell the cabinet is using adaptive cooling? |
| **Annealing — basin hop** | Does automatic hopping after stagnation occur during a normal visit? Is it distinguishable from an accepted high-energy annealing move? |
| **Annealing — probability** | Is P(accept) gauge intelligible as a distribution of proposal acceptance probabilities rather than the current single probability? |
| **Annealing — Max-Q placement** | Confirm the same-cell spawn displacement/elevation. Move it to floor level and compare the reader experience before preserving the ceiling description. |
| **Annealing — Max-Q meaning** | With labels neutralised, what do visitors actually say about the static deep-well cube and periodically jostled shallow-well soft body before being given the Q proposition? |
| **Annealing — end table** | Does it have any runtime physics/constraints not visible in the included source? If not, describe it as a static structural model. |
| **Forge — stack interaction** | Can XR hands reliably arrange eight small physics pieces into a stable stack above the 0.4 m threshold? |
| **Forge — criterion** | Can a visitor deliberately build a stable low arrangement and see it refused, then a taller stable arrangement accepted? This is the hall’s essential experiment. |
| **Forge — transformation** | Does the transformation/walker animation read as reward after detection rather than as “life emerging from physics”? |
| **Forge — optimiser** | Does the automatic gradient optimiser visibly restart from another point after local convergence, and can the visitor compare two trail histories before the old 40-sample trail disappears? |

---

# 9. What I would not cut

## Do not cut the three stopping conditions in Descent

SMALL SLOPE, LEFT FRAME and STEP LIMIT are not extra implementation trivia.

They establish that “finished” can mean:

- the measured local change is small enough;
- the search left the domain we agreed to inspect;
- the allotted budget ran out.

That distinction is foundational for the entire sequence.

---

## Do not cut the two-start local-minimum experiment

It is the reason Annealing later has something to answer.

Without it, “escape a local minimum” becomes theory pasted onto a cabinet.

---

## Do not cut the difference between rendered surface and sampled objective

The point does not descend on the triangles.

That distinction prevents the landscape metaphor from quietly becoming physical terrain.

It is especially important because later retained chapters sometimes blur physical and analytic form.

---

## Do not cut the cable-builder confession

> the cable is a convincing drawing of a catenary, not a solver.

This is one of the best passages in the retained middle chapters.

It should become the model for the room rather than an exception surrounded by stronger claims.

---

## Do not cut the catenoid/helicoid pair merely because they are static formulas

Their static nature can be productive if named accurately:

> two analytically generated minimal surfaces whose relationship can be discussed, but whose deformation is not staged here.

The problem is claiming the physical process is present when it is not.

---

## Do not cut “fossil of forces”

That metaphor is strong because the frozen vessel really is the retained output of a finite simulation.

Just distinguish:

- initial geometric inflation;
- gravity/springs during relaxation;
- chosen stopping step.

The process history matters even when the live process is gone.

---

## Do not cut the non-interactive dial critique if the dial remains

If the artifact still looks like a control and is not one, the manuscript is right to expose it.

But making it genuinely interactive would be better.

---

## Do not cut the correction that `tensegrity_triangle` is not tensegrity

That is valuable source criticism.

A name is not evidence of mechanism.

Apply the same standard to the hall’s other claims.

---

## Do not cut the mobile’s lever arithmetic

The recursive computation is real and inspectable.

Just call it what it is:

> a geometry generated so its idealised moments balance.

That is enough.

---

## Do not cut the uphill-acceptance branch in Annealing

It is the algorithmic heart of the hall.

Correct the cold-limit language; keep the willingness to accept a worse local state.

---

## Do not cut basin hopping—but name it as an additional mechanism

The cabinet’s forced hop after stagnation is conceptually interesting:

> the optimiser admits that its own local policy can remain stuck.

It simply should not be folded silently into “this is simulated annealing.”

---

## Do not cut the Q caveat

The final sentence:

> the comparison is a choice about the model’s purpose, not a test that separates living matter from dead matter

is essential.

Move its discipline earlier into the labels and staging.

---

## Do not cut the Forge refusal

A physically stable low stack that fails the detector is one of the clearest demonstrations in the whole project of:

> **the world can produce a result; a rule still decides whether it counts.**

Protect it.

---

# 10. Reader-experience strengths to protect

## Discovery before naming

**Descent**  
STEP precedes gradient terminology.

**Forge**  
a low stable heap can be refused before success criterion is philosophically discussed.

**Catenary cable**  
the visitor can first trust the form, then discover it is drafted.

---

## Prediction before explanation

**Descent**  
where will the next step go?

**Descent two starts**  
will both endings be the same?

**Forge**  
will this quiet arrangement count?

These are stronger than the middle rooms’ more declarative openings and should guide revisions there.

---

## Productive mismatch

Form Finding is at its best when mismatch becomes evidence:

- visible downhill direction / no stored velocity;
- local minimum / not global minimum;
- convincing cable / not a catenary solver;
- current form / frozen history of a process;
- stable physical arrangement / failed authored success criterion.

Protect those.

---

## Returns with changed meaning

**Forces → Descent**  
a vector changes an address rather than velocity.

**Descent → Annealing**  
same idea of objective landscape, different search policy.

**Change → Relaxation**  
repeated update becomes form history.

**Forces → Equilibrium**  
force language returns as balance—but must be implemented carefully.

**Primitives / Polyhedra → Forge**  
pieces and collision become an authored form-recognition task.

---

# 11. Questions for the author

## 11.1 Is Catenary meant to be a room about matter solving, or a room about representations of famous matter-solved forms?

The current implementation strongly supports the second.

If the first is essential, a real chain/rope solver or dynamic minimal-surface experiment is needed.

My preference is the second, because the drafted cable versus analytic catenary comparison is already rich.

---

## 11.2 Do you want the Relaxation pass count to be a real visitor control?

The sequence objectives say:

> compare local relaxation rules.

That argues strongly for yes.

If so, the current decorative dial should become the actual comparison instrument.

---

## 11.3 Is Equilibrium intended as engineering evidence or as a gallery of structural ideas?

The current objects mostly support the latter.

One actual physical triangle-vs-square or balanced/mobile comparison could anchor the room and allow the others to remain speculative/sculptural.

Without that anchor, I would reduce the engineering certainty of the prose.

---

## 11.4 Should Q remain visible as “alive/dead” language in Annealing?

The final manuscript caveat argues against it.

I would present the physical/algorithmic differences first and introduce the Q interpretation as a proposal afterward.

---

## 11.5 Is the automatic basin-hop part of the annealing lesson, or legacy extra functionality?

If it is part of the lesson, name it separately.

If it is not, disable it for this hall so the visitor can actually compare annealing acceptance with Descent without a second escape mechanism entering silently.

---

## 11.6 Do you want the Forge optimiser to anticipate Machine Learning?

If yes, the bridge should wait until there is an actual model being trained.

If not, remove `TRAINING IS SETTLING` now and let the later ML sequence establish its own relation to optimisation.

---

# 12. Overall conclusion

Form Finding has a very strong sequence-level question:

> **What makes a form count as an answer?**

Descent answers:

> a local update and a stopping condition.

Catenary wants to answer:

> boundary conditions and a variational principle.

Relaxation adds:

> finite iteration and duration.

Equilibrium adds:

> relations that cancel.

Annealing adds:

> a search policy that can temporarily accept worsening.

Forge finally exposes:

> an authored success criterion that can reject a physically valid result.

That is an excellent curriculum.

The difficulty is that the retained middle chapters sometimes speak as though **form-finding has already happened physically merely because a mathematically or visually plausible form has been generated**.

The current source makes several distinct kinds of object:

- a drafted Bezier approximation;
- an analytic parametric surface;
- a finite iterative soft-body simulation;
- a frozen output;
- static geometry computed to satisfy an equation;
- a prescribed animation;
- a stochastic optimiser;
- a physically simulated stack judged by a detector.

Those distinctions should be the sequence’s material.

The highest-value work now is therefore:

1. **reframe Catenary around how each form is produced, not around an absent matter-solver;**
2. **make Relaxation’s pass count genuinely inspectable and move spawn-overlap artifacts to intentional positions;**
3. **stop Equilibrium from claiming physical proof where it currently has generated geometry/prescribed animation;**
4. **separate annealing, basin hopping and the Q interpretation, and let the shallow/deep comparison happen before “alive/dead” naming;**
5. **clean the Forge optimiser’s unearned machine-learning equivalence;**
6. **source the historical/scientific claims that remain;**
7. **headset-test the embodied encounters, because several retained chapters currently describe source audits more confidently than actual visitor experience.**

The reader-experience principle I would carry forward from Form Finding is:

> **Let the form appear first; then ask which rule, constraint, history or stopping condition made that form possible.**

And the structural principle is:

> **An emerged form is never evidence of one universal process. Ask whether it was solved, sampled, relaxed, prescribed, frozen, balanced, selected—or simply drawn.**
