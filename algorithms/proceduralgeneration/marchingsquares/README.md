# Godot 4 Marching Squares Complete

Full implementation of Catlike Coding's Marching Squares tutorials for Godot 4.

## Features

✅ **Editable Voxel Grid** - Click and drag to paint
✅ **Chunk System** - Map divided into independent chunks
✅ **Marching Squares** - Smooth triangulation of voxel data
✅ **Stencil Editing** - Square and circular brushes
✅ **Variable Radius** - Brushes from size 0 to 5
✅ **Fill/Empty Modes** - Add or remove voxels
✅ **Seamless Chunks** - Perfect connections between chunks
✅ **Visual Feedback** - Voxel dots show grid structure

## Quick Start

```bash
python install_marching_squares.py
```

1. Open Godot 4
2. Open `marching_squares_scene.tscn`
3. Press F5
4. Start painting!

## Controls

**Editing:**
- **Left Mouse** - Paint with current brush
- **F** - Fill mode (add voxels)
- **E** - Empty mode (remove voxels)

**Brushes:**
- **S** - Square stencil
- **C** - Circle stencil
- **1-6** - Set brush radius (0-5)

## How It Works

### Voxel Grid
- Binary voxels (filled or empty)
- Organized in 2D grid
- Each chunk manages its own voxels

### Marching Squares Algorithm
1. Check each cell's 4 corner voxels
2. Determine configuration (16 possible cases)
3. Generate triangles based on case
4. Connect to neighboring chunks seamlessly

### 16 Marching Squares Cases

```
0: Empty
1-4: Single corner
5-6,9-10: Two corners (adjacent or opposite)
7-8,11-14: Three corners  
15: Full
```

### Chunking System
- Map divided into NxN chunks
- Each chunk has NxN voxels
- Chunks share edge data with neighbors
- Triangulation handles seams automatically

## Configuration

### Map Settings (voxel_map.gd)
```gdscript
map_size = 4.0              # Total map size
voxel_resolution = 16       # Voxels per chunk
chunk_resolution = 2        # Chunks per side (2x2 = 4 chunks)
```

### Performance Guidelines
- **8x8 voxels, 2x2 chunks**: Very fast, good for testing
- **16x16 voxels, 2x2 chunks**: Balanced, recommended
- **32x32 voxels, 4x4 chunks**: Detailed, slower
- **64x64 voxels, 4x4 chunks**: Very detailed, heavy

## Code Structure

### Core Classes

**Voxel** (`voxel.gd`)
- Stores state (filled/empty)
- Stores position
- Stores edge positions
- Dummy voxel support for chunk boundaries

**VoxelStencil** (`voxel_stencil.gd`)
- Base class for editing tools
- Square stencil (default)
- Defines affected area

**VoxelStencilCircle** (`voxel_stencil_circle.gd`)
- Circular brush
- Distance-based filtering

**VoxelGridSurface** (`voxel_grid_surface.gd`)
- Manages mesh generation
- Vertex/triangle arrays
- Caching system for efficiency
- Case-specific triangulation methods

**VoxelGrid** (`voxel_grid.gd`)
- Individual chunk management
- Voxel storage
- Triangulation orchestration
- Neighbor connections

**VoxelMap** (`voxel_map.gd`)
- Overall map controller
- Chunk creation and management
- Input handling
- Edit distribution to chunks

## Advanced Features

### Extend with Walls (Tutorial 4)

The system is ready for 3D walls:
1. Create `VoxelGridWall` class
2. Add depth (bottom/top positions)
3. Generate wall quads at edges
4. Add proper normals for lighting

### Add Sharp Features (Tutorials 2-3)

Detect sharp angles:
1. Store normals at edges
2. Calculate angle between edges
3. Add extra vertices for sharp corners
4. Smooth vs sharp transitions

### Custom Stencils

Create new stencil shapes:
```gdscript
extends VoxelStencil

func apply(x: int, y: int, voxel: bool) -> bool:
	# Custom logic here
	return fill_type
```

## Use Cases

**Level Editing:**
- Draw terrain
- Create obstacles
- Define walkable areas

**Game Mechanics:**
- Digging/building systems
- Destructible environments
- Paint-based gameplay

**Procedural Generation:**
- Generate from noise
- Random caves/dungeons
- Organic shapes

**Physics Simulation:**
- Flowing liquids
- Cellular automata
- Wave propagation

## Troubleshooting

**Seams between chunks:**
- Check neighbor assignments
- Verify dummy voxel setup
- Ensure triangulation order (right-to-left, top-to-bottom)

**Slow performance:**
- Reduce voxel_resolution
- Reduce chunk_resolution
- Disable voxel dots after editing

**Triangulation errors:**
- Check all 16 cases
- Verify cache indices
- Test each case individually

**Input not working:**
- Check collision shape size
- Verify raycast layer masks
- Check camera setup (orthographic)

## Next Steps

### Add 3D Walls
Follow Tutorial 4 to add depth

### Add Smooth Features
Follow Tutorials 2-3 for sharp corner detection

### Save/Load
Serialize voxel states to files

### Procedural Generation
Generate from Perlin noise

### Multiplayer
Sync voxel edits across network

## Performance Optimization

1. **Object Pooling**: Reuse voxel visuals
2. **Dirty Flags**: Only re-triangulate changed chunks
3. **LOD**: Reduce resolution at distance
4. **Caching**: Store commonly used configurations
5. **Threading**: Generate meshes off main thread

## Credits

Based on Catlike Coding's excellent Marching Squares tutorials:
- Marching Squares (Basic triangulation)
- Marching Squares 2 (Sharp features)
- Marching Squares 3 (Smoothing)
- Marching Squares 4 (3D walls)

Ported to Godot 4 with GDScript.

Enjoy creating! 🎨
