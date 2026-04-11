# Chemical Apparatus

Chemistry station with bubbling flasks, beakers, and test tubes animated by phase-offset sine waves. Includes a Bunsen burner flame.

## Behavior

- Flask and beaker liquids bob vertically at bubble_frequency
- Each vessel has a phase offset (phase_offset_per_vessel) creating a wave propagation effect
- Test tube liquid levels oscillate with individual colors
- Flame light flickers at flame_flicker_speed

## Files

| File | Purpose |
|------|---------|
| chemicalapparatus.gd | LabChemicalApparatus -- procedural build + bubble animation |
| chemicalapparatus.tscn | Scene |
