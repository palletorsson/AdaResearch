# Lifeform Walker

Walking creature with a 6x6 Game of Life grid on its torso — living cells provide armor, dead cells expose weakness.

## Behavior

Extends `HazardCreatureBase`. Cellular automata hazard.

- 6x6 Conway's Game of Life grid displayed on the creature's body
- CA rules execute each tick (different tick rates for patrol vs chase)
- Living cells = armor (damage absorbed)
- Dead cells = vulnerability (damage passes through)
- Teaches how simple local rules produce global patterns

## Files

| File | Purpose |
|------|---------|
| `lifeform_walker.gd` | Main script — CA simulation, armor system, cell visualization |
| `lifeform_walker.tscn` | Scene |
