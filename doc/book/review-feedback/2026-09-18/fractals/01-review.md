# Fractals — 01 Review

Source-aware editorial and reader-experience review of the **Fractals** sequence.

Basis: `fractals-book.md`, `fractals-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where the visitor can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. Recurrence is not treated as redundancy when a construction returns at another scale, with another branching factor, another removal rule, another body, or another representation.

The current sequence has a strong and coherent arc:

> **self-call → branching inheritance → repeated removal → replacement and measurement → porous volume → numerical recurrence and mapping → procedural synthesis**

A second formulation is:

> **A fractal-looking form does not tell us how it was made. We have to separate the repeated instruction, what each call receives, where it places its descendants, what stops the process, what gets removed, and what the finite display or body can actually resolve.**

That is more precise than older project rhetoric about “the golden ratio everywhere,” “walkable fractals,” or a finite measured slope simply **being** fractal dimension.

---

# 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **Fractal Recursion** | **Carries:** an excellent opening because four objects immediately separate kinds of “again”: one self-call, four self-calls, a finite split budget spent on selected cells, and an authored five-stage chair that is **not recursive at all**. LAYOUT/COLLAPSE, PACKING/TURN, DRILL/SPREAD and GHOST/SCAR make procedure, placement, visibility and selection independently inspectable. **Gap:** the manuscript is stronger than several source identities/registry notes. In particular, current `cube_subdivision.gd` supports twelve DRILL/SPREAD splits and 85 cells, while stale registry DNA says DRILL saturates at ~35 visible cells due to a 1 cm cutoff that is not present in the current executor. **Next:** preserve the chapter; clean that registry contradiction and runtime-test whether tiny deep DRILL cells remain meaningfully visible in headset. |
| **Fractal RecursiveTrees** | **Carries:** a clear branching experiment. GROW changes generation count; ANGLE and LENGTH alter geometry without changing segment count; FORKS changes the graph itself; the deterministic tree has no random variation, while the red block tree uses a seeded local RNG and offers STRATA/REACH/ENDS as alternative readings of already-built geometry. The chapter repeatedly asks what a branch inherits and what a seed cannot specify. **Gap:** no major source/text contradiction. The map metadata still says “natural forms” and “deterministic vs stochastic” rather broadly, while the manuscript carefully says neither tree seeks light, water, support, or shelter. **Next:** preserve and headset-test branch readability rather than adding explanation. |
| **Fractal CantorSet** | **Carries:** perhaps the sequence’s cleanest quantity/body progression: each generation doubles piece count while retained length falls; HISTORY separates current state from the record used to explain it; GHOST visualises removal without restoring support; the pagoda turns an interval gap into a bodily passage and DEPTH changes travel length without changing opening width. **Gap:** the old map description still foregrounds “infinite subdivision / zero-measure infinite set,” whereas the actual room is unusually careful about a five-cut finite instrument and body-dependent passage. **Next:** preserve the finite/limit distinction and verify the narrow-gap embodied comparison in headset. |
| **Fractal KochSierpinski** | **Carries:** three distinct experiments work together unusually well: Koch separates endpoint distance from path length; Sierpinski makes removal itself available as a positive/negative view; box counting then turns “dimension” into a measurement procedure whose fitted value changes with the selected range even while the point sample stays fixed. **Gap:** source identity for `box_counting_dimension` still says “the slope IS the dimension” and that finer grids “converge to true dimension,” while the staged lesson correctly labels a **finite-scale fit** and lets coarse/fine/all ranges disagree. **Next:** clean source/registry rhetoric; keep the manuscript’s measurement-first caution. |
| **Fractal MengerSponge** | **Carries:** a very strong embodied culmination of repeated removal. One cut turns a solid cube into a crossing; the second reproduces smaller openings; GHOST marks removed volume without collision; flight changes locomotion without changing the sponge; the same geometric connectivity becomes usable or unusable depending on body dimensions. The chapter correctly distinguishes the finite 400-cube specimen from the infinite Menger limit. **Gap:** the flight enclosure’s large sign says **FLY THROUGH THE HOLES** before the first NEXT has created any hole, pre-answering the opening discovery. The XR movement provider is also outside this source snapshot, so headset flight behaviour is not independently source-verified. **Next:** delay/neutralise the sign and include the provider in future bundles. |
| **Fractal GoldenSpiral** | **Carries:** the current chapter is much better than its old title/metadata. Fibonacci is first treated as a numerical recurrence and then as two different height mappings; SUM makes the recurrence physically checkable only in linear mode. The retained “natural” examples are explicitly tagged as additional mapping rules, including the crucial correction that the displayed helix grows by φ per **full** turn, not the quarter-turn convention usually called a golden spiral. The golden rectangle then separates retained proportion from the quarter-circle arc drawn through its squares. **Gap:** source identity and map objectives still say Fibonacci/golden ratio govern sunflower packing, shells and natural growth broadly. The current lesson wrapper has already done the harder work of qualifying those claims. **Next:** update map/registry language to match the actual mapping lesson rather than re-expanding the mythology. |
| **Fractal Synthesis** | **Carries:** an excellent ending. Cantor and the seeded block tree are revisited not as canonical names but as procedures the visitor must verbally reconstruct: retained fraction, placement, inherited origin/direction, branching count, depth stop, seed/draw order. HISTORY/GHOST and STRATA/REACH/ENDS again separate generated state from interpretive views. The transition to L-systems is precise: rewriting a string and interpreting it as movement are another pair of operations to separate. **Gap:** little editorially. A small `fractal_procedure_gallery` prompt sits near the entrance before the two primary desks; its implementation is not included in the primary snapshot, so verify that it does not name the procedures too explicitly before the manuscript asks for a description “without using their names.” **Next:** preserve the chapter and runtime-check that the coda prompts support rather than pre-empt verbal reconstruction. |

---

# 2. Sequence structure

Unlike several previous bundles, the **declared sequence order and museum-authored order already agree**:

1. Fractal Recursion  
2. Fractal RecursiveTrees  
3. Fractal CantorSet  
4. Fractal KochSierpinski  
5. Fractal MengerSponge  
6. Fractal GoldenSpiral  
7. Fractal Synthesis

That order is conceptually strong.

## 1. Recursion — separate procedure from appearance

The sequence begins by refusing the shortcut:

> nested or subdivided appearance = recursion.

It places four related-looking constructions beside each other:

- a one-child self-call;
- a four-child self-call;
- selected subdivision with no self-similar generation front;
- an authored chair built through five explicit stages and **no self-call**.

This is exactly the right opening.

## 2. Trees — give descendants inheritance

The next question is not merely “branch more.”

A child receives:

- parent endpoint;
- parent direction;
- inherited/scaled length;
- a turn;
- a descendant count.

The second tree adds seeded variation without changing the need for those inherited values.

This prepares the later language of grammar very well.

## 3. Cantor — repetition can remove

Branching had multiplied material.

Cantor now multiplies **pieces while decreasing retained measure**.

The room also adds an essential representational distinction:

- current generation;
- displayed history;
- ghosts of removed parts.

Then the pagoda asks what a removed interval becomes when it receives:

- height;
- depth;
- collision;
- a visitor body.

## 4. Koch / Sierpinski — boundary, removal, measurement

This hall broadens the fractal vocabulary without collapsing it into one definition.

- Koch: replacement increases path length at fixed endpoints.
- Sierpinski: repeated removal decreases retained area while increasing addressed pieces.
- Box counting: a finite point sample is measured through a family of covers, and the fitted slope depends on chosen scale range.

That is stronger than a glossary of famous fractals.

## 5. Menger — removed volume becomes inhabitable space

This is the correct three-dimensional culmination of the removal thread.

The important progression is not:

> 1D → 2D → 3D means “more fractal.”

It is:

> an absence that was a gap in an interval becomes a hole in a surface and then a volume a body might occupy.

The flight fixture then lets locomotion vary independently of the generated geometry.

## 6. GoldenSpiral — numerical recurrence is not geometric recursion

This is a useful deliberate turn.

The sequence leaves recursive calls and asks:

> if the next quantity depends on previous quantities, what must be added before the numbers become a spatial form?

The chapter’s current answer is very good:

- recurrence supplies numbers;
- mapping supplies tower height;
- additional rules supply seeds, shells, helices, branches;
- the golden rectangle supplies a self-similar proportion under repeated subtraction;
- the quarter-circle arc is another added representation.

## 7. Synthesis — name the instruction, not the image

The final hall asks the visitor to reconstruct a procedure without relying on canonical names.

That is exactly what L-systems need:

> explicit alphabet / rewriting / interpretation instead of “this looks like a tree.”

The sequence ends by making procedural description itself the transferable skill.

---

# 3. Reader-experience lens

## Fractal Recursion — How many times can *again* happen?

### Curiosity

The first square is excellent because the visitor can understand the instruction before knowing the term recursion:

> press MORE → another smaller square appears.

LAYOUT then produces the first productive surprise:

> the same stored set can read as nested interior or temporal/successive row.

COLLAPSE adds another:

> visible distinction can disappear while the count remains.

### Discovery

The one-call versus four-call comparison works very well.

The circle instrument asks for a count prediction:

- 1
- 5
- 21
- 85
- 341

while footprint remains roughly bounded.

That is a concrete way to make branching factor computationally meaningful.

PACKING then changes spatial relation without changing count.

The DUST/depth-five cutoff is especially good because it distinguishes:

- requested recursion depth;
- source minimum size;
- actually drawn level.

### Cube subdivision

The selected-split machine adds another form of “again.”

A press does **not** transform every current cube.

It chooses one existing cell and replaces it with eight, so each split adds seven net cells.

Twelve successful splits therefore give:

> `1 + 12 × 7 = 85`

regardless of whether selection is DRILL or SPREAD.

The important difference is where the budget is spent:

- DRILL repeatedly descends through one lineage;
- SPREAD selects the shallowest remaining cell.

That is a very good comparison.

### Important source correction

During the source pass, a stale registry DNA note initially suggested DRILL stopped creating visible cells below a 1 cm cutoff and saturated at 35 cells.

The current `cube_subdivision.gd` executor contains **no such cutoff**.

It instantiates eight children on every successful split with:

```gdscript
new_scale = cube_scale * 0.5 * 0.9
```

and the lesson caps the budget at twelve splits.

So the manuscript’s 85-cell comparison is supported by the current executor.

The registry note should be corrected because it can mislead future reviews/capture tooling.

### Chair

The chair is perhaps the room’s strongest conceptual object.

The source’s first subdivision divides a 3×3×3 cube into 27 roles:

- 16 kept cells;
- 11 removed cells.

Later steps reshape seat, legs and back and add details.

The lesson readout says explicitly:

> authored sequence of five stages / no self-call.

That makes “recursive chair” a useful false friend rather than a mistake to hide.

### Timing

Very good.

RULE is opt-in.

No major concept is named before the visitor has one consequence to inspect.

### Return

Primitives and Tiling return through subdivision and occupancy, but the new subject is **continuation**:

> which output becomes another input to the same instruction?

---

## Fractal RecursiveTrees — Where will the next branch go?

### Curiosity

A trunk waiting for its first fork is an excellent reduction.

The visitor is asked to predict one branch before looking at the whole tree.

That prevents the “tree silhouette” from swallowing the local rule.

### Discovery

The deterministic lesson is very clean:

- GROW increases generations;
- ANGLE changes placement without count;
- LENGTH changes inherited scale without count;
- FORKS changes branching factor and therefore count.

At generation four:

- 2 forks → `1 + 2 + 4 + 8 + 16 = 31` segments;
- 3 forks → `1 + 3 + 9 + 27 + 81 = 121`.

This gives the visitor a direct distinction between:

> changing edge geometry  
> versus changing graph structure.

### Deterministic / stochastic comparison

The first tree deliberately turns randomness off.

The second block tree uses a fixed local RNG and seeded branching/dimensions.

STRATA / REACH / ENDS do not regenerate it; they reinterpret already-built geometry.

This is a particularly good continuation of the book’s representation method.

### Timing

Very good.

The code arrives after the visitor has followed inheritance spatially.

The critical paragraph:

> no light, root water, neighbour shade, climbable support

comes only after the tree has been allowed to persuade the eye.

That is the right timing.

### Return

Forces’ vectors return as inherited direction/endpoint.

Randomness returns as bounded variation inside a construction rule.

Neither return dominates the new branching question.

---

## Fractal CantorSet — More pieces, less material

### Curiosity

The first instruction is beautifully simple:

> one bar → where could it go if it became two?

The visitor is encouraged to find the **gap before the pieces**.

That is the right perceptual priority for this chapter.

### Discovery

The key contradiction develops immediately:

- piece count increases;
- retained total length decreases.

HISTORY then shows something else:

> the busy visual field partly belongs to the explanatory record, not the current Cantor generation.

GHOST makes absence visible without making it solid.

This is very strong.

### Finite versus limit

The manuscript handles this unusually well:

> fifth cut still has finite bars with width/depth;
> the mathematical construction has no final cut;
> zero total length / uncountably many points belongs to the limiting mathematical set, not to the headset display.

Keep this distinction exactly.

### Pagoda

The bodily extension is well chosen.

The lesson wrapper deliberately sets:

- base width 9 m;
- cuts 1–3;
- block height 2.2 m;
- adjustable depth 1/2/4 m.

So after successive cuts the visible gap family includes:

- 3 m;
- 1 m;
- 1/3 m.

The same “gap” therefore becomes several bodily questions.

DEPTH is important because opening width can stay fixed while passage length changes.

### Timing

Excellent.

The body only enters after the interval rule is established.

The lesson does not say “fractal architecture is walkable” in general.

It asks which interval admits this implemented body.

### Return

Array/Trace return through history.

Polyhedra/Transformation return through gap versus passage.

Fractals adds repeated removal.

---

## Fractal KochSierpinski — The boundary takes a detour

### Koch: curiosity

The opening question:

> four metres of line; endpoints fixed; where could more line go?

is excellent.

The visitor discovers longer path before seeing the count.

TURN then demonstrates:

> same count + same path length ≠ same shape.

FORM adds inside/outside without changing the replacement rule itself.

### Finite versus ideal

The manuscript again keeps the limit honest.

At step four:

- 256 finite segments;
- path ≈ 12.64 m at the staged 4 m start.

The ideal indefinite Koch construction is discussed as a mathematical continuation, not claimed as the object on the desk.

Good.

### Sierpinski: removal as alternative subject

VIEW is a strong artifact choice.

The source computes both:

- retained corner triangles;
- removed middle triangles.

The visitor can switch:

- absence;
- ghost;
- negative.

So what was “waste” becomes another visible subject without changing the recursive corner computation.

This is conceptually rich.

### Box counting: measurement rather than revelation

The measurement instrument is one of the best source/text alignments in the sequence.

It uses:

- 8000 chaos-game points;
- fixed seed 2026;
- six grid scales;
- occupied-cell counts;
- linear fit in log₂(count) versus log₂(1/box size);
- selectable coarse three / fine three / all six.

The lesson readout explicitly says:

> **finite-scale fit**

This is exactly right.

The point cloud stays fixed while the reported slope changes with the selected fit range.

The visitor therefore learns:

> “fractal dimension” in this instrument is a measurement procedure with finite sample/scale choices.

### Timing

Very strong.

RANGE is not shown until requested.

The ideal `log(3)/log(2)` value arrives after the finite estimates can already disagree.

### Source mismatch

The old identity says:

> “the slope IS the fractal dimension”  
> “fine grids converge to true dimension.”

That rhetoric is too strong for this finite instrument.

Clean the identity; keep the manuscript.

---

## Fractal MengerSponge — A hole becomes a place

### Curiosity

The chapter has a perfect opening:

> “The cube has no entrance.”

Then:

> press NEXT and find the opening before counting blocks.

The visitor is meant to discover the first cross-shaped through-passage.

### Artifact timing problem

The flight enclosure exists from the beginning and its large four-line sign says:

> **FLY THROUGH THE HOLES**

on both sides of both ground doors.

That tells the visitor in advance:

- holes are coming;
- they are intended to be flown through.

This is exactly the discovery the first NEXT should produce.

### Artifact proposal

Before the first cut, use a neutral title such as:

> **LOCAL FLIGHT VOLUME**

or:

> **FLIGHT AVAILABLE INSIDE FRAME**

After the first cut, the lesson can update the title to:

> **FLY THROUGH THE OPENING**

After the second:

> **WHICH HOLE CAN THIS BODY USE?**

The movement instructions can remain visible throughout.

### Discovery

The source now correctly retains 20 of each 27 subcubes:

- centre removed;
- six face centres removed;
- 20 retained.

The repaired implementation uses integer x/y/z lattice indexing and operates only on cubes belonging to this sponge.

This matters because the bundle’s registry documents two serious historical bugs that are **already repaired in the current snapshot**:

1. old float z-division smeared the 3×3×3 structure;
2. old cube scanning could accidentally subdivide neighbouring map artifacts.

The current manuscript assumes the repaired Menger geometry, which is appropriate for this snapshot.

### Counts / volume

At staged 9 m initial size:

- cut 0: one 9 m cube → 729 m³;
- cut 1: 20 cubes, side 3 m → 540 m³;
- cut 2: 400 cubes, side 1 m → 400 m³.

These are source-supported consequences of the implemented keep table.

### GHOST

Very good.

The removed cells are returned as pale volumes with no collision.

The visitor can see subtraction and passage at once without changing the actual occupied set.

### Flight / body

This is where the hall becomes more than a canonical fractal display.

The enclosure changes locomotion, not the sponge.

A large 3 m central passage can admit the desktop body.

A second-level axial opening is 1 m × 1 m.

The book says the desktop capsule is 1.5 m high; that dimension is documented in the supplied technical notes, but the actual XR movement provider/collider implementation is not in this source snapshot.

So:

- desktop comparison is plausible/source-documented;
- VR body size remains user/setup dependent and must be runtime-tested.

### Timing

Excellent except for the flight sign.

### Return

Cantor’s gap becomes inhabitable volume.

Force-as-Place’s local movement mode returns as a receiver change independent of geometry.

Very strong.

---

## Fractal GoldenSpiral — A number needs a mapping

### Curiosity

The first towers are effective because they begin as numbers before becoming “natural” imagery.

The visitor is asked:

> after 1,1, what comes next?

Then the suspicious heights create the second question:

> why is 55 not 55 times taller than 1?

That makes representation visible before the formula is shown.

### Discovery

HEIGHT is the key control.

The sequence itself does not change.

Only the mapping does:

- log: `0.5 ln(value) + 0.5`;
- linear: `0.05 value`.

SUM then becomes a particularly good instrument:

> in linear mode, 21 unit layers + 34 unit layers exactly reach 55 unit layers.

Return to logarithmic mapping and the visual equality disappears even though the recurrence does not.

Excellent.

### Retained “natural” examples

The current lesson wrapper is unusually self-critical.

It deliberately tags the held examples with their **added rules**:

- seed points: radius ∝ √i, turn = 360/φ²;
- layered “pinecone”: 8 around × 13 layers with 0.3 rad turn;
- shell-like chambers: chosen growth + quarter turns;
- helix: radius × φ per **full turn**;
- branch diagram: a different branching rule.

This is much better than the old source identity saying:

> golden ratio governs spiral growth, seed packing, shells, and trees.

The manuscript correctly says:

> the Fibonacci recurrence did not contain instructions to make a flower.

### “Golden spiral” correction

The original `FibonacciSequences.gd::create_golden_spiral()` uses:

```text
radius ∝ φ^(angle / 2π)
```

so radius grows by φ over a **full** turn.

The conventional golden spiral grows by φ every **quarter turn**.

The lesson wrapper explicitly labels the displayed object:

> **LOGARITHMIC HELIX / radius × phi per FULL turn**

and the manuscript uses that mismatch as evidence.

This is excellent source criticism.

### Golden rectangle

The second main instrument is cleaner than the old “golden spiral” mythology.

Repeatedly removing the shorter-side square from a golden rectangle leaves a similar golden rectangle.

ARC then adds quarter-circle segments through the squares.

The manuscript correctly says:

> joined quarter-circles resemble a logarithmic spiral but are not the same smooth curve.

Keep that.

### Timing

Excellent.

RULE is optional.

ARC is off initially, so the subdivision can be understood before the familiar spiral image appears.

### Metadata problem

The map’s learning objectives still say:

- Fibonacci sequence;
- golden ratio;
- golden angle;
- phyllotaxis.

The current chapter is really about:

> **recurrence → mapping → additional construction rules → proportional self-similarity.**

Update the metadata to match the better lesson.

---

## Fractal Synthesis — What, exactly, is repeated?

### Curiosity

This is a strong coda because it asks for description without canonical names.

The visitor has to say:

- what one step receives;
- what survives;
- where descendants go;
- what stops.

That is much closer to a usable computational understanding than “this is a Cantor set.”

### Cantor return

HISTORY and GHOST return, but now as evidence about description:

> “remove middle thirds” still omits placement, retained fraction and stop condition.

The visitor must supply those.

### Tree return

The seeded red block tree is also well chosen.

The source scene sets `random_seed = 12345`.

The recursive source passes:

- parent;
- endpoint/origin;
- descendant count;
- current/max depth.

Additional seeded draws choose dimensions, directions and descendant counts.

STRATA/REACH/ENDS do not regenerate the tree.

They reveal another reading of fixed geometry.

### Timing

Very good.

The main possible issue is the entrance prompt artifact `fractal_procedure_gallery`.

Its source is not part of the primary bundle.

Because the manuscript begins:

> “Can you explain two recursive constructions without using their names?”

the entrance prompt should not immediately print canonical names or full procedural answers.

That needs runtime/source verification.

### Return

The chapter is an excellent preparation for L-systems.

It ends by explicitly distinguishing:

- string rewrite;
- interpretation as movement/geometry.

The warning that the grammar-lab preset called “Koch Curve” uses a different rule/turn angle from the equilateral snowflake is exactly the right handoff.

---

# 4. Four high-value changes

Four are enough. The sequence does not need a fifth intervention simply because the review format permits one.

## 4.1 Menger — delay the flight sign’s conceptual answer until a hole exists

**Hall / instance**

`Fractal_MengerSponge`

Primary:

`menger_sponge:0:2#flight_box:true#lesson:true`

