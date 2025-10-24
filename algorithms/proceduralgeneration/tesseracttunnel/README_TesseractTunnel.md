# Tesseract Tunnel

A 4D tesseract visualization system that creates immersive tunnel structures by projecting 4-dimensional hypercubes into 3D space using various mathematical projection methods.

## Features

### 🎯 **4D Projection Methods**
- **Cell First**: Orthographic projection emphasizing outer cube structure
- **Vertex First**: Orthographic projection with W-based scaling for inner cube emphasis
- **Perspective**: Perspective projection from 4D viewpoint
- **Stereographic**: Conformal mapping preserving angles

### 🌌 **4D Space Manipulation**
- **W-Dimension Animation**: Automatic movement through 4th dimension
- **4D Rotation**: Rotation in 4D space (XY-ZW plane)
- **Cylindrical Arrangement**: Tesseracts arranged in hollow cylinder pattern
- **Dynamic Color Mapping**: Colors based on W-position for depth perception

### ⚙️ **Configurable Parameters**

#### Tunnel Configuration
- `projection_type`: Mathematical projection method (enum)
- `tunnel_radius`: Overall size of the tunnel
- `tunnel_length`: Length of the tunnel structure
- `tesseract_grid_density`: Number of tesseract rings
- `tesseract_size`: Size of individual tesseracts

#### 4D Space
- `w_offset`: Position in 4th dimension
- `animate_w`: Enable automatic W-dimension animation
- `w_speed`: Speed of W-dimension movement
- `rotation_4d`: Rotation angle in 4D space

#### Visual Properties
- `edge_color`: Base color for tesseract edges
- `emission_strength`: Glow intensity
- `inner_color`: Color for inner W-positions
- `outer_color`: Color for outer W-positions

## Usage

### Basic Usage
```gdscript
# Create a tesseract tunnel
var tunnel = TesseractTunnel.new()
add_child(tunnel)

# Configure parameters
tunnel.projection_type = TesseractTunnel.ProjectionType.PERSPECTIVE
tunnel.tunnel_radius = 6.0
tunnel.tunnel_length = 25.0
tunnel.tesseract_grid_density = 4

# Generate the tunnel
tunnel.regenerate()
```

### Advanced Configuration
```gdscript
# Set up a complex 4D visualization
tunnel.projection_type = TesseractTunnel.ProjectionType.STEREOGRAPHIC
tunnel.tunnel_radius = 8.0
tunnel.tunnel_length = 30.0
tunnel.tesseract_grid_density = 5
tunnel.tesseract_size = 2.0
tunnel.animate_w = true
tunnel.w_speed = 0.8
tunnel.edge_color = Color(0.8, 0.2, 0.9)  # Magenta
tunnel.inner_color = Color(1.0, 0.3, 0.5)  # Pink
tunnel.outer_color = Color(0.2, 0.6, 1.0)  # Blue
```

## Projection Methods Explained

### 1. Cell First (Orthographic)
- **Method**: Simple orthographic projection (drops W coordinate)
- **Effect**: Emphasizes the outer cube structure
- **Use Case**: Clear geometric visualization
- **Formula**: `(x, y, z, w) → (x, y, z)`

### 2. Vertex First (Scaled Orthographic)
- **Method**: Orthographic with W-based scaling
- **Effect**: Inner cube emphasized through scaling
- **Use Case**: Understanding tesseract structure
- **Formula**: `(x, y, z, w) → (x, y, z) / (2.0 + w * 0.3)`

### 3. Perspective (4D Perspective)
- **Method**: Perspective projection from 4D viewpoint
- **Effect**: Natural depth perception from 4D
- **Use Case**: Immersive 4D experience
- **Formula**: `(x, y, z, w) → (x, y, z) * distance / (distance - w)`

### 4. Stereographic (Conformal)
- **Method**: Stereographic projection preserving angles
- **Effect**: Conformal mapping with interesting distortions
- **Use Case**: Mathematical visualization
- **Formula**: `(x, y, z, w) → (x, y, z) / (1.0 - w / 5.0)`

## Algorithm Details

