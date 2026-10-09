# Cellular Automata — 01 Review

Source-aware editorial and reader-experience review of the **Cellular Automata** sequence.

Basis: `cellularautomata-book.md`, `cellularautomata-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where the visitor can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. Recurrence is not treated as redundancy when a local rule returns with a changed state space, neighbourhood, update schedule, history representation, receiver, body, or stopping condition.

The strongest current sequence arc is:

> **ordered neighbourhood → lingering state → history made spatial → travelling pattern / fixed address → visitor enters the update → graded exchange → resemblance without shared mechanism → controlled difference**

A second formulation is:

> **A cellular automaton is not “simple rules make complexity.” It is a set of decisions about what a cell can store, which neighbours it can read, when updates become available, how boundaries work, what history is retained, and what another body is allowed to do with the resulting state.**

That is substantially more precise than the older sequence rhetoric about universal computation, “edge of chaos,” and global emergence from local entropy.

---

# 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **CA Introduction** | **Carries:** a strong beginning because the visitor first predicts one cell from an ordered three-cell neighbourhood; Rule 90 versus Rule 30 then shows that a more complicated-looking history need not have a longer local instruction. The rug and line network prevent “CA” from becoming one visual style by adding imposed symmetry and a post-hoc connection drawing. **Gap:** the neighbour-study readout already prints `NEXT: ...` before the manuscript asks “What would you make from these three?”, and the main explorer immediately labels Rule 90 **Sierpiński**. The artifact gives away two discoveries the text wants the visitor to make. **Next:** hide the predicted output and famous-rule nickname until after the first prediction/step; preserve the chapter’s breadth. |
| **CA ElementaryRules** | **Carries:** an excellent development from binary presence to temporal state. A green fading cell remains occupied/drawn but no longer contributes to active-neighbour counts; state 2 must pass to zero before rebirth. VIEW changes appearance without changing state; ACTIVE/FADING/DRAWN distinguish calculation from surface rendering; fixed empty boundaries contrast with the previous wrapped line. **Gap:** little editorially. The key runtime question is whether green active/fading transitions and omitted fully enclosed cells remain perceptually legible in the reduced 50³ specimen. **Next:** preserve and headset-test rather than explain more. |
| **CA GameOfLife** | **Carries:** despite the internal map name, the primary encounter is a **Rule 30 history study**, not Conway Life. One stored history is dressed as desk record, colliding floor tiles and ornamental lattice; depth becomes time, and changing the seed forces descendants to be recomputed. This is a strong history/receiver chapter. **Gap:** the hall name/sequence metadata are misleading, and a large secondary Turing-machine lab farther down the same route advertises Rule 110 / Game-of-Life universality while the primary chapter is about Rule 30 history. **Next:** keep the manuscript; clean user-facing map metadata/signage so “Game of Life” is reserved for the actual Life encounter in the next hall. |
| **CA BeyondBinary** | **Carries:** this is the actual Conway Game of Life chapter. A glider appears to travel while cell addresses remain fixed; lamps are wired to addresses, not to “the glider”; LINK exposes one-way coupling between simulation and room; BLINKER separates a stationary occupied address from an oscillating neighbourhood; MEET shows that persistence depends on encounter. **Gap:** the source dependency that implements the lamp receiver, `life_address_receiver.gd`, is absent from the snapshot, so the exact lamp/onset behaviour cannot be independently source-verified here. **Next:** preserve prose and include the missing receiver source in future bundles. |
| **CA ExpandingSpace** | **Carries:** one of the strongest embodied chapters. A continuous health value meets separate thresholds for support and neighbour contribution; a probe and the visitor can supply the same numerical proximity input; CHAIN makes synchronous versus in-place scan order directly comparable; withdrawal does not automatically restore a fully depleted field. **Gap:** no major literary mismatch. The central embodied claims—visitor proximity, support loss, collision thresholds and recovery ramps—need headset/runtime verification. **Next:** preserve; this is a model for later embodied CA work. |
| **CA SoftRules** | **Carries:** the sequence moves from neighbour counts to graded exchange. Two Gray–Scott-like fields begin identically; one has neighbourhood exchange disabled; EXCHANGE B restores the relation; W shows the first local difference; VIEW and COAT separate stored fields from their material presentation; the Clockmaker then distinguishes a working live comparison from still diagrams/ornamental machinery. **Gap:** the artifact titles already say **A / EXCHANGE ON** and **B / EXCHANGE OFF** before the manuscript asks “What has the right-hand square been denied?”—the answer is printed over the experiment. The core `live_field.gd` implementation quoted by the manuscript is also missing from the source snapshot. **Next:** delay the exchange labels and include the missing field source. |
| **CA AgentsCircuits** | **Carries:** the book title is accurate—**the same pattern, different work**. Rule 90 grows triangular gaps through repeated local updates; the Sierpinski pyramid explicitly recurses copies of a shape. The hall is a valuable bridge into Fractals because resemblance is made into a test rather than a proof of shared mechanism. **Gap:** the hall is declared in the sequence but absent from museum-authored order; the SoftRules transition currently points directly toward EdgeOfChaos; and if the hall is restored, its authored placement puts the pyramid near the spawn `(2,2)` and the rule explorer later `(1,6)`, opposite the manuscript’s intended Rule-90-first comparison. Its internal name “AgentsCircuits” also does not describe the current content. **Next:** restore/reclassify it deliberately, fix the transition and swap/restage the primary encounters so local-rule pattern comes before recursive construction. |
| **CA EdgeOfChaos** | **Carries:** the current manuscript/source have substantially improved the old “edge of chaos” framing. Two matched runs receive the same forcing; one changed address can be toggled; PULL and DRIVE are separated; integer versus fractional storage shows how a tiny difference can disappear or spread differently; display gain is explicitly exposed. The text correctly says a spreading difference does not establish chaotic amplification. **Gap:** the actual paired model `difference_model.gd` is dynamically preloaded by `difference_study.gd` but is missing from the snapshot, so the quoted update equation, storage fork, exact 27-cell first-step result and 0.75 maximum difference cannot be independently verified from this package. **Next:** include that source/evidence and keep “Edge of Chaos” explicitly as a questioned legacy title rather than a demonstrated regime. |

---

# 2. Sequence structure

The current eight-hall book has a coherent argument if its naming/route are cleaned.

## 1. Introduction — what information is local?

The first hall gives the minimum CA machinery:

- state;
- ordered neighbourhood;
- rule lookup;
- separate next row;
- boundary convention;
- initial condition;
- visible history.

Then the rug and line network immediately complicate the idea that “local rules” alone explain a visible form.

The rug also uses:

- distinct border/interior rules;
- imposed quadrant copying.

The line network uses:

- random-walk/growth occupancy;
- a later drawing decision selecting an older neighbouring cell to connect.

This is a very good opening because it prevents the sequence from treating visual organicity as proof of one mechanism.

## 2. ElementaryRules — state can contain history

The three-state 3D automaton adds a temporal state between active and empty.

A fading cell is:

- still present;
- still drawn if exposed;
- not counted as active;
- not immediately eligible for rebirth.

The cell therefore carries a small local past.

That is a meaningful development from binary Rule 90/30.

## 3. GameOfLife map — history becomes spatial architecture

Despite its internal name, the primary encounter is Rule 30.

The important progression is:

> one current row  
> → retained rows  
> → depth as generation  
> → the same stored history used as diagram, collision support and lattice infill.

This is a receiver/history chapter, not a Conway Life chapter.

## 4. BeyondBinary — a recognisable pattern moves without cells moving

Now actual Conway Life arrives.

The glider gives the book a new ontological question:

> what does it mean to say a “body” travelled if no cell travelled with it?

The fixed address/lamp receivers make the distinction unusually clear.

## 5. ExpandingSpace — the observer becomes an input

The visitor/probe relation enters the update.

The chapter then goes further:

- continuous health;
- support threshold;
- recovery-contribution threshold;
- synchronous versus in-place update order.

This is the point where “when answers become available to neighbours” becomes bodily architecture.

## 6. SoftRules — neighbour relation becomes graded exchange

Neighbourhood is no longer a count of qualifying cells.

It becomes a discrete Laplacian-like exchange term between continuous concentrations.

This is a strong move toward morphogenesis while preserving the grid, double buffer and boundary questions.

## 7. AgentsCircuits — similar form, different procedure

This is a methodological interlude:

- Rule 90: repeated local state update;
- Sierpinski pyramid: explicit recursion.

Its purpose is not agents or circuits.

Its purpose is to teach:

> resemblance is a hypothesis about relation, not evidence of shared construction.

That is an excellent bridge into Fractals.

## 8. EdgeOfChaos — controlled perturbation and storage

The last hall asks:

> if one initial difference spreads, what exactly is being measured and retained?

The key variables are:

- neighbour pull;
- matched disturbance;
- integer/fractional storage;
- initial one-cell difference;
- display threshold/gain.

The manuscript’s refusal to equate spreading difference with chaos is exactly right.

The chapter then hands Fractals a clear distinction:

> local exchange can produce larger resemblance; recursion explicitly asks for another copy.

That is a strong end.

---

# 3. Reader-experience lens

## CA Introduction — What will the next row do?

### Curiosity

The opening scene is good:

> rug already moving; small board waits.

The text directs the visitor toward the apparatus that can actually be predicted before the room’s ongoing motion dominates attention.

The core question:

> “What would you make from these three?”

is exactly the right first CA question.

It asks for one local outcome before “cellular automaton” becomes a category.

### Discovery

The manuscript supports a very strong progression:

1. inspect left/self/right;
2. predict;
3. STEP;
4. follow one diagonal under Rule 90;
5. inspect another neighbourhood with CELL;
6. switch to Rule 30;
7. change seed;
8. inspect wrapping boundary.

Then the rug and network answer:

> the same broad language “local rule” can enter forms with additional symmetry, random growth and representational choices.

### Timing problem

The artifact partially defeats the first prediction.

`neighbour_study.gd::refresh()` displays:

> LEFT SELF RIGHT  
> ...  
> **NEXT: 0/1**  
> RULE ...

from the beginning.

The manuscript literally has to say:

> “read their states on the side plate, but leave NEXT for a moment.”

This is an artifact telling too much too soon.

There is a second early name.

`ca_rule_explorer.gd::_update_rule_display()` maps:

- 90 → `Sierpiński`
- 30 → `Chaotic`
- 110 → `Turing Complete`.

So the visitor can receive a classification before making the observations the sequence wants.

For Intro, “Rule 90” and “Rule 30” are sufficient initial labels.

### Reader proposal

For `study:neighbours`:

- start the witness plate with LEFT / SELF / RIGHT and `NEXT: ?`;
- reveal NEXT after the first STEP, or with a `SHOW NEXT` action;
- suppress famous-rule subtitles until the first few generations have been inspected.

This preserves clarity but allows one real discovery.

### Return

Array’s ordered addresses and Change’s “same count / different arrangement” questions return here in a new form:

> `100` and `010` have the same occupied count and different meaning because neighbourhood order matters.

Excellent.

---

## CA ElementaryRules — A cell with a past

### Curiosity

The opening is unusually precise:

> how would you recognise a cell that stopped being active but has not disappeared?

That gives the green state a job before its numeric code is explained.

### Discovery

The best sequence is:

- STEP;
- find green;
- see it persist visually;
- learn that neighbour counting checks only `state == 1`;
- watch state 2 go to zero rather than immediately become active;
- VIEW changes visual treatment;
- compare ACTIVE / FADING / DRAWN;
- run to a limit;
- compare stopped clock with `CHANGED 0`.

This is strong.

The statement:

> “Being present and being counted have parted company.”

is fully earned.

### Timing

Very good.

The rulestring `6-8/6-8/3/M` is visible, but cryptic enough that it does not answer the experiential question before the visitor sees green.

The code arrives after the state difference is perceptible.

### Return

The previous hall’s binary cell becomes a cell with a local temporal memory.

Noise’s threshold questions also return:

> the renderer omits some occupied interior cells without removing them from the computation.

That is a productive recurrence.

---

## CA GameOfLife — A history you can inhabit

### Curiosity

The title does not rely on the map name.

The first question is bodily:

> a gap in a screen versus a gap in the floor.

This immediately asks how the same recorded bit behaves in different receivers.

### Discovery

ROW is a good first control because it does not advance the automaton.

It moves attention through existing history.

REPLAY then reduces the spatial history to one starting cell.

STEP gradually rebuilds:

- desk record;
- colliding support deck;
- wall lattice.

The visitor can see that depth is being used as time.

### Timing

Very strong.

The Rule 30 code arrives only after the same historical row has been located in several media.

SEED/FLIP X9 then make a principled point:

> descendants must be recomputed when the beginning changes.

### Naming problem

The source/map name `CA_GameOfLife` is now misleading.

The primary artifact is:

> `ca_bridge#study:history`

