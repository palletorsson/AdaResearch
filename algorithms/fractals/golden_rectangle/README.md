# Golden Rectangle

## Overview
Visualizes the classic golden ratio rectangle subdivision - the geometric construction that produces the Fibonacci spiral.

## Spawn
```
golden_rectangle
golden_rectangle#preset:rainbow
```

## Parameters
| Parameter | Description | Example |
|-----------|-------------|---------|
| `preset` | Apply preset configuration | `#preset:rainbow` |
| `subdivisions` | Number of divisions | `#subdivisions:12` |
| `animate` | Enable/disable animation | `#animate:false` |
| `spiral` | Show/hide golden spiral | `#spiral:true` |
| `numbers` | Show/hide Fibonacci numbers | `#numbers:false` |
| `delay` | Animation delay (seconds) | `#delay:0.3` |

## Presets
| Preset | Description |
|--------|-------------|
| `classic` | 8 subdivisions, colored, spiral + numbers |
| `minimal` | 6 subdivisions, grayscale, spiral only |
| `rainbow` | 10 subdivisions, full spectrum colors |
| `deep` | 12 subdivisions, detailed spiral |
| `fast` | Quick animation (0.2s per step) |

## How It Works
1. Starts with a golden rectangle (width/height = φ ≈ 1.618034)
2. Cuts off a square from one side
3. The remaining rectangle is also a golden rectangle
4. Repeat recursively
5. Quarter-circle arcs through each square form the golden spiral

## Mathematical Properties
- **Golden Ratio (φ)**: (1 + √5) / 2 ≈ 1.618034
- **Fibonacci Connection**: Square side lengths follow Fibonacci sequence (1, 1, 2, 3, 5, 8, 13, 21...)
- **Self-Similarity**: Each subdivision produces another golden rectangle
- **Spiral**: Logarithmic spiral approximated by quarter-circle arcs

## Visual Elements
- 3D extruded rectangles with depth
- Color gradient based on subdivision level
- Golden spiral overlay (animated drawing)
- Fibonacci number labels on squares
- Outline edges for clarity

## API Methods
```gdscript
regenerate()           # Reset and rebuild
set_subdivisions(n)    # Set subdivision count
toggle_spiral()        # Toggle spiral visibility
toggle_numbers()       # Toggle number labels
apply_preset(name)     # Apply named preset
```
