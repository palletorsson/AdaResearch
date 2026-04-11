# Grids and Checkers

A set of four minimal GPU shaders that teach **fundamental 2D pattern math** -- checkerboards, stripes, scrolling grids, and rotated tiling. These are the building blocks of procedural texturing: `floor()`, `fract()`, `mod()`, `smoothstep()`, and 2D rotation matrices. Each shader is concise enough to read in a few minutes while producing visually striking results.

## How It Works

### Checkers
The classic checkerboard: `mod(floor(uv.x) + floor(uv.y), 2.0)` yields 0 or 1 in alternating cells. Two source colors are mixed by this value. An emission glow is applied only to the "light" cells.

### Diagonal Stripes
UV coordinates are shifted to center, scaled, then combined as `(uv.x + uv.y) * 0.5`. The `fract()` of this sum creates diagonal bands. `smoothstep()` with a configurable `stripe_width` softens the edges for an anti-aliased result.

### Line Grid
Horizontal bands scroll vertically over time using `uv.y += TIME * speed`. The `fract()` function isolates each band; `smoothstep()` with a `line_width` parameter controls thickness. Emission makes the lines glow against a dark background.

### Rotated Checkers
The most complex variant: a 2D rotation matrix (`mat2`) rotates UV space by a configurable angle before applying the checkerboard formula. A **gutter** (gap line) is added by computing `min(fract(uv), 1.0 - fract(uv))` to find each pixel's distance to the nearest cell edge, then `smoothstep()` masks a third "gutter" color along those edges. This produces a tile-floor effect with visible grout lines.

## Parameters

### Checkers
| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `uv_scale` | vec2 | `(20, 20)` | Tile count in U and V |
| `col_a` | vec4 | dark purple | Color A |
| `col_b` | vec4 | white | Color B |
| `glow` | float | 0.8 | Emission intensity on light cells |

### Diagonal Stripes
| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `uv_scale` | vec2 | `(12, 12)` | Tile scale |
| `stripe_width` | float | 0.35 | Stripe thickness (0--0.5) |
| `col_a` | vec4 | dark blue | Background color |
| `col_b` | vec4 | pink | Stripe color |

### Line Grid
| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `uv_scale` | vec2 | `(2, 12)` | Grid density |
| `line_width` | float | 0.15 | Line thickness |
| `speed` | float | 1.0 | Vertical scroll speed |
| `col_bg` | vec4 | dark teal | Background color |
| `col_ln` | vec4 | orange | Line color |
| `glow` | float | 1.0 | Line emission intensity |

### Rotated Checkers
| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `uv_scale` | vec2 | `(24, 24)` | Tile count |
| `angle_deg` | float | 45.0 | Rotation angle in degrees |
| `gutter` | float | 0.08 | Gap line width |
| `edge_soft` | float | 0.02 | Feathering on gutter edges |
| `col_a` | vec4 | dark purple | Tile color A |
| `col_b` | vec4 | pink | Tile color B |
| `col_gutter` | vec4 | teal | Grout / gap color |
| `glow` | float | 1.2 | Gutter emission intensity |
| `metallic` | float | 0.0 | PBR metallic |
| `roughness` | float | 0.45 | PBR roughness |

## Features

- Four progressively complex shaders teaching core pattern math.
- All shaders are double-sided (`cull_disabled`) for use on any geometry.
- Emission / glow support for neon-style visuals.
- Anti-aliased edges via `smoothstep()`.
- 2D rotation matrix for arbitrary tile angles.
- Gutter / grout lines with configurable width and color.
- Time-animated scrolling in the line grid shader.
- Scene file demonstrates all four shaders on boxes and spheres.

## Files

| File | Purpose |
|------|---------|
| `checkers.gdshader` | Basic checkerboard with glow |
| `diagonalstripes.gdshader` | Smooth diagonal stripe bands |
| `linegrid.gdshader` | Scrolling horizontal line grid |
| `rotatedcheckers.gdshader` | Rotated checkerboard with gutter lines |
| `gridscheckers.tscn` | Demo scene with all four shaders on various meshes |
