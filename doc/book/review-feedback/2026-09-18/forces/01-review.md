# Forces — 01 Review

Source-aware editorial and reader-experience review of the **Forces** sequence.

Basis: `forces-book.md`, `forces-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where the visitor can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. Recurrence is not treated as redundancy when an earlier vector or force returns with a different receiver, unit, state history, collision rule, body, or purpose.

The sequence currently reads as:

> **displacement → composition → vector relations → analytic trajectory → accumulated motion → receiver-dependent fields → kinetic effects → restoring dynamics → phase and throughput → mutual attraction → support → encounter → field-as-place**

A second formulation is:

> **The arrow does not tell us what it does. Its consequence depends on what quantity it represents, which body receives it, what state that body already carries, and which parts of the world are allowed to respond.**

This is the sequence’s strongest conceptual achievement. The book repeatedly refuses to let one familiar visual language—an arrow—collapse displacement, direction, velocity, acceleration, force, projection, classification and target selection into the same operation.

---

# 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **Vectors Act1 — What a Vector Is** | **Carries:** an excellent opening reduction: move both endpoints and their addresses change while displacement survives; two projections expose that a diagram keeps only selected components; ZERO shows direction is not hidden inside zero; normalization then deliberately removes magnitude. **Gap:** no major literary problem. The source identity for normalization still speaks as though every tiny nonzero vector is normalized, while the actual lesson uses a `0.001` threshold and the manuscript correctly names it. **Next:** preserve the discovery order and headset-test the pin manipulation, projection clipping and unit-reference readability. |
| **VFM 02 Operations** | **Carries:** vector addition becomes a bodily route before it becomes arithmetic. SWAP preserves destination but changes the turn; PATH preserves destination while changing distance; CANCEL makes zero displacement coexist with a travelled journey. “Zero has not meant that nothing happened” is earned rather than announced. **Gap:** the hall contains many secondary vector objects that could visually compete with its single primary carriage comparison. **Next:** keep the prose; test whether the primary stage remains visually dominant and whether the direct/via-A distinction is legible without reading the counters first. |
| **Vectors Act2 — Vector Arithmetic** | **Carries:** a deliberately long linear sequence from relation to use: immediate addition → directed gap → dot-product classification → projection and remainder → cross-product/turning relation. The hall asks repeatedly “what did this operation keep, and what story did the receiver attach?” **Gap:** the torque instrument prints a fabricated `rpm` number computed as normalized cross-product magnitude × 320 even though no angular dynamics are simulated. The manuscript has to correct the artifact. **Next:** repair the readout rather than relying on prose to disclaim a false measurement. |
| **VFM 05 Launch** | **Carries:** the straight initial velocity vector becomes a full time-dependent trajectory. Complementary launch angles produce the same horizontal range but different flight times; PARTS then separates horizontal/vertical velocity and continuing acceleration. **Gap:** mostly runtime/perceptual. The analytical source supports the stated 30°/60°, 10 m/s, g=10 comparison. **Next:** preserve; headset-test whether the paired lanes, turning around, PATH/PARTS and 64-segment stored path remain readable at body scale. |
| **VFM 03 Motion** | **Carries:** the sequence moves from a curve known in advance to a body that carries velocity between updates. PUSH ends while motion persists; BRAKE and COAST become different operations; MASS changes response without changing silhouette; collision, damping and force can each alter measured acceleration. The friction ramp then deliberately uses a much simpler threshold model, making implementation difference part of the lesson. **Gap:** no major editorial cut indicated. **Next:** preserve and verify that the rigid-body chamber’s pulse/coast/brake distinctions and the ramp’s abrupt STATIC transition are perceptually obvious rather than only textual. |
| **Vectors Act3 — Fields and Motion** | **Carries:** one of the strongest halls in the sequence. Two bodies sample the same spatial field but interpret the sample differently: cyan **sets velocity**, pink **adds acceleration**. Their divergence makes “an arrow does not decide” operational. FIELD/REVERSE/GAIN then show that receiver state matters. **Gap:** the artifact labels the two bodies `SET v` and `ADD to v` before the first RUN, giving away the key distinction the manuscript wants the visitor to discover from their motion. **Next:** delay those labels until PARTS/RULE or after first comparison. |
| **Vectors Act4a — Kinetic Forces** | **Carries:** three deliberately different uses of vector/force language: actual linear drag applied to rigid bodies, nominal signed work accumulated from a chosen force annotation, and centripetal acceleration calculated for a prescribed circular path. The hall’s point is that similar arrows do not imply the same mechanism. **Gap:** manuscript order is drag → mower → ring, while primary placement by authored z is drag `(15,8)` → ring `(9,24)` → mower `(8,37)` from spawn `(15,1)`. The map description itself names mower before ring, suggesting the spatial arrangement may be stale. **Next:** verify walking order and, if necessary, swap/restage ring and mower rather than rewriting the conceptual order. |
| **Vectors Act4b — Oscillation** | **Carries:** a restoring force brings a body to the rest position but momentum carries it through. Damping then separates “remove movement” from “return quickly.” The grab interaction also makes a deliberate choice: hand position is retained, throwing velocity is discarded. **Gap:** little editorially. **Next:** preserve; runtime-test CRITICAL/HEAVY distinctions, hand-release behaviour and whether the force arrows are readable through a crossing. |
| **Change Choreography** | **Carries:** two kinds of temporal relation. Rods distinguish phase offset from frequency drift; the conveyor turns a mismatch of arrival and service intervals into accumulated spatial history. RECOVER then changes capacity without erasing backlog. **Gap:** no primary prose problem, but its placed outgoing utility is an untargeted `t` and the previous Oscillation hall’s explicit portal points to Force-as-Place rather than here. **Next:** reconcile navigation utilities before judging this hall’s museum accessibility. |
| **VFM 07 Gravity** | **Carries:** the question “who gets to stay still?” exposes implementation privilege. First one source is held fixed; then mutual equal masses share response; adding a third body changes the summed relations; NUDGE turns initial difference into measured separation without claiming a proof of chaos. **Gap:** the artifact’s always-visible board says “The source is held fixed; only the satellite receives acceleration” before the manuscript asks “Why has it not moved?” This weakens discovery. The manuscript’s specific 3 cm → ~7.6 cm after 4 s claim is described as a checked run but no runtime capture is attached. **Next:** delay the fixed-source explanation until RULE/PARTS and retain the measured claim only with runtime evidence. |
| **VFM 09 Legs** | **Carries:** physical support is first negotiated by a rigid plate and finite support pads; then a convincing four-legged gait is shown not to solve that support problem because the walker’s body is commanded directly. This is an excellent critical return from visual plausibility to mechanism. **Gap:** the `four_leg_critter` source identity says diagonal pairing/trot “emerges” and is demanded by geometry, while the actual implementation and manuscript say one leg at a time, chosen by a branch. **Next:** clean the source/registry identity; keep the manuscript. |
| **VFM 08 Arena** | **Carries:** the first half asks what makes something a target—visibility, distance, nominated visitor, food, feeding state—and carefully separates implementation from interpretations such as trust or friendship. The second half asks what an encounter preserves when momentum conservation constrains two bodies. Both concern relation, but with different mechanisms. **Gap:** the scoped crab source is included, but its inherited `head_crab.gd` and mushroom base are not, so steering/failed-target exclusions and some food behaviour are not fully source-verifiable from this ZIP. **Next:** include inherited sources in the next bundle; runtime-test the encounter before simplifying the prose. |
| **Vectors Act5 — Force as Place** | **Carries:** a strong culmination. A vector first becomes an adjustable local acceleration, then acts on a loose cube, then on the visitor through a separate movement receiver. The retained plank becomes part of the argument: contact underneath and acceleration around you are two different ways of making passage. **Gap:** source/registry identities still call the zone and machine “force” while the configured lesson correctly labels the quantity **acceleration** and applies it directly as `Δv = a·dt`. The sentence “It is the oldest problem in spherical coordinates” is an unsupported historical superlative. **Next:** clean the source terminology and replace that sentence with a technical description of the polar/azimuth singularity. |

---

# 2. Sequence structure

Forces is long—thirteen halls—but it has a coherent dependency chain. The repeated arrow is not the sequence’s weakness; it is the controlled object whose meaning keeps changing.

The actual arc is:

1. **A vector as retained relation**  
   Two positions can move together while their displacement remains.

2. **A vector as composable displacement**  
   Contributions add; route and destination can diverge.

3. **A vector as operation**  
   Subtraction, dot, projection and cross product answer different questions.

4. **A vector as initial condition**  
   Launch velocity enters a temporal equation.

5. **A vector as continuing influence**  
   Force changes a velocity already carried by a body.

6. **A field as input awaiting interpretation**  
   The same sample can be read as velocity or acceleration.

7. **Forces as state-dependent interactions**  
   Drag depends on velocity; work depends on force/displacement relation; turning depends on speed and radius.

8. **Restoring force as state-dependent return**  
   Position and velocity together determine what happens next.

9. **Time relations as collective form**  
   Phase and throughput differences accumulate into patterns/backlogs.

10. **Interaction as mutual relation**  
    Gravity can withhold or permit reaction.

11. **Contact as support**  
    Stillness itself becomes an outcome of collision and geometry.

12. **Encounter as sensing/state/conservation**  
    A body can be guided by a controller or constrained by an interaction law.

13. **A vector as property of a place**  
    The final hall asks where an instruction actually enters a receiver.

That structure is strong enough that I would not reduce the sequence simply to make it shorter.

The main structural weakness is not conceptual repetition. It is **museum navigation metadata that appears to predate this thirteen-hall order**.

---

# 3. Reader-experience lens

## Vectors Act1 — What a Vector Is

### Curiosity

> “Can something move without its vector changing?”

is a very good opening because the answer is not obvious to a beginner if “vector” has been visually attached to an arrow between two points.

SHIFT then makes the question concrete: both endpoints move while the yellow wall arrows remain unchanged.

### Discovery

The order is strong:

- manipulate pins;
- compare two projections;
- change length;
- shift both endpoints;
- only then reveal components/magnitude;
- then collapse to zero;
- finally normalize another vector.

The surprising result is **unchanged output after visible movement**. That is exactly the kind of negative evidence Ada handles well.

### Timing

PARTS is hidden until requested. Good.

ZERO comes after displacement has been understood. Good.

Normalization comes after free displacement, so “remove magnitude / keep direction” has something to operate on.

### Return

Point One’s reference frames and Lines’ endpoint relation return here, but the purpose is different: the vector becomes portable because the original addresses are deliberately discarded.

Do not cut that callback.

---

## VFM 02 Operations

### Curiosity

The first GO gives a bodily journey before the arithmetic appears.

SWAP is especially effective because something obvious changes—the corner—while something important does not—the destination.

### Discovery

The sequence:

> GO → SWAP → PATH → RULE → CANCEL

is excellent.

CANCEL is strongest because it produces a zero vector without producing a zero journey.

### Timing

The formula `result = a + b` arrives late enough. The visitor has already seen two displacements produce one destination.

The direct-route comparison similarly arrives before the distance interpretation.

### Return

Change’s accumulation returns as travelled distance. Trace returns as route history. Both survive a zero displacement.

“Zero has not meant that nothing happened” is therefore not rhetoric pasted onto vector arithmetic; the carriage has enacted it.

---

## Vectors Act2 — Vector Arithmetic

### Curiosity

This hall is broad, but its physical route is linear:

- immediate addition;
- subtraction;
- dot alignment;
- projection;
- torque.

Each station narrows a different question about what a vector relation can keep.

### Discovery

The subtraction/projection pair is particularly good because it uses the **actual live gap** from one station as the next station’s input.

The projection then keeps the excluded part visible in pink.

The visitor can discover that “remainder” means **excluded from this question**, not disappeared.

The dot-aligner’s FRIEND threshold introduces another layer: a continuous geometric agreement becomes a categorical status.

### Timing

The torque crank is the weak point.

The manuscript correctly asks the visitor to notice that `rpm` is not measured rotation. But the artifact presents the number as if it were an instrument reading.

That makes the prose corrective rather than exploratory.

### Return

The hall is doing useful recurrence:

- addition from VFM02 returns without the carriage;
- SHIFT from Act1 returns inside subtraction;
- dot and projection reuse the same idea of asking a vector along a direction;
- projection prepares the perpendicular component that matters for torque.

Do not cut the sequence into isolated formula exhibits.

---

## VFM 05 Launch

### Curiosity

> “Does aiming higher always carry the marker farther?”

is an excellent prediction question.

The paired 30°/60° comparison then gives a pleasing result:

- same horizontal range;
- different time aloft;
- different occupied height.

### Discovery

PAIR is strong because it makes equivalence conditional:

> same X in separate lanes, not literally same world position.

SLOW is also good reader design: it changes observation time without changing model time/path.

PARTS arrives after the trajectory has been watched.

### Timing

The analytic rule is hidden behind RULE.

PATH is optional.

The room lets the trajectory exist first as an event, then as stored prediction, then as components/equation.

Excellent.

### Return

Transformation’s “same destination, different journey” returns with time and velocity now inside the model.

That recurrence changes meaning.

---

## VFM 03 Motion

### Curiosity

> “The command lasts one second. The cube keeps going.”

This is one of the strongest short surprises in the sequence.

The visitor expects the button action to end with the button. The body disagrees.

### Discovery

COAST and BRAKE are good contrasting words because ordinary language could make both sound like “stop doing something.”

The experiment shows:

- COAST = stop adding that command;
- BRAKE = add a new opposing influence.

DRAG then creates another distinction: motion can decay after command ends because the receiver’s dynamics changed.

### Timing

PARTS and RULE are delayed.

The ramp appears only after the large chamber has established persistence, so its abrupt threshold model can be read as **another implementation**, not “the physics of friction.”

### Return

Change’s accumulation is now velocity.

Reset again appears as a privileged operation that can erase state instantly.

The trail’s finite recent history also returns Trace without re-teaching Trace.

---

## Vectors Act3 — Fields and Motion

### Curiosity

This hall has an excellent visual puzzle:

> two bodies start together in the same field; one stops at the centre, the other crosses and returns.

The question:

> “What did the second body bring through a place where the first was coming to rest?”

is exactly right.

### Discovery

The intended reveal sequence is:

1. RUN;
2. observe divergence;
3. TRAILS;
4. ARROWS;
5. only then RULE.

The field is the same. The receivers differ.

This gives the equals / plus-equals distinction real bodily consequence.

### Timing

The artifact undermines this slightly by putting visible nameplates on the bodies from the beginning:

- `SET v`
- `ADD to v`

Those labels essentially explain the answer before the first run.

The code is still worth revealing later. The labels should wait.

### Return

Flow Field from Change returns, but now the new question is not how a direction field makes a path. It is:

> **What does the receiver do with the sample?**

This is a major conceptual progression.

---

## Vectors Act4a — Kinetic Forces

### Curiosity

Each sub-encounter has a distinct bodily hook:

- three cubes launched into named “media”;
- a lawn that records passage irreversibly;
- a pod moving on a large circle.

The manuscript is careful to resist the names:

> air/water/honey are coefficients, not simulated fluids.

Good.

### Discovery

Drag makes state-dependent force visible.

The mower is excellent because three records disagree:

- path length;
- signed nominal work;
- cut grass.

Returning can cancel one and not the others.

The ring then gives another vector relation:

- velocity tangent;
- acceleration inward;
- speed can stay constant while velocity changes.

### Timing

The conceptual order in the manuscript is strong:

> applied force → annotated work → required acceleration.

But the authored coordinates place the ring before the mower along increasing z from the recorded spawn.

That risks giving the hall a different argument physically.

### Return

The mower’s “return is not undo” is an especially important return of the entire book.

Keep it.

---

## Vectors Act4b — Oscillation

### Curiosity

RELEASE is excellent because the expected destination—the rest line—is not where movement ends.

> “It goes through.”

is enough.

### Discovery

The visitor first sees overshoot, then adds damping.

Only later does PARTS reveal:

- restoring force;
- damping force;
- their sum.

PULL / hand grabbing also shows that the experiment retains selected initial data: displacement, not throw velocity.

### Timing

Very good.

The critical discussion of “restoring” comes late, after the visitor has seen what the system actually restores and what it ignores.

### Return

The room prepares Wavefunctions without pretending the spring is directly prescribed by a cosine.

That distinction is important.

---

## Change Choreography

### Curiosity

ONE+ is a simple and effective disturbance.

The visitor sees one rod out of relation while all periods remain equal.

WAVE then produces apparent travelling motion without any rotor translating across the array.

### Discovery

The hall distinguishes:

- phase offset;
- frequency difference;
- collective pattern.

The conveyor repeats the logic in a material system:

- matched arrival/service rates;
- transport delay;
- backlog after service mismatch;
- recovery without history erasure.

### Timing

RULE comes after WAVE.

The conveyor’s count equation comes after a pile has started.

Good.

### Return

Change returns here explicitly, but appropriately: the hall shifts from the calculus of one changing quantity to relations among repeated processes.

---

## VFM 07 Gravity

### Curiosity

The opening works because the pink source appears physically like a body yet remains still.

> “Why has it not moved?”

is a productive question.

Then the mutual pair removes that privilege.

### Discovery

Strong progression:

- fixed-source orbit;
- REVERSE;
- reveal omitted reaction;
- equal mutual pair;
- add third body;
- NUDGE second copy;
- observe separation.

The manuscript is particularly careful around chaos:

> tangled trails are not enough;
> one four-second departure does not establish exponential sensitivity.

This restraint should remain.

### Timing

The artifact currently writes on its board from the beginning:

> “The source is held fixed; only the satellite receives acceleration.”

That answers the manuscript’s later question too soon.

Move that statement behind RULE/PARTS.

### Return

The first vector hall’s “reference need not move” becomes political/mechanical here:

> a reference can be useful because the implementation has denied it a response.

That is a meaningful development.

---

## VFM 09 Legs

### Curiosity

> “Almost nothing happens.”

is excellent.

The plate’s tiny drop makes standing itself visible as an event produced by contact.

Removing one support and shifting the load then turns stillness into prediction.

### Discovery

PARTS reveals:

- centre of mass;
- projection;
- finite support footprint.

The progression from four supports → three → adjacent pair → opposite pair is good because **same count / different relation** becomes visible.

Then the walker appears to answer the problem—but does not.

### Timing

The manuscript wisely lets the walker look convincing before explaining that its body is simply moved by patrol code and does not negotiate support.

Excellent.

### Return

Point/width questions return through feet:

> a foot is not necessarily a point.

This is a particularly good long-range callback.

---

## VFM 08 Arena

### Curiosity

The first encounter benefits from the familiar crab-like body and the visitor’s own expectations.

RUN, BEACON and FOOD alter direction without changing legs.

Then VISITOR places the user into the candidate comparison.

### Discovery

SCREEN makes visibility operational.

PARTS distinguishes current selected target from retained meal count.

The five-meal stopping threshold then creates a state whose name—`rooted`—invites interpretation but does not justify one.

The manuscript is very good here:

> feeding changed state; it did not train a policy.

### Timing

The no-bite disclosure comes early. That is appropriate because it changes what a visitor can safely risk in the experiment.

The target rule is delayed until after multiple manipulations.

### Return

Collision carts then change the kind of relation completely:

- controller selection asks who becomes a target;
- collision diagram asks what a physical interaction must conserve under assumptions.

This is broad, but the heading “What makes an encounter?” is capacious enough to hold both.

---

## Vectors Act5 — Force as Place

### Curiosity

The opening is strong because the hall begins with a gap and two possible routes.

The yaw-at-pole behaviour is also a genuine instrument puzzle:

> move a control and nothing changes.

The ghost arrow makes the “inactive” parameter still visible as retained state.

### Discovery

The progression is excellent:

1. aim local acceleration;
2. observe cube motion;
3. enter the field yourself;
4. compare cube and visitor receivers;
5. set acceleration to zero while retaining incoming velocity;
6. reconsider the solid plank.

This is the whole sequence condensed into one room:

> value → receiver → state → consequence.

### Timing

The technical explanation of the coordinate singularity is good, but:

> “It is the oldest problem in spherical coordinates”

is an unsupported historical superlative and does no necessary work.

The configured machine already labels the third slider ACCEL, and the field readout says LOCAL ACCELERATION. The manuscript follows that implementation.

### Return

The plank is not an embarrassing leftover. It is now evidence:

> writing the same vector into the world did not automatically make the visitor a receiver.

Keeping the repair is exactly right.

---

# 4. Five high-value changes

## 4.1 Reconcile the navigation utilities with the declared thirteen-hall sequence

**Evidence type:** CAPTURE / SOURCE QUESTION

The package reports:

> Declared sequence order and museum map-authored order agree.

At the metadata level, they do.

However, the placed `t:` utility tokens tell a different story.

Recorded explicit targets include:

- `Vectors_Act1_WhatAVectorIs` at `(7,20)` → `t:Vectors_Act2_VectorArithmetic`  
  **skips `VFM_02_Operations`**

- `Vectors_Act2_VectorArithmetic` at `(9,36)` → `t:Vectors_Act3_FieldsAndMotion`  
  **skips `VFM_05_Launch` and `VFM_03_Motion`**

- `Vectors_Act4b_Oscillation` at `(15,18)` → `t:Vectors_Act5_ForceAsPlace`  
  **skips `Change_Choreography`, Gravity, Legs and Arena**

- `Change_Choreography` at `(12,24)` has bare `t` with no explicit target in the raw token

- `Vectors_Act5_ForceAsPlace` at `(8,20)` → `t:Vectors_Act1_WhatAVectorIs`  
  while the declared next sequence is Form Finding.

Other halls do have explicit targets matching the declared order, e.g.:

- Launch → Motion
- Motion → Fields and Motion
- Fields and Motion → Kinetic Forces
- Gravity → Legs
- Legs → Arena
- Arena → Force as Place.

### Why this matters

The manuscript is strongly cumulative. Skipping VFM02, Launch/Motion, or the late sequence removes dependencies the following chapters explicitly assume.

The brief correctly warns:

> a portal utility need not retain standalone-level behaviour inside the museum.

So this is **not proof that runtime navigation is broken**.

### Proposal

Resolve `t` through the museum’s current `UtilityRegistry.gd` / `GridUtilitiesComponent.gd` and then walk the sequence.

If these raw targets remain active museum navigation, update them to the current curriculum order.

If museum assembly overrides them, document that override in the review bundle so future source reviews do not repeatedly treat the raw route as ambiguous.

### Reason

This is more important than any line edit. A carefully cumulative curriculum cannot rely on readers discovering skipped halls manually.

---

## 4.2 Vector Arithmetic — repair the torque instrument’s fake `rpm`

**Hall / instance**

`Vectors_Act2_VectorArithmetic`  
A9 `(6,27)`  
`torque_crank`

### Work performed by the passage

The manuscript uses the crank to make an important distinction:

- cross product gives a geometric relation;
- torque in physics also needs actual lever length and force magnitude;
- dynamics would need inertia and time;
- the current wheel pose is illustrative, not a simulated rotating machine.

That work is valuable.

### SOURCE

`commons/artifacts/torque_crank/torque_crank.gd`

The artifact computes:

```gdscript
var torque_vec = r_dir.cross(f_dir)
var torque_mag = torque_vec.length()
...
var rpm: int = int(roundf(torque_mag * 320.0))
```

and prints:

```text
CROSS r × F
τ = ...
θ = ...
... rpm
```

No rotation counter or angular velocity integration exists.

The manuscript explicitly says:

> “In this implementation it is the factor multiplied by 320 and rounded. It is not a rotation counter.”

### Artifact proposal

Do not keep a false unit merely so the prose can expose it.

Replace `rpm` with something operationally true, for example:

> **TURN FACTOR 0–1**

or:

> **illustrated wheel angle**

If the historical/misleading instrument quality is artistically desired, mark it visibly:

> **RPM?  illustrative scale only**

Then the manuscript can still ask what would be required to make it a real measurement.

### Reason

A critical tutorial should expose constructed measurements, but it should not accidentally manufacture a false physical unit and rely on the book to rescue it.

The stronger experiment is:

> here is a correct geometric relation; what additional state would be needed before `rpm` could legitimately appear?

---

## 4.3 Fields and Motion — delay `SET v` / `ADD to v` until after the first divergence

**Hall / instance**

`Vectors_Act3_FieldsAndMotion`  
A1 `(9,7)`  
`VectorFieldFlow#lesson:field_receivers`

