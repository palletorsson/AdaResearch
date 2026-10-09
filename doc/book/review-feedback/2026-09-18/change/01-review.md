# Change — 01 Review

Source-aware editorial and reader-experience review of the **Change** sequence.

Basis: `change-book.md`, `change-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where the visitor can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. Recurrence is not treated as redundancy when an earlier idea returns at another scale or with another independent variable.

The consolidated sequence now reads as:

> **sample a change → accumulate finite contributions → recover net change → let each update choose the next address**

A second formulation is:

> **A value, its local rate, an accumulated total, and the path produced by repeated updates can all be correct descriptions of the same system without being interchangeable.**

That is more precise than the current sequence-level editorial intention, which appears to preserve language from an earlier version of Change.

---

## 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **Change Intro** | **Carries:** this is not one long calculus lecture but a three-part encounter built around productive disagreement: a wide secant can report falling while the local curve rises; a coarse “reasonable” Riemann rule can miss badly and even lose to another coarse rule; a journey can rise and fall while its net endpoint difference is zero. Those surprises make derivative, accumulation and net change necessary rather than merely named. **Gap:** the manuscript depends on the order tangent → accumulation → FTC bridge, but the tangent and Riemann benches are placed opposite each other at the same depth in the entrance bay, so the physical room does not clearly guarantee the reading order. The FTC bridge also prints the theorem equation and longhand equality from the start, answering part of its prediction before the visitor can make it. **Next:** preserve the three encounters and their mathematical density; improve spatial and reveal timing rather than cutting them. |
| **Flow Field** | **Carries:** the local rate/lookup problem becomes recursive: the particle’s updated position becomes the address for its next direction. ARROWS exposes the same sampler the particles use; SPEED and SCALE separate movement per update from spatial variation of the rule; FIELD TIME adds another clock; RESET and SEED separate starting distribution from rule; wrapping exposes a seam between coordinate return and field continuity. **Gap:** the teaching overlay immediately prints `ARROWS = PARTICLE SAMPLER`, which states the key relation before the visitor has revealed and compared the arrows. Source/registry rhetoric also still calls the field a “force landscape,” invokes turbulence/laminar flow and a QFEP λ-edge, although the actual code simply maps a Perlin scalar to an angle and prescribes a unit direction. **Next:** delay/remove the answer in the status display and clean the metadata; preserve the manuscript’s careful distinction between direction field, gradient, force and fluid association. |

The sequence structure itself is strong. The first hall asks:

> **What is changing? At what scale? What is lost when we gather it?**

The second asks:

> **What happens when the result of one update determines where the next one reads?**

That is a good bridge from calculus into Forces.

---

# 2. Reader-experience lens

## Change Intro — Measure a change

### Curiosity

The opening question is excellent:

> “Where can a high curve be changing very little?”

It already separates **value** from **rate** without giving either a formal definition.

The starting configuration is particularly well chosen. At `x = 1` with `h = 0.5`, the two-sample finite rate is negative, approximately `-0.59565`, while the analytic derivative is positive, approximately `+0.38628`. The wide interval crosses a crest.

So the artifact begins with a real contradiction in appearance:

> **the endpoints say overall fall; the local curve is still rising.**

That gives the derivative a reason to exist.

### Discovery

The comparison adapter is well designed for discovery.

`commons/artifacts/tangent_slope_workbench/rate_comparison.gd` changes the base workbench into:

> **TWO SAMPLES / x IS POSITION**

and hides:

- the gold tangent;
- the derivative subplot;
- the slope-sign display

until **DERIVATIVE** is pressed.

`STEP` cycles:

- `0.5`
- `0.25`
- `0.125`
- `0.0625`

without ever offering zero.

This is exactly the right artifact logic: the visitor first sees a relation between two actual samples, then watches the neighbour approach, then receives the analytic comparison.

The current prose also correctly refuses the common beginner error “keep making h smaller until h = 0.” The tangent is not generated by dividing by zero.

### Timing

Most of the timing is strong.

One sentence arrives slightly early:

> “A negative rise says the second value is lower when the interval points to the right. **It does not tell us that every part of the journey went down.**”

The second sentence performs real conceptual work, but it appears before the visitor has made the smaller-step / derivative comparison.

It is not wrong, and it should not be cut. But moving it to the paragraph where the wide interval is compared with the local rise would let the artifact produce the need for that distinction first.

This is a **minor editorial timing improvement**, not a structural problem.

### Return

Several earlier Ada distinctions return with changed meaning:

- Trace: two endpoints do not preserve the journey between them.
- Grid: a finite interval decides what distinctions can be seen.
- Portals: approaching a limit is not the same as arriving at a final displayed member.
- Transformation: the same value can participate in different relations.

Here those ideas become mathematical rate.

The return is productive.

---

## Change Intro — Add contributions

### Curiosity

This may be the strongest reader-timing section in the hall.

It does **not** begin:

> “Now we learn integration.”

It begins:

> “How much area lies between the curve and the baseline?”

Then:

> “Where would you put [the rectangle’s] top?”

The visitor has to confront representation before receiving the formal name.

### Discovery

The comparison adapter gives the visitor several independent variables:

- sampling rule: MID / RIGHT / LEFT;
- selected contribution;
- rectangle count;
- a held comparison;
- a hidden 4096-midpoint reference.

The best decision is that **REFERENCE is initially hidden**.

The visitor can first ask:

> Which total would you trust?

before the machine supplies a comparison number.

The held panel is also important. It preserves not merely a total but the visible rectangle construction that produced it. This supports the later question:

> what did the total discard?

The numerical starting examples are useful and source-consistent:

- MID, N=4 ≈ `2.23665`
- MID, N=8 ≈ `2.88669`
- 4096-midpoint reference ≈ `2.86384`

The jump from four to eight is intentionally large enough to make “more rectangles” perceptually and numerically consequential.

The later counterexample is especially good:

> at N=4, RIGHT is closer to the reference than MID.

That prevents midpoint from becoming a moral hierarchy rather than a sampling rule.

### Timing

The phrase:

> “This is a Riemann sum.”

arrives only after the visitor has already:

- chosen a cell;
- seen height × width;
- changed sampling rule;
- held a comparison.

That is excellent timing.

The reference appears only after increasing resolution.

Again, excellent.

### Return

The chapter’s larger epistemology is enacted rather than announced:

- one height stands for an interval;
- intervals become contributions;
- contributions become a total;
- the total loses where each contribution came from.

This is a direct mathematical version of the book’s recurring question:

> **what does a useful representation discard?**

The prose should not be shortened merely because it becomes philosophically explicit here. The operations have earned the reflection.

---

## Change Intro — Recover a difference

### Curiosity

The opening is strong:

> “Can a journey return to its starting height after changing all the way?”

The bridge makes **zero** interesting instead of trivial.

The symmetric arch deliberately gives equal endpoint heights, so the net result is zero while the path visibly rises and falls.

This is conceptually valuable. An older source comment complains that the shipped bridge equation becomes “0 = 0,” but the present manuscript turns exactly that degeneracy into the encounter:

> **zero net change does not mean no change.**

That is a good example of the book making something useful out of a limitation rather than pretending it is not there.

### Discovery

The visitor can:

1. watch the pulse travel;
2. predict endpoint difference;
3. follow positive and negative rate contributions;
4. compare the accumulated rate with endpoint height difference.

The source uses:

- 40 signed visual rate strips;
- a 512-interval trapezoid numerical comparison;
- the same selected bridge curve for endpoint heights and local slope.

The manuscript correctly calls that finite numerical evidence rather than a proof.

### Timing

Here the artifact undermines the manuscript’s discovery timing.

`ftc_bridge.gd::_build_label()` places this equation directly on the bridge:

> `∫ f'(x) dx = f(b) − f(a)`

