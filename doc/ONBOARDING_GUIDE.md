# Ada Research: Onboarding Guide
> Generated: 2026-02-20 — run `/ada-orchestrator refresh` to regenerate

## Who This Is For

This guide orients anyone arriving at the Ada Research project for the first time — a new Claude session picking up mid-project, a human collaborator joining the team, or an AI assistant asked a one-off question. It is the fastest path from "what is this?" to productive contribution.

## How to Use This Guide

- **"I want to understand the project"** — Read Sections 1-4
- **"I want to contribute a map or sequence"** — Read Sections 3, 5, then use the skills in Section 8
- **"I need to know what's happening right now"** — Jump to Section 7
- **"I want to explore from code"** — Section 5 with the worked example

---

## 1. Project at a Glance

### Quick Stats (Live)
> Generated: 2026-02-20

| Metric | Count | Source |
|--------|------:|--------|
| Spine sequences | 19 | `commons/maps/curriculum_spine.json` |
| All sequences (excl. index) | 49 | `commons/maps/sequences/*.json` file count |
| Declared maps (in sequences) | 431 | `doc/reports/SEQUENCE_CONTRACT_AUDIT.md` |
| Existing map folders | 585 | Glob `commons/maps/*/map_data.json` |
| Modular registry artifacts | 491 | `commons/artifacts/registry/*.json` entry count |
| Legacy registry artifacts | 17 | `commons/artifacts/grid_artifacts.json` entry count |
| Algorithm categories | 52 | `algorithms/` subdirectory count |

**Note:** ENTRY.md reports 42 sequences / 503 maps / 752 legacy artifacts — these counts have drifted. The numbers above are from live file counting as of today.

### What Makes This Project Different

1. **Dual-lens pedagogy** — every algorithm has both technical explanation AND critical theory examining the politics of computation
2. **Embodied VR learning** — grab vectors, tune parameters, see emergence happen in spatial, haptic, audio-rich 3D environments
3. **QFEP framework** — the Queer Free Energy Principle provides a unified theoretical structure connecting order, chaos, and becoming
4. **Generative incompleteness** — the project is deliberately unfinished; you learn by filling gaps and expanding the curriculum
5. **Academic research outputs** — 5 research papers connecting algorithms to queer theory, spatial justice, and computational resistance

Full reference: `doc/ENTRY.md`

---

## 2. How the System Works

### The Content Chain

```
Sequences  ->  Maps  ->  Artifacts  ->  Scenes
   .json     map_data    registry      .tscn/.gd
			  .json       .json
```

A **sequence** defines a playlist of maps. Each **map** is a 3-layer JSON grid (structure/utilities/interactables). The interactables layer references **artifacts** by `lookup_name`, resolved through the **registry** to a Godot scene file. Each map also has 4 companion markdown files (`blurb.md`, `summary.md`, `technical.md`, `critical.md`) that form an in-game booklet accessible by pressing `X`.

### Grid System

The grid is the core architecture. Maps define a 3D grid with three layers:
- **Structure** — numeric height values (`0` = empty, `1` = floor-level, `2`+ = walls/columns of increasing height). Numbers define the geometry; `GridStructureComponent` builds the 3D mesh from these integers
- **Utilities** — string tokens: spawn points (`s`), teleporters (`t:MapName`), annotations (`an`), speed readers (`sr:key`), lights, audio
- **Interactables** — string tokens: artifacts placed by `lookup_name:rotation:scale`

The `GridSystem` node coordinates 8+ components: `GridDataComponent`, `GridStructureComponent`, `GridUtilitiesComponent`, `GridInteractablesComponent`, `GridSpawnComponent`, `GridCeilingComponent`, `GridWallComponent`, `GridAudioComponent`.

### Artifact System

Two registries coexist:
- **Modular** (`commons/artifacts/registry/*.json`) — 24 files, 491 entries organized by domain
- **Legacy** (`commons/artifacts/grid_artifacts.json`) — 17 entries for backward compatibility

