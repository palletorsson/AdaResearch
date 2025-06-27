# 🏔️ Marching Cubes - Rhizomatic Cave System

A comprehensive marching cubes implementation for generating organic, interconnected cave systems with physics colliders and procedural rhizomatic growth patterns.

## 🎯 Overview

This module implements the marching cubes algorithm to generate smooth, organic cave systems that grow like rhizomes - spreading horizontally and vertically with interconnected chambers and tunnels.

### Key Features
- **Marching Cubes Algorithm**: Smooth isosurface generation from 3D scalar fields
- **Rhizomatic Growth**: Organic, interconnected cave networks
- **Physics Integration**: Automatic collision mesh generation
- **Procedural Generation**: Configurable parameters for diverse cave systems
- **Performance Optimized**: Chunked generation for large cave systems
- **VR Compatible**: Designed for both desktop and VR exploration

## 🏗️ Module Structure

```
algorithms/marchingcubes/
├── README.md                           # This documentation
├── core/                               # Core marching cubes implementation
│   ├── MarchingCubesGenerator.gd      # Main algorithm implementation
│   ├── MarchingCubesLookupTables.gd   # Edge and triangle lookup tables
│   └── VoxelChunk.gd                  # Voxel data management
├── rhizome/                            # Rhizomatic cave generation
│   ├── RhizomeCaveGenerator.gd        # Cave system orchestrator
│   ├── RhizomeGrowthPattern.gd        # Growth algorithm and patterns
│   └── CaveSegment.gd                 # Individual cave segment logic
├── physics/                            # Physics and collision
│   ├── CaveCollisionGenerator.gd      # Collision mesh creation
│   └── CavePhysicsBody.gd             # Physics body management
├── visualization/                      # Rendering and materials
│   ├── CaveMaterialManager.gd         # Cave surface materials
│   └── CaveDebugRenderer.gd           # Debug visualization tools
├── scenes/                             # Demo and test scenes
│   ├── rhizome_cave_demo.tscn         # Interactive cave demo
│   ├── marching_cubes_test.tscn       # Algorithm testing scene
│   └── cave_explorer_vr.tscn          # VR cave exploration
└── examples/                           # Usage examples and presets
	├── simple_cave.gd                 # Basic cave generation
	├── complex_network.gd             # Multi-chamber system
	└── procedural_dungeon.gd          # Game-ready dungeon
```

## 🧮 Marching Cubes Algorithm

The marching cubes algorithm converts a 3D scalar field (density values) into a triangle mesh by:
1. Sampling density at grid vertices
2. Determining surface intersections using lookup tables
3. Generating triangles that approximate the isosurface
4. Creating smooth, organic surfaces from discrete data

## 🌿 Rhizomatic Growth Patterns

Rhizomatic cave systems grow organically through:
- **Horizontal Spreading**: Tunnels that branch and merge
- **Vertical Growth**: Multi-level cave systems
- **Nodal Chambers**: Larger spaces at growth intersections
- **Adaptive Density**: Varying tunnel sizes and chamber volumes
- **Interconnectivity**: Multiple paths between chambers

## 🎮 Usage Examples

### Basic Cave Generation
```gdscript
# Create a simple cave system
var cave_generator = RhizomeCaveGenerator.new()
cave_generator.setup_parameters({
	"size": Vector3(50, 20, 50),
	"density": 0.3,
	"complexity": 0.5
})
var cave_mesh = cave_generator.generate_cave()
```

### Advanced Rhizomatic System
```gdscript
# Create complex interconnected caves
var rhizome_pattern = RhizomeGrowthPattern.new()
rhizome_pattern.add_growth_node(Vector3(0, 0, 0), 5.0)  # Starting chamber
rhizome_pattern.set_growth_rules({
	"branch_probability": 0.7,
	"merge_distance": 8.0,
	"vertical_bias": 0.3
})
var cave_system = cave_generator.generate_from_pattern(rhizome_pattern)
```

## 🔧 Configuration Parameters

### Marching Cubes Settings
- **Resolution**: Voxel grid density (higher = smoother but slower)
- **Threshold**: Isosurface value (0.5 = standard)
- **Smoothing**: Post-processing smoothing iterations

### Rhizomatic Growth
- **Seed Points**: Initial growth locations
- **Branch Factor**: How much the system branches
- **Growth Speed**: Rate of tunnel extension
- **Chamber Size**: Size variation of larger spaces
- **Interconnect Probability**: Chance of tunnel merging

### Physics Options
- **Collision Simplification**: LOD levels for collision meshes
- **Physics Layers**: Collision detection layers
- **Material Properties**: Friction, bounciness for cave surfaces

## 🎯 Performance Considerations

- **Chunked Generation**: Large caves split into manageable chunks
- **LOD System**: Different detail levels based on distance
- **Collision Optimization**: Simplified collision meshes
- **Memory Management**: Efficient voxel data structures
- **Threading**: Background generation for smooth gameplay

## 🚀 Getting Started

1. **Basic Setup**:
   ```gdscript
   var cave = preload("res://algorithms/marchingcubes/scenes/rhizome_cave_demo.tscn").instantiate()
   add_child(cave)
   ```

2. **Custom Generation**:
   ```gdscript
   var generator = RhizomeCaveGenerator.new()
   generator.configure_rhizome_parameters(your_settings)
   var mesh = generator.generate()
   ```

3. **VR Exploration**:
   ```gdscript
   var vr_cave = preload("res://algorithms/marchingcubes/scenes/cave_explorer_vr.tscn").instantiate()
   get_tree().change_scene_to_packed(vr_cave)
   ```

## 🧪 Testing

- **Algorithm Tests**: `marching_cubes_test.tscn` - Verify core algorithm
- **Performance Tests**: Benchmark generation times and memory usage
- **Visual Tests**: Compare different parameter combinations
- **Physics Tests**: Verify collision detection and movement

## 🔮 Future Extensions

- **Texture Mapping**: UV generation for cave surfaces
- **Lighting Integration**: Dynamic lighting for atmospheric caves
- **Sound Propagation**: Acoustic modeling for realistic cave audio
- **Ecosystem Simulation**: Flora, fauna, and environmental effects
- **Procedural Decoration**: Stalactites, stalagmites, crystal formations

---

*This module combines the mathematical precision of marching cubes with the organic beauty of rhizomatic growth to create immersive, explorable cave systems.* 
