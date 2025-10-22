# Marching Cubes Variants 🎨

This directory contains **four different variants** of procedurally generated geometry using marching cubes:

## 1. 🏔️ Original Cave System
**File**: `Scenes/marchingcubes_cave.tscn`

Dense underground cave network with organic tunnels and chambers.

### Features:
- Inverted density (hollow inside, solid outside)
- Dark atmospheric lighting with torches and bioluminescent lights
- Dense volumetric fog
- Perfect for dungeon exploration

### Parameters:
```gdscript
noise_scale = 3.5
noise_offset = Vector3(200, -120, 150)
iso_level = 0.85
chunk_scale = 300.0
```

---

## 2. 🌄 Flat Landscape with Caves
**File**: `Scenes/marchingcubes_flat_landscape.tscn`

Open landscape with rolling hills and occasional underground cave pockets.

### Features:
- Normal density (solid below surface, air above)
- Bright outdoor lighting with sun
- Light atmospheric fog
- Perfect for open-world exploration and mining

### How It Works:
The shader creates a flat terrain surface and then **subtracts 3D noise** to carve out cave pockets:

```glsl
// Surface with rolling hills
float surfaceHeight = surfaceNoise;
float terrainDensity = (surfaceHeight - worldPos.y) / 30.0;

// Carve out caves
float density = terrainDensity - (caveNoise * 0.4);
```

### Parameters:
```gdscript
noise_scale = 2.0
noise_offset = Vector3(100, 50, 75)
iso_level = 0.0
chunk_scale = 300.0
```

**Tip**: Adjust `iso_level` to control cave frequency:
- Negative (-0.2): More caves
- Positive (0.2): Fewer caves

---

## 3. 🎭 Torus Sculpture (Topology 3)
**File**: `Scenes/marchingcubes_torus_sculpture.tscn`

An organic, twisted torus sculpture with complex topology - perfect for art installations!

### Features:
- Uses torus SDF (Signed Distance Function)
- Organic noise deformation
- Twisting effect around the ring
- Bulges and constrictions
- Gallery-style lighting (spotlights + accent lights)

### How It Works:
The shader creates a mathematical torus shape and adds multiple layers of organic deformation:

```glsl
// Torus SDF
float majorRadius = 50.0;  // Ring radius
float minorRadius = 20.0;   // Tube thickness
float distFromYAxis = length(vec2(worldPos.x, worldPos.z));
vec2 torusPoint = vec2(distFromYAxis - majorRadius, worldPos.y);
float torusDist = length(torusPoint) - minorRadius;

// Add organic deformations
float sculptureShape = torusDist + deformation * 8.0 + twist + bulge;
```

### Parameters:
```gdscript
noise_scale = 2.0
noise_offset = Vector3(50, 25, 100)
iso_level = 0.0
chunk_scale = 200.0
```

**Customization**: Edit the shader to change:
- `majorRadius`: Size of the donut
- `minorRadius`: Thickness of the tube
- `twist = sin(angle * 3.0 + worldPos.y * 0.1) * 3.0`: Twisting intensity
- `bulge = sin(angle * 5.0) * cos(worldPos.y * 0.15) * 4.0`: Bulge frequency

---

## 4. 🕯️ Inside Cave (First-Person)
**File**: `Scenes/marchingcubes_inside_cave.tscn`

Optimized cave scene designed for first-person exploration - you start **inside** the cave!

### Features:
- Same cave generation as original
- **Camera positioned inside the cave** at spawn
- Torch light attached to camera (player light)
- Multiple atmospheric light sources
- Dense volumetric fog for immersion
- Perfect for first-person cave exploration

### Differences from Original:
- Camera starts at `(0, 5, 15)` looking slightly down
- Player torch attached to camera (follows your view)
- Additional torch and bio-luminescent lights
- Extra spot lights for dramatic lighting
- Tuned fog settings for better visibility while maintaining atmosphere

### Parameters:
```gdscript
noise_scale = 3.8
noise_offset = Vector3(150, -100, 200)
iso_level = 0.88
chunk_scale = 280.0
```

---

## Comparison Table

