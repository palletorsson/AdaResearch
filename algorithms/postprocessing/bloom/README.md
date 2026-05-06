# Bloom

A post-processing artifact that demonstrates the bloom (glow) effect by creating a dark scene filled with highly emissive objects and GPU particles. The environment's glow settings are animated in real time, teaching how bloom transforms bright surfaces into soft, luminous halos.

## Concept Taught

**Bloom post-processing and HDR rendering** -- how fragments with emission values exceeding the HDR threshold bleed light into surrounding pixels, creating the characteristic glow of bright light sources. The artifact teaches the relationship between emission intensity, bloom threshold, bloom strength, and blend modes, and how these interact with HDR luminance capping.

## How It Works

1. **Environment Setup**: A Godot `Environment` is configured with `glow_enabled = true`. Bloom parameters -- intensity, strength, threshold, blend mode, and HDR scale -- are set to produce visible glow. A dark procedural sky ensures the bloom stands out.

2. **Bloom Object Shader**: A custom spatial shader calculates per-fragment emission as a product of base intensity, a sine-wave pulse (time and position-based), and a distance factor. Objects with emission values above the glow threshold produce bloom halos.

3. **Object Arrangement**: 12 glowing objects (sphere, box, cylinder, torus) are placed in three arrangement patterns -- circular, vertical column, and random scatter. Each receives a unique hue, emission intensity, and pulse speed.

4. **GPU Particles**: 200 floating particles use a bloom particle shader with billboard orientation, size pulsing, and extreme brightness (12x). A `ParticleProcessMaterial` adds turbulence-driven swirling motion.

5. **Animated Bloom**: Tweens continuously cycle the environment's `glow_intensity` and `glow_bloom` threshold, creating a breathing effect across the entire scene.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `bloom_intensity` | float | 1.5 | Base glow intensity for the environment |
| `bloom_threshold` | float | 0.8 | HDR threshold above which bloom activates |
| `glow_object_count` | int | 12 | Number of emissive objects |
| `animation_speed` | float | 1.0 | Speed multiplier for all animations |

## Features

- Full Godot glow pipeline configuration (intensity, strength, threshold, blend mode, HDR scale)
- Custom emissive shader with pulsing and position-based variation
- GPU particle system with billboard shader and turbulence
- Four bloom presets: subtle, dramatic, dreamy, neon
- Dynamic `add_bloom_object()` API for runtime object creation
- Animated environment bloom settings (breathing glow)
- Three object arrangement strategies (circular, columnar, scattered)
- Dark sky environment optimized for bloom visibility

## Files

| File | Description |
|------|-------------|
| `postprocessing_bloom.gd` | Complete scene with environment glow, emissive shaders, particles, presets, and animations |
