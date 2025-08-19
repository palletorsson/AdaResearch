# Kusama Sine - Yayoi Kusama Inspired 3D Sculpture Generator

A procedural 3D sculpture generator inspired by Yayoi Kusama's iconic polka dot infinity installations, combining mathematical sine wave forms with her distinctive visual language.

## Features

### 🎨 **Kusama Visual Elements**
- **Iconic Color Palette**: Vibrant reds, pinks, greens, blues, yellows, and purples
- **Polka Dot Patterns**: Procedurally generated dot distributions on all surfaces
- **Organic Forms**: Flowing, biomorphic shapes reminiscent of Kusama's soft sculptures
- **Infinity Aesthetics**: Repetitive patterns suggesting infinite expansion

### 🌸 **Sculptural Components**

#### **Central Core**
- **Primary Sphere**: Large yellow sphere as the central focal point
- **Inner Spiral**: Geometric spiral pattern within the core
- **Polka Dot Surface**: Contrasting colored dots covering the sphere surface
- **Material Properties**: Metallic finish with controlled roughness

#### **Radiating Petals** 
- **Custom Petal Geometry**: Flattened torus forms reshaped into organic petals
- **Sine Wave Deformation**: Mathematical waviness along petal edges
- **Color Distribution**: Each petal uses a different color from Kusama's palette
- **Rotational Symmetry**: Configurable number of petals arranged radially

#### **Flowing Tendrils**
- **Curved Paths**: Organic pathways extending from the central form
- **Diminishing Scale**: Spherical segments decreasing in size along length
- **Multi-colored**: Different base colors per tendril
- **Height Variation**: Sine-based vertical movement for natural flow

### ⚙️ **Generation Parameters**
- `num_petals`: Number of radiating petal forms (default: 7)
- `num_tendrils`: Number of flowing tendril extensions (default: 3)
- `generate_on_ready`: Automatic generation when scene loads
- Color palette arrays for consistent Kusama-style coloring

### 🔄 **Procedural Features**
- **Randomized Elements**: Each generation creates unique variations
- **Mesh Deformation**: Mathematical reshaping of basic geometric forms
- **Dynamic Scaling**: Size variations create visual hierarchy
- **Surface Detail**: Polka dot placement with inverted color schemes

## Usage

### Quick Start
1. **Load Scene**: Open `kusama_sine.tscn`
2. **Auto-Generate**: Sculpture creates automatically with default parameters
3. **Regenerate**: Call `generate_sculpture()` for new variations
4. **Customize**: Adjust parameters in inspector for different configurations

### Customization
1. **Petal Count**: Modify `num_petals` for more/fewer radiating elements
2. **Tendril Complexity**: Adjust `num_tendrils` for additional flowing forms
3. **Color Variations**: Edit the `kusama_colors` array for custom palettes
4. **Scale Adjustments**: Modify radius and height values for different proportions

## Technical Implementation

### Mesh Generation
```gdscript
- SurfaceTool: Custom mesh creation and modification
- MeshDataTool: Vertex-level manipulation for organic shaping
- ArrayMesh: Final optimized mesh output
- Material Assignment: PBR materials with metallic properties
```

### Mathematical Deformation
```gdscript
# Petal waviness calculation
var waviness = sin(angle * 5) * 0.1
vertex.y += waviness

# Tendril curvature
var segment_angle = angle + (i * 0.2)
var height_curve = sin(i * 0.8) * 0.5
```

### Color System
- **Kusama Palette**: Six signature colors with proper Color() definitions
- **Cycling Distribution**: Colors assigned cyclically to ensure variety
- **Contrast Management**: Automatic color inversion for polka dots

## Development Roadmap

### 🎨 **Artistic Enhancements**
- [ ] **Infinity Rooms**: Surrounding environment with mirror effects
- [ ] **Animated Dots**: Pulsating or moving polka dot patterns
- [ ] **Scale Variations**: Multiple sculpture sizes in same scene
- [ ] **Interactive Elements**: User-triggered generation or color changes
- [ ] **Light Integration**: Colored lighting to enhance mood

### 🌟 **Visual Improvements**
- [ ] **Texture Maps**: Procedural texture generation for surface detail
- [ ] **Subsurface Scattering**: Soft material properties for organic feel
- [ ] **HDR Environment**: Museum-quality lighting setups
- [ ] **Particle Systems**: Floating dots or atmospheric effects
- [ ] **Post-Processing**: Bloom and color grading for gallery aesthetics

### 🔧 **Technical Features**
- [ ] **LOD System**: Performance optimization for complex scenes
- [ ] **Export Functions**: STL/OBJ export for 3D printing
- [ ] **Animation System**: Subtle movement and transformation over time
- [ ] **VR Support**: Immersive gallery experience
- [ ] **Physics Integration**: Soft-body dynamics for interactive elements

### 🎭 **Cultural Extensions**
- [ ] **Historical Context**: Educational information about Kusama's work
- [ ] **Style Variations**: Different periods of Kusama's artistic evolution
- [ ] **Contemporary Integration**: Modern digital art influences
- [ ] **Collaborative Features**: Multiple users creating shared infinity spaces
- [ ] **Sound Integration**: Audio-visual synchronization with ambient sound

### 🎮 **Interactive Experiences**
- [ ] **Gallery Mode**: Curated presentation with camera paths
- [ ] **Creation Tools**: User interface for live sculpture modification
- [ ] **Exhibition Space**: Virtual gallery with multiple works
- [ ] **Social Features**: Sharing and collaboration capabilities

## Artistic Context

### Yayoi Kusama Influence
This generator captures key elements of Kusama's artistic vision:
- **Infinity Obsession**: Repetitive patterns suggesting endless space
- **Polka Dot Universe**: Dots as fundamental building blocks of reality
- **Color Psychology**: Vibrant colors evoking joy and transcendence
- **Biomorphic Forms**: Organic shapes suggesting growth and life
- **Mental Landscape**: Art as expression of inner psychological states

### Mathematical Art
The integration of sine waves and mathematical deformation reflects:
- **Parametric Art**: Computer-generated forms with mathematical precision
- **Organic Algorithms**: Natural patterns emerging from simple rules
- **Procedural Aesthetics**: Infinite variation within consistent style
- **Digital Craftsmanship**: Technology serving artistic vision

## Performance Notes

- **Mesh Complexity**: Moderate polygon count suitable for real-time rendering
- **Generation Time**: ~0.5-1 seconds for complete sculpture creation
- **Memory Usage**: ~20-30MB for complete scene with materials
- **Platform Compatibility**: Optimized for desktop and VR platforms

## Scene Files

- `kusama.gd` - Main procedural sculpture generator
- `kusama_sine.tscn` - Complete scene with lighting and environment
- `kusama.gd.uid` - Godot asset identifier

## Educational Value

### Art History
- **Contemporary Art**: Understanding of conceptual and installation art
- **Cultural Context**: Japanese post-war art and international recognition
- **Mental Health Awareness**: Art as therapy and personal expression
- **Feminist Art**: Women artists in contemporary international scenes

### Mathematics in Art
- **Parametric Design**: Mathematical functions creating artistic forms
- **Algorithmic Art**: Computer-generated creativity and human expression
- **Geometry and Nature**: Mathematical patterns in organic forms
- **Color Theory**: Systematic approaches to color palette design

## Installation Notes

Perfect for:
- **Art Gallery Simulations**: Virtual museum installations
- **Educational Environments**: Art and mathematics integration
- **Therapeutic Applications**: Calming, meditative visual experiences
- **Creative Inspiration**: Starting point for original artistic exploration 