The configured map also uses:

`#evidence:longhand`

so the bridge immediately shows the numerical accumulated rate and endpoint difference.

The manuscript asks the visitor:

> “Predict the height difference left between its beginning and end.”

But the artifact may already be displaying both the theorem and the numerical answer.

This is the clearest reader-experience issue in Change.

The bridge should still be the FTC bridge. The equation should not be removed from the work. But the **longhand answer should arrive after the first prediction**.

### Return

The positive-area Riemann sum and the signed-rate sum need to remain separate.

They look mathematically similar—both add finite contributions—but answer different questions.

The sentence:

> “Adding the magnitudes of the rate contributions would measure something else again.”

is valuable because it resists the temptation to identify every accumulation with “area under the curve” in one undifferentiated sense.

---

## Flow Field

### Curiosity

The opening is excellent:

> “Where will this particle look next?”

This translates the abstract update loop into a spatial question.

The field begins held while particles move. That is also a good choice: the visitor first has a stable rule and moving samples before temporal evolution is added.

### Discovery

The strongest sequence is:

1. follow one trail;
2. predict the next bend;
3. reveal ARROWS;
4. compare a nearby arrow with a particle;
5. change SPEED while SCALE stays fixed;
6. change SCALE while SPEED stays fixed;
7. evolve FIELD TIME;
8. distinguish RESET from SEED;
9. inspect a wrapping edge.