### Current manuscript

The reader is first asked to RUN and observe:

- cyan slows to the centre;
- pink crosses, continues, returns.

Only afterward does the manuscript explain that the two receivers treat the same sample differently.

### SOURCE

`algorithms/vectors/10_vector_field_flow/field_receivers.gd::_ready()`

Each body receives a visible nameplate immediately:

```gdscript
nameplate.text = "SET v" if i == 0 else "ADD to v"
```

### Artifact proposal

Initial labels:

- **CYAN**
- **PINK**

or no semantic label beyond colour.

Reveal the mechanism label when:

- PARTS is pressed;
- RULE is pressed;
- or after the first pause/run cycle.

Then show:

- **SET v**
- **ADD to v**

### Reason

The hall’s strongest reader experience is wondering how two bodies in the same field can behave so differently.

Let motion generate that question before the answer is written on the bodies.

---

## 4.4 Gravity — delay the explanation of the fixed source

**Hall / instance**

`VFM_07_Gravity`  
A1 `(11,8)`  
`orbital_mechanics_demo#lesson:gravity_orbit`

### Current manuscript

The visitor first watches the satellite orbit and later receives the question:

> “Look again at the pink body. Why has it not moved?”

Then code reveals that body zero is excluded from acceleration.

### SOURCE

`commons/artifacts/orbital_mechanics_demo/gravity_relations.gd::update_text()`

