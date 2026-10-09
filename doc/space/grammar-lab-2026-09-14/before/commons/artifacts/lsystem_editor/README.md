# L-System Editor

An interactive L-system viewer with VR controls for exploring how formal grammars generate complex geometric patterns. Includes seven built-in presets (Koch Curve, Sierpinski Triangle, Dragon Curve, Plant, Bush, Fern, Binary Tree) with adjustable generation depth and branching angle.

## How It Works

The editor performs iterative string rewriting: starting from an axiom, each character matching a production rule is replaced by the rule's output string. After the specified number of generations, a turtle interpreter walks the resulting string, drawing line segments for "F"/"G", turning by the configured angle for "+"/"-", and saving/restoring position for "["/"]". The output is auto-scaled to fit the display bounds and rendered with height-based color gradients using ImmediateMesh line primitives.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | 1.0 |
| `line_color` | Color | (0.3, 0.8, 0.3) |
| `max_line_length` | float | 0.02 |
| `axiom` | String | "F" |
| `angle_degrees` | float | 25.0 |
| `generations` | int | 4 |
| `preset` | int | 3 (Plant) |

## Features

- Seven built-in L-system presets covering curves, fractals, and plant structures
- VR sliders for preset selection, generation depth, and branching angle
- Custom rule input via `set_rules()` API
- Height-based color gradient from base color to light tips
- Auto-scaling to fit within display bounds
- Performance-safe string length limit (100,000 characters)
- Keyboard shortcuts for preset and parameter changes

## Files

- `lsystem_editor.gd` -- Main script
- `lsystem_editor.tscn` -- Scene file