and `history_study.gd` explicitly sets:

> Rule 30.

The actual Conway Life chapter is the next hall.

A secondary lab deeper in this room also contains signage combining:

- Rule 110 universal computation;
- “Game of Life is Turing complete.”

That can make the hall’s identity even less legible.

### Return

Randomness’s reproducibility and Trace’s finite history return here as architectural support.

Good.

---

## CA BeyondBinary — A pattern visits an address

### Curiosity

Excellent opening.

The visitor is told to step four times, notice that “something” returned, and ask:

> what travelled?

Then the text deliberately moves attention away from the glider to address A.

That is exactly the right move.

### Discovery

The glider permits several distinct accounts:

- pattern translates;
- individual cells turn on/off;
- fixed address can be occupied, empty, occupied;
- lamp responds to address occupancy rather than pattern identity.

BLINKER adds:

> occupied address can remain while neighbourhood changes around it.

LINK adds:

> receiver relation is independently switchable.

MEET adds:

> same rule, changed initial/encounter condition, different continuation.

### Timing

Very good.

The Life rule arrives only after the pattern/address distinction has already been experienced.

The one-way receiver relation is named after LINK makes it visible.

### Source gap

`address_study.gd` dynamically loads:

> `life_address_receiver.gd`

but that file is not in the snapshot.

