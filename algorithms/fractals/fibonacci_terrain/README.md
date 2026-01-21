# Fibonacci Terrain

## Overview
Generates terrain through golden ratio subdivision - starting with a plane, recursively subdividing and lifting random non-edge faces to create organic mountain/landscape growth.

## Spawn
```
fibonacci_terrain
fibonacci_terrain#preset:mountain_peak
```

## Parameters
| Parameter | Description | Example |
|-----------|-------------|---------|
| `preset` | Apply preset configuration | `#preset:archipelago` |
| `iterations` | Number of growth cycles | `#iterations:8` |
| `lift` | Base lift height | `#lift:0.8` |
| `animate` | Enable/disable growth animation | `#animate:false` |
| `spiral` | Show/hide golden spiral overlay | `#spiral:true` |

## Presets
| Preset | Description |
|--------|-------------|
| `gentle_hills` | Low lifts, many faces, spread out |
| `mountain_peak` | High lifts, single face, center-focused |
| `plateau` | High flat areas |
| `archipelago` | Multiple scattered islands |
| `fibonacci_spiral` | Maximum iterations with spiral overlay |

## Algorithm
1. Start with golden ratio rectangle (8 × 4.944) subdivided into 2×2 faces
2. Each iteration:
   - Find all non-edge faces (edges can't lift - they'd break continuity)
   - Randomly select faces (biased toward center for mountain-like growth)
   - Lift selected faces using golden-ratio-scaled heights
   - Subdivide lifted faces using golden ratio proportions
   - Recalculate which faces are now edges
3. Golden spiral overlay follows terrain surface height

## Mathematical Properties
- **Golden Ratio Subdivision**: Faces split at φ ratio, not 50/50
- **Height Scaling**: Lift heights scale by 1/φ^(iteration/2) for natural falloff
- **Edge Detection**: Faces touching bounding box edges cannot lift
- **Center Bias**: Preferential selection of faces closer to origin

## Visual Elements
- Height-based coloring (green base → white peaks)
- Side walls for lifted faces (self-shadowing effect)
- Golden spiral overlay tracing terrain surface
- Animated step-by-step growth

## API Methods
```gdscript
regenerate()              # Reset and rebuild
set_iteration(n)          # Jump to specific iteration
toggle_spiral()           # Toggle spiral visibility
apply_preset(name)        # Apply named preset
```

## Signals
- `iteration_complete(iteration: int)` - Emitted after each growth step
- `terrain_complete()` - Emitted when all iterations finish
