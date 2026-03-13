# Crack Propagation Cellular Automaton

A stress-driven cellular automaton that simulates crack formation and propagation across a 2D surface, rendered as 3D mesh geometry on the XZ plane. This artifact teaches how material fracture patterns emerge from local stress accumulation, diffusion, and directional propagation -- the same principles that govern cracking in dried mud, aging paint, and geological fractures.

## How It Works

The simulation runs on a 2D grid where each cell has a **state** (Intact, Stressed, or Cracked) and a **stress value** (0.0 to 1.0):

1. **Initialization**: 5% of cells receive small random stress values (0.1--0.25) as weak spots. A high-stress seed is placed at the grid center.
2. **Each frame**, three sub-steps execute:
   - **Stress diffusion and decay**: Stress values diffuse slightly toward neighbors (averaging) and decay over time, simulating material relaxation.
   - **State transitions**: Intact cells accumulate stress from cracked neighbors via `PROPAGATION_RATE`. When stress exceeds `CRACK_THRESHOLD`, they become Stressed. Stressed cells probabilistically crack based on local stress and number of cracked neighbors.
   - **Branching**: Cracked cells can spawn new crack arms in neighboring cells. Candidate directions are scored by alignment with the cell's existing crack direction (`DIRECTION_BIAS`) and local stress, favoring straight propagation with occasional branching.
3. **Direction memory**: Each cracked cell stores a `Vector2` direction from its parent, and new arms prefer to continue in that direction, producing realistic linear cracks rather than random scatter.

Crack geometry is rendered as quad strips (triangle pairs) whose width varies with local stress, built into an `ArrayMesh` each frame.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `GRID_SIZE` | int | 64 | Cells per side of the simulation grid |
| `CELL_SIZE` | float | 0.25 | World meters per cell |
| `SEED` | int | 0 | Random seed (0 = randomize) |
| `CRACK_THRESHOLD` | float | 0.30 | Stress level needed to transition from Intact to Stressed |
| `PROPAGATION_RATE` | float | 0.06 | Stress transferred from cracked cells to intact neighbors |
| `STRESS_DIFFUSE` | float | 0.04 | Rate of general stress diffusion across neighbors |
| `STRESS_DECAY` | float | 0.02 | Stress relaxation per simulation tick |
| `CRACK_PROPAGATION_CHANCE` | float | 0.55 | Probability a cracked cell spawns a new arm each step |
| `MAX_BRANCHES_PER_STEP` | int | 400 | Safety cap on new crack arms per frame |
| `DIRECTION_BIAS` | float | 0.6 | How strongly new arms prefer to follow existing crack direction |
| `CRACK_COLOR` | Color | (0.08,0.05,0.04) | Dark brown crack line color |
| `CRACK_WIDTH_BASE` | float | 0.02 | Minimum crack line width in meters |
| `CRACK_WIDTH_STRESS_SCALE` | float | 0.15 | Additional width based on local stress |
| `EMISSIVE` | float | 0.0 | Emission energy (set > 0 for faint glow) |

## Features

- **Three-state cellular automaton** -- Intact, Stressed, and Cracked states model progressive material failure
- **Directional memory** -- each cracked cell stores its propagation direction, producing realistic linear cracks with natural branching
- **Stress-based width** -- crack lines are thicker where stress is higher, thinner at tips
- **Greedy path tracing** -- mesh generation traces connected crack chains for smooth line rendering
- **Public API** -- `add_stress_point(world_pos, amount)` lets external systems (e.g., VR interactions) trigger cracks at specific locations; `get_stress_at(world_pos)` reads local stress

## Files

- `crackpropagation_ca.gd` -- Full simulation: grid management, stress diffusion, state transitions, directional branching, ArrayMesh quad-strip rendering
- `crackpropagation_ca.tscn` -- Scene file
