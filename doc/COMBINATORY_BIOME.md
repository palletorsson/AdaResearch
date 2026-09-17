# The Combinatory Biome — the world is made of what you have learned so far

> Design memo, 2026-09-17. Written from a conversation with Palle, occasioned by
> *Dream-RSI: Recursive Self-Improvement through Evolving Worlds* (Zheng et al.,
> arXiv:2609.14858, 14 Sep 2026) and by the encyclopedia's fractal database
> (`localhost:3003/fractal`, `/blog/fractal-database`). Nothing here is built yet.
> The sieve pass is at the end; the recorded copy is under `doc/sieve_passes/`.
>
> Scope: `algorithms/nature_system/`, `commons/maps/soft_stages.json`, the catalyst
> bracelet, one tool, one room per threshold. It does not touch `GridSystem.gd`.

---

## 1. The dream

Palle, 2026-09-17: *"I dream of having the game — an evolving biome. How does the
biome look with points, lines, triangles as primitives combined; then with
transformation, and in combination; add colour, add arrays, combine, dream, next
sequence, randomness, noise. What can we build with what we have in combination,
what things cannot be combined, paths that are stale if any, what is sufficient,
what happens to the work if we add cellular automata, L-systems and still let it
evolve; the softbodies; and then the crises maps."*

Ada already introduces what the world is made of subject by subject. The biome is
where that can become **literal**: the living ring around hall *k* is built from
exactly the operators the visitor has been shown up to *k*, and it evolves. The game
is the evolution of what the visitor can compose. Each sequence is one round of a
three-beat loop:

| beat | the biome | the paper (Dream-RSI) |
|---|---|---|
| **combine** | evolve a population over the unlocked vocabulary | online exploration with the current policy |
| **dream** | replay the recorded lineages: what was stale, sufficient, unreachable — and what would have grown | offline "dreaming" over the discovery trees |
| **next** | unlock the next sequence's operators | adopt the improved policy, round *t+1* |

The sequence index *is* the paper's round number.

---

## 2. Three borrowed ideas, and the one rule that binds them

**Dream-RSI.** Keep every attempt as a node in a scored discovery tree; treat the
recorded trees as a replay world; evaluate alternative exploration policies by
replaying them over that world (score = best find − β₁·reveals + β₂·batch); adopt the
best; repeat. The doer is untouched — a thin layer above it decides where to look
next. Two nouns come with it: **a history is a world you can walk again**, and **a
policy is a thing you can hold separately from the doer**.

**The fractal database.** The project as a tree walkable at any depth, seven lenses,
cost measured in tokens per correct answer. Its own limitations name the gap the
paper fills — *"which fold at which depth produces a correct answer with the fewest
tokens?"* — and the wall both hit: *"edges are not folded; folding a graph is an
open problem."* Dream-RSI's discovery tree has one primary parent per node. The
biome does not (see §7).

**The bracelet garden memo** (`doc/BRACELET_GARDEN_MODIFIERS.md`). Placing is
tending λ; the grid has a felt state, *never a score*; removal is compost; patina is
memory. This is the rule that binds: **the dream shows, it never rates.** The paper's
objective is a number for the agent; the visitor sees three gardens and no number.

---

## 3. The vocabulary ladder

`commons/maps/soft_stages.json` already gates the biome by sequence — *"allow flags
and hand verbs are cumulative across completed stages"* — with kingdoms and
vegetation density per stage. What it lacks is the **operators**: the things a body
can be made *of*, typed, so that "what we have so far" is a fact and not a feeling.

