# Godot 4 Procedural Mesh Generation Strategies

A collection of different techniques for generating meshes procedurally.

## Included Strategies

### 1. Marching Cubes 🧊
**File:** `marching_cubes.gd`

**What it does:** Extracts smooth surfaces from 3D scalar fields (like density)

**Use cases:**
- Liquid simulation visualization
- Terrain with caves
- Organic blob shapes
- Medical imaging (CT/MRI visualization)

**How it works:**
- Creates 3D grid of scalar values (noise/density field)
- For each cube in grid, checks which corners are "inside"
- Uses lookup table to create triangles at surface
- Results in smooth, continuous surfaces

**Key parameters:**
- Grid size: Resolution (more = smoother but slower)
- ISO value: Surface threshold
- Noise scale: Organic variation

---

### 2. Metaballs 🔮
**File:** `metaballs.gd`

**What it does:** Creates smooth, blobby shapes from sphere influences

**Use cases:**
- Lava/liquid effects
- Organic characters
- Soft body visualization
- Magical effects

**How it works:**
- Multiple spheres with influence radii
- Each point in space has "potential" based on distance to spheres
- Surface extracted where potential = threshold
- Spheres blend smoothly into each other

**Key parameters:**
- Number of balls
- Animation speed
- Threshold value

**Special feature:** Animated! Balls move and blend in real-time

---

### 3. Delaunay Triangulation 📐
**File:** `delaunay.gd`

**What it does:** Creates mesh from random 2D points, extruded to 3D

**Use cases:**
- Procedural rocks/crystals
- Abstract art
- Architectural forms
- Optimized collision meshes

**How it works:**
- Scatter points in 2D
- Use Delaunay triangulation (maximizes minimum angles)
- Extrude upward to create 3D shapes
- Adds side faces

**Key parameters:**
- Number of points
- Spread area
- Extrude height

**Advantage:** Guaranteed no thin/degenerate triangles

---

### 4. Heightmap Terrain 🏔️
**File:** `heightmap.gd`

**What it does:** Generates terrain from height values (noise)

**Use cases:**
- Terrain generation
- Landscapes
- Ocean floors
- Dunes/hills

**How it works:**
- Creates 2D grid of points
- Sample noise function for height at each point
- Connect points into triangulated mesh
- Can use multiple noise layers (octaves)

**Key parameters:**
- Resolution: Detail level
- Height scale: How tall
- Noise frequency: Feature size
- Octaves: Detail layers

**Classic technique:** Used in games since 90s

---

### 5. Convex Hull 📦
**File:** `convex_hull.gd`

**What it does:** Creates smallest convex shape containing points

**Use cases:**
- Simplified collision meshes
- Bounding volumes
- Rock/asteroid shapes
- Physics optimization

**How it works:**
- Scatter points in 3D
- Calculate convex hull (shrink wrap)
- Hull is smallest convex volume containing all points
- Always convex (no indents)

**Key parameters:**
- Number of points
- Point spread

**Advantage:** Fast collision detection with convex shapes

---

### 6. Curve Extrusion 🛤️
**File:** `curve_extrusion.gd`

**What it does:** Sweeps 2D shape along 3D path

**Use cases:**
- Roads/paths
- Pipes/cables
- Vines/tentacles
- Trails/ribbons

**How it works:**
- Define 3D curve path
- Define 2D profile shape (circle for tube)
- Move profile along path
- Connect profile positions into mesh

**Key parameters:**
- Path complexity
- Tube radius
- Number of segments

**Flexible:** Can extrude any 2D shape along any path

---

## Quick Start

```bash
python install_mesh_strategies.py
```

Then open `demo_scene.tscn` and press F5!

## Controls

- **Number keys 1-6**: Switch between strategies
- **Arrow keys**: Previous/next strategy
- **SPACE**: Regenerate current mesh
- **Strategy-specific keys** (see each file)

## Comparison Table

| Strategy | Smooth | Organic | Fast | Best For |
|----------|--------|---------|------|----------|
| Marching Cubes | ✅✅✅ | ✅✅✅ | ⚠️ | Liquids, caves |
| Metaballs | ✅✅✅ | ✅✅✅ | ⚠️ | Blobs, effects |
| Delaunay | ⚠️ | ⚠️ | ✅✅ | Crystals, art |
| Heightmap | ✅✅ | ✅✅ | ✅✅✅ | Terrain |
| Convex Hull | ⚠️ | ⚠️ | ✅✅✅ | Collision |
| Curve Extrusion | ✅✅ | ✅ | ✅✅ | Roads, pipes |

## Advanced Combinations

### Terrain with Caves
```
1. Generate heightmap for surface
2. Use marching cubes underground
3. Blend at interface
```

### Organic Creature
```
1. Metaballs for main body
2. Curve extrusion for limbs
3. Convex hull for collision
```

### Procedural City
```
1. Delaunay for building plots
2. Curve extrusion for roads
3. Heightmap for surrounding terrain
```

## Performance Tips

1. **Grid Resolution**: Lower = faster but blockier
2. **Point Count**: Fewer = faster generation
3. **Caching**: Generate once, reuse
4. **LOD**: Multiple detail levels
5. **Async Generation**: Don't block main thread

## Other Strategies (Not Implemented)

These would be great additions:

- **Dual Contouring**: Like marching cubes but preserves sharp edges
- **Surface Nets**: Simpler than marching cubes
- **Poisson Reconstruction**: From point cloud with normals
- **CSG (Constructive Solid Geometry)**: Boolean operations
- **L-Systems**: Procedural plants/trees
- **Wave Function Collapse**: Tile-based generation
- **Signed Distance Fields**: Ray marching
- **Alpha Shapes**: Concave hull from points
- **Ball Pivoting**: Point cloud meshing

## When to Use What?

**Need smooth organic shapes?**
→ Marching Cubes or Metaballs

**Need fast terrain?**
→ Heightmap

**Need optimized collision?**
→ Convex Hull or simplified voxels

**Need to follow a path?**
→ Curve Extrusion

**Need abstract/crystalline?**
→ Delaunay Triangulation

**Need runtime generation?**
→ Heightmap (fastest) or Metaballs (most dynamic)

## Extending

Each script is self-contained and can be:
- Modified for specific needs
- Combined with others
- Exported to mesh files
- Used in game runtime

## Credits

Based on classic computer graphics algorithms.
Implemented in Godot 4 GDScript.

Enjoy creating! 🎨
