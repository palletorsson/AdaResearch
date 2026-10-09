# L-Systems — 01 Review

Source-aware editorial and reader-experience review of the **L-Systems** sequence.

Basis: `lsystems-book.md`, `lsystems-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where the visitor can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. Recurrence is not treated as redundancy when the same sentence, symbol, branch or stored choice returns through another interpreter, spatial receiver, resource field, body, or threshold.

The current book has a strong underlying arc:

> **rewrite → interpret → save/restore state → change the reader → construct inhabitable boundaries → let a shared world constrain rewriting → expose tool parameters and their quantisation → reinterpret fixed choices through another alphabet**

A second formulation is:

> **A grammar does not contain its body. Rewriting decides which symbols exist; an interpreter decides what they do; a construction decides what their traces become in space; an environment decides which actions remain possible; and a tool decides which parts of that whole process the visitor is allowed to change.**

That is considerably more precise than older sequence rhetoric such as “a sentence can become a forest,” “grammar is the artist,” or “the world comes alive.”

---

# 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **LSystems Grammar Lab** | **Carries:** an excellent opening separation between **rewriting** and **interpretation**. HOLD gives the same sentence two bodies; TURN changes geometry while holding the rewritten symbols; PLANT introduces an undrawn `X` that still participates in later rewriting; brackets introduce saved turtle state; generation/symbol budgets keep finite limits visible. **Gap:** the source/registry still describes the editor as letting the visitor edit axioms and production rules in real time, while the staged physical lesson only offers presets, generation, angle, hold/reset and a rule reveal. **Next:** preserve the manuscript; clean the artifact identity/registry so the desk is not credited with authoring controls it does not currently expose. |
| **LSystems Growth** | **Carries:** one of the strongest reader-first halls. STEP exposes non-drawing operations—SAVE, TURN, RESTORE—before the full tree appears; the branch stack restores position/orientation/length/angle; RATIO shows that “length decay” can equal or exceed one; TREE separates interpreter-trace inspection from requesting another rewrite generation. **Gap:** no major text/source contradiction. The body is genuinely rendered in metres without fit-to-case scaling, so the surprising 7.2 m second-generation extent is part of the experiment rather than a display artifact. **Next:** preserve and headset-test whether nested save/restore and metre-scale comparison remain readable at the current physical size. |
| **LSystems Grammars And Curves** | **Carries:** a precise interpreter lesson: three readers share one sentence and one 0.32 m stride; ANGLE changes a parameter only when a turn instruction uses it; READ F swaps x/y in the drawing direction, producing a reflection-like reading while preserving the underlying stored heading/state; gold and white arrows make interpretation disagreement visible before a larger tree hides it. **Gap:** little editorially. The parent super-object’s plaque still says the same sentence “grows three different plants,” which is rhetorically stronger than this finite reading experiment and can naturalise the tree metaphor too early. **Next:** preserve the manuscript and tone down parent/source identity rather than simplifying the controlled comparison. |
| **LSystems Architecture** | **Carries:** one of the sequence’s clearest transitions from symbolic connectivity to bodily access. A short branch grammar produces four movement records and two `R` room records; both R instructions resolve to the same saved junction; BUILD adds footprint and boundary policy; ROOMS changes the spatial use of that shared address; WIDTH holds the centreline graph fixed while changing whether a 0.6 m desktop body can enter. **Gap:** the artifact prints **“4 moves / 2 room records / 1 room address”** and the readout repeats **“2 R records / 1 shared address”** from the start, before the manuscript asks the visitor to follow the brackets and discover that duplication. **Next:** delay the “one shared address” answer until after the visitor has inspected the two R instructions or pressed RULE/ROOMS. |
| **LSystems Competition** | **Carries:** the sequence’s environmental turn is technically strong. Two specimens begin with the same F grammar, diameter and growth multiplier; overlapping 5×5 soil sampling squares make the first turn consume 2.250 model units and the second 1.980; ORDER reverses the advantage without changing grammar; WINTER still consumes soil but refuses the rewrite; SOIL changes the field without letting a tree take a turn. **Gap:** this fully authored/source-backed hall is **missing from museum map-authored order**, even though the declared sequence and Architecture/Competition manuscripts explicitly require Architecture → Competition → Living. **Next:** restore it to the actual museum route if the seven-hall curriculum is definitive; verify the `next_in_sequence` resolution rather than treating the mismatch as an automatic runtime failure. |
| **LSystems Living** | **Carries:** an unusually good tool-critique chapter. HOLD creates a stable witness; a continuous-looking Depth gene crosses an integer generation threshold only at certain values; Angle changes geometry continuously without adding generations; PLANT now exports a deep-copied DNA snapshot so later edits do not silently alter the placed specimen; the chapter ends by naming what the eight exposed controls still cannot ask for. **Gap:** the book’s exact mapping from raw DNA values to generations and its 200-command drawing budget live in `TreeMorphology`/`CritterDNA` systems that are **not included in this snapshot**. Registry metadata also still presents the artifact primarily as genetic-algorithm selection even though this placed lesson uses `pressure=none` and teaches manual parameter authoring. **Next:** include the global class dependencies in future bundles and distinguish the placed manual sculptor from optional pressure/evolution modes in registry copy. |
| **Assemblage Same Desire** | **Carries:** a strong sequence coda. A fixed 12×12 set of random samples can be held while ALPHABET changes the marks; ODDS changes decisions while reusing the samples; SEED changes the reproducible samples; STEP makes the finite textile window discard one old row; the same marks on the floor invite paths without creating collision boundaries. This returns the grammar/interpreter distinction in a non-L-system medium and prepares procedural generation. **Gap:** registry metadata still lists `ten_print_textile` under Randomness rather than this L-systems/assemblage role, and the source package does not establish the exact bodily support of the floor beyond the lesson’s fixed backing/museum substrate. **Next:** update curation metadata and runtime-test floor support; preserve the manuscript’s refusal to call perceived paths planned routes. |

---

# 2. Sequence structure

The seven-hall book is conceptually coherent.

The only major structural mismatch is that **museum-authored order currently omits Competition**.

The intended arc is worth preserving.

## 1. Grammar Lab — sentence and body separate

The opening establishes two passes:

1. rewrite a string;
2. interpret it.

That alone gives the sequence a strong epistemic foundation.

The same string can receive:

- another angle;
- another drawing convention;
- another fit-to-display operation.

And an undrawn symbol can still participate in rewriting.

The string is therefore not a picture in disguise.

## 2. Growth — interpretation needs state and memory

The next hall asks what a branching reader must retain.

The answer becomes explicit:

- position;
- orientation axes;
- current length;
- current angle;
- branch depth.

Brackets are not decorative syntax. They operate a stack.

That gives later architecture a concrete memory model.

## 3. Grammars And Curves — interpretation itself can be changed

The sentence stays fixed.

The stride stays fixed.

One reader changes turn angle.

Another changes the meaning of “forward.”

The sequence therefore distinguishes:

> **rewriting variation**  
> from  
> **interpreter variation**.

This is essential before architecture.

## 4. Architecture — line connectivity is not bodily passage

A turtle history becomes a floor plan.

Then additional policies are required:

- corridor footprint;
- room footprint;
- union of overlapping cells;
- exposed-edge walls;
- explicit entrances;
- collision;
- body width.

The grammar provides records.

The architectural construction decides what those records are allowed to become.

## 5. Competition — a grammar enters a shared world

This is the missing but necessary environmental step.

Two identical grammar systems no longer have identical futures because:

- soil is shared;
- consumption changes later conditions;
- update order determines who sees which resource state;
- season can withhold rewriting after consumption.

This is the first hall where the environment does not merely receive grammar output—it changes whether rewriting may continue.

## 6. Living — the authoring tool itself becomes the subject

The sequence now steps back from the environment and asks:

> which parameters have we made editable?

The raw controls do not map uniformly to visible differences.

Depth is a continuous slider whose downstream consumer quantises it to a generation count.

Angle is a continuous geometric parameter.

PLANT/HOLD introduce persistence and copying as separate design decisions.

The chapter ends by asking what is **not represented by a control at all**.

That is an important transition from grammar to procedural-generation tool design.

## 7. Assemblage Same Desire — stored decision and visible alphabet separate again

The last hall deliberately leaves L-system strings behind.

It carries the sequence’s method into a simpler two-outcome textile:

- sample;
- threshold decision;
- alphabet/mark;
- finite rolling history;
- bodily reading.

This works as a coda because it makes the core lesson portable:

> changing the symbol’s **interpretation** can transform the picture without changing the stored choice.

And changing the **threshold** can transform the choice without drawing another random sample.

That prepares generated environments well.

---

# 3. The structural mismatch: Competition is missing from the museum-authored route

The declared order is:

> Grammar Lab → Growth → Grammars And Curves → Architecture → **Competition** → Living → Assemblage Same Desire

The museum-authored order currently reports:

> Grammar Lab → Growth → Grammars And Curves → Architecture → Living → Assemblage Same Desire

This is not a minor omission.

## The text depends on Competition

Architecture ends:

> “Next, in Competition, we ask what happens when a rule's next move must meet a world that other growth already occupies.”

Competition ends:

> “In Living, we turn towards the controls that let us author a body…”

Living begins:

> “In Competition, the same grammar met different conditions.”

So the book’s argumentative chain explicitly requires the missing hall.

## The map itself exists and is complete enough to review

`LSystems_Competition` has:

- authored map;
- primary `ForestCompetition:180#lesson:true`;
- manuscript;
- source snapshot;
- next-in-sequence utility;
- secondary retained works.

