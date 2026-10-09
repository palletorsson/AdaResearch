# QFEP Laboratory — 01 Review

Source-aware editorial and reader-experience review of the **QFEP Laboratory** sequence.

Basis: `qfeplaboratory-book.md`, `qfeplaboratory-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what each instrument actually computes, what each control reaches, and where source, map, registry and manuscript disagree.
2. **Reader experience:** where a visitor can discover a dependence before the project vocabulary names it, where the architecture has already recommended an answer, and whether the better intervention belongs to the artifact rather than to more prose.

The brief’s instruction is especially important here:

> **Treat QFEP as the project's research framework, not an established universal physical law.**

The current **final manuscripts already do this substantially better than the inherited sequence metadata and artifact identities**.

The strongest current eight-hall book arc is:

> **formula arithmetic → source uncertainty versus model fit → counted possibility → spatial recommendation → signed change → unstable “edge” model under audit → control/receiver audit → one explicitly authored body mapping**

A second formulation is:

> **The same symbols can function as arithmetic weights, spatial metaphors, labels, control signals or mappings into one body. QFEP becomes accountable only when each use says what quantity is actually computed, which receiver uses it, and which interpretation is supplied by the project rather than discovered by the model.**

That is a strong sequence.

The main work now is not to make QFEP more universal. It is to make the distinctions already present in the manuscripts more executable.

---

# 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **QFEP Introduction** | **Carries:** an unusually responsible opening. Four controls feed an explicit arithmetic expression, `F − λE + φ·0.3`; λ=0 gives a clean dependency test; two different knob arrangements can return similar totals; the manuscript explicitly says ΔE is fixed rather than measured and that the named “phase” is nearest to an authored reference tuple rather than an experimentally detected transition. **Gap:** the artifact still visually names those nearest-neighbour tuples “dominant phases” and the source identity calls them characteristic system phases. Its φ knob is also normalized to `[0,1]`, while later φ controllers use `[-1,1]`; the shared symbol therefore changes domain across the laboratory. **Next:** preserve the prose; make the intro display say **nearest project reference** rather than dominant phase, and either standardize φ’s domain or label the intro mapping explicitly as normalized. |
| **QFEP F Term** | **Carries:** the fixed-seed Bernoulli source is an excellent controlled instrument. Moving `p` re-thresholds the same stored random draws, so source probability changes without replacing the underlying random sequence; the manuscript correctly distinguishes Shannon source uncertainty from predictor error and from variational free energy. **Gap:** this hall is absent from museum-authored order, and its own readout contradicts the manuscript by printing `min H·N / N` and “incompressible” as if Shannon entropy were an exact lower bound on the shortest encoding of this particular finite displayed grid. The room is also named F while currently computing no actual prediction error/F-like quantity. **Next:** restore it, repair the entropy readout to describe the source/asymptotic quantity, and add the manuscript’s simple fixed predictor so identical H can coexist with very different prediction error. |
| **QFEP E Term** | **Carries:** a clear count-of-possibilities model. One branch per level gives one leaf, two gives 16, three gives 81; the manuscript explicitly states that `log(number of outcomes)` corresponds to treating leaves as equally possible and separates changing probabilities from changing the allowed set. **Gap:** the artifact/readout still says “more ways to be is more entropy” / “high entropy” without displaying that equal-weight assumption. The source already contains an excellent `prospect:pruned` state with 27 surviving leaves and 18 visible amber closures, but the room does not expose it interactively even though the manuscript proposes showing excluded futures. **Next:** add **ASSUMING EQUAL LEAF WEIGHTS** to the instrument and expose the existing PRUNED/CLOSED-FUTURE state rather than explaining absence only in prose. |
| **QFEP Lambda Spectrum** | **Carries:** the manuscript successfully turns the hall against its own inherited thesis. The architecture itself authors “order” as a regular frozen wall, “chaos” as jittered/animated cubes, and a glowing λ≈0.35 route labelled `life walks here`; the final text explicitly calls that route a curatorial recommendation rather than a discovered physical threshold. **Gap:** the recommendation cannot be moved independently. `lambda_value` controls not only the walkway but also pushes nearby rows aside and recolours/emphasises rows around the preferred band, so changing it would change both the architecture and its recommendation. **Next:** separate **STRUCTURE** from **RECOMMENDATION**: keep the spectrum fixed and add a movable lit-route control so visitors can test whether architecture can make another λ feel “right” without changing the underlying forms. |
| **QFEP Phi Term** | **Carries:** the signed control is genuinely legible. φ crosses zero, magnitude grows on either side, and its local particles change direction/colour/amount. The manuscript is careful that these particles represent the slider’s value rather than measuring openness, life or queerness; the nearby transforming pattern is also correctly identified as independent of φ. **Gap:** the artifact prejudges the question in its permanent labels—**RESIST / NEUTRAL / EMBRACE**—and its source truth says positive φ is “the queer parameter.” The book asks whether direction can exist before improvement is assigned, but the rail assigns improvement before the experiment begins. **Next:** for this lesson, begin with **NEGATIVE / ZERO / POSITIVE** (or use the existing calibration-dispute vocabulary) and introduce resist/embrace only as one project interpretation afterward. |
| **QFEP Edge Of Chaos** | **Carries:** conceptually this is the sequence’s most important self-audit. λ changes feed, kill and diffusion coefficients together; RESEED changes initial condition; SIM SPEED changes update count; the manuscript explicitly refuses to infer physical chaos, criticality or life from visual activity and proposes a defined observable plus timestep study. **Gap:** source shows the numerical problem is much stronger than the text states. The interactive/unlocked system uses an unnormalised 5-point Laplacian at `dt=1`; the source’s own stability analysis says this is unstable across the entire λ range. Only the fixed `frozen` and `chaos` capture variants use the repaired normalized/stable integrator. Meanwhile the live readout still labels λ bands **FROZEN / EDGE OF CHAOS / CHAOS** as if they were observed regimes. **Next:** run the interactive study on the stable integrator first, separate model timestep from SIM SPEED, and replace regime words with neutral λ/rule labels until a defined measurement supports a transition claim. |
| **QFEP Sandbox** | **Carries:** potentially a very valuable audit hall. It asks the right question: how do you distinguish a control that changes itself from a control that reaches another system? The final manuscript correctly says the room’s surrounding systems are not reliably connected and refuses to treat coincident motion as evidence of causation. **Gap:** this hall is absent from museum-authored order, and the source bundle omits `qfep_reactor` / `reactive_particle_field`, so the exact receiver wiring cannot be independently audited here. Registry DNA records a dead historical driver caused by group-name mismatch, which would make the hall’s failure particularly relevant if still current. **Next:** restore the hall explicitly as a **WIRING AUDIT**; include the receiver sources in future bundles, and ideally provide a simple UNWIRED/WIRED comparison with a receiver readout showing the value it actually consumed. |
| **QFEP Synthesis** | **Carries:** the correct kind of finale: the specimen has its **own** local λ/φ controls, and the manuscript names the mappings rather than pretending nature supplied them. Source supports λ→stiffness and φ→damping/drag, and the text correctly says a responsive body is not an assay of queerness or life. **Gap:** one central mapping does not behave as described during runtime. `_apply_lambda()` gives pressure a peak at λ=.5, but every frame in `0.3 < λ < 0.7`, `_process()` overwrites `pressure_coefficient` with `base_pressure * (1 + breathe)`, erasing that edge-boost baseline. Thus the manuscript’s “pressure has a designed peak near the middle” is not the continuing physics the visitor sees. Source labels also still say **EDGE OF CHAOS / Max complexity / Life emerges**. **Next:** make breathing modulate around the λ-derived pressure baseline instead of replacing it, and replace biological/regime labels with the explicit mechanical quantities the chapter actually tests. |

---

# 2. The largest structural issue: the eight-hall book is currently a six-hall museum route

## Declared/current book order

1. QFEP Introduction  
2. **QFEP F Term**  
3. QFEP E Term  
4. QFEP Lambda Spectrum  
5. QFEP Phi Term  
6. QFEP Edge Of Chaos  
7. **QFEP Sandbox**  
8. QFEP Synthesis

## Museum-authored order

1. QFEP Introduction  
2. QFEP E Term  
3. QFEP Lambda Spectrum  
4. QFEP Phi Term  
5. QFEP Edge Of Chaos  
6. QFEP Synthesis

The current route omits:

- **QFEP F Term**
- **QFEP Sandbox**

Both omissions damage the book’s logic.

## Missing F Term breaks the F/E distinction

Introduction ends:

> “The next room starts with a smaller, computable question: what makes an outcome easy or difficult to predict?”

That is the F hall.

The E hall later says:

> “Compare this with the bit workbench. There, the probability changed while the possible bit values remained the same.”

If the museum skips F, the E manuscript asks visitors to compare against an instrument they did not encounter.

More importantly, the two halls perform different work:

**F hall**
- same binary outcome alphabet;
- change source probability;
- compute `H(p)`;
- distinguish source uncertainty from predictor mismatch.

**E hall**
- change the number of allowed branch continuations;
- count final possibilities;
- compute `log(futures)` under equal-weight assumption.

Those are not redundant entropy rooms.

They make the sequence’s strongest distinction between:

> **how likely outcomes are**

and:

> **which outcomes the model contains at all.**

Restore F.

## Missing Sandbox removes the explicit control/receiver audit

Edge Of Chaos ends:

> “The sandbox extends the question of control across several objects.”

Sandbox asks:

> when is a changing number actually an input to another system?

Synthesis then says:

> its own specimen supplies a smaller completed connection.

That progression is excellent:

> **claimed global parameter → broken/uncertain wiring → one local explicit mapping**

Skipping Sandbox makes the Synthesis specimen look like a direct fulfilment of the general theory rather than a deliberately smaller, accountable model.

Restore Sandbox.

## Route verification remains necessary

The brief correctly warns that `map_authored` mismatch is not automatic proof that raw utilities are broken.

The maps themselves use `next_in_sequence`.

After authored-order repair, walk:

> Intro → F → E → Lambda → Phi → Edge → Sandbox → Synthesis

before revising transitions.

---

# 3. Sequence structure

QFEP Laboratory is strongest when it moves **from symbol toward receiver**, not when it moves from “order” toward “life.”

## 1. Introduction — arithmetic before ontology

The first room should remain exactly what the final manuscript calls it:

> an operational introduction to one project expression.

The source computes:

```text
QFE = F - λE + φ × 0.3
```

No living system is measured.

No ΔE is observed.

No physical phase is detected.

The phase display performs nearest-neighbour classification against seven authored reference tuples.

This is a useful first lesson:

> a formula can be manipulated before any claim is made that its terms have been operationally measured in the world.

The visitor can also discover information loss:

> different tuples can produce similar scalar totals.

That is a strong beginning.

## 2. F Term — uncertainty is not model fit

This room is badly named only if we expect it to “be F.”

The current manuscript is more sophisticated.

It says:

> before claiming F/free energy, begin with a quantity we can actually compute.

The Bernoulli source gives a precise uncertainty measure.

Then the proposed zero-predictor comparison can introduce mismatch.

That would allow the visitor to see:

> p=.1 and p=.9 have equal H  
> while a predictor that always says 0 performs very differently.

That is an excellent bridge toward “fit” without pretending Shannon entropy is F.

## 3. E Term — possibility count is another operation

The fan does not change a Bernoulli probability.

It changes:

> how many continuations the diagram contains.

Under equal weights:

> entropy ∝ log(number of leaves).

This lets QFEP’s “possibility space” language be handled carefully:

> available alternatives and probability over those alternatives are different descriptions.

The pruned state can make a further distinction:

> unavailable from the beginning  
> versus  
> visibly closed.

## 4. Lambda Spectrum — preference becomes architecture

This hall should remain a critique of its own spatial rhetoric.

The source is not discovering a special λ.

It literally builds:

- orderly frozen lattice at one side;
- hot jitter/animation at the other;
- an emissive route at a chosen λ;
- green edge tint around the chosen band;
- floor text saying **life walks here**.

The manuscript correctly says:

> this is a curatorial argument.

The next step is to let the recommendation itself move while the staged spectrum does not.

## 5. Phi Term — sign before value judgement

The phi rail has a useful mechanical property:

- negative;
- zero;
- positive.

That is already enough.

The cultural/project interpretation:

- resist;
- embrace;
- queer signature

should arrive after the signed relation is understood.

The independent transforming pattern is also useful because it prevents:

> “two things change near each other”

from silently becoming causation.

## 6. Edge Of Chaos — a model must survive its own numerics

This is the sequence’s crucial turn.

A named λ regime is not evidence.

A striking pattern is not evidence.

A source code update is not evidence if the integrator destroys the distinction among parameter settings.

The current final text already recognises this.

Source inspection makes the point more severe:

> the interactive/default numerical update is unstable over the entire parameter range.

This should become the laboratory’s central technical repair.

## 7. Sandbox — controls need receivers

The question changes from:

> what does this parameter mean?

to:

> **who actually uses it?**

This is a very strong Ada move.

A slider’s colour/particles prove only that:

> the slider received its own value.

A nearby moving object proves nothing without:

- a connection;
- an input readout;
- controlled timing/reset.

The room can therefore work as an explicit **wiring audit** even before a complete global QFEP system exists.

## 8. Synthesis — one local body, one explicit mapping

The final specimen is strongest precisely because it gives up universality.

It says:

> **for this body**, λ is mapped to these mechanical/material properties, and φ to these others.

The visitor can now compare:

- resistance to deformation;
- persistence of motion;
- pressure;
- damping;
- drag.

That is a much better ending than:

> here is life at the edge.

The body does not verify QFEP.

It makes one implementation of QFEP inspectable.

---

# 4. Reader-experience lens

## QFEP Introduction — Four controls, one result

### Curiosity

The opening question is strong:

> can different arrangements produce the same scalar result?

This is already more interesting than explaining the formula term-by-term.

The visitor is asked to discover **compensation**.

### Discovery

λ=0 is the right special case.

Move E:

> E slider changes, total does not through the `−λE` term.

Then raise λ and repeat.

One dependency becomes bodily obvious.

This is excellent.

The second discovery is:

> one scalar result loses information about how it was composed.

The radar makes that loss visible.

### Phase-name timing

The source continuously detects the closest of seven authored phase signatures by Manhattan distance and labels it:

> `dominant phase`.

The manuscript already demotes this:

> “proximity to a project example.”

Good.

I would go one step further in the artifact.

Visitor-facing label:

> **NEAREST PROJECT REFERENCE: lambda_edge**

rather than:

> **dominant phase: lambda_edge**.

“Phase” implies the model discovered a state transition.

It did not.

### φ domain discrepancy

The Intro workbench reads all four sliders as normalized `[0,1]`.

Later:

- Phi Term φ ∈ `[-1,1]`;
- Synthesis φ ∈ `[-1,1]`.

The final Synthesis text acknowledges that the ranges differ.

That is honest.

Still, this should be visible earlier.

Either:

- standardize φ throughout; or
- label intro:
  > **φ weight (normalised 0…1 in this console)**.

Otherwise the same symbol quietly changes mathematical domain halfway through the laboratory.

### Return

Foundations Crisis’s synthesis formula returns, but now as arithmetic rather than thesis.

That is the right opening.

---

## QFEP F Term — Predictable according to what model?

### Curiosity

The p=.1 versus p=.9 comparison is excellent.

Both distributions have equal binary entropy.

A fixed “always zero” predictor would have radically different error.

This is exactly the distinction QFEP needs before invoking fit/free energy.

### Controlled random evidence

The source is well designed for this comparison.

It seeds one RNG once and stores fixed `[0,1)` draws.

Changing p changes only the threshold applied to those draws.

The same random evidence is therefore reclassified.

Excellent.

### Artifact/source contradiction: “min bits”

The manuscript says:

> H under the source model is **not** a guarantee about the exact shortest encoding of this displayed grid.

The artifact readout says:

```text
min H*N / N
```

and at H≈1:

> **incompressible**.

The source identity goes further:

> those bits cannot fall below the Shannon floor.

For a particular finite realised bit string, that is too strong.

`N·H(p)` belongs to the source/distribution/coding theorem context—expected/asymptotic coding performance under assumptions—not a certified minimal description length of this one displayed sample.

This is especially unfortunate because the manuscript has already made the right distinction.

### Artifact proposal

Readout:

```text
SOURCE H(p) = 0.469 bits/symbol
N × H(p) ≈ 120 bits
(distribution quantity — not measured file size)
```

At p=.5:

```text
SOURCE H(p) = 1.000 bits/symbol
N × H(p) = 256 bits
```

Remove:

> min  
> incompressible

unless the instrument actually runs a specified code/compressor on the sample.

### Add the predictor the manuscript already wants

Beside the source H readout:

> **PREDICT 0**

show:

- expected error under source = p;
- observed errors in the displayed finite grid.

Then p=.1 and p=.9 become the key demonstration:

> same H  
> opposite predictor fit.

This gives the hall a concrete **fit/prediction** quantity without pretending it is already variational free energy.

### Route

This hall must be restored before E.

---

## QFEP E Term — Counting what could happen

### Curiosity

The fan makes multiplicative possibility count bodily.

One → 16 → 81 is easy to predict.

Good.

### Discovery

The most important sentence in the manuscript is:

> the leaves being drawn does not make them equally likely.

That protects the simple `S = log(futures)` display from becoming a universal entropy definition.

### Source/readout mismatch

The source identity says:

> “possibility itself is what S measures”

and labels:

> `WIDE FAN — high entropy`.

The code contains no transition probabilities over leaves.

So the high-entropy wording is only justified under the book’s equal-weight assumption.

The instrument should say that.

### The source already implements the manuscript’s future extension

`prospect:pruned` builds:

- branch factor 3;
- 27 surviving leaves;
- 18 visible amber closed stumps;
- `FUTURES = 27 of 81`.

This is excellent.

It makes:

> “never offered”

different from:

> “offered and then closed.”

No new conceptual mechanism is needed.

Expose:

> **PROSPECT — THREAD / FAN / PRUNED**

or at minimum:

> **CLOSE FUTURES**.

### Timing

Very good.

The equal-weight assumption should arrive on the instrument at the same time the entropy number arrives.

---

## QFEP Lambda Spectrum — The path the hall recommends

### Curiosity

This hall is intentionally seductive.

A glowing path says:

> stand here.

The best reader question is not “what is λ?”

It is:

> why did I assume the lit path was the preferred answer?

The manuscript handles this exceptionally well.

### Source makes the recommendation explicit

The source literally writes on the floor:

> `λ = 0.35 — life walks here`.

Its identity says:

> “life only on the narrow band between.”

The architecture also codes the ends:

**order**
- frozen;
- repetitive;
- cold blue.

**chaos**
- jittered positions;
- random orientation;
- variable scale;
- moving drifters;
- hot magenta/orange.

The central band is tinted green and pulses.

This is not a neutral measurement display.

It is a designed argument.

Excellent material—provided the chapter keeps naming it as such.

### Best next artifact

The manuscript proposes:

> move the lit route while keeping structures fixed.

The existing source cannot do that with `lambda_value`.

Changing `lambda_value` also:

- moves the path;
- shifts nearby rows away from it;
- changes edge-distance weighting/tint.

So the recommendation and the exhibit are entangled.

Add a separate:

> **RECOMMENDATION POSITION**

that controls only:

- lit floor;
- edge strips;
- label.

Keep the underlying spectrum geometry fixed.

Then visitors can ask:

> if the same hall tells me λ=.2 is the special path, does it begin to feel special?

That is a much more powerful queer/critical experiment than another claim that the middle is liberating.

### Return

The project’s values become architecture rather than mathematics.

That is exactly why this hall belongs.

---

## QFEP Phi Term — Giving change a sign

### Curiosity

The core operation is very good:

> cross zero.

The visitor can separate:

- sign;
- magnitude.

This is enough to make φ operational.

### Reader-timing conflict

The source labels the rail:

- RESIST;
- NEUTRAL;
- EMBRACE.

The manuscript asks:

> “Can change have a direction without that direction already meaning improvement?”

But the physical rail has already given positive direction a normatively positive verb.

The source identity further says:

> positive φ is the queer signature.

That makes the answer arrive before the question.

### Artifact proposal

For this lesson only:

**initial marks**
- `−`
- `0`
- `+`

or:

- NEGATIVE
- ZERO
- POSITIVE.

Then after the visitor has compared direction:

> **PROJECT READING: RESIST / EMBRACE**

can be revealed.

The source’s `calibration:dispute` mode may also help because it admits several proposed preferred positions rather than one natural answer.

### Transforming pattern

This is a good nearby counterexample.

It changes continuously through its own wave field.

φ does not control it.

The manuscript says so.

Do not rush to wire it merely to satisfy “interactive” expectations.

Its independence teaches:

> same theme / no causal connection.

### Return

Change’s directional history returns as a signed project weight.

---

## QFEP Edge Of Chaos — A pattern and the way we drive it

### Curiosity

The chapter’s current opening is strong:

> keep simulation speed fixed; vary λ; reseed; describe a local feature instead of trusting the regime label.

This is exactly what a serious “edge of chaos” hall should ask.

### The source’s own audit is devastating—and useful

The live/unlocked solver uses:

- raw four-neighbour sum minus `4×centre`;
- diffusion A from 0.8 to 1.2;
- explicit Euler `dt=1.0`;
- per-step clamping to [0,1].

The source comments derive the stability problem:

> for the worst grid mode, `D·dt < .25` is required.

At D=.8–1.2 and dt=1:

> **the entire interactive λ range violates that bound**.

The source says the result saturates toward clamp-driven patterns and can erase the feed/kill distinctions the slider is supposed to reveal.

This is not merely:

> “some settings may be affected by timestep.”

It is:

> **the current interactive numerical method is not a trustworthy experiment for comparing the authored λ regimes.**

### Partial repair currently applies only to still/capture poles

The code contains `_simulate_step_stable()`:

- normalized neighbour average minus centre;
- dt=.6.

But `_process()` uses it only when tenure is:

- frozen;
- chaos.

Default/unlocked—the actual interactive lesson—continues using the unstable original step.

So capture variants are numerically repaired while the learner-facing experiment is not.

### High-value artifact fix

Use the stable formulation for **all tenures**.

Then separate:

- **DT** — numerical timestep;
- **SIM SPEED** — how quickly model time advances relative to visitor time.

At present SIM SPEED merely changes how many fixed-size numerical updates happen every rendered frame.

It is not a timestep control.

A strong lesson could offer:

> DT .6 / .3

with equal model duration for comparison.

That would directly perform the manuscript’s proposed next test.

### Regime names

The readout chooses:

- FROZEN if λ<.2;
- EDGE OF CHAOS if .2≤λ<.55;
- CHAOS above .55.

These are threshold labels based on the knob value.

They are not measured regimes.

The manuscript tells the visitor not to rely on them, but they remain visually authoritative.

For the scientific lesson:

> `λ LOW / λ MID / λ HIGH`

is safer.

If the old names remain, prefix:

> **PROJECT LABEL:**

### What not to do

Do not try to prove a universal edge of life after stabilising the solver.

First measure one defined property:

- spatial correlation;
- feature persistence;
- entropy of a specified field;
- variance;
- autocorrelation time.

Then ask how it changes across λ and seed.

The final manuscript already points in that direction.

---

## QFEP Sandbox — Where the control reaches

### Curiosity

This room asks one of the sequence’s best questions:

> how do you know a slider changed a system rather than itself?

That is the correct question after Edge.

### Current book is appropriately skeptical

The manuscript says:

> lambda and phi provide reliable local feedback.

It refuses to infer that the surrounding reactor/particle field received their values.

That is good.

### Source-package limitation

Primary roles contain only:

- lambda_slider;
- phi_slider.

The surrounding:

- `qfep_reactor`;
- `reactive_particles`;
- `qfep_formula_3d`

are secondary.

Their implementation sources are not in this snapshot.

So the current package cannot independently verify receiver wiring.

### Registry DNA points to exactly the failure the book describes

The current registry record for `qfep_reactor` says its old connector looked for:

> group `qfep_slider`

while the actual sliders register themselves as:

- `qfep_lambda_controllers`;
- `qfep_phi_controllers`.

According to that record, the reactor therefore never received the values and sat at λ=.4.

Because `qfep_reactor.gd` is not bundled, treat this as:

> **CAPTURE/registry evidence requiring source inclusion**,

not independently re-proven source.

### Why this hall is worth restoring even before repair

It can become an explicit:

> **WIRING AUDIT**

The visitor can see:

- slider value changed;
- local slider particles changed;
- surrounding movement continued;
- no receiver input confirms causal connection.

That is excellent Ada material.

### Best future artifact

Add:

> **WIRE / UNWIRE**

to one receiver only.

The receiver should print:

```text
received λ = ...
received φ = ...
```

and one controlled observable.

Then the visitor can compare:

- coincident motion;
- demonstrated input;
- measured response.

This is more valuable than trying to make the entire room globally responsive at once.

---

## QFEP Synthesis — What should this body keep?

### Curiosity

This is the right kind of ending.

One object.

Two local controls.

A clear body response.

The whole theoretical vocabulary contracts into an inspectable mapping.

### Source-supported mappings

λ setter:

- stiffness linearly .9 → .1;
- pressure gets an intended midrange boost;
- colour/emission/shader also change.

φ setter:

- damping .2 → .001;
- drag .3 → 0;
- subsurface scatter changes.

The manuscript correctly says:

> these mappings are authored for this specimen.

Excellent.

### Major source contradiction: pressure peak is overwritten

`_apply_lambda()`:

```gdscript
edge_boost = 1 - abs(lambda - .5) * 2
pressure = base_pressure * (1 + .5 * edge_boost)
```

So intended baseline pressure peaks at:

> 1.5 × base at λ=.5.

But `_process()` runs every frame.

For:

> `.3 < λ < .7`

it replaces pressure with:

```gdscript
base_pressure * (1 + breathe)
```

where breathing amplitude rises roughly .02 → .10 with λ.

Thus in the exact “edge” region:

- the designed 1.3–1.5 baseline pressure is lost on the next frame;
- mean pressure returns to 1.0×base;
- only breathing oscillation remains.

The manuscript says:

> “pressure has a designed peak near the middle.”

That is true only momentarily when λ is set, not of the continuing runtime state.

### Artifact fix

Keep the λ baseline and breathe around it.

For example conceptually:

```text
lambda_pressure =
    base_pressure * (1 + 0.5 * edge_boost)

