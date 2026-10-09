# Procedural Generation — 01 Review

Source-aware editorial and reader-experience review of the **Procedural Generation** sequence.

Basis: `proceduralgeneration-book.md`, `proceduralgeneration-review.md`, and the supplied ZIP snapshot on branch `palm-scanner-door-entry`, captured 2026-09-18. No repository code was executed.

This review uses two linked lenses:

1. **Structural / technical:** what the implemented encounter actually supports, what each return does in the sequence, and where source, metadata, map, and manuscript disagree.
2. **Reader experience:** where curiosity builds, where the visitor can discover something before it is named, where explanation arrives too early, and whether the better intervention belongs to the artifact rather than the prose.

Before proposing any cut, the review asks what technical, poetic, critical, or structural work the passage performs. Recurrence is not treated as redundancy when a familiar operation returns with a changed evaluator, eligible set, body, connection policy, sampling rule, collision consequence, or receiver.

The seven-hall route is coherent and the declared sequence order agrees with the museum-authored order.

The strongest current sequence arc is:

> **criterion → target assignment → responder eligibility → connectivity → inhabitable clearance → sampled/cut form → copied surface and constructed network**

A second formulation is:

> **Procedural generation is not one operation called “generate.” A world is made through a stack of decisions: what is represented, what receives a score, who may respond, which neighbours count, what becomes empty, what is sampled, how a surface is built, which connections are retained, and whether any of it supports a particular body.**

That is substantially stronger than older source rhetoric about “evolution without a designer,” trees “growing toward light,” random caves “no one designed,” or one universal percolation threshold separating disconnected from connected worlds.

---

# 1. One line per hall

| Hall | What carries it / main gap / next useful revision |
|---|---|
| **PG Genetic Evolution** | **Carries:** an excellent opening because the visitor is asked to choose a personally valued body before the scoring logic is unpacked. TARGET reranks unchanged genomes; RING adds a conspicuous torus that the builder renders and the estimator ignores; HOLD preserves the numerical leader but not an arbitrary visitor preference; evolution then shows that a feature can survive through elitism without having contributed to the score. **Gap:** source identity/registry still describes this as “evolution without a designer,” convergent evolution and mutation-rate “edge of chaos,” while the staged lesson is a much narrower audit of one proxy evaluator plus a simple evolutionary kernel. **Next:** preserve the manuscript; clean source metadata and runtime-test whether rank/estimate labels bias the visitor’s initial personal choice too strongly. |
| **PG Space Colonization** | **Carries:** one of the sequence’s strongest causal studies. Three unit-direction requests sum to a half-metre upward step; TIPS makes one-root growth a strand because influenced leaves are replaced in the eligible set; NETWORK keeps earlier sites eligible so forks can arise across generations; HOLD keeps one scaled witness; the 96-point canopy is explicitly authored rather than fresh stochastic “nature.” **Gap:** no major literary issue. The current source is unusually well aligned with the manuscript. **Next:** preserve and headset-test the gold assignment vectors, first-step prediction, held 0.45-scale witness and physical separation between generated form and museum support. |
| **PG Branching Growth** | **Carries:** the manuscript makes a valuable contrast with Space Colonization: one active site listens to its **nearest** invitation rather than summing several; no-variation mode can create duplicate stored children at one visible position, so record count and spatial distinction can diverge; VARIATION then adds explicit jitter/pulsing rather than pretending the organic-looking result emerged from the nearest-target rule alone. **Gap:** the actual lesson controls—TEN STEPS, HOLD, VARIATION, RULE and the deterministic opening field—live in the shared `pg_workshop.gd`, which is not included in this bundle. The underlying algorithm’s own `lesson` flag only reduces counts and does **not** by itself switch off jitter/pulse or build the manuscript’s controlled study. **Next:** fix the review exporter/source closure before treating this hall as fully source-verified. |
| **PG Percolation Network** | **Carries:** face contact versus corner contact makes neighbourhood definition concrete; the finite 18³ lattice then turns occupation density into a reachability experiment; one generation at a time keeps connectivity procedural rather than instant; flow removes collision from sites it reaches, so the same event becomes connection for the signal and reduced resistance for the visitor. The manuscript wisely refuses to infer a universal critical threshold from one finite lattice. **Gap:** all CONTACT/LATTICE/DENSITY/RULE controls are supplied by the missing `pg_workshop.gd`. Source identity still claims a sharp universal threshold, fractal critical cluster and “below nothing / above everything,” far stronger than the finite experiment. **Next:** include the workshop source and clean the percolation identity/registry rather than weakening the manuscript. |
| **PG Caves Mazes** | **Carries:** two generators make interior in genuinely different ways. The cave begins full and removes 3D cells around biased carving centres with explicit headroom; TRACE records where carving happened without pretending separate walkers form one continuous route. The maze removes walls while retaining a backtracking stack; its path in the array is not yet certified as comfortable VR passage. **Gap:** the manuscript begins with the cave, but from spawn `(19,1)` the workshop is `(19,3)`, the maze is `(19,6)` and the cave is farther at `(9,12)`. The natural forward route therefore presents the maze first. The main control implementation is again in missing `pg_workshop.gd`. **Next:** restage cave before maze if the current manuscript order is intended, and include the shared control source. |
| **PG Sculpted Forms** | **Carries:** a strong three-way materialisation comparison. Cubes physically fall; SAMPLE records only their centres and builds an enlarged axis-aligned voxel approximation; ORIGINAL makes body and sampled surface comparable while keeping the sampled collider; VOXEL changes the reconstruction resolution without changing the frozen sample. The dome then exposes subtraction operands; the membrane adds a skin-versus-solid contrast. **Gap:** curation metadata still lists only `cube_mound_scene` as primary even though the current manuscript gives the dome a full second encounter. The shared DROP/SAMPLE/ORIGINAL/VOXEL/CUT controls live in the unbundled workshop source. `cube_mound` source identity also says voxelisation “smooths” the pile, although the implementation emits exposed axis-aligned voxel faces. **Next:** promote the dome to primary role, include the workshop, and clean the mound identity. |
| **PG Mirrored Patterns** | **Carries:** an effective sequence ending because copying and connectivity remain distinct. A held cellular field can be reinterpreted through quadrant/eight-way/rotation/no-copy arrangements without drawing a new random field; odd-grid centre lines and integer rotational mapping expose implementation residue. The network study then changes connection policy over a fixed seed set, counts undirected edges/components/cycles, and separates skeleton from generated tunnel skin while disabling collision in both. **Gap:** the manuscript treats `rhizomatic_maze_space` as a primary second encounter, but role metadata lists only the mirrored CA as primary. The workshop controls and the rhizomatic helper classes (`RhizomaticMazeGenerator`, path network, mesh builder, materials) are absent from the snapshot, so NETWORK/SURFACE behaviour is not fully source-verifiable. **Next:** promote the network to primary curation, extend source closure, and clean the older Deleuzian “rhizome as architecture / world with no author” identity around the much more concrete finite network study. |

---

# 2. Sequence structure

Procedural Generation is already much more coherent than the category name suggests.

It does not simply collect several generators.

Each hall adds another layer that a generated environment needs before it can become a world for a body.

