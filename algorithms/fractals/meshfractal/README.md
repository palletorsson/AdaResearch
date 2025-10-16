# Godot 4 Organic Fractal Generator

An animated 3D fractal with organic variety, color gradients, gravity simulation, and variable spin.

## Features

✨ **Hierarchical Fractal Generation** - Self-similar 3D structure with configurable depth
🎨 **Color Gradients** - Smooth color transitions with organic variety
🍃 **Leaf Differentiation** - Different mesh and colors for leaf nodes
🌍 **Gravity Simulation** - Realistic sagging effect
🌀 **Variable Spin** - Each branch spins at different speeds, some reverse
🎭 **Procedural Rendering** - Efficient MultiMesh instancing

## Setup

1. Run the installer:
   ```bash
   python install_fractal.py
   ```

2. Open Godot 4 and import the project (or add files to existing project)

3. Open `fractal_scene.tscn`

4. Press F5 to run!

## Configuration

### Fractal Settings (fractal.gd in Inspector)

- **Depth** (3-8): Number of recursive levels. Higher = more complex
  - Depth 6: ~3,900 instances
  - Depth 7: ~19,500 instances
  - Depth 8: ~97,600 instances

- **Branch Mesh**: Mesh for all non-leaf parts (default: Sphere)
- **Leaf Mesh**: Mesh for deepest level (default: Cube)
- **Material**: Material to use (uses vertex colors)

### Colors

- **Gradient A**: First color gradient (trunk → branches)
- **Gradient B**: Second color gradient (blended with A)
- **Leaf Color A/B**: Colors for leaf nodes

Colors are procedurally varied using Weyl sequences for organic look.

### Gravity Simulation

- **Max Sag Angle A/B** (0-90°): How much branches droop
  - Lower values: Stiffer, more upright
  - Higher values: Droopier, more natural

### Animation

- **Spin Speed A/B** (0-90°/s): Rotation speed range
- **Reverse Spin Chance** (0-1): Probability of counter-rotation

## Customization Examples

### Tree-like
```
depth = 6
max_sag_angle_a = 15
max_sag_angle_b = 25
spin_speed_a = 10
spin_speed_b = 20
gradient_a = Brown → Light brown
gradient_b = Dark brown → Tan
leaf_color = Green
```

### Crystal-like
```
depth = 5
max_sag_angle_a = 0
max_sag_angle_b = 5
spin_speed_a = 30
spin_speed_b = 40
gradient_a = Blue → Cyan
gradient_b = Purple → White
leaf_color = Bright white
```

### Coral-like
```
depth = 7
max_sag_angle_a = 20
max_sag_angle_b = 40
spin_speed_a = 5
spin_speed_b = 15
gradient_a = Orange → Pink
gradient_b = Red → Yellow
leaf_color = Bright orange
```

## Performance

The fractal uses MultiMesh instancing for efficient rendering:

- **Depth 6**: 3,906 instances - Very smooth on most hardware
- **Depth 7**: 19,531 instances - Smooth on modern GPUs
- **Depth 8**: 97,656 instances - May slow on older hardware

### Optimization Tips

1. Use simpler meshes (fewer vertices)
2. Lower sphere/box subdivisions
3. Reduce depth for older hardware
4. Disable shadows if needed

## Technical Details

### Fractal Structure

Each part has 5 children (except leaves):
- 1 pointing up
- 1 pointing right  
- 1 pointing left
- 1 pointing forward
- 1 pointing back

This creates a self-similar branching structure.

### Sagging Algorithm

Parts naturally point in their parent's direction, but are pulled down by:
```
sag_rotation = Quaternion(sag_axis, max_sag_angle * sin(angle_from_up))
```

This simulates gravity without physics simulation.

### Color Variation

Uses Weyl sequences for pseudo-random but deterministic colors:
```
t = fract(instance_id * 0.381 + level * 0.618)
color = color_a.lerp(color_b, t)
```

This creates organic-looking variation without actual randomness.

## Code Structure

- **fractal.gd**: Main controller
  - `generate_fractal()`: Creates part hierarchy
  - `update_fractal()`: Animates and updates transforms
  - `update_colors()`: Sets instance colors
  
- **FractalPart** (Dictionary):
  - `rotation`: Local rotation offset
  - `world_rotation`: Final world rotation
  - `world_position`: World position
  - `spin_angle`: Current spin rotation
  - `spin_velocity`: Rotation speed (rad/s)
  - `max_sag_angle`: Maximum droop angle

## Differences from Unity Version

- Uses MultiMesh instead of DrawMeshInstancedProcedural
- No Burst compilation (GDScript is interpreted)
- Colors set via vertex colors in MultiMesh
- Simpler than Unity's job system approach

## Advanced Usage

### Modify Colors Per-Frame

Access `multi_mesh_instances[level].multimesh` to change colors:

```gdscript
var mm = multi_mesh_instances[0].multimesh
mm.set_instance_color(index, Color.RED)
```

### Add Custom Behaviors

Extend `update_fractal()` to add:
- Wind simulation (sine wave offsets)
- Growth animation (scale over time)
- Seasonal color changes
- Interactive responses (mouse hover)

### Export for Use in Games

The fractal can be used as:
- Decorative vegetation
- Procedural trees/plants
- Abstract visual effects
- Level geometry

## Troubleshooting

**Fractal not visible**: Check camera position and distance

**Low framerate**: Reduce depth or use simpler meshes

**Colors not showing**: Ensure material has "Vertex Color > Use As Albedo" enabled

**Jerky animation**: Check project FPS settings (should be 60+)

## Credits

Based on Catlike Coding tutorials:
- Jobs (Animating a Fractal)
- Organic Variety (Making the Artificial Look Natural)

Ported to Godot 4 with MultiMesh instancing.

Enjoy your organic fractal! 🌳
