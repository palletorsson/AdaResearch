# Voxel Noise -- 3D Noise Sampling and Isosurface Extraction

A multi-file toolkit for sampling 3D noise fields and extracting isosurface meshes via marching tetrahedra. The artifact teaches how **continuous noise functions become solid geometry** through thresholding -- a density value at every point in space defines inside vs. outside, and the isosurface extraction algorithm finds the boundary between them.

## How It Works

The system is split into layered components:

1. **VoxelField** (`VoxelField.gd`) -- Defines a scalar field combining layered Simplex noise with a soft sphere falloff. Provides `field(p)` to sample any point, `grad(p)` for central-difference gradients, and `interesting_score()` to rank regions by gradient magnitude, Laplacian curvature, and proximity to the isosurface.

2. **VoxelSampler** (`VoxelSampler.gd`) -- Samples a centered 3D grid of density values from FastNoiseLite, producing a `PackedFloat32Array` ready for meshing.

3. **voxelnoise1** (`voxelnoise1.gd`) -- A robust noise sampler node with full FastNoiseLite configuration (noise type, fractal type, octaves, lacunarity, gain). Exposes `get_density_local()`, `get_density_world()`, `sample_centered_grid()`, `sample_roi_centered_at_local()`, and `make_isoband_mask()` for flexible sampling patterns.

4. **VoxelExtractor** (`VoxelExtractor.gd`) -- Marching tetrahedra isosurface extractor. Splits each cube into 6 tetrahedra using a fixed decomposition, classifies corners with a 4-bit bitmask, and interpolates edge intersections from a 16-entry triangle table. Commits the result as a Godot ArrayMesh with optional smooth normals.

5. **voxelnoise** (`voxelnoise.gd`) -- World-level chunk generator that creates voxel cubes above the iso-level threshold, applies a wireframe shader (blue glass with pink edges), and adds collision shapes.

6. **ROIViewer** (`ROIViewer.gd`) -- Orchestrates the pipeline by finding interesting regions of interest via VoxelField scoring, then instantiating VoxelExtractor scenes at each ROI to produce focused mesh samples.

7. **MeshFix** (`MeshFix.gd`) -- Post-processing utility that detects open boundary edges, chains them into loops, and triangulates the holes with fan triangulation from the loop centroid.

## Parameters

Key exports across the system:

| Export | Script | Default | Description |
|--------|--------|---------|-------------|
| `seed` / `noise_seed` | multiple | 1337 | Noise seed |
| `frequency` / `noise_scale` | multiple | 0.02--0.05 | Noise frequency |
| `iso_level` / `iso` | multiple | 0.0 / -0.3 | Isosurface threshold |
| `resolution` | VoxelExtractor | (32,32,32) | Voxels per axis |
| `chunk_size` | voxelnoise | 32 | Chunk width in voxels |
| `world_height` | voxelnoise | 64 | Chunk height in voxels |
| `smooth_normals` | VoxelExtractor | true | Generate smooth normals |
| `search_aabb` | ROIViewer | (-12..+12)^3 | Region of interest search bounds |
| `coarse` | ROIViewer | 18 | Coarse grid resolution for ROI scoring |
| `keep` | ROIViewer | 1 | Number of top ROIs to visualize |

## Features

- Full marching tetrahedra isosurface extraction with 16-case triangle table
- Multiple noise types: OpenSimplex2, Perlin, Cellular, Value, ValueCubic
- Fractal modes: FBM, Ridged, PingPong, Domain Warp
- Region-of-interest scoring by gradient magnitude, Laplacian, and iso-proximity
- Wireframe shader with barycentric edge detection (blue glass + pink glow)
- Boundary hole-filling via edge-loop detection and fan triangulation
- Linked Perlin sculptor integration for runtime parameter control

## Files

- `VoxelField.gd` -- Scalar field definition with noise layering and ROI scoring
- `VoxelSampler.gd` -- Centered grid density sampler
- `voxelnoise1.gd` -- Full-featured noise sampler with ROI and isoband utilities
- `VoxelExtractor.gd` -- Marching tetrahedra mesh extraction (class_name VoxelExtractor)
- `voxelnoise.gd` -- Chunk-based voxel world with shader and collision
- `ROIViewer.gd` -- ROI-based sample visualization orchestrator
- `MeshFix.gd` -- Open boundary detection and hole-filling (class_name MeshFix)