That is an unusually clean escalation.

The source supports the key technical distinctions.

Both arrows and particles call:

`flow_field_painter.gd::field_direction(point)`

which:

1. samples a Perlin scalar;
2. multiplies it into an angle;
3. returns `Vector2(cos(angle), sin(angle))`.

The manuscript correctly says this is **not the scalar field’s gradient**.

Likewise, particle state contains position and trail, not accumulated velocity. Each update receives a fresh prescribed direction.

That makes the transition to Forces exact rather than metaphorical.

### Timing

The prose timing is strong, but the artifact answers one of its own questions too early.

`shared_field_lesson.gd::refresh()` always displays:

> `FIELD HELD / 80 PARTICLES`
>
> `ARROWS = PARTICLE SAMPLER`

even while the arrows are hidden.

The manuscript wants the visitor to reveal arrows, compare them, and then learn:

> “The arrows and particles call the same function.”

The artifact announces that relation first.

The fix is simple: keep the status line about field state and particle count, but remove the equality claim from the always-visible display. If a confirmation label is wanted, show it only after ARROWS is enabled or place it in a later explanatory panel.

### Return

Trace returns through a finite retained trail.

Disco/Paint return through different update schedules.

Grid/Portals return through wrapping and seams.

Noise is previewed, but the manuscript properly avoids turning this into the Noise chapter.

Forces is prepared by absence:

> no mass, no accumulated velocity, no collision negotiation.

That is a strong ending.

---

# 3. Five high-value changes

## 3.1 Update the sequence intention and objectives to match the consolidated sequence

**Location**

Sequence/review metadata, not the chapter prose.

### Current editorial intention

> “Separate a changing value from accumulated history; ask how timing, repetition and a mismatch of phases make different events possible.”

That describes only part of the current two-hall sequence and sounds inherited from an earlier Change structure.

The current manuscript is primarily about:

- value versus rate;
- finite difference versus derivative;
- contribution versus total;
- positive area versus signed net change;
- update position becoming next sample address.

### Current declared objectives that need revision

Two are particularly problematic.

**1.**

> “Vector fields: change-and-flow at every point in space; the first encounter with a function of space (not just time)”

This is no longer true in the book. Color Pillar already makes hue and saturation functions of spatial position, and several earlier halls use fields/mappings over space.

**2.**

> “The fundamental theorem of calculus: change and accumulation are inverse operations; one undoes the other”

This is too broad. The manuscript itself is better:

> integrating a derivative over an interval recovers endpoint difference, and reconstructing a function from its derivative still needs a starting value.

**3.**

> “F = ma is calculus made physical”

This is rhetorically stronger than the actual relation being prepared. `F = ma` itself is an algebraic relation; dynamics becomes differential because acceleration is change of velocity and velocity is change of position.

### Proposed replacement

**Editorial intention**

> **Separate a value from its local rate and a local contribution from an accumulated total; then let repeated updates make the path through a field part of the computation.**

**Selected objective revisions**

> - Compare finite change across an interval with a local derivative where the limit exists.  
> - Build finite accumulation from sampled contributions and distinguish the approximation from its limiting integral.  
> - Use signed accumulation of a derivative to recover endpoint difference, while keeping the required starting value explicit.  
> - Let a spatial field be sampled at a moving address so that each update determines where the next sample is taken.  
> - Prepare Forces by distinguishing a prescribed direction field from acceleration, velocity and carried motion.

### Reason

