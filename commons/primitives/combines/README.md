# Combine Primitives

## Scenes
- `combine_portals.tscn`: torus portal sequence with increasing ring resolution.
- `combine_torus.tscn`: torus combinator variant.
- `combine_sphere.tscn`: sphere combinator variant.
- `combine_capsule.tscn`: capsule combinator variant.
- `hole_with_cones.tscn`: radial cone-hole study.
- `diamonds.tscn`: diamond collection utility.

## Registry Keys (commonly used)
- `combine_portals`
- `hole_with_cones`
- `diamonds`

## Map Token Examples
- `combine_portals:0:-0.2`
- `hole_with_cones:30:0.5`
- `diamonds:0:1:0.6`

## VR Notes
- `combine_portals.gd` duplicates a base torus mesh and increases `rings` / `ring_segments` per instance.
- Keep `portal_count` moderate in VR-heavy scenes to avoid overdraw and mesh cost spikes.