So the wrapper/source supports the intended wiring call, but not the receiver’s exact event counting, illumination and reset behaviour.

### Return

Array’s address/object distinction returns in an especially strong form:

> a “body” can move across addresses while no stored body travels with it.

This is one of the sequence’s best conceptual moments.

---

## CA ExpandingSpace — The surface includes you

### Curiosity

The bridge looks available before the visitor is told how it fails.

The PROBE mode is a good first step because it makes the numerical relation observable without immediately putting the visitor at risk.

### Discovery

Strong sequence:

1. probe near;
2. watch W health decline;
3. move probe far;
4. watch recovery;
5. restore;
6. switch source to VISITOR;
7. experience support loss;
8. CHAIN isolates update-order question;
9. compare SYNC / SCAN / REVERSE.

The chapter develops from bodily consequence into computational schedule without losing the same state variable.

### Timing

Excellent.

The biological word “health” is exposed as a name for a number rather than naturalised.

The threshold structure is also introduced after the visitor has watched colour/support change:

- `< 0.2` no collision;
- `> 0.5` contributes to neighbour recovery.

This is one continuous value with multiple permissions.

### Update-order experiment

CHAIN is particularly strong.

It holds source input at NONE and prepares values:

- 0.600
- 0.495
- 0.000

so the question:

> can a newly recovered neighbour immediately help the next one in this pass?

becomes visible.

This is a genuinely important CA concept that many tutorials leave abstract.

### Return

The Introduction’s “write all answers into another row” returns as a bodily architectural choice:

> snapshot/synchronous versus in-place scan.

Excellent.

---

## CA SoftRules — What can a cell receive?

### Curiosity

The manuscript sets up an ideal controlled comparison:

- same values;
- same addresses;
- same reaction;
- one field receives neighbour exchange;
- one does not.

Witness W begins just outside the seeded patch.

After one step:

- left gets a little V;
- right gets none.

The question:

> “What has the right-hand square been denied?”

is very good.

### Timing problem

The artifact gives away the answer immediately.

`exchange_study.gd::_build_space()` titles the fields:

> **A / EXCHANGE ON**  
> **B / EXCHANGE OFF**

before any step.

The central reader question becomes confirmation rather than discovery.

### Artifact proposal

Initial titles:

> **A**  
> **B**

or:

> **FIELD A / SAME BEGINNING**  
> **FIELD B / SAME BEGINNING**

After the first +100 or after pressing EXCHANGE B, reveal:

> **EXCHANGE ON/OFF**

The readout can likewise initially show values without naming the withheld relation.

### Discovery

Once the relation is named, the rest is excellent:

- discrete Laplacian-like neighbour exchange;
- local U×V² reaction;
- right field still reacts but cannot create first V at unseeded W;
- wrap boundary;
- display mapping VIEW U/V;
- COAT separates texture from architecture;
- INJECT adds a later historical event.

The Clockmaker is also appropriately demoted:

> still fractional ring is not a running Lenia field; ornamental crank does not advance it.

This is good source criticism.

### Source gap

The main live comparison loads:

> `live_field.gd`

which is absent from the snapshot.

The manuscript quotes its exact update equations.

`rd_sim.gd` is present, but that is a different batch wrapper around another Gray–Scott implementation and does not independently prove that the staged field uses the same live step.

Include the actual `live_field.gd`.

### Return

Noise’s correlated field becomes explicit neighbour exchange with stored concentrations.

This is an excellent transition.

---

## CA AgentsCircuits — The same pattern, different work

### Curiosity

The manuscript’s method is right:

> first observe Rule 90’s triangular gaps through local updates;
> carry one specific relation to the pyramid;
> test whether it really corresponds.

This prevents “they both look Sierpinski” from ending the investigation.

### Discovery

The room can teach:

- Rule 90: one row → next row through neighbourhood lookup;
- Sierpinski pyramid: explicit recursive copying of a geometric object;
- visual holes can correspond at some scales without mechanisms matching;
- a failed correspondence is useful evidence.

This is an excellent methodological bridge into Fractals.

### Reader problems

There are three.

#### 1. The hall is not in museum-authored order

Declared:

> SoftRules → AgentsCircuits → EdgeOfChaos.

Museum:

> SoftRules → EdgeOfChaos.

#### 2. SoftRules has the old direct transition

It ends:

> “Carry the matched beginning and the visible clock into the next hall: when a small intervention changes an outcome, how will we tell what actually changed?”

That is clearly EdgeOfChaos, not AgentsCircuits.

#### 3. Physical order reverses manuscript order

Spawn `(0,0)`.

- pyramid `(2,2)`
- rule explorer `(1,6)`.

The visitor likely encounters the recursive construction before the Rule 90 pattern the text wants them to establish first.

There is also a label-timing issue:

`ca_rule_explorer` calls Rule 90:

> **Sierpiński**

on its rule label.

That names the resemblance before the visitor tests it.

### Return

Tiling’s recurrence/recognition question returns here in a new methodological form:

> resemblance is a reason to compare procedures, not to infer identity.

This hall is worth keeping.

---

## CA EdgeOfChaos — How far does one difference go?

### Curiosity

The opening is strong because the difference is deliberately hard to see.

Two volumes are nearly identical; one address in B differs by one.

The visitor is asked to find the difference before the instrument shows its spread.

### Discovery

The paired setup has excellent experimental discipline:

- same forcing schedule;
- same initial rule/settings;
- optional single-cell intervention;
- PULL changes neighbour averaging;
- DRIVE changes disturbance;
- integer/fractional storage is independently switchable;
- replay returns matched conditions.

The most valuable experiment is:

> integer storage erases the first fractional spread; fractional storage distributes a smaller difference to more sites.

This is exactly the kind of representational/storage choice Ada should expose.

### Timing

The manuscript is very good.

It waits until the difference has visibly spread before explaining display gain.

Then it explicitly says:

> brightness is a visibility decision.

The title “Edge of Chaos” is also handled responsibly:

> let the name remain a question.

### Evidence gap

Unfortunately the core model is not in the package.

`difference_study.gd` preloads:

> `difference_model.gd`

which is listed as a further dependency and not included.

The manuscript’s exact algorithm/code and figures therefore cannot be independently source-checked here:

- neighbour sum and forcing equation;
- integer/fractional storage fork;
- “27 addresses differ after one step”;
- max difference 0.75;
- precise threshold for difference count.

The wrapper supports the existence of controls/readouts, but not the underlying numerical update.

### Return

The chapter finishes the sequence appropriately:

> a local update can spread a difference, preserve it, erase it, or make it visible differently depending on storage and representation.

That prepares Fractals without claiming CA and recursion are the same.

---

# 4. Five high-value changes

## 4.1 Restore/reclassify CA_AgentsCircuits deliberately, repair the transition, and make its spatial order match the manuscript

**Hall**

`CA_AgentsCircuits`

Primary placements:

- A1 `(2,2)` `sierpinski_pyramid:0:6`
- A2 `(1,6)` `ca_rule_explorer:0:0.5:1#mount:wall`

Spawn `(0,0)`.

### Work performed

This hall makes an important distinction:

> **similar pattern / different procedure**

Rule 90 creates nested triangular relations through repeated local updates.

The pyramid creates self-similarity through explicit recursion/copy placement.

This distinction is exactly what the next sequence, Fractals, needs.

### Current route problem

The hall is in:

- `sequence.json.maps`;
- declared sequence order;
- current book.

It is absent from:

- museum map-authored order.

The transition at the end of `CA_SoftRules` also skips it and points directly to EdgeOfChaos:

> “when a small intervention changes an outcome, how will we tell what actually changed?”

### Spatial problem

If restored as currently placed, the pyramid is encountered first.

But manuscript order is:

1. Rule 90 explorer;
2. carry one triangular relation;
3. compare it with Sierpinski pyramid.

### Label-timing problem

`ca_rule_explorer.gd` automatically labels Rule 90:

> `Sierpiński`

which gives the comparison its answer before the visitor has located the resemblance.

### Proposal

If the hall remains in the sequence:

1. add it back to museum-authored route between SoftRules and EdgeOfChaos;
2. revise the SoftRules transition to prepare resemblance/mechanism, e.g.:

   > We have watched neighbour exchange make a pattern. In the next hall another construction looks related from across the room. Before naming the resemblance, ask whether the two forms are doing the same work.

3. swap/restage the primary objects so the rule explorer is encountered first;
4. in this map, suppress the famous nickname and initially display simply:

   > **RULE 90**

5. update visitor-facing title/metadata from “Agents and Circuits” toward the actual content, e.g.:

   > **LOCAL RULE / RECURSION**  
   > or keep the book title **THE SAME PATTERN, DIFFERENT WORK**.

The internal filename can remain for compatibility if renaming it is costly.

### Reason

This hall is not surplus. Its current absence creates a conceptual gap between SoftRules and Fractals, while its current placement/naming would weaken the comparison if restored unchanged.

---

## 4.2 CA Introduction — let the visitor predict one cell before the apparatus prints the answer

**Hall / instance**

`CA_Introduction`

A4 `(10,4)`

`ca_rule_explorer:180:1.04#study:neighbours#rule:90#speed:4#plinth:0`

### Current manuscript

> “Read their states on the side plate, but leave NEXT for a moment. What would you make from these three?”

### SOURCE

`commons/artifacts/ca_rule_explorer/neighbour_study.gd::refresh()`

The witness display immediately prints:

```text
LEFT SELF RIGHT
...
NEXT: <0/1>
RULE <n>
```

So the visitor is asked not to look at an answer already placed beside the inputs.

The parent also calls:

`ca_rule_explorer.gd::_update_rule_display()`

which maps:

```text
90 → Sierpiński
30 → Chaotic
110 → Turing Complete
```

### Artifact proposal

For `study:neighbours`:

**Initial plate**

```text
LEFT SELF RIGHT
1    0    0

NEXT: ?
RULE 90
```

After first STEP—or a dedicated `SHOW NEXT` action—reveal the predicted bit.

Also suppress the nickname in this study until after at least one generation has been advanced.

A later plate can say:

> **RULE 90 · commonly associated with a Sierpiński-like triangular pattern**

if that label remains useful.

### Reason

The text already has good reader timing.

The artifact is currently explaining earlier than the text.

This small change gives the visitor one genuine act of local prediction before the rule becomes vocabulary.

---

## 4.3 CA SoftRules — stop printing EXCHANGE ON/OFF before the visitor discovers the missing relation

**Hall / instance**

`CA_SoftRules`

A1 `(8,5)`

`rd_artifact:0:0#study:exchange#plinth:0`

### Current manuscript

> “They began with the same values, at the same addresses. They have the same reaction. What has the right-hand square been denied?”

Only after the comparison does the text introduce neighbourhood exchange.

### SOURCE

`commons/artifacts/rd_artifact/exchange_study.gd::_build_space()`

The walls are labelled from the start:

```text
A / EXCHANGE ON
B / EXCHANGE OFF
```

The readout likewise says:

```text
B EXCHANGE OFF
```

before the visitor has stepped the matched fields.

### Artifact proposal

Initial titles:

> **A / SAME BEGINNING**  
> **B / SAME BEGINNING**

Initial readout should give:

- U/V at W;
- tick;
- view;
- injections;

but not name the missing mechanism.

After one of these conditions:

- first `+100`;
- first `EXCHANGE B` press;
- or a new `REVEAL` action,

change the titles to:

> **A / EXCHANGE ON**  
> **B / EXCHANGE OFF/ON**

Then the manuscript’s question becomes discovery rather than confirmation.

### Source-package action

The study dynamically loads:

> `res://commons/artifacts/rd_artifact/live_field.gd`

but the file is not in the snapshot.

Include it in the next review bundle because the manuscript quotes its exact Laplacian/reaction update.

### Reason

This is the same reader-experience principle as Intro:

> clarity does not require printing the causal answer before the difference is observed.

---

## 4.4 Rewrite sequence-level metadata and hall labels to match what the current book actually demonstrates

**Location**

`sequence.json`, map descriptions/user-facing titles, possibly secondary signage.

### Current sequence truth

> “Local rules, global patterns. Each cell knows only its neighbors, yet worlds emerge. Rule 110 is Turing complete—simple rules can compute anything.”

### Current QFEP connection

> “Cellular automata demonstrate emergence—the E(S) term manifesting as complex global behavior from simple local entropy. They are laboratories for studying how order and chaos interact at the edge of computation.”

### Declared objectives include

- Rule 110 Turing completeness;
- “Edge of chaos: where complex behavior emerges.”

The current final manuscripts do **not** demonstrate those claims.

In fact, the last hall explicitly says:

> spreading difference alone does not establish chaotic amplification.

And AgentsCircuits explicitly says:

> resemblance does not prove a general-purpose computer.

### Hall naming mismatches

The current content also has two important map-name mismatches.

#### `CA_GameOfLife`

Primary current lesson:

> Rule 30 history bridge.