The initial board already says:

> “The source is held fixed; only the satellite receives acceleration.”

This is visible before RULE.

### Artifact proposal

Initial board:

> Change the starting speed, then RUN.  
> Walk inside the calculation.  
> Which body responds, and which does not?

After PARTS or RULE:

> Source mass 12 kg; satellite 1 kg.  
> **Reaction on body zero omitted.**

Keep the code reveal where it is.

### Reason

This is precisely the kind of implementation privilege the chapter wants the visitor to notice.

Do not label the privilege before it has become strange.

---

## 4.5 Kinetic Forces — make the physical order match the manuscript’s argument

**Hall / primary placements**

Spawn: `(15,1)`

- drag corridor `(15,8)`
- centrifuge ring `(9,24)`
- force mower `(8,37)`

Current manuscript order:

1. drag corridor
2. force mower
3. centrifuge ring

The map’s own description also says:

> drag probes open the hall; **the mower** compares signed work; **the ring** compares speed and centripetal acceleration.

### Work performed by manuscript order

This order develops:

1. **a force actually applied to a rigid body**
2. **a chosen force used to annotate work along a human-controlled path**
3. **an acceleration required by a path that is prescribed rather than dynamically produced**

The closing sentence can then legitimately say:

> we have met an applied force, a force chosen for work annotation, and an acceleration calculated from a prescribed path.