The book has become more precise than its sequence metadata. Update the metadata rather than making the manuscript recover older slogans.

---

## 3.2 Change Intro — make the physical route support the conceptual order

**Hall / instances**

`Change_Intro`

Primary placements:

- A1 `tangent_slope_workbench` at `(6,5)`
- A2 `riemann_sum_workbench` at `(20,5)`
- A4 `ftc_bridge` at `(6,12)`

The museum has a straight three-metre central route.

### Work performed by the current order

The manuscript depends on:

> **sample a change**  
> → **add contributions**  
> → **recover a difference**

The Riemann section explicitly says:

> “The curve has followed us. At the first workbench...”

The bridge explicitly says:

> “Compare the earlier positive-area sum with this signed-rate sum.”

So these are not three independent stations that can be read in arbitrary order.

### Spatial problem

Tangent and Riemann are opposite one another at the same entrance depth.

A visitor entering on the central axis can plausibly turn right first and meet accumulation before rate.

Source plans do not prove actual gaze or route, so this is a **HYPOTHESIS** to test in walkthrough. But the authored positions do not themselves establish the manuscript’s order.

### Artifact/spatial proposal

First observe the live approach.

If order is ambiguous, prefer one of these interventions:

1. stagger the primary encounters in z: tangent first, Riemann second, bridge third;
2. use a subtle floor/lighting continuation between the three;
3. give the first bench a stronger approach cue and the accumulation bench a sightline that becomes dominant only after leaving it.

Do not add a large “1 / 2 / 3” unless learner testing shows it is necessary.

### Reason

The prose is already modular and coherent. The room should make its dependency chain legible without requiring a textual navigation paragraph.

---

## 3.3 FTC Bridge — reveal the theorem’s working after the first prediction

**Hall / instance**

`Change_Intro`  
A4 `(6,12)`  
`ftc_bridge:0:0:1#pin:1#plinth:0#evidence:longhand`

### Current text

> “Watch the pulse move along the arch. Predict the height difference left between its beginning and end.”

The manuscript then lets the visitor inspect signed contributions before naming the net-change relation as the fundamental theorem.

### SOURCE

`algorithms/change/ftc_bridge.gd`

The bridge always creates:

```text
∫ f'(x) dx = f(b) − f(a)
```

on the beam.

With `evidence=longhand`, it additionally prints:

```text
∫ f' dx = ...     f(b) − f(a) = ...
```

from the start.

For the configured default `hump`, both endpoint difference and accumulated signed rate are approximately zero.

### Artifact proposal

Keep the beam equation as the artifact’s identity if desired, but delay the **longhand numeric equality**.

Best option:

- initial bridge: arch, pulse, rate strips, endpoints;
- control/button: **COMPARE TOTALS** or **SHOW WORK**;
- after activation: reveal numerical integral and `f(b) − f(a)` readout.

A stronger discovery-first option would also put the theorem equation on the far side / reverse of the bridge or reveal it with the same control, but that is not necessary if the equation is meant to function as the object’s title.

### Reason

The valuable discovery is:

> the journey changed continuously yet endpoint difference is zero; positive and negative local rates cancel.

Let the visitor make that prediction before the artifact prints `0 = 0`.

---

## 3.4 Flow Field — remove the answer from the always-visible status

**Hall / instance**

`Flow_Field`  
A1 `(5,5)`  
`flow_field_painter:...#lesson:shared_field`

### Current text

> “Press **ARROWS**. Twenty-four arrows appear over the canvas. Find one near a particle and compare their directions.”

Then:

> “The arrows and particles call the same function.”

### SOURCE

`commons/artifacts/flow_field_painter/shared_field_lesson.gd::refresh()`

always displays:

```gdscript
status.text="FIELD %s / %d PARTICLES\nARROWS = PARTICLE SAMPLER"
```

The sentence is visible even when `arrows.visible == false`.

### Artifact proposal

Initial status:

> **FIELD HELD · 80 PARTICLES**

When FIELD TIME is active:

> **FIELD EVOLVING · 80 PARTICLES**

Remove `ARROWS = PARTICLE SAMPLER` from the permanent status.

If a confirmation is useful after the experiment, reveal a smaller line only while ARROWS is on:

