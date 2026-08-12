# Ada Research — Canonical Spatial Build Pipeline

> **Status: canonical architecture + agent-work protocol.**
>
> Read this before adding a new map generator, placement heuristic, artifact spatial schema, museum composition system, or agent-specific README describing how spatial generation works.
>
> Ada Research is now too large for a single LLM session to safely hold as implicit context. The repository, not the context window, must be the project's durable memory.

---

## 0. The problem this document solves

The project has repeatedly reached useful spatial ideas and then rediscovered them in later Claude/Codex sessions under different names. This is not primarily a code-generation failure. It is a **context and memory architecture failure**.

Several generations of work are already present:

```text
hand placement
    -> measured footprints / AABB
    -> spatial_needs
    -> grammar + A* spatial intelligence
    -> spine_hints() artifact contract
    -> dressing-room micro-scenes
    -> spatial_profile derivation
    -> structure-only / placement-only research
    -> [NOW] one documented pipeline + bounded agent sessions
```

A later agent often reads the files closest to its current task—especially local README/CLAUDE/agent notes—and mistakes that local description for the architecture of the whole project. It then adds a new abstraction rather than recovering the existing lineage.

The correction is:

> **No agent is expected to remember Ada Research. The repository must make the relevant slice recoverable.**

And:

> **A session should be small enough that its complete problem, evidence, implementation and validation can remain coherent at the same time.**

---

# PART I — WHAT WE ARE BUILDING

## 1. Ada Research needs a spatial compiler

The goal is not merely an automatic museum generator.

The input is conceptual:

- sequences and curriculum;
- artifacts and DNA/lineage;
- relationships and teaching order;
- authored spatial intentions.

The output is experiential:

- a navigable 3D/VR environment;
- sufficient physical space around artifacts;
- correct approach, reading and interaction distance;
- coherent architecture;
- explicit validation that the result works.

The central rule is:

> **The artifact speaks first about what it needs. Architecture responds. Neither owns the whole problem.**

The system separates six questions:

1. **What should be encountered?** — sequence / atlas / curriculum.
2. **What does each artifact require?** — measurement, metadata, dynamic hints, staging.
3. **What spatial topology should organize the encounter?** — architecture grammar.
4. **Where can each staged artifact legally fit?** — negotiation / constraint solving.
5. **How is the accepted plan assembled?** — map layers + modular 3D architecture.
6. **Does the result actually work?** — pathfinding, accessibility, visibility, interaction, performance, capture and critique.

## 2. Canonical pipeline

```text
CONTENT / ONTOLOGY
sequence / curriculum / atlas / DNA / relationships
        |
        v
EXHIBITION BRIEF
ordered artifact IDs + conceptual priorities
        |
        v
ARTIFACT KNOWLEDGE
scene geometry + registry + measured AABB + dynamic hints
        |
        v
CANONICAL SPATIAL CONTRACT
body mask + access mask + presentation mask + legal placement modes
        |
        v
DRESSING ROOM
reusable micro-scene: footing + anchor + approach + exit + extras
        |
        v
ARCHITECTURE GRAMMAR
rooms + corridors + walls + openings + placement surfaces
        |
        v
NEGOTIATOR / SOLVER
slot -> rotation -> mode -> alternate slot -> resize -> explicit failure
        |
        +---------------------+
        |                     |
        v                     v
FLOOR OCCUPANCY         WALL OCCUPANCY
X/Z cells               wall-U / Y surface
        |                     |
        +----------+----------+
                   v
ASSEMBLY
structure + utilities + interactables + modular museum geometry
                   |
                   v
GODOT RUNTIME
                   |
                   v
VALIDATION
reachability + clearance + visibility + interaction + performance
                   |
                   v
CAPTURE / CRITIQUE
                   |
                   +---------- feedback ----------> artifact / solver / grammar
```

This is a feedback pipeline, not a one-shot generator.

---

# PART II — ONE FACT, ONE AUTHORITY

## 3. Spatial ownership hierarchy

Previous sessions produced several overlapping representations. Treat them as a hierarchy, not as competing architectures.

### Measured AABB

**Owns:** observed geometry.