### Spatial problem

From the recorded spawn and authored z coordinates, the ring lies before the mower in the forward direction.

There is also a `t:Vectors_Act4b_Oscillation` utility at `(15,18)`, before both later primary stations, which makes the need for route verification even stronger.

### Proposal

First verify the assembled museum route and teleporter behaviour.

If the forward path really presents ring before mower:

- move mower into the middle zone and ring toward the later zone; or
- exchange their placement regions.

Do not reorder the manuscript unless there is a strong artistic reason to prefer:

> drag → prescribed circular acceleration → work/history.

### Reason

This is not cosmetic. The present prose uses each experiment to qualify the previous one.

The hall should let the body encounter that argument in the same order.

---

# 5. Source / artifact discrepancies

## 5.1 The declared objective list is substantially older and broader than the current manuscript

The sequence-level objectives include:

- “Projection and reflection: mirrors and collisions”
- “Gravity: constant downward acceleration (9.8 m/s²)”
- “Attraction and repulsion: inverse square laws”
- “Particle systems: many bodies under forces”
- “N-body dynamics: gravitational chaos from simple rules”
- “F = ma is calculus made physical”

Several do not accurately describe the current primary route.

### Projection and reflection

Projection is central. Vector reflection is not a primary current lesson, and collision carts are about 1D elastic momentum exchange, not vector reflection.

