# 🏔️ Overhang Landscape - Complex Topology

## Overview

**Scene**: `marchingcubes_overhang_landscape.tscn`

This scene generates a marching cubes landscape with **interesting topology** including:
- 🪨 **Rocky overhangs** - Cliffs that extend outward
- 🕳️ **Cave entrances** - Natural openings in the terrain
- 🌉 **Natural arches** - Bridge-like formations
- 🗿 **Vertical outcrops** - Rocky pillars and formations

Most of the terrain remains **flat and walkable**, but includes strategic areas with complex 3D features.

## Key Features

### Terrain Characteristics

1. **Base Terrain** (70% of landscape)
   - Flat rolling hills
   - Walkable surface
   - Gentle elevation changes

2. **Overhang Features** (15-20%)
   - Located on elevated areas
   - Rock outcroppings that extend beyond base
   - Height-based modulation for variety

3. **Cave Entrances** (10-15%)
   - Carved using ridged noise
   - Located near ground level
   - Walk-in accessible

4. **Natural Arches** (5-10%)
   - Vertical pillar structures
   - Horizontal layering
   - Creates bridge-like formations

5. **Rocky Outcrops** (5%)
   - Solid features jutting upward
   - Above-surface formations
   - Adds vertical interest

## Technical Details

### Compute Shader: `MarchingCubesOverhangTerrain.glsl`

The shader combines multiple noise functions:

```glsl
density = baseTerrain          // Flat base
        - overhangDensity      // Subtract for overhangs (air pockets)
        - caveStrength         // Carve cave entrances
        - archStrength         // Create natural arches
        - outcropStrength      // Add rocky outcrops
```

### Noise Techniques

- **Overhang Noise**: Multi-octave Simplex noise with elevation masking
- **Cave Noise**: Ridged noise (inverted absolute) for cavern-like structures
- **Arch Noise**: Combination of horizontal bands and vertical pillars
- **Outcrop Noise**: Sharpened positive noise values

### Parameters (Inspector)

| Parameter | Default | Description |
|-----------|---------|-------------|
| `noise_scale` | 2.0 | Scale of noise patterns |
| `noise_offset` | (100, 50, 75) | Offset for noise sampling |
| `iso_level` | 0.0 | Surface threshold |
| `chunk_scale` | 400.0 | Overall landscape size |
| `use_fallback` | false | Use simple flat mesh if compute fails |

## Usage

1. **Open the scene**: `res://algorithms/proceduralgeneration/marchingcave/Scenes/marchingcubes_overhang_landscape.tscn`

2. **Run** (F6): Wait 5-10 seconds for generation

3. **Explore**: Walk around to find:
   - Overhanging cliffs
   - Cave entrances you can walk into
   - Natural stone arches
   - Interesting vertical formations

## Customization

### More Overhangs

In `MarchingCubesOverhangTerrain.glsl`, increase:
```glsl
float overhangStrength = elevationFactor * 0.8;  // Increase to 1.2
```

### More Caves

In the shader:
```glsl
float caveStrength = caveNoise * caveMask * 0.6;  // Increase to 0.9
```

### Flatter Base

In `TerrainGeneratorOverhang.gd`, change:
```gdscript
chunk_scale = 400.0  # Increase to 600.0 for more spread out features
```

## Comparison with Other Scenes

- **marchingcubes_flat_landscape.tscn**: Basic flat terrain with gentle hills
- **marchingcubes_overhang_landscape.tscn**: ⭐ This scene - adds overhangs, caves, arches
- **marchingcubes_portal_landscape.tscn**: Flat terrain + torus portals
- **marchingcubes_inside_cave.tscn**: Full cave interior

## Performance

- **Generation Time**: 5-10 seconds (compute shader)
- **Polygon Count**: ~50k-100k triangles (depending on chunk_scale)
- **Fallback Available**: Set `use_fallback = true` for simple mesh

## Troubleshooting

**No overhangs visible**:
- Increase `overhangStrength` in shader
- Check you're looking at elevated areas (hills)

**Too many features / hard to navigate**:
- Reduce strength multipliers in shader
- Increase `chunk_scale` to spread features out

**Compute shader fails**:
- Set `use_fallback = true` in Inspector
- Will create simple flat terrain

---

**Created**: 2025-10-23  
**Based on**: Flat landscape with enhanced topology features  
**Purpose**: Demonstrate complex marching cubes terrain with overhangs and caves