Each entry maps a `lookup_name` to a scene path, with optional QFEP connection, tags, and description.

### Sequence System

Sequences in `commons/maps/sequences/*.json` define ordered map playlists with:
- `maps[]` array (the visit order)
- `lab_map` (the Lab state loaded on completion)
- Learning objectives, difficulty, audio presets

Unlock progression is defined in `curriculum_spine.json` via `branch_points` and `lab_evolution`, not in individual sequence files.

`AdaSceneManager` (autoload singleton) manages transitions between maps within a sequence.

### Autoloads

| Singleton | Purpose |
|-----------|---------|
| `AdaSceneManager` | Scene transitions, sequence state, game mode |
| `MapProgressionManager` | Unlock graph, save/load progress |
| `GridArtifactRegistry` | Resolves lookup_names to scene paths |
| `SoundBankSingleton` | Audio preset system |
| `GameSettings` | Persistent user settings |
| `DesktopModeManager` | Desktop/VR mode detection |

### VR and Desktop Modes

Platforms: Meta Quest, Pico, Lynx, plus Khronos desktop fallback. Four game modes:
- **Story** — full sequence progression with unlock requirements
- **Test** — jump to the last map in a sequence (for testing)
- **TestPlus** — hybrid: plays from a specific map forward
- **Explorer** — all maps unlocked, free navigation

Full reference: `doc/ARCHITECTURE.md`

---

## 3. The Learning Journey

### The QFEP Curriculum Spine

19 spine sequences ordered by QFEP phase, from `curriculum_spine.json`:

| # | Sequence | Phase | Maps | Status |
|---|----------|-------|-----:|--------|
| 1 | `primitives` | F_order | 12 | All exist |
| 2 | `transformation` | F_order | 6 | All exist |
| 3 | `color` | F_order | 12 | All exist |
| 4 | `forces` | oscillation | 10 | All exist |
| 5 | `array_tutorial` | F_order | 8 | All exist |
| 6 | `wavefunctions` | oscillation | 12 | All exist |
| 7 | `randomness` | E_entropy | 13 | All exist |
| 8 | `noise` | E_entropy | 11 | All exist |
| 9 | `cellularautomata` | E_entropy | 12 | All exist |
| 10 | `fractals` | lambda_edge | 14 | All exist |
| 11 | `lsystems` | lambda_edge | 11 | All exist |
| 12 | `proceduralgeneration` | lambda_edge | 18 | All exist |
| 13 | `softbodies` | integration | 8 | All exist |
| 14 | `swarmintelligence` | integration | 7 | All exist |
| 15 | `machinelearning` | integration | 16 | All exist |
| 16 | `foundationscrisis` | synthesis | 7 | All exist |
| 17 | `qfeplaboratory` | synthesis | 8 | All exist |
| 18 | `postfoundationscrisis` | synthesis | — | Collects from deferred sequences |
| 19 | `graphtheory` | integration | 14 | All exist |

**All 21 spine sequences in the build status report show 0 missing maps.**

### Branch Sequences

Beyond the spine, ~30 branch sequences unlock from spine completion points. Examples:
- `primitives` unlocks `meshes`, `datastructures`, `color`
- `forces` unlocks `physicssimulation`, `particles`
- `proceduralgeneration` unlocks `spatial_partitioning`, `constraint_solvers`, `isosurfaces`, `higher_dimensions`, `grammar_systems`
- `machinelearning` unlocks `recursiveemergence`, `artmathematics`

Three sequences are unassigned to the unlock graph: `vectors`, `resourcemanagement`, `bricolage`.

### Playability Status

