# Penrose Triangle

A 3D construction of the impossible Penrose triangle -- an object that appears as a closed triangle from one specific viewpoint but reveals its disconnected geometry when viewed from any other angle. Teaches the distinction between local coherence and global consistency in geometry and perception.

## How It Works

Three rectangular beams are arranged along the edges of an equilateral triangle in 3D space. One vertex is offset along the Z-axis, creating a physical gap that prevents the triangle from actually closing. However, from a specific "sweet spot" viewpoint, the Z-offset aligns visually with the adjacent edge, making the triangle appear perfectly closed. The artifact tracks viewer proximity to this sweet spot and emits signals when the illusion activates or breaks, updating an info label to describe the perceptual state.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `size` | float | 0.5 |
| `bar_thickness` | float | 0.08 |
| `auto_rotate` | bool | false |
| `rotation_speed` | float | 0.2 |
| `show_sweet_spot` | bool | true |

## Features

- Impossible triangle geometry with Z-offset gap at one vertex
- Sweet spot detection: emits `viewpoint_locked` and `illusion_revealed` signals
- Glowing green sphere marks the optimal viewing position
- Optional auto-rotation to reveal the 3D structure
- Three distinct material tones for visual depth on each beam
- Dynamic info label describing current perceptual state

## Files

- `penrose_triangle.gd` — Main script
- `penrose_triangle.tscn` — Scene file
