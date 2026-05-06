# Nature System — Entities

Base class for every living thing in the Nature System.

## CritterEntity

`CritterEntity` (`critter_entity.gd`) is the Node3D base class that all five kingdoms extend. It owns a `CritterDNA` Resource and uses `CritterTraitMapper` to express genes as visual form.

### Lifecycle

1. Instantiate the scene.
2. Call `init_from_dna(dna)` — or assign `dna` in the inspector.
3. `_apply_visual_traits()` builds mesh and materials.
4. `_apply_gameplay_traits()` sets behavior parameters.
5. `dna_applied` signal fires — external systems can react.

### Runtime State

- **Bond level** (0–1) — drives transmutation overlay visuals.
- **Energy / metabolism** — consumed over time, replenished by interactions.
- **Age** — tracks lifetime for fitness evaluation.

### Signals

| Signal | Description |
|--------|-------------|
| `dna_applied` | Fired after visual and gameplay traits are built |
| `bond_changed` | Player bond level updated |
| `energy_changed` | Energy value changed |
| `transmutation_ready` | Bond threshold reached — ability unlock available |

## Files

- `critter_entity.gd` — CritterEntity base class.

See the parent [Nature System README](../README.md) for architecture and system overview.