### Current manuscript

> “The cube has no entrance.”

> “Press NEXT. Find the opening before counting the blocks.”

### SOURCE

`museum_flight_box.gd` defaults to:

```gdscript
@export var instruction_title: String = "FLY THROUGH THE HOLES"
```

`menger_sponge.gd::_sync_flight_box()` creates the enclosure immediately when `flight_box:true` and does not change that title.

The sign is built on both sides of both doors.

### Problem

The visitor is asked to discover:

> removal produced a through-opening that might become a place.

But the room already says:

> there are holes; fly through them.

This converts the first removal into confirmation.

### Artifact proposal

Initial title:

> **LOCAL FLIGHT VOLUME**

or:

> **FLIGHT AVAILABLE INSIDE FRAME**

After first NEXT, update to:

> **FLY THROUGH THE OPENING**

After second NEXT:

> **WHICH HOLE CAN THIS BODY USE?**

Keep the control instructions unchanged.

### Reason

This preserves accessibility while letting the first geometric opening actually arrive as a discovery.

---

## 4.2 Clean Fractals’ remaining “golden nature / infinite object” metadata so it matches the finite, procedural book

**Location**

`sequence.json`, map descriptions/objectives, source identities.

The top-level `sequence.json.truth` is already good:

> “A finite construction lets us investigate repeated rules, scale, removal and the cost of further detail.”

