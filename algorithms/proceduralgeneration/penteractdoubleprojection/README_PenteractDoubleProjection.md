# Penteract Double Projection

An advanced 5D visualization system that performs double projection from 5-dimensional penteract (5-cube) through 4D space to 3D rendering, showcasing the complex mathematics of higher-dimensional geometry.

## Features

### 🎯 **Double Projection System**
- **5D → 4D Projection**: First projection from 5D penteract to 4D tesseract
- **4D → 3D Projection**: Second projection from 4D tesseract to 3D rendering
- **Four Projection Modes**: Different combinations of perspective and orthographic projections
- **Mathematical Accuracy**: Proper implementation of higher-dimensional projection mathematics

### 🌌 **5D Space Manipulation**
- **5D Rotation**: Rotation in VW plane (5th and 4th dimensions)
- **4D Rotations**: Multiple rotation planes (XW, YW, ZW)
- **Animation Support**: Automatic rotation through higher dimensions
- **Dynamic Color Mapping**: Colors based on 5D V-coordinate for depth perception

### ⚙️ **Configurable Parameters**

#### Projection Settings
- `projection_mode`: Double projection method (enum)
- `penteract_size`: Size of the 5D penteract
- `projection_distance_5d`: Distance for 5D→4D perspective projection
- `projection_distance_4d`: Distance for 4D→3D perspective projection

#### Higher Dimension Rotations
- `rotation_5d_vw`: Rotation in VW plane (5D)
- `rotation_4d_xw`: Rotation in XW plane (4D)
- `rotation_4d_yw`: Rotation in YW plane (4D)
- `rotation_4d_zw`: Rotation in ZW plane (4D)
- `animate_rotation`: Enable automatic rotation
- `rotation_speed`: Speed of rotation animation

#### Visual Properties
- `inner_color`: Color for innermost 5D positions
- `middle_color`: Color for middle 5D positions
- `outer_color`: Color for outermost 5D positions
- `edge_thickness`: Thickness of rendered edges
- `emission_strength`: Glow intensity

## Usage

### Basic Usage
```gdscript
# Create a penteract double projection
var penteract = PenteractDoubleProjection.new()
add_child(penteract)

# Configure parameters
penteract.projection_mode = PenteractDoubleProjection.ProjectionMode.PERSPECTIVE_BOTH
penteract.penteract_size = 3.0
penteract.projection_distance_5d = 5.0
penteract.projection_distance_4d = 4.0

# Generate the penteract
penteract.regenerate()
```

### Advanced Configuration
```gdscript
# Set up a complex 5D visualization
penteract.projection_mode = PenteractDoubleProjection.ProjectionMode.MIXED_PERSP_ORTHO
penteract.penteract_size = 2.5
penteract.projection_distance_5d = 6.0
penteract.projection_distance_4d = 4.0
penteract.animate_rotation = true
penteract.rotation_speed = 0.5
penteract.inner_color = Color(1.0, 0.2, 0.2)  # Red
penteract.middle_color = Color(0.2, 1.0, 0.2)  # Green
penteract.outer_color = Color(0.2, 0.2, 1.0)  # Blue
```

## Projection Modes Explained

### 1. Perspective Both
- **5D→4D**: Perspective projection
- **4D→3D**: Perspective projection
- **Effect**: Most immersive 5D experience
- **Use Case**: Educational visualization, art installations

### 2. Orthographic Both
- **5D→4D**: Orthographic projection (drops V dimension)
- **4D→3D**: Orthographic projection (drops W dimension)
- **Effect**: Clear geometric structure
- **Use Case**: Mathematical analysis, structural understanding

### 3. Mixed Persp-Ortho
- **5D→4D**: Perspective projection
- **4D→3D**: Orthographic projection
- **Effect**: 5D depth with 4D clarity
- **Use Case**: Hybrid visualization approach

### 4. Mixed Ortho-Persp
- **5D→4D**: Orthographic projection
- **4D→3D**: Perspective projection
- **Effect**: 4D structure with 3D depth
- **Use Case**: 4D-focused visualization

## Algorithm Details

### Penteract Generation
1. **5D Vertices**: Generate 32 vertices of 5-cube in 5D space
2. **5D Rotation**: Apply rotation in VW plane
3. **First Projection**: Project 5D → 4D using selected method
4. **4D Rotations**: Apply rotations in XW, YW, ZW planes
5. **Second Projection**: Project 4D → 3D using selected method
6. **Edge Detection**: Connect vertices differing by exactly one bit
7. **Rendering**: Create line mesh with 5D-based color mapping

### Mathematical Projections

#### 5D → 4D Projection
- **Perspective**: `(x,y,z,w,v) → (x,y,z,w) * distance / (distance - v)`
- **Orthographic**: `(x,y,z,w,v) → (x,y,z,w)`

