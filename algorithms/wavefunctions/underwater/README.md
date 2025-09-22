# Underwater Algorithm

This folder contains a comprehensive underwater visualization system with water effects and grid patterns.

## Files

- `see_under_water.tscn` - Main scene demonstrating underwater effects
- `see_under_water.gdshader` - Water surface shader with waves and refraction
- `see_under_water_grid.gdshader` - Grid pattern shader for underwater visibility

## How it works

The underwater system creates realistic underwater environments:

1. **Water Surface**: Animated waves with normal mapping and refraction
2. **Grid Patterns**: Moving grid lines for underwater visibility reference
3. **3D Objects**: Sample geometry to demonstrate underwater effects
4. **Real-time Animation**: Continuous wave motion and pattern changes

## Water Shader Features

The main water shader provides:
- **Wave Animation**: Sine-based wave patterns with configurable speed and strength
- **Normal Mapping**: Surface detail using noise textures
- **Refraction**: Realistic light bending through water
- **Transparency**: Configurable water opacity
- **Underwater Glow**: Subtle emission for depth perception

## Grid Shader Features

The grid shader creates:
- **Static Grid**: Regular grid pattern for spatial reference
- **Moving Lines**: Animated horizontal lines for dynamic effects
- **Color Gradients**: Smooth transitions between top and bottom colors
- **Configurable Density**: Adjustable grid line frequency

## Parameters

### Water Shader
- **Wave Speed**: Animation speed of water waves
- **Wave Strength**: Amplitude of wave distortions
- **Normal Scale**: Intensity of surface detail
- **Water Color**: Base color of the water
- **Transparency**: Water opacity level
- **Refraction Amount**: Light bending strength

### Grid Shader
- **Color Top/Bottom**: Gradient colors for the grid
- **Intensity**: Overall pattern strength
- **Number of Lines**: Grid density
- **Speed**: Animation speed of moving lines
- **Line Height**: Thickness of grid lines

## Scene Components

The scene includes:
- **Water Plane**: Large subdivided quad with water shader
- **Torus Objects**: Sample 3D objects to demonstrate underwater distortion
- **Grid Sphere**: Sphere with grid pattern for visibility reference
- **Noise Texture**: Procedural noise for water surface detail

## Features

- Real-time water animation
- Configurable wave parameters
- Refraction and transparency effects
- Dynamic grid patterns
- Built-in sample geometry
- GPU-accelerated rendering
- Educational underwater visualization

## Technical Implementation

- **Shader Type**: Spatial shaders for 3D objects
- **Normal Mapping**: Surface detail using texture sampling
- **Wave Functions**: Mathematical wave generation
- **UV Manipulation**: Texture coordinate transformations
- **Material Properties**: Comprehensive PBR material setup

## Educational Value

This demonstrates:
- **Water Effects**: How to create realistic water in shaders
- **Normal Mapping**: Adding surface detail to materials
- **Refraction**: Simulating light through transparent media
- **Pattern Generation**: Creating animated grid patterns
- **Shader Parameters**: Configurable shader uniforms

## Usage

Run the `see_under_water.tscn` scene to experience an underwater environment. The water surface will continuously animate with waves, while grid patterns provide spatial reference. The scene demonstrates how shaders can create immersive underwater visual effects.