Per the SPINE_MAP_BUILD_STATUS report: all 21 audited spine sequences have 0 missing declared maps. The project has 97 undeclared map folders (maps that exist on disk but aren't assigned to any sequence) — these are an inventory queue for future assignment.

### How Sequences Unlock

The progression forms a DAG (directed acyclic graph) defined in `curriculum_spine.json`. The `branch_points` section maps which sequences unlock which others, and `lab_evolution` defines the Lab post-states. Completing a sequence returns the player to the Lab hub, where new teleporters appear based on what was unlocked.

Full reference: `doc/TAXONOMY.md`, `doc/CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md`

---

## 4. The Theoretical Framework

### The Queer Free Energy Principle

Everything is organized around the QFEP formula:

```
QFE = F - lambda * E(S) + phi * dE(S,t)
```

| Symbol | Meaning | Curriculum Phase |
|--------|---------|------------------|
| **F** | Free energy — order, prediction, stability | `primitives`, `transformation` |
| **E(S)** | Entropy — disorder, randomness, creative force | `randomness`, `noise`, `cellularautomata` |
| **lambda** | Order-chaos balance parameter (0 to 1) | `fractals`, `lsystems`, `proceduralgeneration` |
| **phi * dE** | Rate of entropy change — emergence, self-organization | `softbodies`, `swarmintelligence`, `machinelearning` |

**Life exists at lambda ~ 0.3-0.5** — enough order to maintain identity, enough chaos to adapt and become.

### Connecting Algorithms to Theory: Four Lenses

Any algorithm can be examined through these four questions:

1. **Normativity** — What does this algorithm assume is "normal"? What happens when that assumption breaks?
2. **Boundaries** — How does this algorithm define inside/outside? What gets excluded?
3. **Difference** — How does this algorithm handle variation? Does it suppress or amplify it?
4. **Temporality** — What is this algorithm's relationship to time? Linear progress or cyclical becoming?

Use `/ada-queer-theory-expert` for deep dives connecting any specific algorithm to theory.

### Research Papers

| Paper | File | Focus |
|-------|------|-------|
| Queer Collective Intelligence | `particle_swarm_queer_intelligence.md` | PSO as resistance to algorithmic conformity |
| Permeable Boundaries | `convex_hull_boundary_theory.md` | 3D convex hull as spatial justice practice |
| Computational Resistance | `computational_resistance_framework.md` | Framework for queer algorithmic practice |
| Queer Ecology Simulation | `queer_ecology_simulation.md` | Ecological modeling through queer theory |
| Free Energy Principle | `free_energy_principle_markov.md` | Markov blankets and the FEP |

All papers in `doc/papers/`. Publication strategy targets IEEE, ACM, Digital Humanities Quarterly, and interdisciplinary venues.

### The Critical Theory Algorithms

The `algorithms/criticaltheory/` directory contains implementations that directly embody critical theory — including Anicka Yi Lab, Pipilotti Rist World, and related art-theory-computation intersections.

Full reference: `doc/papers/README.md`, `algorithms/COMPREHENSIVE_ALGORITHM_CATALOG.md`

---

## 5. How to Explore the Project

### The Generative Play Method

You are simultaneously **Player** and **System**. Read the source files as if walking through the VR space. When files are missing or incomplete, note the gap — that's the project's generative incompleteness at work.

### Reading a Sequence

1. **Load the sequence JSON** — `commons/maps/sequences/randomness.json` — your map playlist
2. **Read the `maps` array** — the ordered visit list (e.g., `["Random_Definition", "Randomness_Dice_Throw", ...]`)
3. **For each map, read `map_data.json`** — three layers: structure (the room), utilities (spawn/teleport/tutorial), interactables (artifacts)
4. **Find the exit teleporter** — look for `t:next_in_sequence` in the utilities layer to advance

### Reading a Map (Worked Example)

Take `randomness.json` → first map is `Random_Definition`:

```
commons/maps/Random_Definition/map_data.json
```

- **Structure layer**: walls define the room shape, floors the walkable area
- **Utilities layer**: `s` = spawn point, `t:Randomness_Dice_Throw` = exit teleporter, `sr:random_definition` = speed reader tutorial, `an` = annotation boards
- **Interactables layer**: `coin_toss:0:1` = coin toss artifact, `dice_throw:90:1` = dice at 90-degree rotation
- **Map documentation** (press `X` in-game to open the booklet):

```
commons/maps/Random_Definition/
├── map_data.json    # Grid layers and artifact placements
├── blurb.md         # Poetic hook — the opening impression
├── summary.md       # Overview of what the map teaches
├── technical.md     # Code examples and implementation details
└── critical.md      # Queer theory / critical theory critique
```

These four markdown files appear as an in-game booklet the player can open at any time. They provide the dual-lens pedagogy: `technical.md` explains the algorithm, `critical.md` examines its politics.

### Utility Token Quick Reference

Most-used tokens first:

| Token | Meaning |
|-------|---------|
| `t:MapName` | Teleporter to named map |
| `t:next_in_sequence` | Advance to next map in sequence |
| `wp` | Slope / walkable ramp |
| `tc:height:axis` | Transport cube (vertical elevator, e.g. `tc:2:y`) |
| `s` | Spawn point |
| `an` | Annotation board |
| `sr:key` | Speed reader (tutorial text lookup) |
| `el` | Extra light |
| `m:label` | Marker (visual label) |
| `3t:text` | Floating 3D text |
| `sub:key` | Subtitle trigger |
| `ib:topic` | Handheld info board |

Full list: `commons/grid/UtilityRegistry.gd`

### Finding Tutorial Content

1. Find `sr:key` in the utilities layer (e.g., `sr:random_definition`)
2. Look up the key in `commons/context/clipboard/tutorial_text.json`
3. If the entry has a `content_file` field, read the `.gd` file at that path for the full tutorial

Full reference: `doc/CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md`

---

## 6. Documentation Map

### Primary Truth Sources

| Path | What It Contains | When to Use |
|------|------------------|-------------|
| `commons/maps/curriculum_spine.json` | Ordered spine + branch unlock graph | Checking sequence order and progression |
| `commons/maps/sequences/*.json` | All 49 sequence definitions | Understanding the curriculum |
| `commons/maps/*/map_data.json` | Individual map grids (585 maps) | Reading or editing specific maps |
| `commons/artifacts/registry/*.json` | Modular artifact registry (491 entries) | Finding valid lookup_names |
| `commons/artifacts/grid_artifacts.json` | Legacy registry (17 entries) | Backward compatibility lookups |

### Navigation Documents

| Document | Purpose | Trust Level |
|----------|---------|-------------|
| `doc/ENTRY.md` | AI/contributor entry point — start here | Current (stats may drift) |
| `doc/CLAUDE_PROJECT_NAVIGATOR.md` | Deep structured fractal map of entire project | Current |
| `doc/CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md` | How to "play" the project from source code | Current (2026-02-20) |
| This guide (`doc/ONBOARDING_GUIDE.md`) | Synthesized onboarding — what you're reading | Generated 2026-02-20 |

### Technical References

| Document | Purpose | Trust Level |
|----------|---------|-------------|
| `doc/ARCHITECTURE.md` | Canonical system architecture | Mostly current |
| `doc/TAXONOMY.md` | 8 generative paradigms, spine table | Current |
| `doc/SCENE_SEQUENCE_GUIDE.md` | Sequence system deep-dive | Current |
| `doc/PROGRESSION_SYSTEM.md` | Lab progression and save system | Current |
| `doc/SOUNDBANK_ARCHITECTURE.md` | Audio system architecture | Current |
| `algorithms/COMPREHENSIVE_ALGORITHM_CATALOG.md` | Full algorithm inventory (52 categories) | Current |

### Theory and Research

| Document | Purpose |
|----------|---------|
| `doc/papers/README.md` | Paper index with publication strategy |
| `doc/papers/*.md` | 5 academic research papers |
| `doc/QFEP_GAMWELL_MAPPING.md` | Art/math historical grounding (Gamwell) |

### Reports and Audits

| Report | Key Content |
|--------|-------------|
| `doc/reports/SEQUENCE_CONTRACT_AUDIT.md` | Declared/existing/missing map metrics |
| `doc/reports/SPINE_MAP_BUILD_STATUS.md` | Playability per spine sequence |
| `doc/reports/ARTIFACT_REGISTRY_AUDIT.md` | Registry completeness |
| `doc/reports/LAB_PROGRESSION_CONSISTENCY_REPORT.md` | Lab post-state consistency |
| `doc/reports/HANDOFF_2026-02-16_MAP_BUILD.md` | Most recent development handoff |

### Contribution Guides

| Document | Purpose |
|----------|---------|
| `doc/HOW_TO_ADD_MAP_SEQUENCE.md` | Step-by-step for adding maps and sequences |
| `doc/MAP_QUALITY_SYSTEM.md` | Quality standards for map creation |

### CLI Tools

| Tool | Purpose |
|------|---------|
| `tools/ada/ada.py` | Fractal project navigator — zoom in/out through project structure from the terminal |
| `tools/spine_map_workbench.py` | Scaffold new spine maps, update sequences |
| `tools/generate_audit_report.py` | Generate sequence contract audit reports |
| `tools/audit_helper.py` | Audit helper utilities |

---

## 7. Current State

### Active Development (as of 2026-02-20)

Primary focus: **noise sequence polish** — annotation boards, spawn safety, teleporter cleanup. Also: wavefunctions map fixes, UID collision fixes, push button variants, and new skill system development.

### Recent Commits

```
9b023112 new random artifact skill update
d4ba7c50 noise map edits
ec8ca72c Rename Noise_Exit to Lab_Path — shared return-to-lab map for all sequences
29c4ab9a Noise sequence exit: portal to transition map before lab
8b4a282b Noise sequence: spawn safety, replace lifts, clean up teleporters
8d622296 Noise_Inside_Noise: compact row formatting
9705c600 Noise sequence maps 2-8: add annotation boards, remove s markers, fix layer dims
b6af520f Random_Noise_Types: remove clipboards
d5e2afec Noise_Voxel: remove stray s marker
2e777818 Noise sequence: fix names, add annotation boards, remove spawn markers
7ad855c2 Color palette overview: remove title, offset 0.06m; map artifact repositioning
08512064 Disco: replace control panel with sequencer-driven beats
0be8c1a4 Tutorial_Disco: bigger disco floor
0d581072 Tiling demo: larger canvases, tighter spacing
55194906 Add mario_cube artifact — listens for NextCube signal, removes DarkSphere, shows rainbow
```

### Audit Health

| Metric | Value |
|--------|------:|
| Total sequences | 44 |
| Declared map entries | 431 |
| Declared unique maps | 431 |
| Map folders on disk | 528 (audit) / 585 (live glob) |
| Duplicate entries | 0 |
| Missing declared maps | **0** |
| Undeclared map folders | 97 |

**0 blockers.** All declared maps exist on disk. The 97 undeclared folders are an inventory queue for future sequence assignment.

### Known Open Issues

- 97 map folders exist but aren't assigned to any sequence — needs triage
- `SYSTEM_KNOWLEDGE.md` has never been generated (run `/ada-knowledge-updater all`)
- ENTRY.md stat counts have drifted from live counts (42 sequences vs 49, 503 maps vs 585, etc.)
- 3 sequences unassigned to unlock graph: `vectors`, `resourcemanagement`, `bricolage`
- Currently modified files include noise maps, wavefunctions fixes, and new push button variants

> Re-run `/ada-orchestrator refresh` to update this section.

---

## 8. The Skill Ecosystem

### All Skills at a Glance

| Skill | Slash Command | Purpose | Example |
|-------|---------------|---------|---------|
| Knowledge Updater | `/ada-knowledge-updater` | Scans codebase, produces SYSTEM_KNOWLEDGE.md | `/ada-knowledge-updater all` |
| Code Documenter | `/ada-code-documenter` | Generates docs for algorithms/components | `/ada-code-documenter algorithms/randomness/coin_toss` |
| Question Assistant | `/ada-question-assistant` | Answers any project question | `/ada-question-assistant "how does AdaSceneManager advance maps"` |
| Code Guide | `/ada-code-guide` | Deep GDScript walkthrough | `/ada-code-guide commons/grid/GridSystem.gd` |
| Map Expert | `/ada-map-expert` | Create, edit, validate maps | `/ada-map-expert Noise_Voxel` |
| Sequence Expert | `/ada-sequence-expert` | Sequence design and progression | `/ada-sequence-expert noise` |
| Queer Theory Expert | `/ada-queer-theory-expert` | QFEP and critical theory connections | `/ada-queer-theory-expert "marching cubes"` |
| Tutor | `/ada-tutor` | Teaching-level algorithm explanation | `/ada-tutor "particle swarm optimization"` |
| Student | `/ada-student` | Probing questions for design thinking | `/ada-student "randomness sequence"` |
| Test Player | `/ada-test-player` | Play a sequence from source files | `/ada-test-player randomness` |
| Skill Updater | `/ada-skill-updater` | Update or create skills | `/ada-skill-updater all` |
| Orchestrator | `/ada-orchestrator` | Regenerate this onboarding guide | `/ada-orchestrator refresh` |

### Choosing the Right Skill

- **"I need current project state"** -> `/ada-knowledge-updater`
- **"I want to create or edit a map"** -> `/ada-map-expert`
- **"I want to understand a sequence"** -> `/ada-sequence-expert`
- **"I want to understand the code"** -> `/ada-code-guide`
- **"I want to understand the theory"** -> `/ada-queer-theory-expert`
- **"I want to teach someone about an algorithm"** -> `/ada-tutor`
- **"I want to think through a design problem"** -> `/ada-student`
- **"I want to play a sequence"** -> `/ada-test-player`
- **"I want to add documentation"** -> `/ada-code-documenter`
- **"I have any other question"** -> `/ada-question-assistant`

### The Skill Pipeline

**Pipeline A — Starting a new session:**
1. `/ada-knowledge-updater` — get current state
2. `/ada-question-assistant "what changed recently"` — understand context
3. `/ada-orchestrator refresh` — update this guide

**Pipeline B — Adding a new map to a sequence:**
1. `/ada-sequence-expert [sequence]` — understand the current sequence
2. `/ada-map-expert [new map name]` — create the map
3. `/ada-test-player [sequence]` — verify it plays correctly

**Pipeline C — Deep dive into a new algorithm domain:**
1. `/ada-tutor [algorithm]` — understand it conceptually
2. `/ada-code-guide [algorithm path]` — understand the implementation
3. `/ada-queer-theory-expert [algorithm]` — connect to QFEP
4. `/ada-code-documenter [algorithm path]` — document it

---

## Quick-Start Checklist

- [ ] Read `doc/ENTRY.md` — the project entry point with QFEP framework and content chain
- [ ] Check `commons/maps/curriculum_spine.json` — the canonical learning order (19 spine sequences)
- [ ] Skim `doc/reports/SPINE_MAP_BUILD_STATUS.md` — playability at a glance (all clear)
- [ ] Pick a sequence and run `/ada-test-player [sequence]` — experience the content from source
- [ ] Run `/ada-knowledge-updater all` if `SYSTEM_KNOWLEDGE.md` doesn't exist yet
- [ ] Check `doc/reports/SEQUENCE_CONTRACT_AUDIT.md` — 0 blockers, 97 undeclared folders to triage
- [ ] Run `git log --oneline -10` to see recent changes (or use `python tools/ada/ada.py` CLI navigator)