> **ARROWS SAMPLE THE SAME FIELD**

or leave that explanation to the manuscript.

### Reason

The visitor should have one chance to compare a nearby arrow and particle before being told they share a sampler.

The prose already has the right order. The artifact should respect it.

---

## 3.5 Move one derivative explanation half a beat later

**Hall / section**

`Change_Intro` → **Measure a change**

### Current sequence

After the first instruction to compare the red and green samples, the manuscript says:

> “A negative rise says the second value is lower when the interval points to the right. **It does not tell us that every part of the journey went down.**”

Only afterward does it ask the visitor to shrink the interval and reveal the derivative.

### Work performed

The sentence is conceptually important. It protects the reader from mistaking endpoint difference for the entire path, and it connects to the earlier Lines/Trace distinction.

It should not be cut.

### Editorial proposal

Keep the first sentence where it is:

> “A negative rise says the second value is lower when the interval points to the right.”

Move:

> “It does not tell us that every part of the journey went down.”

into the next observational paragraph, for example:

> At this starting position, the wide interval crosses a crest. Its two endpoints report an overall fall. Close enough to the red point, the curve is still rising. **The negative rise was true; it did not tell us that every part of the journey went down.** Both reports describe this same curve. They answer questions at different scales.

### Reason

The same idea becomes stronger when it names a discrepancy the visitor has just produced.

This is a small editorial move, but it directly serves the new reader-experience criterion:

> let the observation happen before its general lesson.

---

# 4. Source / artifact discrepancies

## 4.1 Riemann registry description still calls the finite reference “true” and the slider “the limit”

The current implementation and manuscript are careful:

`riemann_sum_workbench.gd` says:

> “The reference is a separate 4096-cell midpoint estimate, not an exact integral.”

and the manuscript says:

> “The integral is the limit these sums approach... none of the buttons reaches that limit.”

But `artifact-index.json` still describes:

> “the true ∫ ≈ 2.864”

and:

> “The slider IS the limit.”

This is conceptually wrong for the current lesson.

There is also a stale internal variable name:

```gdscript
_true_integral
```

whose value is actually the 4096-midpoint finite reference.

**SOURCE maintenance**

Prefer names such as:

- `_reference_sum`
- `_reference_midpoint_4096`

and update the registry description:

> a dense finite reference, not the integral itself; the slider explores a family of finite sums approaching a limit.

Do not weaken the manuscript to match old metadata.

---

## 4.2 FTC source rhetoric still overstates “inverse operations”

The `ftc_bridge.gd` header says:

> “derivative and integral shown as inverse operations”

and:

> “differentiation and integration are the same bridge walked in opposite directions.”

That is evocative, but mathematically incomplete.

The present manuscript is better because it states the interval net-change relationship and adds:

> “Recovering a function from its derivative still requires a starting value.”

Keep that qualification.

If the source identity remains, change “inverse operations” to something like:

> differentiation and accumulation are linked by the fundamental theorem; integrating a derivative gives net change, while recovering the original function requires an initial value.

---

## 4.3 The FTC source comment treats the symmetric hump as a defect; the manuscript turns it into a valid experiment

The source says the shipped symmetric parabola makes the equation read:

> `0 = 0`

and implies that only the `ramp` and `step` configurations make the beam “say something.”

The current manuscript does something more interesting:

> “Zero net change does not mean that nothing happened.”

The symmetric arch is therefore not mathematically empty. It demonstrates cancellation of signed rate over a nontrivial journey.

This is a **source-comment judgement**, not a code defect.

Update the comment if it is used for future editorial decisions.

---

## 4.4 Flow Field metadata describes forces and fluid regimes that are not implemented

The current code:

```gdscript
var direction = field_direction(position)
position += direction * speed * delta
```

and `field_direction()` maps a scalar Perlin value to an angle.

It does **not** implement:

- force accumulation;
- mass;
- acceleration;
- stored velocity;
- particle-particle interaction;
- a fluid solver;
- a scalar-gradient field.

Yet source and registry rhetoric includes claims such as:

- “force landscape”
- “laminar rivers”
- “turbulent eddies”
- “λ-edge”
- “Paint with vector fields — particles follow the flow you create”
- “your gestures define the force landscape”