pressure =
    lambda_pressure * (1 + breathe)
```

Then:

- midrange pressure really remains elevated;
- breathing is another modulation;
- λ/φ comparison is more interpretable.

### Named states still overclaim

The source label says:

> EDGE OF CHAOS  
> Max complexity  
> Life emerges.

Registry says:

> THIS IS QFEP EMBODIED.

Those claims are much stronger than the final manuscript.

Replace the state panel with mechanics:

```text
λ = .50
stiffness = ...
pressure = ...

φ = +.20
damping = ...
drag = ...
```

Optional project interpretation can sit below:

> **QFEP preset: EDGE**

not:

> life emerges.

### A second subtlety: timed breathing is a third variable

The manuscript already warns:

> watch long enough to separate persistent response from timed breathing.

Good.

After fixing pressure baseline, consider an optional:

> **BREATH ON/OFF**

so λ/φ mechanical mappings can be inspected without the additional periodic driver.

Not necessary for first revision, but scientifically useful.

### Return

Soft Bodies’ stiffness/damping/pressure distinctions return as a deliberate QFEP mapping.

That is the right ending.

---

# 5. Five high-value changes

## 5.1 Restore QFEP F Term and QFEP Sandbox to the museum route — and repair the misleading λ placements before restoration

**Evidence type:** CAPTURE + SOURCE

### Current orders

Declared:

> Intro → F → E → Lambda → Phi → Edge → Sandbox → Synthesis

Museum-authored:

> Intro → E → Lambda → Phi → Edge → Synthesis

### Why F matters

E explicitly refers back to the bit workbench.

F distinguishes probability/uncertainty from predictor fit.

### Why Sandbox matters

Sandbox distinguishes a control’s **own feedback** from a proven **receiver connection**.

Synthesis then provides the smaller completed connection.

### Additional source problem exposed by restoration

Several maps place `lambda_slider` with tokens such as:

- F Term: `#locked:0`
- E Term: `#value:1.0`
- Edge: `#locked:0.4`

