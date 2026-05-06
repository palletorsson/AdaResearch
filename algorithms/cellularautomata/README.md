# Cellular Automata

Simple rules, complex emergence. Discrete cells evolving in parallel create patterns from chaos.

## QFEP Connection

Cellular automata embody the **λ edge of chaos**: Rule 110 is computationally universal, Game of Life generates infinite complexity from four rules, and the transition from order (rule 0) to chaos (rule 30) maps directly onto the λ parameter.

```
λ = 0    → Static (all cells die or freeze)
λ = 0.5  → Edge of chaos (complex patterns, Rule 110)
λ = 1    → Chaos (random noise, no structure)
```

## Contents

### Core Implementations

| Folder | Description |
|--------|-------------|
| `cellular_automata_1d/` | Elementary CA — Wolfram's 256 rules visualized as 3D walls |
| `cellular_automata_2d/` | Game of Life and variants on 2D grids |
| `cellular_automata_3d/` | Full 3D cellular automata with volumetric rules |
| `cellular_automata_3d_stacked/` | 1D CA stacked over time into 3D structures |
| `cellular_automata_3d_tree/` | Tree-like growth patterns via 3D CA |
| `rule_30_110/` | Famous elementary rules — chaos (30) vs computation (110) |

### Architectural / Artistic CA

| Folder | Description |
|--------|-------------|
| `ca_bridge/` | Bridge structures grown via CA rules |
| `ca_columns/` | Architectural columns generated from automata |
| `living_architecture/` | Buildings that grow and evolve |
| `persian_rug/` | Persian rug patterns (symmetric 2D CA) |
| `sierpinski_pyramid/` | Sierpinski triangle extruded to 3D pyramid |
| `CAchairtests/` | Furniture generation through CA |

### Natural Phenomena

| Folder | Description |
|--------|-------------|
| `ca_showcase/` | **13 CA variants** — disease spread, dendrite growth, avalanches, ecosystems, percolation, recrystallization, cracks, self-organization |
| `ca_growth_network/` | Network growth patterns |
| `CA_sphere/` | CA on spherical surfaces |
| `lattice_gas_automata/` | Microscopic particle dynamics for fluid simulation |
| `volumetric_fog/` | Fog/cloud generation via CA |

### Utilities

| Folder | Description |
|--------|-------------|
| `ca_screen/` | CA displayed on in-game screens/monitors |
| `crossway_ca/` | Crossroad/intersection patterns |
| `cellularautomata/` | Core shared utilities |
| `noc_ch07/` | Nature of Code Chapter 7 implementations |

## Key Classes

- `BaseCA` — Base class for all CA implementations (64³ grid, MultiMesh rendering)
- `CellularAutomata1D`, `CellularAutomata2D`, `CellularAutomata3D` — Dimension-specific runners
- `CAMenu` — Interactive menu for switching between CA types

## Educational Value

1. **Emergence** — Simple local rules → complex global behavior
2. **Computation** — Rule 110 proves CA can compute anything
3. **Phase transitions** — Sharp boundary between order and chaos
4. **Natural modeling** — Fire spread, crystal growth, epidemics, ecology

## VR Experience

- Walk through 3D CA as they evolve in real-time
- Scale from cell-level to global patterns
- Interact with initial conditions
- Watch time evolution as spatial depth

## Files

- 41 GDScript files
- 41 scene files
- 15 documentation files
