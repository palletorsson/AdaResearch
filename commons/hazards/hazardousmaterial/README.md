# Hazardous Material

Toxic/radioactive environmental zone with 6 material types and lingering damage after exit.

## Behavior

Extends `Area3D`. 6 types: TOXIC_GAS, RADIOACTIVE, ACID, LAVA, ELECTRICITY, FREEZING.

- Damage per second: 5.0, plus initial burst on entry: 10.0
- Lingering damage after exit: 2.0/s for 3.0s
- Reduces visibility and slows movement (0.5x multiplier) conditionally
- Radius 3.0 with intensity multiplier
- 200-count particle emitter with warning mesh

## Files

| File | Purpose |
|------|---------|
| `hazardousmaterial.gd` | Main script — damage tracking, lingering effects |

## Signals

- `player_entered_hazard` / `player_damaged` / `player_left_hazard`

## Key State

`ExposureData` per player tracks exposure time, last damage time, and lingering timer.