#### `CA_BeyondBinary`

Primary current lesson:

> actual Conway Game of Life glider/blinker/meeting.

#### `CA_AgentsCircuits`

Primary current lesson:

> Rule 90 versus Sierpinski recursive pyramid.

No agents or circuits are central.

### Proposed sequence intention

> **Let local state updates grow histories and recognisable forms; vary state, neighbourhood, update schedule, boundary and receiver to see which larger relations survive.**

### Proposed objectives

- Read an elementary one-dimensional rule as an ordered neighbourhood lookup.
- Distinguish synchronous/double-buffered updates from in-place scan updates.
- Compare binary state with a multistate cell that retains a fading history.
- Turn a one-dimensional generation history into different spatial receivers, including physical support.
- Follow a Game of Life pattern while keeping fixed cell addresses in view.
- Connect a fixed simulation address to an external receiver and distinguish one-way output from feedback.
- Let visitor/probe proximity enter a graded neighbourhood-update rule and separate visibility, support and recovery permissions.
- Compare threshold/count-based neighbour relations with graded diffusion/exchange.
- Compare a locally generated triangular pattern with explicit recursive self-similarity without inferring shared mechanism from resemblance.
- Measure how one controlled difference spreads, disappears or persists under different coupling and storage rules.

### Universality / Rule 110

Rule 110’s computational universality can remain as a **sourced contextual fact** if you want it in supporting material, but the current primary route should not claim it has demonstrated:

> “simple rules can compute anything.”

Likewise, the secondary Turing lab should be reviewed separately before its signage becomes sequence truth.

### Edge-of-chaos

Keep the hall’s current disciplined wording:

> **let the name remain a question.**

Remove “edge of chaos” as a demonstrated learning objective unless a separate operational criticality experiment is built.

### Reason

The manuscripts are now more rigorous than the sequence metadata.

Updating the metadata prevents future passes from reintroducing claims the current rooms have deliberately learned to limit.

---

## 4.5 Make the review bundle follow dynamic dependencies for the three halls whose central claims currently outrun the supplied snapshot

This is a source-review infrastructure change, but it has immediate editorial value.

### CA BeyondBinary

Missing:

> `life_address_receiver.gd`

The chapter depends on it for:

- lamp state;
- rise/onset count;
- reset;
- LINK behaviour.

`address_study.gd` shows the calls but not the receiver implementation.

### CA SoftRules

Missing:

> `rd_artifact/live_field.gd`

The chapter depends on it for:

- 32×32 field state;
- neighbour exchange;
- U/V reaction step;
- injection;
- wrapping;
- exact coefficients.

The current ZIP includes `exchange_study.gd` but not the model it advances.

### CA EdgeOfChaos

Missing:

> `ca_showcase/difference_model.gd`

The chapter depends on it for:

- matched forcing schedule;
- neighbour pull;
- disturbance;
- integer/fractional storage;
- initial one-cell intervention;
- exact difference counts and amplitudes.

`difference_study.gd` is only the furniture/controller/view layer.

### Proposal

Promote dynamic dependencies loaded by a **primary study adapter** into the source-export closure even when they lie beyond two static resource hops.

A practical exporter rule:

> If a primary source calls `load()` / `preload()` for another `.gd` that owns state evolution or receiver consequence, include it as primary evidence.

### Reason

These are not optional helpers.

They are exactly where the chapter’s key causal claims live.

A source-aware editorial process should not have to infer the algorithm from a display wrapper when the book quotes the missing model directly.

---

# 5. Source / artifact discrepancies

## 5.1 `ca_rule_explorer` identity is stronger than the current lesson

Source identity says:

> “slide through all 256 rules and watch chaos, order, and Turing completeness appear”

and:

> “Rule 110 proves that three neighbors and one bit can compute anything.”

The current Intro manuscript is much more disciplined.

It teaches:

- neighbourhood order;
- rule bit lookup;
- synchronous row update;
- boundary wrap;
- initial condition.

Do not let the identity pull the book back toward claims about “chaos” or universality without a separate demonstration/source.

---

## 5.2 The explorer’s famous-rule labels are interpretations, not the local rule itself

Current built-in labels include:

- Rule 30 → `Chaotic`
- Rule 90 → `Sierpiński`
- Rule 110 → `Turing Complete`
- Rule 255 → `Life`.

These are useful navigation mnemonics but can be pedagogically premature or overly categorical.

For study modes, prefer rule numbers first and named associations later.

---

## 5.3 Persian Rug source identity says the rug “designs itself,” but the source includes explicit imposed symmetry

The implementation has:

- border/interior rules;
- multistate decay;
- seeding;
- `_enforce_quadrant()` copying one value into three reflected positions.

The manuscript correctly says:

> “The ornament has several makers: local updates, a chosen boundary, a palette, and this repeated act of copying.”

That should be the canonical interpretation.

Source identity:

> “the rug designs itself”

is too autonomous for the actual construction.

---

## 5.4 Line Network source identity treats its drawn parent as causal ancestry, but the current implementation cannot prove that

Identity says:

> each new cell traces a line back to its parent;
> ancestry creates structure.

Actual flow:

1. growth routine adds occupied cells from frontier updates;
2. later `update_visualization()` scans the grid;
3. if an active position has not been seen before, `_find_parent_and_connect()` chooses **a random already recorded neighbouring position**.

That selected neighbour is a drawing relation.

It need not be the frontier cell whose update caused the new occupancy.

The manuscript catches this exactly:

> “The parent in the drawing is selected during the scan. The line does not prove which earlier cell caused the birth.”

Protect the manuscript; clean the source identity.

---

## 5.5 Structure Growth’s visible surface omits occupied interior cells

The base implementation renders only occupied cells with at least one empty six-face neighbour.

The study readout therefore correctly allows:

> DRAWN < ACTIVE + FADING.

This is not a renderer bug.

It is one of the hall’s strongest representation distinctions.

---

## 5.6 Structure Growth uses fixed empty outer boundary rather than wrap

`structure_study.replay()` explicitly clears both buffers on the outer shell.

The base `_step()` iterates only the safe inner volume.

This supports the manuscript’s comparison with the wrapped elementary board.

---

## 5.7 `CA_GameOfLife` is currently not a Game of Life primary lesson

`history_study.gd` explicitly sets:

```gdscript
work.rule = 30
```

and records a 15-wide, maximum 24-row Rule 30 history.

Treat the internal map name as legacy if necessary, but update user-facing metadata.

---

## 5.8 `ca_bridge` source identity still overstates “bridge topology” and universality

Its older identity says:

- Rule 30 chaotic broken path;
- Rule 110 universal;
- “walk on computation.”

The current history study uses the solver well, but the primary chapter’s deeper point is not that a particular rule is universally computational.

It is:

> one stored history can receive multiple spatial uses.

Keep that focus.

---