### Gravity

The sequence contains several different gravity models:

- Launch: configurable uniform downward `g = 10` or `15 m/s²`
- Motion: gravity explicitly removed
- Gravity hall: softened inverse-square-like pair interaction with `G = 1`
- Support lab: engine gravity
- Force as Place: local configurable acceleration initially set to `9.8 m/s²` downward.

“Gravity: constant downward acceleration 9.8” therefore describes only one local starting condition.

### Attraction and repulsion

The current primary Gravity hall implements attraction. Repulsion is not part of the manuscript’s main encounter.

### Particle systems

There are many bodies in several halls, but “particle systems” is not a developed primary concept in this sequence.

### Chaos

The manuscript explicitly says the three-body nudge comparison does **not** establish chaos or exponential separation.

So “gravitational chaos from simple rules” overstates what the current lesson demonstrates.

### `F = ma is calculus made physical`

The manuscript’s actual bridge is more precise:

- velocity is retained state;
- force/mass contributes acceleration;
- acceleration changes velocity over time;
- velocity carries position.

`F = ma` itself is an algebraic relation.

### Proposed objective rewrite

Use objectives such as:

- represent displacement independently of origin and inspect what projections/normalisation discard;
- compose, subtract, classify and project vectors while keeping units and frames explicit;
- distinguish destination vectors, velocity, acceleration and force by how receivers use them;
- compare analytic trajectory with stateful integration;
- compare prescribed velocity with accumulated acceleration in the same field;
- inspect drag, work annotation, centripetal acceleration, spring restoration and gravity as different state relations;
- distinguish commanded locomotion from physically supported or momentum-conserving motion;
- investigate how sensing, collision, support and field boundaries decide which bodies can interact;
- treat short numerical divergence in N-body motion as measured departure, not by itself as proof of chaos.

Also fix the mojibake in the generated objective text (`âˆš`, `aÂ·b`, etc.).

---

## 5.2 `four_leg_critter` identity contradicts its actual gait implementation

The source header says:

> diagonal pairs alternate; trot/gallop emerge; four legs naturally fall into this pattern; geometry demands it.

The actual implementation says, and the code enforces:

> **Only one leg steps at a time.**

It finds the planted leg furthest beyond `step_threshold` while no other leg is stepping.

The manuscript correctly says:

> “Four legs have not forced it into a trot; a branch in the program has chosen this sequence.”

### SOURCE / registry maintenance

Rewrite the artifact identity and registry description around the actual mechanism:

> planted feet remain fixed in world space; when no leg is stepping, the most overextended planted foot is moved to a new target; one leg steps at a time.

Do not reintroduce diagonal-pair claims into the book.

This is a significant example of stale conceptual metadata being more deterministic and biologically sweeping than the current code.

---

## 5.3 The torque-crank source and readout confuse angular factor with rotational rate

As above:

- cross-product direction/magnitude are computed;
- wheel pose is derived from that magnitude;
- displayed `rpm` is `round(torque_mag * 320)`.

No angular velocity is integrated.

The manuscript is technically correct to reject the readout as measurement.

Prefer correcting the artifact/source.

---

## 5.4 `centrifuge_ring` source rhetoric repeatedly calls its inward arrow “force,” but the implementation draws acceleration

The code draws:

```gdscript
v * v / radius
```

scaled as an arrow.

No mass enters the value.

The current visible label is more careful:

> `a = v²/r`

although it adds `(F = m·a, inward)`.

The manuscript correctly calls the primary quantity **inward acceleration** and explicitly says the pod is prescribed onto the circular path rather than dynamically held there by a simulated centripetal force.

### SOURCE maintenance

Change identity language from:

> “centripetal force”

to:

> “required centripetal acceleration for this prescribed circular motion”

unless a mass/force receiver is later implemented.

---

## 5.5 `force_cube`, `vector_machine` and `force_field_zone` contain legacy “force” naming that the configured final lesson has already corrected

### `force_cube`

Header language calls the live vector the force you apply.

But the current process computes:

```gdscript
vel = (global_position - _last_pos) / delta
f_world = (vel * 0.5).limit_length(2.6)
```

The manuscript correctly calls it a **motion arrow** and explicitly notes that `f_world` is a stale variable name.

### `vector_machine`

Legacy identity calls the third slider FORCE.

In `lesson:force_as_place`, the actual UI changes it to:

> **ACCEL**

and the readout replaces `F` / `|F|` with `a` / `|a|` and adds `m/s²`.

### `force_field_zone`

Legacy identity says “force field” and “the field is the only force.”

In the configured lesson, the readout correctly says:

> **LOCAL ACCELERATION**

and the implementation applies:

```gdscript
rb.linear_velocity += field_vector * delta
```

without dividing by mass.

The manuscript is aligned with the implementation.

### SOURCE / registry maintenance

Keep the historical class/token names if renaming is costly, but make the current configured semantics explicit in headers and registry descriptions.

---

## 5.6 Collision-carts source rhetoric is broader than the model

The source identity says:

> “momentum is shared but never spent — the books always balance; the only question is how the world splits the velocity between the two of them.”

The actual artifact is a very specific analytic case:

- one-dimensional;
- isolated;
- elastic;
- target initially at rest;
- striker speed fixed;
- mass ratio varied.

The manuscript correctly names those assumptions and notes that sticking would be a different collision law while momentum could still be conserved.

Clean the source identity rather than broadening the book.

---

## 5.7 Arena’s inherited controller and food dependencies are not fully included

