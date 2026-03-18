# Microscope

Laboratory microscope with pulsing stage illumination following a sine wave for focus demonstration.

## Behavior

- Stage OmniLight3D intensity oscillates between light_min and light_max
- Objective SpotLight3D has a phase-offset glow
- Optional auto-focus: focus knob oscillates at focus_frequency
- Eyepiece glow mesh tracks illumination state

## Files

| File | Purpose |
|------|---------|
| microscope.gd | LabMicroscope -- procedural build + illumination animation |
| microscope.tscn | Scene |
