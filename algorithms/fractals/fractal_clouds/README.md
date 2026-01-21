# Fractal Clouds

## Overview
Generates volumetric clouds using fractal Brownian motion (fBm) noise - multiple octaves of Simplex noise combined for natural-looking cloud formations.

## Spawn
```
fractal_clouds
fractal_clouds#preset:storm
```

## Parameters
| Parameter | Description | Example |
|-----------|-------------|---------|
| `preset` | Apply preset configuration | `#preset:cumulus` |
| `octaves` | Noise detail levels (1-8) | `#octaves:6` |
| `resolution` | Points per axis | `#resolution:32` |
| `animate` | Enable/disable wind animation | `#animate:false` |

## Presets
| Preset | Description |
|--------|-------------|
| `cumulus` | Puffy fair-weather clouds (15×8×15) |
| `stratus` | Flat layered clouds (40×3×40) |
| `cirrus` | Thin wispy high-altitude clouds |
| `storm` | Dark towering storm clouds (25×15×25) |

## Algorithm
### Fractal Brownian Motion (fBm)
```
value = 0
amplitude = 1
frequency = 1

for each octave:
    value += noise(position * frequency) * amplitude
    amplitude *= persistence  (typically 0.5)
    frequency *= lacunarity   (typically 2.0)
```

### Cloud Generation
1. Sample 3D grid of points within cloud volume
2. Calculate fBm noise at each point
3. Apply distance falloff from center (ellipsoid shape)
4. Keep points above density threshold
5. Render using MultiMesh for GPU instancing

## Parameters Explained
| Parameter | Effect |
|-----------|--------|
| `octaves` | Detail levels - more = finer detail |
| `lacunarity` | Frequency multiplier (2.0 = each octave 2x detail) |
| `persistence` | Amplitude multiplier (0.5 = each octave half strength) |
| `density_threshold` | Below this = transparent |
| `density_falloff` | Edge softness exponent |

## Visual Elements
- Height-based coloring (lighter top, darker bottom)
- Alpha transparency based on density
- Wind animation with turbulence
- Unshaded rendering for cloud-like appearance

## Animation
- `wind_speed` - Global drift direction (Vector3)
- `turbulence` - Internal swirling motion strength
- Per-particle noise-based displacement

## API Methods
```gdscript
regenerate()              # Rebuild cloud
set_noise_seed(seed)      # Change noise pattern
set_octaves(n)            # Adjust detail level
randomize_cloud()         # New random seed
apply_preset(name)        # Apply named preset
```

## Performance
- Uses MultiMesh for efficient GPU instancing
- Resolution of 32 = 32,768 potential points
- Only points above threshold are rendered
- Typical cloud: 2,000-8,000 visible particles