The ZIP includes:

- `arena_relation_lab.gd`
- `lesson_crab.gd`
- `lesson_food.gd`

but lists further dependencies including:

- `res://commons/hazards/head_crab/head_crab.gd`
- `res://commons/artifacts/spore_mushroom/spore_mushroom.gd`

The manuscript refers to inherited failed-target exclusion, steering/gait and food behaviour.

Those claims cannot be fully source-verified from this snapshot.

### Next bundle

When a primary lesson subclasses a large controller whose inherited behaviour remains part of the prose, include the base class as primary evidence even if it is more than two static hops away.

---

## 5.8 Kinetic WALK behaviour depends on a source not bundled

`kinetic_drag.gd` clearly says the walking adapter uses:

> `1 / (1 + b)`

and the manuscript reports approximate factors:

- 0.71
- 0.43
- 0.24.

However, the actual movement-provider implementation:

`kinetic_walk_provider.gd`

is listed among dependencies not traversed.

So the arithmetic mapping is source-supported, but exact XR/controller application is not independently inspectable in this ZIP.

Runtime/headset verification remains necessary.

---

## 5.9 The Gravity hall’s measured 7.6 cm departure is not accompanied by runtime evidence in this bundle

The source supports:

- NUDGE values `[0, 0.03, 0.15]`;
- a second copy;
- deterministic integration;
- RMS separation readout.

But the manuscript says:

> in the checked three-body run, 3 cm produced about 7.6 cm paired difference after four seconds.

No capture/check file is included under `evidence/`.

Treat this as a prior measured result, not a result independently verified by this review package.

Either attach the check next time or phrase the number as dated runtime evidence.

---

# 6. Runtime questions

No repository code was executed. Every hall still records `learner_verified: false`; statuses say desktop-verified/headset-pending, but those are prior labels rather than proof of this snapshot’s current embodied experience.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Sequence navigation** | Resolve every placed `t:` utility through the museum utility system. Which hall does the visitor actually reach from each exit? Do any explicit targets still skip the current declared curriculum? |
| **Vector Act1 — pins** | Are both vector endpoints comfortably grabbable in headset? Does SHIFT visibly move both pins while the wall projections remain unchanged? |
| **Vector Act1 — projections** | Can a visitor distinguish XY elevation from XZ floor plan without reading the labels repeatedly? Is clipping visibly labelled when the projection exceeds the 1.05 m drawing window? |
| **Vector Act1 — normalize** | Can a learner see that a short input grows while a long input shrinks toward unit length? Is the `≤0.001 → zero` threshold reachable/legible in the actual controller? |
| **VFM02 — route** | Does GO reliably execute via-A and direct paths at the prescribed speed? Does SWAP visibly move the corner while preserving cyan destination? |
| **VFM02 — CANCEL** | With B = −A, does via-A visibly leave and return while the direct path remains home? Does travelled distance exclude the instant reset as stated? |
| **Vector Arithmetic — route hierarchy** | Do the five primary stations form a readable linear progression through the room, or do secondary exhibits pull attention away before subtraction/projection continuity can be understood? |
| **Dot aligner** | Is the transition to FRIEND at dot `0.985` obvious enough to provoke the critical classification question rather than simply reading as game success? |
| **Projection** | Does the live subtraction station actually feed the projection station in the assembled hall? When SLIDE changes only the perpendicular component, does gold remain stable while pink grows? |
| **Torque** | Does the current `rpm` label read as a genuine measurement to learners? If renamed, can the relation between leverage angle and cross-product factor still be discovered without false dynamics? |
| **Launch — paired range** | At 30°/60°, speed 10, g=10, do the two markers visibly land at equal X while at different times? Is lane separation clear enough that “same X, different world address” is understandable? |
| **Launch — SLOW/PATH** | Does SLOW genuinely alter only playback clock? Are 64 stored path segments visible as a different representation from frame-evaluated marker motion? |
| **Motion — pulse** | After a one-second PUSH X, does the cube continue clearly enough that persistence is immediately evident? Can COAST during the pulse shorten the acquired velocity as intended? |
| **Motion — BRAKE/DRAG** | Does BRAKE stop gradually without reversing near rest? Does DRAG continue deceleration after COAST? |
| **Motion — boundary** | Does the cube rebound from the amber boundary while player/furniture cross or remain unaffected as described? |
| **Friction ramp** | Can the visitor approach the STATIC/SLIDING threshold slowly enough with μ and ANGLE to see a continuous parameter crossing produce a discrete state change? |
| **Friction ramp — mid-motion edit** | If μ is raised into STATIC while sliding, does velocity visibly cut to zero? Is that discontinuity understandable as this model’s rule rather than a physics claim? |
| **Fields — first run** | With semantic labels hidden, can visitors reliably observe cyan settling and pink overshooting before RULE is revealed? |
| **Fields — UNIFORM** | At gain one, does the first-second comparison match the stated ~0.8 m versus ~0.4 m / 0.8 m/s behaviour to displayed precision? |
| **Fields — REVERSE** | During motion, does cyan reverse on the next update while pink decelerates before turning? Is the difference visible at body scale? |
| **Kinetic — spatial order** | From the spawn, which primary encounter is naturally reached second: centrifuge ring or mower? Does the teleporter at z18 trigger before either? |
| **Kinetic — drag** | At equal 4 m/s starts, do the three probes visibly separate by coefficient? Does mass 2/4 kg slow the deceleration as expected? |
| **Kinetic — WALK** | With WALK enabled, do desktop and XR stick movement use the intended factors, and does ordinary movement return immediately outside the corridor? Physical room-scale walking must remain unaffected. |
| **Mower** | Can the mower be returned without rotating enough to make signed work approach its prior value while path keeps increasing and cut grass remains? Does grab constraint truly keep it upright/on-plane? |
| **Centrifuge** | Do SPEED settings 2/4/6 m/s preserve phase across changes? Are velocity and inward acceleration arrows distinguishable, and does acceleration visibly scale quadratically? |
| **Oscillation — release** | Does releasing from rest clearly overshoot the zero-force line in FREE and LIGHT modes? |
| **Oscillation — critical/heavy** | Under same initial displacement, does CRITICAL return without crossing faster than HEAVY, as expected from the configured damping ratios? |
| **Oscillation — grab** | Does releasing after hand movement truly start with zero model velocity, making the discarded throwing speed perceptible rather than merely textual? |
| **Choreography — ONE+/WAVE** | Does one rod’s phase jump read as fixed offset rather than delay? Does WAVE appear to travel across stationary bases? |
| **Choreography — DRIFT** | Is 4% frequency difference perceptible over a reasonable visit, even though full realignment takes 150 s? |
| **Conveyor** | Does matched 1.2/1.2 s operation maintain occupancy without growth? Under BACK UP (3 s receiver), what first visible sign of backlog appears? |
| **Conveyor — capacity/recovery** | Does inlet hold when occupied and feed hold at 48 live parcels? Does RECOVER at 0.6 s clear history gradually rather than instantly? |
| **Gravity — fixed source** | With explanatory board delayed, do visitors notice that pink stays fixed and ask why before seeing RULE? |
| **Gravity — reverse** | Does velocity reversal approximately retrace the single-satellite path under the softened conservative model at current integration settings? |
| **Gravity — NUDGE** | Reproduce and attach the 3 cm / four-second separation measurement if the ~7.6 cm number is to remain in main prose. |
| **Gravity — trail/frame** | Does PATH retain ~12 seconds at 20 Hz and does the golden frame pause the model without a collision-like visual cue? |
| **Legs — support lab** | Does positive/negative initial support margin correlate with the opening release as intended across support/load configurations? Test marginal cases near hull boundary. |
| **Legs — opposite supports** | With two diagonal 16 cm pads, is the narrow support region visible enough to distinguish finite pads from ideal point supports? |
| **Legs — walker** | Does one and only one foot step at a time in the current four-leg critter? Does the foot remain visibly planted in world space before swing? |
| **Arena — targets** | With beacon/food/visitor configurations, does closest visible candidate within 6 m reliably win? Test occlusion and the 0.2 m horizontal sight ray. |
| **Arena — feeding** | Does a meal remain uninterrupted for two seconds once begun? Does five completed meals reliably produce rooted/stopped state rather than learned policy? |
| **Arena — inherited controller** | Verify failed-target exclusion, obstacle steering and gait using the missing `head_crab.gd` base. |
| **Collision carts** | Across light/equal/heavy striker ratios, do arrow directions and cart widths make before/after body identity unambiguous? |
| **Force as Place — yaw pole** | At vertical pitch, does YAW visibly do nothing to the main vector while the ghost bearing responds? Is the “idle” state understandable rather than seeming broken? |
| **Force cube** | When a held cube stops, does the motion arrow disappear in the configured lesson? Does orientation correctly change component-leg axes without changing world velocity? |
| **Field zone — rigid cube** | On entry, is gravity replaced while contact/damping remain? On exit, is the previous `gravity_scale` restored? |
| **Field zone — visitor** | In XR and desktop, does the exclusive carry provider retain incoming/post-collision velocity and add local acceleration while inside, then hand control back cleanly at exit? |
| **Field zone — zero accel** | With ACCEL zero, does the visitor retain incoming motion while the loose cube decays through damping, making receiver difference bodily legible? |
| **Plank comparison** | Is the solid plank still available and obviously distinct from field carry? Does it genuinely help the visitor investigate without forcing the experimental crossing? |

