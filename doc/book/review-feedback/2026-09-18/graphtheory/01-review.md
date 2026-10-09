# Graph Theory — 01 Review

Source-aware editorial and reader-experience review of the **Graph Theory** sequence.

Basis: `graphtheory-book.md`, `graphtheory-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, scene configuration, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where a learner can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. Graph Theory especially benefits from keeping distinct:

- graph structure;
- drawing/layout;
- traversal order;
- route availability;
- named network measure;
- optimisation criterion;
- capacity;
- matching feasibility;
- and bodily access.

The strongest current **book** arc is:

> **same graph / different traversal → same graph / different drawing → changed graph / changed route → visual importance versus measured relation → directed mutual reachability → cheapest spanning connection → throughput under capacity → locally valid versus globally maximum pairing**

A second formulation is:

> **A graph makes some relations explicit and leaves others out. Algorithms then act on those represented relations under different objectives: visit order, reachability, total connection cost, capacity or pairing. A procedure can satisfy its local rule without establishing the stronger conclusion named by its title.**

That is an excellent preparation for Foundations Crisis.

The inherited sequence truth:

> “Everything is a graph if you squint hard enough.”

is weaker than the current manuscripts, which repeatedly insist that **what was not represented cannot be recovered by the algorithm simply because the graph is useful.**

---

# 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **GT Foundations** | **Carries:** one fixed 15-node tree is traversed breadth-first and depth-first, cleanly separating adjacency from visit order and queue from stack. The visitor can keep one waiting branch in mind and see that pending-work memory, not graph geometry, creates the two rhythms. **Gap:** the artifact’s entrance plaque immediately explains “BFS level by level / DFS branch and backtrack,” pre-answering the manuscript’s discovery; the primary is also at `(10,9)` after several older graph artifacts while the book begins with it. Sequence metadata still calls this the Königsberg foundations chapter although the current primary lesson is traversal. **Next:** delay BFS/DFS naming until after one cycle and verify/restage the primary toward the entrance; update metadata rather than re-expanding the book around old Königsberg material. |
| **GT Layout** | **Carries:** a strong representation lesson: adjacency remains while force-directed coordinates move; connected vertices can become farther apart and unconnected vertices visually close. The source genuinely runs Hooke-like edge attraction, all-pairs repulsion, damping and integration. **Gap:** source identity says equilibrium “reveals graph structure” and implies local-energy minimisation as if the drawing were authoritative; the manuscript is more careful. The room currently offers only one moving layout of one graph, despite the source already supporting cube/ring/star/clique/bipartite graph families rather than multiple layouts of the same graph. **Next:** preserve prose; eventually add a SAME GRAPH / NEW START comparison before adding more centrality interpretation. |
| **GT Pathfinding** | **Carries:** sinking a stone disables a graph vertex and forces AStar3D to recompute a route through the remaining connections; after three sinkings the oldest stone returns, so route change can come from loss or restored availability. The book correctly distinguishes graph route from bodily crossing. **Gap:** pressing the sink button immediately calls `_replan()`, which resets the spark to its bank-side route start even if it was mid-crossing; the source identity says the spark asks again “at every bank,” but the button creates a discontinuous jump. The primary is also late at `(10,9)` after several secondary path works. **Next:** either replan from the spark’s current graph location / delay the new plan until the next bank, or make the restart explicit; verify/restage primary encounter order. |
| **GT Network Analysis** | **Carries:** the manuscript already performs an important audit: large/high/glowing is not evidence of graph centrality, and the displayed hierarchy/readouts are not all computed from edges. **Gap:** the source confirms the critique more strongly than the room admits. “Centrality” values are assigned from tier/random ranges, node size/colour/orbit are authored from those values, while `clustering_coefficient` and `connectivity_index` are animated formulas over time—not measurements of the displayed graph. The hall therefore contains almost no actual network analysis despite its title. **Next:** compute at least DEGREE plus one disagreeing named measure (e.g. betweenness or closeness) from the current edge set and let the visitor switch which one drives size/colour. |
| **GT Connectivity** | **Carries:** a genuine Tarjan SCC implementation. Discovery numbers, low links, unresolved stack membership, back edges and component pops are source-supported; the manuscript correctly makes “a way there” different from “a way back” and keeps strong connectivity distinct from cost/capacity/accessibility. **Gap:** little technical or literary mismatch. Two secondary algorithms sit beside the primary in the same front row, so a visitor may not know which traversal the manuscript is describing. **Next:** preserve; clarify physical primacy/signage and runtime-test whether arrow direction, low-link values and component pop are readable in headset. |
| **GT Spanning Trees** | **Carries:** a real Kruskal implementation with Union-Find and weighted edges. Accepted edges join components; rejected edges would close cycles; the resulting tree minimises total edge weight on the generated connected weighted graph. The manuscript then correctly asks what cheap connection sacrifices in route length and failure redundancy. **Gap:** this fully authored/source-backed hall is absent from museum map-authored order. Source identity says Kruskal and Prim give “same result”; they guarantee the same minimum total weight but not necessarily the identical edge set when ties exist. **Next:** restore the hall; keep Kruskal as primary and optionally use the existing `backbone:bare/refused/forest` views as later comparative readings, not as substitutes for the live construction. |
| **GT Flow** | **Carries:** the manuscript is unusually responsible about an incomplete algorithm. The source really visualises preflow, excess, height labels, forward residual capacity, push and relabel; it makes local congestion legible. The text explicitly says a complete maximum-flow method must be able to revise earlier allocations. **Gap:** the artifact still calls itself **Push-Relabel Algorithm: Maximum Flow** and on termination prints **“Max flow”**, but it never constructs reverse residual arcs. It can therefore neither implement classical push-relabel nor justify a general maximum-flow result, and some excess configurations can become stuck. **Next:** either implement reverse residual capacity and a case requiring revision, or immediately relabel the current artifact/readout as a **forward-only push/relabel study** whose sink excess is not certified maximum. |
| **GT Matching** | **Carries:** the manuscript catches the crucial distinction between valid, maximal and maximum matching and gives the exact kind of counterexample the hall needs. The source itself openly admits it is a greedy edge scan rather than Edmonds’ blossom algorithm. Better still, the implemented `coupling:blossom` graph is specifically designed so greedy cycle-edge choices strand four leaves while a perfect matching exists. **Gap:** this hall is absent from museum-authored order; the map uses the default random `partial` graph rather than the guaranteed blossom counterexample; and the artifact still prints “Finding maximum matching…” / “Maximum matching found.” **Next:** restore the hall with `coupling:blossom` as the lesson baseline (or expose COUPLING), and rename the current run **GREEDY MATCHING** until augmenting/blossom revision is actually implemented. |

---

# 2. The largest structural issue: the eight-hall book is currently a six-hall museum route

## Declared/current book order

1. GT Foundations  
2. GT Layout  
3. GT Pathfinding  
4. GT Network Analysis  
5. GT Connectivity  
6. **GT Spanning Trees**  
7. GT Flow  
8. **GT Matching**

## Museum-authored order

1. GT Foundations  
2. GT Layout  
3. GT Pathfinding  
4. GT Network Analysis  
5. GT Connectivity  
6. GT Flow

Missing:

- **GT Spanning Trees**
- **GT Matching**

This is not a neutral shortening.

It removes both sides of a very strong optimisation argument.

## Missing distinction 1 — minimum total connection versus redundancy

Connectivity ends:

> one return edge can merge strongly connected components.

Spanning Trees then changes the objective:

> which edges can be rejected while everyone stays connected, minimising total edge weight?

That hall gives the sequence a critical new tension:

> a cycle can look redundant under construction cost and essential under failure resilience.

Without the hall, the transition from SCC directly to Flow loses this argument about objective-dependent redundancy.

## Missing distinction 2 — locally legal pair versus globally best collection

Flow ends by preparing:

> an early allocation may need revision.

Matching makes the same issue more elementary.

A greedy pair can be locally valid and still prevent a larger matching.

That is one of the cleanest possible handoffs to Foundations Crisis:

> **meeting the local rule is not proof of the strongest theorem named by the artifact.**

Removing Matching weakens the sequence ending substantially.

## Recommendation

If the eight-hall manuscripts represent the current curriculum:

1. restore GT Spanning Trees between Connectivity and Flow;
2. restore GT Matching after Flow;
3. verify `next_in_sequence` through current museum assembly;
4. then update sequence completion/transition into Foundations Crisis.

Do not rewrite the book to fit the six-hall route.

---

# 3. Sequence structure

## 1. Foundations — same structure, different itinerary

The sequence begins with a highly useful distinction:

> **graph adjacency does not contain visit order.**

The same tree supports:

- BFS;
- DFS.

The only changed thing is the procedure’s pending-work memory:

- queue;
- stack.

That is exactly the right starting point because it teaches that:

> graph + algorithm = another experience of the same relation set.

## 2. Layout — same graph, changed coordinates

The next room takes the drawing itself away from graph identity.

Force-directed physics produces coordinates.

It does not create edges.

This gives the sequence a second separation:

> **adjacency ≠ display geometry.**

That becomes crucial before pathfinding and centrality.

## 3. Pathfinding — now the graph itself changes

The first two rooms held graph structure fixed.

Pathfinding removes/re-enables vertices.

Now the available route genuinely changes.

The distinction becomes:

> moving a drawing is not graph change; disabling a stone is.

Excellent.

## 4. Network Analysis — a visual ranking is another representation claim

The hall then asks:

> does a large/central-looking node deserve to be called important?

The current answer is mostly:

> no conclusion yet, because the display is authored rather than analytically derived.

That is an important critical step—but it needs one genuine measure to become an experiment rather than only an audit.

## 5. Connectivity — exact directed reachability

Tarjan then gives one sharply defined global relation:

> maximal mutual reachability.

This is a strong correction after the ambiguous word “important.”

A one-way edge can make the drawing look joined without making a return possible.

Good.

## 6. Spanning Trees — connection under a cost objective

Now the graph becomes weighted.

Kruskal asks:

> what is the cheapest edge set that keeps all vertices connected?

The algorithm discards cycles under one objective.

The manuscript immediately asks what that sacrifice means for:

- individual route length;
- resilience.

Excellent.

## 7. Flow — connectivity gains capacities and revisability

A route can exist but lack throughput.

Flow introduces:

- capacity;
- flow;
- vertex excess;
- height;
- revision via residual network as the missing general capability.

The current incomplete implementation is actually valuable **if it is named as incomplete**.

## 8. Matching — exclusivity and revision

The final hall shifts from movement through edges to selecting edges themselves.

Each endpoint can belong to one selected pair.

A greedy local rule can create a maximal result without producing a maximum result.

That is precisely the distinction the sequence should hand to Foundations Crisis.

---

# 4. Reader-experience lens

## GT Foundations — Two travellers, one graph

### Curiosity

The manuscript’s first question is strong:

> same connections, different order?

The visitor is asked to pick one lamp and make a timing prediction.

That is exactly the right scale.

### Discovery

The source computes both orders honestly from one child adjacency:

**BFS**
```text
queue.pop_front()
append children
```

**DFS**
```text
stack.pop_back()
push children in reverse order
```

The same 15 lamps are used for both.

Good.

The strongest reader moment is the unfinished side branch:

> it has not disappeared; it moved inside the traversal’s pending memory.

That gives queue/stack meaning beyond textbook vocabulary.

### Timing problem

The artifact plaque immediately says:

> “the tide floods level by level (BFS), the diver follows one branch to its leaf and backtracks (DFS).”

The readout also names:

> THE TIDE — BFS  
> THE DIVER — DFS.

So the visitor does not really get to infer the two rhythms before the terms arrive.

### Artifact proposal

Initial plaque:

> **TWO TRAVELERS**  
> same fifteen lamps / two visit orders

Readout:

> **THE TIDE**  
> **THE DIVER**

After one complete alternation—or a small **NAMES** reveal—add:

> BFS / queue  
> DFS / stack.

This is a small reader-experience improvement.

### Spatial issue

The primary is at `(10,9)`.

Before it the room contains:

- synthesis stand;
- graphspace;
- graphspace3d;
- Königsberg bridge.

The current book begins with the traveller.

A first-time visitor may encounter the legacy graph-introduction material first.

That is not automatically wrong, but it means the manuscript and embodied order may differ.

**RUNTIME / SPACE:** test. If necessary, move `two_travelers` forward or make a clear path to it.

### Metadata

`sequence.json.content` still says:

> GT Foundations: Königsberg Bridges and Euler — what IS a graph?

The current final chapter is traversal.

Either:

- update metadata to current primary; or
- make Königsberg a deliberate prelude in the final text.

Do not let metadata imply a chapter that the manuscript no longer teaches.

### Return

Array’s queue/order questions return as graph traversal.

---

## GT Layout — A connection is not a coordinate

### Curiosity

The opening is extremely clear:

> if the drawing moves, did the graph change?

That is exactly the question this artifact can answer.

### Source support

The source genuinely runs:

- connected-edge Hooke-like spring attraction;
- all-pairs inverse-square repulsion;
- velocity integration;
- damping;
- bounds.

Default graph is the cube graph Q3.

The graph can also be configured as:

- ring;
- star;
- clique;
- bipartite.

### Discovery

The manuscript’s instruction:

> identify an edge without saying left/right/above

is excellent.

It makes the visitor use adjacency as identity rather than screen position.

The “unconnected nodes can pass close together” counterexample is also strong.

### Source rhetoric

The identity says:

> “equilibrium … reveals graph structure.”

The manuscript is more careful:

> layout may make adjacency easier to inspect and may also invite unsupported stories.

Keep the manuscript.

A force-directed layout is an authored energy metaphor with:

- spring length;
- force constants;
- repulsion;
- damping;
- initial conditions.

It is not a neutral graph reading.

### Future experiment

The manuscript proposes several layouts of the same graph.

That is the right next artifact.

The current source’s Stage-2 axis varies **graph structure**, not initial layout of one graph.

A useful addition would be:

> **NEW START**

using another pinned initial seed while holding the cube graph fixed.

Then the visitor can see:

> same graph / same force law / another settled drawing.

This supports the current chapter better than adding more graph families.

### Return

Forces returns as a layout tool rather than physical world law.

---

## GT Pathfinding — The route after a stone disappears

### Curiosity

This is a good embodied graph chapter.

The visitor predicts the next connection.

Then one route stone sinks.

This is graph change, not merely display change.

### Source support

The river source uses:

> `AStar3D`.

Stones within `link_r = 1.05` are connected.

Bank nodes connect to nearest stones.

The current route comes from:

> `get_point_path()`.

Sinking:

- disables the selected graph point;
- visually lowers/darkens the stone.

After more than three sunk stones:

- oldest returns;
- graph point is re-enabled.

Good.

### Important implementation seam

When the button is pressed:

```gdscript
_on_sink()
...
_replan()
```

`_replan()` computes from whichever bank is currently the journey’s origin and resets:

- `_leg = 0`;
- `_t = 0`;
- spark position = route[0].

Thus pressing the button mid-crossing **teleports/restarts the spark at the bank**.

The source identity says:

> “next crossing, the spark has already learned a new river.”

The actual button replan happens immediately.

### Preferred artifact fix

Either:

**A. Replan from current route position**
- map spark to nearest enabled point;
- run AStar from there to destination bank.

or:

**B. Queue the graph change**
- sink stone now;
- let current traversal finish if still valid;
- replan at next bank.

Option A is conceptually strongest:

> a traveller revises from where it is, not from an erased history.

### Reader timing

Good otherwise.

The book correctly separates:

> graph route  
> from  
> bodily jump/clearance.

### Spatial order

Primary `impatient_river` is at z9 after five other path/graph artifacts.

Again, test whether legacy content pre-empts the focused primary.

---

## GT Network Analysis — Important by which measure?

### Curiosity

The opening question is excellent.

The visitor begins with a large conspicuous node and checks actual incident edges.

That is a good small piece of evidence.

### Source truth

The source validates the manuscript’s skepticism.

In the default `pockets` graph:

- five “central” nodes are given centrality in roughly 0.85–1.0;
- eight “cluster” nodes roughly 0.5–0.7;
- twelve “peripheral” nodes roughly 0–0.3.

Those centrality numbers are assigned during construction.

They are **not calculated from the resulting edge set**.

Then node size, glow, orbit and animation depend on those values.

So the display visually confirms its own authored hierarchy.

### Summary measures are also theatrical

Every frame:

```gdscript
clustering_coefficient =
    0.3 + analysis_progress * 0.5 + sin(...) * 0.1

