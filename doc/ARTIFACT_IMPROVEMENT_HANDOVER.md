# Artifact Improvement Handover

> Work through all 19 spine sequences, improving every artifact's documentation, code, and screenshots using `/ada-artifact-improver`.

## The Skill

```
/ada-artifact-improver auto registry:physics_simulation    # all in one registry
/ada-artifact-improver auto worst 10                       # 10 worst globally
/ada-artifact-improver bulging_tunnel                      # single (with approval)
```

The skill runs a 4-phase loop: **SCAN → PLAN → EXECUTE → VERIFY**. In auto mode it skips approval. Each artifact gets:

1. **Documentation** — 5-layer description, QFEP connection, capacity statement, interactions, tags, Gamwell reference
2. **Code** — class_name, @identity block (if missing), apply_grid_config stub
3. **Screenshot** — Godot capture with optimal camera params, AABB→footprint written back

## Scoring

Each artifact is scored 0-8:

| # | Field | Present if... |
|---|-------|---------------|
| 1 | description | >20 chars, multi-sentence |
| 2 | qfep_connection | Non-empty |
| 3 | gamwell_reference | Non-empty |
| 4 | interactions | Array >=1 entry |
| 5 | signals | Array >=1 entry |
| 6 | capacity | Non-empty |
| 7 | tags | >=5 entries |
| 8 | footprint | [x,y,z] not all [1,1,1] |

## Priority Order (worst first)

Work the sequences in this order — worst average score and most artifacts needing work first:

| # | Sequence | Arts | Avg | Need Work | Priority |
|---|----------|------|-----|-----------|----------|
| 1 | graphtheory | 12 | 1.2 | 12 | **all need work** |
| 2 | transformation | 22 | 1.2 | 21 | **nearly all** |
| 3 | primitives | 68 | 1.4 | 66 | **largest sequence, most work** |
| 4 | array_tutorial | 22 | 1.5 | 21 | |
| 5 | color | 25 | 1.5 | 22 | |
| 6 | fractals | 51 | 1.7 | 43 | |
| 7 | proceduralgeneration | 15 | 1.7 | 13 | |
| 8 | wavefunctions | 83 | 1.8 | 67 | **largest, many audio artifacts** |
| 9 | qfeplaboratory | 31 | 1.8 | 26 | |
| 10 | softbodies | 20 | 1.9 | 16 | |
| 11 | cellularautomata | 26 | 2.0 | 21 | |
| 12 | swarmintelligence | 15 | 2.1 | 9 | |
| 13 | randomness | 54 | 2.2 | 34 | footprints done |
| 14 | noise | 20 | 2.4 | 17 | footprints done |
| 15 | machinelearning | 24 | 2.4 | 13 | |
| 16 | lsystems | 17 | 2.8 | 7 | footprints done, mostly improved |
| 17 | postfoundationscrisis | 5 | 3.4 | 0 | **done** |
| 18 | forces | 65 | 3.6 | 29 | partially improved this session |
| 19 | foundationscrisis | 25 | 4.3 | 9 | best baseline |

**Total: 600 artifacts across 19 sequences, ~445 need work (<3/8).**

## How to Process Each Sequence

### Step 1: Run footprint detection (if not done)
```bash
godot --path . --xr-mode off --no-window \
  --script res://commons/testing/detect_footprints.gd \
  -- --sequence=graphtheory --timeout=20
```
Already done for: randomness, noise, lsystems, fractals, cellularautomata, swarmintelligence, forces.

### Step 2: Run the improver on the registry
```
/ada-artifact-improver auto registry:graphtheory
```
Or for large registries that span multiple files:
```
/ada-artifact-improver auto worst 10
```

### Step 3: Verify
```bash
python -c "import json; json.load(open('commons/artifacts/registry/FILENAME.json', encoding='utf-8')); print('valid')"
```

### Step 4: Commit
```
feat: improve {sequence} artifacts — docs, code, screenshots
```

## Per-Sequence Notes

### graphtheory (12 arts, avg 1.2 — worst)
Registry: `algorithms_misc.json` (shared with many others)
Key artifacts: graphspace, KonigsbergBridge, mst_visualization, pathfinding_visualization
Most have @identity blocks. Graph algorithms are well-suited for QFEP (F=structure, E=search).

### transformation (22 arts, avg 1.2)
Registry: `primitives.json` (shared)
Key artifacts: geometric_transformations, scale_me, rotation_match_puzzle
These are fundamental math operations — good QFEP connections to F (deterministic transforms).

### primitives (68 arts, avg 1.4 — largest low-scoring)
Registry: `primitives.json`
Includes: points, lines, triangles, cubes, platonic solids, puzzles
Many are tiny procedural artifacts. Batch-improvable because they share the same pattern.

### wavefunctions (83 arts, avg 1.8 — largest overall)
Registry: `wavefunctions.json` + `physics_simulation.json`
Includes: audio synths, oscillators, pendulums, wave visualizations, SoundscapeRadioRack
Audio artifacts may timeout during capture (no visual output). Skip screenshots for audio-only.

### qfeplaboratory (31 arts, avg 1.8)
Registry: `qfep.json`
The QFEP artifacts ARE the formula — every one should have a qfep_connection by definition.
Many are status:"planned" — flag but don't fabricate descriptions for unbuilt artifacts.

### forces (65 arts, avg 3.6 — partially done)
Registry: `physics_simulation.json` + `vectors.json`
15 core physics artifacts already improved this session. 29 still need work.
The example_* Nature of Code translations are the bulk — batch-improvable.

### foundationscrisis (25 arts, avg 4.3 — best baseline)
Registry: `foundations.json`
Already the gold standard — use as template for what "done" looks like.

## What "Done" Looks Like

An artifact at 7-8/8 has:
- 5-layer description sourced from @identity truth/essence/desire
- QFEP connection mapped from category
- Gamwell reference from registry theoretical_grounding
- Capacity statement: "VERB what_the_learner_can_do"
- Interactions list from @identity needs/triggers
- Tags: 5-10 keywords
- Footprint: real AABB measurement from Godot capture
- (Optional) signals from GDScript declarations

Code additions (conservative):
- `class_name PascalCase`
- `@identity` block (8 lines) if missing
- `apply_grid_config()` stub if missing

## Key Files

| File | Purpose |
|------|---------|
| `.claude/skills/ada-artifact-improver/SKILL.md` | The improvement skill |
| `commons/artifacts/improvement_log.json` | Tracks what was improved |
| `commons/artifacts/registry/*.json` | All artifact registries (17 files) |
| `commons/testing/detect_footprints.gd` | Godot headless footprint detection |
| `tools/auto_structure_generator.py` | MST corridor generation from footprints |

## Session Stats (April 8, 2026)

- 27 artifacts improved from 0/8 → 6-7/8
- 688 real footprints measured across 7 sequences
- 5 GDScript files improved (wireframe fix, trails, @identity, class_name)
- 3 blog posts written
- Artifact improver skill created and tested
- Footprint detection script created and tested
- Auto-structure API created (TypeScript MST)
- Voxel editor: ?map= auto-load, ghost cubes, right panel sequence browser, auto-structure proposal
- Artifact detail page: screenshot header added
- Artifacts page: "By Sequence" view added
- Scene catalog: grid view as default