#### 4D → 3D Projection
- **Perspective**: `(x,y,z,w) → (x,y,z) * distance / (distance - w)`
- **Orthographic**: `(x,y,z,w) → (x,y,z)`

### Color Mapping
- **5D V-Coordinate**: Colors based on V position in 5D space
- **Three-Color System**: Inner, middle, outer color interpolation
- **Depth Perception**: Visual cues for 5D positioning

## Demo Scene

The `penteract_demo.tscn` scene includes:
- Interactive UI controls for all parameters
- Real-time camera rotation
- Mouse wheel zoom
- Click to randomize parameters
- Right-click to cycle projection modes
- Live statistics display
- Multiple color pickers for 5D depth visualization

## Integration

The PenteractDoubleProjection class integrates well with:
- **Mathematical Education**: 5D geometry visualization
- **Research Applications**: Higher-dimensional analysis
- **Art Installations**: Abstract 5D sculptures
- **VR Experiences**: Immersive 5D exploration

## Examples

### Educational Visualization
```gdscript
penteract.projection_mode = PenteractDoubleProjection.ProjectionMode.ORTHOGRAPHIC_BOTH
penteract.penteract_size = 2.0
penteract.animate_rotation = false
penteract.inner_color = Color(0.8, 0.2, 0.2)  # Red
penteract.middle_color = Color(0.2, 0.8, 0.2)  # Green
penteract.outer_color = Color(0.2, 0.2, 0.8)  # Blue
```

### Immersive Experience
```gdscript
penteract.projection_mode = PenteractDoubleProjection.ProjectionMode.PERSPECTIVE_BOTH
penteract.penteract_size = 3.0
penteract.animate_rotation = true
penteract.rotation_speed = 0.8
penteract.inner_color = Color(1.0, 0.4, 0.8)  # Pink
penteract.middle_color = Color(0.4, 1.0, 0.8)  # Cyan
penteract.outer_color = Color(0.8, 0.4, 1.0)  # Purple
```

### Mathematical Analysis
```gdscript
penteract.projection_mode = PenteractDoubleProjection.ProjectionMode.MIXED_PERSP_ORTHO
penteract.penteract_size = 1.5
penteract.projection_distance_5d = 8.0
penteract.animate_rotation = true
penteract.rotation_speed = 0.2
```

## Technical Notes

### 5D Vector Class
- Custom `Vector5` class for 5D mathematics
- Efficient 5D rotation calculations
- Operator overloads for vector arithmetic

### Performance Considerations
- **Fixed Geometry**: 32 vertices, 80 edges (constant)
- **Projection Complexity**: Perspective projections are more expensive
- **Animation**: Real-time regeneration for smooth effects
- **Line Rendering**: Uses ImmediateMesh for efficiency

### Memory Management
- Dynamic mesh generation
- Efficient edge detection algorithm
- Color interpolation per edge

## Mathematical Background

### Penteract Structure
- **Vertices**: 32 corners of 5D hypercube
- **Edges**: 80 edges connecting adjacent vertices
- **Faces**: 80 square faces (10 tesseracts)
- **Cells**: 40 cubic cells (5 tesseracts)
- **4-Cells**: 10 tesseract cells

### Higher-Dimensional Rotations
- **5D Rotations**: VW plane rotations
- **4D Rotations**: XW, YW, ZW plane rotations
- **Matrix Form**: 5x5 and 4x4 rotation matrices

### Projection Mathematics
- **Double Projection**: Two-stage projection process
- **Perspective**: 5D and 4D perspective projections
- **Orthographic**: Simple coordinate dropping

## Future Enhancements

- **Interactive 5D Navigation**: Mouse-controlled 5D rotation
- **Particle Effects**: 5D particle systems
- **Sound Integration**: Audio based on 5D position
- **VR Support**: Immersive 5D exploration
- **Custom Projections**: User-defined projection functions
- **Animation Sequences**: Predefined 5D motion patterns
- **6D Extensions**: Hexeract (6-cube) visualization
- **Real-time Shaders**: GPU-accelerated projections

## Mathematical Complexity

This system represents one of the most advanced mathematical visualizations possible in 3D space, requiring:
- **5D Vector Mathematics**: Complete 5D vector operations
- **Double Projection**: Two-stage mathematical projection
- **Higher-Dimensional Rotations**: Multiple rotation planes
- **Edge Detection**: Efficient 5D edge finding algorithm
- **Color Interpolation**: 5D position-based color mapping

The PenteractDoubleProjection system pushes the boundaries of mathematical visualization, making the abstract concept of 5-dimensional space tangible and explorable.

