# Marching Cubes: 15 Surface Cases Demo

## Overview

This interactive demo visualizes the **15 fundamental surface cases** that can occur in the Marching Cubes algorithm. Each case represents a unique surface topology configuration when a cube is intersected by an isosurface. This is an essential educational tool for understanding how marching cubes generates surfaces from voxel data.

![Marching Cubes 15 Cases](screenshot_fifteen_cases.png)

## Features

✨ **Complete Visual Demo** - All 15 unique marching cubes configurations  
🎮 **Interactive Controls** - Zoom, toggle wireframes, animate thresholds  
🎨 **Color-Coded Surfaces** - Each case has unique coloring based on complexity  
📊 **Vertex Visualization** - Red (inside) and blue (outside) vertex indicators  
🔬 **Educational Labels** - Clear descriptions of each surface topology  
⚡ **Advanced Generator** - Uses production-quality marching cubes implementation  

## Files

- `scenes/fifteen_cases_demo.tscn` - The main demo scene
- `scenes/FifteenCasesController.gd` - Interactive demo controller
- `core/MarchingCubesGenerator.gd` - Advanced marching cubes implementation
- `core/MarchingCubesLookupTables.gd` - Triangle lookup tables
- `core/VoxelChunk.gd` - Voxel data management
- `README_FifteenCases.md` - This documentation

## The 15 Fundamental Cases

| Case | Configuration | Description | Vertex Count | Surface Type |
|------|---------------|-------------|--------------|--------------|
| **0** | `00000000` | Empty - All vertices outside | 0 | No surface |
| **1** | `00000001` | Single Corner - One vertex inside | 1 | Tetrahedron |
| **2** | `00000011` | Adjacent Corners - Two adjacent vertices | 2 | Wedge |
| **3** | `00000111` | Triangle Corner - Three vertices | 3 | Triangular surface |
| **4** | `00001001` | Diagonal Corners - Two opposite vertices | 2 | Bridge surface |
| **5** | `00001111` | L-Shape - Four vertices (bottom face) | 4 | Flat surface |
| **6** | `00010111` | Wedge - Five vertices | 5 | Complex wedge |
| **7** | `00110011` | Tunnel - Creates passage through cube | 4 | Tunnel topology |
| **8** | `01010101` | Saddle - Alternating pattern | 4 | Saddle point |
| **9** | `01100110` | Complex Saddle - Different alternating | 4 | Complex saddle |
| **10** | `00111100` | Bridge - Connects opposite edges | 4 | Bridge connection |
| **11** | `01011010` | Complex Surface - Multi-component | 5 | Complex topology |
| **12** | `01101001` | Asymmetric - Irregular pattern | 5 | Asymmetric surface |
| **13** | `01111111` | Nearly Full - Seven vertices inside | 7 | Inverse tetrahedron |
| **14** | `11111111` | Full - All vertices inside | 8 | No surface |

## Interactive Controls

### Camera Controls
- **Mouse Wheel Up/Down** - Zoom in/out
- **+ / =** - Zoom in (keyboard)
- **- / _** - Zoom out (keyboard)
- **Zoom Range** - 8 to 30 units distance

### Visualization Controls
- **W** - Toggle wireframe cubes on/off
- **L** - Toggle text labels on/off
- **A** - Toggle threshold animation (shows surface changes)
- **R** - Regenerate all surfaces (refresh demo)

### Visual Elements
- **Colored Surfaces** - Each case has unique color based on vertex count
- **Wireframe Cubes** - Show the underlying voxel structure
- **Vertex Spheres** - Red = inside surface (density > 0.5), Blue = outside (density < 0.5)
- **Text Labels** - Show case name, description, and configuration index

## Technical Implementation

### Advanced Features
- **Seamless Boundary Handling** - No holes or gaps in surfaces
- **Robust Edge Interpolation** - Precise surface intersection calculation
- **Consistent Normal Generation** - Proper lighting and shading
- **Performance Tracking** - Debug statistics for mesh generation
- **Type-Safe Implementation** - Proper Godot 4 compatibility

### Density Configuration
- **Outside Surface**: 0.3 (below threshold)
- **Inside Surface**: 0.7 (above threshold)  
- **Threshold**: 0.5 (isosurface level)
- **Edge Interpolation**: Linear interpolation between vertex densities

### Surface Generation Process
1. **Cube Analysis** - Check which of 8 vertices are inside/outside surface
2. **Configuration Index** - Calculate binary pattern (0-255)
3. **Lookup Table** - Find triangle configuration for this pattern
4. **Edge Interpolation** - Calculate exact surface intersection points
5. **Triangle Generation** - Create triangles with proper normals
6. **Mesh Assembly** - Combine all triangles into final surface

## Educational Value

This demo helps understand:

🔍 **Algorithm Fundamentals** - How marching cubes works at the core level  
📐 **Topology Principles** - Relationship between vertex patterns and surface shapes  
🎯 **Edge Cases** - Special configurations like saddle points and tunnels  
⚡ **Optimization Techniques** - Lookup tables vs. real-time calculation  
🎨 **Surface Quality** - Impact of interpolation and normal calculation  

## Usage in Projects

This demo serves as:
- **Educational Tool** - Teaching marching cubes algorithm
- **Debug Visualization** - Understanding surface generation issues
- **Reference Implementation** - Example of proper marching cubes code
- **Testing Framework** - Validating marching cubes implementations

## Performance Notes

- **Generation Time** - ~1ms per case on modern hardware
- **Triangle Count** - Varies by case (0-5 triangles per cube)
- **Memory Usage** - Minimal for single cube demonstrations
- **Scalability** - Core algorithm scales to large voxel grids

## Related Files

- `TUTORIAL_MARCHING_CUBES.md` - Complete implementation tutorial
- `README_TERRAIN_GENERATION.md` - Using marching cubes for terrain
- `EVALUATION_REPORT.md` - Performance analysis and comparisons

## Quick Start

1. Open `algorithms/spacetopology/marchingcubes/scenes/fifteen_cases_demo.tscn` in Godot 4
2. Run the scene to see all 15 cases in a 3×5 grid
3. Use mouse wheel to zoom and examine surface details
4. Press W to toggle wireframes and see vertex configurations
5. Study how different vertex patterns create unique surface topologies

Perfect for learning computer graphics, procedural generation, and understanding how voxel-based terrain systems work! 
