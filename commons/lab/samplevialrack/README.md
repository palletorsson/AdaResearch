# Sample Vial Rack

Rack of glowing vials demonstrating phase relationships -- each vial pulses with a phase offset, creating a wave propagation visualization.

## Behavior

- num_vials vials arranged in a rack with individual sample_colors
- Phase offsets computed per phase_mode: linear, radial, or random
- Glow intensity oscillates between glow_min and glow_max at wave_frequency

## Files

| File | Purpose |
|------|---------|
| samplevialrack.gd | LabSampleVialRack -- phase calculation + glow animation |
| samplevialrack.tscn | Scene |