Architecture’s utility definition is even named:

> **Competition / Continue to see multiple trees compete**

The raw map source and declared sequence therefore still remember the intended route.

## But the brief is right: route mismatch is not automatic proof of broken runtime

`next_in_sequence` may be resolved through museum-level sequencing rather than raw utility labels.

The correct action is:

1. inspect/update `map_authored`;
2. resolve `next_in_sequence` in the museum utility layer;
3. walk Architecture → Competition → Living.

Do not rewrite Living as if Competition never existed merely to fit stale authored-order metadata.

---

# 4. Reader-experience lens

## LSystems Grammar Lab — The same sentence, another body

### Curiosity

The opening is excellent:

> two upright lines; same `F`; can one sentence have two bodies?

It does not begin by defining formal grammar.

NEXT creates the first transformation.

HOLD then gives the visitor a stable comparison.

TURN makes the central distinction visible:

> same string / another interpretation.

### Discovery

The strongest sequence is:

1. one `F`;
2. rewrite once;
3. hold;
4. alter turn angle;
5. compare same sentence;
6. rewrite again;
7. reveal the production rule;
8. move to PLANT and encounter undrawn `X`.

The invisible `X` is particularly good.

It demonstrates:

> no drawing action ≠ no computational role.

That is a meaningful return of earlier “zero/absence” questions in another medium.

### Timing

Very good.

RULE is opt-in.

The code arrives only after the visitor has seen rewriting and interpretation separate.

The sentence printer also explicitly declares when only the first 120 symbols are shown.

The 4,096-symbol lesson budget rejects a whole next generation rather than truncating a bracketed sentence mid-generation.

That is excellent finite-instrument discipline.

### Source/metadata gap

The source identity says:

> “Edit L-system grammars in real-time”  
> “Adjust axiom, production rules…”

The staged physical lesson cannot type a new axiom or production.

It can select one of seven presets, change generation/angle, and reveal the rule.

The manuscript is explicit about this limit:

> “the physical desk does not yet let us type a new rule.”

Keep the manuscript; correct the registry.

### Return

Fractals’ recursion becomes explicit textual rewriting.

The important new distinction is:

> rewrite operation and geometric reader are separate passes.

That is the sequence’s foundation.

---

## LSystems Growth — What a branch remembers

### Curiosity

This is one of the cleanest chapters in the bundle.

A short line is already drawn.

The next symbol is not another line but `[`.

The visitor presses STEP and sees **nothing extend**.

Instead:

- stack count changes;
- next length changes.

That is exactly the kind of “invisible operation” a programming tutorial should embody.

### Discovery

The bracket sequence is very well staged:

- `[` saves;
- `+` turns;
- `F` draws;
- `]` restores.

The visitor can predict:

> where will the point go when `]` is read?

The return to the fork without a return-line is a strong spatial explanation of stack restoration.