## 1. Genetic Evolution — who decides what continues?

The opening establishes a distinction the whole sequence needs:

> **body representation ≠ evaluator representation**

A genome can contain a torus that the builder draws and the estimator ignores.

Changing the target changes the ranking without changing the bodies.

Selection therefore acts through a **proxy account** of the body, not through the body “as a whole.”

This is an excellent starting point for procedural generation because it makes judgement visible before growth begins.

## 2. Space Colonization — which requests contribute?

The target is no longer one scalar score.

It becomes a field of positions.

Each target contributes a normalized direction to its nearest eligible site.

Several directions can be summed.

Then a second question appears:

> which sites remain eligible to receive later requests?

TIPS and NETWORK therefore separate **target assignment** from **responder eligibility**.

That distinction is structurally important.

## 3. Branching Growth — what if a site listens to only one invitation?

The next hall deliberately changes the growth policy.

Instead of summing all requests assigned to one site, each active branch finds one nearest target.

The no-variation version exposes a source-level oddity:

> an old branch can produce another stored child at the same spatial position.

The database may therefore say “another child” while the visual field says “nothing new.”

This is a very useful transition from procedural form to procedural accounting.

## 4. Percolation — what counts as connected?

Now the sequence stops asking where a branch goes.

It asks whether state can propagate through a finite occupied set.

The decisive choice is local:

> six face-neighbours count; corner contact does not.

The hall then keeps another important distinction visible:

> signal connectivity and bodily collision are not the same relation.

Flowing sites become less obstructive to the visitor, but successful signal propagation still does not guarantee a human route.

## 5. Caves / Mazes — connection is not yet inhabitable interior

The cave and maze turn connectivity into carved spatial form.

The cave starts with solid volume and removes cells around guided walker positions.

The maze starts with walls and removes selected walls while remembering unfinished alternatives on a stack.

Both produce “routes,” but through different stored structures.

The chapter’s key progression is:

> line/path logic  
> → width/headroom  
> → collision/clearance  
> → body-specific traversal.

## 6. Sculpted Forms — when do generated events become surfaces?

The sequence reverses direction.

Instead of carving an environment first, it takes a physical event and **samples** it.

A cube pile becomes a centre-based voxel surface.

A dome becomes the subtraction of explicit operands.

A layered membrane becomes several displaced skins that can look thick without constituting one filled solid.

The lesson is:

> generated form can arise from sampling, subtraction or surface arrangement; the visible result alone does not tell us which one happened.

## 7. Mirrored Patterns — compose copied information and connection policy

The final hall gathers earlier capabilities.

One artifact asks:

> how much independent information was actually generated before symmetry copied it?

The other asks:

> which graph edges were created, which components/cycles result, and what kind of surface was later wrapped around those edges?

This is a good closing move because it leaves Procedural Generation with two separable tasks:

- **copy/transform information**
- **connect places**

Both are necessary for world building, and neither guarantees embodied access by itself.

---

# 3. Reader-experience lens

## PG Genetic Evolution — What does the score notice?

### Curiosity

The opening is excellent:

> six candidates; one is pink; choose the one **you** want before learning why the program selected its leader.

This establishes a visitor criterion that the machine cannot currently store.

The limitation of HOLD reinforces that distinction:

> HOLD preserves the numerical leader, not an arbitrary visitor preference.

That is not a missing convenience to rush to fix. It is part of the encounter.

### Discovery

TARGET is particularly strong.

Nothing about the candidates changes.

Generation does not advance.

The target changes:

- 8
- 16
- 32.

Ranking changes.

The visitor can therefore discover:

> “best” belongs to a criterion.

RING is even stronger.

A visually conspicuous torus appears.

The score does not move.

RULE then reveals why:

- primitive builder supports torus;
- volume estimator has cases for sphere, box, cylinder;
- no torus case.

The evaluator literally cannot notice something the renderer can show.

### Timing

Very good overall.

The only reader-timing question is the permanent candidate labels.

`selection_lesson.gd::refresh()` puts:

> rank  
> estimate  
> score  
> part count

under every candidate from the start.

That could pull the visitor’s attention toward the evaluator before they have made their own choice.

I would not change this immediately.

First learner-test whether visitors actually choose a body from form or simply read the ranking labels.

If the score dominates first attention, a later **SHOW SCORE** reveal would improve the opening.

### Evolution

STEP is well framed.

Two elites are copied.

Four other population slots come through tournament selection, optional crossover and mutation.

The important manuscript sentence is:

> “An elite copy can carry [the ring] into the next generation although it earned no points.”

This is source-supported and conceptually excellent.

Survival of a feature is not proof that the feature was selected for.

### Return

Form Finding returns through authored fitness.

L-systems returns through genomes/builders.

The new subject is:

> which representation the evaluator is able to notice.

---

## PG Space Colonization — Which points get a say?

### Curiosity

The opening geometry is unusually good.

Three points are arranged so a visitor can predict the resultant without a tree already obscuring the relation:

- left at `(-2,3,0)`
- right at `(2,3,0)`
- upper at `(0,5,0)`.

Each contributes a **unit** direction.

Horizontal components cancel.

Vertical components survive.

The first half-metre child appears at `(0,0.5,0)`.

The artifact’s gold request lines and white proposed segment make the calculation spatial before the code arrives.

### Discovery

FIELD 1 moves from the symmetrical opening to an authored asymmetric set.

The visitor can see some points retain influence and some fall behind.

TIPS then creates the central limitation:

> with one root, an influenced tip is replaced by one successor.

The visible result is a strand.

HOLD preserves a witness.

POLICY then resets the **same field** and changes eligibility.

NETWORK keeps earlier sites eligible.

A previous site can later act again.

Forks become possible.

The held strand and live network now embody the policy difference.

### Timing

Excellent.

RULE is hidden.

The policy name arrives after the strand has already made its limitation visible.

The 96-point canopy is explicitly described as authored through sine offsets.

This prevents “more organic” from becoming “more natural/random.”

### Return

Forces returns through normalized vectors.

L-systems returns through branching.

Procedural Generation adds:

> target assignment + eligible responder set.

---

## PG Branching Growth — One nearest invitation

### Curiosity

The chapter deliberately reuses the eight-point field from Space Colonization.

That is a strong controlled return.

The visitor can ask:

> if several requests previously combined, what changes when the rule listens only to one nearest request?

The first displacement is small enough to predict:

- target `(-2,1.5,0)`
- normalized direction `(-0.8,0.6,0)`
- half-metre step `(-0.4,0.3,0)`.

This is very good tutorial construction.

### Discovery

The most interesting result is not the eventual “tree.”

It is the mismatch between:

- stored branch records;
- distinct spatial positions.

The underlying algorithm keeps old active branches active.

With jitter/pulsing suppressed, an old branch can choose the same target again and add another child at the same computed position.

So:

> stored branching can increase without visible branching increasing.

The manuscript correctly calls this a failure of the first description rather than hiding it.

VARIATION then makes previously coincident paths separate.

That is a good moment because the additional organicity has an explicit source:

- jitter;
- pulsing segment length.

It is not credited to the nearest-target rule alone.

### Timing

The manuscript timing is strong.

The source evidence is the problem.

