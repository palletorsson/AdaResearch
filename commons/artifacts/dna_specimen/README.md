# DNA Specimen

A DNA double helix suspended in a luminescent glass specimen jar, demonstrating biological oscillation and helical waveforms through a slowly rotating, glowing display.

## How It Works

The artifact assembles a glass jar, colored fluid, and a double helix structure from scene sub-nodes. The jar uses a highly transparent material with low roughness for a glass effect, while the fluid inside emits a soft glow that pulses sinusoidally. The double helix rotates continuously around the Y axis at a configurable speed, and the strand colors can be set to highlight the two complementary strands of the DNA structure.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `rotation_speed` | float | `0.2` |
| `helix_color_a` | Color | `Color(0.2, 0.6, 1.0)` |
| `helix_color_b` | Color | `Color(1.0, 0.4, 0.6)` |
| `fluid_color` | Color | `Color(0.1, 0.4, 0.3, 0.3)` |
| `glow_intensity` | float | `1.5` |

## Features

- Transparent glass jar with metallic sheen
- Emissive fluid with sinusoidal glow pulsing
- Continuously rotating double helix with two distinct strand colors
- Metallic base pedestal
- Configurable specimen label text via `set_specimen_label()`

## Files

- `dna_specimen.gd` — Main script
- `dna_specimen.tscn` — Scene file