---

# 7. What I would not cut

## Do not cut SHIFT from the first vector room

It is the whole reason “free vector” becomes embodied rather than definitional.

A vector remaining unchanged while both endpoints visibly move is better than three paragraphs saying “vectors are translation-invariant.”

---

## Do not remove ZERO just because zero vectors are elementary

The interface’s fallback direction `(1,1,1)` after zero makes an important distinction:

> a later control can **supply** a direction; it did not recover one from zero.

That is a recurrent Ada question about default/convention.

---

## Do not cut normalization’s tiny-vector threshold

The threshold is implementation detail with conceptual consequence:

> “direction only” is not literally extracted from every nonzero magnitude in this artifact.

That is exactly the kind of operational boundary the book wants to expose.

---

## Do not cut the out-and-back carriage

Zero displacement after a nonzero journey is one of the sequence’s strongest callbacks to Trace and Change.

A static parallelogram diagram would not do the same work.

---

## Do not cut the small addition console at the start of Vector Arithmetic

It appears redundant after VFM02, but it changes the context:

> in VFM02, the sum became a destination used by a carriage;
> here, the relation appears immediately without a moving receiver.

That absence is the point.

---

## Do not cut the FRIEND classification from the dot aligner

The word is not merely gamification.

It exposes how a continuous numerical relation becomes a categorical story at a chosen threshold.

The manuscript already handles it critically.

---

## Do not cut the projection remainder

The pink remainder is one of the sequence’s most important visual ideas:

> what a question excludes need not cease to exist.

It links directly to the book’s broader treatment of representation.

---

## Do not keep fake `rpm` merely because the manuscript can critique it

The critical distinction between geometry and dynamics is worth keeping.

The false unit is not required to make that distinction.

---

## Do not cut complementary launches

The 30°/60° pair makes “same range” visibly insufficient because time and occupied height differ.

This is Transformation’s “same destination / different journey” brought into dynamics.

---

## Do not cut SLOW

Local slowed playback is not decorative.

It gives the visitor more observation time while explicitly not changing the model path, continuing the project’s distinction between simulation time and visitor time.

---

## Do not cut the friction ramp as a second friction explanation

The large motion chamber and the ramp are deliberately **different models**.

The ramp’s abrupt threshold and simplified scalar state give the visitor something to compare against engine-integrated rigid-body motion.

The manuscript says so.

---

## Do not cut `SET` versus `ADD` as “just code syntax”

`=` versus `+=` is the entire Fields-and-Motion argument.

It demonstrates that the same spatial sample can become radically different movement depending on the receiver’s state update.

Hide the labels initially; keep the distinction.

---

## Do not cut WALK from the drag corridor

The visitor receiver is intentionally not the same mechanism as the rigid cubes.

That is useful because it prevents “felt slowing” from being mistaken for proof of shared dynamics.

The limitation of VR physical walking is part of the argument.

---

## Do not cut the mower’s irreversible grass

The grass is the remainder that signed work and net return cannot undo.

Without it, the work section becomes mainly a dot-product illustration.

---

## Do not cut the prescribed-ring caveat

The centripetal ring is valuable precisely because the book distinguishes:

> the acceleration a path requires

from:

> a force simulation that dynamically produces that path.

Keep that sentence even if source metadata is cleaned.

---

## Do not replace the spring with a scripted cosine

The manuscript explicitly values the fact that the next state is computed from current displacement/velocity rather than read from a prewritten periodic function.

That distinction is necessary before Wavefunctions.

---

## Do not cut the DRIFT realignment time just because 150 seconds is long

It makes phase drift quantitatively different from one fixed phase offset.

The visitor need not wait for full realignment to understand the relation.

---

## Do not cut backlog recovery

RECOVER demonstrates:

> changing a rate now ≠ deleting accumulated history.

That principle recurs throughout the book.

---

## Do not “fix” the Gravity source by making the pink source move in the first experiment

Its artificial stillness is exactly what allows the hall to ask who was denied reaction.

The second mutual model is the answer.

---

## Do not call the NUDGE experiment chaos unless more evidence is added

The current manuscript is excellent here.

Keep:

> measured departure under stated initial perturbation.

Do not let the older objective “gravitational chaos from simple rules” overtake it.

---

## Do not cut support-pad width