But `lambda_slider.gd::apply_grid_config()` currently reads only:

> `calibration`.

Its own source comment explicitly says existing `#locked:` and `#value:` keys do **nothing here**.

Therefore these secondary λ sliders do not currently enact the map’s advertised values/locks.

This is especially serious in F:

- the physical slider sits near the entrance;
- map text says `λ=0 PURE ORDER`;
- source slider remains the default ≈.4 unless another external mechanism changes it.

### Proposal

1. Restore F and Sandbox to authored order.
2. Either:
   - implement `value` / `locked` in `lambda_slider`; or
   - remove those misleading secondary sliders from the halls.
3. Verify all eight `next_in_sequence` transitions.
4. Treat Sandbox explicitly as **WIRING AUDIT** until a receiver is demonstrably connected.

### Reason

This repairs both the conceptual sequence and a concrete room-level contradiction that would become more visible once F is restored.

---

## 5.2 F Term — fix the Shannon readout and add the predictor that makes “fit” computable

**Hall:** `QFEP_F_Term`  
**Artifact:** `shannon_workbench` at `(1,3)`

### Original manuscript

> “H describes uncertainty under that source model; it is not a guarantee about the exact shortest encoding of this particular displayed grid.”

Excellent.

### SOURCE contradiction

`shannon_workbench.gd::_refresh_readout()` prints:

```text
min H*N / N
```

and at H≈1:

> `incompressible`.

Source identity likewise says the displayed bits:

> “cannot fall below” that Shannon floor.

That language overstates what `H(p)` establishes about **this particular finite sample**.

### Artifact proposal A — correct the readout

Use:

> **SOURCE H(p) = ... bits/symbol**  
> **N·H(p) ≈ ... bits for N source symbols**  
> **distribution quantity — not measured compressed length**

Do not print `min` / `incompressible` for the individual sample unless a specified coding/compression procedure is actually run.

### Artifact proposal B — add the manuscript’s zero predictor

Display beside the same fixed-draw grid:

> **PREDICTOR: always 0**

Read:

- expected mismatch = `p`;
- observed sample mismatches = count of 1s / N.

Then compare:

> p=.1 versus p=.9.

Both have the same H.

The predictor performs oppositely.

### Reason

This turns the F hall into a real bridge:

> source uncertainty  
> ≠  
> model mismatch.

It also makes the hall’s cautious title “Predictable according to what model?” executable instead of merely explanatory.

---

## 5.3 Edge Of Chaos — repair the interactive integrator before reading λ regimes

**Hall:** `QFEP_Edge_Of_Chaos`  
**Artifact:** `edge_of_chaos_unlocked` at `(13,4)`

