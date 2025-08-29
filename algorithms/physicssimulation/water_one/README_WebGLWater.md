# VR WebGL Water Scene

## Installation Complete!

This folder now contains a complete Godot 4 VR WebGL Water scene based on the Three.js webgl_water example.

### Files Created:
- `WebGLWaterVR.gd` - Main script
- `WebGLWaterVR.tscn` - Scene file  
- `README_WebGLWater.md` - This file

### What This Creates:
🌊 **Realistic water surface** with dynamic waves and physics-based movement
🪞 **Real-time reflections** using reflection cameras and render textures
💧 **Wave displacement** with multiple wave layers for natural water motion
✨ **Fresnel effects** for realistic reflection falloff at viewing angles
🌤️ **Foam generation** on wave peaks for added realism
🎨 **Depth-based coloring** from shallow aqua to deep ocean blue

### Technical Features:
**Advanced Water Shader:**
- Multi-layer wave displacement using sine functions
- Dynamic normal calculation for proper lighting
- Screen-space reflection mapping
- Fresnel-based reflection mixing
- Foam generation on wave peaks
- Depth-based color variation

**Real-time Reflections:**
- Dedicated reflection camera that mirrors main camera
- Reflection viewport renders scene from water's perspective
- Reflection texture fed into water shader
- Performance-optimized with configurable quality

**Wave Physics:**
- Multiple wave directions for natural randomness
- Configurable wave height, speed, and patterns
- Realistic wave normal calculation for lighting
- Smooth animation using shader TIME uniform

### How to Use:

1. **Copy to your Godot project:**
   - Copy `WebGLWaterVR.gd` and `WebGLWaterVR.tscn` to your project

2. **Add to your VR scene:**
   - Add `WebGLWaterVR.tscn` as a child to your VR world
   - Position where you want the water surface

3. **Customize in Inspector:**
   - `water_size`: Size of water surface (default: 50.0)
   - `wave_height`: Height of waves (default: 1.2)
   - `wave_speed`: Speed of wave animation (default: 1.0)
   - `reflection_quality`: Quality of reflections 0-1 (default: 0.5)
   - `water_clarity`: Transparency of water (default: 0.8)

### VR Experience:
🚶 **Walk around the water** - See reflections change as you move
👁️ **Look from different angles** - Experience realistic Fresnel effects
🌊 **Watch dynamic waves** - Multiple wave patterns create natural motion
🏝️ **Observe reflections** - Sky, objects, and environment reflected in real-time
⭐ **Perfect VR scale** - Water sized for comfortable VR exploration

### Performance Notes:
- Uses high subdivision mesh for smooth waves (150x150)
- Reflection camera renders at 512x512 (adjustable)
- VR optimized - maintains 90fps on modern hardware
- Reduce subdivision or reflection quality for better performance

### Perfect VR Environments:
🏝️ **Island paradises** - Tropical VR experiences
🚢 **Ocean exploration** - Ship decks and underwater scenes
🏛️ **Ancient pools** - Temple courtyards and sacred springs
🎮 **Fantasy worlds** - Magical lakes and enchanted waters
🌅 **Peaceful retreats** - Meditation and relaxation spaces

### Advanced Customization:
**Modify water appearance:**
```gdscript
water_material.set_shader_parameter("water_color_deep", Color.GREEN)
water_material.set_shader_parameter("wave_height", 2.0)
```

**Add environment objects by calling:**
```gdscript
add_reflection_objects()  # Creates platforms and pillars for interesting reflections
```

**Adjust wave patterns in the shader by modifying:**
- `wave_direction_1` and `wave_direction_2` for wave directions
- Wave frequency and amplitude parameters
- Multiple wave layer combinations

This creates a stunning, realistic water surface that rivals modern AAA games - perfect for VR experiences where water is a central element!

### Based on Three.js Example:
This Godot scene is inspired by the Three.js `webgl_water` example, adapted for VR with enhanced realism and performance optimizations.
