# Electronic Scales

Laboratory scales that demonstrate damped harmonic oscillation -- the display settles toward the target weight with exponentially decaying sine oscillation.

## Behavior

- On weigh trigger, reading oscillates: A * e^(-bt) * sin(wt)
- damping_factor controls decay rate, oscillation_frequency the wobble speed
- LCD display and indicator light update each frame
- Idle state shows gentle noise drift

## Files

| File | Purpose |
|------|---------|
| electronicscales.gd | LabElectronicScales -- damped oscillation + procedural build |
| electronicscales.tscn | Scene |