The opt-in control desk `pg_workshop_console` is what technical documentation says supplies:

- TEN STEPS;
- HOLD;
- VARIATION;
- RESET;
- RULE;
- deterministic opening configuration/readout.

But `pg_workshop.gd` is **not in the bundle**.

The primary `branching_growth_algorithm.gd` does not itself establish the full staged lesson.

Its `config_lesson` only adjusts counts; it does not by itself zero jitter/pulse or build the held comparison.

So this hall cannot honestly be called fully source-verified from the current ZIP.

### Return

Space Colonization returns under one changed operation:

> sum several directions  
> → choose one nearest direction.

This is exactly the kind of recurrence to protect.

---

## PG Percolation Network — Touching is not enough

### Curiosity

The face-versus-corner comparison is an excellent opening because it begins with an apparently obvious relation:

> two cubes touch.

Then the algorithm says only one of those contacts counts.

That makes “neighbour” operational instead of visual.

### Discovery

The key local rule is simple:

- six axis neighbours;
- no diagonals.

The larger lattice then gives that local definition consequence.

DENSITY changes the occupation cutoff while preserving the seeded draw sequence.

The source/lesson uses values equivalent to:

- 0.2
- 0.4
- 0.6

in the staged comparison.

The visitor can follow flow one generation at a time rather than treating the connected cluster as instantly known.

### Collision

The best embodied distinction is:

- OCCUPIED/white → collision;
- SOURCE/FLOWING/CONNECTED/pink → no collision.

The signal’s successful arrival changes another system’s resistance.

This is exactly the kind of layered consequence the sequence needs.

### Timing

The manuscript is careful.

It explicitly says:

> one finite 18³ field cannot establish a universal critical threshold.

That should govern the entire artifact.

The old source identity does the opposite.

It says:

> below the threshold nothing connects; above it everything does; at the threshold the system decides.

and invokes a specific 3D critical `p_c ≈ 0.3116`, a fractal incipient cluster and broad analogies to forests, fluids and rumours.

Those may be scientifically contextualizable, but they are not demonstrated by this one finite seeded museum field and the package supplies no citations for the claims.

### Source gap

Again, CONTACT/LATTICE/DENSITY/STEP/RULE belong to the missing workshop source.

The base algorithm can be read, but the staged comparison cannot be fully audited.

### Return

Cellular Automata returns through double-buffer-style local propagation.

Randomness returns through occupancy sampling.

The new question is:

> which local relation becomes a connected route for one process?

---

## PG Caves Mazes — A route needs room

### Curiosity

The manuscript wants the cave to come first for a good reason.

It begins from a bodily question:

> a connected line has no width; your shoulders do.

That is stronger than starting with a textbook maze.

TRACE then marks carving centres and makes a useful distinction:

> the generator stores/removes space; it does not necessarily store one continuous “cave path.”

### Cave discovery

The cave is highly authored.

Its identity says “a cave no one designed,” but the actual procedure specifies:

- four side starts;
- centre-biased phase;
- low-level lateral phase;
- upward level-by-level phase;
- two-cell headroom;
- lateral carve radius;
- explicit centre pocket.

The manuscript correctly exposes these choices.

This should become the canonical interpretation.

### Maze discovery

The maze asks another kind of route question.

Depth-first backtracking stores current alternatives in a stack.

When one branch has no unvisited neighbour:

> pop and continue from an earlier cell.

Backtracking is therefore a **memory mechanism**, not a failure.

The 9×9 lesson and 1.5 m cells provide a finite inspectable example.

The desktop route check establishes an array-level entrance-to-exit connection.

The manuscript correctly refuses to turn that into a guarantee of comfortable headset clearance everywhere.

### Spatial timing problem

Current authored positions:

- spawn `(19,1)`
- workshop `(19,3)`
- maze `(19,6)`
- cave `(9,12)`.

The visitor moving forward from the entrance naturally encounters the maze first.

The manuscript says:

1. cave
2. across the court, maze.

This is not a tiny ordering detail.

The cave establishes **interior clearance** as the chapter’s question.

The maze then compares another route-construction procedure.

If maze arrives first, the bodily framing is weakened.

### Proposal

If cave-first remains the intended argument:

- place cave in the nearer front court;
- move the maze later/across from it.

The console can remain near the entrance.

Do not rewrite the chapter maze-first simply to follow accidental current coordinates unless that spatial order is deliberate.

### Evidence gap

The chapter says:

> “The desktop check follows open maze cells from entrance to exit.”

No dated check/capture is attached in `evidence/`.

Keep it as prior runtime evidence only if its provenance is carried into the bundle.

---

## PG Sculpted Forms — What did the sample keep?

### Curiosity

The first action is excellent:

> drop twelve cubes; **choose when to sample**.

The visitor has to decide what state the next construction inherits.

This makes SAMPLE a temporal/editorial operation rather than a neutral export button.

### Cube mound discovery

The source does something deliberately lossy.

It stores only cube centres in the mound’s local frame:

```gdscript
to_local(cube.global_position)
```

Then each centre marks an axis-aligned voxel neighbourhood.

With the lesson values:

- cube size = 1.0 m;
- voxel size = 0.5 m;

the source computes:

> `ceil(cube_size / voxel_size) = 2`

as the extent in each direction.

So each centre affects a sizeable voxel block around its cell.

The result is **not** a copy of cube rotation/contact geometry.

The manuscript is technically strong here.

### ORIGINAL

This control is especially important.

The visible original cubes and sampled mesh can alternate while the sampled collider remains active.

That means:

> visual source body and currently enforced collision body can disagree.

Very good.

### VOXEL

The same frozen centres receive another discretisation.

An opening can fill.

A boundary can move.

This is a strong continuation of the book’s recurring:

> resolution is a decision, not merely polish.

### Source identity problem

`cube_mound.gd` says:

> “the voxelized mesh smooths over individual cube positions.”

But the actual builder emits exposed faces of occupied axis-aligned voxels.

There is no smoothing pass.

The reconstruction may visually merge cubes into one blocky surface, but “smooths” is technically misleading.

The identity also says:

> a mound is what gravity does, release geometry is the whole design.

Yet the result also depends on:

- cube count;
- rigid-body collisions;
- spawn rotations;
- physics;
- sampling time;
- voxel size;
- voxel reconstruction.

The manuscript is much better because it treats the sampled surface as another authored representation rather than as gravity’s pure answer.

### Dome

The Boolean dome is a good second encounter.

CUT exposes:

- cast;
- blank stock;
- cutting cores;
- section.

The source genuinely uses CSG subtraction.

The manuscript correctly makes **negative volume** authored rather than empty/non-work.

### Membrane

The manuscript uses the secondary layered membrane as a third contrast:

> nested displaced skins can suggest thickness without becoming one filled solid.

Its implementation source is not included in this bundle.

That is acceptable as secondary context, but if the paragraph remains conceptually important, future bundles should include it.

### Curation mismatch

The manuscript treats both:

- mound;
- dome

as primary encounters.

`artifact_roles` still lists only the mound as primary.

Update that metadata.

---

## PG Mirrored Patterns — A repeated image, another way through

### Curiosity

The opening is well designed.