The placed lesson has no user-painted field and the manuscript correctly avoids these claims.

**SOURCE/registry maintenance**

Describe the artifact operationally:

> particles repeatedly sample a Perlin-derived direction field and move a fixed speed along the returned unit vector; their trails visualize the resulting trajectories.

Associations with fluid flow can remain as associations, not implementation labels.

---

## 4.5 Flow Field registry curation is stale

`artifact-index.json` still records `flow_field_painter` as:

- sequence: `noise`
- map_sequences: `testmaps`
- interaction: `observe`

But the current Change sequence uses it as a primary interactive artifact with:

- SCALE;
- SPEED;
- RESET;
- SEED;
- ARROWS;
- FIELD TIME.

Update registry / sequence metadata so future automated reviews do not route it as a passive Noise/testmap artifact.

---

## 4.6 Tangent source identity is stronger and more slogan-like than the current lesson

The header says:

> “The slider walks the zoom.”

and describes the tangent as:

> “the slope of the line you would draw if you zoomed in until the curve looked straight.”

This can be an intuitive metaphor, but the configured comparison lesson no longer teaches by literal zoom. It teaches through finite secants plus a separately calculated analytic derivative.

The manuscript is technically clearer.

No urgent code change is required, but future source documentation should distinguish the old intuitive identity from the current `comparison:true` encounter.

---

# 5. Runtime questions

No repository code was executed for this review. The package records both halls as `desktop_verified_headset_pending`, but `learner_verified` remains false.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Change Intro — route** | From the actual entrance, which primary bench do visitors approach first: tangent at `(6,5)` or Riemann at `(20,5)`? Does the central passage visually imply a sequence, or are both equally inviting? |
| **Tangent — initial paradox** | At the authored scale, can a visitor visually see that the wide secant crosses a crest before DERIVATIVE is revealed? Does STEP make the sign change legible across the four intervals? |
| **Tangent — controls** | In XR, are the x slider, x−/x+, STEP, DERIVATIVE and RESET reachable without occluding the curve? Does the tangent/subplot reveal happen clearly enough to feel like a new comparison rather than visual clutter? |
| **Tangent — near-zero** | Can a learner distinguish the `|slope| < 0.05` display threshold from an actual extremum? Test whether the sign card invites the mistaken conclusion despite the manuscript caveat. |
| **Riemann — contribution** | Can the red cell marker be followed as CELL+ advances through N=4? Are height, width and product readable as one contribution before the visitor sees only the total? |
| **Riemann — held comparison** | Does HOLD preserve the correct frozen curve/rectangles while the live rule changes? Is the held panel physically positioned so comparison is easier rather than doubling visual density? |
| **Riemann — count slider** | Are N=4, 8, 16, 32, 64, 128 detents reliable in XR? At high N, can the visitor still perceive the idea of narrower contributions even if individual rectangles merge visually? |
| **Riemann — reference** | Is REFERENCE initially hidden as intended? Does the capped difference bar visibly saturate for substantially different errors, making the numeric readout necessary as the text claims? |
| **FTC bridge — prediction** | Before reading any formula/readout, can a visitor perceive that the two ends of the configured hump are level and predict zero difference? If not, is the prediction still meaningful? |
| **FTC bridge — reveal timing** | With `evidence:longhand`, how prominent are the theorem equation and `0 = 0` numerical readout from the approach? Do they answer the manuscript’s prediction before the pulse/strips can be inspected? |
| **FTC bridge — signed strips** | Are positive versus negative strips visibly distinguishable and spatially attributable to rising/falling parts of the arch? Does the 512-interval numeric comparison agree at the displayed precision? |
| **Flow — first trail** | With 80 particles on the 2.5× placed canvas, can a visitor realistically follow one particle through a bend, or does trail density make the opening instruction too difficult? |
| **Flow — arrows** | When ARROWS is revealed, can a visitor pair one arrow with a nearby particle closely enough to understand why their directions may differ slightly because the addresses differ? |
| **Flow — SPEED** | Holding SCALE fixed, does increasing speed visibly increase distance between per-frame trail samples rather than simply making the whole image harder to follow? |
| **Flow — SCALE** | Holding SPEED fixed, does the SCALE slider create a legible change in spatial variation of direction? Give old trails enough time to clear or use RESET; test whether learners understand why history remains briefly. |
| **Flow — FIELD TIME** | Can visitors see a practical difference between FIELD HELD and FIELD EVOLVING? Is the 10 Hz arrow refresh visibly lagged relative to frame-updated particles under normal headset framerate? |
| **Flow — RESET / SEED** | Does RESET preserve noise seed and current field time while scattering particles? Does SEED change noise seed and reset particles without rewinding field time, as the manuscript states? |
| **Flow — wrap seam** | Does the trail renderer actually produce conspicuous cross-canvas segments after wrap, and can a visitor distinguish that drawn segment from the particle’s coordinate teleport? |
| **Flow — boundary field** | Are differences between directions at opposite wrapped edges visible enough to support the claim that particle coordinates wrap while the noise field itself is not periodic? |