connectivity_index =
    0.4 + analysis_progress * 0.4 + cos(...) * 0.1
```

These values are not computed from edges.

The chapter’s statement:

> readouts cannot certify the hierarchy through graph analysis

is exactly right.

### High-value artifact improvement

Make the room actually answer its title.

At minimum compute:

**DEGREE**
```text
number of incident edges
```

Then add one genuinely different measure:

**BETWEENNESS**
or
**CLOSENESS**.

Provide a control:

> **MEASURE — degree / betweenness / closeness**

Use the selected computed value to:

- resize nodes;
- recolour;
- perhaps label top 3.

Keep the authored current visual hierarchy as:

> **DIAGRAM**

for comparison.

Then the visitor can discover:

> the visually central node, highest-degree node and bridge/betweenness node need not be the same.

This is a major artifact-first improvement.

### Stage-2 mutuality axis

The source also has:

- pockets;
- none/tree;
- split;
- total/complete graph.

That can later become a second experiment.

But first, compute one real metric.

### Return

Layout’s warning about presentation becomes a quantitative audit.

---

## GT Connectivity — A way back

### Curiosity

The opening is exactly right:

> reachability one way does not guarantee return.

The visitor can trace arrows before the SCC explanation.

### Source support

This is a genuine non-blocking Tarjan implementation.

It uses:

- `discovery_time`;
- `low_link`;
- unresolved stack;
- on-stack flag;
- DFS frames.

On a back edge:

```gdscript
low_link[v] =
    min(low_link[v], discovery_time[w])