AABB is evidence, not preference.

Relevant tooling includes `tools/measure_artifact_aabbs.py` and earlier footprint-detection work.

### `spatial_profile`

**Owns:** automatically inferred placement characteristics when no stronger authored information exists.

Typical fields include direction group, range, density, minimum clearance, stack priority and approach direction.

Relevant tool: `tools/derive_spatial_profile.py`.

### `spatial_needs`

**Owns:** durable registry-level spatial defaults and semantic requirements.

Existing vocabulary includes platform, footprint cells, clearance, wall backing, isolation, clustering and preferred zone.

Do not create a second registry vocabulary for the same facts.

### `spine_hints()`

**Owns:** dynamic/runtime hints that cannot reliably be represented statically, plus lightweight artifact-local fallbacks.

The existing contract includes role, footprint, approach, reading distance, height, rotation, budget and tags.

`spine_hints()` is a **provider into the spatial contract**, not an independent map-generation architecture.

See `doc/SPINE_HINTS_CONTRACT.md`.

### Dressing room

**Owns:** the strongest reusable static staging solution for an artifact.

A dressing room may specify:

- footing;
- artifact anchor;
- legal rotations;
- approach and exit;
- clearance;
- labels and tutorial panels;
- lights and local supporting elements;
- fine positioning.

See `doc/DRESSING_ROOM_SCHEMA.md` and `commons/artifacts/dressing_rooms/`.

### Sequence / atlas

**Owns:** which artifacts belong together and their conceptual/teaching order.

It does **not** own exact x/z placement.

### Architecture grammar

**Owns:** topology: rooms, corridors, walls, openings, boundaries, architectural rhythm and available placement surfaces.

It does **not** silently violate artifact staging requirements.

### Negotiator / solver

**Owns:** placement decisions.

It matches staged artifact requirements against architectural opportunities and records why decisions succeed or fail.

### Assembler

**Owns:** translating an accepted plan into map layers and modular 3D geometry.

### Validator

**Owns:** accept/reject evidence.

Generation completing is not proof that the map is good.

## 4. Resolution order

Resolve artifact spatial knowledge in this order:

```text
measured scene geometry
        |
        v
registry spatial defaults / spatial_profile
        |
        v
spine_hints() dynamic overrides where applicable
        |
        v
auto-generated default dressing room
        |
        v
human/research-refined dressing room
        |
        v
canonical staged artifact unit
```

Desired relationship:

```text
AABB -> spatial_profile -> default dressing room -> authored dressing room
                 ^
                 |
          spatial_needs
                 ^
                 |
          spine_hints() when dynamic
```

A stronger layer may refine a weaker one. It should not duplicate the same fact without documenting why.

---

# PART III — THE DRESSING ROOM AND THE SOLVER

## 5. Why dressing rooms are central

The April composer work reached the clearest division of responsibility in the history of this system:

> **Staging decisions go DOWN to the artifact level; layout goes UP into a constraint-routing problem.**

```text
ATLAS / SEQUENCE
chooses WHAT
      |
      v
DRESSING ROOM
specifies HOW it must be staged
      |
      v
COMPOSER / NEGOTIATOR
solves WHERE and routes circulation
```

A dressing room is more expressive than a scalar profile. A profile can say:

```text
panel / front approach / 2m reading range
```

A dressing room can say:

```text
this micro-layout
artifact here
plinth here
player enters here
label here
light here
these rotations are legal
```

Therefore do **not** replace dressing rooms with `spatial_profile`. Use profiles and hints to bootstrap them.

## 6. Representation is not the solver

`tools/map_composer.py` demonstrates the dressing-room architecture, but its historical placement strategy is deliberately simple: rooms are distributed approximately along the spawn-to-teleport direction, rotated, nudged to avoid overlap, and then connected with A*.

Therefore:

> **A bad map from a prototype solver is evidence about the solver, not evidence that the dressing-room representation failed.**

Solvers are replaceable. The spatial contract should survive solver replacement.

## 7. Two research modes

Both modes are useful and must remain distinguishable.

### Architecture-first research

```text
grammar -> floor plan -> candidate surfaces -> artifact placement
```