---

# 6. What I would not cut

## Do not cut the wide-secants-first construction

The derivative section needs the initial disagreement.

Starting directly with a tangent and saying “this is the derivative” would be clearer in the narrow sense and much weaker pedagogically.

The wide interval gives the visitor a true answer that is insufficient for a more local question.

That is Ada’s method in mathematical form.

---

## Do not cut the four finite STEP values as repetitive

They let the visitor see that changing scale of comparison changes the rate estimate.

The point is not to watch four nearly identical lines. The point is to make the approach itself visible while refusing to pretend the button ever reaches the limit.

---

## Do not cut the analytic derivative because the finite differences are already there

The analytic `df(x)` is doing a different job.

The finite differences are an experiment across chosen intervals.

The analytic derivative gives the bench an independent local comparison.

The manuscript is careful not to say the four secants numerically “prove” the derivative.

---

## Do not cut the held Riemann panel

The held panel is not merely convenience.

A total alone discards where the contribution came from. The held picture keeps some of that construction visible while the live estimate changes.

It therefore materially supports the later critical paragraph about what accumulation loses.

---

## Do not cut the coarse-rule counterexample

> four RIGHT samples can be closer to the reference than four MID samples.

That prevents a textbook heuristic from turning into an absolute hierarchy.

It also reinforces a recurrent Ada claim:

> adequacy is for a task and a configuration, not a moral property of one method.

---

## Do not remove the 4096 reference merely because it is still finite

Its finitude is the lesson.

The manuscript explicitly makes the reassuring “reference” inspectable as another constructed estimate.

Fix the registry language that calls it “true”; keep the comparison.

---

## Do not replace the symmetric FTC arch with a ramp solely to avoid zero net change

A ramp would make the theorem numerically nonzero and perhaps easier.

The symmetric arch makes a more interesting distinction available:

> **net zero ≠ no journey.**

That connects directly to the sequence’s concern with totals that discard history.

The problem is only that the artifact reveals the answer too early.

---

## Do not cut the distinction between positive area and signed rate accumulation

They use similar finite-sum structures but answer different questions.

That distinction matters before Forces, where signs and directions will no longer be optional decoration.

---

## Do not cut the Flow paragraph saying the field is not a gradient

The picture strongly invites viewers to infer “flow downhill through noise.”

The actual implementation does something else:

> scalar noise → angle → unit direction.

Naming that difference is technically and artistically useful.

---

## Do not cut the independent update schedules in Flow

Particles update every rendered frame; arrows refresh at 10 Hz; the field’s time coordinate can be held or evolved.

This is not unnecessary implementation detail.

It extends the book’s recurring investigation of when a displayed representation samples a process on another schedule.

---

## Do not cut RESET versus SEED

They separate:

- new starting distribution;
- new underlying rule.

That is exactly the kind of controlled variation the project wants to teach.

---

## Do not hide the wrap artifact as a rendering defect without first using it

The long cross-canvas line exposes a difference between:

- coordinate wrapping;
- actual path;
- drawn connection between retained samples.

It is a Flow version of Trace’s interpolated gap.

If it is visually readable, it is pedagogically valuable.

---

# 7. Reader-experience strengths to protect

## Discovery before naming

**Derivative**

Two finite samples and STEP precede the analytic tangent.

**Accumulation**

Rectangles and height × width precede “Riemann sum.”

**FTC**

The manuscript asks about a journey and endpoint difference before naming the theorem.