The restored length is equally important:

> branch-local decay does not silently become the trunk’s new length.

### Ratio experiment

The `length_decay` name is productively challenged.

The staged values include:

- 0.45
- 0.72
- 1.00
- 1.15.

At 1.15 the “decay” lengthens.

That is excellent source criticism.

### TREE

TREE does not animate rewriting in time.

It requests a second rewrite generation and then exposes a recorded interpreter trace.

The book correctly distinguishes:

> inspecting a trace  
> from  
> making the computer pause between operations.

### Timing

Excellent.

No changes recommended.

### Return

Transformation’s state restoration returns as a stack.

Fractal trees return, but now branch inheritance is explicit symbol interpretation.

---

## LSystems Grammars And Curves — When forward goes sideways

### Curiosity

The opening question is exactly right:

> “Does an instruction say how it must be obeyed?”

Three lines begin identically.

The comparison is kept extremely local.

READ F then makes one reader go sideways.

The gold heading and white drawing-direction arrows visibly disagree.

### Discovery

The reader can isolate:

- sentence;
- stored heading;
- interpreted movement;
- stride;
- turn angle.

ANGLE is also a good experiment because the first line does not change.

A parameter can change without producing a visible difference until the sentence reaches an operation that uses it.

That echoes Living later.

### `x/y` exchange

The source operation is concrete:

```gdscript
dir = Vector2(dir.y, dir.x)
```

For the same angle and origin, this reflects the path across `x = y`.

The manuscript correctly says it is not simply a 90° rotation.

This is an unusually precise treatment of “another interpretation.”

### Timing

Good.

The caption updates to:

> `READ F / exchange x,y`

as soon as the button is pressed, so the exact operation is not being withheld for long.

But the chapter’s real discovery is the **disagreement between stored heading and used direction**, which the two arrows still expose directly.

I would not add another reveal state unless learner observation shows visitors read the caption before looking at the arrows.

### Source rhetoric

The parent source plaque says the same sentence “grows three different plants.”

The current staged chapter does not need that biological language.

These are finite geometric readings.

Clean the plaque/identity eventually.

### Return

Vectors returns explicitly:

> direction × step + position.

The sequence demonstrates that “F” has no spatial meaning until a reader assigns one.

---

## LSystems Architecture — When a line acquires walls

### Curiosity

This room has an excellent first contrast:

> the plan can be followed with the eyes, but feet can ignore it.

BUILD then makes the same graph acquire bodily consequence.

That is exactly the right move after the believing turtle.

### Discovery

The chapter’s strongest sequence is:

1. inspect centreline plan;
2. BUILD;
3. traverse;
4. follow bracketed `R` instructions;
5. discover both room markers share one address;
6. ROOMS enlarges that shared place;
7. WIDTH changes bodily access while graph remains fixed.

This is a very strong progression.

### Timing problem

The artifact answers step 5 immediately.

At startup:

```text
F[+RF][-RF]F
4 moves / 2 room records / 1 room address
```

and the normal readout says:

```text
4 segments / 2 R records / 1 shared address
```

The manuscript asks:

> “Two Rs appear in the sentence. Find the two places they mark. Follow the brackets carefully before deciding that there must be two rooms.”

But the instrument has already told the visitor there is one shared address.

### Artifact proposal

Initial program label:

```text
F[+RF][-RF]F
4 moves / 2 R records
```

Initial readout:

```text
PLAN / clear width 1.4 m / rooms OFF
4 segments / 2 R records
```

After:

- RULE,
- ROOMS,
- or a dedicated `COMPARE R` reveal,

add:

> **1 shared address**

The discovery then belongs to following the bracket stack.

### Construction

The source is excellent here.

The grammar records movement/room markers.

The architecture lesson then adds:

- corridor width;
- room footprint;
- union of occupied cells;
- wall boundary around exposed cells;
- deliberate entrance omissions.

The manuscript correctly says:

> grammar supplies records; construction supplies a boundary policy.

### Width/body

The desktop body comparison is sourced in technical notes:

- radius 0.3 m → 0.6 m diameter;
- 1.4 and 2.2 m corridors pass;
- 0.4 m entrance stops it.

The book properly limits that to one body.

### Return

Tiling/Array connectivity returns.

Force/Polyhedra bodily passage returns.

L-systems adds:

> a symbolic graph must still be given footprint and boundary policy.

---

## LSystems Competition — Who gets the first turn?

### Curiosity

This is the hall most damaged by being absent from the museum route because its opening is excellent.

Two trees are deliberately as equal as possible:

- same grammar;
- same diameter;
- same growth multiplier;
- same soil.

The only first difference is **turn order**.

A takes 2.250.

B takes 1.980.

Then ORDER reverses the advantage.

That is an extremely clear environmental constraint experiment.

### Source support for the numbers

The pair is placed only 0.35 m apart.

Each root samples a 5×5 square of soil cells.

The squares overlap in 20 of 25 cells.

Initial soil value is 0.6.

A takes 15% from 25 untouched cells:

> `25 × 0.6 × 0.15 = 2.250`.

B then sees 20 overlap cells reduced to 0.51 and five untouched cells at 0.6:

> `20 × 0.51 × 0.15 + 5 × 0.6 × 0.15 = 1.980`.

This is source-derived, not a guessed runtime statistic.

### Discovery

The best reader movement is:

- first turns;
- ORDER;
- same grammar / changed advantage;
- SEASON winter;
- see uptake happen without rewrite;
- SOIL changes shared field without tree turn.

The crown alone cannot tell the whole story.

That is the chapter’s central achievement.

### Timing

Very good.

The exact soil subtraction code arrives only after the order effect has been observed.

### Source rhetoric

The registry calls this:

> “ecosystem dynamics”  
> “multi-agent F-minimization”

The current lesson is more precise.

It demonstrates:

- shared scalar resource field;
- sequential consumption;
- season gate;
- diffusion/replenishment;
- authored L-system growth.

No need to make a general ecology claim.

### Return

CA’s scan/update-order issue returns in a different medium:

> who reads a shared field first changes what remains for the next body.

That is an excellent cross-sequence connection.

---

## LSystems Living — What counts as a change?

### Curiosity

The opening is very strong:

> change Depth several times; number changes; tree does not.