| spine | sequence | operators added (typed, §4) | soft_stages today | the biome can newly be | what becomes askable |
|---|---|---|---|---|---|
| 1 | primitives | `point`, `line(p,p)`, `triangle(p,p,p)`, `plane` | static_geometry, grey_palette; no kingdoms, density 0 | stick-and-vertex bodies, flat leaves, grey | how many bodies exist at depth 3? |
| 2 | transformation | `translate`, `rotate`, `scale`, `compose(t,t)`, `mirror` | static_movement | limbs, symmetry, posture | does order matter? (it does — non-commuting) |
| 3 | array_tutorial | `index`, `repeat(n)`, `lattice` | arrays; flower + tree, 0.2 | segments, rings, rows of petals | which repeats survive, which are noise? |
| 4 | color | `palette`, `gradient(c,c)`, `tint` | color; flower, 0.1 | plumage, bark tone | is colour a gene or a habit? |
| 5 | tiling | `tile(surface, rule)`, `wallpaper_group` | *(missing — see §8)* | scales, mosaic hide | which symmetries are cheap? |
| 6 | change | `rate(x)`, `accumulate` | function_visualization, rate_arrows | growth curves, ageing | what is the derivative of a body? |
| 7 | forces | `push`, `spring`, `gravity` | force; flower + tree, 0.15 | sag, weight, recoil | which static forms die once things move? |
| 8 | formfinding | `relax(energy)` | *(missing — see §8)* | hanging chains, minimal leaves | what shape does a body take when it stops trying? |
| 9 | wavefunctions | `oscillate(f,a)` | sine_wave; 0.25 | breathing, swaying, phase | do two oscillators become one organism? |
| 10 | randomness | `sample(dist, seed)` | random_placement, random_variation; fungus arrives, 0.3 | variation within a kind | is a seed a gene? |
| 11 | noise | `field(noise)` | noise_terrain, noise_voxels; 0.4 | camouflage, terrain-fitted bodies | which bodies are the terrain? |
| 12 | cellularautomata | `rule(neighbourhood)` | growth, game_of_life; 0.5 | grown skins, colonies | what did a rule make possible that composition never did? |
| 13 | fractals | `recurse(op, depth)` | fractal_flora, fractal_terrain; 0.6 | infinite edge, bark | how much depth does a body need? |
| 14 | lsystems | `rewrite(grammar)` | lsystem_*; creature kingdom arrives, 0.7 | branching, articulated limbs | can a grammar be inherited? |
| 15 | proceduralgeneration | `constrain(WFC)`, `markov` | self_generating_world; 0.8 | bodies that fit their neighbours | what is a body's constraint set? |
| 16 | softbodies | `deform(mass, spring)`, `turing(react, diffuse)` | morphogenesis, soft_matter; 0.85 | flesh, spots, stripes | which earlier bodies become obsolete? |
| 17 | isosurfaces | `implicit(field) → surface` | field_volumes (at 4.6 today — §8) | smooth unions, blobs | do fields replace triangles? |
| 18 | boolean_surfaces | `union`, `subtract`, `intersect` | composed_solids (at 4.7 today — §8) | holes, sockets, shells | what is subtraction in a lineage? |
| 19 | swarmintelligence | `local_rule(neighbours)`, `stigmergy` | swarm_behavior, flocking; 0.9 | herds, trails | is the herd the organism? |
| 20 | machinelearning | `select(fitness)`, `learn` | adaptive_evolution, mutation; 0.95 | learned niches | who chooses the fitness? |
| 21 | graphtheory | `connect(a,b)` | connection_topology, network_world; 1.0 | rhizomes, mycelium | the tree of lineages is a graph — it always was (§7) |
| 22 | foundationscrisis | *the limits* | contradiction, paradox_terrain; 0.9 | a fitness that cannot decide; a genome that names the population | what can the dream not replay? |
| 23 | qfeplaboratory | `tune(λ, F, E, φ)` | tunable_becoming, parameter_world | the biome with its dials exposed | which dial is the visitor? |
| 24 | postfoundationscrisis | *applied limits* | applied_limits | bias made visible in what survived | whose fitness was it? |

The operators are proposals; the typed grammar in §4 is what makes the table
checkable. Every row's "askable" question is a dream-tool query (§6), not prose.

---

## 4. The genome: expression trees over the unlocked operators

Today a critter's genome is `CritterDNA`: some forty typed float genes (body_type,
segments, symmetry, pattern, roughness, mobility, aggression, branch_angle,
phyllotaxis, inflorescence, root_type, scent…), three colours, and — already —
`generation`, `parent_a_id`, `parent_b_id`, `mutations[]`. The morphology router
dispatches on kingdom (tree / walker / flower / fungus / hybrid) and blends
hybrids gene-wise. It is a **parametric** genome: it can vary a body, it cannot
*compose* one.

`GeneticProgramming` (`algorithms/proceduralgeneration/growth_systems/genetic_programming/`,
registered in `alphabet_grammar.json`) already has the other half: genomes as
**expression trees** with `genome_type ∈ {Primitives, CSG_Tree, Parametric, Voxel,
L_System}`, `max_depth`, crossover and mutation on trees, and the identity line
*"evolution does not design — it accumulates accidents that happen to survive."*
It lives in one artifact in one hall.

