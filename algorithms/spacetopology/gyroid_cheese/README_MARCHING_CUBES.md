# Gyroid Cheese - Marching Cubes Edition

**New approach**: Real geometry instead of ray marching!

## What Changed

### Old Approach (Ray Marching)
- ❌ Pure shader - no actual geometry
- ❌ GPU-intensive, fragile
- ❌ Hard to debug when invisible
- ❌ Separate sphere collision scaffolding

### New Approach (Marching Cubes)
- ✅ Real mesh geometry (vertices, faces, normals)
- ✅ Standard materials that always work
- ✅ Visible in editor, exportable
- ✅ Collision from the mesh itself
- ✅ Consistent with terrain/cave system

## How It Works

1. **GyroidFieldGenerator** creates a density field:
   ```gdscript
   func calculate_gyroid_density(world_pos: Vector3) -> float:
       var gyroid = sin(kx)*cos(ky) + sin(ky)*cos(kz) + sin(kz)*cos(kx)
       return 0.5 + gyroid * 0.3  # Map to [0,1] for marching cubes
   ```

2. **VoxelChunk** samples the field on a 3D grid (default 40×40×40)

3. **MarchingCubesGenerator** extracts the isosurface (density = 0.5)

4. **Result**: Real ArrayMesh with proper vertices and normals

## Usage

### Basic Scene

```gdscript
extends Node3D

var gyroid: Node3D

func _ready():
    gyroid = preload("res://algorithms/spacetopology/gyroid_cheese/gyroid_cheese_vr.tscn").instantiate()
    add_child(gyroid)
```

### Adjust Parameters

In the Inspector:
- **Frequency** (1.2): Higher = more tunnels
- **Noise Amplitude** (0.15): Organic variation
- **Voxel Resolution** (40, 40, 40): Higher = smoother mesh (but slower)
- **Box Size** (8, 8, 8): Volume dimensions

### Regenerate Mesh

Change parameters in Inspector, then enable `regenerate_mesh` checkbox.

## Performance

| Resolution | Voxels | Generation Time | Triangles |
|------------|--------|-----------------|-----------|
| 20×20×20   | 8,000  | ~50ms          | ~2,000    |
| 40×40×40   | 64,000 | ~400ms         | ~15,000   |
| 60×60×60   | 216,000| ~1.5s          | ~50,000   |

**Recommendation**: Start with 40×40×40 for good quality/speed balance.

## Entropy Morphogenesis

The entropy version generates static geometry at a specific entropy state:

```gdscript
# Set entropy S ∈ [0, 1]
$EntropyMorphogenesis.S = 0.3

# Regenerate mesh at new entropy
$EntropyMorphogenesis.regenerate_at_entropy = true
```

To see the morphological transformation:
1. Set `S = 0.2` (low entropy - crystalline)
2. Enable `regenerate_at_entropy`
3. Wait ~0.5s for mesh generation
4. Set `S = 0.8` (high entropy - complex)
5. Enable `regenerate_at_entropy` again
6. Compare the two structures!

## Files

- `GyroidFieldGenerator.gd` - Core gyroid field + marching cubes integration
- `gyroid_cheese_vr.gd` - Simple gyroid scene
- `gyroid_cheese_vr.tscn` - Scene file
- `../entropy_morphogenesis/entropy_morphogenesis_vr.gd` - Entropy-driven variant

## Dependencies

Uses your existing marching cubes system:
- `marchingcubes/core/VoxelChunk.gd`
- `marchingcubes/core/MarchingCubesGenerator.gd`
- `marchingcubes/physics/CaveCollisionGenerator.gd`

## Troubleshooting

**Nothing visible?**
- Check console for errors
- Try `show_wireframe = true` to see if mesh exists
- Enable `Debug > Visible Collision Shapes` in editor

**Mesh looks blocky?**
- Increase `voxel_resolution` to 60×60×60
- Reduce `noise_amp` for smoother features

**Too slow to generate?**
- Reduce `voxel_resolution` to 30×30×30
- Disable `generate_collision` during testing

**Want to export the mesh?**
- The gyroid is real geometry - you can save it as a .tres resource!
