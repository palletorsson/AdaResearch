# Euclid's Postulates Plaque

An interactive wall plaque that displays Euclid's five postulates one at a time, with special emphasis on the controversial fifth postulate (the parallel postulate) that gave rise to non-Euclidean geometry.

## How It Works

The plaque presents each of Euclid's five postulates with a title, full text, and Roman numeral indicators (I through V) along the bottom. A glowing highlight marker tracks the currently selected postulate. When the fifth postulate is displayed, the title and text shift to a warm orange color and the highlight turns red-orange, visually distinguishing it from the other four. Users cycle through postulates via mouse clicks (desktop) or programmatic calls, and the artifact emits signals on selection changes and when the parallel postulate is highlighted.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `current_postulate` | int | `0` |
| `highlight_fifth` | bool | `true` |
| `plaque_size` | Vector3 | `Vector3(0.8, 1.0, 0.05)` |

## Features

- All five Euclidean postulates with full text
- Visual emphasis on the fifth (parallel) postulate with distinct coloring
- Glowing highlight marker tracking the active postulate
- Roman numeral indicators with active/inactive states
- Gold metallic frame surrounding a dark plaque surface
- Emits `postulate_selected` and `parallel_highlighted` signals
- Mouse click navigation on desktop; VR-aware input handling

## Files

- `euclid_postulates_plaque.gd` — Main script
- `euclid_postulates_plaque.tscn` — Scene file
