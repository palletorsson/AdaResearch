# Cloud Volume

A volumetric cloud rendered inside a cube using a **ray marching** shader. The cloud shape is defined by fractal Brownian motion (FBM) built on 3D simplex noise, with animated drift and realistic lighting computed by marching secondary rays toward the sun.

This artifact teaches how **noise functions** combined with **ray marching** can produce realistic volumetric phenomena like clouds. The density at any point in space is a pure function of position and time -- no mesh geometry defines the cloud shape. Structure emerges entirely from layered noise.

## How It Works

1. **Ray Marching**: The shader renders the back faces of a cube (using `cull_front`). For each fragment, it computes where the camera ray enters and exits the cube volume. It then steps through the volume in `march_steps` increments, sampling the density function at each point.

2. **Density Function**: At each sample point, the shader evaluates 4-octave FBM of 3D simplex noise. The result is offset by `cloud_cover` (a threshold that controls how much of the volume is filled) and softened near the volume edges using a distance falloff. The `density` uniform scales the overall opacity.

3. **Light Marching**: At each sample point where density is above threshold, a secondary ray is marched toward the sun direction for `light_steps` iterations. The accumulated transmittance along this light ray determines how much sunlight reaches the point. High transmittance means the point is lit; low means it is in shadow.

4. **Color Blending**: Lit areas use `base_color` and shadowed areas use `shadow_color`, blended by the light transmittance. Front-to-back alpha compositing accumulates the final color and opacity, with early exit when opacity reaches 0.99.

5. **Animation**: The density function's position is offset along Z by `TIME * time_scale`, causing the cloud to drift. The GDScript slowly rotates the volume mesh for 3D visual interest and continuously updates the shader with the current camera position and sun direction.

## Parameters

**Shader uniforms:**

| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `cloud_cover` | float | 0.25 | Noise threshold -- lower = more cloud |
| `noise_scale` | float | 0.6 | Frequency of the noise pattern |
| `time_scale` | float | 0.15 | Speed of cloud drift animation |
| `absorption` | float | 0.15 | How quickly density accumulates opacity |
| `density` | float | 3.0 | Overall density multiplier |
| `base_color` | Color | white | Color of lit cloud areas |
| `shadow_color` | Color | (0.5, 0.6, 0.8) | Color of shadowed cloud areas |
| `light_steps` | float | 8.0 | Steps for light marching toward sun |
| `light_absorption` | float | 0.1 | Light attenuation rate through cloud |
| `march_steps` | int | 64 | Number of ray marching steps |
| `volume_size` | Vector3 | (1, 1, 1) | Size of the volume box |

**GDScript exports:**

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `rotation_speed` | float | 0.05 | Y-axis rotation speed of the volume mesh |

## Features

- Full volumetric ray marching with front-to-back compositing
- 3D simplex noise with 4-octave FBM for cloud density
- Secondary light marching toward a directional sun for realistic self-shadowing
- Animated cloud drift via time-offset noise coordinates
- Soft volume-edge falloff to prevent hard cutoffs at cube boundaries
- Early exit optimization when accumulated alpha reaches near-opaque
- Emission added for better visibility in dark environments

## Files

| File | Description |
|------|-------------|
| `cloudvolume.gd` | GDScript -- rotates volume, updates camera and sun direction uniforms |
| `cloudvolume.gdshader` | Spatial shader -- 3D simplex noise, FBM, ray marching, light marching |
| `cloudvolume.tscn` | Scene file with VolumeBox mesh, Sun light, and Camera3D |