But older submetadata still makes stronger claims.

### Current stale examples

**Menger sequence content**

> “Walkable Three-Dimensional Fractal — D≈2.727, infinite surface zero volume”

The room is deliberately a **finite two-cut 400-cube object** with one implemented body/flight relation.

**Golden Spiral content**

> “Fibonacci and Phyllotaxis — golden ratio, 137.5°, romanesco”

The current primary chapter is recurrence + mapping + golden rectangle.

Phyllotactic/natural examples are held side exhibits whose extra construction rules are explicitly exposed.

**Fibonacci source identity**

> “To reveal the golden ratio everywhere”

and:

> “growth, when it remembers its last two steps, spirals.”

Those are precisely the shortcuts the current chapter now teaches against.

**Golden rectangle identity**

> “the classic Fibonacci spiral construction”  
> “the golden spiral emerges”

The artifact actually draws quarter-circle arcs through golden-rectangle squares.

The manuscript correctly distinguishes that joined circular construction from a smooth logarithmic golden spiral.

**Completion reward**

`mandelbrot_master_badge` remains even though Mandelbrot is explicitly deferred outside the current seven-hall route.

### Proposed metadata direction

For Menger:

> **Finite repeated removal in 3D; compare retained volume, geometric openings and body-dependent passage.**

For Golden:

