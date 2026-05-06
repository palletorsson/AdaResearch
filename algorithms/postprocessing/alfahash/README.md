# Alpha Hash

A post-processing artifact that demonstrates alpha hashing (dithered transparency) as an alternative to traditional alpha blending. Geometric objects float in an ethereal, volumetric-fog environment, fading in and out using screen-space dither patterns and stipple noise rather than conventional transparency.

## Concept Taught

**Alpha hashing and order-independent transparency** -- how dithered discard patterns can approximate transparency without the sorting problems of alpha blending. Traditional alpha blending requires back-to-front rendering order, which is expensive and error-prone with overlapping translucent surfaces. Alpha hashing instead discards fragments based on a noise threshold, producing a stippled look that is order-independent. This teaches the tradeoff between visual smoothness and rendering correctness.

## How It Works

1. **Alpha Hash Shader**: Computes an animated alpha value per fragment using a sine-wave pulse and position-based variation. A screen-space dither threshold is generated from a hash function. If the alpha falls below the dither threshold, the fragment is discarded. A noise layer adds organic variation. Edge glow is calculated from the dot product of surface normal and view direction.

2. **Stipple Shader**: An alternative approach that creates a world-space stipple pattern. A hash function generates a stipple noise value; fragments above the animated density threshold are discarded. Distance-based fading adds depth perception.

3. **Scene Composition**: 15 objects (configurable) are arranged in a layered spiral using 8 different geometries -- sphere, box, cylinder, torus, octahedron, truncated pyramid, star, and crystal cluster. The last four are custom `ArrayMesh` geometries built procedurally.

4. **Animation**: Tween-based animations control alpha wave cycling, floating motion, gentle rotation, and phase-in/phase-out visibility toggling for every fourth object.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `object_count` | int | 15 | Number of alpha-hashed objects |
| `transparency_animation_speed` | float | 1.0 | Speed of transparency wave animations |
| `dither_scale` | float | 1.0 | Base scale of the dither/stipple pattern |
| `ghost_intensity` | float | 0.7 | Base alpha/density level |

## Features

- Two shader approaches: alpha hash (screen-space dither) and stipple (world-space pattern)
- Eight geometry types including four custom ArrayMesh shapes (octahedron, truncated pyramid, star, crystal cluster)
- Volumetric fog environment for ethereal atmosphere
- Complementary color pairing per object based on hue wheel
- Position-based transparency waves that flow through the scene
- Tween-driven floating, rotation, and phase animations
- Dynamic dither scale modulation over time

## Files

| File | Description |
|------|-------------|
| `alphahash.gd` | Complete scene with dual shaders, procedural meshes, animations, and fog environment |