### Original manuscript

> “some settings can be dominated by the size of its computational step…”

### SOURCE finding

For the default/unlocked interactive path:

- unnormalised 5-point Laplacian;
- `dt = 1`;
- diffusion A = .8…1.2.

The source’s own stability analysis states the bound is approximately:

> `D·dt < .25`

for its raw stencil.

Thus the entire interactive range is outside the bound.

The source explicitly says clamp saturation erased differences between parameter extremes in earlier evidence.

A repaired method already exists:

> `_simulate_step_stable()`

but it is used only for the fixed `frozen` / `chaos` tenure variants, not the interactive lesson.

### Proposal

1. Use the stable normalized-Laplacian update for the interactive/unlocked mode.
2. Separate:
   - numerical **DT**;
   - visitor-facing **SIM SPEED**.
3. Compare equal model duration when testing DT.
4. Change the regime readout from:
   - FROZEN / EDGE OF CHAOS / CHAOS
   to:
   - λ LOW / MID / HIGH
   or prefix with:
   - **PROJECT LABEL**.
5. Only reintroduce “transition/criticality” after defining and measuring an observable.

### Reason

The room cannot be a controlled λ experiment while the numerical scheme itself dominates the result.

This is the highest-priority technical repair in the sequence.

---

## 5.4 Lambda Spectrum — separate the recommended path from the spectrum it recommends

**Hall:** `QFEP_Lambda_Spectrum`  
**Artifact:** `lambda_hall` at `(11,11)`

### Current source

`lambda_value` simultaneously controls:

- walkway x-position;
- edge-strip position;
- floor inscription;
- which rows are pushed aside to create clearance;
- which rows receive green edge weighting/pulse emphasis.

The hall therefore cannot test:

> “Would I prefer another location merely because the architecture highlighted it?”

because moving the recommendation also alters the exhibit around it.

### Original manuscript

> “For a future comparison, move the lit route while keeping the structures fixed.”

This is exactly the right experiment.

### Artifact proposal

Split the current one number into two.

**STRUCTURE SPECTRUM**
- fixed once built;
- regular → increasingly jittered/moving across x.

**RECOMMENDATION**
- independently movable lit strip;
- label/colour only;
- no row displacement or retinting.

Control:

> **RECOMMEND**

or a simple slider.

Optional modes:

- NONE
- λ=.2
- λ=.35
- λ=.7.

### Reason

This converts a critical paragraph into direct evidence:

> a spatial invitation can manufacture preference without changing the underlying alternatives.

For this project, that is a more important finding than defending one “correct” λ.

---

## 5.5 Synthesis — preserve the λ-derived pressure baseline while breathing, and replace regime biology with mechanical readout

**Hall:** `QFEP_Synthesis`  
**Artifact:** `queer_morphology_specimen` at `(3,1)`

### Original manuscript

> “LAMBDA changes the mapping to stiffness and pressure.”

> “pressure has a designed peak near the middle…”

### SOURCE contradiction

`_apply_lambda()` gives a midrange pressure boost.

But `_process()` replaces pressure each frame inside `.3 < λ < .7` with:

```gdscript
base_pressure * (1 + breathe)
```

erasing the λ-dependent baseline.

### Artifact proposal

Retain a stored λ-derived pressure:

```text
lambda_pressure = base_pressure × authored_edge_mapping
```

and then:

```text
pressure = lambda_pressure × periodic_breathing_multiplier
```

Show live mechanical values:

- stiffness;
- pressure;
- damping;
- drag.

Replace:

> EDGE OF CHAOS / Max complexity / Life emerges

with:

> **QFEP PRESET: EDGE**  
> plus the actual mechanical quantities.

Optional later:

> **BREATH ON/OFF**

for controlled comparison.

### Reason

The Synthesis room is strongest because it gives up universality and shows one authored mapping.

Its runtime physics should therefore actually preserve the mapping the text asks the visitor to inspect.

---

# 6. Sequence-level metadata should catch up with the final manuscripts

This is source/curation maintenance rather than a sixth high-value revision.

The current `sequence.json` still says:

> **Life exists at λ ≈ 0.3–0.5.**

It defines:

- F = prediction error / order-seeking / surprise minimisation;
- E = disorder / freedom from pattern;
- λ = crystallisation ↔ dissolution;
- φΔE = queer signature;
- edge of chaos = where adaptation happens.

The final manuscripts are considerably more accountable.

For example:

- Introduction says the console is arithmetic, not a living-system measurement.
- F says Shannon uncertainty, prediction error and variational free energy are not interchangeable.
- E states that equal weights are an assumption.
- Lambda says the lit middle is a curatorial argument, not universal physics.
- Phi says sign does not decide which history deserves continuity.
- Edge says the pattern cannot certify chaos/criticality/life.
- Sandbox says connection must be demonstrated.
- Synthesis says the responsive specimen is not a life/queerness assay.

Those statements should become canonical.

## Proposed editorial intention

> **Investigate the project’s QFEP vocabulary through distinct operational roles: arithmetic weights, probability models, possibility counts, spatial recommendations, signed controls and explicit mappings into one body. Keep each model’s measured quantity separate from the project interpretation attached to it.**

## Proposed objectives

- Manipulate the QFEP expression as arithmetic without treating its terms as automatically measured physical quantities.
- Distinguish Shannon source uncertainty from prediction error and from any later free-energy interpretation.
- Distinguish changing outcome probabilities from changing the set of available outcomes.
- Identify when a spatial layout recommends a λ value rather than measuring it.
- Treat φ first as a signed weight before assigning positive/negative normative meanings.
- Test a reaction–diffusion parameter route only under numerically stable integration and a defined observable.
- Verify that a control reaches a receiver before interpreting the receiver’s motion as a response.
- Compare explicit λ/φ mappings into one body while keeping those mappings project-specific and revisable.

## Proposed sequence truth

> **QFEP is an Ada Research framework for asking how fit, uncertainty and change are weighted in a model. The laboratory does not establish a universal λ or φ for life; it makes the project’s mappings inspectable.**

---

# 7. Source / artifact discrepancies

## 7.1 Introduction’s φ uses a different domain from later φ

`QFEPBalanceWorkbench` polls four normalized sliders and clamps all of:

- F;
- E;
- λ;
- φ

to `[0,1]`.

`PhiSlider` and `QueerMorphologySpecimen` use:

> φ ∈ `[-1,1]`.

The final Synthesis manuscript acknowledges this.

The introduction should label its φ as a normalized weight or the domains should be unified.

---

## 7.2 Introduction’s “phase” is nearest authored tuple, not detected physical regime

`_detect_phase()` computes Manhattan distance to seven hard-coded tuples.

The manuscript is accurate.

Source identity/readout language such as:

> dominant phase

should be weakened.

---

## 7.3 Introduction’s ΔE is fixed at 0.30

This is source-supported and correctly stated in the manuscript.

Do not let later descriptions call the intro result a measured rate of entropy change.

---

## 7.4 `lambda_slider` ignores the map’s existing `#locked` and `#value` keys

This is a concrete source/map mismatch.

`apply_grid_config()` only handles:

> `calibration`.

The source comment explicitly says:

> existing `#locked:` and `#value:` tokens do nothing here.

Affected placements include:

- F Term `#locked:0`;
- E Term `#value:1.0`;
- Edge `#locked:0.4`.

Thus source map rhetoric such as:

> λ=0 PURE ORDER / λ=1 DISSOLUTION

is not currently guaranteed by those physical sliders.

---

## 7.5 Lambda slider source still hard-codes the project’s old edge/life ontology

Its labels and API define:

- Crystal;
- Stable;
- Edge of Chaos (adaptive);
- Creative;
- Dissolution;
- `is_at_edge()` = .3–.5.

That is project vocabulary.

The final manuscripts correctly treat it as authored calibration, not discovered universal regimes.

---

## 7.6 Phi slider similarly embeds a normative direction

Source:

- RESIST;
- NEUTRAL;
- EMBRACE;
- Queer Signature.

The manuscript’s signed-weight interpretation is more precise.

---

## 7.7 Shannon Workbench fixed draws are excellent experimental control

`draw_seed = 1234`.

The same stored random values are thresholded as p changes.

This is a strong source/text match.

Protect it.

---

## 7.8 Shannon readout/source identity overstates finite-sample compression

As detailed above.

The manuscript already corrects this.

Fix the artifact.

---

## 7.9 Shannon `plate_scale` export is stale/unapplied in normal build

The source contains a long latent-bug note:

- export default says 2.0;
- `_ready()` build path does not apply it;
- only explicit config changes scale.

This is not central to the chapter’s concept, but it is another example of:

> inspector declaration ≠ built artifact.

Keep it in technical maintenance, not main prose unless it affects reach/headset scale.

---

## 7.10 Entropy Fan computes natural `log(futures)` without probabilities

That is a valid log-count under equal-weight interpretation.

The final manuscript says the assumption.

The source identity/readout should say it too.

---

## 7.11 Entropy Fan already implements a visible closed-future condition

`prospect:pruned` is exactly the chapter’s proposed future experiment.

Promote it.

---

## 7.12 Lambda Hall is explicitly a designed ideology of the middle

Source text itself says:

> life only on the narrow band.

Its built geometry makes:

- one side frozen/orderly;
- one side hot/jittered/moving;
- the chosen band green/pulsing/lit.

The final manuscript correctly interprets this as curatorial argument.

Source identity should catch up.

---

## 7.13 Phi Transforming Pattern is completely independent of the phi slider

The source has no phi input.

It follows its own time-dependent scalar wave field.

The manuscript correctly says so.

---

## 7.14 Transforming Pattern’s old identity equates positive phi with life/becoming

The current chapter appropriately demotes this to one representational association.

Keep the mechanism first:

> prescribed waves under an independent clock.

---

## 7.15 Edge Of Chaos interactive integrator is unstable across the current λ range

As detailed above.

This is the central technical finding of the bundle.

---

## 7.16 Edge’s stable solver currently applies only to capture/pole variants

`_process()` calls stable update only for:

- frozen;
- chaos.

Default unlocked remains original unstable update.

Repair the learner-facing path.

---

## 7.17 Edge SIM SPEED is update-count-per-frame, not timestep

`sim_steps` changes:

> number of `_simulate_step()` calls per rendered frame.

It does not change numerical `dt`, which remains 1.0 in the unlocked solver.

Do not describe SIM SPEED as a timestep control.

---

## 7.18 Edge regime label is thresholded from λ, not measured from the field

Source:

- λ<.2 → FROZEN;
- λ<.55 → EDGE OF CHAOS;
- otherwise CHAOS.

That is a project label.

The manuscript is right not to use it as evidence.

---

## 7.19 Sandbox receiver sources are missing

Primary source closure includes the sliders but not:

- `qfep_reactor.gd`;
- `reactive_particle_field.gd`.

The chapter’s wiring audit cannot be fully source-verified from this bundle.

Include them next time.

---

## 7.20 Registry DNA records a historical dead-driver mismatch in QFEP Reactor

The registry says the reactor looked for:

> group `qfep_slider`

while λ/φ sliders join:

- `qfep_lambda_controllers`;
- `qfep_phi_controllers`.

If that is still current source, it exactly supports the manuscript’s disconnected-control hall.

Because the source file is absent here, verify in the next bundle/current repository before treating it as SOURCE fact.

---

## 7.21 Synthesis’s λ stiffness mapping is source-supported

`linear_stiffness` maps:

> .9 → .1

as λ goes 0→1.

The manuscript is accurate.

---

