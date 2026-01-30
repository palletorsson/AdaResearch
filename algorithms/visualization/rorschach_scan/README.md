# Rorschach Brain Scan

Animated medical-style display showing mirrored inkblot patterns — procedural brain slices that scroll like CT/MRI scans.

## QFEP Connection

The Rorschach test reveals how humans find **pattern in noise** — we project meaning onto random shapes. This visualization generates symmetric noise (pure E, entropy) that our pattern-seeking minds (F) interpret as faces, creatures, forms. The symmetry is the minimal order that enables recognition.

## How It Works

```
┌─────────────────────────────────────┐
│                                     │
│     ████░░░░░░████                  │
│   ████████░░████████                │
│  ██░░████████████░░██               │
│  ████░░██████░░████                 │
│   ██████░░░░██████                  │
│     ██████████                      │
│       ██████                        │
│                                     │
│   [Layer 24/48]  CT Mode            │
└─────────────────────────────────────┘
```

1. **Simplex noise** generates organic random patterns
2. **Threshold** converts to black/white
3. **Mirror** horizontally for bilateral symmetry
4. **Animate** through Z-layers like medical scan slices

## Scan Modes

| Mode | Colors | Aesthetic |
|------|--------|-----------|
| **CT** | White on dark blue | Classic X-ray look |
| **MRI** | Bright white on gray | Magnetic resonance |
| **PET** | Orange/red on blue | Metabolic activity |
| **Thermal** | Yellow on purple | Heat map |

## Components

| File | Purpose |
|------|---------|
| `rorschach_scan.gd` | Core layer generation |
| `rorschach_monitor.gd` | Medical monitor frame |
| `rorschach_scan.tscn` | Standalone display |
| `rorschach_monitor.tscn` | Framed monitor version |

## Parameters

### Scan
| Export | Default | Description |
|--------|---------|-------------|
| `scan_speed` | 0.4-0.5 | Layer scroll rate |
| `layer_count` | 48-64 | Total depth slices |
| `resolution` | 256 | Image pixel size |
| `threshold` | 0.45 | Ink density |
| `noise_scale` | 3.0 | Pattern frequency |

### Visual
| Export | Default | Description |
|--------|---------|-------------|
| `scan_mode` | CT | Color preset |
| `ink_intensity` | 1.0 | Pattern brightness |
| `glow_strength` | 0.5 | Edge emission |
| `screen_emission` | 0.8 | Monitor glow |

## Performance

Layers generate incrementally (`layers_per_frame = 2`) to avoid blocking. The cache stores all layers once computed, enabling smooth playback.

## Files

| File | Purpose |
|------|---------|
| `rorschach_monitor.tscn` | Medical monitor display |
| `rorschach_scan.tscn` | Bare display |

## Usage

```gdscript
var scan = preload("res://algorithms/visualization/rorschach_scan/rorschach_monitor.tscn").instantiate()
scan.scan_mode = 2  # PET scan colors
scan.scan_speed = 0.3  # Slower
add_child(scan)
```

## VR Experience

Watch the scan cycle through brain slices. The bilateral symmetry triggers pareidolia — you'll see faces, creatures, and forms that aren't "really" there. This is your visual cortex doing what it evolved to do: finding meaning in ambiguity.

## Psychological Note

Hermann Rorschach's 1921 inkblot test used this phenomenon diagnostically. What you see in ambiguous patterns reveals something about your perceptual biases and associations. This procedural version generates infinite unique "tests."

## See Also

- `randomness/` — Noise generation techniques
- `color/` — Color theory and gradients
- `postprocessing/` — Visual effects