The combinatory biome lifts that into the biome as a **two-layer genome**:

- **the tree** — what operators, composed how: `union(recurse(line, 3), tint(triangle, palette₂))`. Nodes are drawn only from the operators unlocked at the visitor's completed stages (the ladder, §3).
- **the genes** — `CritterDNA` as today, the parameters of the leaves (lengths, angles, colours, behaviour). Kingdom routing and hybrid blending stay as they are.

A **typed grammar** makes "cannot be combined" a static fact:

```
types:      Point · Curve · Surface · Solid · Field · Colour · Rule · Motion · Grammar
line:       Point × Point → Curve
triangle:   Point × Point × Point → Surface
translate:  T × Motion → T                (any geometric T)
tint:       Surface | Solid × Colour → same
repeat:     T × int → T
rate:       Motion → Motion               (a derivative of a static Point is refused)
implicit:   Field → Surface
union:      Solid × Solid → Solid         (a Curve has no inside — refused)
rule:       Surface × Rule → Surface
rewrite:    Grammar → Curve | Solid
deform:     Solid × Field → Solid
```

Refusals of the first kind are typed and known before any run. Refusals of the
second kind — well-typed combinations that never survive a generation — can only be
read off the record (§5). Keeping the two apart is the whole point of recording.

---

## 5. The record: `ada_run/biome_lineage.jsonl`

`EvolutionSystem` keeps `_generation_history` in memory and forgets it at exit. The
dream needs the lineage on disk. One line per organism, append-only, **derived**
(never edited, like everything under `ada_run/`):

```json
{"id":"c_01f3","session":"…","stage":"randomness","stage_order":7,"hall":"Random_Walk",
 "generation":12,"parents":["c_00a9","c_00c2"],"tree":"tint(repeat(line,6),gradient)",
 "ops":["line","repeat","tint","gradient"],"genes":"sha1…","fitness_fn":"default",
 "fitness":0.61,"seed":1982044,"fate":"bred|culled|survived","t":"2026-09-17T09:31:04"}
```

Two fields are not optional:

- **`seed`** — the RNG state per generation. The paper's replay is exact because a
  recorded node's outcome never changes. Ours re-runs a simulation (§6, counterfactual),
  and it is only a *replay* if the randomness is the same randomness.
- **`fitness_fn`** — the fitness is pluggable (`_default_fitness`: survival, energy,
  engagement). A survivor under one pressure is a corpse under another; the record
  must say which pressure it lived under, or "stale" means nothing.

Two parents, not one. The paper's tree has a primary parent; `CritterDNA` has two and
breeds across kingdoms. The lineage is a DAG from generation one. §7.

---

## 6. The dream: `tools/dream_biome.py`

Palle's questions, each an exact computation over the record:

| question | computation | kind |
|---|---|---|
| **what can we build with what we have** | the closure: every well-typed tree of depth ≤ *d* over the operators unlocked at stage *k*; count, sample, render a sheet | static (grammar) |
| **what cannot be combined** | (a) typed refusals from §4; (b) well-typed trees that occur in the record and never reach `fate: survived` in *n* generations — listed separately, because (b) may be a fact about the fitness, not the world | static + empirical |
| **stale paths** | operators present in the record that occur in no survivor after *n* generations; lineages with no living descendant. The paper's test applies exactly: a policy that never expanded them loses nothing in replay | empirical |
| **what is sufficient** | the smallest operator subset whose closure still covers the survivor phenotypes (greedy set cover — say it is approximate). This is the paper's reveal-cost term applied to *vocabulary* | empirical |
| **add CA / L-systems and still let it evolve** | counterfactual: take the recorded population at stage *k*, inject the operator, re-evolve with the recorded seeds, compare survivors. The one thing the paper's frozen tree cannot do; here it can, because a generation of critters is cheaper than a visitor's walk | re-run |
| **the crises** | the queries that fail: a fitness that references the population's own average (undecidable), a genome that names the biome (self-membership), a lineage the DAG cannot order. The tool reports *why* it cannot answer | limit |

Output is a report under `ada_run/` and — for the visitor — three gardens (§7),
never a table.

---

## 7. The rooms