## 7.22 Synthesis’s φ damping/drag mapping is source-supported

Damping:

> .2 → .001.

Drag:

> .3 → 0.

The manuscript is accurate.

---

## 7.23 Synthesis’s pressure mapping is not source-stable during edge breathing

As detailed above.

Fix it.

---

## 7.24 Synthesis’s state labels remain substantially stronger than the manuscript

Source:

> EDGE OF CHAOS  
> Max complexity  
> Life emerges.

Registry:

> “THIS IS QFEP EMBODIED.”

The final manuscript correctly rejects that level of claim.

Update the object labels/registry.

---

## 7.25 Synthesis’s “becoming” DNA axis is separate from λ/φ physics

The artifact can be built as:

- jarred;
- cracked;
- escaped;
- clouded.

Those are build-time mesh/count states and are deliberately not driven by λ/φ.

The current Synthesis manuscript does not rely on them.

Good.

Do not let source rhetoric collapse the DNA axis and physics controls into one causal “becoming.”

---

# 8. Spatial / reader-order findings

## Introduction

Primary workbench at `(2,2)` is right at the front.

Good.

Several separate λ/φ/formula objects sit nearby but the manuscript focuses the workbench.

No restage indicated.

## F Term

Primary Shannon Workbench `(1,3)` is near the entrance.

However, a secondary `lambda_slider#locked:0` is at `(3,1)` and may be encountered first.

Because that token is currently ignored, the physical room can present a movable/default λ≈.4 control before a chapter that the map labels “λ=0 pure order.”

Fix/remove that slider before route restoration.

## E Term

Primary fan `(4,2)` and the misleading `lambda_slider#value:1.0` `(10,2)` share the front band.

Again, repair/remove the secondary slider.

## Lambda Spectrum

The `lambda_hall` is a large 7×14 m environment anchored at `(11,11)` inside a 13×22 map.

The hall itself is the encounter.

The source route recommendation is therefore likely perceptually dominant.

Good for the chapter’s critical question.

## Phi Term

Phi slider `(5,5)` precedes transforming pattern `(8,7)`.

This matches manuscript order.

## Edge Of Chaos

Several older secondary “edge” artifacts and a supposedly locked .4 slider sit at z2.

The primary unlocked study is later at `(13,4)`.

Visitors may receive the edge-of-chaos answer before reaching the room that audits it.

**RUNTIME / SPACE:** check. If necessary, move the unlocked study forward or reduce the authority of the secondary labels.

## Sandbox

Primary sliders are at `(5,1)` and `(9,1)`.

Reactive particles also begin at `(1,1)` and the reactor sits `(7,4)`.

If restored, the room has the right physical layout for a wiring audit:

> controller first / receiver later.

Good.

## Synthesis

Primary specimen `(3,1)` is immediately at the front.

Good.

The formula and callback objects become supporting context.

The chapter’s focused one-body reading is spatially plausible.

---

# 9. Runtime questions

No repository code was executed. Every hall remains recorded as learner-unverified.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Whole sequence** | Does current museum routing actually skip F Term and Sandbox exactly as `map_authored` reports? |
| **Whole sequence** | After restoration, verify all eight `next_in_sequence` transitions. |
| **Introduction — equal totals** | Can a visitor reasonably find two visibly different knob tuples with nearly equal QFE without numerical trial becoming tedious? |
| **Introduction — phase label** | Does “dominant phase” cause visitors to interpret a physical regime despite the manuscript’s authored-reference caveat? |
| **Introduction — φ domain** | Is it obvious that this console’s φ is 0…1 while later φ is −1…1? |
| **F — λ secondary** | Confirm `#locked:0` currently leaves the lambda slider at its default and interactive. |
| **F — Shannon sample** | At p=.1/.9, verify same fixed draws are simply re-thresholded and H remains symmetric. |
| **F — readout** | After correction, test whether visitors distinguish source H from finite observed predictor error. |
| **F — predictor** | Add ALWAYS ZERO predictor and verify expected/observed errors clearly diverge between p=.1 and .9 while H matches. |
| **E — fan timing** | Can visitors count branch factor/leaves before the 9-second breathing cycle changes state again? |
| **E — pruned** | Expose `prospect:pruned`; can visitors distinguish closed amber futures from futures never generated? |
| **Lambda — recommendation** | Can visitors articulate why the current glowing path feels preferable before reading the chapter’s critique? |
| **Lambda — movable path** | After decoupling RECOMMENDATION from structure, does moving only the lit route change preferred standing position for learners? |
| **Phi — semantic bias** | Compare neutral `−/0/+` labels with RESIST/EMBRACE labels. Do descriptions of the same particle directions become more normative under the latter? |
| **Phi — independence** | Confirm transforming pattern remains unchanged by φ slider in current build. |
| **Edge — numerical instability** | Reproduce the source’s stability failure in the original interactive solver; compare with `_simulate_step_stable()` under identical λ/seed/model duration. |
| **Edge — stable lambda sweep** | After repair, define one observable and test across λ with multiple reseeds before using any “edge” language. |
| **Edge — SIM SPEED** | Verify the current slider changes update count per rendered frame rather than numerical dt. |
| **Sandbox — source closure** | Include `qfep_reactor.gd` and `reactive_particle_field.gd`; verify exactly which slider groups/signals they listen to. |
| **Sandbox — UNWIRED/WIRED** | If added, show receiver’s actual consumed λ/φ values and compare one resettable response under connected/disconnected states. |
| **Synthesis — λ pressure** | At λ=.5, record pressure immediately after slider set and after `_process()` runs; confirm current breathing loop erases the 1.5× edge baseline. |
| **Synthesis — repaired pressure** | After fix, verify λ changes stiffness and baseline pressure while breath only modulates around that baseline. |
| **Synthesis — φ** | Verify damping/drag mapping remains stable under the independent breathing pressure driver. |
| **Synthesis — body response** | In headset, are deformation resistance and motion persistence distinguishable enough to support the manuscript’s comparison? |

---

# 10. What I would not cut

## Do not cut the arithmetic simplicity of the Introduction

The fixed ΔE=.3 is a strength because the room admits it.

The console is a manipulable equation, not a fake biological sensor.

Keep it.

## Do not turn the nearest project reference into a “real phase detector”

The current manuscript’s caveat is exactly right.

Change the artifact wording, not the conceptual restraint.

## Do not cut λ=0 as a special case

It makes weighting dependency directly discoverable.

That is better than an abstract explanation of multiplication.

## Do not cut the F hall because it “only computes entropy”

Its job is precisely to separate a quantity we can compute from the stronger QFEP term people may be tempted to call it.

Restore it and add predictor error.

## Do not cut the fixed-draw threshold design

It is excellent experimental control.

The same random evidence is reinterpreted as p moves.

Keep it.

## Do not keep the finite-sample “incompressible” claim merely because the manuscript can correct it

Fix the instrument.

The hall is about accountable quantities.

## Do not cut the E fan’s simple log-count model

It is valuable if its equal-probability assumption remains visible.

It does not need to become a full statistical-mechanics model.

## Do not cut closed futures from the conceptual discussion

Better: expose the already-implemented PRUNED state.

## Do not neutralise Lambda Hall until it becomes aesthetically bland

The seduction is the work.