Use this to investigate topology and architectural language.

### Artifact-context-first production

```text
artifact -> dressing room -> reserve staged units -> route architecture between them
```

Use this as the dominant model for the Endless Museum and other content-led sequences.

## 8. Structure research is not placement research

### Structure research

Hold artifact requirements stable and vary topology/architecture.

Relevant systems include `tools/spine_auto_research.py` and map grammar tooling.

### Placement research

Hold architecture stable and re-solve artifact positions.

Relevant system: `tools/spine_placement_only.py`.

If both mutate simultaneously, the result becomes difficult to interpret and difficult for a later agent to continue.

---

# PART IV — CONTEXT-BUDGET DOCTRINE

## 9. The context window is working memory, not project memory

Claude, Codex and similar agents can read a great deal of material, but the dangerous assumption is:

> "If it fits in the context window, the agent understands it as one coherent system."

That is not a safe engineering assumption.

Large contexts develop practical failure modes long before a hard token limit is reached:

- early architectural constraints lose salience;
- recent local files dominate older canonical decisions;
- similar systems become conflated;
- an agent remembers conclusions but loses the evidence for them;
- tool output and debugging noise displace the original goal;
- the agent begins optimizing the implementation it most recently touched;
- README files written by previous agents become self-reinforcing local realities;
- the session continues because tokens remain, even though conceptual coherence is already degrading.

Therefore Ada Research should optimize for **recoverability**, not maximum context occupancy.

## 10. How much work should one agent session hold?

Do not define session size primarily by token count or number of hours. Define it by **number of simultaneously live decisions**.

### Default maximum: one vertical slice

A healthy implementation session should normally contain:

```text
ONE goal
ONE primary abstraction or subsystem
ONE bounded set of files
ONE before-state
ONE implementation hypothesis
ONE validation loop
ONE durable handoff
```

Examples of appropriate sessions:

- make three selected artifacts produce valid spatial contracts;
- improve candidate-slot generation without changing artifact schemas;
- implement wall occupancy for one wall-artifact test case;
- replace `place_rooms()` while keeping the dressing-room format fixed;
- add diagnostic rendering for body/access/presentation masks;
- audit whether `spatial_needs` and `spatial_profile` conflict for 20 featured artifacts.

Examples that are **too large for one session**:

- "finish the Endless Museum";
- "understand all artifact placement and improve it";
- "clean up the registry and rewrite the composer";
- "make all 1700 artifacts AAA and place them correctly";
- "review the whole repository and implement the best architecture";
- changing artifact schema, placement solver, map grammar, renderer and validation in one pass.

### Practical file budget

As a default, a coding session should have approximately:

- **3–8 primary files** it is allowed to modify;
- **up to ~15–25 reference files** it may inspect closely;
- broader repository search only for orientation and dependency checks.

This is not a hard technical limit. It is a coherence limit.

If the agent discovers that the task genuinely requires changing 30 unrelated files, stop and split the problem unless the files are mechanical instances of one already-proven transformation.

### Practical abstraction budget

A session should normally modify **one architectural layer**.

For example:

```text
GOOD:
negotiator only

GOOD:
dressing-room schema migration only

GOOD:
wall-surface representation only

RISKY:
dressing-room schema + map grammar + solver

STOP:
registry ontology + artifact code + solver + architecture + visual style
```

### Practical uncertainty budget

At session start, write down at most **one or two unresolved architectural questions**.

If implementation exposes a third major uncertainty, stop implementation and create a handoff/research note. Do not continue stacking guesses.

## 11. Context saturation signals

An agent should end or checkpoint the session when any of these occur:

- it proposes a new system that sounds very similar to an existing one;
- it can no longer state the original goal in one paragraph without rereading the prompt;
- more than two architectural questions are unresolved at once;
- it starts changing files outside the declared working set "to make things consistent";
- test failures lead to broad refactoring unrelated to the hypothesis;
- the session has accumulated several temporary compatibility layers;
- it repeatedly rereads its own newly written README instead of canonical project docs;
- it cannot name which source owns a piece of data;
- it is simultaneously debugging runtime, schema, solver and presentation issues;
- summaries begin describing activity rather than decisions and evidence.