**Flow**

A moving particle precedes the vector-field implementation.

---

## Prediction before explanation

**Derivative**

Will the line keep leaning the same way as h shrinks?

**Riemann**

Which total would you trust before REFERENCE?

**FTC**

What endpoint difference remains after the arch journey?

**Flow**

Where will the particle turn next?

---

## Productive disagreement

This is the real reader engine of Change.

**Derivative**

> wide finite rate negative / local derivative positive.

**Riemann**

> smooth curve / coarse total badly wrong.

**Sampling rule**

> familiar midpoint / coarse right-edge can be closer here.

**FTC**

> visible rise and fall / net zero.

**Flow**

> particle and nearby arrow / same sampler but different addresses.

**Wrap**

> rendered line crosses canvas / update teleported at boundary.

Protect these disagreements. They make the mathematics necessary.

---

## Returns with changed meaning

**Lines / Trace → derivative**

endpoints versus local journey becomes secant versus local rate.

**Portals → calculus limits**

finite members approaching a limit become finite differences / finite sums.

**Array / Grid → Flow**

address is no longer merely selected by a visitor; the update produces the next address.

**Disco / Paint → Flow**

several schedules coexist inside one visible system.

---

# 8. Questions for the author

## 8.1 Should Change Intro have an explicit spatial order?

The manuscript clearly has one.

The map currently gives tangent and accumulation equal entrance depth on opposite sides of the central route.

If you want a visitor to browse these in either order, the prose should be more modular.

If you want the book’s dependency chain, I would stage the room to encourage:

> tangent → sum → bridge.

I prefer the latter.

---

## 8.2 Do you want the FTC bridge equation to function as a title or as a discovery?

At present it functions as a title painted on the object.

The manuscript treats the relation more like a discovery.

Both can work, but the numerical `longhand` equality should not pre-empt the first prediction.

My preference:

> equation can remain as identity; numerical equality waits for a reveal.

---

## 8.3 Is the 10 Hz arrow sampling difference intended as a visible experiment?

The manuscript asks:

> “Can an arrow appear to lag a nearby turn?”

If this is meant to be important, it should be reliably observable in headset.

If it is usually too subtle, keep the fact in technical documentation and let the main ARROWS experiment focus on shared sampler / different address.

---

## 8.4 How much should Change retain the old QFEP framing in source metadata?

The placed manuscript is admirably careful.

The Flow source still contains “λ-edge” claims, and FTC source comments explicitly position the bridge as QFEP’s rate-term substrate.

If these are internal research associations, keep them in research metadata.

I would not let them leak into the beginner-facing explanation unless QFEP itself is being introduced and operationalised there.

---

# 9. Overall conclusion

Change is compact in map count but mathematically dense.

The consolidation into two halls works because the first hall is not actually one lesson. It is a carefully constructed triptych:

> **local change**  
> → **finite accumulation**  
> → **net recovery**

and the second hall turns a static sampling problem into an iterative one:

> **read direction at position**  
> → **move**  
> → **use the new position as the next address**.

The strongest editorial achievement is that the manuscript rarely begins from mathematical vocabulary. It begins from contradictions a visitor can inspect:

- a falling secant on a locally rising curve;
- a coarse rectangle account that changes dramatically when one decision changes;
- a zero total after a nonzero journey;
- a path whose next lookup depends on where the previous instruction carried it.

That is exactly the reader-experience method worth carrying forward.

The highest-value work now is therefore not cutting calculus explanation. It is:

1. **update the sequence metadata so it describes the current consolidated argument;**
2. **make the physical room support the tangent → accumulation → bridge dependency;**
3. **delay the FTC longhand answer until after prediction;**
4. **remove `ARROWS = PARTICLE SAMPLER` from the pre-discovery status;**
5. **clean source/registry rhetoric that is stronger than the implemented mathematics;**
6. **headset-test whether the subtle perceptual distinctions—secant sign, arrow lag, wrap seam—are actually discoverable.**

The reader-experience principle I would carry forward from Change is:

> **Give the visitor two correct answers that disagree before telling them what scale of question makes each one correct.**

And the structural principle is:

> **A total can be correct while forgetting the route that produced it; a local rule can be simple while repeated updates make a history.**
