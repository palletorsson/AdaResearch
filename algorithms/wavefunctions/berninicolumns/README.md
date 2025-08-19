# Bernini Columns - Baroque Architecture Simulation

A 3D procedural generation system that creates spiral columns inspired by Gian Lorenzo Bernini's baroque architectural style, particularly the Baldacchino columns of St. Peter's Basilica.

## Features

### 🏛️ **Architectural Elements**
- **Spiral Column Generation**: Procedural mesh creation with customizable spiral patterns
- **Baldacchino Layout**: Four-column arrangement in classical style
- **Column Components**: Base, shaft with spiral details, and capitals
- **Platform Base**: Supporting marble-like platform

### 🌊 **Mathematical Spiral System**
- **Dual-Axis Spiraling**: Sine and cosine wave displacement for complex spiraling
- **Height-Based Variation**: Progressive twisting and radius changes
- **Surface Complexity**: Secondary wave patterns for baroque detailing
- **Parametric Control**: Adjustable spiral density, amplitude, and twist factors

### ⚙️ **Customization Parameters**
- `column_height`: Overall height of columns (default: 8.0)
- `column_radius`: Base radius of column shaft (default: 0.5) 
- `spiral_density`: Number of complete rotations (default: 3.0)
- `sine_amplitude` / `cosine_amplitude`: Spiral displacement strength
- `twist_factor`: Progressive twisting as column rises (default: 0.8)
- `material_color`: Gold-like baroque coloring

### 🎨 **Visual Features**
- **Metallic Materials**: Gold-like appearance with proper metallic/roughness values
- **Animated Rotation**: Optional gentle rotation animation
- **Lighting System**: Directional lighting to highlight column details
- **Surface Normals**: Proper normal generation for realistic lighting

## Usage

1. **Scene Setup**: Load `BerniniScene.tscn` or attach `BerniniColumns.gd` to a Node3D
2. **Parameter Tuning**: Adjust export variables in the inspector
3. **Material Customization**: Modify `material_color` for different marble/metal effects

## Development Roadmap

### 🔮 **Planned Features**
- [ ] **Historical Variants**: Different baroque column styles (Solomonic, Composite)
- [ ] **Material Library**: Multiple baroque materials (marble types, bronze, gold leaf)
- [ ] **Architectural Context**: Surrounding church elements, arches, vaulting
- [ ] **Interactive Tours**: Camera paths for architectural exploration
- [ ] **Audio Integration**: Baroque music synchronized with visual elements

### 🛠️ **Technical Improvements**
- [ ] **LOD System**: Level-of-detail for performance optimization
- [ ] **Collision Meshes**: Physics-enabled columns for interaction
- [ ] **Texture Mapping**: Procedural marble veining and surface detail
- [ ] **Shadow Optimization**: Efficient shadow casting for complex geometry

### 📚 **Educational Extensions**
- [ ] **Historical Information**: Interactive plaques with architectural history
- [ ] **Construction Process**: Animated assembly showing baroque techniques
- [ ] **Style Comparison**: Side-by-side classical vs baroque comparisons
- [ ] **VR Support**: Immersive architectural walkthroughs

## Mathematical Foundation

The spiral generation uses parametric equations:
```
x(t,θ) = cos(θ + twist*t) * radius(t) + sine_wave(t)
z(t,θ) = sin(θ + twist*t) * radius(t) + cosine_wave(t)
y(t) = t * height
```

Where `t` represents height progression (0-1) and `θ` represents radial position.

## Scene Files

- `BerniniColumns.gd` - Main procedural generation script
- `BerniniScene.tscn` - Pre-configured scene with lighting
- `BerniniColumns.gd.uid` - Godot asset identifier

## Historical Context

Inspired by Bernini's Baldacchino (1623-1634) in St. Peter's Basilica, this simulation captures the dynamic, spiraling energy characteristic of baroque architecture while providing modern parametric control over the mathematical generation process. 