# Postprocessing Bloom Scene

## Installation Complete!

This folder now contains a complete Godot 4 postprocessing bloom scene based on the Three.js webgl_postprocessing_bloom example.

### Files Created:
- `postprocessing_bloom.gd` - Main script
- `postprocessing_bloom.tscn` - Scene file  
- `README_postprocessing_bloom.md` - This file

### What This Creates:
- **12 glowing objects** with bright emissive materials that create bloom effects
- **Advanced bloom post-processing** with multi-level glow rendering
- **Floating bright particles** that add additional light sources for bloom
- **Dynamic animations** - objects pulse, rotate, and float
- **Customizable bloom presets** - subtle, dramatic, dreamy, neon styles

### Technical Features:
**Advanced Bloom System:**
- Multi-level glow with configurable intensity and threshold
- HDR bloom with luminance capping
- Different blend modes (softlight, screen, additive)
- Real-time bloom parameter animation

**Emissive Object Shaders:**
- Pulsing emission effects synchronized with time
- Distance-based intensity variations
- Customizable colors and animation speeds
- Metallic and roughness properties for realistic materials

**Particle Bloom Sources:**
- GPU particles with emissive shaders
- Billboard particles that face the camera
- Flickering and size variation effects
- Floating motion with turbulence

### How to Use:

1. **Copy to your Godot project:**
   - Copy `postprocessing_bloom.gd` and `postprocessing_bloom.tscn` to your project

2. **Add to your scene:**
   - Add `postprocessing_bloom.tscn` as a child to your world
   - Position where you want the bloom demonstration

3. **Customize in Inspector:**
   - `bloom_intensity`: Overall bloom strength (default: 1.5)
   - `bloom_threshold`: Brightness threshold for bloom (default: 0.8)
   - `glow_object_count`: Number of glowing objects (default: 12)
   - `animation_speed`: Speed of all animations (default: 1.0)

### Experience:
- Walk around glowing objects and see bloom halos
- Watch dynamic pulsing and color changes
- Experience how bloom affects the overall atmosphere
- See particles creating additional light sources

### Bloom Presets:
Call these functions for different bloom styles:
- `set_bloom_preset("subtle")` - Gentle, refined bloom
- `set_bloom_preset("dramatic")` - High-intensity, cinematic bloom
- `set_bloom_preset("dreamy")` - Soft, ethereal bloom with screen blend
- `set_bloom_preset("neon")` - Bright, electric bloom for neon aesthetics

### Performance Notes:
- Uses Godot's built-in glow/bloom post-processing
- Multi-level bloom for quality while maintaining performance
- Efficient emissive shaders with minimal overdraw
- GPU particles for optimal particle rendering

### Perfect Environments:
- Sci-fi and cyberpunk scenes with neon lighting
- Fantasy environments with magical glowing elements
- Night scenes with bright light sources
- Concert or club environments with stage lighting
- Futuristic interfaces and holographic displays

### Advanced Customization:
**Add dynamic bloom objects:**
```gdscript
add_bloom_object(Vector3(0, 5, 0), Color.RED, 4.0)
```

**Modify bloom settings:**
```gdscript
bloom_environment.glow_intensity = 2.0
bloom_environment.glow_bloom = 0.6
bloom_environment.glow_strength = 1.5
```

**Create custom bloom presets by modifying the set_bloom_preset function**

### Technical Details:
- Uses Environment.glow_enabled for post-processing bloom
- Multi-level glow (levels 1, 2, 3, 5 enabled by default)
- HDR threshold and luminance cap for realistic bloom falloff
- Softlight blend mode for natural bloom integration

### Based on Three.js Example:
This Godot scene is inspired by the Three.js `webgl_postprocessing_bloom` example, adapted with Godot's built-in bloom system and enhanced with dynamic objects and animations.
