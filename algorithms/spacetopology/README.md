# Space Topology & Computational Geometry

This directory contains 3D visualizations of computational geometry algorithms, spatial data structures, and topological analysis techniques used in computer graphics, robotics, and spatial computing.

## Algorithms

### 1. Convex Hull (`convexhull/`)
- **Description**: Finds the smallest convex polygon that contains all given points
- **Algorithms Implemented**:
  - **Graham Scan**: O(n log n) complexity, sorts by polar angle
  - **Jarvis March**: O(nh) complexity where h is hull size
  - **Quick Hull**: O(n log n) average case, divide-and-conquer approach
- **Features**:
  - 3D point cloud generation with multiple distributions
  - Real-time hull computation
  - Interactive point manipulation
  - Multiple algorithm comparison
  - Visual hull boundary representation

### 2. Marching Cubes (Existing implementation)
- **Description**: Extracts polygonal mesh from 3D scalar field
- **Inventor**: William E. Lorensen, Harvey E. Cline (1987)
- **Features**: Isosurface extraction, medical imaging support, 3D rendering

### 3. Space Colonization (Existing implementation)
- **Description**: Algorithm for generating organic structures like trees and veins
- **Features**: Growth pattern simulation, organic network generation

## Technical Details

### Convex Hull Algorithms

#### Graham Scan
- **Complexity**: O(n log n)
- **Method**: Sort points by polar angle, then scan for left turns
- **Best for**: General purpose, most efficient for most cases

#### Jarvis March (Gift Wrapping)
- **Complexity**: O(nh) where h is hull size
- **Method**: Find leftmost point, then repeatedly find next hull point
- **Best for**: Small hulls, simple implementation

#### Quick Hull
- **Complexity**: O(n log n) average case
- **Method**: Divide-and-conquer using extreme points
- **Best for**: Large datasets, parallel implementation

### Point Distributions
- **Uniform**: Random points across the entire space
- **Normal**: Gaussian distribution around the center
- **Clustered**: Points grouped in several clusters

### Visualization Features
- **Point Representation**: 3D spheres with configurable materials
- **Hull Visualization**: Connected lines showing the convex boundary
- **Real-time Updates**: Dynamic computation and display
- **Interactive Controls**: Parameter adjustment and regeneration

## Usage

Each algorithm scene can be:
1. **Opened independently** in Godot 4
2. **Integrated into larger projects** for spatial analysis
3. **Used for educational purposes** to understand computational geometry
4. **Extended** with additional algorithms or visualization methods

## Controls

### Point Generation
- **Point Count**: Number of points to generate (5-50)
- **Distribution**: Type of spatial distribution
- **Generate**: Create new random point set

### Hull Computation
- **Algorithm**: Choose hull computation method
- **Compute Hull**: Execute the selected algorithm
- **Clear All**: Reset the visualization

## File Structure

```
spacetopology/
├── convexhull/
│   ├── convexhull.tscn
│   ├── ConvexHull.gd
│   └── ConvexHullVisualizer.gd
├── marchingcubes/
│   ├── Various existing implementations
│   └── README_MarchingCubes.md
├── spacecolonization/
│   └── Various existing implementations
└── README.md
```

## Dependencies

- **Godot 4.4+**: Required for all scenes
- **Standard 3D nodes**: CSGSphere3D, CSGBox3D, Camera3D, DirectionalLight3D
- **Math functions**: Built-in mathematical and geometric functions
- **Random generation**: Built-in random number generators

## Mathematical Concepts

### Convex Hull Properties
- **Convexity**: All interior angles ≤ 180°
- **Minimality**: Smallest convex set containing all points
- **Uniqueness**: Only one convex hull for a given point set

### Geometric Operations
- **Cross Product**: Used for orientation testing
- **Polar Angles**: For sorting in Graham scan
- **Left Turn Test**: Determines if three points form a left turn

### Algorithm Analysis
- **Time Complexity**: Varies by algorithm and input characteristics
- **Space Complexity**: Generally O(n) for storage
- **Optimality**: Graham scan and Quick Hull are optimal for general cases

## Future Enhancements

- [ ] Add more computational geometry algorithms (Voronoi diagrams, Delaunay triangulation)
- [ ] Implement 3D convex hull algorithms
- [ ] Add point cloud manipulation tools
- [ ] Create algorithm performance comparison visualizations
- [ ] Add export functionality for computed hulls
- [ ] Implement parallel versions of algorithms

## Applications

### Computer Graphics
- **Collision Detection**: Bounding volume computation
- **Mesh Simplification**: Reducing polygon count
- **Level of Detail**: Adaptive mesh complexity

### Robotics & Navigation
- **Path Planning**: Obstacle avoidance
- **Localization**: Environment mapping
- **SLAM**: Simultaneous localization and mapping

### Scientific Visualization
- **Data Clustering**: Group identification
- **Outlier Detection**: Boundary analysis
- **Spatial Analysis**: Geographic data processing

## References

- Graham, R.L. "An efficient algorithm for determining the convex hull of a finite planar set." Information Processing Letters 1.4 (1972): 132-133
- Jarvis, R.A. "On the identification of the convex hull of a finite set of points in the plane." Information Processing Letters 2.1 (1973): 18-21
- Preparata, F.P., and Shamos, M.I. "Computational Geometry: An Introduction." Springer-Verlag (1985)
- Various computational geometry and algorithm design references
