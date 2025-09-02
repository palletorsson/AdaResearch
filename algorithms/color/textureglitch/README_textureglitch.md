# VR Colored Lines Scene

## Installation Complete!

This folder now contains a complete Godot 4 VR Colored Lines scene.

### Files Created:
- `ColoredLinesVR.gd` - Main script
- `ColoredLinesVR.tscn` - Scene file  
- `README_ColoredLines.md` - This file

### What This Creates:
🌈 **25 dynamic colored lines** weaving through 3D space in complex patterns
⚡ **Flowing colors** - Rainbow gradients that move along each line
✨ **Pulsing glow effects** - Lines pulse and breathe with energy
🎨 **Unique patterns** - 5 different mathematical curve types
🌌 **Neon atmosphere** - Dark space with volumetric fog for glow effects

### Line Pattern Types:
🌀 **Spiral Helixes** - Corkscrewing through space with varying radius
〰️ **Sine Waves** - Flowing wave patterns in multiple directions  
🎲 **Random Walks** - Organic, noise-based curves
⭕ **Circular Orbits** - Elliptical and circular orbital patterns
🧬 **DNA Double Helix** - Intertwining twin spirals
📐 **Mathematical Art** - Lissajous curves and torus knots (optional)

### Visual Effects:
🔥 **Color Flow:**
- Colors flow along lines like liquid light
- Rainbow effects cycle through hue spectrum  
- Each line has unique start/end colors
- Smooth color transitions create mesmerizing patterns

💫 **Dynamic Properties:**
- **Thickness variation** - Lines pulse thicker and thinner
- **Glow intensity** - Emission strength varies over time
- **Path deformation** - Lines gently bend and flex
- **Individual timing** - Each line animates at slightly different speeds

### How to Use:

1. **Copy to your Godot project:**
   - Copy `ColoredLinesVR.gd` and `ColoredLinesVR.tscn` to your project

2. **Add to your VR scene:**
   - Add `ColoredLinesVR.tscn` as a child to your VR world
   - Position where you want the neon light show

3. **Customize in Inspector:**
   - `line_count`: Number of colored lines (default: 25)
   - `points_per_line`: Detail level of each line (default: 100)
   - `animation_speed`: Speed of all animations (default: 1.0)
   - `line_length`: Length scale for wave patterns (default: 15.0)
   - `flow_speed`: Speed of color flow along lines (default: 2.0)

### VR Experience:
🚶 **Walk through neon sculptures** - Lines form living art installations around you
👀 **Watch from all angles** - Complex 3D curves look different from every viewpoint
🎭 **Observe color symphonies** - Colors flow and pulse in harmony
🌊 **Experience motion** - Lines gently deform creating organic, breathing effects
⭐ **Immersive scale** - Lines stretch above, below, and around you

### Performance:
- **VR optimized** - Efficient tube geometry generation
- **Smooth animations** - No sudden movements that could cause motion sickness
- **Scalable complexity** - Reduce line_count or points_per_line if needed
- **GPU shaders** - All color and glow effects calculated on GPU

### Perfect VR Environments:
🎪 **Tron-style worlds** - Futuristic neon environments
🎨 **Art galleries** - Living light sculptures  
🌌 **Space stations** - Energy conduits and data streams
🏛️ **Mystical realms** - Magical energy ley lines
💃 **Music visualization** - Abstract flowing forms (could sync to audio)

### Advanced Customization:
**Change line colors:**
```gdscript
material.set_shader_parameter("color_start", Color.RED)
material.set_shader_parameter("color_end", Color.BLUE) 
```

**Modify line patterns by editing the path generation functions**

**Add audio reactivity by modifying shader parameters based on audio input**

This scene transforms your VR space into a living gallery of flowing light sculptures!
