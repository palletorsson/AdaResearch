# Dark Sphere

An atmospheric decorative artifact featuring a semi-transparent dark orb with pulsing emission and slow rotation, designed as ambient scenery for L-system and algorithm maps.

## How It Works

A sphere mesh floats above a halo ring disc at ground level. The sphere rotates slowly around the Y axis with a slight wobble on X, while its emission energy oscillates sinusoidally between configurable min and max values. The albedo brightness also pulses in sync, creating a breathing glow effect. The halo ring beneath the sphere has its own opacity pulse at a slightly different frequency, simulating a faint shadow or aura.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | `0.5` |
| `sphere_radius` | float | `0.35` |
| `float_height` | float | `0.25` |
| `rotation_speed` | float | `0.15` |
| `pulse_speed` | float | `1.2` |
| `pulse_min` | float | `0.05` |
| `pulse_max` | float | `0.35` |
| `albedo_color` | Color | `Color(0.08, 0.04, 0.12)` |
| `emission_color` | Color | `Color(0.18, 0.08, 0.28)` |

## Features

- Semi-transparent sphere with metallic sheen and pulsing emission
- Slow rotation with subtle X-axis wobble
- Ground-level halo ring with independent opacity animation
- Fully configurable via grid system (`apply_grid_config()` rebuilds geometry)

## Files

- `dark_sphere.gd` — Main script
- `dark_sphere.tscn` — Scene file