```

At a root:

```gdscript
low_link[v] == discovery_time[v]
```

it pops a component from the stack.

This is source-aligned with the manuscript.

### Reader timing

Good.

The visible moment when several vertices receive one component colour is the right event to focus on.

The stack now carries:

> unresolved reachability information.

That is a meaningful return to Foundations.

### Spatial/curriculum issue

At the same front row sit:

- topological sort;
- Tarjan;
- Kosaraju.

The manuscript only discusses Tarjan.

A visitor may naturally compare algorithms before learning the one being explained.

Possible fix:

- strongest lighting/signage on Tarjan;
- place Kosaraju/Topological Sort later or behind it.

This is a curation question, not a text defect.

### Return

DFS from Foundations returns with a new job.

---

## GT Spanning Trees — The price of one more route

### Curiosity

This hall has an excellent question:

> which edge can be removed without separating anyone?

That is immediately inspectable.

### Source support

The current source genuinely implements Kruskal:

1. sort edges by weight;
2. find Union-Find roots;
3. accept if roots differ;
4. union components;
5. reject if edge would close a cycle.

The manuscript’s account is technically aligned.

### Minimum claim

For the generated connected weighted graph, Kruskal produces an MST.

The manuscript correctly limits “minimum” to:

> total selected edge weight.

It explicitly rejects the inference:

> every individual trip is shortest.

Excellent.

### Source nuance

Identity says Kruskal and Prim:

> “same result, different experience.”

Both produce an MST / same minimum total weight.

They need not return the exact same edge set when equal-weight alternatives exist.

Use:

> **same optimisation criterion / possibly different minimum tree**

rather than identical result if this becomes visitor-facing.

### Existing source axis

The artifact already supports:

- picked;
- bare;
- refused;
- forest.

`bare` and `refused` are especially strong representations of one solved run.

But the map currently uses the default live `picked` version.

That is correct for the first visit.

Do not replace the live algorithm with the still answer.

### Route problem

This complete, source-backed hall is missing from museum order.

Restore it.

### Return

Connectivity’s useful cycle becomes redundant under another objective.

This is one of the sequence’s best conceptual pivots.

---

## GT Flow — What a junction cannot pass on

### Curiosity

The chapter’s local scale is very good.

The visitor watches:

- excess at one node;
- residual room on outgoing edges;
- PUSH versus RELABEL.

That is understandable without solving max-flow globally.

### Source support

The source has:

- capacities;
- current flow matrix;
- source preflow;
- height labels;
- excess;
- active nodes;
- local push;
- local relabel.

Those are real.

### Fundamental algorithm gap

The source itself admits:

> it only pushes along **forward edges**.

It never builds reverse residual arcs.

Classical push-relabel needs the residual network, including reverse capacity equal to current forward flow.

Without it, the algorithm cannot always undo earlier flow decisions.

The manuscript correctly explains that.

### Artifact overclaim

Despite this, the source still labels itself:

> **Push-Relabel Algorithm: Maximum Flow**

and on termination:

> **Algorithm completed! Max flow: ...**

That is not justified.

A local run can produce some sink excess.

It does not generally prove that value maximum.

### Potential liveness problem

If an active node has excess but:

- no forward residual edge;
- no relabel candidate,

the live loop does not remove it.

The offline relief solver has explicit guards for this condition.

The live algorithm does not.

A generated graph may avoid the failure in common runs, but the general implementation is incomplete in two senses:

- optimality;
- potential termination.

### Preferred artifact fix

Long-term:

> implement proper residual reverse edges and a test case that **requires** rerouting.

Then the visitor can see:

- forward push;
- reverse correction;
- revised allocation.

Short-term, immediately fix the identity/display:

> **FORWARD-ONLY PUSH / RELABEL STUDY**

and:

> **sink flow observed: N**

not “Max flow”.

### Why this hall should remain

The incomplete version is not worthless.

It is an excellent Foundations-Crisis preparation if the title tells the truth:

> local legal updates are not enough to establish the theorem you wanted.

Keep that.

---

## GT Matching — A pair that blocks two pairs

### Curiosity

This is an ideal final graph-theory question.

Every selected pair can be individually valid.

The collection can still be suboptimal.

That is an accessible form of local/global distinction.

### Source truth

The file is named:

> `edmonds_algorithm.gd`

but comments explicitly say:

> simplified greedy version.

The run scans edges in order.

If both endpoints are unmatched:

> accept.

Otherwise:

> reject and never revisit.

No:

- augmenting path;
- blossom contraction;
- revision.

The manuscript is exactly right.

### Artifact overclaim

The visible status says:

> “Finding maximum matching…”

and at completion:

> “Complete! Maximum matching found.”

That is false for the current procedure.

Change immediately to:

> **GREEDY MATCHING**

and:

> **Greedy matching complete — size N**

### The source already contains the perfect counterexample

Stage-2 axis:

> `coupling`

has:

- partial;
- perfect;
- stranded;
- blossom.

`blossom` constructs:

- an odd inner cycle;
- one pendant leaf per cycle vertex.

Cycle edges are listed first.

The greedy algorithm consumes cycle pairs.

That strands leaves.

But a perfect matching exists:

> each leaf paired with its cycle vertex.

This is exactly the chapter’s concept.

### The map does not use it

Current token:

> `edmonds_algorithm:0:0:0.6`

so default:

> `coupling = partial`.

The strongest lesson is already implemented but hidden.

### Artifact proposal

Restore the hall with:

> `#coupling:blossom`

