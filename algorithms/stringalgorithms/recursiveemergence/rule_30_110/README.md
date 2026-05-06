# Rule 30/110 Elementary Cellular Automata

A side-by-side visualization of two elementary cellular automata -- Rule 30 and Rule 110 -- that grow generation by generation in 3D. An extended gravity variant adds Rules 90 and 150 plus a pyramid, turning each pattern into a physics-based falling-cube sculpture. The artifact teaches how radically different emergent behavior can arise from nearly identical simple rules.

## Concept Taught

**Elementary cellular automata** are one-dimensional systems where each cell is either 0 or 1, and the next generation is computed by looking at each cell and its two neighbors. A three-bit pattern (left, center, right) maps to a single output bit; the eight possible mappings encode the rule number in binary. Rule 30 produces **chaotic**, pseudorandom output, while Rule 110 produces **complex** structured patterns and is known to be Turing-complete. The visualization highlights this contrast by showing both grids evolving simultaneously and measuring entropy, periodicity, and complexity in real time.

## How It Works

### Base Script (`Rule30110.gd`)

1. A 51-cell wide row is initialized with a single active cell in the center.
2. Each generation, the `apply_rule_30` and `apply_rule_110` functions compute the next row using wraparound boundary conditions.
3. Active cells are drawn as small emissive CSGBox3D cubes -- orange/yellow for Rule 30, blue for Rule 110.
4. A comparison panel shows the eight input-output mappings for each rule side by side.
5. Pattern analysis functions compute **entropy** (Shannon entropy over 3-bit windows), **periodicity** (row-level repetition detection), and **Kolmogorov-like complexity** (cell-transition ratio), visualized as bar charts.
6. After reaching `max_generations` the simulation resets.

### Gravity Variant (`Rule30110Gravity.gd`)

1. Extends the base script and replaces static cubes with `RigidBody3D` nodes that start frozen in place.
2. Cycles through five modes: Rule 30, Rule 110, Rule 90, Rule 150, and a stacked pyramid.
3. When a generation sequence finishes, all rigid bodies are unfrozen and fall under gravity, collapsing the pattern into a physics pile.
4. After a 5-second pause the next rule takes over.

## Parameters

Defined as class variables (not `@export`):

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `grid_width` | int | `51` | Number of cells per row |
| `max_generations` | int | `30` (base) / `12` (gravity) | Generations before reset |
| `generation_speed` | float | `0.3` | Seconds between generations |

## Features

- Side-by-side Rule 30 vs Rule 110 visualization with distinct color palettes.
- Rule comparison panel showing all eight input/output mappings.
- Live entropy, periodicity, and complexity metrics displayed as 3D bar charts.
- Gravity variant cycles through Rules 30, 110, 90, 150, and a stacked pyramid.
- Physics-based collapse: frozen rigid bodies with collision shapes unfreeze after the pattern completes.
- Wraparound (toroidal) boundary conditions.

## Files

- `Rule30110.gd` -- Base script: Rule 30 and Rule 110 logic, CSG visualization, pattern analysis metrics.
- `Rule30110Gravity.gd` -- Extended gravity variant: Rules 90/150, pyramid mode, RigidBody3D falling cubes.