These are **stop conditions**, not invitations to use more context.

---

# PART V — REPOSITORY MEMORY, NOT README LOOPS

## 12. Documentation hierarchy

Not all documentation has equal authority.

Agents must distinguish four levels.

### Level A — Canonical project doctrine

Defines architecture and ownership across sessions.

Examples:

- this document;
- `doc/SPINE_HINTS_CONTRACT.md`;
- `doc/DRESSING_ROOM_SCHEMA.md`;
- canonical map-grammar documentation;
- explicit decision records.

A local README cannot silently override Level A.

### Level B — Subsystem reference

Explains how a bounded subsystem currently works.

Examples:

- a grid-mutator README;
- composer API documentation;
- tool usage instructions;
- schema field reference.

It may describe implementation, but must link upward to the canonical doctrine it implements.

### Level C — Session handoff / research record

Records what one session tried, learned and left unresolved.

It is evidence, not doctrine.

A handoff can say:

```text
We tried X.
Y failed because Z.
Commit abc contains the experiment.
Next test should compare A/B.
```

It must not redefine the whole architecture.

### Level D — Agent-local notes / README / scratch

Convenient temporary orientation only.

These files have the lowest authority. An agent must never infer that a Level-D file is canonical merely because it is nearest to the code it is editing.

## 13. The README-loop failure

A common failure mode is:

```text
agent A writes README
        |
        v
agent B starts nearby
        |
        v
reads README as source of truth
        |
        v
extends its assumptions
        |
        v
writes a more detailed README
        |
        v
agent C now sees a very coherent but locally invented architecture
```

This creates **documentation gravity**: prose becomes more internally consistent while drifting away from the actual project lineage.

To prevent this:

1. Every subsystem README should contain a **Canonical parent** link.
2. Every agent session should start from the canonical parent, then descend to local docs.
3. Local README claims that conflict with canonical docs must be treated as stale until resolved.
4. Architectural discoveries must be promoted upward into canonical docs or decision records.
5. Do not create a new README merely to remember the current conversation.
6. Use Git commits and handoff notes for session-specific state.

## 14. The Ada Research Encyclopedia should be a navigator, not a second memory universe

The encyclopedia is useful when it helps answer:

```text
What exists?
Where is the authority?
What is current?
What was tried?
What should I read next?
```

It is harmful if it becomes a parallel body of prose disconnected from repository authority.

The desired model is:

```text
                 CANONICAL REPO DOCS
                        ^
                        |
        links / indices / generated summaries
                        |
              ADA ENCYCLOPEDIA
                        |
          search / browse / visualization
                        |
                        v
                agent or human reader
```

Not:

```text
repo truth <---- competing ----> encyclopedia truth
```

The encyclopedia should preferentially **index and surface canonical documents, commits, reports, schemas and generated evidence**, rather than paraphrasing the architecture into another independent description.

Where it contains interpretation, that interpretation should identify its source and date/commit.

## 15. Every important page needs provenance

For durable agent-readable documentation, prefer a small provenance header:

```text
Status: canonical | subsystem | handoff | generated | historical
Owner: spatial-pipeline | grid | artifacts | etc.
Canonical parent: doc/SPATIAL_PIPELINE.md
Last verified against code: <commit SHA or date>
Supersedes: <old document/system if applicable>
Superseded by: <document if historical>
```

This is more useful to an LLM than another paragraph saying "this is important."

---

# PART VI — SESSION CONTRACT

## 16. Required start-of-session procedure

A session working on the spatial pipeline should begin with a short orientation pass, not unrestricted repository exploration.

### Step 1 — State the task boundary

Write internally or in the handoff:

```text
Goal:
Layer being changed:
Primary files allowed to change:
Canonical docs read:
Evidence/baseline:
Success test:
Explicit non-goals:
```

### Step 2 — Read canonical docs first

At minimum when relevant:

1. `doc/SPATIAL_PIPELINE.md`;
2. `doc/SPINE_HINTS_CONTRACT.md`;
3. `doc/DRESSING_ROOM_SCHEMA.md`;
4. current map-grammar documentation;
5. latest relevant Git history.

