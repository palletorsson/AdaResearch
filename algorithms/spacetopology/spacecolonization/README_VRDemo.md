# Space Colonization Mold Spore VR Demo

## Overview
This VR demo showcases automatically growing 3D mold spore networks using the Space Colonization Algorithm. The demo features bioluminescent materials, atmospheric lighting, and automated growth cycles.

## Files
- `MoldSporeVRDemo.gd` - Main VR demo script
- `moldsporeVRdemo.tscn` - VR scene configuration with camera
- `MoldSporeVRDemoCamera.gd` - Interactive camera controller
- `SpaceColonizationMoldSpore.gd` - Core algorithm implementation
- `README_VRDemo.md` - This documentation file

## Troubleshooting

### If the demo crashes on startup:

1. **Test the core algorithm first:**
   - Open and run `test_mold_demo.tscn`
   - This will test the basic functionality without VR complexity
   - Check the output console for error messages

2. **Common issues and fixes:**

   **Issue: Missing SpaceColonizationMoldSpore class**
   - Ensure `SpaceColonizationMoldSpore.gd` is in the same directory
   - Check that the class is properly exported in project settings

   **Issue: Signal connection errors**
   - Fixed in latest version with duplicate connection checks
   - Make sure the mold generator is created before connecting signals

   **Issue: Timer conflicts**
   - Fixed in latest version - uses existing scene timer or creates new one
   - Scene includes `AutoGrowthTimer` node that may conflict with code

   **Issue: VR setup problems**
   - Demo includes fallback scene setup for non-VR environments
   - Will use basic lighting if VR environment setup fails

3. **Debug steps:**
   - Run `test_mold_demo.tscn` first to verify core functionality
   - Check console output for specific error messages
   - Ensure all required files are present in the directory
   - Verify Godot project settings include the spacecolonization directory

### Expected behavior:
- Demo should start generating mold networks automatically
- Growth cycles occur every 8 seconds (optimized for fast generation)
- Console output shows generation progress every 25%
- Visual progress indicator appears above the generation space
- Generation is non-blocking and smooth (processes over multiple frames)
- Bioluminescent spore networks appear in the 1x1x1 space

### Performance notes:
- Optimized parameters: 50 auxin sources with 80 max iterations
- Non-blocking generation processes 5 iterations per frame
- Total generation time: ~2-3 seconds
- Visual progress indicator shows real-time generation status
- No UI freezing during generation

## Features
- **Fast Non-Blocking Generation**: Networks generate in ~2-3 seconds without UI freezing
- **Automatic Growth Cycling**: New networks generate every 8 seconds
- **Interactive Camera**: Full WASD + mouse look controls with zoom and focus
- **Visual Progress Indicator**: Real-time glowing sphere shows generation progress
- **VR-Optimized Lighting**: Atmospheric fog and bioluminescent effects
- **Interactive Elements**: Spore body detection and highlighting
- **Animated Growth**: Organic scaling animations for new generations
- **Particle Effects**: Atmospheric spore particles around growth bodies

## Camera Controls
- **WASD** - Move camera around
- **Mouse** - Look around (right-click to capture/release mouse)
- **Mouse Wheel** - Zoom in/out
- **Space/Shift** - Move up/down
- **Ctrl + WASD** - Move faster (sprint)
- **F** - Focus on generation space center
- **Esc** - Release mouse capture

## Manual Controls
- `enable_auto_growth()` - Start automatic cycling
- `disable_auto_growth()` - Stop automatic cycling
- `trigger_manual_growth()` - Generate new network immediately
- `set_growth_cycle_time(seconds)` - Change cycle duration

## VR Integration
The demo is designed for VR but works in standard 3D as well:
- Immersive lighting with multiple colored accent lights
- Atmospheric fog for depth perception
- Glow effects for bioluminescent materials
- Particle systems for enhanced atmosphere

## Algorithm Parameters (Optimized for Speed)
```gdscript
{
    "influence_radius": 0.15,      # How far auxins influence growth
    "kill_distance": 0.05,         # Distance to consume auxins
    "step_size": 0.03,             # Growth step size
    "num_auxin_sources": 50,       # Number of growth targets (reduced)
    "sporulation_probability": 0.025,  # Chance to create spore bodies
    "branching_probability": 0.3,   # Chance to create branches
    "max_iterations": 80           # Maximum growth steps (reduced)
}
```

### Performance Settings
- **iterations_per_frame**: 5 (processes 5 algorithm steps per frame)
- **Total generation time**: ~2-3 seconds
- **Frame rate impact**: Minimal (non-blocking)

## Support
If issues persist:
1. Check Godot version compatibility (4.x required)
2. Verify all dependencies are properly loaded
3. Run the test scene to isolate the problem
4. Check console output for specific error messages 