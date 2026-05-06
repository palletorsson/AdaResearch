# Sequence Overhaul Checklist

Systematic approach for overhauling one sequence at a time. Run through this for each sequence in curriculum order.

## Quick Health Check

```bash
# See all maps in a sequence
python tools/spine_map_workbench.py list-maps --sequence <id>

# Full health report
python C:\Users\palle\clawd\tasks\sequence_health.py <id>

# Validate map quality (when --sequence is fixed)
python scripts/validate_map.py commons/maps/<MapName>/map_data.json -v
```

## Phase 1: Sequence Definition (`sequences/<id>.json`)

Fill in all standard fields:

| Field | What | Priority |
|-------|------|----------|
| `name` | Display name | Required |
| `truth` | One-line thesis | Required |
| `qfep_term` | Which QFEP term (F, E(S), λ, φ) | Required |
| `qfep_connection` | How this sequence connects to QFEP | Required |
| `formula` | Key formula or algorithm | Required |
| `description` | Full description paragraph | Required |
| `layer` | Curriculum layer (primitives/behaviors/etc) | Required |
| `prerequisites` | Which sequences must come first | Required |
| `unlocks` | Which sequences this enables | Required |
| `difficulty` | beginner/intermediate/advanced/expert | Required |
| `estimated_time` | Playthrough time | Nice-to-have |
| `learning_objectives` | What player learns | Required |
| `content` | Map descriptions (one per map) | Required |
| `maps` | Ordered map list | Required |
| `axiom_files` | Tutorial text paths | Nice-to-have |
| `algorithm_paths` | Algorithm scene paths | Nice-to-have |
| `return_to` | Where to go after (usually "lab") | Required |
| `lab_map` | Post-map path | Required |
| `completion_rewards` | Badge/unlock names | Nice-to-have |

## Phase 2: Map Order & Flow

Review the map list for pedagogical flow:

1. **Progression**: Do maps build from simple → complex?
2. **First map**: Is it a gentle introduction?
3. **Last map**: Does it synthesize what was learned?
4. **Pacing**: Are there breather maps between intense ones?
5. **Remove/move**: Any maps that don't belong? (→ devexamples or another sequence)
6. **Add**: Any gaps in the learning arc?

## Phase 3: Map Data Quality

For each map in the sequence:

### Structure Layer
- [ ] Dimensions match (structure = utilities = interactables row/col count)
- [ ] 2×2 spawn safety at spawn point
- [ ] Reasonable spatial temperature for sequence position
- [ ] Walls form coherent rooms (no orphan cells)

### Utilities Layer  
- [ ] Has spawn point (`s`)
- [ ] Has exit teleporter (`t` or sequence-end return)
- [ ] Transport cubes (`tc`) on `0` in structure
- [ ] One `m:` marker if needed
- [ ] Waypoints (`wp`) placed sensibly

### Interactables Layer
- [ ] Artifacts are registered (in `grid_artifacts.json` or `registry/*.json`)
- [ ] Artifacts on valid cells (not void `0` unless intentional)
- [ ] Artifact rotation/scale params reasonable
- [ ] Directionality respected (displays face walkable space)

### General
- [ ] Valid JSON (no trailing commas for Python tools)
- [ ] Compact row formatting (use `scripts/format_map_json.py`)

## Phase 4: Documentation (4 files per map)

Each map folder should have:

| File | Content | Guide |
|------|---------|-------|
| `blurb.md` | Poetic hook — the entry point | Short, evocative, makes you want to enter |
| `summary.md` | What the map teaches, spatial logic, key interactions | Practical overview |
| `technical.md` | Code examples, implementation details | Uses ada-tutor skill |
| `critical.md` | Queer theory critique — what does this normalize/exclude? | Uses ada-theorist skill |

For writing docs, use the specialized skills:
- `ada-tutor` for technical.md
- `ada-theorist` for critical.md

## Phase 5: Lab Integration

- [ ] Post-map exists: `Lab/map_data_post_<id>.json`
- [ ] Post-map is correct type (gate with new teleporters, or neutral copy of parent)
- [ ] Teleporter in Lab points to this sequence
- [ ] Post-map propagates correctly to downstream maps

## Phase 6: Validation

```bash
# Validate all maps in sequence
for map in $(python tools/spine_map_workbench.py list-maps --sequence <id> --flat); do
    python scripts/validate_map.py "commons/maps/$(echo $map | cut -d/ -f2)/map_data.json" -v
done

# Check lab chain still consistent  
python C:\Users\palle\clawd\tasks\consistency_check.py

# Regenerate reports
python tools/spine_map_workbench.py status --report doc/reports/SPINE_MAP_BUILD_STATUS.md
```

## Sequence Priority Order

Based on curriculum progression and current completeness:

### Tier 1 — Foundation (do first)
1. `primitives` — 11/12 docs ✅ (nearly done, finish One_Primitives)
2. `transformation` — needs check
3. `color` — needs check

### Tier 2 — Core Branches
4. `forces`
5. `array_tutorial`
6. `wavefunctions`
7. `noise`
8. `randomness`

### Tier 3 — Pattern Recognition  
9. `cellularautomata`
10. `lsystems`
11. `fractals`

### Tier 4 — Generation & Emergence
12. `proceduralgeneration`
13. `softbodies`
14. `swarmintelligence`
15. `morphogenesis`

### Tier 5 — Advanced
16. `machinelearning`
17. `graphtheory`
18. `foundationscrisis`

### Tier 6 — Synthesis
19. `qfeplaboratory`
20. `speculativecomputation`
21. `criticalalgorithms`
