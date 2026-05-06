# Perlin Noise Clouds

VR-optimized volumetric cloud simulation using Perlin noise — performance-tuned atmospheric effects.

## QFEP Connection

Clouds are **structured randomness in 3D**. Perlin noise creates the coherent patterns (F) while wind and turbulence introduce drift (E). The result looks natural because real clouds form through similar processes — ordered fluid dynamics producing chaotic-seeming shapes.

## How It Works

```
Noise Field:                 Cloud Particles:
┌───────────────────┐        ┌───────────────────┐
│ ▒▒░░▓▓▒▒░░▓▓▒▒░░ │        │   ●●  ●●●  ●●●   │
│ ░░▓▓▒▒░░▓▓▒▒░░▓▓ │   →    │  ●●●●   ●●●●●   │
│ ▓▓▒▒░░▓▓▒▒░░▓▓▒▒ │        │    ●●●●●  ●●     │
└───────────────────┘        └───────────────────┘
  Density values              Instanced spheres
```

Particles spawn where noise exceeds threshold; opacity follows noise value.

## Parameters

### VR Performance
| Export | Default | Description |
|--------|---------|-------------|
| `vr_quality` | BALANCED | HIGH/BALANCED/PERFORMANCE |
| `enable_adaptive_quality` | true | Auto-adjust for FPS |
| `target_fps` | 90.0 | VR framerate target |
| `max_frame_time` | 11.0 | Max ms per frame |

### Cloud Shape
| Export | Default | Description |
|--------|---------|-------------|
| `cloud_size` | (50,20,50) | Volume dimensions |
| `cloud_density` | 0.3 | Particle density |
| `noise_scale` | 0.05 | Noise frequency |
| `cloud_layers` | 2 | Vertical stacking |
| `animation_speed` | 0.5 | Drift rate |
| `fade_distance` | 80.0 | Fog-out distance |

### Optimization
| Export | Default | Description |
|--------|---------|-------------|
| `frustum_culling` | true | Skip off-screen particles |
| `use_instancing` | true | GPU instancing |
| `batch_size` | 100 | Process per frame |

## VR Quality Presets

| Preset | Particles | Layers | Notes |
|--------|-----------|--------|-------|
| HIGH | ~5000 | 3 | For powerful GPUs |
| BALANCED | ~2000 | 2 | Default, 90 FPS target |
| PERFORMANCE | ~800 | 1 | For weaker systems |

## Adaptive Quality

When enabled, system monitors frame time:
- If too slow: reduce particles, increase LOD
- If headroom: restore quality
- Targets smooth 90 FPS for VR comfort

## Files

| File | Purpose |
|------|---------|
| `perlin_noise_clouds.gd` | Cloud generator |
| `*.tscn` | Scene file |

## Usage

```gdscript
var clouds = preload("res://algorithms/randomness/perlinnoiseclouds/clouds.tscn").instantiate()
clouds.vr_quality = clouds.VRQuality.HIGH
clouds.cloud_density = 0.5  # Denser clouds
add_child(clouds)
```

## VR Experience

Look up at clouds drifting overhead. They form, shift, and dissipate naturally. The volumetric feel comes from thousands of translucent spheres following noise patterns. Frustum culling ensures you only render what you can see.

## Technical Notes

- Uses `MultiMeshInstance3D` for GPU instancing
- Custom `CloudParticle` class for memory efficiency
- Frustum culling via `Plane` intersection tests
- Batched processing to spread load across frames

## See Also

- `noiselayers/` — Terrain from layered noise
- `noisesphere/` — Spherical noise
- `postprocessing/` — Other atmospheric effects
