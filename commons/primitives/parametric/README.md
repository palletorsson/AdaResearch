# Parametric Surfaces

Library of mathematical parametric surfaces with configurable resolution.

## Files

- `parametric_surface.gd`: base parametric surface renderer (MeshInstance3D)
- `breather_surface.gd`, `catenoid.gd`, `dini_surface.gd`: classical surfaces
- `enneper_order3.gd`, `double_enneper.gd`: Enneper minimal surfaces
- `figure_eight_knot.gd`, `trefoil_knot.gd`, `torus_knot.gd`: knot surfaces
- `helicoid.gd`, `klein_bottle.gd`, `mobius_strip.gd`: topology examples
- `seashell.gd`, `wave_torus.gd`: organic forms
- `math_objects_gallery.gd`: gallery displaying multiple surfaces
- Matching `.tscn` files for each

## Behavior

- Each surface computes vertices from parametric equations (u, v parameters).
- Configurable mesh resolution (segments).
- Gallery mode arranges multiple surfaces for comparison.
