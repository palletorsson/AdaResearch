# Paradox Stalker

Self-contradicting creature with two ghost silhouettes that swap which is "real" — teaches paradoxes and limits of formalization.

## Behavior

Extends `HazardCreatureBase`. Foundations Crisis hazard.

- Two overlapping ghost meshes (A: magenta, B: cyan) with transparency
- Periodically swaps which silhouette is "real" (swap interval 3.0s)
- Zeno's paradox: 15% chance to halve remaining distance instead of arriving
- Lunge attacks from the "real" ghost
- Labels identify real vs ghost state

## Files

| File | Purpose |
|------|---------|
| `paradox_stalker.gd` | Main script — dual ghost logic, Zeno behavior, swap timer |
| `paradox_stalker.tscn` | Scene |