Keep the cold order wall, hot moving side, green glowing route and “life walks here” historical claim **as an object to interrogate**.

Just let the recommendation move independently.

## Do not treat the preferred middle as a physics result

The final manuscript correctly refuses this.

Keep that refusal central.

## Do not remove the sign from φ

Signed direction is the parameter’s best operational feature.

Remove the premature moral evaluation, not the asymmetry.

## Do not wire the transforming pattern to φ merely because it sits nearby

Its independence is useful evidence.

The Sandbox/Synthesis can handle causal connection later.

## Do not cut Edge Of Chaos because its current solver is unstable

Repair the numerics.

The hall’s current self-critique is exactly why the model deserves to remain.

## Do not use the regime labels as evidence after the numerical repair

A stable solver is necessary but not sufficient for “criticality.”

Define an observable.

## Do not cut Sandbox because its wiring is incomplete

It may be the sequence’s most Ada-like audit:

> a control can be beautifully interactive and still control nothing beyond itself.

Restore it intentionally.

## Do not make every Sandbox object respond to every slider

One explicit receiver is more scientifically useful than a roomful of synchronized spectacle.

## Do not cut Synthesis’s authored mapping language

“The mapping is authored for this specimen” is the correct ending.

Protect it.

## Do not let “Queer Morphology” become an assay

The manuscript’s refusal is important.

A responsive soft body can open a conceptual question without measuring queerness or life.

---

# 11. Reader-experience strengths to protect

## Discovery before naming

**Introduction**  
E moves but QFE does not at λ=0 before dependency is explained.

**F**  
p=.1 and p=.9 look opposite while H agrees.

**E**  
count leaves before log-count is named entropy.

**Lambda**  
the lit route attracts before the chapter calls it a curatorial argument.

**Phi**  
particle direction changes at zero before project meaning is assigned—once the rail labels are neutralised.

**Edge**  
follow one feature before reading a regime name.

**Sandbox**  
slider responds before receiver connection is assumed.

**Synthesis**  
body response appears before project interpretation, provided mechanical values remain visible.

---

## Prediction before explanation

- Can another knob restore the same QFE total?
- Which source p makes an always-zero predictor fail?
- How many leaves does branch factor 3 produce?
- Where would you stand if the route were not lit?
- What changes when φ crosses zero versus merely increases in magnitude?
- Will the same λ setting produce the same feature after RESEED?
- Did this surrounding object actually receive the slider’s value?
- Which body property changes first under λ versus φ?

These are strong and should remain the sequence’s rhythm.

---

## Productive distinctions to protect

- scalar summary ≠ complete parameter state
- project phase label ≠ detected physical phase
- source uncertainty ≠ realised sample appearance
- source entropy ≠ predictor error
- predictor error ≠ variational free energy
- outcome probability ≠ number of allowed outcomes
- counted leaves ≠ equally probable leaves
- unavailable future ≠ future that was available then closed
- spatial recommendation ≠ discovered optimum
- signed parameter ≠ moral direction
- local slider feedback ≠ receiver response
- visual pattern activity ≠ measured chaos
- simulation speed ≠ numerical timestep
- stable numerical update ≠ proof of criticality
- emitted control value ≠ consumed receiver value
- shared vocabulary ≠ shared numerical domain
- authored body mapping ≠ universal biology
- responsive body ≠ assay of life or queerness.

This list is the real QFEP Laboratory curriculum.

---

# 12. Questions for the author

## 12.1 Are F Term and Sandbox definitively part of the current spine?

The book says yes.

`map_authored` says no.

I recommend restoring both.

## 12.2 Do you want φ to have one numerical domain throughout the project?

Intro uses 0…1.

Phi/Synthesis use −1…1.

Both can work if the difference is explicit, but the same symbol currently invites equivalence.

## 12.3 Is F intended eventually to become actual variational/free-energy computation?

The current F hall very responsibly says it is not.

The next small step should be predictor error, not a leap directly into Friston/FEP terminology.

## 12.4 Is the lit λ route meant to persuade the visitor?

I think yes.

If so, the independent recommendation-position control would turn that persuasion into a genuine experiment.

## 12.5 Do you want Edge Of Chaos to remain a reaction–diffusion study after the numerical repair?

I think yes.

But its goal should initially be:

> parameterised model response under stable integration,

not proving a universal edge of life.

## 12.6 Should Sandbox remain deliberately incomplete?

It can.

I would name it **Wiring Audit** and give it one optional WIRE control.

Its value is showing that connection itself is an implemented relation.

## 12.7 Is the Synthesis specimen intended to be the one place where QFEP becomes a concrete receiver mapping?

The manuscript strongly suggests yes.

That is an excellent role.

If so, make its live mechanical readout and source mapping exceptionally clean and remove the “Life emerges” regime rhetoric from the object.

---

# 13. Overall conclusion

QFEP Laboratory is much stronger in its **current final manuscripts** than in its inherited source slogans.

The old sequence says:

> life exists at λ≈0.3–0.5  
> F is order  
> E is freedom/disorder  
> φ is the queer signature  
> edge of chaos is where adaptation happens.

The current book increasingly says something more accountable:

> **Here is one project formula. Here is what this instrument actually computes. Here is what this other artifact merely represents. Here is where a parameter becomes architecture. Here is where a control is not connected. Here is one body for which we explicitly authored a mapping.**

That is the right direction.

The sequence’s best discoveries are all **failures of automatic equivalence**:

- one QFE total can hide two very different parameter tuples;
- equal Shannon entropy can accompany opposite performance for one predictor;
- 81 visible futures do not establish equal probability among them;
- a glowing middle route can recommend a value without measuring one;
- a signed parameter can have direction without one direction being intrinsically better;
- a reaction–diffusion picture can look “chaotic” because the numerical method is unstable;
- a slider can emit a value without any surrounding receiver actually consuming it;
- a responsive body can implement λ and φ mappings without becoming evidence that nature, life or queerness use those mappings.

Those are excellent Ada Research moments.

The highest-value work now is:

1. **restore F Term and Sandbox, and repair the ignored λ slider map configurations those rooms currently rely on visually;**
2. **turn F Term into a clean uncertainty-versus-predictor-error experiment and remove the finite-sample compression overclaim;**
3. **repair Edge Of Chaos’s learner-facing integrator before treating any λ region as a regime;**
4. **make Lambda Spectrum’s recommendation movable independently of its structures;**
5. **repair Synthesis so breathing modulates the λ-derived pressure instead of erasing it, and let mechanical readouts replace “life emerges” labels;**
6. **promote the cautious final-manuscript framing into sequence/registry metadata so QFEP remains visibly a research framework rather than drifting back toward universal-law language;**
7. **include Sandbox receiver sources in future review bundles and verify actual control wiring before attributing any response.**

The reader-experience principle I would carry forward from QFEP Laboratory is:

> **Let the project make a recommendation, then give the visitor a way to separate the number, the mapping, the receiver and the value judgement that made the recommendation feel necessary.**

And the structural principle is:

> **QFEP becomes testable only locally. A symbol is not a cause until a receiver uses it; a named phase is not a measurement until an observable defines it; and a project interpretation stays strongest when the mapping that produced it remains visible and revisable.**
