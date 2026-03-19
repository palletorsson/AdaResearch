# Glass Rack — Modular Laboratory Glassware

Turtle-graphics pipe system specialized for transparent laboratory glassware with liquid flow simulation. Used by audio synthesis visualizations and the grid editor's glass rack layouts.

## Files

| File | Role |
|------|------|
| `GlassRackController.gd` | Main controller — extends `GlassRackPipeBase` with glass materials and liquid flow |
| `TurtlePipeBase.gd` | Turtle-graphics pipe building (forward, turn, branch) |
| `GlassPipeSegments.gd` | Individual pipe segment geometry |
| `GlassSegmentPorts.gd` | Connection port definitions for segment linking |
| `GlassRack.tscn` | Base scene for glass rack instances |
| `glass_rack_test_runner.gd` | Automated test runner |
| `glass_rack_test_scene.tscn` | Test scene for visual verification |

## Features

- Borosilicate glass material with refraction, rim lighting, alpha transparency
- Liquid flow animation with configurable speed and color
- Turtle-graphics API for procedural pipe construction
- Modular segment connection via ports

Web layout editor: `localhost:3003/grid-editor`
