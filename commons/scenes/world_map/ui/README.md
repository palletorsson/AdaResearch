# World Map UI

Subway-style map visualization showing curriculum progression through QFEP phases, rendered as a 2D Control for embedding in 3D viewports.

## How It Works

`SubwayMapRenderer` draws the entire map using Godot's `_draw()` API: thick solid lines for the main spine path, dashed lines for optional branches, and colored stations indicating completed/unlocked/locked state. Stations are laid out using `WorldMapDataProvider`'s subway layout algorithm. Hovering a station shows a tooltip with sequence details and QFEP role; holding the cursor triggers selection. `WorldMapUI` wraps the renderer with a legend panel, stats display, and panning support.

## Files

- `SubwayMapRenderer.gd` -- Custom Control that draws metro-style lines, stations, phase bands, and hold-to-select progress rings
- `WorldMapUI.gd` -- Main UI controller with tooltip, legend, stats, panning, and progression event handling
- `WorldMapUI.tscn` -- Layout scene combining the subway renderer, tooltip panel, legend, and stats label