That is a real interface puzzle.

The visitor can feel that a control is moving before the downstream instruction changes.

Then 5.0 crosses the generation threshold.

### Discovery

The chapter distinguishes:

- raw parameter value;
- compiled/discrete grammar parameter;
- visible geometry.

Angle then provides a counterexample:

> a continuous change can alter geometry immediately without adding a generation.

This is good tool literacy.

### HOLD / PLANT

HOLD creates a stable visual/DNA witness.

PLANT does something different:

- flushes pending preview edit;
- deep-duplicates DNA;
- stores a snapshot;
- copies current geometry onto local planting pad.

Later edits leave it alone.

This persistence had to be explicitly implemented.

The manuscript is right to foreground it.

### Source-package gap

The exact line quoted in the book:

```gdscript
var generations: int = clampi(roundi(dna.segments * 0.5), 2, 5)
```

belongs to `TreeMorphology`, not to the supplied `genetic_tree_sculptor.gd`.

Likewise the 200-command drawing budget:

> `TreeMorphology.LOD_MAX_BRANCHES[2]`

is referenced by `living_lesson.gd` but its declaration is not present.

`CritterDNA`, `CritterTraitMapper` and `TreeMorphology` are global-class dependencies not included by the current two-hop exporter.

So the manuscript’s claims are internally consistent with the wrapper but not independently source-verified from this ZIP.

### Metadata mismatch

The registry still describes the artifact as:

> “Evolutionary L-system tree that uses genetic algorithm selection…”

The source now does contain an optional `pressure` hill-climb.

But the placed lesson token:

> `genetic_tree_sculptor:180#lesson:true`

does not set `pressure`.

Default pressure is `none`.

The lesson explicitly resets a manually editable DNA resource.

So the visitor-facing chapter is a **manual gene-to-body sculptor**, not an evolutionary selection experiment.

The registry needs to distinguish:

- base/manual lesson;
- optional pressure variant.

### Return

The whole sequence becomes a critique of interface affordance:

> which possible grammar changes have been made into controls?

That is exactly the right question before procedural generation.

---

## Assemblage Same Desire — Two marks, many paths

### Curiosity

This is a good coda because it makes the grammar/interpreter distinction portable.

The visitor first finds a path in diagonal marks.

Then HOLD preserves one sheet.

ALPHABET changes what the same binary decisions draw.

A path can disappear even though samples and A/B choices remain unchanged.

### Discovery

The chapter’s controlled distinctions are excellent.

**ALPHABET**

- same stored samples;
- same threshold;
- same A/B choices;
- different marks.

**ODDS**

- same stored samples;
- threshold changes;
- some A/B choices switch.

**SEED**

- new reproducible samples.

**STEP**

- one old row removed;
- one new row sampled;
- finite window shifts.

This is a very precise decomposition of what casual language might call “the pattern changed.”

### Floor

The same marks are mapped to a fixed floor area.

The manuscript correctly says:

> following the diagonal versus crossing it are both supported;
> mark is not a collision wall.

The source explicitly says no path-finding/collision toggle is smuggled into the mark choice.

That is a good sequence ending.

### Timing

Very good.

The visitor is allowed to find a path before the chapter tells them that the generator did not plan it.

### Curation mismatch

The `ten_print_textile` registry still lists:

> `map_sequences: ["randomness"]`

even though it is now the primary artifact of this L-systems coda.

Update the registry to reflect its cross-sequence use.

### Return

Randomness returns through stored draws.

Tiling returns through mark alphabet.

L-systems contributes the transferable distinction:

> stored choice ≠ interpreter/mark ≠ perceived path.

---

# 5. Five high-value changes

## 5.1 Restore LSystems Competition to the museum-authored route

**Evidence type:** TEXT + SOURCE / ROUTE QUESTION

Declared order:

> Grammar Lab → Growth → Grammars And Curves → Architecture → Competition → Living → Assemblage

Museum-authored order:

> Grammar Lab → Growth → Grammars And Curves → Architecture → Living → Assemblage

### Why it matters

Competition is not a side gallery.

It performs a unique sequence-level step:

> **same grammar / changed environmental history**.

Architecture asks what spatial construction the grammar receives.

Competition asks whether the grammar gets to rewrite at all after another body has changed the world.

Living explicitly begins by referring back to Competition.

### Source state

The map exists.

The primary source is included.

The Architecture utility is named “Competition.”

Competition has its own next-in-sequence utility to Living.

### Proposal

If the seven-hall sequence remains definitive:

1. add `LSystems_Competition` back to museum-authored order;
2. verify that `next_in_sequence` resolves Architecture → Competition → Living in the assembled museum;
3. run a full navigation pass before editing the surrounding prose.

If there is a deliberate reason Competition was removed, then revise:

- Architecture ending;
- Living opening;
- sequence.json maps/content;

as one editorial decision.

Do not leave the current hybrid state.

### Reason

This is the single highest-value change in the bundle.

The missing hall carries an argument the other six do not.

---

## 5.2 Architecture — delay “1 shared address” until the visitor has traced the brackets

**Hall / instance**

`LSystems_Architecture`

A1 `(9,7)`

`lsystem_dungeon:180#lesson:true`

### Current manuscript

> “Two Rs appear in the sentence. Find the two places they mark. Follow the brackets carefully before deciding that there must be two rooms.”

### SOURCE

`architecture_lesson.gd::_ready()` creates:

```text
F[+RF][-RF]F
4 moves / 2 room records / 1 room address
```

and `refresh()` prints:

```text
4 segments / 2 R records / 1 shared address
```

from the initial PLAN state.

### Work performed

The two room-marker instructions are important because they expose:

> instruction count ≠ distinct spatial address.

The reason is the bracket stack:

- first side branch saves/restores junction;
- second side branch starts from the same restored junction;
- both R instructions record that same point.

That is a beautiful grammar/state discovery.

### Artifact proposal

Initial label:

> `F[+RF][-RF]F`  
> `4 moves / 2 room records`

Initial readout:

> `PLAN / clear width 1.4 m / rooms OFF`  
> `4 segments / 2 R records`

Reveal:

> **1 shared address**

after:

- `RULE`;
- first `ROOMS`;
- or a small `COMPARE R`/inspection action.