as the lesson baseline.

Or add:

> **GRAPH — partial / perfect / stranded / blossom**

and make BLOSSOM the final/reveal case.

No need to implement full Edmonds before publication if the artifact is honestly named greedy.

The failure itself prepares the next sequence.

### Return

Flow’s missing revision becomes Matching’s missing augmenting path.

This is the best possible handoff to Foundations Crisis.

---

# 5. Five high-value changes

## 5.1 Restore GT Spanning Trees and GT Matching to the museum-authored route

**Evidence type:** ROUTE / CURATION

Declared:

> Foundations → Layout → Pathfinding → Network Analysis → Connectivity → **Spanning Trees** → Flow → **Matching**

Museum-authored:

> Foundations → Layout → Pathfinding → Network Analysis → Connectivity → Flow

### Proposal

Restore:

1. `GT_Spanning_Trees`
2. `GT_Matching`

and verify all eight `next_in_sequence` transitions.

### Reason

Spanning Trees introduces:

> objective-dependent redundancy.

Matching introduces:

> locally valid ≠ globally maximum.

Those are not optional subtopics.

Together they make the final transition to Foundations Crisis much stronger.

---

## 5.2 Network Analysis — implement one real computed measure and let two measures disagree

**Hall:** `GT_Network_Analysis`  
**Artifact:** `network_analysis`