Then read subsystem docs.

### Step 3 — Recover history before inventing

Before adding an abstraction, search Git history and code for the same concept under older names.

Questions:

- Which existing layer owns this fact today?
- Why can that layer not represent it?
- Is this proposed concept a provider, canonical representation, solver, assembler or validator?
- What does it supersede?
- How will old data migrate?

If these cannot be answered, implementation should stop.

### Step 4 — Declare the experiment

One sentence:

> "If we change X while holding Y and Z fixed, metric/evidence Q should improve."

This prevents a session from turning into general cleanup.

## 17. Required end-of-session handoff

A useful session should leave a compact durable record even if the code is unfinished.

The handoff should contain:

```text
GOAL
What exact question this session addressed.

BASELINE
What existed before, including relevant commit/tool/test.

CHANGES
Only the meaningful architectural/code changes.

EVIDENCE
Tests, captures, scores, pathfinder results, examples.

DECISIONS
What is now considered true and why.

FAILED APPROACHES
What was tried and should not immediately be repeated.

OPEN QUESTIONS
Maximum 1-3 concrete unresolved issues.

NEXT ACTION
One bounded continuation task.

FILES / COMMITS
Exact paths and commit SHA(s).
```

A handoff is successful if a fresh agent can continue **without reading the previous conversation**.

That is the test.

## 18. Commit discipline as external memory

Commits should record conceptual checkpoints, not only file changes.

Good commit messages answer:

```text
What hypothesis changed?
What evidence supports it?
What is intentionally not solved?
```

When a wrong approach teaches something, prefer a documented revert/correction over silently erasing the history. The repository already contains useful examples of this pattern.

Git history is part of the project's research memory.

---

# PART VII — CURRENT RESOURCE MAP

## 19. Existing systems to check before writing a new one

| Purpose | Existing resource |
|---|---|
| Registry | `commons/artifacts/registry/` |
| AABB measurement | `tools/measure_artifact_aabbs.py` |
| Spatial defaults | `spatial_needs` in registry |
| Spatial derivation | `tools/derive_spatial_profile.py` |
| Artifact-to-map dynamic contract | `doc/SPINE_HINTS_CONTRACT.md`, `commons/grid/SpineHints.gd` |
| Staged artifact contexts | `commons/artifacts/dressing_rooms/*.json` |
| Dressing-room specification | `doc/DRESSING_ROOM_SCHEMA.md` |
| Dressing-room 3D catalog/editor | DressingRoom catalog / inspector scenes and scripts |
| Plan/elevation rendering | `tools/map_plans.py` |
| Artifact selection | atlas / artifact groups / sequence files |
| Missing-artifact proposals | atlas stub proposer tooling |
| Map grammar | `tools/map_grammar/` |
| Grammar documentation | `doc/MAP_GRAMMAR.md`, `doc/MAP_GRAMMAR_OPERATIONS.md` |
| Spatial grammar | `tools/lib/spatial_grammar.py` |
| A* composition | `tools/lib/astar_composer.py` |
| Earlier composition | `tools/compose_map.py` |
| Dressing-room composition | `tools/map_composer.py` |
| Placement-only experiments | `tools/spine_placement_only.py` |
| Structure experiments | `tools/spine_auto_research.py` |
| Evaluation | map grammar / quality audit tooling |
| Reachability | pathfinder + reachability repair tooling |
| Placement comparison | `tools/compare_placements.py` |
| Isometric diagnostics | `tools/iso_voxel_render.py` |
| Map plans | `tools/generate_map_plans.py` |
| Artifact plans | `tools/generate_artifact_plans.py` |
| Artifact-map index | artifact map index tooling / `doc/artifact_to_maps.json` |
| Capture | multi-angle capture and gallery tooling |
| Research inventory | `tools/auto_research_inventory.py` |
| Research recipes | `commons/research_recipes/` |
| Historical architecture | `floor_plan_space`, museum maps, facade presets |
| Editing | Map Studio / voxel editing tools |

Names have changed. Search before assuming a historical tool was deleted. If superseded, record the successor in canonical documentation.

