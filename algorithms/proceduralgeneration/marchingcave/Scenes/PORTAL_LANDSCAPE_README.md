# 🌀 Portal Landscape - UNIFIED Marching Cubes Topology

## Overview

**Scene**: `marchingcubes_portal_landscape.tscn`

This scene generates a **single unified marching cubes mesh** that includes both a flat landscape AND 7 torus portals emerging from the terrain. The portals are not separate objects - they are seamlessly integrated into the terrain topology using SDF (Signed Distance Function) combination in the compute shader.

### ✨ What Makes This Special

- **Single Mesh**: Terrain + all portals = ONE mesh (not separate objects!)
- **Organic Integration**: Portals emerge seamlessly from the ground
- **CSG Union in Shader**: Multiple torus SDFs combined with terrain in real-time
- **True Portal Geometry**: Walk-through torus rings integrated into the landscape

## Features

### 🎨 Visual Elements

- **Flat Marching Cubes Terrain**: A procedurally generated landscape base
- **7 Colored Portals**: Each torus has a unique color (Red, Green, Blue, Yellow, Magenta, Cyan, Orange)
- **Emission Glow**: Portals emit their respective colors for a mystical effect
- **Labels**: Each portal has a floating label ("Portal 1", "Portal 2", etc.)

### 🔧 Configuration Parameters

The `TerrainGeneratorPortals.gd` script exposes these parameters:

| Parameter | Default | Description |
|-----------|---------|-------------|
| `num_portals` | 7 | Number of portal toruses to generate |
| `portal_radius` | 50.0 | Outer radius of each torus |
| `portal_thickness` | 15.0 | Thickness of the torus tube |
| `portal_spacing` | 300.0 | Distance from center to each portal |
| `portal_emergence_height` | -30.0 | How much of the torus is buried underground (negative = buried) |
| `use_fallback` | false | Use simple fallback meshes if compute shaders fail |
| `terrain_material` | TerrainMat | Material for the terrain surface |

### 🎯 Portal Arrangement

Portals are arranged in a **perfect circle** around the origin:
- Each portal is positioned at equal angular intervals (360° / 7 ≈ 51.4°)
- All portals are at the same distance from the center (`portal_spacing`)
- Portals are partially buried to create an "emerging from the ground" effect

## Technical Details

### Architecture

The system consists of:

1. **TerrainGeneratorUnifiedPortals.gd** (Main Script)
   - Single `MeshInstance3D` that generates the entire scene
   - Manages all portal parameters
   - Handles compute shader initialization and mesh generation

2. **MarchingCubesPortalTerrain.glsl** (Compute Shader) ⭐
   - **Unified density function** combining:
     - Terrain SDF (flat landscape with hills)
     - 7 torus SDFs at different positions
   - Uses `min()` for CSG Union (solid where ANY shape is solid)
   - Each portal has organic noise deformation

### Compute Shader Pipeline

The **unified compute shader** generates a single mesh:

1. **Density Evaluation** (per voxel):
   ```glsl
   terrainDensity = calculate_terrain_height(worldPos)
   
   portalsDensity = HUGE_VALUE
   for each portal:
       torusDist = calculate_torus_sdf(worldPos, portalPos)
       portalsDensity = min(portalsDensity, torusDist)
   
   finalDensity = min(terrainDensity, portalsDensity) // CSG Union
   ```

2. **Marching Cubes**: Converts combined density field to triangles
3. **Result**: ONE continuous mesh with terrain AND portals

## Usage

### Opening the Scene

1. Open `res://algorithms/proceduralgeneration/marchingcave/Scenes/marchingcubes_portal_landscape.tscn`
2. Run the scene (F6) to see the portals generate
3. The terrain and all 7 portals will generate procedurally

### Customization

**In the Scene**:
1. Select the `PortalGenerator` node
2. Adjust exposed parameters in the Inspector:
   - Change `num_portals` to add/remove portals
   - Adjust `portal_spacing` to make them closer/farther
   - Modify `portal_emergence_height` to change burial depth
   - Toggle `use_fallback` if compute shaders fail

**Portal Colors**:
Colors are defined in the `portal_colors` array in `TerrainGeneratorPortals.gd`:
```gdscript
@export var portal_colors : Array[Color] = [
    Color(1.0, 0.3, 0.3, 1.0),  # Red
    Color(0.3, 1.0, 0.3, 1.0),  # Green
    # ... modify these to change portal colors
]
```

### Performance Notes

- **Compute Shader Requirement**: Requires GPU compute shader support
- **Fallback Mode**: Set `use_fallback = true` for simple geometric toruses if compute fails
- **Generation Time**: Initial generation takes 2-5 seconds depending on hardware
- **Memory**: Each portal generates ~10k-50k triangles depending on resolution

## Extending as Actual Portals

To make these functional teleportation portals:

1. **Add Portal Logic**:
   ```gdscript
   # In TerrainGeneratorPortals.gd, add:
   func _create_portal_trigger(portal: MeshInstance3D, index: int):
       var area = Area3D.new()
       area.name = "PortalTrigger"
       portal.add_child(area)
       
       var collision = CollisionShape3D.new()
       var shape = CylinderShape3D.new()
       shape.radius = portal_radius * 0.8
       shape.height = portal_thickness
       collision.shape = shape
       area.add_child(collision)
       
       area.body_entered.connect(_on_portal_entered.bind(index))
   
   func _on_portal_entered(body: Node3D, portal_index: int):
       # Implement teleportation logic here
       var next_portal_index = (portal_index + 1) % num_portals
       var next_portal = portal_meshes[next_portal_index]
       body.global_position = next_portal.global_position
   ```

2. **Add Visual Effects**:
   - Particle effects when entering portal
   - Sound effects for teleportation
   - Screen transition/flash effect

3. **Add Portal Markers**:
   - Glowing rings around portal edges
   - Swirling particles inside torus
   - Destination preview inside portal

## Related Scenes

- `marchingcubes_flat_landscape.tscn` - Base flat terrain
- `marchingcubes_torus_sculpture.tscn` - Single torus example
- `marchingcubes_inside_cave.tscn` - Cave interior with marching cubes

## Troubleshooting

**Portals not appearing**:
- Check console for compute shader errors
- Set `use_fallback = true` to use simple torus meshes
- Verify GPU supports compute shaders

**Portals too buried/exposed**:
- Adjust `portal_emergence_height` (negative = buried, positive = floating)
- Typical range: -50 to 0 for partially buried effect

**Performance issues**:
- Reduce `num_portals`
- Decrease `portal_radius` (smaller = fewer triangles)
- Enable `use_fallback` mode

---

**Created**: 2025-10-23  
**Based on**: Existing marching cubes terrain and torus examples  
**Purpose**: Demonstrate multiple marching cubes objects in a single scene as portal structures