### Original manuscript

> “Its centrality values are assigned from ranges, and some summary measures follow an animation over time. They are not all calculated from the displayed edges.”

This is accurate, but the room currently ends there.

### SOURCE

Default node “centrality” is assigned while nodes are built.

Examples:

```gdscript
centrality = 0.85 + rand * 0.15
centrality = 0.5 + rand * 0.2
centrality = rand * 0.3
```

Animated “metrics”:

```gdscript
clustering_coefficient =
    0.3 + progress * 0.5 + sin(...) * 0.1

connectivity_index =
    0.4 + progress * 0.4 + cos(...) * 0.1
```

Neither comes from current edge analysis.

### Artifact proposal

Add real:

> **MEASURE**

with at least:

1. DEGREE
2. BETWEENNESS

or DEGREE / CLOSENESS if simpler.

For each mode:

- compute value from actual current edge set;
- show numeric value on selected vertex;
- optionally map node size/colour to that computed measure.

Keep the old tiered breathing picture as:

> **DIAGRAM**

or **AUTHORED HIERARCHY**.

Then explicitly compare:

> large in the diagram  
> versus  
> high under degree  
> versus  
> high under betweenness.

### Reason

The chapter’s title is a question:

> Important by which measure?

It deserves at least two actual answers.

This is better than adding prose about what betweenness *would* mean.

---

## 5.3 Flow — stop claiming maximum flow until reverse residual capacity exists

**Hall:** `GT_Flow`  
**Artifact:** `push_relabel_algorithm`

### Current manuscript

Already accurate:

> “A complete maximum-flow method also needs a way to revise earlier allocations… This exhibit does not yet implement those reverse adjustments.”

### SOURCE contradiction

Artifact labels:

> `Push-Relabel Algorithm: Maximum Flow`

Completion:

> `Algorithm completed! Max flow: N`

Implementation only checks:

```gdscript
edge.capacity - forward_flow
```

on original forward edges.

No reverse residual arc is created from current flow.

### Immediate proposal

Rename current mode:

> **PUSH / RELABEL — FORWARD RESIDUAL STUDY**

and completion:

> **current sink flow: N**

Add a visible limitation:

> **NO REVERSE RESIDUAL CAPACITY**

### Stronger artifact proposal

Add a small fixed graph where:

1. an early forward push takes a locally available path;
2. reaching the true maximum requires pushing some flow back through a reverse residual edge;
3. the current algorithm stalls/underachieves;
4. a repaired RESIDUAL mode reaches the larger result.

Controls:

> **FORWARD ONLY / RESIDUAL**

### Reason

The manuscript has already identified the exact missing power.

Make that difference executable.

---

## 5.4 Matching — use the source’s `blossom` graph and stop calling greedy output “maximum”

**Hall:** `GT_Matching`  
**Artifact:** `edmonds_algorithm`

### Current source

The algorithm is:

```gdscript
for edge in edges:
    if both endpoints unmatched:
        accept
```

No accepted edge is ever removed.

Yet the display says:

> Finding maximum matching  
> Maximum matching found.

### Existing source asset

The implemented `coupling:blossom` case intentionally creates:

- odd cycle first;
- one pendant leaf per cycle vertex;
- greedy edge order that strands four leaves;
- a perfect matching that exists but requires different/revised choices.

### Proposal

Restore the hall configured as:

> `#coupling:blossom`

or add a COUPLING control.

Rename:

> **GREEDY MATCHING**

and:

> **Greedy matching complete — N pairs**

Add a simple comparator plate:

> **another matching can make 5 pairs**

only after the greedy run has completed.

If full Edmonds/blossom augmentation is implemented later:

> add it as REVISE / AUGMENT and let the visitor watch the matching grow.

### Reason

The source already contains the exact counterexample the manuscript currently asks the reader to imagine with A–B–C–D.

Use it.

This is one of the highest-return artifact fixes in the sequence.

---

## 5.5 Foundations — delay the BFS/DFS answer and align the physical opening with the manuscript

**Hall:** `GT_Foundations`  
**Artifact:** `two_travelers`

### Current manuscript

> choose a lamp; predict whether it will be reached early or late; watch one traversal, then the other.

### Current artifact

The startup plaque already says:

> tide = BFS, level by level  
> diver = DFS, branch then backtrack.

The map also places the primary at `(10,9)` after several older graph artifacts.

### Artifact proposal

Start with:

> **THE TIDE**  
> **THE DIVER**

and only:

> same fifteen lamps / two visit orders.

After one full pair of traversals, reveal:

> **BFS — queue**  
> **DFS — stack**.

### Spatial proposal

Walk the room.

If visitors naturally encounter:

- graphspace;
- graphspace3d;
- Königsberg;

before `two_travelers`, decide intentionally whether those are a prelude.

If not, move/signpost the primary forward.

### Metadata proposal

Update the sequence content line from:

> “Königsberg Bridges and Euler — what IS a graph?”

to something matching the current chapter:

> **One graph, two traversals — adjacency, queue and stack**

unless Königsberg is restored to the manuscript as a deliberate preface.

### Reason

The text already has discovery-first timing.

The artifact and metadata are ahead/behind it.

---

# 6. Source / artifact discrepancies

## 6.1 Foundations primary lesson is traversal, while sequence metadata still describes Königsberg

The current final manuscript does not teach Eulerian traversal.

The map contains older Königsberg/graphspace works as secondaries.

Update metadata or explicitly integrate them.

---

## 6.2 TwoTravelers reveals BFS/DFS terminology before the manuscript’s prediction

As above.

The algorithm itself is correct.

This is a reader-timing issue, not an algorithm issue.

---

## 6.3 Force-directed layout is a display heuristic, not a graph invariant

The source genuinely computes spring/repulsion/damping motion.

But its identity says:

> equilibrium reveals graph structure.

The manuscript’s more cautious:

> “may make adjacency easier to inspect”

should be canonical.

---

## 6.4 Force-directed source already supports several graph topologies, but not the manuscript’s proposed same-graph/multiple-layout comparison

The current `graph` axis changes adjacency.

