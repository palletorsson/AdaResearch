# Perlin Terrain Sculptor

A voxel-based terrain sculpting tool that uses 3D Perlin noise as a carving brush. Users adjust noise scale and density threshold via VR sliders to shape terrain in real-time. Teaches how Perlin noise and thresholding create natural-looking 3D structures from continuous mathematical functions.

## How It Works

A 24x24x24 voxel grid is evaluated against Godot's FastNoiseLite Perlin noise generator with fractal Brownian motion (fBm). Each voxel is filled when its noise value minus a height bias exceeds the threshold parameter. Lowering the threshold reveals more voxels (denser terrain), while raising it carves away material. The noise scale controls feature size: low scale produces broad landmasses, high scale creates fine detail. Voxels are rendered using GPU-instanced MultiMesh with height-based color gradients, and the artifact broadcasts its noise parameters to any listening VoxelNoise receivers in the scene.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `grid_size` | int | 24 |
| `voxel_size` | float | 0.04 |
| `noise_scale` | float | 4.0 |
| `noise_octaves` | int | 3 |
| `threshold` | float | 0.0 |
| `voxel_color` | Color | (0.3, 0.7, 0.4) |
| `height_gradient` | bool | true |

## Features

- 3D Perlin noise terrain generation with fBm fractal layering
- VR sliders for threshold (-1 to 1) and noise scale (0.5 to 20)
- New Seed and Reset buttons for terrain variation
- GPU-instanced voxel rendering via MultiMesh with per-instance colors
- Height-based color gradient from base green to snow-white peaks
- Live info display showing scale, threshold, and active voxel count
- Broadcasts noise parameters to VoxelNoise receiver nodes
- Keyboard controls: arrows (threshold/scale), R (reset), N (new seed)

## Files

- `perlin_terrain_sculptor.gd` — Main script
- `perlin_terrain_sculptor.tscn` — Scene file