A held irregular field comes first.

STENCIL then changes the copying operation rather than changing the underlying sample.

This is a good continuation of Assemblage Same Desire:

> same decisions / another visible organisation.

### Mirrored field discovery

The implementation’s 21×21 odd grid matters.

Different stencils have different edge consequences.

Quadrant and octant copying do not treat every centre row/column as a perfectly interchangeable member of the mirrored loop.

Rotational copying also converts floating positions into integer grid addresses.

The manuscript correctly says:

> symmetrical intention still passes through implementation.

Good.

### HOLD / STEP

The staged lesson says HOLD stores the current array.

STENCIL then reapplies copying to that held field rather than drawing a new random field.

STEP performs one CA update and then symmetry.

That makes the comparison controlled.

But these controls belong to missing `pg_workshop.gd`, not to the included wrapper alone.

### Network

The second encounter is conceptually strong.

The lesson mode on `RhizomaticMazeSpace.gd` pins:

- a six-seed-ish reduced arrangement through two vertical layers;
- topology to tree initially;
- fixed seed;
- no secondary growth iterations;
- stripped capture-stage fog/debug furniture.

The workshop then apparently changes NETWORK policy among finite alternatives such as:

- tree;
- a more connected/rhizomatic policy;
- severed.

The manuscript carefully says the severed policy also displaces positions to produce its gap, so visible difference is not attributed only to deleted edges.

That is good.

### Graph counts

The chapter uses:

> `edges - nodes + components`

for independent cycle count in a finite undirected graph.

That is appropriate for the displayed graph abstraction.

But the source package lacks the actual helper classes that build/store the network:

- `RhizomaticMazeGenerator`
- `RhizomaticPathNetwork`
- `OrganicMeshBuilder`
- `RhizomaticMaterials`

So exact edge/component/cycle behaviour cannot be fully source-audited from this bundle.

### SURFACE

The manuscript says collision is disabled in both skeleton/surface views.

Again, this depends on workshop/study configuration and helper source that is not included.

### Source rhetoric

The old identity is much stronger:

> “Deleuze’s rhizome as architecture”  
> “non-hierarchical tunnel network”  
> “world with no author.”

The current lesson is better:

> six fixed starting positions, explicit connection policy, explicit cycles/components, optional severing, generated surface, collision disabled for observation.

Keep the finite construction primary.

### Curation mismatch

This network is half of the chapter.

Yet `role_primary_order` lists only the mirrored cellular texture.

Promote `rhizomatic_maze_space` to primary for this map.

---

# 4. Five high-value changes

## 4.1 Fix the review/source exporter so the **actual lesson controller** is always included

**Affected halls**

- `PG_Branching_Growth`
- `PG_Percolation_Network`
- `PG_Caves_Mazes`
- `PG_Sculpted_Forms`
- `PG_Mirrored_Patterns`

**Artifact**

`pg_workshop_console`

Registry scene:

> `res://commons/artifacts/timing_machines/pg_workshop.tscn`

Technical docs repeatedly state:

> controls are implemented in `commons/artifacts/timing_machines/pg_workshop.gd`.

That file is not present in this ZIP.

### Why this matters

For these halls the workshop is not decorative in the editorial sense, even though role metadata calls it `decoration`.

It owns the very interactions the manuscript asks the visitor to perform.

Examples:

**Branching**

- TEN STEPS
- HOLD
- VARIATION
- RULE
- deterministic/variation comparison

**Percolation**

- CONTACT
- LATTICE
- DENSITY
- STEP
- reset/replay logic

**Caves/Mazes**

- TRACE
- CAVE SEED
- MAZE STEP
- FINISH
- RESET

**Sculpted Forms**

- DROP
- SAMPLE
- ORIGINAL
- VOXEL
- CUT

**Mirrored Patterns**

- HOLD
- STENCIL
- STEP
- NETWORK
- SURFACE

The primary scripts expose kernels, but the **lesson-specific causal experiment** is partly assembled by this missing controller.

### Evidence type

SOURCE GAP

### Exporter proposal

Change source closure rules:

> Any placed artifact referenced by a current manuscript action or by a hall’s technical implementation notes must be included regardless of whether `artifact_roles` calls it decoration.

Also follow global/helper classes that own the relevant state:

- Rhizomatic maze helper classes;
- layered membrane if its paragraph remains part of the main conceptual comparison.

### Reason

The current source-aware review can verify kernels but not the actual lesson state machine for five of seven halls.

That is too large a blind spot for a package designed specifically for source-aware review.

---

## 4.2 Caves/Mazes — make the spatial encounter order match the manuscript

**Hall**

`PG_Caves_Mazes`

Current placements:

- spawn `(19,1)`
- workshop `(19,3)`
- maze `(19,6)`
- cave `(9,12)`
- BSP secondary `(11,23)`.

### Current manuscript order

1. cave
2. “Across the court” → maze
3. BSP as secondary comparison.

### Work performed by this order

The cave establishes the chapter’s central body question:

> **a route needs width and headroom.**

It begins from a volume that is already intended as bodily space.

The maze then supplies another generator whose stored path/backtracking relation can be compared with that bodily problem.

That order is coherent.

### Spatial problem

From the low-z entrance, the maze occupies the forward route before the cave.

A first-time visitor may therefore learn:

> maze algorithm → later cave

while the book argues:

> bodily void → compare maze construction.

### Evidence type

SPACE + HYPOTHESIS

The authored coordinates strongly suggest the mismatch, but actual sightline/path still needs a walk.

### Artifact/spatial proposal

If the manuscript’s cave-first argument is intended:

- bring `caverandomwalk` into the near/front court;
- move `maze_generation` farther/across from it.

Keep the central workshop where both can be controlled.

Alternative:

- if current spatial order is artistically preferred, rewrite the chapter around maze-first and then use cave as the bodily correction.

I prefer restaging because the current chapter’s first line is excellent.

### Reason

This is a classic reader-experience issue.

The better fix is in the room, not in adding navigation prose.

---

## 4.3 Update artifact roles so automated tooling follows the **current manuscript**, not older single-primary curation

Three halls have manuscript-promoted second primaries that role metadata still treats as secondary/non-primary.

### PG_Caves_Mazes

Manuscript:

- `caverandomwalk`
- `maze_generation`

Role primary order:

- `caverandomwalk` only.

### PG_Sculpted_Forms

Manuscript:

- `cube_mound_scene`
- `dome`

Role primary order:

- `cube_mound_scene` only.

### PG_Mirrored_Patterns

Manuscript:

- `mirror_cellular_texture_for_3d`
- `rhizomatic_maze_space`

Role primary order:

- `mirror_cellular_texture_for_3d` only.

### Evidence type

CURATION / SOURCE ROUTING

### Proposal

Update `artifact_roles.json` / core encounter records so all of these current manuscript encounters are primary.

Do not demote the first object.

Use ordered primary sets:

**Caves**

> cave → maze

**Sculpted**

> mound → dome

**Mirrored**

> mirrored field → network.

The workshop console should also receive a role such as:

> **lesson controller / instrument**

rather than decoration where the role system supports that distinction.

### Reason

This is not bookkeeping only.

The stale roles already cause:

- incomplete source export;
- one-line review summaries that underrepresent half a chapter;
- potential future automated deletion/curation suggestions based on an outdated reading path.

The current manuscript should be authoritative for what is pedagogically primary.

---

## 4.4 Percolation — bring source/registry claims down to the finite experiment the book actually performs

**Hall / artifact**

`PG_Percolation_Network`

`percolationnetwork_ca`

### Current manuscript

The book says:

> “One such field cannot establish a universal critical threshold. Its seed, dimensions, boundary source and neighbourhood are part of the experiment.”

This is excellent.

### Current source/registry rhetoric

The source identity says:

> “PERCOLATION_THRESHOLD (0.4) — the probability that defines whether the system connects or fragments; near p_c the outcome is uncertain”

> “at the critical threshold, the percolating cluster forms a fractal”

> “below the threshold nothing connects, above it everything does, and at the threshold the system decides.”

Registry language similarly says:

> connectivity snaps from rubble to network at one critical value.

The source comments also cite:

> `p_c ~= 0.3116`

for 3D site percolation.

These are broader statistical-physics claims.

They are not demonstrated by one:

- finite 18³ lattice;
- selected seed;
- particular face/point/seam/shell inlet;
- dynamic flow model with additional flow magnitudes;
- collision remapping.

No scientific citation is provided in this review package.

### Evidence type

SOURCE + UNSUPPORTED SCIENTIFIC CLAIM

### Proposal

Change visitor/project identity to operational language:

> **Sample an 18³ occupied lattice at a declared site probability; inject flow from a declared boundary set; propagate through six-connected occupied neighbours; compare whether this finite run reaches the opposite face.**

If you want the infinite-lattice site-percolation threshold in technical/contextual material:

- cite it;
- distinguish it from the finite museum result;
- do not imply that every finite sample below it fails or every sample above it succeeds.

Remove “edge of chaos” / universal snap rhetoric from the artifact identity.

### Reason

The manuscript has already solved this problem.

The source metadata should stop reintroducing the stronger claim.

---

## 4.5 Genetic / Branching / Cave / Mound / Rhizome — clean the old “natural/autonomous” identities around the current accountable lessons

This is a sequence-level source-maintenance change rather than a prose rewrite.

Several artifacts still carry claims the current manuscripts explicitly complicate.

### GeneticProgramming

Current source:

> “evolution without a designer”

> creatures converge on similar body plans

> mutation 0.3 is “the edge of chaos.”

Current lesson actually demonstrates:

- authored genome alphabet;
- authored proxy estimator;
- authored target;
- tournament size;
- elitism;
- crossover probability;
- mutation implementation.

Suggested identity:

> **A finite evolutionary search over an authored genome language under an explicit proxy fitness function.**

### branching_growth_algorithm

Current source:

> “tree grow toward light”

> “more queer energy”

> “natural spacing patterns that resemble real vascular networks.”

Current lesson:

- nearest target;
- optional jitter/pulse;
- duplicate records;
- finite branch budget.

Suggested identity:

> **Nearest-target branch extension with optional jitter/pulsed segment length; inspect records, distinct positions and finite budget.**

### caverandomwalk

Current source:

> “cave that no one designed”

> “walker’s path is the cave’s memory.”

Current implementation is deliberately guided:

- four side starts;
- centre bias;
- explicit multi-level schedule;
- carve radius;
- headroom;
- centre pocket.

Suggested identity:

> **Guided stochastic carving through a solid voxel grid; the carved void records where authored walkers were allowed to remove cells.**

### cube_mound

Current source:

> “voxelized mesh smooths over individual cube positions”

> “mound is not designed — it is what gravity does.”

Current implementation:

- authored release geometry;
- rigid-body event;
- visitor-chosen sample time;
- centre-only sample;
- axis-aligned voxel expansion;
- extracted exposed faces;
- collider.

Suggested identity:

> **Sample a rigid-body pile by cube centres and rebuild it as an axis-aligned voxel surface.**

### rhizomatic_maze_space

Current source:

> “Deleuze’s rhizome as architecture”

> “world with no author.”

Current placed lesson:

- fixed small seed set;
- explicit topology policy;
- edge/component/cycle counts;
- optional severing/displacement;
- generated tunnel surfaces;
- collision disabled for observation.

Suggested identity:

> **Compare explicit network-construction policies over one fixed seed arrangement, then inspect how a tunnel surface changes the legibility of that graph.**

### Reason

These source descriptions were valuable ideation.

The current book has matured into a method where the visitor can locate the operation responsible for a form.

The source metadata should now support that method.

---

# 5. Source / artifact discrepancies

## 5.1 Genetic volume score is intentionally a proxy, not measured union volume

This is one of the sequence’s strongest source/text matches.

The builder creates a unit `BoxMesh` and scales it by the gene scale.

The estimator uses:

```gdscript
scale.x * scale.y * scale.z * 8.0
```

so a scale-1 box is estimated as volume 8 although its rendered unit box has volume 1 before scaling.

It also sums per-gene contributions without subtracting overlaps.

And torus genes are rendered but ignored by `estimate_volume()`.

The manuscript correctly names the estimator as a proxy and turns the omission into an encounter.

Do not silently “fix” the estimator before deciding whether you want to preserve this explicit critique.

---

## 5.2 Genetic RESET does not replay later offspring

`selection_lesson.reset_population()` restores six fixed one-box genomes and target 8.

It does not reseed the global random stream used later by:

- tournament draws;
- crossover decisions;
- mutation.

The manuscript correctly says:

> opening repeatable; later offspring need not repeat.

Keep that distinction.

---

## 5.3 Genetic source identity overstates autonomy and criticality

As above.

The current lesson exposes extensive authorship.

A mutation rate being 0.3 in this implementation does not by itself demonstrate an “edge of chaos.”

---

## 5.4 Space Colonization’s TIPS and NETWORK policies are source-supported and genuinely different

The current source has been improved substantially.

**TIPS**

- targets choose nearest current leaf;
- leaf receives sum of unit directions;
- influenced leaf adds one successor;
- successor replaces it in eligible `leaf_nodes`.

**NETWORK**

- every existing node remains eligible;
- all assignments are read from one unchanged generation;
- one child max per eligible site per generation;
- duplicate proposed positions are skipped;
- every new node has exactly one parent;
- no operation joins existing branches into loops.

The manuscript’s strand/tree distinction is therefore accurate.

---

## 5.5 Space Colonization has one legacy zero-sum edge case worth remembering

The technical notes say the original TIPS kernel can produce a zero-length successor when assigned request vectors cancel completely.

The lesson’s opening three-point setup does not do this because the upward components survive.

But the field rule does not globally guarantee nonzero sums.

No prose change is required.

It is a useful implementation boundary if a later field produces it.

---

## 5.6 Branching Growth’s lesson state cannot be fully reconstructed from included source

`branching_growth_algorithm.gd` does expose:

- nearest-attractor search;
- jitter;
- pulse;
- persistent active branches;
- fixed max branch count.

But the current manuscript depends on a controlled workshop mode with:

- exact eight points;
- no variation opening;
- TEN STEPS;
- HOLD;
- VARIATION;
- distinct-position count.

Those controls are not in the included primary source.

