# Glitch Body

A procedural mesh that refuses stable form, rebuilt every frame with time-varying vertex perturbation and cycling HSV colors. It embodies the concept of continuous becoming and resists fixed categorization -- the queer theory artifact.

## How It Works

A base sphere is computed once using spherical coordinates, then every frame each vertex is displaced along its normal by a layered noise function. Multiple sin-based noise octaves at different spatial and temporal frequencies produce organic, cross-coupled deformation. Occasional sharp "glitch" spikes create abrupt deformation peaks, and a slow radial breathing cycle adds pulsation. Vertex colors cycle through the HSV spectrum with per-vertex hue offsets, and saturation drops to near-white during glitch peaks. The entire mesh is rebuilt per frame as an ImmediateMesh with triangle primitives.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `body_radius` | float | `0.25` |
| `lat_segments` | int | `20` |
| `lon_segments` | int | `24` |
| `noise_amplitude` | float | `0.08` |
| `noise_speed` | float | `1.5` |
| `hue_cycle_speed` | float | `0.12` |
| `deformation_layers` | int | `4` |

## Features

- Per-frame procedural mesh rebuild with multi-octave vertex displacement
- HSV hue cycling with per-vertex variation
- Glitch spike events creating sudden deformation bursts
- Breathing animation via slow radial pulsation
- Double-sided rendering (backface culling disabled)

## Files

- `glitch_body.gd` -- Main script
- `glitch_body.tscn` -- Scene file