### Reason

The manuscript already has excellent discovery timing.

The object currently answers its own puzzle.

---

## 5.3 Rewrite sequence-level metadata around rewriting, interpretation and environmental constraint

**Location**

`sequence.json` and selected registry descriptions.

### Current truth/description

> “A sentence can become a forest. Grammar is generative.”

> “From a single axiom, a tree grows… trees, cities, space-filling curves… watch the world come alive.”

Declared objectives include:

- context-sensitive vs context-free rules;
- formal grammars and space-filling curves;
- ecosystem transition.

Those topics exist as retained/secondary works, but they are not all primary controlled lessons in the current seven-hall manuscript.

### Current primary sequence actually demonstrates

- parallel string rewriting;
- turtle interpretation;
- stack/state inheritance;
- alternative reader conventions;
- corridor/room construction from movement records;
- shared environmental resource constraints;
- tool-parameter quantisation/persistence;
- fixed samples reinterpreted by another alphabet.

### Proposed editorial intention

> **Separate string rewriting from the interpreter that gives symbols spatial effects; then follow how saved state, construction rules, shared environments and authoring tools determine which grammatical forms can become bodily worlds.**

### Proposed objectives

- Rewrite every symbol from the previous generation into a new string without recursively rewriting newly produced symbols in the same pass.
- Distinguish rewriting from turtle interpretation and hold one fixed while changing the other.
- Use stack-based save/restore to give branches inherited position, orientation, angle and length.
- Change the meaning of an instruction while holding sentence and stride constant.
- Convert movement/marker records into a floor footprint and boundary system; distinguish graph connectivity from passage for a particular body.
- Let two identical grammars act sequentially on one shared resource field and inspect how update order and season alter their futures.
- Compare raw continuous tool parameters with the discrete or bounded instructions their downstream interpreter actually receives.
- Preserve a design by explicit copying and distinguish an editable source from a held or placed snapshot.
- Reinterpret one stored decision field through different visual alphabets and distinguish mark, decision and perceived route.

### De-emphasise unless separately taught

- context-sensitive grammar taxonomy;
- computational universality/formal-language hierarchy;
- “world comes alive” biology language;
- grammar as a universal world-building principle.

### Reason

The current book has become more exact than its inherited slogan.

The sequence is strongest when it says **which layer did what**.

---

## 5.4 Living — include the actual global-class dependencies and distinguish manual sculpting from optional selection

**Hall / instance**

`LSystems_Living`

A1 `(9,8)`

`genetic_tree_sculptor:180#lesson:true`

### Manuscript/source dependency

The chapter’s central technical explanation depends on:

- `CritterDNA`;
- `TreeMorphology`;
- `CritterTraitMapper`.

Examples include:

```gdscript
var generations: int = clampi(roundi(dna.segments * 0.5), 2, 5)
```

and the readout’s:

> drawing budget 200.

But these global-class implementations are not included in `sources/`.

The wrapper only calls them.

### Exporter proposal

Extend source closure to include referenced global classes/types used by primary artifacts.

A useful rule:

> if a primary source calls a class/static method that owns the transformation from stored state into the chapter’s visible outcome, include that class as primary evidence even when Godot resolves it globally rather than through `load()`.

### Registry mismatch

Current registry description:

> “Evolutionary L-system tree that uses genetic algorithm selection…”

The source does contain optional `pressure` values:

- reach;
- spread;
- thicket;
- spare;

implemented as seeded greedy hill-climb.

But the current lesson placement passes only:

> `lesson:true`.

Default:

> `pressure = "none"`.

The lesson then manually edits the DNA resource.

### Registry proposal

Describe two modes separately.

**Base / placed lesson**

> Interactive DNA-to-tree sculptor: exposed parameters are mapped into a grammar/interpreter; HOLD and PLANT create explicit snapshots.

**Optional pressure variant**

> Seeded hill-climb over the same eight exposed genes under one authored fitness function.

### Reason

The current manuscript carefully says:

> “DNA here means a collection of parameters used to construct a body; the name does not establish that the specimen is alive.”

The metadata should not reintroduce an evolutionary claim the placed encounter is not performing.

---

## 5.5 Clean artifact identities that still collapse grammar into form or biological metaphor

This is a source-maintenance change across several primary artifacts.

### `lsystem_editor`

Current identity:

> “the grammar is the artist”  
> “one renderer + different rules = infinite variety”  
> “edit axioms and production rules in real time.”

The staged lesson demonstrates:

- presets;
- finite generation budget;
- angle as interpreter parameter;
- rewrite/interpret separation.

Prefer:

> **A finite preset grammar is rewritten, then interpreted by a turtle; generation and angle can be varied independently in this lesson.**

### `parametric_lsystem`

Registry:

> “More organic than discrete rules.”

This is an aesthetic ranking, not an implementation fact.

Prefer:

> branch entry modifies inherited length/angle; the same sentence can therefore produce different metric geometry.

### `the_believing_turtle`

Parent plaque:

> same sentence “grows three different plants.”

The staged lesson is about finite readers, not plant ontology.

Prefer:

> **same sentence, different spatial readings.**

### `lsystem_dungeon`

Registry:

> “corridors and rooms emerge from string rewriting.”

In the current lesson:

- grammar produces movement and marker records;
- a separate footprint/boundary builder makes corridor width, room area, walls and doors.

Prefer:

> **grammar supplies movement/room records; an architectural receiver turns those records into floor area and boundaries.**

### `ForestCompetition`

Registry:

> “ecosystem dynamics” / “multi-agent F-minimization.”

The study demonstrates a specific model:

- shared scalar nutrient grid;
- sequential uptake;
- season gate;
- diffusion/replenishment;
- L-system rewrite.

Keep QFEP framing project-specific if desired, but do not let it replace the operational description.

### Reason

The book’s recurring method is now:

> know exactly where a capability entered.

Source identity should reinforce that rather than collapse the entire pipeline into one poetic verb such as *grows* or *emerges*.

---

# 6. Source / artifact discrepancies

## 6.1 Grammar Lab physical lesson does not expose arbitrary axiom/rule editing

The base class has methods and internal rule dictionaries that could support more editing.

The staged lesson’s six controls are:

- NEXT;
- TURN;
- HOLD;
- PRESET;
- RESET;
- RULE.

So the manuscript is correct:

> presets are beginnings; the physical desk does not yet let us type a new rule.

Update registry wording.

---

## 6.2 Grammar Lab’s fit-to-display is an explicit post-interpretation operation

`lsystem_editor.gd::_draw_lsystem()`:

1. interprets the string into line points;
2. finds bounds;
3. computes `scale_factor`;
4. fits the result into a fixed display size.

The manuscript correctly says more instructions need not make a taller displayed body.

This is source-supported and worth keeping.

---

## 6.3 Grammar Lab’s symbol budget preserves whole generations

The lesson sets:

> `max_symbols = 4096`.

The generator estimates the next complete generation before allocating it.

If it would exceed budget:

- `budget_limited = true`;
- the previous complete generation remains.

This supports the manuscript’s “requested versus shown generation” distinction.

---

## 6.4 Growth’s parametric state is genuinely part of the bracket stack

The source saves:

- position;
- direction;
- right/up axes;
- depth;
- current length;
- current angle.

At `[`:

- depth increments;
- length *= ratio;
- angle *= 0.95.

At `]`, the previous state is restored.

The manuscript is technically aligned.

---

## 6.5 Growth uses a deterministic turn in the placed lesson

The underlying `parametric_lsystem` can add `angle_variation`.

The placed token/config and lesson explicitly set:

> `angle_variation = 0.0`.

So this chapter’s comparison is deterministic.

Good.

---

## 6.6 The Believing Turtle’s x/y exchange is a reader convention, not a changed sentence

The source’s `interpret()` keeps:

- sentence;
- heading;
- step length;
- bracket stack;

and changes only the vector used by an `F` move when `sideways` is enabled:

```gdscript
dir = Vector2(dir.y, dir.x)
```

The manuscript is accurate.

---

## 6.7 Architecture has two room instructions but one distinct room address

`lsystem_dungeon.plan_records("branch", 1)` uses:

```text
F[+RF][-RF]F
```

The interpreter appends room position when it reads `R`.

Because both bracketed branches begin from the restored junction, both R records share one position.

`architecture_lesson` deduplicates them through a dictionary of room addresses.

The manuscript is source-supported.

The problem is only that the artifact tells the answer too early.

---

## 6.8 Architecture’s walls are not produced by the L-system turtle

The staged construction:

- rasterises corridor/room footprints into cells;
- unions overlapping cells;
- adds walls only at exposed edges;
- leaves deliberate doors at main-stem ends.

This is exactly why the manuscript’s sentence:

> “The grammar supplies the records; the construction supplies a boundary policy.”

should remain.

---

## 6.9 Competition’s initial 2.250 / 1.980 uptake difference is source-derived

As described above.

This is stronger than an unattached runtime observation.

It follows from:

- 25 cells each;
- 20-cell overlap;
- initial nutrient 0.6;
- 15% sequential uptake.

The exact values are supported by the configured model.

---

## 6.10 Competition’s winter still consumes soil before refusing the rewrite

`_grow_step()`:

1. consumes nutrients;
2. calls diameter growth (winter multiplier makes that growth zero);
3. tests:

```gdscript
nutrients > 0.05 and season != WINTER
```

before L-system generation.

The manuscript correctly says the field changes while visible branching does not.

---

## 6.11 Competition map omission is a curation/route mismatch, not missing implementation

The map and primary source are present.

Its omission is in museum-authored ordering.

Do not classify the hall itself as unfinished on that basis.

---

## 6.12 Living’s core DNA-to-grammar mapping is not in this source bundle

`living_lesson.gd` references:

- `CritterDNA`;
- `TreeMorphology`;
- `CritterTraitMapper`.

Those sources are absent.

Therefore exact claims about:

- segments → generation conversion;
- fork mapping;
- grammar creation;
- 200-command LOD cap;
- morphology build;

are not independently verified by this ZIP.

The surrounding lesson UI and snapshot-copy logic **are** included.

---

## 6.13 Living’s PLANT snapshot copy is source-supported

`_on_export_dna()` now does:

```gdscript
var snapshot := _dna.duplicate(true) as CritterDNA
```

then stores/emits copies.

The manuscript’s explanation that later edits no longer silently alter the exported resource is supported.

---

## 6.14 Living registry describes optional evolution more strongly than the placed lesson

The optional `pressure` hill-climb is real source functionality.

But it is not configured in this placement.

Distinguish capabilities from the active encounter.

---

## 6.15 `ten_print_textile` is now a primary L-systems coda but registry still lists it under Randomness

Artifact registry:

> `map_sequences: ["randomness"]`

Current sequence/map:

> primary artifact in `Assemblage_Same_Desire`.

This should be updated to include L-systems/assemblage use.

---

## 6.16 Assemblage ALPHABET and ODDS genuinely operate on different layers

`reinterpret()` reuses stored per-cell random samples.

Changing:

- alphabet changes mark geometry while retaining sample and threshold;
- odds changes threshold classification using the same sample.

This is a very clean source/text match.

---

## 6.17 Assemblage STEP discards one visible row but does not preserve a complete textile history

The finite window:

- pops the oldest row;
- shifts retained rows;
- adds one new row.

The manuscript correctly treats the discarded route/row as no longer in this window.

Do not imply an offscreen complete history exists unless another logger is added.

---

# 7. Runtime questions