Do not claim full source verification of this chapter until `pg_workshop.gd` is present.

---

## 5.7 Branching source identity biologises the algorithm more strongly than the book

“grow toward light,” “vascular networks,” and similar language are associations, not demonstrated mechanisms.

The attractors are coordinates.

The current manuscript is correct to say so.

---

## 5.8 Percolation source uses six-connected neighbourhood and synchronous grid copy

The base algorithm source supports the manuscript’s local contact distinction.

It duplicates the grid/flow arrays before update and uses only:

- ±x
- ±y
- ±z.

Corner contact is excluded.

That part of the lesson is technically grounded.

---

## 5.9 Percolation collision is state-dependent and source-supported

OCCUPIED sites get `StaticBody3D` collision.

FLOWING, CONNECTED and SOURCE do not.

When a site changes state, `update_cube_collision()` removes/rebuilds collision accordingly.

The manuscript’s “connection for signal / reduced resistance for body” is source-supported.

Actual safe bodily passage remains a runtime question.

---

## 5.10 Percolation criticality rhetoric needs external sourcing and stronger qualification

As above.

The package itself supplies no scientific reference for the numerical critical threshold.

Do not invent one inside the book.

---

## 5.11 Cave generation is explicitly guided and phase-structured

The current source has:

**Phase A**

- four side starts;
- centre-biased lateral motion.

**Phase B**

- jump to y=1;
- 10 random lateral steps.

**Phase C**

- climb y=2..top;
- prescribed steps per level;
- mostly mild centre bias with some free lateral choices.

Each carve centre removes a radius-1 lateral disk over two vertical cells.

The manuscript’s phrase:

> “guided more deliberately than its name might suggest”

is exactly right.

---

## 5.12 Cave TRACE is carve-centre history, not one continuous walker path

`carve_history.append(center)` occurs for every `_carve_ball()` call.

Because there are several walkers and repeated visits, the trace is a set/sequence of carving centres across multiple processes.

The manuscript correctly says not to connect them into a fictitious single trajectory.

---

## 5.13 Maze backtracking is source-supported

The maze generator:

- moves to an unvisited neighbour;
- removes the wall between cells;
- pushes current cell to stack;
- pops when stuck;
- finishes when no unvisited neighbour and stack empty.

The manuscript is aligned.

The exact workshop `MAZE STEP`/`FINISH` wrapper remains unverified until the control source is included.

---

## 5.14 Cube mound source identity says “smooths”; code builds exposed voxel faces

There is no smoothing pass in `create_mesh_from_voxels()`.

The surface is an axis-aligned voxel boundary.

It may merge many cubes into one continuous-looking mound, but “smooth” is technically inaccurate.

---

## 5.15 Cube mound sample intentionally omits cube orientation/contact geometry

Only centre positions are sampled.

Rotation and exact contact faces of original cubes are not copied.

The manuscript’s centre-based approximation language is source-supported.

---

## 5.16 Cube mound generated surface has its own trimesh collider

After mesh generation, the artifact creates a `StaticBody3D` and `create_trimesh_shape()` from the generated mesh.

Original cube collisions are disabled.

Thus the visitor can encounter a new collision representation derived from the sample.

The workshop’s ORIGINAL visual-toggle semantics still need source verification.

---

## 5.17 Dome’s Boolean subtraction source is direct and well aligned with the manuscript

The current `dome.gd` can stage:

- cast;
- blank;
- cores;
- section.

The section itself uses a subtraction CSG box.

The manuscript’s “absence has operands” account is source-supported.

---

## 5.18 Layered membrane source is missing

The manuscript uses the membrane as a conceptual third example.

Its source is not included.

If it stays as supporting material, that is acceptable.

If it becomes a major comparison, include it.

---

## 5.19 Mirrored CA source identity has already improved, but registry copy remains older

The wrapper now explicitly says:

> mandala is not emergent; a fragment is computed and the rest copied.

That is excellent.

The registry still says:

> “symmetry is cheap” and “eye reads intention.”

The manuscript can retain aesthetic reflection, but operational source wording should remain primary.

---

## 5.20 Mirrored field uses a 21×21 grid, not 100×100 in the placed source

Some DNA commentary still discusses 10,000 cells / 5×5 motif tiled 400 times, apparently from an older/larger configuration.

The current `mirrored_cellular_automata.gd` export is:

> `grid_size = 21`.

The manuscript wisely avoids quoting those old 10,000-cell counts.

Clean registry/source commentary if it continues to be read as current measurement.

---

## 5.21 Rhizomatic network helper classes are not included

`RhizomaticMazeSpace.gd` instantiates global/helper classes by name.

Those implementations are absent from `sources/`.

Therefore exact claims about:

- minimum-spanning tree policy;
- rhizome connections;
- severed topology;
- graph edge storage;
- mesh generation;

cannot be independently inspected from this ZIP.

The source/registry comments describe them, but comments are weaker evidence than implementation.

---

## 5.22 Rhizomatic lesson mode is strongly configured and should be distinguished from the full artwork

When `config_lesson` is present, source sets:

- maze size 12×6×12;
- two vertical layers;
- zero secondary growth iterations;
- pinned seed 1337;
- topology `tree`;
- stripped debug/fog/navigation stage.

This is a deliberately reduced study, not the full default rhizomatic artwork.

The manuscript’s finite network comparison is therefore the right framing.

---

# 6. Spatial / curation findings

## PG Genetic Evolution

Spawn `(9,1)` → primary `(9,5)`.

Good.

The secondary science screen is at `(13,22)` and explicitly not wired to the genetic score.

No restructuring suggested.

---

## PG Space Colonization

Spawn `(9,1)` → primary `(9,5)`.

Very clean.

The retained rear structure is later and independent.

---

## PG Branching Growth

Spawn `(13,1)` → workshop `(13,3)` → primary growth `(8,10)` → organic-space secondary `(18,15)`.

This works if the workshop provides the staged field/readout described in technical notes.

The control-source omission prevents confirming the exact spatial binding.

---

## PG Percolation Network

Spawn `(13,1)` → workshop `(13,3)` → lattice primary `(10,11)`.

Good conceptual order.

Supporting dark-sphere material is later.

---

## PG Caves Mazes

As above:

> spawn → workshop → maze → cave.

This conflicts with manuscript cave-first order.

Highest-value spatial change in the sequence.

---

## PG Sculpted Forms

Spawn `(16,1)` → workshop `(16,3)`.

Primary mound `(8,11)` and dome `(22,12)` sit on opposite sides at nearly the same depth.

This is not necessarily a problem: the chapter can deliberately direct the visitor left/mound first and then right/dome.

Runtime sightline testing should confirm the dome does not visually dominate before the physical drop/sample experiment.

---

## PG Mirrored Patterns

Spawn `(16,1)` → workshop `(16,3)` → mirrored field `(8,10)` → network `(22,14)` → pattern tunnel `(14,22)`.

This largely supports manuscript order.

The main problem is curation/source completeness, not placement.

---

# 7. Runtime questions

No repository code was executed. Every hall still records `learner_verified: false`.

