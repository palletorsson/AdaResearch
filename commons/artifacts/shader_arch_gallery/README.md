# Shader Arch Gallery

A rectangular tunnel built from cubes, where each cube displays a different wallpaper group tile pattern. Uses the `wallpaper_tile` shader with varying groups, palettes, and domain textures per cube in an Art to Eat patchwork style.

## How It Works

The gallery constructs a tunnel shell (floor, ceiling, left wall, right wall) from individual BoxMesh cubes. Each cube receives a unique ShaderMaterial with a randomly selected wallpaper group (0-16), color palette, tile scale, and a procedurally generated 8x8 domain texture. Ten domain pattern generators (blocks, stripes, diagonal, cross, concentric, checker, scatter, stairs, zigzag, frame) create visual variety. Omni lights are spaced along the tunnel length.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| tunnel_width | int | 5 |
| tunnel_height | int | 4 |
| tunnel_length | int | 25 |
| cube_size | float | 1.0 |
| emission_strength | float | 0.8 |

## Features

- Walk-through tunnel showcasing all 17 wallpaper groups
- 10 neon/Art-to-Eat color palettes
- 10 procedural domain pattern generators including zigzag and frame patterns
- Each cube has a unique combination of wallpaper group, palette, and domain
- Configurable tunnel dimensions and cube size
- Evenly spaced omni lights along the tunnel

## Files

- `shader_arch_gallery.gd` -- Tunnel builder with per-cube wallpaper shader materials
- `shader_arch_gallery.tscn` -- Scene file
