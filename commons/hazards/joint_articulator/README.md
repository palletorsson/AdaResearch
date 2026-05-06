# Joint Articulator

Central body with 6 limbs, each demonstrating a different joint type.

## Behavior

Extends `HazardCreatureBase`. Teaches joint mechanics and constrained motion.

6 joint types across 6 color-coded limbs:
1. **HINGE** — Swing in one plane
2. **BALL** — Free rotation
3. **SLIDER** — Extend/retract
4. **REVOLUTE** — Continuous spin
5. **PRISMATIC** — Telescope
6. **FIXED** — Rigid connection

- Walks on bottom 2 limbs
- Joint-constrained attacks during CHASE state
- Labels identify each joint type

## Files

| File | Purpose |
|------|---------|
| `joint_articulator.gd` | Main script — joint animation, constrained attacks |
| `joint_articulator.tscn` | Scene |
