# AdaResearch — Project Entry Point

> **For new contributors and AI assistants: Start here.**

## What Is This?

**AdaResearch** is a VR/desktop educational platform built in Godot 4 that teaches computational geometry and algorithms through embodied interaction and critical theory.

Named after **Ada Lovelace** (1815-1852), who first envisioned that computation could generate art and music, not just crunch numbers.

**The core idea:** You learn algorithms by *touching* them in VR, manipulating parameters, seeing emergence happen. Each algorithm comes with both technical explanation AND critical theory examining the politics of computation.

---

## Quick Stats (Live from Project)

| Metric | Count | Source |
|--------|-------|--------|
| **Sequences** | 42 | `commons/maps/sequences/*.json` |
| **Maps** | 503 | `commons/maps/*/map_data.json` |
| **Artifacts** | 749+ | `commons/artifacts/grid_artifacts.json` |
| **Algorithm folders** | 639 | `algorithms/` |
| **Spine sequences** | 18 | `curriculum_spine.json` |

---

## The QFEP Framework

Everything is organized around the **Queer Free Energy Principle**:

```
QFE = F − λE(S) + φΔE(S,t)
```

| Symbol | Meaning | Curriculum Phase |
|--------|---------|------------------|
| **F** | Free energy (order, prediction) | `primitives`, `transformations` |
| **E(S)** | Entropy (disorder, randomness) | `randomness`, `noise`, `cellularautomata` |
| **λ** | Order↔chaos balance (0→1) | `fractals`, `lsystems` |
| **φΔE** | Rate of change (queer signature) | `morphogenesis`, `swarmintelligence` |

**Life exists at λ ≈ 0.3-0.5** — enough order to maintain identity, enough chaos to adapt.

---

## Project Structure (Truth Sources)

### 🔴 Primary Truth (Authoritative)

| Path | What It Contains |
|------|------------------|
| `commons/maps/curriculum_spine.json` | The 18-sequence learning progression |
| `commons/maps/sequences/*.json` | All 42 sequence definitions with maps |
| `commons/maps/{MapName}/map_data.json` | Individual map data (grid layers, artifacts) |
| `commons/artifacts/grid_artifacts.json` | Legacy artifact registry (749 entries) |
| `commons/artifacts/registry/*.json` | New modular registries |
| `algorithms/` | Actual algorithm implementations |

### 🟡 Secondary Truth (Documentation)

| Path | What It Contains |
|------|------------------|
| `doc/ARCHITECTURE.md` | Technical system reference |
| `doc/TAXONOMY.md` | Generative paradigms framework |
| `doc/README.md` | Project overview |

### 🔵 Validation Tools

| Tool | Purpose |
|------|---------|
| `commons/dev_tools/ContentValidatorDesktop.tscn` | **Run this** to see real content state |
| `commons/dev_tools/validation_report.md` | Exported validation report |

**⚠️ Documentation can be outdated. When in doubt, run the validator or check the JSON files.**

---

## Content Chain

```
Sequences → Maps → Artifacts → Scenes
    ↓          ↓         ↓          ↓
  .json    map_data   registry   .tscn/.gd
            .json      .json
```

### Sequence Structure
```
commons/maps/sequences/primitives.json
{
  "sequences": {
    "primitives": {
      "name": "Primitives: Points Build Worlds",
      "truth": "A point is position without extension...",
      "qfep_connection": "...",
      "maps": ["Point_One", "Point_Lines", ...],
      "learning_objectives": [...]
    }
  }
}
```

### Map Structure
```
commons/maps/Point_One/
├── map_data.json      # Grid layers, artifact placements
├── blurb.md           # Poetic hook
├── summary.md         # Overview
├── technical.md       # Code examples
└── critical.md        # Queer theory critique
```

### Map Layers (in map_data.json)
```json
{
  "layers": {
    "structure": [[...]],      // Walls, floors, ceilings
    "utilities": [[...]],      // Lights, sounds, teleporters
    "interactables": [[...]]   // Artifacts to manipulate
  }
}
```