> **Distinguish numerical recurrence from the mappings that give it height, angle, radius or geometric subdivision.**

For the sequence generally:

> **Repeat, branch, remove, replace and measure finite constructions; compare the generated form with the mathematical continuation and with the body that encounters it.**

### Reason

The current manuscripts have already done the hard conceptual work.

Cleaning metadata prevents future curation/review from reintroducing the very naturalising myths the book now interrogates.

---

## 4.3 Fix the stale `cube_subdivision` registry DNA that contradicts the current executor

**Hall / instance**

`Fractal_Recursion`

A3:

`cube_subdivision:180:1.5#seed_value:31415#lesson:true`

### Current manuscript

> “Choose DRILL and spend the twelve splits. Then choose SPREAD and spend the same allowance. Both end with eighty-five cells. The readout reaches depth twelve in one case and depth three in the other.”

### SOURCE

Current `cube_subdivision.gd`:

- every successful split removes one cube and adds eight;
- there is no size-based early return in `subdivide_cube_return_children()`;
- new child scale is:

```gdscript
new_scale = cube_scale * 0.5 * 0.9
```

- lesson budget is twelve splits;
- DRILL follows a child from the last split;
- SPREAD chooses a shallowest current cell.

Therefore after twelve successful splits:

> `1 + 12×7 = 85` cells.

