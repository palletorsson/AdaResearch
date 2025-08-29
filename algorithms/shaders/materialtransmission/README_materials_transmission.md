# Materials Transmission Scene

## Installation Complete!

This folder now contains a complete Godot 4 materials transmission scene featuring realistic glass, crystal, and transmission effects.

### Files Created:
- `materials_transmission.gd` - Main script
- `materials_transmission.tscn` - Scene file  
- `README_materials_transmission.md` - This file

### What This Creates:
- **8 transmission objects** with three different material types
- **Advanced transmission shader** with refraction, reflection, and fresnel effects
- **Simple glass shader** with rim lighting and transparency
- **Crystal shader** with internal reflections and sparkle effects
- **Dynamic animations** - objects rotate and float
- **Real-time parameter updates** for interactive transmission effects

### Technical Features:
**Advanced Transmission Shader:**
- Realistic refraction using screen-space sampling
- Fresnel-based reflection and transmission
- Depth-based transmission falloff
- Configurable IOR (Index of Refraction)
- Screen texture and depth texture integration

**Simple Glass Shader:**
- Rim lighting for glass-like appearance
- Adjustable transparency and rim power
- Clean, performant glass rendering

**Crystal Shader:**
- Faceted crystal effect with internal reflections
- Dynamic sparkle effects synchronized with time
- Configurable facet strength and sparkle intensity

### How to Use:

1. **Copy to your Godot project:**
   - Copy `materials_transmission.gd` and `materials_transmission.tscn` to your project

2. **Add to your scene:**
   - Add `materials_transmission.tscn` as a child to your world
   - Position where you want the transmission demonstration

3. **Customize in Inspector:**
   - `object_count`: Number of transmission objects (default: 8)
   - `transmission_strength`: Overall transmission intensity (default: 1.0)
   - `refraction_intensity`: Refraction effect strength (default: 0.3)
   - `animation_speed`: Speed of all animations (default: 1.0)

### Experience:
- Walk around glass and crystal objects
- See realistic refraction and transmission effects
- Watch dynamic sparkle and reflection changes
- Experience how transmission affects the overall atmosphere

### Transmission Presets:
Call these functions for different transmission styles:
- `set_transmission_preset("subtle")` - Gentle, refined transmission
- `set_transmission_preset("dramatic")` - High-intensity, cinematic transmission
- `set_transmission_preset("crystal_clear")` - Crystal-clear transmission effects

### Performance Notes:
- Uses advanced screen-space effects for realistic transmission
- Efficient shader-based material system
- Optimized for VR performance
- Screen-space ambient occlusion for depth enhancement

### Perfect Environments:
- Jewelry and gemstone displays
- Architectural glass and windows
- Scientific visualization (lenses, prisms)
- Fantasy environments with magical crystals
- Modern interior design with glass elements

### Advanced Customization:
**Add dynamic transmission objects:**
```gdscript
add_transmission_object(Vector3(0, 5, 0), "advanced")
add_transmission_object(Vector3(2, 5, 0), "crystal")
add_transmission_object(Vector3(-2, 5, 0), "simple")
```

**Modify transmission settings:**
```gdscript
transmission_strength = 0.8
refraction_intensity = 0.4
```

**Create custom transmission presets by modifying the set_transmission_preset function**

### Technical Details:
- Screen-space refraction for realistic light bending
- Fresnel equations for accurate reflection/transmission ratios
- Depth-based transmission falloff for realistic material thickness
- HDR-compatible transmission color tinting

### Based on Three.js Examples:
This Godot scene is inspired by Three.js material transmission examples, adapted with Godot's advanced shader system and enhanced with dynamic objects and animations.