---

# PART VIII — CURRENT MILESTONE

## 20. Three-artifact proof

Before bulk migration or generation, make one small end-to-end pipeline undeniable.

Select three deliberately different artifacts:

1. compact floor object;
2. wall/panel or front-read object;
3. larger or interaction-heavy object.

For each:

1. measure actual geometry;
2. inspect registry `spatial_needs` / profile;
3. inspect any `spine_hints()`;
4. generate or author one dressing room;
5. produce the canonical spatial contract;
6. offer architecture several candidate placement surfaces;
7. let the negotiator place it;
8. assemble the map;
9. run path/reachability/clearance validation;
10. capture useful viewpoints;
11. record why each placement was accepted or rejected.

Do not scale until this works.

## 21. Required solver behaviour

For each staged artifact:

```text
candidate slot
 -> legal rotation
 -> alternate legal placement mode
 -> alternate slot
 -> architecture expansion / room resize if permitted
 -> explicit failure with reasons
```

Expose:

- candidate slots considered;
- rejected constraints;
- chosen placement mode;
- chosen rotation;
- body/access/presentation reservations;
- path impact;
- final score and score components.

A failure is valuable output. Silent fallback is not.

## 22. Validation contract

Minimum checks:

- spawn -> required artifact(s) -> exit reachable;
- physical masks do not illegally overlap;
- required access zones remain traversable;
- wall-backed objects have valid surfaces;
- front-read objects retain viewing distance;
- interaction-heavy artifacts have player standing space;
- spawn and teleporter are valid;
- no accidental unreachable islands;
- performance within target when budget metadata exists.

Visual capture is validation evidence, not decoration.

---

# PART IX — STOP CONDITIONS

## 23. Do not do these before the three-artifact proof

- invent another artifact spatial schema;
- add another general-purpose map generator;
- generate hundreds of variants;
- bulk-edit registries to fit a new heuristic;
- migrate every artifact;
- build another museum style as a substitute for solving placement;
- optimize AAA presentation before the spatial contract works;
- treat a prototype solver's bad output as proof that its representation failed;
- silently redefine ownership among `spatial_needs`, `spine_hints`, `spatial_profile` and dressing rooms;
- ask one context window to hold the complete project;
- allow agent-local READMEs to become architecture by repetition.

---

# PART X — DECISIONS

## 24. Decision log

### Decision 1 — Artifact staging is reusable

Local spatial requirements belong with the artifact, not independently in every map.

### Decision 2 — Architecture and staging are separate

Architecture proposes opportunities. Dressing rooms describe requirements. A negotiator matches them.

### Decision 3 — Dressing room is the strongest static staging representation

Profiles and hints feed it; they do not compete with it.

### Decision 4 — Solvers are replaceable

The spatial contract must survive changes to composer/optimizer implementation.

### Decision 5 — Generation must be inspectable

The system must explain why placement happened and why alternatives failed.

### Decision 6 — Research proceeds small-to-large

Prove three heterogeneous artifacts end-to-end before scaling.

### Decision 7 — Context is disposable

No architectural fact is considered safely preserved merely because an agent currently remembers it.

### Decision 8 — Repository documentation is durable memory

Important decisions must survive a fresh session with no access to the previous conversation.

### Decision 9 — Local documentation cannot silently become canonical

READMEs and session notes must identify their authority level and canonical parent.

### Decision 10 — Agent sessions are bounded experiments

One goal, one layer, one hypothesis, one validation loop, one handoff.

---

# Short version for agents

If you remember only ten things:

1. **Do not invent another schema.**
2. **Artifact needs and architecture are separate systems.**
3. **Dressing rooms are the canonical reusable staging unit.**
4. **The negotiator/solver is the main unfinished spatial component.**
5. **Prove three different artifacts end-to-end before scaling.**
6. **Your context window is working memory, not Ada Research memory.**
7. **Modify one architectural layer per session whenever possible.**
8. **Read canonical docs before local READMEs.**
9. **Leave a handoff that works without the previous conversation.**
10. **If the task has become 'understand/fix the whole project', stop and split it.**