No repository code was executed. Every hall still records `learner_verified: false`.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Whole sequence** | Does the current assembled museum route skip `LSystems_Competition` exactly as `map_authored` reports? What does `next_in_sequence` currently resolve to from Architecture? |
| **Grammar Lab — NEXT/HOLD** | After first NEXT, can a visitor count five live segments before reading the counter? Does HOLD make the two drawings visibly comparable at different angles? |
| **Grammar Lab — fit** | Does fitting make generation growth visually comparable without hiding the fact that the actual turtle path scale changed? Is “Both drawings fitted to their display” readable enough? |
| **Grammar Lab — PLANT** | At preset PLANT / generation 0, is the undrawn `X` legible in the sentence while the live plinth truly contains no line? |
| **Grammar Lab — budget** | Can a visitor reach a requested generation beyond the 4,096-symbol limit with one of the presets and see requested versus retained complete generation clearly? |
| **Growth — stack** | Can the pale point and stack count make SAVE/RESTORE understandable in headset without following only the text readout? |
| **Growth — metres** | At RATIO 1.15 and TREE generation 2, is the ~7.2 m trunk extent actually visible within the hall without clipping/ceiling problems? |
| **Growth — nested branch** | Can a visitor locate a branch within a branch and verify that the length factor applies twice? |
| **Grammars — arrows** | Are gold heading and white used-direction arrows distinguishable at body scale after READ F? |
| **Grammars — reflection** | With same angle, does the blue x/y-swapped path correspond cleanly enough to the green path that a visitor can recognise reflection rather than rotation? |
| **Grammars — TREE** | At 172 symbols / 64 segments, can the first local fork still be found across all three readers as the manuscript asks? |
| **Architecture — shared R discovery** | If the “1 shared address” text is delayed, can visitors successfully trace both R markers back to the same junction? |
| **Architecture — BUILD** | Do wall union/door rules produce one open junction, closed side-branch ends and two main entrances as intended? |
| **Architecture — width** | Reproduce the documented desktop result: 0.6 m diameter body traverses 1.4/2.2 m and is stopped by 0.4 m entrance. |
| **Architecture — rebuild lockout** | While a player is inside the study, do BUILD/WIDTH/ROOMS changes reliably refuse without deferred rebuilding after exit? |
| **Competition — route** | After restoring map order, can the visitor arrive from Architecture and leave to Living without a manual map jump? |
| **Competition — first turn** | Does the live study display source-derived 2.250 / 1.980 first-turn uptake values under the configured pair? |
| **Competition — ORDER** | Does reversing order cleanly reverse which tree receives the larger first uptake while every other initial condition resets? |
| **Competition — WINTER** | Do soil values drop while branch generation stays fixed? Does diameter also remain unchanged under the winter multiplier? |
| **Competition — SOIL** | Does one SOIL press perform exactly one simulated second of diffusion/replenishment without tree growth or season advance? |
| **Living — raw depth threshold** | Include `TreeMorphology`; verify that segments 4.0→4.8 all compile to two generations and 5.0 compiles to three exactly as the text claims. |
| **Living — Angle** | Does a small angle edit visibly rebuild branch directions without changing generation count? |
| **Living — HOLD** | Does held geometry/DNA remain stable under later edits and RESET? |
| **Living — PLANT** | Does the local planted specimen preserve its snapshot under later edits and get replaced only by a later PLANT? |
| **Living — command cap** | Include `TreeMorphology`; verify the reported 200 F/S drawing budget and the treatment of very short segments. |
| **Assemblage — ALPHABET** | Does changing diagonals→orthogonals→blocks reuse exactly the same 144 stored samples/threshold choices? |
| **Assemblage — ODDS** | With a fixed sheet, do cells whose samples lie in `[0.5,0.75)` change side exactly as expected when odds rises from .5 to .75? |
| **Assemblage — HOLD** | Does the held sheet remain visually unchanged while editable sheet changes seed/alphabet/odds? |
| **Assemblage — STEP** | Does exactly one old row leave and one new row enter while the other eleven retain their stored samples and shift? |
| **Assemblage — floor** | Is the floor physically continuous/supporting in every alphabet/odds state, with no collision derived from the marks? |
| **Assemblage — secondary loom/gallery** | Do the retained working loom and maker galleries remain legible as separate procedures rather than being read as extensions of the two-mark random textile? |

---

# 8. What I would not cut

## Do not cut HOLD from Grammar Lab

HOLD is what makes:

> same sentence / different interpreter

physically inspectable.

Without it, TURN would simply replace one result with another.

---

## Do not cut fit-to-display from the discussion

The fit is not an implementation nuisance.

It changes what “larger generation” looks like and makes the difference between computed path and composed display explicit.

---

## Do not cut the invisible `X`

It gives the sequence an important lesson:

> a symbol can be operational in rewriting while having no direct drawing action.

This prepares more complex grammars better than another visible segment would.

---

## Do not cut the 4,096-symbol budget

Finite grammar systems need a stopping/budget rule.

The important part is that this one preserves complete generations rather than cutting through a sentence.

Keep it.

---

## Do not cut STEP from Growth even though the whole sentence could be drawn at once

The non-drawing bracket operation is only really understandable when the visitor sees state change without geometry change.

STEP is doing epistemic work.

---

## Do not cut the “length_decay > 1” experiment

It exposes the difference between a variable name and the operation.

The multiplier can lengthen.

That is exactly the kind of source literacy the project values.

---

## Do not cut the x/y-swapped reader as whimsical

It demonstrates the sequence’s central thesis with one executable change:

> symbol meaning belongs to the interpreter.

The fact that many geometric relations survive the reflection makes it even stronger.

---

## Do not cut Architecture’s duplicated R records

Two symbols / one address is a very useful array/grammar distinction.

Just stop printing the answer before the visitor can discover it.

---

## Do not cut WIDTH or treat it as an accessibility footnote

It is the point where symbolic connectivity becomes body-relative passage.

The same graph remains connected while one body loses access.

Keep it central.

---

## Do not remove Competition merely to make the museum route shorter

It is the only chapter where a grammar’s continuation depends on a shared environmental resource and update order.

The sequence loses an important causal layer without it.

---

## Do not cut winter consumption because “nothing grows”

That is precisely the discovery:

> visible stillness does not imply the environment remained unchanged.

Keep it.

---

## Do not cut SOIL as a secondary system control

SOIL lets the field change without a tree turn.

That makes environment and grammar separable enough to inspect.

---

## Do not cut Living’s quantised Depth mapping

This is one of the book’s clearest examples of:

> a smooth user control feeding a discrete downstream instruction.

It belongs in the main text.

---

## Do not call DNA “life” more strongly

The manuscript’s line:

> “DNA here means a collection of parameters used to construct a body”

is exactly right.

Keep it even if optional evolutionary pressure remains in the underlying artifact.

---

## Do not cut snapshot copying from Living as implementation trivia

Without a deep copy, “placed design” is not actually stable.

Persistence is part of the conceptual encounter.

Keep the source-level explanation.

---

## Do not cut Assemblage because it is not an L-system

