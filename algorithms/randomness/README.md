# Randomness Algorithms

This directory contains 3D visualizations of various randomness and noise generation algorithms used in procedural generation, computer graphics, and simulation.

## Algorithms

### 1. Perlin Noise (`perlinnoise/`)
- **Description**: A gradient noise function that creates natural-looking randomness
- **Inventor**: Ken Perlin (1983)
- **Features**:
  - 3D noise field visualization
  - Adjustable frequency, amplitude, and octaves
  - Real-time parameter changes
  - Smooth interpolation between values
  - Animation capabilities
- **Use Cases**: Terrain generation, texture synthesis, procedural animation

### 2. Simplex Noise (`simplexnoise/`)
- **Description**: An improvement over Perlin noise with lower computational complexity and fewer directional artifacts
- **Inventor**: Ken Perlin (2001)
- **Features**:
  - Improved noise algorithm performance
  - Reduced directional artifacts
  - Configurable persistence
  - Smooth interpolation
  - Comparison capabilities with Perlin noise
- **Use Cases**: High-performance noise generation, 3D terrain, procedural textures

### 3. Value Noise (`valuenoise/`)
- **Description**: Simple interpolation-based noise that interpolates between random values at integer coordinates
- **Features**:
  - Configurable interpolation methods (None, Linear, Smoothstep)
  - Adjustable grid resolution
  - Visual grid lines
  - Real-time parameter changes
  - Bilinear interpolation
- **Use Cases**: Simple procedural generation, educational purposes, grid-based systems

## Technical Details

### Noise Generation Methods
- **Perlin Noise**: Uses gradient vectors and dot products for smooth interpolation
- **Simplex Noise**: Based on simplex grid for better performance and quality
- **Value Noise**: Direct interpolation between random values at grid points

### Interpolation Types
- **None**: Step function (no interpolation)
- **Linear**: Linear interpolation between grid points
- **Smoothstep**: Smooth interpolation using cubic Hermite interpolation

### Performance Characteristics
- **Perlin Noise**: O(n) complexity, good quality
- **Simplex Noise**: O(n) complexity, better performance than Perlin
- **Value Noise**: O(n) complexity, simplest implementation

## Usage

Each algorithm scene can be:
1. **Opened independently** in Godot 4
2. **Integrated into larger projects** as sub-scenes
3. **Customized** by modifying the script parameters
4. **Extended** with additional noise types or visualization methods

## Controls

### Common Controls
- **Frequency**: Controls the scale of the noise pattern
- **Amplitude**: Controls the height/intensity of the noise
- **Regenerate**: Creates new noise with different random seed

### Algorithm-Specific Controls
- **Perlin Noise**: Octaves for fractal noise
- **Simplex Noise**: Persistence for octave contribution
- **Value Noise**: Interpolation method and grid size

## File Structure

```
randomness/
├── perlinnoise/
│   ├── perlinnoise.tscn
│   ├── PerlinNoise.gd
│   └── NoiseVisualizer.gd
├── simplexnoise/
│   ├── simplexnoise.tscn
│   ├── SimplexNoise.gd
│   └── SimplexVisualizer.gd
├── valuenoise/
│   ├── valuenoise.tscn
│   ├── ValueNoise.gd
│   └── ValueNoiseVisualizer.gd
└── README.md
```

## Dependencies

- **Godot 4.4+**: Required for all scenes
- **FastNoiseLite**: Used in Perlin Noise implementation
- **OpenSimplexNoise**: Used in Simplex Noise implementation
- **Standard 3D nodes**: CSGBox3D, Camera3D, DirectionalLight3D

## Future Enhancements

- [ ] Add more noise types (Worley, Cellular, etc.)
- [ ] Implement 3D noise visualization
- [ ] Add texture generation capabilities
- [ ] Create noise combination tools
- [ ] Add export functionality for generated noise

## References

- Perlin, Ken. "An image synthesizer." ACM SIGGRAPH Computer Graphics 19.3 (1985): 287-296.
- Perlin, Ken. "Improving noise." Proceedings of the 29th annual conference on Computer graphics and interactive techniques. 2002.
- Various sources on value noise and interpolation techniques
