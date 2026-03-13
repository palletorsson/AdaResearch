# Branching Growth Algorithm -- Continued

An extended version of the space colonization branching algorithm that adds continuous growth, lifecycle phases, branch aging, energy systems, and environmental influences. This artifact teaches how biological systems sustain and regulate growth over time -- not just the initial burst of branching, but the ongoing cycle of sprouting, maturation, dormancy, and renewal.

## How It Works

This builds on the base space colonization algorithm and layers on several systems:

1. **Continuous growth** -- Instead of halting when attractors run out, the system regenerates new attractors over time in an expanding radius, keeping growth perpetual.
2. **Growth phases** -- The system cycles through four seasonal phases (Rapid Growth, Steady Growth, Flowering, Dormant), each adjusting growth speed, segment length, and visual effects.
3. **Branch lifecycle** -- Each branch tracks its `age` and `energy`. Energy decays over time and is inherited (at 90%) from parent branches. Branches marked `is_dying` fade out and stop growing. Old branches (beyond `branch_lifespan * 2`) are fully deactivated.
4. **Attractor regeneration** -- New attractor clusters spawn periodically, with 30% marked as temporary (self-removing after 15 seconds). The spawning radius expands as time passes.
5. **Environmental effects** -- A simulated wind randomly nudges active branch directions. Seasonal hue shifts alter coloring over time.
6. **Energy-modified growth** -- Branch energy affects attraction range (weaker branches see shorter distances), growth distance, jitter intensity, and visual brightness.

Rendering and color cycling use the same ImmediateMesh line approach and pride flag palette system as the base version.

## Parameters

All parameters from the base version plus:

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `continuous_growth` | bool | true | Keep generating new attractors and growing indefinitely |
| `growth_phases` | bool | true | Enable seasonal phase cycling |
| `seasonal_changes` | bool | true | Enable seasonal hue shifts in coloring |
| `branch_lifespan` | float | 30.0 | Seconds before a branch begins dying |
| `attractor_regeneration_rate` | float | 0.5 | New attractor clusters spawned per second |
| `environmental_influence` | bool | true | Enable wind-like directional perturbation |
| `growth_acceleration` | float | 1.0 | Speed multiplier (changes with growth phase) |

## Features

- **Perpetual organic growth** -- the structure never stops evolving, modeling real biological systems
- **Four growth phases** -- Rapid (1.5x speed, longer segments), Steady (1x), Flowering (0.8x with sparkles), Dormant (0.3x, short segments)
- **Branch energy system** -- parent-to-child energy inheritance with gradual decay creates natural tapering
- **Temporary attractors** -- 30% of regenerated attractors auto-remove, creating dynamic "bloom and fade" patterns
- **Wind simulation** -- random directional perturbation applied to active branches each second
- **Extended keyboard controls** -- G (toggle continuous growth), +/- (acceleration), F (toggle phases), E (toggle environment), N (force new attractors), L (toggle seasonal colors)
- **Enhanced stats** -- `get_growth_stats()` returns dying count, temporary attractors, average energy, current phase, elapsed time

## Files

- `branching_growth_algorithm.gd` -- Extended space colonization with continuous growth, lifecycle phases, energy system, environmental effects
- `BranchingGrowthAlgorithm.tscn` -- Scene file