The manuscript is source-supported.

### Conflicting registry DNA

`artifact-index.json` still says DRILL:

> “SATURATES ABOVE fine”  
> “fine, dense and limit all leave 35 visible cubes”

and attributes that to a 1 cm minimum.

That minimum is not present in the current executor.

### Proposal

Recompute/rewrite the registry DNA from the current source.

If the old 35-cell result came from:

- capture visibility;
- an older branch;
- an external runner threshold;

name it explicitly as historical evidence rather than current artifact behaviour.

### Runtime test

At the twelfth DRILL split, the deepest cell is extremely small.

Verify whether it is actually distinguishable in headset.

If not, the **reader-facing** issue is perceptual resolution:

> computation continues after experience stops differentiating the result.

That would strengthen the current manuscript line:

> “More work need not yield more experience.”

### Reason

This contradiction already produced a false interim review finding.

It is precisely the kind of stale metadata the source-aware workflow is intended to catch.

---

## 4.4 Box Counting — make the source identity as cautious as the actual finite-scale instrument

**Hall / instance**

`Fractal_KochSierpinski`

A4:

`box_counting_dimension:180#lesson:true`

### Current manuscript

> “The ideal Sierpinski triangle has dimension `log(3) / log(2)`, about 1.585. This instrument fits a finite sample at six box sizes. The number it returns depends on those choices; it is evidence from a procedure, with a range beyond which we have not tested it.”

This is excellent.

### SOURCE identity

`box_counting_dimension.gd` still says:

> “the slope IS the fractal dimension”

> “fine grids converge to true dimension”

> “The number 1.585 from pure geometry. Measurement from counting.”

But the staged lesson itself has been improved:

- fixed 8000-point sample;
- six finite covers;
- coarse/fine/all fit selection;
- readout says:

> **finite-scale fit = ...**

The same sample can produce different fitted slopes when RANGE changes.

### Proposal

Update identity to something like:

> **Estimate a box-counting slope from a finite sampled point set over selected box scales; compare how the estimate changes with the fit range.**

And:

> **The ideal Sierpinski construction provides a known reference value; this instrument does not make the finite estimate exact.**

### Reason

The artifact is already teaching epistemic humility through interaction.

Its header should not claim certainty that the instrument itself has been designed to question.

---

# 5. Source / artifact discrepancies

## 5.1 Recursion-square source identity says self-call is visible from the image; the manuscript correctly denies that

Old identity:

> “a square inside a square ... is the first evidence that a function can call itself.”

The current chapter says:

> this particular one-child descent could be written as a loop; appearance does not tell us which program made it.

The manuscript is better.

Clean the identity.

---

## 5.2 Recursive circles are a branching recursion, but “first fractal you can hold” is rhetoric rather than an operational claim

The source implements exactly four child calls per ring with a size cutoff.

Depth and packing are real variables.

The book wisely focuses on:

- branching cost;
- packing;
- cutoff;
- overlap/pose.

No need to call it the first fractal or make ontological claims about self-reference.

---

## 5.3 Cube-subdivision registry is stale relative to current source

As detailed above.

This should be fixed in the review infrastructure.

---

## 5.4 Recursive chair’s old “chair was always inside the cube” identity contradicts the source and current manuscript

Source identity still says:

> “The chair was always inside the cube — subdivision merely removed what was not chair.”

But after the 3×3×3 role selection, subsequent stages:

- flatten seat;
- extend legs;
- extend back;
- add armrests.

The chair was **not** fully latent in the original 27-cell arrangement.

The current manuscript correctly says:

> “Parts are selected, translated, stretched and added according to an intention about chairs.”

Promote that.

---

## 5.5 Recursive tree source comments are now usefully precise

The deterministic tree opens with:

> “Growth is prescribed, not biological.”

That aligns well with the manuscript.

Its staged lesson truly sets:

- no randomness;
- fixed turn;
- explicit length ratio;
- whole-generation stepping.

This is a good source identity model.

---

## 5.6 Block-tree seed is source-supported at 12345 in the staged scene

The script export default is 42, but the `.tscn` overrides:

> `random_seed = 12345`.

The Synthesis manuscript’s seed 12345 is therefore supported by the staged scene.

---

## 5.7 Cantor finite/limit arithmetic is source-supported

The lesson explicitly sets:

- initial length 6 m;
- five cuts.

