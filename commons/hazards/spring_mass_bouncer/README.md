# Spring Mass Bouncer

3x3 grid of mass nodes connected by springs — implements Hooke's law with visible deformation.

## Behavior

Extends `HazardCreatureBase`. Soft bodies sequence hazard.

- 9 mass nodes in a 3x3 grid connected by springs
- Hooke's law spring physics with damping
- Nodes jiggle and deform when creature moves or collides
- Contact damage scales with spring compression at impact point
- Color lerps from orange to red based on tension

## Files

| File | Purpose |
|------|---------|
| `spring_mass_bouncer.gd` | Main script — spring physics, deformation, tension coloring |
| `spring_mass_bouncer.tscn` | Scene |
