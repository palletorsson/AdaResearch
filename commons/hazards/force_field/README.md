# Force Field

Dual-nature zone embodying the Q-FEP principle: same potential, different restraint, different manifestation.

## Behavior

Extends `Area3D`. 12 force types (fire, vacuum, electric, toxic, radiation, freezing, acid, magnetic, gravity, entropy, resonance, void).

Two modes:
- **HAZARD** — Damages the player
- **TRANSMUTED** — Benefits the player

Transmutation occurs via:
- **Mediator object**: VR-grab a specific item into the field
- **Courage**: Endure exposure long enough

Can revert after configurable delay or stay transmuted.

## Files

| File | Purpose |
|------|---------|
| `force_field.gd` | Main script — mode switching, damage/benefit logic |
| `force_field.tscn` | Scene |
| `force_transmutation_config.gd` | Transmutation rules and timing |
| `force_visual_controller.gd` | Particles, colors, labels per force type |

## Signals

- `mode_changed` — HAZARD ↔ TRANSMUTED
- `transmutation_started` / `transmutation_complete` / `transmutation_reverted`

## Key Parameters

| Parameter | Value |
|-----------|-------|
| `zone_radius` | 1.5 |
| `zone_height` | 2.5 |
| `courage_enabled` | configurable |
