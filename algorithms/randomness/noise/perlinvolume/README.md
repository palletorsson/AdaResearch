# Perlin Volume

A volumetric animated Perlin noise renderer that fills a cube with colorful, flowing noise patterns using ray marching. The main shader produces vivid, semi-transparent volumetric shapes with configurable lighting, color ramps, and noise warping. A companion fog volume shader provides atmospheric depth using Godot 4's native fog system.

This artifact teaches how **Perlin/simplex noise** can be visualized as a volumetric field rather than a flat texture. By ray-marching through 3D noise, the viewer sees how coherent noise fills space -- with smooth gradients, organic shapes, and layered detail from multiple octaves.

## How It Works

1. **Ray Marching (Main Shader)**: The spatial shader computes a ray from the camera through each pixel of the volume cube. It intersects the ray with the unit cube boundaries, then steps through the volume in `march_steps` increments. At each step, it samples the noise field and accumulates color and opacity using front-to-back blending.

2. **Noise Field**: Each sample point evaluates 3D simplex noise, optionally enhanced with FBM (controlled by `fbm_detail`). Noise warping (`warp_amount`) offsets the sample coordinates by additional noise values to create flowing, organic distortion patterns. Time animation scrolls the noise along Z.

3. **Lighting**: A simple forward-scattering model uses the Henyey-Greenstein phase function to brighten areas where the view direction aligns with the light direction. A rim term adds glow at noise gradient boundaries. The `light_strength` and `phase_g` uniforms control the intensity and directionality of the scattering.

4. **Color Ramp**: Three configurable colors (`color1`, `color2`, `color3`) are interpolated based on the noise value at each sample. An optional gradient texture can replace the built-in ramp.

5. **Edge Softness**: The shader fades density near the cube walls using a `box_inner_edge` function, preventing hard cutoffs at volume boundaries.

6. **Fog Volume Shader**: A separate `FogVol.gdshader` uses Godot's `shader_type fog` to render atmospheric fog using 3D gradient noise FBM. It supports height-based fading, spherical edge falloff, palette-based coloring, animated scrolling, and progressive zoom-out over time.

## Parameters

**Main shader uniforms (perlinvolume.gdshader):**

| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `time_scale` | float | 0.25 | Speed of noise animation |
| `noise_scale` | float | 1.75 | Frequency of the noise pattern |
| `density` | float | 1.35 | Overall opacity multiplier |
| `march_steps` | int | 72 | Number of ray marching steps |
| `fbm_detail` | float | 0.8 | Blend factor for multi-octave FBM |
| `warp_amount` | float | 0.2 | Noise-driven coordinate warping |
| `contrast` | float | 1.15 | Boosts mid-to-high noise values |
| `edge_softness` | float | 0.04 | Fade distance near cube walls |
| `jitter_amount` | float | 1.0 | Per-pixel step jitter to reduce banding |
| `light_dir` | Vector3 | (0.4, 0.7, 0.3) | Direction of the virtual light source |
| `light_strength` | float | 1.6 | Intensity of forward scattering |
| `phase_g` | float | 0.2 | Henyey-Greenstein scattering parameter |
| `rim_strength` | float | 0.5 | Rim lighting intensity |
| `emission_boost` | float | 0.6 | Emission multiplier for glow |
| `color1` | Color | (0.0, 0.45, 1.0) | Low noise color |
| `color2` | Color | (0.4, 1.0, 1.0) | Mid noise color |
| `color3` | Color | (1.0, 1.0, 1.0) | High noise color |

**GDScript exports:**

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `rotation_speed` | float | 0.1 | Y-axis rotation speed of the volume mesh |

## Features

- Volumetric ray marching with per-pixel jitter to eliminate banding
- 3D simplex noise with configurable FBM detail blending
- Noise warping for organic, flowing distortion
- Henyey-Greenstein phase function for forward-scattering lighting
- Rim lighting from noise gradient approximation
- Three-color ramp with optional gradient texture override
- Soft edge fading near volume cube boundaries
- Companion fog volume shader using Godot 4's native fog system
- Fog shader features height fade, spherical edge falloff, palette coloring, and zoom animation

## Files

| File | Description |
|------|-------------|
| `perlinvolume.gd` | GDScript -- finds the VolumeBox mesh (shader driven by TIME) |
| `perlinvolume.gdshader` | Main spatial shader -- simplex noise, FBM, ray marching, color ramp, lighting |
| `FogVol.gdshader` | Fog shader -- 3D gradient noise FBM, height fade, edge falloff, palette |
| `perlinvolume.tscn` | Scene file with VolumeBox mesh |