| Variant | Use Case | Density | Lighting | Topology |
|---------|----------|---------|----------|----------|
| **Original Cave** | External view of cave system | Inverted | Dark, torches | Complex tunnels |
| **Flat Landscape** | Open world with caves | Normal | Bright sun | Flat with pockets |
| **Torus Sculpture** | Art installation | Inverted | Gallery spots | Donut shape |
| **Inside Cave** | First-person exploration | Inverted | Dark + player torch | Complex tunnels |

---

## Technical Details

### All Variants Use:
- **Marching Cubes** algorithm for mesh generation
- **Compute Shaders** (GLSL) for GPU-accelerated generation
- **Simplex Noise** for organic shapes
- **Fallback meshes** if compute shaders fail

### Shader Files:
1. `Compute/MarchingCubes.glsl` - Original cave
2. `Compute/MarchingCubesFlat.glsl` - Flat landscape
3. `Compute/MarchingCubesTorus.glsl` - Torus sculpture

### Script Files:
1. `Scripts/TerrainGenerator.gd` - Original cave generator
2. `Scripts/TerrainGeneratorFlat.gd` - Flat landscape generator
3. `Scripts/TerrainGeneratorTorus.gd` - Torus sculpture generator

---

## Performance Tips

1. **Lower `chunk_scale`** (200-250) = Smaller area, better performance
2. **Higher `chunk_scale`** (400-500) = Larger area, more triangles
3. **Resolution is fixed** at 8x8x8 work groups = 64x64x64 voxels
4. All variants generate similar triangle counts for similar volumes

---

## Creating Your Own Variant

To create a custom variant:

1. **Copy a shader** (e.g., `MarchingCubesTorus.glsl`)
2. **Modify the `evaluate()` function** to change the density calculation
3. **Copy a script** (e.g., `TerrainGeneratorTorus.gd`)
4. **Update the shader path** in `init_compute()`
5. **Create a new scene** with appropriate lighting
6. **Experiment with parameters!**

### Density Function Tips:

```glsl
// Sphere
float density = radius - length(worldPos);

// Box
float density = boxSize - max(max(abs(worldPos.x), abs(worldPos.y)), abs(worldPos.z));

// Cylinder
float density = radius - length(vec2(worldPos.x, worldPos.z));

// Add noise for organic feel
density += snoise(worldPos * scale) * amplitude;
```

---

## Common Parameters Explained

### `noise_scale`
- Controls the frequency of the noise
- Lower = larger features
- Higher = smaller, more detailed features
- Range: 0.5 - 5.0

### `noise_offset`
- Changes which part of noise space is sampled
- Acts like a random seed
- Any values work
- Change to get a completely different shape

### `iso_level`
- The density threshold for the surface
- Determines where solid becomes air
- Negative = expand solid areas
- Positive = shrink solid areas
- Range: -0.5 to 1.5

### `chunk_scale`
- The world-space size of the generated chunk
- Larger = bigger area but same detail
- Smaller = smaller area but denser detail
- Range: 100 - 1000

---

## Troubleshooting

### "No triangles generated"
- Your `iso_level` might be too extreme
- Try values closer to 0.0
- Check that `chunk_scale` isn't too large

### "Using fallback mesh"
- Compute shaders failed (normal on some systems)
- A simple procedural mesh is created instead
- Still looks good, just simpler geometry

### "Low FPS"
- Reduce `chunk_scale`
- The marching cubes algorithm is GPU-intensive
- Consider using the fallback mesh for testing

### Shader won't compile
- Make sure `.glsl` files are in `Compute/` folder
- Check that Godot imports them as `RDShaderFile`
- Look for syntax errors in shader code

---

## License

The marching cubes algorithm implementation is based on Paul Bourke's tables and is used under the MIT License. See `MITLicenseForMarchingCubes.txt` for details.

---

## Credits

- **Marching Cubes Algorithm**: Paul Bourke
- **Simplex Noise**: Ian McEwan, Ashima Arts (MIT License)
- **Implementation**: AdaResearch VR Project

---

Enjoy creating procedural worlds! 🌍✨