## 5.9 `game_of_life_petri` source identity makes broad emergence/computation claims beyond the configured study

The staged address study uses only:

- GLIDER;
- BLINKER;
- MEET;
- 24×24 wrapping grid;
- fixed receiver sites.

It does not demonstrate glider guns, arbitrary computation or universality.

The broader source artifact may contain those presets, but the configured hall should be described by what is actually used.

---

## 5.10 Life lamp receiver source is missing

As above.

This is a source-package gap, not evidence that the manuscript is wrong.

---

## 5.11 Decaying Bridge separates visibility/support/recovery thresholds in a way the manuscript correctly preserves

The source supports:

- health ∈ [0,1];
- proximity decay;
- four axial neighbours;
- healthy-neighbour threshold > 0.5;
- collision disabled below 0.2;
- wall/frieze material display without bridge collision;
- synchronous versus in-place reads.

The current manuscript is well aligned.

---

## 5.12 SoftRules’ core model source is missing

As above.

The wrapper/readout supports the UI and comparison design, but not the exact equations.

Do not claim full source verification of those equations from this bundle.

---

## 5.13 The Clockmaker is intentionally a mixed computed/diagrammatic super-object

Its current source comments are unusually careful:

- elementary histories are computed;
- Life glider is computed;
- Brian’s Brain is computed;
- Langton’s ant is run;
- Wireworld and fractional ring are still illustrations;
- crank is ornamental;
- no live visitor-driven step;
- fractional ring is not a running Lenia field.

The manuscript reflects this accurately.

This is a good example of source identity improving enough that the book does not need to fight it.

---

## 5.14 `SierpinskiPyramid` is explicit recursion, not a CA

The source calls itself a bridge from CA to fractals and builds:

> top copy + four corner copies recursively.

That makes it an excellent comparison object.

Do not let the visual resemblance to Rule 90 turn into a shared-mechanism claim.

---

## 5.15 EdgeOfChaos current configured source has already disowned the old lambda-criticality claim

`self_organization_ca.gd` now opens with:

> “legacy lambda interpolates two coefficients; its regime names are authored labels, not Langton rule-table measurements or established criticality.”

That is exactly the right correction.

But legacy functions remain:

- `is_at_edge_of_chaos()`;
- `get_regime()` returning `order / edge / chaos`;
- comments calling the middle regime `living`.

These are not used by the current difference study, but should not be promoted back into the manuscript.

---

## 5.16 EdgeOfChaos core difference model is missing

As above.

The study wrapper supports:

- STEP;
- +10;
- REPLAY;
- ONE CELL;
- PULL ±;
- DRIVE ±;
- SEED;
- STORE;
- Z SLICE;
- COAT;
- dynamic display gain.

The actual numerical evolution lives in the missing model.

---

# 6. Spatial / route findings

## CA Introduction

Spawn `(2,1)`.

Early primary objects:

- rug `(4,4)`;
- rule explorer `(10,4)`.

The manuscript intentionally says:

> the rug is already changing; the board waits; begin with the board.

Because both are at the same z, this is not automatically a spatial error. The board needs a runtime sightline check: is it visually legible as the deliberately “held” object across the room?

The line network `(3,12)` comes later and fits the text.

---

## CA ElementaryRules

Spawn `(6,1)` → primary `(6,6)` → exit `(6,12)`.

Very clean.

No spatial restructuring suggested.

---

## CA GameOfLife

Spawn `(6,1)` → primary history bridge `(6,5)` → secondary Turing lab `(6,22)` → later secondary works → exit `(6,35)`.

The primary lesson is near the entrance and clearly staged first.

However, the visitor must continue through a large secondary Turing-machine installation before leaving.

Runtime observation should check whether its strong signage redefines the hall as “universal computation” after the manuscript has deliberately focused on history/receiver.

---

## CA BeyondBinary

Spawn `(6,1)` → Life address study `(6,4)` → secondary gallery from z21 onward → exit `(6,25)`.

Good primary staging.

---

## CA ExpandingSpace

Spawn `(6,1)` → bridge `(7,4)` → secondary gallery around z20+ → exit `(6,26)`.

Good.

---

## CA SoftRules

Spawn `(8,1)` → exchange study `(8,5)` → Clockmaker `(8,13)` → secondary gallery → exit `(8,24)`.

This spatial order matches the manuscript very well.

---

## CA AgentsCircuits

Spawn `(0,0)` → pyramid `(2,2)` → rule explorer `(1,6)` → exit `(5,6)`.

This reverses the manuscript’s comparison order.

If restored to museum route, fix it.

---

## CA EdgeOfChaos

Spawn `(9,1)` → difference study `(9,5)` → secondary gallery later → exit `(9,28)`.

Good primary staging.

---

# 7. Runtime questions