| Hall / encounter | RUNTIME TEST |
|---|---|
| **Whole sequence / workshop** | Include `pg_workshop.gd` and verify every chapter binding. Does each workshop discover only artifacts in its own hall, and do all six physical buttons call the intended study actions? |
| **Genetic — initial preference** | Before interacting, do rank/estimate/score labels pull visitors toward the machine’s leader rather than their own preference? If so, test delayed score display. |
| **Genetic — TARGET** | Do targets 8→16→32 rerank the same six genomes without generation change? Verify initial estimate/score numbers exactly. |
| **Genetic — RING** | Does torus appear on the current leader while estimate/score remain unchanged? Does remove restore exactly? |
| **Genetic — HOLD** | Does held genome remain visually independent through TARGET, STEP and RESET? |
| **Genetic — evolution** | With torus on an elite leader, can an elite copy visibly preserve that unscored torus into the next generation? |
| **Space Colonization — first step** | Do the three opening request vectors visually sum to the predicted vertical half-metre child? |
| **Space Colonization — TIPS** | With one root/eight-point field, does eligible-leaf replacement produce a strand with no forks? |
| **Space Colonization — NETWORK** | Does the same field/pinned beginning produce forks through older-site eligibility while never creating loops? |
| **Space Colonization — HOLD** | Does the 0.45-scale held witness preserve parent relations/proportions while live field/policy reset? |
| **Branching — workshop source** | Confirm the workshop explicitly suppresses jitter and pulse in opening mode, defines the eight fixed attractors and enables TEN STEPS/HOLD/VARIATION. |
| **Branching — duplicate records** | With variation off, reproduce cases where stored child count rises while distinct spatial positions do not. |
| **Branching — VARIATION** | Verify jitter/pulse can separate previously coincident children under the same target set. |
| **Branching — budget** | Does the workshop cap/report 192 stored branch records consistently with the underlying algorithm? |
| **Percolation — face/corner** | Verify the workshop’s two-cube CONTACT setup is using the same six-neighbour test as the full lattice rather than a separate illustrative rule. |
| **Percolation — DENSITY** | With pinned occupation draws, does changing .2/.4/.6 only change threshold/admission rather than resample? |
| **Percolation — STEP** | Does one button press advance exactly one synchronous CA generation despite the base artifact normally running in `_process`? |
| **Percolation — collision** | As cells become flowing/connected, is collision removed immediately/reliably enough that the visitor does not hit an invisible stale collider? |
| **Percolation — body route** | Does a signal path across the lattice ever correspond to a comfortably traversable human route, and where do the two diverge? |
| **Caves — spatial order** | From spawn, does the maze visually/physically become the first encounter before the cave? Test a cave-first restaging. |
| **Cave — TRACE** | Does TRACE accurately show all carve centres across all walkers without visually implying one continuous path? |
| **Cave — clearance** | Which generated openings actually admit the current desktop capsule and headset body under the 1 m voxel / 2-cell headroom construction? |
| **Cave — seed** | Does CAVE SEED rebuild under the same three-phase authored process while changing stochastic choices only? |
| **Maze — STEP** | Does workshop MAZE STEP perform one DFS generation step while preserving stack/readout? |
| **Maze — FINISH** | Does FINISH produce a valid entrance-to-exit array route for the pinned lesson seed/config? Attach the prior desktop check if quoted in the book. |
| **Maze — XR clearance** | Even with 1.5 m cells, are all corners/entrances comfortable in headset? |
| **Sculpted — DROP** | Are twelve cubes reliably visible/physical and can the visitor choose an obviously unfinished versus settled SAMPLE moment? |
| **Sculpted — SAMPLE** | Does generated mesh/collider use exactly the frozen centres and replace/disable original cube collision as expected? |
| **Sculpted — ORIGINAL** | While original cubes are visually restored, does sampled collider remain active as the manuscript says? |
| **Sculpted — VOXEL** | With same frozen centres, do different voxel sizes fill/remove openings in a clearly inspectable way? |
| **Dome — CUT** | Does CUT cycle cast/blank/core/section without losing the authored CSG baseline between states? |
| **Membrane** | Include source and verify that visible nested skins have the collision/interior relation the manuscript describes. |
| **Mirrored — HOLD/STENCIL** | Confirm workshop truly reapplies each stencil to the held array rather than generating a new random field. |
| **Mirrored — odd-grid seams** | Are centre-row/column asymmetries or rotational integer-address artifacts visible enough to support the implementation caveat? |
| **Mirrored — NETWORK** | Include helper classes/workshop; verify tree / connected / severed policies over the same fixed six-seed arrangement. |
| **Mirrored — graph counts** | Confirm reported undirected edge count, connected components and cycle rank are computed after duplicate directed records are deduplicated. |
| **Mirrored — SURFACE** | Verify collision is disabled in both skeleton and tunnel-surface lesson views, so the specimen remains observational rather than secretly walkable. |

---

# 8. What I would not cut

## Do not cut the visitor’s unrecorded personal choice in Genetic Evolution

The instrument’s inability to HOLD an arbitrary preferred candidate is conceptually useful.

It makes a limit of the evaluator/interface visible:

> what you value may not yet have a storage/selection channel.

Keep it.

---

## Do not fix the missing torus score silently before deciding whether to preserve the lesson

The torus omission is a genuine evaluator defect.

But it is also an exceptionally clear demonstration that:

> builder and evaluator read the same genome differently.

If the production evaluator is repaired later, preserve the lesson through another deliberate blind feature or an explicit old/new comparison.

---

## Do not cut the factor-of-eight box estimate

It is not “correct physics,” but the book correctly calls it a proxy rather than cubic metres.

Its mismatch is useful because it prevents fitness from appearing objective merely because it is numeric.

---

## Do not cut TIPS / NETWORK

They separate two operations that generic “space colonization” diagrams often collapse:

- which targets assign to a site;
- which sites remain eligible to answer again.

The strand/tree comparison is one of the sequence’s strongest controlled experiments.

---

## Do not cut the 0.45-scale held witness

The witness is explicitly a display-scale copy.

It prevents physical display size from masquerading as a change in generated proportions.

Keep the scaling disclaimer.

---

## Do not cut Branching’s duplicate-position failure

This is extremely valuable.

A stored parent can acquire another child while space acquires no distinct new position.

That is a sharp distinction between:

> data structure  
> and  
> visible geometry.

Keep it.

---

## Do not treat jitter/pulsing as “naturalising polish”

The manuscript correctly names them as explicit additional operations.

That makes the organic-looking result more accountable.

Keep that distinction.

---

## Do not cut the face-versus-corner contact comparison

It is the simplest possible embodiment of:

> neighbourhood is authored.

The full lattice then has something precise to inherit.

---

## Do not cut percolation collision removal

The flow is more interesting because it has another consequence:

> what conducts the signal stops resisting the body in this implementation.

Just keep reachability and traversability separate.

---

## Do not promote the source’s universal percolation-threshold claim into the manuscript

The current finite/seeded caveat is stronger.

Keep it.

---

## Do not cut Caves’ bias/headroom details as implementation clutter

Those details are exactly what stop the cave from being mythologised as “random nature.”

They are the construction.

---

## Do not cut maze backtracking

The stack is the mechanism that distinguishes:

