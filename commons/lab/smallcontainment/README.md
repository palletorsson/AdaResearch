# Small Containment

Desktop containment cube with energy field, status indicators, and field projectors. Monitors containment integrity and emits breach warnings.

## Behavior

- Energy field and projector animations run continuously
- Contained specimen floats with animation
- field_strength and containment_breach_risk tracked over time
- Signals: containment_stabilized, breach_warning, specimen_contained, field_fluctuation

## Files

| File | Purpose |
|------|---------|
| containment_cube.gd | Field animation, breach monitoring, specimen floating |
| smallcontainment.tscn | Scene with walls, projectors, indicators |