**The cage** (built 2026-09-17 — `commons/artifacts/biome_vitrine`, Palle: *"a room with
a glass large cage with an open ceiling"*). The biome was the ring *around* a grid map;
the endless museum builds no ring. So the biome is contained instead: a glass cage in
the middle of a room, four panes, two doorways, no roof, and inside it the stage's
biome built by the **current implementation** — the patch is painted with the stage's
kingdoms at the stage's density and every cell goes through `BiomePaintDispatcher` at
that stage's order (locked kingdoms render as coloured cubes, the seeds of what is to
come); live creatures come through `CritterSpawner` and evolve under `EvolutionSystem`;
a `PresenceGrid` — written but gated off in the grid lane — remembers every organism and
glows through the floor (tree green, creature amber, flower blue, fungus violet); a stand
screen states the cage; the state is written to `ada_run/biome_vitrines.json`. One word,
`stage`, moves it along the spine: coloured cubes at primitives, the first flower at
colour, fungus at randomness, live creatures at L-systems. `commons/maps/Biome_Cage` is
the first room, dealt in the museum as the randomness pearl *biome cage*; the ring's
ground-cover recipe was extracted to `commons/biome_layers/ground_cover.gd` so cage and
ring scatter the same plants (the ring is unchanged: `probe_ring_refactor.gd`, 176/176).

**The ring, later.** Growing outwards from the cage is the ring code inverted (§7,
"growing outwards" below); the ring's own gating by `soft_stages.json` stands as it is.

