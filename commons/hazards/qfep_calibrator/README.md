# QFEP Calibrator

Morphing dodecahedron with 3 oscillating parameter beams — phi, delta_e, and constraint dynamically change its behavior.

## Behavior

Extends `HazardCreatureBase`. QFEP Laboratory sequence hazard.

- Parameters oscillate sinusoidally, continuously altering behavior:
  - **phi** — Controls rotation speed
  - **delta_e** — Controls damage output
  - **constraint** — Controls detection radius
- Body pulses with emission based on combined parameter energy
- 2 walking legs for locomotion

## Files

| File | Purpose |
|------|---------|
| `qfep_calibrator.gd` | Main script — parameter oscillation, dodecahedron mesh |
| `qfep_calibrator.tscn` | Scene |