The manuscript’s future experiment should instead change:

- initial positions/seed

while holding adjacency fixed.

That is a new axis, not the current one.

---

## 6.5 Pathfinding replans immediately and restarts the spark at the bank

As above.

The source identity implies bank-to-bank replanning.

The button can interrupt mid-crossing and reset to the route origin.

The manuscript does not currently name this discontinuity.

---

## 6.6 Pathfinding’s “shortest” is shortest under AStar3D’s represented graph/costs, not bodily shortest route

The source and manuscript are aligned here.

The visual stepping-stone graph determines which edges exist.

A body’s jump/reach is another relation.

Keep that distinction.

---

## 6.7 Network Analysis does not compute its advertised centrality hierarchy

As detailed above.

Node centrality is assigned.

Visual size/colour/orbit follow the assigned value.

---

## 6.8 Network Analysis’s clustering/connectivity readouts are animation formulas

As detailed above.

Do not present them as graph statistics.

---

## 6.9 Network Analysis Stage-2 `mutuality` axis changes graph structure in real ways

The source can build:

- a 25-node tree;
- two dense subnetworks with one bridge;
- a complete graph.

This is useful supporting material.

But the current hall’s first repair should still be a real measure.

---

## 6.10 Tarjan is a genuine SCC implementation

The source correctly maintains:

- discovery number;
- low link;
- on-stack state;
- unresolved stack.

Back edges update low links.

Root detection pops SCCs.

The manuscript is source-supported.

---

## 6.11 Tarjan’s `mutuality` axis is a separate graph-structure family, not the algorithm itself

The source can configure:

- pockets;
- none/DAG-like;
- split/two components;
- total/one cycle.

This can be a useful later study, but should not obscure the one-run Tarjan explanation.

---

## 6.12 MST is a genuine Kruskal/Prim implementation; Borůvka remains a placeholder

Kruskal:

- sorted edges;
- Union-Find;
- cycle rejection.

Prim is separately implemented.

`start_boruvka()` simply calls Kruskal.

The manuscript only teaches Kruskal, so no current text error.

Do not advertise three implemented algorithms.

---

## 6.13 MST source identity says Kruskal and Prim have “same result”

Better:

> same minimum spanning-tree objective / same minimum total weight.

The exact edge set can differ under equal-weight alternatives.

---

## 6.14 MST source already includes useful `backbone` representations

- picked
- bare
- refused
- forest.

These are strong visualisations of:

> kept / discarded / impossible spanning.

They do not replace the live Kruskal construction.

---

## 6.15 Push-relabel is not complete classical push-relabel

No reverse residual arcs.

The source itself documents this in Stage-2 comments.

The book is correct.

The visible labels are not.

---

## 6.16 Push-relabel may fail to terminate on some generated states

If an active node retains excess and has no forward residual edge:

- relabel finds no candidate;
- node remains active;
- loop can repeat.

The offline relief solver contains explicit guards.

The live loop does not.

Runtime with the fixed seeded graph may avoid this, but the general implementation is incomplete.

---

## 6.17 Flow source exports many edit/display options not necessarily wired to museum controls

Examples:

- capacity editing;
- graph editing;
- residual display.

Do not infer user interaction from exported booleans alone.

The current manuscript wisely focuses on observable push/relabel state.

---

## 6.18 Matching is explicitly a greedy algorithm despite the filename/class/title

The first source comments state this.

The manuscript correctly refuses the Edmonds claim.

Registry/technical docs should catch up.

---

## 6.19 Matching visible status falsely claims maximum

As above.

Fix the labels immediately.

---

## 6.20 Matching’s `coupling:blossom` graph is already a deterministic greedy-failure exhibit

This is excellent source work currently unused by the map.

Promote it.

---

## 6.21 Matching source scene exports blossom/augmenting-path visual flags that the algorithm never implements

The `.tscn` contains:

- `show_augmenting_paths = true`
- `show_blossoms = true`
- `animate_path_augmentation = true`.

The current script does not perform blossom contraction/augmentation.

These exported claims should be removed/disabled or implemented.

---

# 7. Sequence-level metadata that should be revised

Current sequence truth:

> **Everything is a graph if you squint hard enough.**

This is playful but opposite to what the current book actually teaches.

The manuscripts repeatedly say:

> the graph contains only the represented relations; a search cannot use an edge the representation never supplies.

The QFEP copy also imports broad claims about:

- F in spanning trees/shortest paths;
- E in randomness/percolation;
- flow as F↔E boundary.

That is project-theoretical interpretation, not established graph-theory fact.

## Proposed editorial intention

> **Make a chosen relation explicit as vertices and edges, then change the algorithm or objective while holding that representation in view. Track what becomes possible, what is omitted, and what must be revised when a locally valid step does not establish the desired global result.**

## Proposed objectives

- Separate graph adjacency from visit order and from drawing coordinates.
- Compare queue-based breadth-first and stack-based depth-first traversal on one graph.
- Change graph availability and recompute a route without confusing graph path with bodily affordance.
- Distinguish visual prominence from a named, computed centrality measure.
- Identify strongly connected components through directed mutual reachability.
- Build a minimum spanning tree and distinguish total connection cost from route redundancy/resilience.
- Distinguish capacity, flow and excess, and understand why residual reverse capacity permits revision.
- Distinguish valid, maximal and maximum matching; expose a case where greedy selection must be undone.
- Carry forward the rule: **a procedure satisfying its local condition does not automatically prove the strongest conclusion attached to its name.**

## Sequence truth option

> **A graph does not contain every relation. It contains the relations we chose to encode; algorithms can only reason with those edges, weights, capacities and directions.**

That better matches the current book and prepares Foundations Crisis.

---

# 8. Spatial / curation findings

## Foundations

Primary `two_travelers` is late at `(10,9)`.

Several older graph artifacts precede it.

Manuscript begins with the primary.

Walkthrough needed.

## Layout

Primary `force_directed_layout` `(4,5)` follows `living_paper_bfs` `(2,3)` but is still early.

Likely acceptable.

## Pathfinding

Primary `impatient_river` `(10,9)` comes after several secondaries.

This is likely a reader-order issue.

The controlled route-removal artifact should probably be earlier.

## Network Analysis