**The ladder, strict** (built 2026-09-17, later the same day — Palle: *"the first biome
might just be one point we can move… how strict can we be?"*). Strict, and computable.
`commons/data/biome_vocabulary.json` gives every primitives hall its words in three
columns — *made of* (point → line → lattice → face → solid → sphere → subdivide →
ornament), *does* (hand from the first hall; self-motion from the animated cube; by rule
from transformation; selection only from machinelearning), *knows* (the trace from
Point_Trace; counts from arrays) — and every later sequence its words; each hall also
carries its own `line` and a `beyond`, what the biome may say past what the hall wrote
("you arrive late"). `commons/biome_layers/biome_grammar.gd` folds them into a cumulative
closure along the walk (spine order, then `map_authored.json` order within a sequence).
The cage reads a hall name, a sequence, or `hall`; before colour it builds the grey
grammar — Point_One is one grey point you can pick up and put down — and from colour on
the painted kingdoms. `commons/maps/Biome_Ladder_Primitives` shows the ten cages along
an aisle as the last primitives pearl. Two exceptions keep it from being sterile: the
visitor's hand is always allowed, and the cage and its screen are furniture, not biome.
The vocabulary's later-sequence entries are a first draft for each sequence's owner to
rewrite; the gate only reads them.

**Transformation and colour** (037bcb38d, the same afternoon). The grammar persists and
gains what the bodies may *do*: Trans_Pre's cube you can take (the solids become
pickables), Trans_Introduction's movement left running, a carrier that slides, a bar
turning about one end, a body that pulses, a post the height of you, a wall that arrives
and — once `compose` — turns. Colour reaches the bodies first (Color_Context_Placed),
then lamps make pools (Flashlight), then the point you move takes a colour (Nails), then
the first flowers with the rainbow (Rainbow — `flower` is a word now, and the painted
patch opens on kingdom words, not on soft_stages' per-sequence list), a gradient on the
lattice (Pillar), a colour per face's address (Grid_Pallet), the floor's memory in colour
(Paint), tinted glass (Walls), and Chamber's `when`. Rooms `Biome_Ladder_Transformation`
and `Biome_Ladder_Color` stand as the last pearls of their chapters. Probe 142/142.

**The dream room.** One per threshold — or the museum's night (`[em-night] the moon
is the light… one circuit every 480 s` already exists in the endless museum). Three
gardens stand side by side: *as grown*, *the sufficient subset only*, and *the
counterfactual* (what would have grown had the next operator arrived one sequence
earlier). No numbers. Stale lineages stand as patina — weathered, not deleted;
compost, per the bracelet memo.

**The crises.** At `foundationscrisis` (`contradiction`, `paradox_terrain`) the
dream fails on purpose and shows the failure: a garden whose fitness is its own
average oscillates and never settles; a genome that names the population grows
something the type system cannot place; and the lineage display — a tree until now
by courtesy — is drawn as what it always was, a graph with two parents per node and
cross-kingdom edges. The fractal database and Dream-RSI hit this same wall
(*"folding a graph is an open problem"*; discovery trees have one parent). At
sequence 21–24 Ada shows the wall from inside.

**The catalyst.** Fourteen modes, one per subject, already put an operator in the
visitor's hand. A fourth stone — the *policy*: breadth, greed, batch — makes the
bracelet mode × policy: not only *what* you place, but *how you look for the next
thing to place*. That is the paper's second noun, held.

---

## 8. What exists, what is missing, what is wrong today

| | |
|---|---|
| **exists** | `soft_stages.json` cumulative gating by stage; `CritterDNA` genes + parents + generation + mutations; `EvolutionSystem` tournament/crossover/mutation/cull with pluggable fitness and cross-kingdom hybrids; `morphology_router` kingdom dispatch; SDF combinators (`MORPHOLOGY_ENGINE.md`); `GeneticProgramming` tree genomes; the catalyst's 14 modes; the museum's night; **since 2026-09-17:** the cage (`biome_vitrine`, any stage by one word, evolution on, presence floor, state file `ada_run/biome_vitrines.json`), the room `Biome_Cage` dealt as a randomness pearl, `ground_cover.gd` shared by ring and cage, the `stage` DNA axis (27 values) |
| **missing** | operators per stage (typed); the tree layer of the genome in the biome; the lineage log with seeds and fitness names; `dream_biome.py`; the cage's query rack (STAGE / GEN scrub) and an `/api/biome/vitrine` reader in the encyclopedia; the dream room; policy as a bracelet stone |
| **wrong today** | `soft_stages.json` lags `curriculum_spine.json`: no `tiling` (spine 5), no `formfinding` (spine 8); `isosurfaces` and `boolean_surfaces` sit at 4.6/4.7 where the spine has them at 17/18; `mosaicanalysis`, `resourcemanagement`, `biome_lab` are stages with no spine slot. The ladder must be keyed to the spine's order, and the sync is the first commit |

---

## 9. Steps, smallest first

_Done 2026-09-17 (commits 48d88ce95, c303cef84): the cage artifact with evolution, presence
floor and state file; the room `Biome_Cage` dealt as a randomness pearl; the ring's ground
cover shared; probes 73/73 and 176/176. The steps below are what remains._

0. **The colonnade knows a body by one cell.** `tools/em_map_halls.py` stamps the templates'
   pier colonnade into every bare map-authored hall, "never on or beside a body" — but a
   body is its token cell, so four piers stood inside the 8 × 8 cage. Today's fix is a
   declaration (`map_info.museum.piers: false`, honoured by the tool, absent = as before);
   the general fix is to keep piers off a body's registry footprint (`parameters.footprint`),
   which needs the tool to read the registry. Any large case (tier_terrarium, the glass
   arenas) has the same exposure.
1. **Sync `soft_stages.json` to the spine** (add tiling, formfinding; move iso/boolean; keep the extras as off-spine stages) and add `operators` per stage from §3. Post to the forum first — the file is read by three managers.
2. **Lineage log**: `EvolutionSystem` appends to `ada_run/biome_lineage.jsonl` with seed and fitness name. No behaviour change.
3. **`tools/dream_biome.py`, read-only questions**: reachable, refused, stale, sufficient. Runs on the log alone.
4. **The tree layer** of the genome, lifted from `GeneticProgramming`, gated by the operators; genes unchanged; kingdom routing unchanged.
5. **Counterfactual re-evolve** (seeded, headless — the biome's `MultiMesh` bodies read back as identity under `--headless`, so any probe that *looks* must run with the real renderer).
6. **The dream room** at one threshold (randomness → noise is the natural first: fungus arrives, variation becomes camouflage).
7. **The crises** behaviour, last — it needs 1–6 to have something to break.

---

## 10. Sieve pass

_Target: this memo — the combinatory biome as a design. Occasioned by Palle's
"see what I mean". Change made during the walk: the `soft_stages` / spine
discrepancy in §8 was found while building the ladder and is now step 1._

### 1. Does this thicken the cognitive water?

**It gives the spine a body.** "What the world is made of, subject by subject" is
today a syllabus order and a density number. An operator ladder with typed
signatures makes it a *thing that can be composed*, and the ring around each hall a
population of compositions the visitor can recognise as made of what they were just
shown. That is a new relational handle: a body's tree can be read back to the
sequences that made it possible.

**It makes "history" a second object.** The biome's evolution already happens; it
leaves nothing behind. A lineage on disk with seeds and fitness names turns every
walk into a world that can be walked again — stale, sufficient, unreachable become
questions with answers rather than moods. The paper's contribution, kept: the doer
is untouched, a thin layer records and dreams.

**It joins three things that were apart.** The bracelet memo (tending λ), the fractal
database (a tree at any depth, and its limit), and `GeneticProgramming` (trees as
genomes, in one hall) become one loop. The crisis sequences get a concrete object
to break — a lineage that was a graph all along — instead of a metaphor.

### 2. What is foreclosed?

**The score, deliberately.** A replay objective is a number, and once a garden has a
number the game is "rate my garden". The memo forecloses it for the visitor: three
gardens, no figure. The agents keep the number (`dream_biome.py` reports it); the
rooms never do. This must hold at the fitness function too — a visitor-visible
fitness is a score wearing a lab coat.

**The cheap ring.** A parametric genome is one mesh build; a tree genome is a
composition, and the museum already warns when a body takes 130 ms to build (a
dropped frame in the hall). Composing bodies at density 0.9 forecloses some of the
biome's present cheapness; the ladder's depth bound *d* is the budget, and it must
be stated as one.

**Walking out of order.** If the vocabulary were keyed to *position* on the spine, a
visitor who picks `color` from the menu first would stand in a ring made of things
they were never shown. `soft_stages` already defines "so far" as **completed
stages**, cumulative — the memo keeps that definition, so the foreclosure is only
apparent, but it must not be re-keyed to position by a later hand.

**Typed refusals foreclose some ugliness.** A grammar that refuses `union(line,
line)` also refuses the accident that might have been interesting. The typing is
kept minimal (nine types) and every refusal is listed as a refusal, not silently
dropped, so the foreclosure is visible and revisable.

### 3. What lives in the dark spot?

**Empirical "cannot be combined" may be a fact about the fitness, not the world.**
A well-typed tree that never survives under `_default_fitness` (survival, energy,
engagement) might thrive under another pressure. The record carries the fitness
name precisely so the dark spot stays open: the tool must say "never survived
*under X*", and the counterfactual must be runnable under Y. Sealing this — calling
a combination impossible because one fitness culled it — would be the sterilising
seal.

**The lineage is not a tree.** Two parents, cross-kingdom breeding: a DAG from
generation one. The paper's method, the fractal fold and the dream room's "three
gardens" all assume a tree. What the encoding hides is that every "stale path" and
"sufficient subset" is computed on a projection. Generative if shown (§7, the
crises); sterilising if the projection is taken for the thing.

**What the record does not carry.** The visitor's attention (which bodies they
looked at — the bracelet memo's "player engagement" is in the fitness but not in the
log), patina (non-genetic state, the grid's memory of care), and the trees of
*other* visitors on other machines (`res://` is read-only on the headset; the log
lives in `user://` there and comes back only by USB). The dream is of *this*
walker's world. That is a habitat, not a seal — as long as the tool names whose
history it dreamed.

---

## References

- Zheng et al., *Dream-RSI: Recursive Self-Improvement through Evolving Worlds*, arXiv:2609.14858 (2026) — discovery trees, replay simulator, the dreaming objective.
- `ada_encyclopedia/src/content/blog/fractal-database.md` — the fold, the dual-agent experiment, the stated limitations.
- `doc/BRACELET_GARDEN_MODIFIERS.md` — tending λ, no score, compost, patina.
- `doc/NATURE_SYSTEM_PLAN.md`, `doc/MORPHOLOGY_ENGINE.md` — kingdoms, discrete traits, SDF combinators.
- `commons/maps/soft_stages.json` — cumulative gating by completed stage.
- `algorithms/nature_system/dna/critter_dna.gd`, `systems/evolution_system.gd`, `systems/morphology_router.gd`.
- `algorithms/proceduralgeneration/growth_systems/genetic_programming/` — tree genomes.
- `commons/hazards/becoming_catalyst/modes/` — fourteen modes, one per subject.
- Blog: `/blog/2026-09-17-the-biome-dreams`.