So:

- pieces = `2^n`;
- each piece = `6/3^n`;
- retained length = `6(2/3)^n`.

At n=5 retained length ≈ 0.790 m.

The book’s “less than a metre” is correct.

---

## 5.8 Cantor Pagoda lesson deliberately overrides legacy source dimensions

Base class default is 8 m width.

Lesson wrapper changes it to:

> 9 m.

It also restricts the bodily experiment to cuts 1–3 and depth 1/2/4 m.

The manuscript correctly follows the configured lesson rather than the class defaults.

---

## 5.9 Sierpinski source identity overstates walkability

Old identity says:

> removed triangles become corridors you walk through.

The staged lesson explicitly makes:

- planar visual triangles;
- no collision on the sculpture;
- optional drawing of removed middles.

The manuscript correctly says an opening in an image is not automatically a passage.

Clean the identity.

---

## 5.10 Box-counting identity overstates exactness

As detailed above.

The staged code itself now gives the more responsible `finite-scale fit`.

---

## 5.11 Menger current source includes two major repairs that have no fresh runtime evidence in this bundle

Registry DNA documents:

1. z indexing changed from float-like smeared layers to correct integer 0/1/2 lattice;
2. cube discovery was scoped to the sponge rather than the whole current scene.

These repairs are source-visible and conceptually correct.

But `evidence/` contains no dated capture/check.

Runtime verification should confirm that the current built museum actually contains:

- orthogonal cross passages;
- no collateral subdivision/deletion of neighbouring cube-based artifacts.

---

## 5.12 Menger source identity describes the infinite limit as if it were the displayed object

Old identity:

> “The Menger sponge has infinite surface area and zero volume — it is a solid made entirely of holes.”

The staged hall stops after two cuts.

The manuscript correctly distinguishes:

- 400 one-metre cubes;
- positive 400 m³ retained volume;
- finite collision;

from the infinite mathematical limit.

Keep that distinction.

---

## 5.13 Museum flight provider is missing

The included `museum_flight_box.gd` defines:

- local 12 m flight enclosure;
- desktop WASD / Space / Ctrl velocity;
- neutral hover;
- ground doors.

XR movement is delegated to:

> `museum_flight_provider.gd`

which is not included.

Therefore headset claims about:

- left-controller tilt;
- stick movement;
- exact body/capsule behaviour;

remain runtime/source questions.

---

## 5.14 Fibonacci source identity naturalises additional mappings the current lesson explicitly separates

Old identity:

> golden ratio governs spiral growth, seed packing angle and recursive-tree form.

Actual source contains multiple independent authored functions:

- Fibonacci recurrence;
- logarithmic tower mapping;
- “golden spiral” radius rule;
- seed radius/angle rule;
- pinecone layer/angle rule;
- shell-like chamber rule;
- recursive-tree branching rule.

The lesson wrapper labels these as **ADDED RULES / HELD EXAMPLES**.

The manuscript’s interpretation should become canonical.

---

## 5.15 Fibonacci “golden spiral” source is not the conventional golden spiral

The generated helix uses:

> radius × φ per full turn.

The lesson wrapper explicitly labels that fact.

The manuscript correctly says the conventional golden spiral grows by φ per quarter turn.

Do not let old names reassert equivalence.

---

## 5.16 Golden rectangle quarter-circle arc is not itself a smooth logarithmic golden spiral

The source joins quarter-circle segments within successive squares.

The book correctly calls it a joined curve that resembles a logarithmic spiral while changing curvature at segment boundaries.

Old source identity should be softened.

---

## 5.17 Sequence completion metadata still contains deferred-topic residue

`mandelbrot_master_badge` remains in completion rewards while Mandelbrot and Julia are explicitly deferred outside the current seven-hall museum route.

Low priority, but worth cleaning so the sequence’s completion state reflects what visitors actually encountered.

---

# 6. Runtime questions