Primary `(2,8)` follows a rhizomatic secondary `(2,2)`.

The older art object may prime “network as organic picture” before the audit.

That could be productive if intentional, but the manuscript does not use it.

Runtime observation needed.

## Connectivity

Tarjan `(3,2)`, topological sort `(2,2)`, Kosaraju `(6,2)` all appear together at the entrance.

Manuscript only discusses Tarjan.

Clarify primacy.

## Spanning Trees

Single primary `(5,4)`.

Clean.

## Flow

Several secondaries appear near entrance:

- grid3d_dfs
- grid3d_prim
- karger

then push-relabel at `(4,4)`.

The primary is still close enough to be legible, but `karger` can introduce min-cut language before the chapter has established the incomplete push/relabel process.

Keep it visually secondary.

## Matching

Single primary `(3,4)`.

Clean once restored.

---

# 9. Runtime questions

No repository code was executed. Every hall records `learner_verified: false`.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Whole sequence** | Does the assembled museum currently route Connectivity directly to Flow and Flow directly to Foundations Crisis, omitting Spanning Trees and Matching as `map_authored` reports? |
| **Whole sequence** | After restoring both halls, verify all eight `next_in_sequence` transitions. |
| **Foundations — timing** | With BFS/DFS names delayed, can a visitor predict one lamp’s relative visit order from the visible traversal alone? |
| **Foundations — spatial order** | Which artifact is naturally encountered first: graphspace/Königsberg or Two Travelers? Decide whether legacy material is a deliberate prelude. |
| **Layout — settling** | Does the default cube graph visibly settle enough during a normal visit to support “same adjacency / changing distances”? |
| **Layout — new start** | If added, do two seeded starts of the same graph settle into visibly different but structurally equivalent layouts? |
| **Pathfinding — mid-crossing sink** | Press sink while spark is halfway across. Confirm it jumps back to the bank under current `_replan()`. |
| **Pathfinding — proposed replan** | If replanning from current position, verify disabled current-route stones cannot produce invalid mid-edge state. |
| **Pathfinding — no route** | Can three active disabled stones produce a genuine no-route interval, and does resurfacing reopen it as the readout suggests? |
| **Network Analysis — authored metrics** | Confirm centrality tiers and animated clustering/connectivity values are independent of actual graph-analysis calculations. |
| **Network Analysis — real measure** | After adding DEGREE/BETWEENNESS, verify computed values correspond exactly to current edge set and can disagree with authored node size. |
| **Connectivity — Tarjan** | Can a visitor read edge arrow direction, discovery/low-link values and stack/component pop at the current scale? |
| **Connectivity — secondary competition** | Do Kosaraju/topological-sort artifacts distract from the primary Tarjan narrative at entrance? |
| **Spanning — route** | Restore hall and verify Connectivity → Spanning → Flow navigation. |
| **Spanning — Kruskal** | Does live sorted-edge order, rejection and Union-Find state produce the expected MST cost on the fixed generated graph? |
| **Spanning — rejected edge** | Can a visitor trace the already-selected route between endpoints of one rejected edge and identify the cycle it would close? |
| **Spanning — failure thought experiment** | If an accepted edge is visually removed for a future extension, does the selected tree split into exactly two components? |
| **Flow — termination** | On the fixed BUILD_SEED graph, does the current forward-only loop always terminate? Record sink excess and any stranded excess. |
| **Flow — maximum** | Independently compute true max flow for the fixed graph in a separate test harness before ever labelling the displayed value “maximum.” |
| **Flow — residual repair** | Add a graph requiring reversal and verify FORWARD ONLY stalls/underachieves while RESIDUAL mode reaches a higher feasible flow. |
| **Matching — route** | Restore hall and verify Flow → Matching → Foundations Crisis. |
| **Matching — current label** | Confirm default greedy run can finish while printing “Maximum matching found” even when maximum is not established. |
| **Matching — blossom case** | Configure `coupling:blossom`; verify greedy cycle-first ordering strands four leaves while a five-edge perfect matching exists. |
| **Matching — future augment** | If Edmonds/augmenting revision is added, make the accepted-edge undo visible rather than only swapping to a final answer. |

---

# 10. What I would not cut

## Do not cut the BFS/DFS pair

The graph remains fixed while traversal memory changes.

That is the correct sequence opening.

Change label timing, not the comparison.

## Do not cut queue and stack as implementation trivia

The visitor’s waiting branch becomes understandable only because “pending work” has a data structure.

Keep it.

## Do not cut the distinction between graph and drawing

The entire sequence depends on it.

Layout is not decorative prelude.

## Do not call force-directed equilibrium the graph’s true shape

The manuscript’s caution is essential.

Keep initial conditions and display forces conceptually separate from adjacency.

## Do not cut the resurfacing-stone pool from Pathfinding

It creates two causes of route change:

- removed option;
- restored option.

That is more interesting than one-way damage.

## Do not cut the statement that the bright route is not a bodily promise

Graph path and traversability are different contracts.

Keep it.

## Do not cut Network Analysis merely because the current measures are fake

The room’s critical question is excellent.

Fix the artifact so it earns its title.

## Do not let degree become “the” definition of importance

Use it as the first computed measure, then let another measure disagree.

That is the hall.

## Do not cut low-link/stack detail from Tarjan

The stack is not implementation clutter.

It represents a question whose component membership remains unresolved.

That is a valuable return from Foundations.

## Do not cut strong-connectivity limitations

Return path exists ≠ equal cost/capacity/accessibility.

Keep that.

## Do not cut Spanning Trees because the route currently skips it

It introduces objective-dependent redundancy, essential before Flow.

Restore it.

## Do not cut rejected MST edges

Their structural reason—a cycle already exists—is where Kruskal becomes intelligible.

Keep one rejected edge as a visitor prediction.

## Do not call the MST the cheapest route for every traveller

The manuscript’s distinction between total tree cost and individual path length is excellent.

Protect it.

## Do not cut Flow because it is incomplete

Its incompleteness is highly educational once named honestly.

It shows exactly why residual revision matters.

## Do not print “maximum” while reverse residual capacity is absent

That is the part to fix.

## Do not cut Matching because it is not Edmonds

The greedy process is an excellent starting case.

Use the implemented blossom counterexample to demonstrate why revision is needed.

