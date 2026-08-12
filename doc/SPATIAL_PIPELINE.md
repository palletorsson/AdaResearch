# Ada Research — Canonical Spatial Build Pipeline

> **Status: canonical architecture note.**
>
> Read this before adding a new map generator, placement heuristic, artifact spatial schema, or museum composition system.
>
> The repository already contains several generations of spatial research. They are not separate abandoned solutions. They are layers of one system. The purpose of this document is to establish ownership, preserve what has been learned, and stop future sessions from rediscovering the same problem under new names.

## 1. What we are building

Ada Research needs a **spatial compiler**, not merely an automatic museum generator.

The input is conceptual: sequences, artifacts, relationships, teaching order, and authored intentions. The output is experiential: a navigable 3D/VR environment in which artifacts have enough physical, perceptual, and interaction space to work.

The central rule is:

> **The artifact speaks first about what it needs. Architecture responds. Neither owns the whole problem.**

The system therefore separates six questions:

1. **What should be encountered?** — sequence / atlas / curriculum.
2. **What does each artifact require?** — measurement, metadata, dynamic hints, staging.
3. **What spatial topology should organize the encounter?** — architecture grammar.
4. **Where can each staged artifact legally fit?** — negotiation / constraint solving.
5. **How is the accepted plan assembled?** — map layers + modular 3D architecture.
6. **Does the result actually work?** — pathfinding, accessibility, visibility, interaction, performance, capture and critique.

## 2. Canonical pipeline

```text
CONTENT / ONTOLOGY
Sequence / curriculum / atlas / DNA / relationships
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

This is a pipeline with feedback, not a one-shot generator.

## 3. Ownership: one fact, one authority

The previous sessions produced overlapping representations. They should be treated as a hierarchy, not competitors.

### Measured AABB

**Owns:** actual observed geometry.

Use automated Godot measurement whenever possible. AABB is evidence, not an authored preference.

Relevant tools include `tools/measure_artifact_aabbs.py` and earlier footprint-detection work.

### `spatial_profile`

**Owns:** automatically inferred placement characteristics derived from geometry/category when no stronger authored information exists.

Typical fields include direction group, range, density, minimum clearance, stack priority and approach direction.

Relevant tool: `tools/derive_spatial_profile.py`.

### `spatial_needs`

**Owns:** registry-level durable spatial defaults and semantic requirements.

Existing vocabulary includes platform, footprint cells, clearance, wall backing, isolation, clustering and preferred zone.

Do not create a second registry vocabulary for the same facts.

### `spine_hints()`

**Owns:** dynamic/runtime hints that cannot reliably be represented statically, plus lightweight artifact-local fallbacks.

The existing contract includes role, footprint, approach, reading distance, height, rotation, budget and tags.

`spine_hints()` is a **provider into the spatial contract**, not an independent map-generation architecture.

See `doc/SPINE_HINTS_CONTRACT.md`.

### Dressing room

**Owns:** the final reusable staging solution for an artifact.

A dressing room may specify footing, artifact anchor, legal rotations, approach, exit, clearance, labels, tutorial panels, lights and other local staging elements. It is the strongest authored representation because it describes not merely the object but the small piece of space required for the object to work.

See `doc/DRESSING_ROOM_SCHEMA.md` and `commons/artifacts/dressing_rooms/`.

### Sequence / atlas

**Owns:** which artifacts belong together and their conceptual/teaching order.

It does **not** own exact x/z placement.

### Architecture grammar

**Owns:** topology: rooms, corridors, walls, openings, boundaries, architectural rhythm and available placement surfaces.

It does **not** decide what an artifact means or silently violate its staging requirements.

### Negotiator / solver

**Owns:** placement decisions.

It matches dressing-room/spatial-contract requirements against architectural opportunities. It may choose slots, rotations and legal modes; request more space; or fail explicitly.

### Assembler

**Owns:** translating an accepted plan into map layers and modular 3D geometry.

### Validator

**Owns:** accept/reject evidence.

A visually plausible map is not accepted merely because generation completed.

## 4. Resolution order

When constructing the spatial contract for an artifact, resolve information in this order:

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

A stronger layer may refine a weaker layer, but it should not duplicate the same fact without an explicit reason.

The desired long-term relationship is:

```text
AABB -> spatial_profile -> default dressing room -> authored dressing room
                 ^
                 |
          spatial_needs
                 ^
                 |
          spine_hints() when dynamic
