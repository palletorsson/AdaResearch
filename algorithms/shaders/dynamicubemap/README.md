# Dynamic Cubemap -- Real-Time Reflections

A scene of reflective objects surrounded by colorful animated environment geometry, using Godot's ReflectionProbe system and custom shaders for real-time dynamic reflections. The artifact teaches how **environment mapping and cubemap reflections** work -- incoming light is captured from six directions into a cube texture, which reflective surfaces then sample to simulate mirror-like behavior.

## How It Works

The system creates three layers:

### Environment Layer
12 environment objects (spheres, boxes, cylinders, tori, gems, pillars) are placed in an outer ring at radius ~15m. Each has a custom spatial shader that generates animated color patterns using sine/cosine functions combined with noise, creating constantly shifting surfaces for reflections to capture.

### Reflective Layer
8 reflective objects (spheres, flat mirrors, tori, cylinders, crystal balls, curved panels) are placed in an inner ring at radius ~6m. They alternate between:
- **Standard PBR**: High metallic (0.95), low roughness (0.05) with color tinting.
- **Custom reflection shader**: Fresnel-based reflection with animated distortion, configurable reflection strength, and subtle emission glow.

### Lighting
4 colored OmniLight3D nodes (Cyan, Magenta, Yellow, Green) orbit the scene in different patterns (circular, figure-8, spiral, pendulum) to continuously change the lighting environment.

ReflectionProbes are placed at each reflective object's position with `UPDATE_ALWAYS` mode, capturing the surrounding environment in real time and providing it to the reflective materials.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `reflective_object_count` | int | 8 | Number of reflective objects |
| `reflection_update_rate` | float | 30.0 | Probe updates per second |
| `reflection_resolution` | int | 256 | Controls probe capture area size |
| `animation_speed` | float | 1.0 | Global animation speed multiplier |
| `metallic_strength` | float | 0.95 | Base metallic value for reflective materials |

## Features

- Real-time reflection probes with configurable update rate
- Custom reflection shader with Fresnel falloff and animated distortion
- Animated environment shader for dynamic color-shifting surfaces
- 4 orbiting colored lights with distinct movement patterns
- Multiple reflective geometry types including curved panels and gem meshes
- Floating and rotation animations for dynamic reflection changes

## Files

- `dynamiccubemap.gd` -- Scene setup, reflection probes, shader definitions, animation system
