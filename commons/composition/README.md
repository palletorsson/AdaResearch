# Composition — Spatial Layout and Coordinate Systems

Content-agnostic spatial composition system that maps grid positions to named zones. Used by PatternCompositor, FacadeBuilder, carpet generators, and any element-based layout.

## Core

| File | Role |
|------|------|
| `spatial_composition.gd` | Main class — zones, regions, modifiers, tiling type |
| `composition_region.gd` | Hit-testing primitives (Fill, Border, Rect, Ellipse, Corners, Stripe, Columns, Ring) |
| `composition_zone.gd` | Region + properties (color, pattern, material) |
| `composition_presets.gd` | Built-in layout presets (carpet, facade, mosaic, quilt, tunnel) |
| `art_history_presets.gd` | Art-historical composition schemes |

## Coordinate Systems

Pluggable tiling backends that transform (gx, gy) grid positions into world-space geometry:

| File | Tiling |
|------|--------|
| `coordinate_system.gd` | Base class — abstract interface |
| `rectangular_coordinate_system.gd` | Standard rectangular grid |
| `hex_coordinate_system.gd` | Hexagonal tiling |
| `polar_coordinate_system.gd` | Polar/radial coordinates |
| `truchet_coordinate_system.gd` | Truchet tile rotations |
| `voronoi_coordinate_system.gd` | Voronoi cell tiling |

## Usage

```gdscript
var comp = SpatialComposition._make(20, 20)
comp.coord_system = HexCoordinateSystem.new()
comp.tiling_type = "hex"
```