---

## Curriculum Spine (18 Sequences)

The recommended progression through QFEP phases:

| # | Sequence | Phase | Focus |
|---|----------|-------|-------|
| 1 | `primitives` | F_order | Points, lines, planes |
| 2 | `transformations` | F_order | Rotation, scale, dot/cross products |
| 3 | `wavefunctions` | oscillation | Sine, audio, oscillation |
| 4 | `forces` | oscillation | Newton, physics vectors |
| 5 | `randomness` | E_entropy | Distributions, entropy |
| 6 | `noise` | E_entropy | Perlin, flow fields |
| 7 | `cellularautomata` | E_entropy | Game of Life, rules→patterns |
| 8 | `fractals` | lambda_edge | Self-similarity, recursion |
| 9 | `lsystems` | lambda_edge | Grammar-based growth |
| 10 | `proceduralgeneration` | lambda_edge | WFC, Markov |
| 11 | `morphogenesis` | integration | Turing patterns |
| 12 | `swarmintelligence` | integration | Boids, emergence |
| 13 | `softbodies` | integration | Deformable physics |
| 14 | `machinelearning` | integration | Neural nets |
| 15 | `foundationscrisis` | synthesis | Gödel, Russell, limits |
| 16 | `qfeplaboratory` | synthesis | Full QFEP embodied |
| 17 | `speculativecomputation` | synthesis | Queer futures |
| 18 | `criticalalgorithms` | synthesis | Algorithmic bias |

Plus **24 branch sequences** that unlock from spine points.

---

## Key Entry Points for Development

### To understand the grid system:
```
commons/grid/GridSystem.gd
commons/grid/GridComponentFactory.gd
```

### To add a new artifact:
1. Create scene in `commons/artifacts/{name}/`
2. Register in `commons/artifacts/registry/{category}.json`
3. Place in map's `interactables` layer

### To add a new map:
1. Create `commons/maps/{MapName}/map_data.json`
2. Add map name to sequence's `maps` array
3. Add 4 markdown files (blurb, summary, technical, critical)

### To test a map:
```
Run: commons/scenes/desktop_map_tester.tscn
Or:  commons/dev_tools/ContentValidatorDesktop.tscn
```

---

## What Makes This Project Different

1. **Dual-lens pedagogy**: Every algorithm has both technical AND critical theory content
2. **Embodied learning**: VR interactions — grab vectors, tune parameters, see emergence
3. **QFEP framework**: Unified theoretical structure connecting order↔chaos
4. **Generative incompleteness**: The project is deliberately unfinished — you learn by filling gaps

---

## Documentation Index

| Document | Purpose | Trust Level |
|----------|---------|-------------|
| `doc/ENTRY.md` | **You are here** | 🟢 Current |
| `doc/ARCHITECTURE.md` | Technical systems | 🟡 Mostly current |
| `doc/TAXONOMY.md` | 8 generative paradigms | 🟢 Current |
| `doc/README.md` | Project overview | 🟡 Mostly current |
| `doc/VR_GAMEPLAY_DESIGN.md` | VR design philosophy | 🟡 |
| `doc/QFEP_GAMWELL_MAPPING.md` | Theory grounding | 🟢 |
| `doc/ARTIFACT_DEVELOPMENT_PLAN.md` | Build roadmap | 🟡 |

**When in doubt:** Run `ContentValidatorDesktop.tscn` or check the JSON source files.

---

## For AI Assistants

1. **Read this file first**
2. **Check `curriculum_spine.json`** for current sequence structure
3. **Check `commons/maps/sequences/*.json`** for map lists
4. **Run validator** to see actual content state
5. **Documentation may be stale** — project files are the truth

### Common Tasks
- "Add an artifact" → See registry files + map_data.json
- "Check what maps exist" → Count map_data.json files
- "Understand curriculum" → curriculum_spine.json
- "See what's broken" → Run ContentValidatorDesktop

---

*Last updated: 2026-02-03*
*To verify this doc: run `commons/dev_tools/ContentValidatorDesktop.tscn`*
