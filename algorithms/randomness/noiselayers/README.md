# Noise Layers

Multi-frequency procedural terrain using layered Perlin noise — realistic landscapes from mathematical randomness.

## QFEP Connection

Natural terrain isn't random at any single scale — it's **random at every scale combined**. Mountains (low frequency), hills (medium), rocks (high) all overlay. Each layer is coherent noise (F), but their combination produces natural complexity (E). The frequency/amplitude ratios encode geological processes.

## How It Works

```
Low Frequency (base terrain):
╭────────────────────────────────────╮
    ╱╲              ╱╲
   ╱  ╲            ╱  ╲
  ╱    ╲──────────╱    ╲

Medium Frequency (ridges):
╭────────────────────────────────────╮
  ╱╲   ╱╲        ╱╲   ╱╲
 ╱  ╲ ╱  ╲      ╱  ╲ ╱  ╲

High Frequency (detail):
╭────────────────────────────────────╮
 ╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲╱╲

Combined:
╭────────────────────────────────────╮
    ╱╲              ╱╲
   ╱  ╲╱╲        ╱╲╱  ╲
  ╱     ╲──╱╲──╱╱╲╱    ╲
```

## Parameters

### Terrain Size
| Export | Default | Description |
|--------|---------|-------------|
| `terrain_size` | 100 | Grid resolution |
| `terrain_scale` | 1.0 | World scale |
| `height_scale` | 10.0 | Vertical exaggeration |

### Low Frequency (Base)
| Export | Default | Description |
|--------|---------|-------------|
| `low_freq_scale` | 0.015 | Feature wavelength |
| `low_freq_amplitude` | 12.0 | Feature height |
| `low_freq_octaves` | 6 | Detail iterations |

### Medium Frequency (Ridges)
| Export | Default | Description |
|--------|---------|-------------|
| `med_freq_scale` | 0.04 | Feature wavelength |
| `med_freq_amplitude` | 6.0 | Feature height |
| `med_freq_octaves` | 4 | Detail iterations |

### High Frequency (Detail)
| Export | Default | Description |
|--------|---------|-------------|
| `high_freq_scale` | 0.08 | Feature wavelength |
| `high_freq_amplitude` | 1.5 | Feature height |
| `high_freq_octaves` | 3 | Detail iterations |

### Walkability
| Export | Default | Description |
|--------|---------|-------------|
| `max_walkable_slope` | 30.0 | Degrees before too steep |
| `slope_smoothing` | 0.8 | Flatten walkable areas |

### Performance
| Export | Default | Description |
|--------|---------|-------------|
| `enable_lod` | true | Level-of-detail system |
| `lod_distance_threshold` | 50.0 | LOD switch distance |
| `chunk_size` | 32 | Terrain chunk size |

## Frequency/Amplitude Relationship

```
Layer      Frequency    Amplitude    Creates
─────────────────────────────────────────────
Low        0.015        12.0         Mountains, valleys
Medium     0.04         6.0          Hills, ridges  
High       0.08         1.5          Rocks, bumps
```

Rule of thumb: double frequency → halve amplitude.

## Files

| File | Purpose |
|------|---------|
| `noise_layers.gd` | Terrain generator |
| `*.tscn` | Scene file |

## Usage

```gdscript
var terrain = NoiseLayers.new()
terrain.height_scale = 20.0  # Taller mountains
terrain.low_freq_amplitude = 15.0  # More dramatic
add_child(terrain)
```

## VR Experience

Walk across procedurally generated terrain. The landscape feels natural because it has structure at every scale — gentle slopes punctuated by smaller features. LOD system keeps performance smooth even for large terrains.

## See Also

- `noiseterrain/` — Simpler terrain generation
- `perlinnoiseclouds/` — Noise for volumetrics
- `transformation/heightmap/` — Height-based terrain
