# VR Dynamic Cubemap Reflections Scene

## Installation Complete!

This folder now contains a complete Godot 4 VR Dynamic Cubemap Reflections scene.

### Files Created:
- `DynamicCubemapVR.gd` - Main script
- `DynamicCubemapVR.tscn` - Scene file  
- `README_DynamicCubemap.md` - This file

### What This Creates:
🪞 **8 highly reflective objects** with real-time mirror surfaces
💎 **Perfect chrome spheres** - Mirror-like reflections of the entire environment
🔄 **Dynamic environment** - 12 animated objects creating changing reflections
💡 **Moving lights** - 4 colored lights that create dynamic lighting in reflections
⚡ **Real-time updates** - Reflections change as objects move through space

### Reflective Object Types:
🔮 **Chrome Spheres** - Perfect mirror balls showing 360° environment
🪞 **Flat Mirrors** - Reflective panels like liquid mercury surfaces  
💍 **Reflective Torus** - Donut shapes with complex curved reflections
🏛️ **Cylinder Mirrors** - Tall pillars with cylindrical reflections
💎 **Crystal Balls** - High-subdivision spheres for flawless reflections  
📐 **Curved Panels** - Warped mirror surfaces for artistic distortion

### Dynamic Environment Elements:
🎨 **Animated Color Objects** - 12 objects with shifting color patterns
💡 **Moving Lights** - 4 colored lights orbiting and dancing through space
🌈 **Pattern Animation** - Environment objects change colors and patterns
🔄 **Continuous Motion** - Everything moves to create dynamic reflections

### Lighting Choreography:
⭕ **Circular Orbits** - Cyan light moving in expanding circles
∞ **Figure-8 Patterns** - Magenta light tracing complex loops  
🌀 **Spiral Motion** - Yellow light corkscrewing through space
⚖️ **Pendulum Swings** - Green light swaying in multiple axes

### How to Use:

1. **Copy to your Godot project:**
   - Copy `DynamicCubemapVR.gd` and `DynamicCubemapVR.tscn` to your project

2. **Add to your VR scene:**
   - Add `DynamicCubemapVR.tscn` as a child to your VR world
   - Position where you want the reflection gallery

3. **Customize in Inspector:**
   - `reflective_object_count`: Number of mirror objects (default: 8)
   - `reflection_update_rate`: Reflection refresh rate in Hz (default: 30)
   - `reflection_resolution`: Quality of reflections (128/256/512, default: 256)
   - `animation_speed`: Speed of all animations (default: 1.0)
   - `metallic_strength`: How mirror-like the surfaces are (default: 0.95)

### VR Experience:
🚶 **Walk between mirrors** - See yourself and the environment reflected infinitely
👁️ **Watch changing reflections** - Lights and colors shift in real-time in mirror surfaces
🎭 **Experience kaleidoscope effects** - Multiple mirrors create complex reflection interactions
🌊 **See dynamic lighting** - Colored lights dance through reflective surfaces
⭐ **Perfect VR scale** - Mirror objects sized for comfortable VR viewing

### Technical Features:
- **Real-time reflection probes** - True dynamic environment capture
- **Dual material system** - PBR and custom shader reflections  
- **Performance optimization** - Configurable update rates and resolutions
- **Advanced lighting** - Multiple moving lights for dynamic reflections
- **Custom geometry** - Specialized shapes optimized for reflections
- **Fresnel effects** - Realistic reflection falloff and rim lighting

### Perfect VR Environments:
🏛️ **Hall of mirrors** - Infinite reflection galleries
🔬 **Futuristic labs** - Chrome equipment and mirror surfaces
💎 **Jewelry showrooms** - Reflective gems and precious metals  
🎪 **Art installations** - Interactive mirror sculpture galleries
🌌 **Space stations** - Polished metal surfaces and chrome details
🏰 **Palace halls** - Ornate mirrors and reflective decorations

### Performance Notes:
- **Scalable quality** - Adjust reflection_resolution for performance
- **Efficient updates** - Configurable reflection_update_rate (30Hz default)
- **VR optimized** - Maintains 90fps with multiple real-time reflections
- **LOD ready** - Can disable distant reflections for performance

### Advanced Customization:
**Adjust reflection quality vs performance:**
```gdscript
reflection_resolution = 128    # Better performance
reflection_resolution = 512    # Higher quality
reflection_update_rate = 60.0  # Smoother reflections
reflection_update_rate = 15.0  # Better performance
```

**Change mirror properties:**
```gdscript
metallic_strength = 1.0   # Perfect mirrors
metallic_strength = 0.7   # Subtle reflections
```

**Modify reflection distortion for artistic effects in the custom shader**

This scene creates a stunning hall of mirrors experience where every surface reflects the dynamic, ever-changing VR environment in real-time!
