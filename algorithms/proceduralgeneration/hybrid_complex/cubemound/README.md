# Godot 4 Cube Mound Mesh Generator

Drop physics cubes, let them pile up, then generate a mesh from their positions!

## Features

🎲 **Physics Simulation** - Real RigidBody3D cubes with collision
📦 **Automatic Mesh Generation** - Creates mesh from settled cube positions
🔷 **Voxel-based Surface** - Finds edges and builds surface mesh
✨ **Two Versions** - Basic and advanced with smoothing
🎨 **Customizable** - Number of cubes, size, spawn area, voxel resolution

## Quick Start

1. **Run installer:**
   ```bash
   python install_cube_mound.py
   ```

2. **Open Godot 4**
3. **Open `cube_mound_scene.tscn`**
4. **Press F5** - Cubes drop and mesh generates automatically!

## Controls

- **SPACE** - Drop new cubes and generate mesh
- **T** - Toggle cube visibility (show/hide original cubes)
- **R** - Restart scene with new random positions

## How It Works

### 1. Drop Phase
- Spawns N RigidBody3D cubes
- Random positions in cylinder above ground
- Random rotations
- Each cube has unique color

### 2. Settle Phase
- Physics engine simulates falling
- Cubes collide and pile up
- Waits for all cubes to sleep (stop moving)
- Or times out after `settle_time` seconds

### 3. Generate Phase
- Captures all cube positions
- Creates 3D voxel grid
- Marks occupied voxels (cube volumes)
- Finds surface voxels (exposed faces)
- Builds mesh from surface faces

### 4. Result
- Single mesh wrapping the pile
- Original cubes hidden
- Can toggle visibility to compare

## Configuration

### Basic Settings (Inspector)

- **Num Cubes** (default: 20)
  - More cubes = bigger pile
  - Try: 10, 20, 50, 100

- **Cube Size** (default: 1.0)
  - Size of each physics cube
  - Smaller = more detail

- **Spawn Height** (default: 10.0)
  - How high cubes drop from
  - Higher = more chaos

- **Spawn Radius** (default: 3.0)
  - Cylinder radius for spawn area
  - Larger = more spread out

- **Settle Time** (default: 3.0 seconds)
  - Max wait for physics to settle
  - Increase for more cubes

- **Voxel Size** (default: 0.5)
  - Resolution of generated mesh
  - Smaller = more detailed mesh
  - Larger = smoother, blockier mesh

## Advanced Version

Use `advanced_cube_mound.gd` for additional features:

### Smoothing Options

- **Smooth Mesh** (true/false)
  - Apply Laplacian smoothing
  - Makes surface less blocky

- **Smooth Iterations** (default: 2)
  - Number of smoothing passes
  - More = smoother but slower

### Convex Hull Option

- **Use Convex Hull** (true/false)
  - Uses convex hull instead of voxels
  - Creates wrapping shape around pile
  - Good for simplified collision mesh

## Use Cases

### Game Development
- **Rubble Piles** - Destroyed buildings
- **Rock Formations** - Natural terrain
- **Debris** - Explosion aftermath
- **Procedural Props** - Random mounds

### Procedural Generation
- **Terrain Features** - Hills, mounds
- **Cave Formations** - Stalactites/stalagmites
- **Organic Shapes** - Abstract sculptures

### Prototyping
- **Quick Collision Meshes** - From placement
- **Level Blocking** - Rapid terrain
- **Visual Effects** - Particle-to-mesh

## Examples

### Small Detailed Pile
```
num_cubes = 30
cube_size = 0.5
spawn_radius = 2.0
voxel_size = 0.3
```

### Large Rough Mound
```
num_cubes = 100
cube_size = 1.0
spawn_radius = 5.0
voxel_size = 1.0
```

### Smooth Organic Shape
```
num_cubes = 50
cube_size = 0.8
voxel_size = 0.4
smooth_mesh = true
smooth_iterations = 3
```

## Performance Notes

### Voxel Resolution
- **Small voxels** (0.2-0.4): High detail, many triangles
- **Medium voxels** (0.5-0.8): Balanced
- **Large voxels** (1.0+): Low detail, few triangles

### Cube Count
- **10-30**: Fast, good for testing
- **30-50**: Normal gameplay
- **50-100**: Heavy, use for baking
- **100+**: Very heavy, pre-generate only

### Optimization Tips
1. Use larger voxel_size for performance
2. Enable smoothing only when needed
3. Hide original cubes after generation
4. Pre-generate meshes at design time
5. Use convex hull for collision-only meshes

## Technical Details

### Voxelization Algorithm
```
For each cube position:
  Calculate voxel grid position
  Mark cube volume as occupied (multiple voxels)

For each occupied voxel:
  Check 6 neighbors (NESW, Up, Down)
  If neighbor is empty:
    Add face to mesh
```

### Mesh Generation
- Uses SurfaceTool for construction
- Generates normals automatically
- Clockwise winding for correct lighting
- Each exposed voxel face becomes 2 triangles

### Smoothing (Advanced)
- Laplacian smoothing
- Averages vertex positions with neighbors
- Preserves topology
- Multiple iterations for more smoothing

## Troubleshooting

**Cubes fall through ground:**
- Check Ground StaticBody3D has collision
- Verify physics layers match

**Mesh looks blocky:**
- Decrease voxel_size
- Enable smoothing (advanced version)
- Increase smooth_iterations

**Generation is slow:**
- Reduce num_cubes
- Increase voxel_size
- Disable smoothing

**Mesh has holes:**
- Decrease voxel_size
- Check cube_size vs voxel_size ratio
- Ensure settle_time is long enough

**Cubes don't settle:**
- Increase settle_time
- Check physics simulation speed
- Verify no moving platforms nearby

## Extending the System

### Add Colors to Mesh
```gdscript
# In generate_mesh_from_cubes:
var cube_colors = []
for cube in cubes:
    var mat = cube.get_child(1).material_override
    cube_colors.append(mat.albedo_color)

# Then assign colors based on nearest cube
```

### Save Generated Mesh
```gdscript
# After generation:
ResourceSaver.save(generated_mesh.mesh, "res://saved_mound.tres")
```

### Animated Growth
```gdscript
# Show cubes appearing one by one
for i in range(num_cubes):
    spawn_cube()
    await get_tree().create_timer(0.1).timeout
```

### Multiple Materials
```gdscript
# Assign different materials to top/sides
# Check face normal in add_voxel_face
if normal.y > 0.5:
    use_top_material()
else:
    use_side_material()
```

## Credits

Inspired by procedural mesh generation techniques.
Voxel-based surface extraction algorithm.
Laplacian smoothing for organic shapes.

Enjoy creating mounds! 📦🏔️
