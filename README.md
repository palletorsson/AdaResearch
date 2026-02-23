# AdaResearch

> A VR/desktop meta-quest into algorithms, exploring the queer potential within mathematical objects

Named after **Ada Lovelace**, who in 1842 wrote about computation's capacity for generative art. AdaResearch asks: *Can we put Paul Klee's Pedagogical Sketchbook in Virtual Drag?*

## 🎯 Vision

AdaResearch is an educational VR/desktop platform built in Godot 4 that teaches algorithms through embodied interaction and critical theory. The project probes for **queer potential within technical objects** — exploring how digital resolution creates "invisible fences" that shape bodies, creativity, and subjectivity.

### The Queer Free Energy Principle (QFEP)

The theoretical framework unifying the curriculum:

```
QFE = F − λE(S) + φΔE(S,t)
```

| Term | Meaning | In the Project |
|------|---------|----------------|
| **F** | Free energy (order, prediction) | Primitives, structure, determinism |
| **E(S)** | Entropy (disorder, freedom) | Randomness, possibility space |
| **λ** | Entropy drive (0→1) | The dial between order and chaos |
| **φΔE(S,t)** | Rate of change sensitivity | Positive φ = queer signature |

**Life exists at λ ≈ 0.3-0.5** — enough order to maintain identity, enough chaos to adapt.

The curriculum embodies this:
- **Primitives** → F maximized (pure order)
- **Wavefunctions** → F ↔ E(S) oscillation
- **Randomness** → E(S) made visible
- **Emergence** → E(S) → F (patterns from noise)

## 🗺️ Learning Sequences

42 sequences organize 500+ maps into learning progressions:

| Sequence | Maps | Focus |
|----------|------|-------|
| `primitives` | 13 | Points, lines, planes, cubes — the building blocks |
| `randomness` | 13 | Entropy, distributions, noise, walks |
| `fractals` | 10 | Self-similarity, recursion, infinite detail |
| `wavefunctions` | — | Audio, oscillation, signal processing |
| `cellularautomata` | — | Local rules → global patterns |
| `lsystems` | — | Grammar-based growth |
| `softbodies` | — | Deformable physics |
| `qfeplaboratory` | 8 | Interactive QFEP exploration |

Each map contains:
- **3-layer grid** — structure, utilities, interactables
- **4 documentation files** — blurb, summary, technical, critical theory

## 🏗️ Architecture

See **[ARCHITECTURE.md](ARCHITECTURE.md)** for complete technical reference.

```
AdaResearch/
├── algorithms/         # 52 categories of algorithm visualizations
├── commons/
│   ├── artifacts/      # 750+ educational objects (registry)
│   ├── audio/          # Procedural sound system
│   ├── grid/           # Component-based map rendering
│   ├── managers/       # Scene, game, progression managers
│   └── maps/           # Map data and sequences
├── core/               # Physics and particle engines
├── addons/             # godot-xr-tools, custom plugins
└── shaders/            # Visual effects
```

### Key Systems

| System | Purpose | Entry Point |
|--------|---------|-------------|
| **Grid** | Renders maps from JSON | `commons/grid/GridSystem.gd` |
| **Artifacts** | Object registry & spawning | `commons/artifacts/registry/` |
| **Sequences** | Curriculum organization | `commons/maps/sequences/` |
| **Audio** | Procedural sound | `commons/audio/SoundBankSingleton.gd` |

## 🎮 Getting Started

### Prerequisites
- Godot 4.x
- VR headset (optional — desktop mode available)

### Quick Start

1. Clone and open in Godot
2. Run `commons/scenes/lab.tscn` — the hub environment
3. Use teleporters to navigate between maps
4. Grab and interact with artifacts

### Desktop Testing
- `commons/scenes/grid_desktop.tscn` — Test any map
- `commons/scenes/desktop_map_tester.tscn` — Map browser

### Release Gates (Onboarding)

Before opening a PR, run the machine gate checks:

```powershell
python tools/run_release_gates.py --max-grade-c -1 --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json
```

Strict mode (all gates must be ON and passing):

```powershell
python tools/run_release_gates.py --max-grade-c -1 --gate-toggles doc/reports/RELEASE_GATES_TOGGLES.json --require-all-gates-enabled
```

Gate toggle file used by dashboard + tooling:
- `doc/reports/RELEASE_GATES_TOGGLES.json`

## 📚 Documentation

| Document | Purpose |
|----------|---------|
| [ENTRY.md](ENTRY.md) | **Start here** — Project entry point |
| [ARCHITECTURE.md](ARCHITECTURE.md) | Technical system reference |
| [TAXONOMY.md](TAXONOMY.md) | Generative paradigms framework |
| [CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md](CLAUDE_GUIDE_TO_PLAYING_ADA_RESEARCH.md) | Gameplay walkthrough |
| [commons/audio/SOUND_SYSTEM_GUIDE.md](commons/audio/SOUND_SYSTEM_GUIDE.md) | Audio system details |
| [commons/scenes/world_map/README.md](commons/scenes/world_map/README.md) | World map modes, VR full-map toggle, hold-to-enter |
| [doc/LAUNCH_GATES.md](doc/LAUNCH_GATES.md) | Release gate policy, strict mode, and CI behavior |
| [doc/SKILL_WORKFLOW.md](doc/SKILL_WORKFLOW.md) | Skill-driven PR workflow and evidence checklist |
| [doc/VR_GAMEPLAY_DESIGN.md](doc/VR_GAMEPLAY_DESIGN.md) | VR design philosophy |
| [doc/QFEP_GAMWELL_MAPPING.md](doc/QFEP_GAMWELL_MAPPING.md) | Theory grounded in art/math history |
| [XR_TOOLS_CHANGES.md](XR_TOOLS_CHANGES.md) | Local patches to `godot-xr-tools` when addon code is ignored |

## 🔄 Recent Development

### February 2026
- ✅ Vector scenes scaled to 1m cube standard
- ✅ ENTRY.md documentation entry point
- ✅ Content validator integration

### January 2026
- ✅ QFEP Laboratory artifacts (sliders, reactor, meters)
- ✅ Trace & Movement Unlock System
- ✅ Procedural generation sequence reorganization
- ✅ Registry cleanup (26 placeholder descriptions fixed)
- ✅ Architecture documentation

### January 2025
- ✅ Singleton Sound Bank system
- ✅ 10 ambient presets with hierarchical configuration
- ✅ 70+ audio parameter files

## 🧭 Project Status

| Area | Status |
|------|--------|
| Grid System | ✅ Production |
| Artifact Registry | ✅ 750+ objects |
| Audio System | ✅ Production |
| VR Integration | ✅ Working |
| Primitives sequence | ✅ 80% documented |
| Randomness sequence | 🔄 Maps done, docs needed |
| Fractals sequence | 🔄 Needs audit |
| Other sequences | 📋 Planned |

## 🤝 Contributing

The project uses component-based architecture for independent development:
- Each algorithm category is self-contained
- Grid system components are modular
- Artifacts can be added via JSON registry
- VR features gracefully degrade to desktop

## 📖 References

- Ada Lovelace's Notes on the Analytical Engine (1842)
- Paul Klee, *Pedagogical Sketchbook* (1953)
- Karl Friston, Free Energy Principle
- Lynn Gamwell, *Mathematics and Art* (2015)
- Daniel Shiffman, *The Nature of Code*

---

*For module-specific documentation, see README files in each subdirectory.*
