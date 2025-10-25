# Tessellating Portal

A procedural portal generation system that creates various geometric portal structures using tessellated 3D shapes.

## Features

### 🎯 **Portal Types**
- **Cube Portal**: Classic brick arch portal with pillars
- **Truncated Octahedron**: Sci-fi honeycomb portal with layered rings
- **Rhombic Dodecahedron**: Organic crystal portal with dome structure
- **Triangular Prism**: Angular geometric portal with outward-pointing prisms
- **Hexagonal Prism**: Honeycomb portal with nested hexagonal rings
- **Gyrobifastigium**: Twisted dual-prism portal with offset layers

### 🎨 **Visual Effects**
- **Glowing Materials**: Emission-based lighting with configurable intensity
- **Rotation Animation**: Optional automatic rotation for dynamic effects
- **Color Customization**: Full color picker support
- **MultiMesh Rendering**: Efficient rendering of thousands of blocks

### ⚙️ **Configurable Parameters**

#### Portal Configuration
- `portal_type`: Type of portal geometry (enum)
- `portal_radius`: Overall size of the portal
- `portal_thickness`: Depth/thickness of the portal structure
- `block_size`: Size of individual tessellation blocks
- `auto_generate`: Generate portal on ready

#### Visual Properties
- `portal_color`: Base color of the portal
- `emission_strength`: Glow intensity (0.0-5.0)
- `animate_rotation`: Enable automatic rotation
- `rotation_speed`: Speed of rotation animation

## Usage

### Basic Usage
```gdscript
# Create a portal
var portal = TessellatingPortal.new()
add_child(portal)

# Configure parameters
portal.portal_type = TessellatingPortal.PortalType.CUBE
portal.portal_radius = 4.0
portal.portal_thickness = 2.0
portal.block_size = 0.3

# Generate the portal
portal.regenerate()
```

### Advanced Configuration
```gdscript
# Set up a sci-fi portal
portal.portal_type = TessellatingPortal.PortalType.TRUNCATED_OCTAHEDRON
portal.portal_radius = 5.0
portal.portal_thickness = 1.8
portal.block_size = 0.4
portal.portal_color = Color(0.8, 0.2, 0.9)  # Purple
portal.emission_strength = 2.5
portal.animate_rotation = true
portal.rotation_speed = 1.0
```

## Portal Types Explained

### 1. Cube Portal
- **Style**: Classic brick arch
- **Structure**: Semi-circular arch with side pillars
- **Use Case**: Medieval/fantasy settings
- **Pattern**: Radial brick placement

### 2. Truncated Octahedron Portal
- **Style**: Sci-fi honeycomb
- **Structure**: Layered rings with top arch
- **Use Case**: Futuristic/space settings
- **Pattern**: Hexagonal packing simulation

### 3. Rhombic Dodecahedron Portal
- **Style**: Organic crystal
- **Structure**: Hexagonal base with dome top
- **Use Case**: Magical/crystal settings
- **Pattern**: Natural crystal growth simulation

### 4. Triangular Prism Portal
- **Style**: Angular geometric
- **Structure**: Outward-pointing triangular prisms
- **Use Case**: Abstract/geometric art
- **Pattern**: Radial triangular arrangement

### 5. Hexagonal Prism Portal
- **Style**: Honeycomb
- **Structure**: Nested hexagonal rings
- **Use Case**: Nature-inspired/hexagonal themes
- **Pattern**: Hexagonal grid tessellation

### 6. Gyrobifastigium Portal
- **Style**: Twisted dual-prism
- **Structure**: Offset layers with twist
- **Use Case**: Surreal/abstract art
- **Pattern**: Twisted geometric arrangement

## Algorithm Details

### Tessellation Process
1. **Shape Selection**: Choose base mesh for tessellation blocks
2. **Pattern Generation**: Create geometric arrangement based on portal type
3. **Transform Calculation**: Position and orient each block
4. **MultiMesh Creation**: Efficiently render all blocks

### Mesh Generation
Each portal type uses appropriate 3D shapes:
- **Cubes**: Simple BoxMesh for brick-like appearance
- **Prisms**: Custom triangular and hexagonal prisms
- **Complex Shapes**: Simplified approximations using spheres

### Performance Optimization
- **MultiMesh Rendering**: Single draw call for all blocks
- **Efficient Meshes**: Optimized geometry for each shape type
- **Material Sharing**: Single material instance for all blocks

## Demo Scene

The `tessellating_portal_demo.tscn` scene includes:
- Interactive UI controls for all parameters
- Real-time camera rotation
- Mouse wheel zoom
- Click to randomize parameters
- Live statistics display
- Color picker integration

## Integration

The TessellatingPortal class integrates well with:
- **Game Portals**: Teleportation mechanics
- **Architectural Visualization**: Building entrances
- **Art Installations**: Interactive geometric sculptures
- **VR Environments**: Immersive portal experiences

## Examples

### Medieval Castle Portal
```gdscript
portal.portal_type = TessellatingPortal.PortalType.CUBE
portal.portal_radius = 3.0
portal.portal_thickness = 2.0
portal.block_size = 0.4
portal.portal_color = Color(0.6, 0.4, 0.2)  # Brown stone
portal.emission_strength = 0.5
```

### Sci-Fi Gateway
```gdscript
portal.portal_type = TessellatingPortal.PortalType.TRUNCATED_OCTAHEDRON
portal.portal_radius = 4.0
portal.portal_thickness = 1.5
portal.block_size = 0.3
portal.portal_color = Color(0.2, 0.8, 1.0)  # Cyan
portal.emission_strength = 2.0
portal.animate_rotation = true
```

### Crystal Portal
```gdscript
portal.portal_type = TessellatingPortal.PortalType.RHOMBIC_DODECAHEDRON
portal.portal_radius = 3.5
portal.portal_thickness = 1.2
portal.block_size = 0.25
portal.portal_color = Color(0.9, 0.3, 0.9)  # Magenta
portal.emission_strength = 1.8
```

## Technical Notes

- Uses `SurfaceTool` for custom mesh generation
- Implements proper normal calculation for lighting
- Supports both static and animated portals
- Memory efficient with MultiMesh rendering
- Compatible with Godot 4.x rendering pipeline
- Export groups for organized inspector interface

## Performance Considerations

- **Block Count**: More blocks = better detail but higher cost
- **Radius vs Block Size**: Larger radius with smaller blocks = more geometry
- **Animation**: Rotation animation adds minimal overhead
- **Materials**: Single material shared across all instances

## Future Enhancements

- **Particle Effects**: Portal activation animations
- **Sound Integration**: Audio feedback for portal interactions
- **Collision Detection**: Portal entry/exit mechanics
- **Custom Shapes**: User-defined tessellation patterns
- **LOD System**: Distance-based detail reduction









