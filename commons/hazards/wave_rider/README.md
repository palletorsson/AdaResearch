# Wave Rider

Ribbon of 20 sine-wave segments — teaches frequency, amplitude, and wavelength through combat.

## Behavior

Extends `HazardCreatureBase`. Wave mechanics hazard.

- 20 BoxMesh segments arranged in a sine wave pattern
- Oscillation frequency ramps up on DETECT
- Fires burst at resonance peak (when wave peak aligns with player Y)
- Segment color lerps blue-to-red by sine value

## Files

| File | Purpose |
|------|---------|
| `wave_rider.gd` | Main script — wave animation, resonance detection, burst firing |
| `wave_rider.tscn` | Scene |