The move from ideal points to finite 16 cm pads is conceptually rich:

> same support count, different region of admissible load positions.

It is a concrete correction to an earlier point-based abstraction.

---

## Do not cut the walker after the support table

The walker is not a second lesson about legs.

It is a deliberately persuasive fake answer:

> gait can look supported while support is not being solved.

That comparison is one of the sequence’s strongest artistic-research moments.

---

## Do not remove the Arena’s anthropomorphic questions

The manuscript carefully separates feeling from evidence:

> trust, taming, exhaustion, friendship are interpretations the visitor may produce;
> the implementation contains target selection, meal timing and a stopping threshold.

This is exactly how the book can hold an artistic question without disguising it as technical fact.

---

## Do not cut collision carts because they are diagrams rather than live collisions

The before/after diagram freezes an event that would otherwise be difficult to compare.

Its value is analytical, provided its elastic/isolation assumptions remain explicit.

---

## Do not remove the yaw singularity from Force as Place

The “dead” yaw control at vertical pitch is an excellent hand-scale encounter with coordinate parameterisation.

Only remove the unsupported historical superlative.

---

## Do not remove the plank from Force as Place

The plank is now part of the project’s self-critique.

It records a previous implementation failure and provides a control condition:

> support by contact versus travel by an acceleration receiver.

That is more valuable than pretending the field worked perfectly from the beginning.

---

# 8. Reader-experience strengths to protect

## Discovery before naming

**Act1**  
SHIFT produces invariance before “free displacement vector” is named.

**VFM02**  
routes change before addition appears.

**Motion**  
push ends before persistence is explained.

**Fields and Motion**  
two bodies diverge before the receiver rule should be named.

**Oscillation**  
the cube crosses rest before restoring-force explanation.

**Legs**  
the plate nearly stays still before support hull appears.

**Arena**  
the animal changes targets before selection code is shown.

**Force as Place**  
yaw visibly fails to affect a vertical vector before the coordinate singularity is explained.

---

## Prediction before explanation

**Act1**  
which projection changes most?

**VFM02**  
what survives SWAP / CANCEL?

**Launch**  
does higher aim always go farther?

**Friction ramp**  
where does STATIC become SLIDING?

**Gravity**  
which part of orbit came from initial speed?

**Legs**  
which support/load configuration stays level?

**Collision carts**  
which direction does striker leave around equal mass?

---

## Same arrow, changed meaning

This is the sequence’s best long-range reader device.

An arrow becomes:

- displacement;
- sum;
- gap;
- alignment relation;
- projection;
- cross-product axis/factor;
- initial velocity;
- current velocity;
- requested force;
- measured acceleration;
- field sample interpreted as velocity;
- field sample interpreted as acceleration;
- drag force;
- nominal work annotation;
- centripetal acceleration;
- restoring force;
- gravity acceleration;
- support/load projection;
- target-selection line;
- local acceleration in a region.

The visitor should gradually become suspicious of arrows in a productive way:

> **What does this vector measure, and what receiver gives it consequence?**

That question is more important than memorising vector operations.

---

# 9. Questions for the author

## 9.1 Is the thirteen-hall order now definitive?

The declared and map-authored metadata say yes.

The raw teleport utilities still encode several older shortcuts/loops.

If the thirteen-hall curriculum is definitive, I would treat route reconciliation as urgent infrastructure work.

---

## 9.2 Do you want Vector Arithmetic to remain one hall with five primary stations?

I think it works because the stations are physically linear and conceptually linked:

> relation → classification → selection → turning consequence.

If learner observation shows fatigue, I would make dot/torque a return layer before splitting the hall.

I would not pre-emptively divide it.

---

## 9.3 Is the misleading torque `rpm` intentionally an exhibit about false instrumentation?

If yes, make that intentionality visible on the instrument itself.

If not, replace the unit.

At present the manuscript is doing repair work that the artifact should partly do.

---

## 9.4 Is the current Kinetic order intended to be drag → mower → ring?

Both manuscript and map description suggest yes.

Primary coordinates suggest drag → ring → mower.

If the current assembled route confirms the latter, I would move the objects rather than rewrite the logic.

---

## 9.5 Should Change Choreography remain inside Forces?

Conceptually I think yes.

It connects oscillation to collective timing and turns differential timing into material accumulation before Gravity.

But its navigation must make that inclusion real; otherwise it behaves like an orphaned hall.

---

## 9.6 Is `rooted` intended to remain the source term in Arena?

It is effective because the manuscript immediately says:

> it does not currently grow branches.

If the word is kept, it should remain exposed as an implementation label open to interpretation, not naturalized as the creature’s psychological state.

---

## 9.7 Do you want “force” retained as the legacy public name of Force-as-Place?

The final configured hall is actually clearer as a **local acceleration field**.

The class names can remain for compatibility, but I would consider visitor-facing language consistently using:

> local acceleration / field acceleration

rather than `FORCE FIELD`, unless a later receiver explicitly interprets the vector through mass as force.

---

# 10. Overall conclusion

Forces is one of the most ambitious sequences in the book because it has to fight a powerful visual simplification:

> **an arrow looks like an arrow.**

The manuscript’s best work is refusing to infer mechanism from that appearance.

Across the sequence, similar vectors become:

- descriptions;
- destinations;
- initial conditions;
- retained velocities;
- state-dependent force requests;
- field samples;
- classification scores;
- projection components;
- required accelerations;
- target-selection displays;
- local environmental instructions.

That gives the sequence a clear epistemic method:

> **Do not ask only what the arrow points to. Ask what quantity it carries, which frame gives it components, what units it has, which receiver accepts it, what state the receiver already has, and what the implementation lets happen next.**

Reader experience is strongest when the artifact creates a discrepancy first:

- both points move but the vector does not;
- route changes but sum does not;
- push ends but movement continues;
- same field produces two trajectories;
- restoring force becomes zero but motion continues;
- source looks like a body but cannot respond;
- four legs look supported but support is not being computed;
- a field seems like one place but cube and visitor receive it differently.

Those are the moments to protect.

The highest-value work now is therefore not broad cutting. It is:

1. **reconcile museum navigation with the thirteen-hall curriculum;**
2. **repair artifact/source terms that claim more physics than the implementation provides;**
3. **delay semantic labels where they pre-empt discovery (`SET v / ADD to v`, fixed source);**
4. **make Kinetic’s physical order match its conceptual order;**
5. **clean stale source identities, especially the four-leg gait and force/acceleration naming;**
6. **bundle inherited controller sources when the manuscript relies on them;**
7. **headset-test the many receiver boundaries, because this sequence’s central argument is embodied consequence.**

The reader-experience principle I would carry forward from Forces is:

> **Let two bodies receive what looks like the same instruction differently before naming the rule that made them different.**

And the structural principle is:

> **A vector becomes physical only through a receiver. The receiver decides what state is retained, what changes, and which bodies are allowed to answer.**