No repository code was executed. Every hall still records `learner_verified: false`.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Recursion — nested square** | Can a visitor distinguish the seven finite sizes before the smallest becomes visually negligible? Does LAYOUT make the same seven stored terms legibly sequential? |
| **Recursion — COLLAPSE** | Does collapsing all drawn squares to the smallest term leave the outer frame/readout sufficiently clear to demonstrate count ≠ visible differentiation? |
| **Recursion — circles** | Are counts 1/5/21/85/341 visible/reliable under each packing? At depth 5 + DUST, is the final requested level correctly omitted by the 1 cm source cutoff? |
| **Recursion — cube splits** | After 12 DRILL splits, does the artifact indeed hold 85 cells and report deepest depth 12 in the assembled hall? How many of the deepest cells can a headset user actually distinguish? |
| **Recursion — SPREAD** | After 12 SPREAD splits, does readout reach the expected shallow maximum depth (~3) while count remains 85? |
| **Recursion — chair** | After first stage, are the 16 kept cells and 11 removed GHOST markers visually legible? Do later deformations make it clear that the chair was not merely “uncovered” by deletion? |
| **Recursive Trees — deterministic** | At generation four, do 31 segments read clearly enough to follow one lineage? With FORKS=3, is 121 still perceptually tractable? |
| **Recursive Trees — angle/length** | Can a visitor follow the same first branch while ANGLE/LENGTH rebuild all descendants, or does the whole tree visually reset too strongly to support comparison? |
| **Recursive Trees — support** | Are branches non-colliding/non-climbable exactly as the manuscript says? |
| **Recursive Trees — red block tree** | Do STRATA/REACH/ENDS change only representation of the existing fixed-seed tree rather than regenerate its random geometry? |
| **Cantor — HISTORY** | With history off, does only the latest generation remain visible/colliding while retained length/readout stays unchanged? |
| **Cantor — GHOST** | Are removed middles visibly non-colliding while solid retained bars preserve their collision? |
| **Cantor — Pagoda** | At cuts 1–3 with base width 9 m, are 3 m / 1 m / 1/3 m gaps physically represented as intended? Which are traversable by desktop and XR bodies? |
| **Cantor — DEPTH** | Does changing block depth 1→2→4 m alter passage length without altering opening width or other support geometry? |
| **Koch** | At step four, does readout produce 256 segments and ~12.642 m path from the staged 4 m line? |
| **Koch — TURN/FORM** | Does TURN preserve count/path while visibly reversing detours? Does FORM add the snowflake boundary without confusing the visitor about the starting segment scale? |
| **Sierpinski** | At cut four, do 81 retained triangles total ~4.93 m²? Are 40 removed middles shown in NEGATIVE view? |
| **Sierpinski — collision** | Confirm the sculpture remains non-colliding in all VIEW/DEPTH states so openings are strictly visual. |
| **Box counting** | Record the six actual occupied counts and slopes for coarse/fine/all fits under seed 2026 if exact numerical results are ever promoted into prose. |
| **Box counting — reader timing** | Is the `finite-scale fit` label visible only after RANGE, or does any other tag reveal 1.585 before the visitor compares scales? |
| **Menger — sign timing** | Does `FLY THROUGH THE HOLES` dominate the entrance view before first NEXT? Test the neutral/dynamic sign proposal. |
| **Menger — repair verification** | Confirm the built two-cut sponge now forms the intended orthogonal Menger cross passages after the z-index repair. |
| **Menger — collateral safety** | Confirm no other cube-based artifacts/floor templates are subdivided or freed by the repaired local cube scan. |
| **Menger — count/volume** | Do NEXT states report 1/20/400 solids and 729/540/400 m³ retained volume? |
| **Menger — flight** | In desktop, can the 1.5 m capsule pass the 3 m opening and fail the 1 m opening as described? |
| **Menger — XR flight** | With the missing provider restored for inspection, how do real headset body height and controller-tilt movement interact with the one-metre opening? |
| **Menger — rebuild safety** | While a visitor is inside the flight enclosure, do NEXT/BACK/RESET truly defer rebuilding until everyone has exited? |
| **Golden — Fibonacci mapping** | In log mode, do terms 1..55 remain legible; in linear mode, do the unit-stack tops for 21+34 and 55 align exactly enough to be read bodily? |
| **Golden — held examples** | Are the correction tags (“radius × phi per FULL turn”, etc.) legible enough to prevent natural-example displays from overpowering the mapping lesson? |
| **Golden Rectangle** | At 5 m initial width, do MEASURE values follow approximately 3.090, 1.910, 1.180 m and preserve long/short ≈ φ? |
| **Golden Rectangle — ARC** | Is the piecewise quarter-circle character visible at close range, or does the rendering visually imply one smooth logarithmic spiral? |
| **Synthesis — entrance prompt** | Does `fractal_procedure_gallery` reveal names/procedures before the visitor has attempted the “describe without names” task? |
| **Synthesis — Cantor return** | Do HISTORY/GHOST change only the representation of the already-generated finite state and not the current generation? |
| **Synthesis — tree return** | Does seed 12345 reproduce fixed geometry, and do STRATA/REACH/ENDS leave it unchanged while revealing depth/bounds/endpoints? |

---

# 7. What I would not cut

## Do not cut the non-branching recursive square

It is useful precisely because one self-call can produce a recursive procedure without producing branching complexity.

It also lets the book say:

> this particular procedure could be rewritten as a loop.

That prevents recursion from becoming an aesthetic category.

---

## Do not cut LAYOUT / COLLAPSE

These controls expose how the same stored recursive terms can become:

- nesting;
- succession;
- visually collapsed near-indistinction.

They make representation part of the recursion lesson.

---

## Do not cut PACKING from the circle recursion

Depth and packing answer different questions:

- how many calls?
- how do descendants claim space?

That distinction becomes important again in Menger and the recursive trees.

---

## Do not cut DUST’s missing fifth level

The source’s 1 cm terminal threshold gives a concrete example of:

> requested depth ≠ actually drawn detail.

That is more useful than pretending every allowed depth produces a visible new generation.

---

## Do not cut DRILL / SPREAD

Equal split budgets producing different depth distributions are one of the opening hall’s strongest demonstrations.

They teach:

> computational cost can be spent in different places.

Keep them.

---

## Do not cut the chair anti-example

The chair is essential because it breaks visual classification:

> subdivision-like geometry and a “recursive” filename do not prove recursion.

Its authored deformations also expose design intention.

---

## Do not cut ANGLE / LENGTH / FORKS from the tree

These three controls separate:

- edge orientation;
- inherited scale;
- branching graph.

That is the hall’s conceptual core.

---

## Do not cut the deterministic tree’s lack of randomness

It gives the stochastic red tree something precise to differ from.

A procedural tree does not need noise to be a recursive tree.

---

## Do not cut HISTORY from Cantor

Without it, the display can look as though every previous row belongs to the current Cantor set.

The control makes explanatory history itself visible as a representation.

---

## Do not cut GHOST from Cantor or Menger

Removed material becomes a visible record without becoming support.

That distinction is one of the sequence’s strongest threads.

---

## Do not cut the Cantor finite/limit paragraph

It is exactly the kind of distinction the book needs repeatedly:

> mathematical continuation ≠ finite artifact.

Keep the zero-length / uncountable limit explicitly separate from the finite bars.

---

## Do not cut TURN from Koch

Same count and same path length surviving a reversal shows immediately that those measurements do not exhaust geometry.

---

## Do not cut Sierpinski NEGATIVE view

The ability to make removed middles the visible subject is more than a visual novelty.

It asks which output of a procedure the renderer treats as the work.

---

## Do not cut RANGE from box counting

The moving fitted slope is the reason the measurement instrument belongs in the sequence.

A single displayed 1.585 would teach much less.

---

## Do not remove finite sample limitations from box counting

The ideal reference value and finite estimate should coexist.

The difference is the lesson.

---

## Do not cut Menger flight as spectacle

Flight is not there merely because the sponge is large.

It creates a controlled intervention:

> change the visitor’s locomotion while leaving the removal rule fixed.

That lets connectivity and traversability separate bodily.

---

## Do not call every geometric opening a route

The manuscript’s one-metre Menger opening is important because it is visibly connected and still inaccessible to one implemented body.

Keep that failure.

---

## Do not cut Fibonacci from a fractals sequence because it is not a recursive self-call in this implementation

The chapter is deliberately contrasting:

- recursive procedure;
- numerical recurrence;
- mapping.

That distinction belongs here.