```

## 5. Why dressing rooms are central

The April composer work discovered the strongest division of responsibility in the repository:

> **Staging decisions go DOWN to the artifact level; layout goes UP into a constraint-routing problem.**

The useful three-part architecture is:

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

This should remain the default mental model for the Endless Museum.

A dressing room is more expressive than a scalar spatial profile. A profile can say "panel, front approach, two metres reading range". A dressing room can say "this 5x4 micro-layout, artifact here, player enters here, plinth here, label here, light here, these rotations legal".

Therefore do **not** replace dressing rooms with `spatial_profile`. Use profiles to bootstrap dressing rooms.

## 6. Important implementation warning: representation vs solver

`tools/map_composer.py` demonstrates the dressing-room architecture, but its current placement strategy is deliberately simple: it distributes rooms at fractional positions along the spawn-to-teleport line, chooses a rotation, nudges overlaps, then uses A* to connect them.

That means:

> **An unattractive result from `map_composer.py` is evidence about the prototype solver, not evidence that the dressing-room representation is wrong.**

Do not discard the abstraction because `place_rooms()` is simplistic. Improve or replace the negotiator while retaining the artifact staging contract.

## 7. Architecture-first vs artifact-first

The history contains two valid research modes.

### Architecture-first

```text
grammar -> floor plan -> candidate surfaces -> artifact placement
```

Useful for studying topology, architectural language and structure generation.

### Artifact-context-first

```text
artifact -> dressing room -> reserve staged units -> route architecture between them
```

Useful for the Endless Museum and other content-led sequences.

For the canonical museum pipeline, **artifact-context-first is dominant**, but architecture still has an independent grammar. The negotiator is the interface between them.

Neither system should directly overwrite the other.

## 8. Research modes must remain separable

Do not conflate structure research with placement research.

### Structure research

Hold artifact requirements relatively stable and vary topology / architecture.

Relevant tooling includes `tools/spine_auto_research.py`, map grammar systems and structural generators.

### Placement research

Hold architecture stable, remove/re-place artifacts, evaluate alternatives.

Relevant tool: `tools/spine_placement_only.py`.

This separation is valuable because it makes failures legible. If both architecture and placement mutate simultaneously, the evaluator cannot tell which decision improved or damaged the map.

## 9. Existing resource map

The following systems should be checked before implementing a new one.

| Purpose | Existing resource |
|---|---|
| Registry | `commons/artifacts/registry/` |
| AABB measurement | `tools/measure_artifact_aabbs.py` |
| Spatial defaults | `spatial_needs` in registry |
| Spatial derivation | `tools/derive_spatial_profile.py` |
| Artifact-to-map contract | `doc/SPINE_HINTS_CONTRACT.md`, `commons/grid/SpineHints.gd` |
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

Names have changed over the history. Search before assuming a listed historical tool was deleted; if it was superseded, document the successor here.

## 10. Current maturity

Qualitative architectural assessment, not automated repository metrics:

```text
Artifact catalogue             [##########]  mature
Measurements / footprints      [########--]  strong
Artifact spatial metadata      [########--]  strong
Artifact order / ontology      [#########-]  mature
Dressing-room concept          [#########-]  mature concept
Dressing-room authoring        [########--]  strong prototype
Map grammar                    [#########-]  mature research
Structure generation           [########--]  strong research
Placement solver               [####------]  prototype
Wall-placement model           [##--------]  early
Unified negotiation layer      [###-------]  missing/fragmented
Modular Endless Museum         [######----]  partial
Validation                     [#######---]  strong but distributed
Visual critique loop           [######----]  partial
Canonical documentation        [####------]  this document begins consolidation
```

The primary missing component is **not another generator**. It is a unified negotiator operating on one documented contract.

## 11. Next implementation milestone: three-artifact proof

Before bulk migration or generation, make one small end-to-end pipeline undeniable.

Use three artifacts with deliberately different spatial behavior:

1. a compact floor object;
2. a wall/panel or front-read object;
3. a larger or interaction-heavy object.

For each artifact:

1. measure actual geometry;
2. inspect registry `spatial_needs` / profile;
3. inspect any `spine_hints()`;
4. generate or author one dressing room;
5. produce the canonical spatial contract;
6. give the architecture several candidate placement surfaces;
7. let the negotiator place all three;
8. assemble the map;
9. run path/reachability/clearance validation;
10. capture it from useful viewpoints;
11. record why each placement was chosen or rejected.

Only after this works should the system scale to tens or hundreds of artifacts.

## 12. Required solver behaviour

The next negotiator should be deterministic under a seed and explain its decisions.

For each staged artifact it should attempt, in order:

```text
candidate slot
 -> legal rotation
 -> alternate legal placement mode
 -> alternate slot
 -> architecture expansion / room resize if permitted
 -> explicit failure with reasons
```

A failure is useful output. Silent fallback to a meaningless 1x1 placement is not acceptable for authored or high-priority artifacts.

The solver should expose at least:

- candidate slots considered;
- rejected constraints;
- chosen placement mode;
- chosen rotation;
- reserved body/access/presentation space;
- path impact;
- final score and score components.

This makes future AI sessions capable of diagnosing the system rather than guessing at it.

## 13. Validation contract

A generated map is not "done" until it passes relevant checks.

Minimum checks:

- spawn -> required artifact(s) -> exit is reachable;
- artifact body masks do not illegally overlap;
- required approach/access zones remain traversable;
- wall-backed objects have valid backing surfaces;
- front-read objects retain sufficient viewing distance;
- interaction-heavy artifacts have usable player standing space;
- teleporter and spawn are valid;
- no accidental unreachable islands are introduced;
- performance budget is within the target when budget metadata exists.

Visual capture is part of validation, not merely presentation.

## 14. Session protocol

Every future session working on spatial generation should begin by reading:

1. this document;
2. `doc/SPINE_HINTS_CONTRACT.md`;
3. `doc/DRESSING_ROOM_SCHEMA.md`;
4. the current map grammar documentation;
5. the latest relevant Git history.

Before introducing a new abstraction, answer:

- Which existing layer owns this fact today?
- Why can that layer not represent it?
- Is the new concept a provider, canonical representation, solver, assembler or validator?
- What existing field/tool does it supersede?
- How will old data migrate?

If these questions cannot be answered, do not add the abstraction yet.

## 15. Anti-patterns / stop conditions

Until the three-artifact proof is complete, do **not**:

- invent another artifact spatial schema;
- add another general-purpose map generator;
- generate hundreds of variants;
- bulk-edit registry entries to fit a new heuristic;
- migrate every artifact;
- build another museum visual style as a substitute for solving placement;
- optimize AAA presentation before the spatial contract works;
- treat a prototype solver's bad output as proof that its input representation failed;
- allow a new session to silently redefine ownership between `spatial_needs`, `spine_hints`, `spatial_profile` and dressing rooms.

## 16. Decision log

### Decision 1 — Artifact staging is reusable

An artifact's local spatial requirements belong with the artifact, not hand-authored independently in every map.

### Decision 2 — Architecture and staging are separate

Architecture proposes spatial opportunities. Dressing rooms describe requirements. A negotiator matches them.

### Decision 3 — Dressing room is the strongest static staging representation

Profiles and hints feed it; they do not compete with it.

### Decision 4 — Solvers are replaceable

`map_composer.py`, A* composers, grammar composers and future optimizers are implementations. The spatial contract must survive solver replacement.

### Decision 5 — Generation must be inspectable

The system should say why a placement happened and why alternatives failed.

### Decision 6 — Research proceeds small-to-large

Prove three heterogeneous artifacts end-to-end before scaling.

## 17. Historical trajectory

The repository's apparent repetition is actually a useful research lineage:

```text
hand placement
    -> measured footprints / AABB
    -> spatial_needs
    -> grammar + A* spatial intelligence
    -> spine_hints artifact contract
    -> dressing-room micro-scenes
    -> spatial_profile derivation
    -> structure-only / placement-only research
    -> [NOW] consolidate into one negotiator + one documented pipeline
```

The project is therefore not starting over. The present task is **convergence**.

---

## Short version for agents

If you remember only five things:

1. **Do not invent another schema.**
2. **Artifact needs and architecture are separate systems.**
3. **Dressing rooms are the canonical reusable staging unit.**
4. **The negotiator/solver is the main unfinished component.**
5. **Prove three different artifacts end-to-end before scaling.**