No repository code was executed. Every hall still records `learner_verified: false`.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Whole sequence** | Does the current endless-museum route skip `CA_AgentsCircuits` exactly as `map_authored` reports? If restored, does `next_in_sequence` follow the declared eight-hall order automatically? |
| **Introduction — board sightline** | From spawn, is the held Rule 90 explorer visibly identifiable across the already-moving rug so visitors can follow the text’s “begin with the one that waits” instruction? |
| **Introduction — prediction** | If NEXT is hidden initially, can a beginner reliably read left/self/right and make one prediction before STEP? |
| **Introduction — famous labels** | Does `Sierpiński` / `Chaotic` on the main rule plate cause visitors to classify the patterns before observing them? |
| **Introduction — Rule 90/30** | Are diagonal relations in Rule 90 and changed predictability under Rule 30 readable at the configured 32×24 neighbour-study display? |
| **Introduction — rug** | Can a visitor identify fourfold mirrored partners before the imposed symmetry is explained? Are border/interior differences visible enough to support the two-ruleset account? |
| **Introduction — line network** | Has the 20-generation growth usually finished before arrival? Can apparent 3D knots be separated by walking around the display? |
| **ElementaryRules — active/fading** | Are pink versus green states visually distinct at headset distance? Does a green fading cell remain drawn long enough to be followed into zero? |
| **ElementaryRules — DRAWN** | Can visitors understand why DRAWN may be less than ACTIVE+FADING by locating a hidden interior occupied cell, or is that distinction source-only? |
| **ElementaryRules — VIEW** | Does gradient view materially obscure active/fading distinction while keeping exact same state, as intended? |
| **ElementaryRules — CHANGED** | When CHANGED reaches zero, does another STEP truly reproduce the full state under the fixed boundary/rule? |
| **GameOfLife/history — ROW** | Does ROW move only the witness through stored history with no recalculation? Can the same selected row be found on desk, deck and lattice? |
| **GameOfLife/history — collision** | Are only occupied historical tiles colliding/supporting over the basin? Are end ramps and side museum passage safe enough for inspection? |
| **GameOfLife/history — seed edit** | Does FLIP X9 reliably force recomputation of all later rows rather than leave stale descendants? |
| **GameOfLife/history — secondary lab** | Does the large Turing lab’s signage dominate the visitor’s interpretation of the hall after the primary Rule 30 encounter? |
| **BeyondBinary — lamps** | Include `life_address_receiver.gd`; verify LINK, light state, onset count and replay reset exactly. |
| **BeyondBinary — glider** | Does the configured glider translate by one address in both axes after four generations under the 24×24 wrapping grid? |
| **BeyondBinary — BLINKER** | Does the middle address remain occupied through the two-state orientation change so its lamp stays continuously on? |
| **BeyondBinary — MEET** | Reproduce/attach the claim that the configured glider+block field is empty by generation 24 if that exact number stays in main text. |
| **ExpandingSpace — visitor/probe** | Does PROBE NEAR/FAR reproduce the same numerical proximity influence expected from the visitor source at comparable distance? |
| **ExpandingSpace — support** | Does collision disable below health 0.2 exactly when the visual tile is still faintly present? Can the visitor safely fall to/recover from the basin? |
| **ExpandingSpace — recovery** | At health 0.3, does a tile still support the visitor while failing to count as a >0.5 healthy recovery neighbour? |
| **ExpandingSpace — CHAIN** | With 0.600 / 0.495 / 0.000, do SYNC and SCAN produce the intended different one-step result? Does REVERSE alter only scan-mode outcome? |
| **SoftRules — first step** | With labels neutralised, can a visitor locate W and see V arrive on A but not B after one step before reading the exchange explanation? |
| **SoftRules — +100** | Does the paired difference remain legible after 100 updates at the current palette/scale? |
| **SoftRules — EXCHANGE B** | After enabling exchange and reset, do the two fields agree exactly/within floating precision under the same update schedule? |
| **SoftRules — core source** | Include `live_field.gd` and verify coefficients, wrap behaviour, injection and clamp used by the study. |
| **SoftRules — Clockmaker** | Do visitors try to turn the ornamental crank or mistake the fractional ring for a running Lenia simulation despite the current labels? |
| **AgentsCircuits — route** | If restored, do visitors encounter Rule 90 before the pyramid after restaging? |
| **AgentsCircuits — resemblance** | With the `Sierpiński` nickname initially suppressed, can visitors independently identify a triangular relation worth carrying to the pyramid? |
| **AgentsCircuits — pyramid** | At configured depth/packing, are gaps across multiple scales readable without the object becoming visually saturated? |
| **EdgeOfChaos — model source** | Include `difference_model.gd` and source-check the exact update and storage equations. |
| **EdgeOfChaos — first intervention** | With DRIVE 0, uniform seed, PULL .25 and +1 cell, reproduce the claimed one-step INTEGER disappearance versus FRACTIONAL 27-site spread / max 0.75. |
| **EdgeOfChaos — matched forcing** | With ONE CELL off, do A and B remain identical through all updates under the shared disturbance schedule? |
| **EdgeOfChaos — display gain** | Is the automatically magnified difference display clearly labelled enough that visitors do not interpret brightness as absolute difference magnitude? |
| **EdgeOfChaos — title** | Does “Edge of Chaos” itself cause visitors to infer a criticality result before reading the chapter’s explicit caveat? |

---

# 8. What I would not cut

## Do not cut Rule 90 versus Rule 30 from Introduction

The change in visual complexity under the same tiny local lookup is important.

Just do not let the labels `Sierpiński` and `Chaotic` perform the interpretation in advance.

---

## Do not cut `100` versus `010`

The equal occupied count / different ordered neighbourhood is one of the cleanest demonstrations in the sequence that:

> what a representation counts as relevant is part of the rule.

Keep it.

---

## Do not cut the double-buffer explanation

“All questions go to the old row” is foundational.

ExpandingSpace later makes the synchronous/in-place alternative bodily.

The early explanation is not redundant; it establishes the baseline that later gets violated intentionally.

---

## Do not cut the rug because it is not a “pure” cellular automaton demonstration

Its imposed quadrant copying is the point.

The room becomes better when the visitor can see that local rules, symmetry enforcement and palette jointly make the cloth.

---

## Do not cut the line network’s parent discrepancy

The fact that the renderer’s selected connection is not proof of causal ancestry is excellent.

It should remain even after source identity is cleaned.

---

## Do not cut the fading state from ElementaryRules

This is the hall’s central development:

> present ≠ active ≠ eligible for rebirth.

It gives state memory a bodily duration.

---

## Do not cut ACTIVE / FADING / DRAWN

These three counts separate:

- computational state;
- another computational state;
- rendering decision.

That is exactly the project’s method.

---

## Do not cut the fixed empty boundary

The contrast with the wrapped Rule 90 board is useful.

A neighbourhood rule is incomplete without a boundary convention.

---

## Do not cut the Rule 30 history bridge because the next hall has Game of Life

They ask different questions.

History bridge:

> what happens when generations become retained spatial structure?

Life address study:

> what happens when a recognisable pattern moves through fixed addresses?

Keep both.

---

## Do not cut the same history rendered three ways

Desk, support deck and lattice are not decorative repetitions.

They demonstrate that one stored bit can become:

- colour;
- collision support;
- ornamental infill.

The receiver changes the meaning.

---

## Do not cut LINK from BeyondBinary

It is what prevents the lamp from appearing to be naturally part of the glider.

The lamp reads an address because a relation was wired.

That relation can be removed.

---

## Do not cut BLINKER just because GLIDER is more famous

BLINKER is the counterexample the address lesson needs:

> a fixed address can remain occupied while a larger pattern changes around it.

Keep it.

---

## Do not cut MEET

It introduces interaction without changing the Life rule.

That makes persistence dependent on what the pattern encounters, not on a new instruction saying “stop.”

---

## Do not cut the PROBE from ExpandingSpace

The probe lets the visitor compare:

> numerical influence from a nominated position  
> versus influence from their own tracked body.

This prevents “the bridge knows I am a person” from becoming the explanation.

---

## Do not cut the two health thresholds

Support at 0.2 and neighbour contribution above 0.5 create a strong permission structure:

> something can carry you without being healthy enough to help its neighbour recover.

Keep it.

---

## Do not cut CHAIN / SYNC / SCAN / REVERSE

This is one of the most important CA experiments in the whole sequence.

It makes update scheduling visible and consequential.

---

## Do not cut reaction–diffusion just because it stretches the definition of “cellular automaton”

The manuscript already handles this carefully.

The grid/double-buffer/neighbour exchange lineage is precisely what makes the comparison interesting.

Call it a graded-field/local-update extension rather than forcing it into binary CA taxonomy.

---

## Do not cut the Clockmaker’s static fractional ring

The manuscript is explicit that it is not a running Lenia field.

That difference between diagram and mechanism is useful.

---

