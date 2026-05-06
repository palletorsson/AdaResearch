# Truchet Tiles

Shader-based procedural patterns using rotated tiles — quarter arcs, mazes, zigzags, and more from simple building blocks.

## QFEP Connection

Truchet tiles demonstrate **order from random choices**. Each tile has just 2-4 orientations (minimal E), but random placement creates infinitely varied patterns (emergent E). The constraint of tile edges matching gives global coherence (F) without central planning.

## How It Works

```
┌───────────────────────────────┐
│  ╭─╮ ╭─╮ │ ╰─╯ ╭─╮ │ ╰─╯    │
│  │ ╰─╯ │ ╰─────╯ │ ╰─────╮  │
│  ╰─────╯ ╭───────╯ ╭─────╯  │
│  ╭─╮ ╭───╯ ╭─╮ ╭───╯ ╭─╮    │
│  │ ╰─╯ ╭───╯ ╰─╯ ╭───╯ │    │
│  ╰─────╯ ╰───────╯ ╰───╯    │
└───────────────────────────────┘
        Quarter Arcs Pattern
```

Each tile is randomly rotated 0°, 90°, 180°, or 270°. Matching edges create continuous paths, loops, and networks.

## Pattern Shaders

| Shader | Description |
|--------|-------------|
| `quarterarcs.gdshader` | Classic quarter-circle arcs |
| `mazelines.gdshader` | Line segments forming maze paths |
| `diagonalsplit.gdshader` | Triangular diagonal splits |
| `zigzag.gdshader` | Zigzag line patterns |
| `dots.gdshader` | Dot-based tile pattern |
| `truchettiles.gdshader` | Base implementation |

## Parameters (Quarter Arcs example)

| Uniform | Range | Description |
|---------|-------|-------------|
| `zoom` | 1.0-20.0 | Tile density (grid size) |
| `animate` | bool | Enable rotation animation |
| `spin_speed` | float | Animation speed |
| `color_a` | Color | Background color |
| `color_b` | Color | Pattern color |

## Usage

Apply shader to a mesh material:

```gdscript
var mesh = MeshInstance3D.new()
mesh.mesh = PlaneMesh.new()

var mat = ShaderMaterial.new()
mat.shader = preload("res://algorithms/patterngeneration/truchettiles/quarterarcs.gdshader")
mat.set_shader_parameter("zoom", 5.0)
mat.set_shader_parameter("color_a", Color.BLACK)
mat.set_shader_parameter("color_b", Color.WHITE)

mesh.material_override = mat
```

## Files

| File | Purpose |
|------|---------|
| `truchettiles.tscn` | Demo scene |
| `*.gdshader` | Individual pattern shaders |

## Mathematical Background

Truchet tiles (1704, Sébastien Truchet) were among the first systematic studies of pattern generation. The key insight: simple local rules + randomness = complex global patterns.

Modern applications:
- **Procedural textures**: Games, graphics
- **Maze generation**: Instant connected paths
- **Art**: Generative design systems

## VR Experience

View the patterns on walls, floors, or floating panels. The zoom parameter controls density — pull back for overview, zoom in for detail. Animation mode creates mesmerizing rotating tile fields.

## See Also

- `patterngeneration/waves/` — Wave-based patterns
- `randomness/ten_print/` — Related random line patterns
- `shaders/` — Other procedural shaders