## Do not cut the A–B–C–D thought experiment if the blossom case is added

The human-scale line remains a compact mental model.

The artifact then supplies the larger proof-of-need.

## Do not let maximum matching become a claim about fair partnership

The manuscript correctly separates:

- cardinality constraint;
- consent;
- preferences;
- suitability.

Keep that boundary.

---

# 11. Reader-experience strengths to protect

## Discovery before naming

**Foundations**  
see two traversal rhythms before BFS/DFS terminology—after label timing is fixed.

**Layout**  
watch edge lengths move before force-directed explanation.

**Pathfinding**  
see route change after a stone becomes unavailable before graph-replanning abstraction.

**Network Analysis**  
count one vertex’s real edges before reading a centrality claim.

**Connectivity**  
trace return paths before SCC terminology.

**Spanning Trees**  
predict accept/reject before Union-Find explanation.

**Flow**  
watch excess accumulate before “push/relabel” terminology becomes the whole story.

**Matching**  
watch a valid pair block later possibilities before maximal/maximum distinction.

---

## Prediction before explanation

- Will this lamp be visited early under each traveller?
- Which edge remains the same while the layout moves?
- Which route replaces the sunken stone?
- Is this large node actually high-degree?
- Can I return along directed edges?
- Will this weighted edge be rejected as a cycle?
- Can this excess be pushed, or must the height change?
- Can this next pair be accepted, and what will it prevent later?

These are strong and should remain the sequence’s rhythm.

---

## Productive distinctions to protect

- graph adjacency ≠ traversal order
- queue ≠ stack
- graph ≠ drawing coordinates
- visual proximity ≠ edge
- changed drawing ≠ changed graph
- graph path ≠ bodily route
- visual importance ≠ computed centrality
- one-way reachability ≠ strong connectivity
- connectivity ≠ cheap connectivity
- minimum total edge cost ≠ shortest individual journey
- redundant under cost objective ≠ useless under failure
- route existence ≠ capacity
- edge saturation ≠ vertex excess
- legal push ≠ globally maximum flow
- valid matching ≠ maximal matching
- maximal matching ≠ maximum matching
- algorithm name ≠ implemented algorithm
- local rule satisfaction ≠ proof of advertised theorem.

This list is the real Graph Theory curriculum.

---

# 12. Questions for the author

## 12.1 Are Spanning Trees and Matching definitively part of the current spine?

The book says yes.

`map_authored` says no.

I strongly recommend restoring both because they make the optimisation/foundations ending coherent.

## 12.2 Is the older Königsberg material meant to precede Two Travelers?

If yes, the manuscript should acknowledge it as a prelude.

If no, move/signpost Two Travelers earlier and update sequence metadata.

## 12.3 Should Pathfinding replan from the traveller’s current position?

I think yes.

The present teleport-to-bank reset weakens the embodied question.

A route planner should encounter its changed graph without erasing the traveller’s current state.

## 12.4 Do you want Network Analysis to become a genuine analysis instrument?

I strongly recommend it.

Degree + betweenness is enough for the first version.

The existing authored hierarchy can then become the deliberately misleading control condition.

## 12.5 Should Flow remain incomplete as a pedagogical failure, or should it become a real push-relabel implementation?

Either can work.

The unacceptable middle state is:

> incomplete algorithm + “Maximum Flow” label.

My preference is a two-mode comparison:

> FORWARD ONLY / RESIDUAL.

## 12.6 Is `edmonds_algorithm` intended eventually to implement Edmonds’ blossom algorithm?

The source’s staged blossom graph is already excellent.

You do not need the full algorithm for the current chapter if the artifact is renamed Greedy Matching.

If you later implement augmentation/contraction, make **undo/revision** the embodied event rather than simply displaying a better final matching.

---

# 13. Overall conclusion

Graph Theory has a strong current argument, and it is not:

> everything is a graph.

It is almost the opposite:

> **a graph is a deliberate reduction to chosen relations. Once that reduction exists, different algorithms can traverse, arrange, optimise or allocate it—but none can recover a relation the representation never encoded.**

The sequence repeatedly changes **what is held fixed**.

Foundations:

> same graph, different pending-work memory.

Layout:

> same adjacency, different coordinates.

Pathfinding:

> changed available vertices, recomputed route.

Network Analysis:

> same drawing can support competing claims of importance.

Connectivity:

> same visible join can fail the return-path criterion.

Spanning Trees:

> same connected graph, different objective about which edges are worth keeping.

Flow:

> same routes, new capacity constraint—and the need to revise earlier allocation.

Matching:

> same legal edge set, but local pair choices can block a larger feasible pairing.

That is excellent progression.

The source audit also gives the sequence a particularly strong handoff to Foundations Crisis.

Two final artifacts are named after algorithms/results they do not currently implement completely:

- Push-Relabel says “maximum flow” without reverse residual capacity.
- Edmonds says “maximum matching” while running a greedy irreversible scan.

The manuscripts already recognise those failures.

That is not embarrassing material to hide.

It is the sequence’s strongest final insight:

> **an algorithm can perform locally intelligible operations and still fail to establish the theorem or optimum its title promises.**

The highest-value work now is therefore:

1. **restore Spanning Trees and Matching to the museum route;**
2. **turn Network Analysis from an authored hierarchy into a real comparison of at least two computed measures;**
3. **either implement residual reverse capacity in Flow or immediately stop labelling the current result maximum;**
4. **use Matching’s already-implemented blossom counterexample and rename the current algorithm Greedy Matching until revision/augmentation exists;**
5. **delay Foundations’ BFS/DFS answer and align its physical/metadata opening with the current manuscript;**
6. **runtime-test the embodied discontinuities and evidence scales—especially Pathfinding’s mid-crossing replan, Tarjan’s low-link readability, Kruskal cycle rejection, Flow termination and Matching’s guaranteed greedy failure.**

The reader-experience principle I would carry forward from Graph Theory is:

> **Let the same network support two different procedures before telling the visitor which extra rule changed the result.**

And the structural principle is:

> **A graph is not the world. It is a chosen set of relations. Every traversal, centrality measure, spanning tree, flow and matching result is conditional on what the graph encoded and on the objective the algorithm was asked to satisfy.**