## Do not cut AgentsCircuits merely because it is missing from the museum route

Its procedural comparison is a very good bridge into Fractals.

Fix the route.

---

## Do not force every Rule 90 / Sierpinski feature into correspondence

The hall’s strength is that failed resemblance counts as evidence about where the analogy stops.

Keep that instruction.

---

## Do not cut the integer/fractional storage comparison in EdgeOfChaos

This is one of the sequence’s strongest examples of a representational/storage decision changing the fate of a perturbation.

The local rule did not change; what the state was permitted to retain did.

---

## Do not remove dynamic display gain from EdgeOfChaos

It is fine to magnify a fading difference if the gain is printed.

The important lesson is exactly:

> visibility is another operation.

Keep it explicit.

---

## Do not let “Edge of Chaos” become a conclusion

The manuscript’s sentence:

> “Let the name remain a question.”

should govern the hall.

The title can remain historically/project-wise useful only if the experiment does not claim to have located a universal critical regime.

---

# 9. Reader-experience strengths to protect

## Discovery before naming

**Introduction**  
predict local output before rule explanation—once NEXT is hidden.

**ElementaryRules**  
find a fading green cell before learning how state 2 behaves.

**GameOfLife/history**  
move through stored generations before code names the Rule 30 update.

**BeyondBinary**  
watch a glider “travel” before the text explains fixed addresses.

**ExpandingSpace**  
lose support before biological “health” language is unpacked.

**SoftRules**  
see W differ before exchange is named—once field labels stop giving it away.

**AgentsCircuits**  
discover one resemblance before `Sierpiński` names it.

**EdgeOfChaos**  
follow a perturbation before storage/display mechanisms are exposed.

---

## Prediction before explanation

- What should the next cell be?
- Will fading state 2 become active again under a qualifying neighbourhood?
- Which Rule 30 tiles appear next?
- Which lamp will the glider visit?
- Will withdrawal repair a depleted patch?
- Can a newly recovered cell help its neighbour in the same scan?
- What has field B been denied?
- Which Rule 90 gap corresponds to a pyramid gap?
- Does one changed cell vanish or spread under this storage rule?

These are strong tutorial questions and should remain the sequence’s rhythm.

---

## Productive distinctions to protect

- same occupied count ≠ same ordered neighbourhood
- local rule ≠ complete visual explanation
- occupied ≠ active
- occupied ≠ drawn
- stopped clock ≠ fixed point
- current state ≠ visible history
- recorded generation ≠ present 3D neighbour
- pattern travels ≠ cells travel
- fixed address ≠ recognised pattern
- output receiver ≠ feedback into simulation
- visible tile ≠ supporting tile
- support threshold ≠ recovery-contribution threshold
- synchronous update ≠ in-place scan update
- neighbour count ≠ graded exchange
- reaction ≠ diffusion/exchange
- material coating ≠ embodied agency
- visual self-similarity ≠ recursive construction
- spreading difference ≠ chaotic amplification
- stored integer ≠ stored fractional state
- brighter difference display ≠ larger absolute difference.

This list is the real Cellular Automata curriculum.

---

# 10. Questions for the author

## 10.1 Is CA_AgentsCircuits definitively part of the sequence?

The declared book says yes.

The museum route and SoftRules transition say no.

I recommend keeping it because it creates a useful local-update-versus-recursion bridge.

If kept, restore and restage it deliberately.

---

## 10.2 Do you want Rule 90’s “Sierpiński” label visible immediately?

For a general-purpose explorer, the nickname is useful.

For Intro and AgentsCircuits study modes, it weakens discovery.

I would make famous-rule subtitles configurable per placement.

---

## 10.3 Should `CA_GameOfLife` remain the internal map name for the Rule 30 history hall?

Renaming paths may be expensive.

The important thing is that user-facing title/description and curriculum metadata stop calling its primary lesson Game of Life.

Then `CA_BeyondBinary` can be named/displayed explicitly as the Conway Life address/glider hall.

---

## 10.4 Is the Turing-machine lab intended to be part of the required reading path?

It sits far down `CA_GameOfLife` between the primary encounter and the exit.

If computational universality is a major curricular objective, it deserves a source-aware chapter/experiment.

If not, keep it as optional supporting material and reduce its authority in sequence metadata.

---

## 10.5 Do you want the Gray–Scott comparison to remain inside Cellular Automata?

I think yes, if framed as:

> **same grid/update discipline, but continuous state and graded exchange**

rather than as “another CA species.”

It usefully prepares later morphogenesis.

---

## 10.6 Is “Edge of Chaos” a retained historical/project title or a claim you still want the sequence to investigate?

The current chapter is strongest when it treats the title as a question.

I would keep it that way.

If you want an actual criticality/edge-of-chaos claim later, it needs a separate operational measure and evidence.

---

# 11. Overall conclusion

Cellular Automata is stronger than its inherited sequence metadata.

The old story is:

> local rules create global complexity  
> Rule 110 computes anything  
> somewhere between order and chaos complexity emerges.

The current book supports a more interesting and accountable story:

> **A local update only becomes a world after we decide what state exists, which neighbours matter, when their values are read, where the boundary is, what gets retained, how the result is displayed, and which external bodies are allowed to receive it.**

The strongest reader moments are not “look, emergence.”

They are narrower surprises:

- two three-cell neighbourhoods with the same occupied count produce different answers;
- a fading cell is still present but no longer counts;
- a Rule 30 history becomes a floor that can fail underfoot;
- a glider “moves” while addresses stay where they are;
- a visible bridge tile can stop supporting a body;
- the same local field changes when update order is allowed to leak through the scan;
- one Gray–Scott field differs because neighbour exchange is missing;
- a Rule 90 pattern resembles a recursive pyramid without sharing its procedure;
- one changed value disappears under integer storage and spreads under fractional storage.

Those are excellent Ada moments because the difference can be located in the implementation and then carried back to the encounter.

The highest-value work now is therefore:

1. **restore/reclassify `CA_AgentsCircuits` deliberately and align its spatial/manuscript order;**
2. **hide Intro’s NEXT/famous-rule answers long enough for one genuine prediction;**
3. **hide SoftRules’ EXCHANGE labels until the missing relation has been observed;**
4. **rewrite sequence/hall metadata so Game of Life, universality and “edge of chaos” claims match the actual primary encounters;**
5. **include dynamically loaded core model/receiver sources in future review bundles;**
6. **headset-test the bodily claims—history support, Life receivers, decaying bridge collision/recovery, and the comparative volumes—before strengthening any language about what the visitor can do.**

The reader-experience principle I would carry forward from Cellular Automata is:

> **Let the visitor watch a local relation fail to explain the whole form before naming the extra rule that made the difference.**

And the structural principle is:

> **A cell is never just a cell. Its state, neighbourhood, clock, boundary, memory and receiver decide what kind of body the local rule can become.**
