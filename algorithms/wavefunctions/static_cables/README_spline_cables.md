# Spline-Controlled Cables

A flexible cable system that uses **Path3D** curves to define custom cable shapes, allowing for complex paths like cables starting wavy on the floor and transitioning upward to tables or other surfaces.

## Features

- **Full Spline Control**: Use Godot's Path3D curves to define any cable shape
- **Easy Editing**: Edit curves visually in the 3D editor
- **Multiple Cables**: Add multiple Path3D children for multiple independent cables
- **Same Visual Quality**: Uses the same tube mesh generation as StaticCables
- **Color Gradients**: Automatic color variation between multiple cables

## How to Use

### In the Editor

1. Open `SplineCables.tscn`
2. Add new **Path3D** nodes as children of the SplineCables root
3. Select a Path3D node and edit its curve:
   - Click **Add Point** to add control points
   - Drag points to shape the cable path
   - Adjust handles for smooth curves
4. Run the scene to see the cables generated

### Example Cable Paths

**Floor to Table Cable:**
```
Start: (-5, 0.2, 0)   # Slightly raised on floor
       (-3, -0.15, 0) # Dips down (wavy)
       (-1, 0.25, 0)  # Rises (wavy)
       (0, 0.5, 0)    # Starts going up
       (1, 1.5, 0)    # Climbing
End:   (2, 2.0, 0)    # Table height
```

The example in `SplineCables.tscn` demonstrates this pattern.

## Export Parameters

- **points_per_cable** (80): Number of sample points along each curve
- **cable_radius** (0.12): Thickness of the cable
- **ring_segments** (12): Cross-section detail (higher = smoother)
- **color_start**: Starting color for gradient
- **color_end**: Ending color for gradient
- **auto_generate_on_ready** (true): Generate cables automatically on scene start

## Script API

```gdscript
# Regenerate all cables after editing curves at runtime
$SplineCables.regenerate_cables()
```

## Comparison with StaticCables

| Feature | StaticCables | SplineCables |
|---------|--------------|--------------|
| Path Definition | Parametric (sine waves, etc.) | Spline curves (Path3D) |
| Flexibility | Predefined patterns | Fully custom shapes |
| Editing | Export parameters | Visual curve editor |
| Use Case | Uniform cable arrays | Custom cable routing |

## Tips

- Use **fewer control points** with smooth handles for natural curves
- For sharp turns, add more points close together
- Combine multiple Path3D nodes to create complex cable arrangements
- Adjust `points_per_cable` based on curve complexity:
  - Simple curves: 40-60 points
  - Complex curves: 80-120 points

## Creating Complex Paths

**Hanging + Rising Cable:**
1. Add points low on the floor with slight Y variations (wavy/sagging)
2. Add transition points gradually increasing Y
3. Add final points at destination height

**Multiple Cables:**
1. Add multiple Path3D children to SplineCables
2. Each Path3D becomes an independent cable
3. Colors automatically gradient across all cables

## Performance

- Static geometry (no physics simulation)
- Efficient tube mesh generation
- Same performance characteristics as StaticCables
- Generate once, render efficiently