> dead end  
> from  
> exhausted process.

It is a good continuation from L-system saved state.

---

## Do not cut the independent museum aisle/floor disclaimers

Generated geometry is not automatically the support that lets the visitor inspect it.

Those parallel supports make the body relation honest.

---

## Do not cut the local-coordinate conversion in Sculpted Forms

`to_local()` is doing real work.

Without it, the sampled mesh could double-apply museum placement.

This is a good return of Transformation/local-world coordinates.

---

## Do not cut the centre-based voxel approximation

The loss of rotation/contact geometry is the chapter.

The sample is productive and partial.

Keep it.

---

## Do not cut ORIGINAL’s collision mismatch

If runtime confirms it, this is an excellent demonstration:

> what you see as “original” can coexist with another active collision representation.

---

## Do not cut the dome operands

A subtraction is much easier to understand when the removed solids can be staged.

The hole becomes authored form.

Keep it.

---

## Do not cut the mirrored field’s odd-grid/integer caveats

They prevent “symmetry” from becoming a Platonic operation independent of implementation.

Keep them.

---

## Do not cut the network graph counts

Edges/components/cycles provide a separate account from the tunnel silhouette.

That is exactly what the final hall needs.

---

## Do not call the rhizomatic surface walkable until collision/clearance are deliberately enabled and tested

The current lesson disabling collision is a strength.

It lets topology/surface remain observational.

A later bodily route can be another experiment.

---

# 9. Reader-experience strengths to protect

## Discovery before naming

**Genetic**  
choose a preferred body before the criterion is explained.

**Space Colonization**  
predict the summed request before code.

**Branching**  
predict nearest-target step before a tree silhouette arrives.

**Percolation**  
face/corner contact before six-neighbour list.

**Caves**  
look for required bodily void before carve code.

**Sculpted**  
choose a sampling moment before the representation is built.

**Mirrored**  
see the held irregular field before copying operation is explained.

---

## Prediction before explanation

- Which candidate would you keep?
- Which way do three normalized requests sum?
- Which target will the root follow if only the nearest counts?
- Does corner contact conduct?
- Which cave restrictions survive a new seed?
- What does maze backtracking do at a dead end?
- Which opening will voxel resampling fill?
- Which graph policy creates a cycle or another component?

These are strong and should remain the sequence’s rhythm.

---

## Productive distinctions to protect

- visible body ≠ scored body
- numerical fitness ≠ value
- surviving feature ≠ rewarded feature
- attraction point ≠ simulated force
- request assignment ≠ responder eligibility
- stored branch record ≠ distinct spatial branch
- face contact ≠ corner contact under six-neighbour rule
- signal connectivity ≠ bodily access
- cave trace ≠ one continuous route
- array route ≠ comfortable VR interior
- physical event ≠ sampled representation
- cube centre ≠ cube orientation/contact geometry
- visual original ≠ active collision representation
- empty region ≠ unauthored nothing
- layered skin ≠ filled solid
- generated sample ≠ copied symmetric field
- directed stored edge records ≠ distinct undirected connection
- graph connectivity ≠ tunnel clearance
- tunnel surface ≠ collision-enabled passage.

This list is the real Procedural Generation curriculum.

---

# 10. Questions for the author

## 10.1 Is cave-first definitely the intended Caves/Mazes reading order?

The manuscript strongly benefits from it.

The current map strongly suggests maze-first from the entrance.

I would restage the hall unless the current physical order is deliberate.

---

## 10.2 Do you want Genetic Evolution to retain the intentionally broken evaluator?

As a research/tutorial object, it is excellent.

If the evaluator is repaired for broader use, consider keeping:

- a deliberate blind evaluator mode;
- or an old/new estimator comparison.

Otherwise one of the clearest sequence arguments disappears.

---

## 10.3 Is `pg_workshop_console` intentionally classified as decoration?

Functionally it is the lesson instrument for five halls.

If the role system can support:

> controller / pedagogical instrument

I would use that rather than decoration.

At minimum, source export must treat it as primary evidence.

---

## 10.4 Is Percolation meant to teach statistical criticality or only finite reachability under varied density?

The current manuscript teaches the second very well.

If critical phenomena are an intended scientific objective, add:

- citations;
- multiple seeds/sizes;
- an explicit estimator/finite-size framing.

Do not let the old identity imply the museum already demonstrates the infinite-lattice result.

---

## 10.5 Is the rhizomatic network here primarily a graph comparison or a Deleuzian architectural artwork?

The current chapter works best as a graph/surface construction comparison.

The broader rhizome discourse can remain attached to the full artwork elsewhere, but I would not let it substitute for the finite operations this lesson actually exposes.

---

## 10.6 Do you want the secondary layered membrane to become a true third primary in Sculpted Forms?

Conceptually it fits:

> sampled volume surface / Boolean subtraction / layered skins.

If it matters at that level, promote it and include the source.

If it remains a supporting comparison, the current short paragraph is enough.

---

# 11. Overall conclusion

Procedural Generation is one of the strongest sequence transitions in the current book because it no longer treats “generation” as a mysterious global property.

It decomposes world-making into inspectable operations:

- an evaluator decides which represented features matter;
- attraction points are assigned to eligible responders;
- another growth rule listens to only one nearest invitation;
- a neighbourhood definition decides whether contact counts as connection;
- a cave or maze turns path logic into bodily clearance;
- a physical event is sampled into another surface;
- subtraction gives absence explicit operands;
- copying reduces how much independent information a pattern contains;
- a graph policy decides components/cycles before a tunnel skin is built.

The strongest reader moments are places where a generated result appears to say more than its implementation can justify:

- a pink “best” body is best only under one proxy;
- an unscored ring survives selection;
- a tree-looking strand has never forked;
- a stored tree reports branches that occupy the same place;
- touching cubes are not neighbours under this rule;
- a successful flow path is not necessarily a human route;
- a “random cave” is heavily guided;
- a valid maze path still needs bodily clearance;
- a frozen pile and its sampled mesh share centres but not shape;
- a hole is the result of explicit cutting bodies;
- a mandala can be mostly copied information;
- a richly surfaced tunnel can conceal a simple graph—or fail to carry a body at all.

Those are excellent Ada moments.

The highest-value work now is therefore:

1. **include the shared `pg_workshop` lesson controller and its relevant helper classes in source-review bundles;**
2. **restage Caves/Mazes so the embodied cave question arrives before the maze if that remains the manuscript order;**
3. **update role metadata so all manuscript-promoted primary encounters are actually primary in curation/tooling;**
4. **remove universal criticality claims from Percolation metadata unless they are explicitly sourced and operationalised;**
5. **clean older “natural/autonomous/evolution without designer” artifact identities so they support the current accountable procedural descriptions;**
6. **headset-test the body-facing claims—percolation collision release, cave clearance, maze turns, sampled mound collision and any future tunnel traversal.**

The reader-experience principle I would carry forward from Procedural Generation is:

> **Let the generated form make one promise, then give the visitor the instrument that reveals which operation actually made that promise possible—or false.**

And the structural principle is:

> **A generated world is a chain of readers and constraints. A form can be selected, grown, connected, carved, sampled or copied without yet becoming a place that a particular body can use.**