Its job is to prove the sequence’s method travels:

> stored decision → interpreted mark → perceived path.

That is an excellent coda.

---

## Do not cut the perceived paths as “only subjective”

The image genuinely contains connected-looking relations.

The crucial distinction is:

> those paths were not planned routes and do not automatically have collision/connectivity semantics.

The reader’s contribution remains part of the encounter.

---

# 9. Reader-experience strengths to protect

## Discovery before naming

**Grammar Lab**  
same sentence / different shape before rewrite/interpreter terminology fully arrives.

**Growth**  
SAVE changes state without drawing before stack explanation.

**Grammars And Curves**  
stored heading and used direction visibly disagree before larger-tree interpretation.

**Architecture**  
plan becomes bodily only after BUILD; shared room address can become a discovery once the readout is delayed.

**Competition**  
turn-order advantage appears before resource subtraction is shown.

**Living**  
control moves several times without tree change before quantisation is named.

**Assemblage**  
a perceived path is followed before the generator’s ignorance of that path is explained.

---

## Prediction before explanation

- Can one sentence have two bodies?
- Where will the turtle return after `]`?
- Why does changing ANGLE not alter the first line?
- Do two `R`s necessarily mean two rooms?
- Which tree gets more soil on the first turn?
- Is the Depth control doing anything before 5.0?
- Does the same path survive another alphabet?

These are excellent questions and should remain the sequence’s rhythm.

---

## Productive distinctions to protect

- rewriting ≠ interpretation
- symbol ≠ drawing action
- generated string ≠ printed prefix
- interpreter state ≠ drawn line
- changed parameter ≠ immediately used parameter
- saved state ≠ return line
- same sentence ≠ same geometry
- graph connectivity ≠ bodily passage
- room marker count ≠ distinct room addresses
- grammar output ≠ architectural boundary policy
- same grammar ≠ same future in a changed environment
- visible stillness ≠ unchanged resource field
- raw continuous gene ≠ compiled discrete generation count
- editable source ≠ held witness ≠ planted snapshot
- optional evolutionary pressure ≠ manual sculpting lesson
- random sample ≠ threshold decision ≠ mark alphabet
- perceived path ≠ planned route
- visual mark ≠ collision boundary.

This list is the real L-systems curriculum.

---

# 10. Questions for the author

## 10.1 Is Competition definitively part of the current spine?

The declared sequence, chapter transitions and source package all say yes.

`map_authored` says no.

I recommend restoring it unless there was a deliberate curatorial decision to remove it.

---

## 10.2 Do you want Architecture’s duplicate-room fact to be discovered?

The manuscript clearly stages it that way.

If yes, remove `1 shared address` from the startup labels.

If it is intended as explicit diagram information, then the manuscript should stop asking the visitor to work it out.

I prefer discovery-first.

---

## 10.3 Should Grammar Lab eventually allow typing/editing a production rule?

The current chapter works without it.

Its closing limitation:

> presets do not exhaust grammar possibilities; the physical desk cannot yet type a rule

is useful.

If direct editing is a future goal, it would deepen the transition to procedural generation.

But I would not delay publication of this sequence for it.

---

## 10.4 Is the evolutionary `pressure` system part of Living or a later evolution/ML encounter?

The placed Living lesson does not use it.

I would keep Living centred on manual authoring, quantisation and persistence.

If pressure is important, expose it in a separate controlled comparison where the fitness function is visible.

---

## 10.5 Is “DNA” intentionally retained as the tool’s public metaphor?

The manuscript handles it responsibly.

If kept, continue doing exactly what the current chapter does:

> name the data structure and immediately state what the name does **not** establish.

---

## 10.6 Do you want Assemblage Same Desire to remain formally inside L-systems?

I think it works as a coda because it tests whether the grammar/interpreter distinction survives outside string rewriting.

Its cross-sequence character is a strength.

Update registry metadata so that intention is legible.

---

# 11. Overall conclusion

L-systems is a strong sequence because its current manuscript has gradually stopped treating “grammar” as a magical generator of form.

The primary encounters show a more exact pipeline:

> **symbols are rewritten**  
> → **a reader gives symbols actions**  
> → **the reader carries/restores state**  
> → **another reader can interpret the same symbols differently**  
> → **a spatial constructor gives the resulting records width, rooms, walls and collision**  
> → **a shared environment can permit or refuse further rewriting**  
> → **an authoring tool exposes only some grammar/body parameters**  
> → **the same stored decisions can be reinterpreted through another alphabet**.

That is a coherent Ada argument.

The strongest reader moments are the places where a symbol or control initially seems to mean more than it does:

- `X` exists in the grammar but draws nothing;
- `[` changes state without extending a line;
- `]` restores a fork without drawing a return path;
- “forward” can be read sideways;
- two room symbols can name one place;
- a connected centreline can become too narrow for a body;
- two identical grammars can diverge because one acts after the other;
- a tree can consume resources in winter while refusing to branch;
- a Depth slider can move while the compiled generation count does not;
- a planted specimen remains because its data was explicitly copied;
- the same binary choices can become diagonals, orthogonals or blocks;
- a visual path can be real to perception without having been authored as navigation.

Those are excellent sequence-level discoveries.

The highest-value work now is therefore:

1. **restore or explicitly remove Competition so the museum route and book tell one sequence;**
2. **delay Architecture’s “1 shared address” answer until the visitor has followed the bracketed room markers;**
3. **rewrite sequence/source metadata around rewrite → interpreter → construction → environment rather than “grammar grows worlds/aliveness”;**
4. **include `CritterDNA` / `TreeMorphology` / related global-class dependencies in future review bundles and distinguish Living’s manual lesson from optional evolutionary pressure;**
5. **clean primary artifact identities that still collapse grammar, interpretation and body into one poetic claim;**
6. **headset-test the embodied claims, especially metre-scale Growth, 0.4 m Architecture access, Competition route/instrument legibility, and Assemblage floor support.**

The reader-experience principle I would carry forward from L-systems is:

> **Let the same instruction acquire two different consequences before naming the interpreter that made them different.**

And the structural principle is:

> **A grammar supplies possibilities for rewriting. It does not by itself supply a body, a habitat, a route, a resource, or a meaning. Those arrive through additional readers and relations.**