### Tesseract Generation
1. **4D Vertices**: Generate 16 vertices of hypercube in 4D space
2. **Edge Detection**: Connect vertices differing by exactly one bit
3. **4D Rotation**: Apply rotation in 4D space
4. **Projection**: Project to 3D using selected method
5. **Rendering**: Create line mesh with color mapping

### Cylindrical Arrangement
- **Ring Structure**: Multiple rings of tesseracts
- **Density Variation**: More tesseracts in outer rings
- **W-Offset**: Each ring offset in 4th dimension
- **Tunnel Length**: Tesseracts distributed along Z-axis

### Color Mapping
- **W-Position Based**: Colors interpolated based on W-coordinate
- **Inner/Outer Colors**: Smooth transition between color ranges
- **Depth Perception**: Visual cues for 4D positioning

## Demo Scene

The `tesseract_tunnel_demo.tscn` scene includes:
- Interactive UI controls for all parameters
- Real-time camera rotation
- Mouse wheel zoom
- Click to randomize parameters
- Right-click to cycle projection types
- Live statistics display
- Multiple color pickers

## Integration

The TesseractTunnel class integrates well with:
- **Mathematical Visualization**: 4D geometry education
- **Art Installations**: Abstract 4D sculptures
- **VR Experiences**: Immersive 4D environments
- **Game Mechanics**: Portal effects and transitions

## Examples

### Educational Visualization
```gdscript
tunnel.projection_type = TesseractTunnel.ProjectionType.CELL_FIRST
tunnel.tunnel_radius = 4.0
tunnel.tunnel_length = 15.0
tunnel.tesseract_grid_density = 2
tunnel.tesseract_size = 1.0
tunnel.animate_w = false
tunnel.edge_color = Color(0.2, 0.8, 0.2)  # Green
```

### Immersive Experience
```gdscript
tunnel.projection_type = TesseractTunnel.ProjectionType.PERSPECTIVE
tunnel.tunnel_radius = 6.0
tunnel.tunnel_length = 25.0
tunnel.tesseract_grid_density = 4
tunnel.animate_w = true
tunnel.w_speed = 1.0
tunnel.edge_color = Color(0.8, 0.4, 1.0)  # Purple
```

### Mathematical Art
```gdscript
tunnel.projection_type = TesseractTunnel.ProjectionType.STEREOGRAPHIC
tunnel.tunnel_radius = 8.0
tunnel.tunnel_length = 20.0
tunnel.tesseract_grid_density = 6
tunnel.animate_w = true
tunnel.w_speed = 0.3
tunnel.rotation_4d = PI / 4
```

## Technical Notes

### 4D Vector Class
- Custom `Vector4` class for 4D mathematics
- Operator overloads for vector arithmetic
- Efficient 4D rotation calculations

### Performance Considerations
- **Tesseract Count**: More density = more geometry
- **Projection Complexity**: Stereographic is most expensive
- **Animation**: Real-time regeneration for smooth effects
- **Line Rendering**: Uses ImmediateMesh for efficiency

### Memory Management
- Dynamic mesh generation
- Efficient edge detection algorithm
- Color interpolation per edge

## Mathematical Background

### Tesseract Structure
- **Vertices**: 16 corners of 4D hypercube
- **Edges**: 32 edges connecting adjacent vertices
- **Faces**: 24 square faces (6 cubes)
- **Cells**: 8 cubic cells

### 4D Rotations
- **Plane Rotations**: Rotations in 4D space planes
- **XY-ZW Rotation**: Most common 4D rotation
- **Matrix Form**: 4x4 rotation matrices

### Projection Mathematics
- **Orthographic**: Simple coordinate dropping
- **Perspective**: 4D to 3D perspective projection
- **Stereographic**: Conformal mapping from 4D sphere

## Future Enhancements

- **Interactive 4D Navigation**: Mouse-controlled 4D rotation
- **Particle Effects**: 4D particle systems
- **Sound Integration**: Audio based on 4D position
- **VR Support**: Immersive 4D exploration
- **Custom Projections**: User-defined projection functions
- **Animation Sequences**: Predefined 4D motion patterns