---

## Do not cut the “wrong golden spiral” correction

It is one of the best demonstrations in the whole sequence that:

> a persuasive canonical name does not make the implemented construction identical to the mathematical object.

Keep it.

---

## Do not cut the golden rectangle ARC caveat

Quarter-circle arcs through squares are a useful construction.

They do not need to become a true logarithmic spiral to be worth following.

---

## Do not cut Synthesis’s repeated Cantor/tree controls as recap

Their function has changed.

Earlier they taught the artifacts.

Here they help the visitor **state a procedure explicitly**.

That is preparation for grammar.

---

# 8. Reader-experience strengths to protect

## Discovery before naming

**Recursion**  
MORE before RULE; chair appearance before “no self-call.”

**Trees**  
predict fork before inherited vector/length code.

**Cantor**  
find the missing middle before formula.

**Koch**  
walk the detour before path-length multiplication.

**Sierpinski**  
find the new opening before midpoint code.

**Menger**  
find the first through-opening before cube count—once the flight sign is fixed.

**Golden**  
notice suspicious tower heights before the mapping equation.

**Synthesis**  
describe the procedure before relying on canonical names.

---

## Prediction before explanation

- How many circles after one more branch?
- Where will the next tree fork go?
- How many pieces and how much length after the next Cantor cut?
- Where can more line go without moving Koch endpoints?
- Which part of the Sierpinski triangle disappears next?
- Which Menger opening can this body actually use?
- What number follows 1,1?
- What information must the next recursive call receive?

These are strong and should remain the sequence’s rhythm.

---

## Productive distinctions to protect

- recursive appearance ≠ recursive procedure
- recursion ≠ branching
- requested depth ≠ visible/drawn depth
- object count ≠ perceptual differentiation
- equal computational budget ≠ equal depth distribution
- subdivision ≠ “form latent inside the parent”
- changing branch angle/length ≠ changing branch count
- deterministic recursion ≠ stochastic recursion
- current generation ≠ displayed history
- removed region visible as ghost ≠ restored support
- more pieces ≠ more retained material
- endpoint distance ≠ path length
- retained area ≠ number of pieces
- ideal dimension ≠ finite fitted estimate
- geometrical connection ≠ route for a particular body
- locomotion change ≠ geometry change
- numerical recurrence ≠ geometric mapping
- familiar natural resemblance ≠ source rule
- proportional self-similarity ≠ recursive program
- recipe name ≠ sufficient reconstruction of procedure.

This list is the real Fractals curriculum.

---

# 9. Questions for the author

## 9.1 Do you want the Menger flight sign to announce the goal immediately?

The manuscript strongly benefits from:

> solid cube → first opening → bodily flight.

I would delay the word **holes**.

If the sign is primarily accessibility/navigation, keep the control instructions but neutralise the conceptual title until NEXT.

---

## 9.2 Should “GoldenSpiral” remain the public hall name?

The current chapter is actually excellent because it dismantles that simplification.

If the familiar title is useful as bait/recognition, keep it.

But the visitor-facing subtitle **A number needs a mapping** should remain dominant, and metadata should stop promising a generic phyllotaxis/nature lesson.

---

## 9.3 Is box-counting intended as an estimate exercise or a canonical dimension demonstration?

The current artifact says estimate.

I strongly prefer that.

If you ever want the ideal `log(3)/log(2)` derivation to be a separate proof, give it another artifact rather than letting the finite regression silently stand in for it.

---

## 9.4 Do you want the tiny DRILL lineage to become an explicit perceptual-limit experiment?

The source can keep subdividing through the twelve-split budget.

If headset users can no longer distinguish the deepest cells, that is not necessarily a failure.

It could become a very strong line:

> **the recursion continued after the room stopped giving your eye a new object.**

I would test before adding more UI.

---

## 9.5 Is the Fractal Synthesis entrance gallery intended to help or withhold canonical names?

Because the chapter asks:

> “Can you explain two recursive constructions without using their names?”

the entrance prompt should support procedural recall rather than answer it.

Verify its actual signage before finalising this chapter.

---

# 10. Overall conclusion

Fractals is one of the cleaner sequence bundles so far.

Its route is already coherent and the current manuscript has largely escaped the standard fractal-tour problem:

> show famous objects, state their dimensions, invoke nature, call everything self-similar.

Instead, the sequence increasingly asks:

> **what is repeated, where is the continuation stored, what changes between calls, what gets removed, what stops the process, and what does the chosen representation or body make available?**

That is the stronger curriculum.

The most successful moments are the ones where a familiar visual category fails:

- a nested square is recursive but could also be written as a loop;
- a “recursive chair” is not recursive;
- the same split budget makes a deep drill or shallow spread;
- a tree-looking object can be fully deterministic;
- more Cantor pieces contain less retained length;
- the explanatory history is not the current Cantor state;
- Koch path grows while endpoints remain;
- removed Sierpinski middles become the visible subject;
- a finite box-counting slope changes with the fitted scale range;
- Menger geometry contains an opening one body still cannot use;
- Fibonacci numbers do not contain a flower;
- a “golden spiral” label can describe the wrong growth rate;
- a recursive-looking pattern and an explicit recursive call are not interchangeable.

Those are excellent Ada moments.

The highest-value work now is therefore:

1. **delay Menger’s “FLY THROUGH THE HOLES” sign so the first hole can actually be discovered;**
2. **clean residual sequence/map/source metadata that re-naturalises golden-ratio imagery or presents infinite fractal properties as if the finite artifacts contained them;**
3. **repair the stale cube-subdivision registry DNA that contradicts the current executor and can mislead source-aware review;**
4. **make the box-counting source identity match the staged finite-scale measurement instrument;**
5. **attach/runtime-test the embodied claims—especially deep subdivision visibility, Cantor gap passage, Menger flight/body dimensions and the synthesis entrance prompt.**

The reader-experience principle I would carry forward from Fractals is:

> **Let the visitor recognise a repeated form, then make them discover whether the repetition lives in the code, the geometry, the record, or only in their reading.**

And the structural principle is:

> **“Again” is incomplete. A recursive or recurrent construction must still say what is passed on, where descendants are placed, what is removed, and what finally makes the process stop.**
