# Simultaneous Contrast

A visual illusion demonstrating simultaneous contrast -- two identical gray objects that appear different because of their surrounding backgrounds, teaching that perceived color depends on context rather than absolute pixel values.

## How It Works

The artifact places two background panels side by side: one dark and one light. A mid-gray sphere sits on each panel. Although both spheres share the exact same gray color, the one on the dark background appears lighter while the one on the light background appears darker. An animation cycle separates the spheres vertically to emphasize the illusion, then brings them back to the same height and reveals a connecting bar to prove they are identical. This animated reveal makes the optical illusion undeniable and demonstrates why color perception algorithms must account for local contrast and surround effects.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `cycle_duration` | float | 8.0 |
| `background_separation` | float | 2.0 |
| `target_size` | float | 1.0 |

## Features

- Classic simultaneous contrast optical illusion in 3D
- Animated proof cycle: separate, align, reveal connector
- Unshaded materials for flat, accurate color comparison
- Tool mode support for in-editor preview

## Files

- `SimultaneousContrast.gd` -- Main script
- `SimultaneousContrast.tscn` -- Scene file
