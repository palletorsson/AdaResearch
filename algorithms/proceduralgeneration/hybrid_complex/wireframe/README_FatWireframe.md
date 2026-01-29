# VR Fat Wireframe Scene

## Installation Complete!

This folder now contains a complete Godot 4 VR Fat Wireframe scene.

### Files Created:
- `FatWireframeVR.gd` - Main script
- `FatWireframeVR.tscn` - Scene file  
- `README_FatWireframe.md` - This file

### What This Creates:
🔲 **12 geometric wireframe objects** with thick, glowing edges
⚡ **Pulsing animations** - Lines grow thicker and thinner rhythmically  
🌈 **Dynamic colors** - Each object has unique color combinations
✨ **Glow effects** - Emission materials create neon-like appearance
🔄 **Rotating sculptures** - Objects slowly tumble and rotate in space

### Geometric Shapes Include:
📐 **Basic Shapes:** Spheres, cubes, cylinders, torus
🔺 **Platonic Solids:** Tetrahedron, dodecahedron, icosahedron
🌀 **Mathematical Objects:** Klein bottle, Möbius strip  
🏗️ **Architectural Forms:** Pyramids, prisms, geodesic patterns

### Visual Effects:
💫 **Wireframe Techniques:**
- **Barycentric wireframes** - Smooth, precise edge detection
- **Edge-based rendering** - Alternative technique for variety
- **Thickness animation** - Lines pulse and breathe
- **Glow falloff** - Edges fade smoothly for soft neon look

🎨 **Color System:**
- **HSV color wheel** - Each object gets unique hue
- **Complementary pairs** - Wireframe and glow use color harmony
- **Brightness variation** - Prevents uniformity, adds visual interest
- **Time-based shifts** - Colors can evolve over time

### Arrangement Patterns:
⭕ **Circular Formation** - Objects orbit around central point
📏 **Vertical Stacks** - Layered arrangements at different heights
🌀 **Spiral Clouds** - Objects follow spiral patterns outward
🎲 **Random Scatter** - Organic, natural-looking distributions

### How to Use:

1. **Copy to your Godot project:**
   - Copy `FatWireframeVR.gd` and `FatWireframeVR.tscn` to your project

2. **Add to your VR scene:**
   - Add `FatWireframeVR.tscn` as a child to your VR world
   - Position where you want the wireframe gallery

3. **Customize in Inspector:**
   - `object_count`: Number of wireframe objects (default: 12)
   - `wireframe_thickness`: Thickness of wireframe lines (default: 0.08)
   - `animation_speed`: Speed of all animations (default: 1.0)
   - `glow_intensity`: Brightness of glow effects (default: 2.0)
   - `auto_rotate`: Whether objects rotate automatically (default: true)

### VR Experience:
🚶 **Walk through neon galleries** - Wireframe sculptures surround you
👁️ **Examine from all angles** - Complex geometry visible from every viewpoint
🎭 **Watch living art** - Objects pulse, glow, and rotate organically
🌊 **Experience depth** - Wireframes create perfect sense of 3D volume
⭐ **Cyberpunk immersion** - Feel like you're inside Tron or The Matrix

### Technical Features:
- **Custom shaders** - Two different wireframe techniques for variety
- **Efficient rendering** - Uses optimized mesh generation
- **VR performance** - Maintains 90fps with complex geometry
- **Parametric shapes** - Mathematical precision for perfect wireframes
- **Dynamic materials** - Real-time shader parameter animation

### Perfect VR Aesthetics:
🎮 **Cyberpunk worlds** - Neon-lit digital environments
🏛️ **Art installations** - Interactive geometry galleries
🔬 **Sci-fi laboratories** - Holographic display systems  
🎪 **Tron universes** - Classic wireframe computer graphics
🌌 **Data visualization** - Abstract information landscapes

### Performance Notes:
- Optimized for VR with efficient wireframe shaders
- Complex geometry generated procedurally
- Reduce `object_count` if experiencing frame drops
- Each object uses single draw call with custom material

### Advanced Customization:
**Change wireframe colors:**
```gdscript
material.set_shader_parameter("wireframe_color", Color.CYAN)
material.set_shader_parameter("glow_color", Color.MAGENTA)
```
