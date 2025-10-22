# Flat Landscape with Caves

This is a variant of the marching cubes cave system that generates a **flat landscape with occasional caves** instead of an underground cave network.

## Files

- **Scene**: `Scenes/marchingcubes_flat_landscape.tscn`
- **Script**: `Scripts/TerrainGeneratorFlat.gd`
- **Shader**: `Compute/MarchingCubesFlat.glsl`

## How It Works

### Original Cave System
The original `marchingcubes_cave.tscn` creates an underground cave by:
- Using 3D noise to create organic cave tunnels
- Using a vertical gradient that makes lower areas solid and upper areas hollow
- Result: Dense cave network

### Flat Landscape with Caves
The new `marchingcubes_flat_landscape.tscn` creates a surface landscape by:
- Starting with terrain that is solid below and air above (inverted from caves)
- Adding rolling hills using 2D noise on the surface
- Subtracting 3D noise to carve out occasional cave pockets
- Result: Mostly flat/hilly terrain with occasional underground caves

## Key Differences in the Shader

The density function was modified in `MarchingCubesFlat.glsl`:

```glsl
// Surface variation (rolling hills)
float surfaceNoise = 0;
surfaceNoise += snoise(vec3(worldPos.x * 0.01, 0, worldPos.z * 0.01)) * 15.0;
surfaceNoise += snoise(vec3(worldPos.x * 0.03, 0, worldPos.z * 0.03)) * 5.0;

// Create flat terrain with caves carved out
float surfaceHeight = surfaceNoise;
float terrainDensity = (surfaceHeight - worldPos.y) / 30.0;

// Subtract cave noise to carve out caves
float density = terrainDensity - (caveNoise * 0.4);
```

## Adjusting Parameters in the Scene

You can tweak these parameters in the Inspector when selecting the `Terrain` node:

### `noise_scale` (default: 2.0)
- **Lower values (0.5 - 1.5)**: Larger, more spread-out caves
- **Higher values (3.0 - 5.0)**: Smaller, more frequent caves
- **Recommended**: 1.5 - 3.0

### `noise_offset` (default: Vector3(100, 50, 75))
- Changes which part of the noise space is sampled
- Modify this to get a different random landscape
- Any values work

### `iso_level` (default: 0.0)
- **Negative values (-0.3 to 0.0)**: More caves, larger openings
- **Positive values (0.0 to 0.3)**: Fewer caves, smaller openings
- **Recommended**: -0.2 to 0.2

### `chunk_scale` (default: 300.0)
- The size of the generated terrain chunk
- **Smaller (100-200)**: Smaller area, more detail
- **Larger (500-1000)**: Larger area, less dense
- **Recommended**: 200 - 500

## Modifying Cave Frequency in the Shader

To adjust how many caves appear, edit `MarchingCubesFlat.glsl` line ~198:

```glsl
// Current: moderate caves
float density = terrainDensity - (caveNoise * 0.4);

// More caves (bigger openings)
float density = terrainDensity - (caveNoise * 0.6);

// Fewer caves (smaller openings)
float density = terrainDensity - (caveNoise * 0.2);

// Almost no caves (rare small pockets)
float density = terrainDensity - (caveNoise * 0.1);
```

## Modifying Surface Hills

To adjust the terrain surface, edit `MarchingCubesFlat.glsl` lines ~188-190:

```glsl
// Current: gentle rolling hills
float surfaceNoise = 0;
surfaceNoise += snoise(vec3(worldPos.x * 0.01, 0, worldPos.z * 0.01)) * 15.0;
surfaceNoise += snoise(vec3(worldPos.x * 0.03, 0, worldPos.z * 0.03)) * 5.0;

// Flatter terrain
surfaceNoise += snoise(vec3(worldPos.x * 0.01, 0, worldPos.z * 0.01)) * 5.0;
surfaceNoise += snoise(vec3(worldPos.x * 0.03, 0, worldPos.z * 0.03)) * 2.0;

// More dramatic hills/mountains
surfaceNoise += snoise(vec3(worldPos.x * 0.008, 0, worldPos.z * 0.008)) * 40.0;
surfaceNoise += snoise(vec3(worldPos.x * 0.02, 0, worldPos.z * 0.02)) * 15.0;

// Completely flat surface
float surfaceNoise = 0;  // No variation
```

## Lighting

The scene uses outdoor lighting suitable for a landscape:
- Bright directional sun light
- Sky-blue ambient lighting
- Light fog for atmospheric depth
- No volumetric fog (unlike the cave scene)

## Comparison

| Feature | Cave Scene | Flat Landscape Scene |
|---------|-----------|---------------------|
| Density Logic | Inverted (hollow inside) | Normal (solid below) |
| Surface | No defined surface | Rolling hills |
| Caves | Entire structure is cave | Occasional pockets |
| Lighting | Dark, atmospheric torches | Bright outdoor sun |
| Fog | Dense volumetric fog | Light atmospheric fog |
| Best for | Exploration, dungeon crawling | Open world, mining |

## Performance

Both scenes use the same marching cubes algorithm and have similar performance characteristics. The flat landscape may actually generate slightly fewer triangles in some cases since it has more empty air space.

## Tips

1. **Start with the defaults** - They provide a good balance of caves and solid terrain
2. **Adjust `iso_level` first** - This has the most immediate impact on cave frequency
3. **Use `noise_offset`** - Generate different landscapes without changing parameters
4. **Edit the shader** - For more control over cave distribution and terrain shape
5. **Check the fallback** - If compute shaders fail, a simple hilly plane is created instead

Enjoy your procedurally generated landscape! 🏞️

