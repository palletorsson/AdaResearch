# Sine Wall

## Overview
Sine Wall offers two complementary takes on one-directional wave interference: an animated particle wall for lively motion studies and a static SurfaceTool mesh for lightweight set dressing or baked references. Both variants layer multiple sine waves that travel only along the horizontal axis, producing rich interference patterns while the wall?s vertical profile stays intact.

## Dynamic Variant (`SineWall.gd`)
A grid of sphere instances forms the wall. Each column receives the summed influence of the configured wave layers, and the entire surface animates over time with slow modulation of amplitude and frequency. This is ideal when you need continuous motion, real-time parameter tweaking, or interactive visualization.

### Highlights
- **Horizontal Superposition** ? Wave layers combine along one axis only.
- **Time Modulation** ? Base amplitude and frequency drift to keep the motion alive.
- **Color Feedback** ? Height-based palette highlights constructive/destructive regions.
- **Configurable Grid** ? Export vars expose resolution, dimensions, and wave settings.
- **Reset Helper** ? `reset_wall()` snaps the animation back to its neutral state.

## Static Variant (`SineWallStatic.gd`)
Uses Godot?s `SurfaceTool` to build a single `ArrayMesh` wall that is displaced once at build time. The script runs as a `@tool`, so any property change in the editor regenerates the mesh. Vertex colors reuse the same palette logic, making it easy to drop into scenes that just need the sculpted silhouette without the runtime overhead.

### Highlights
- **SurfaceTool Generation** ? Lightweight mesh built on demand, ready for export.
- **Shared Wave Layers** ? Same dictionaries drive both static and dynamic looks.
- **Editor Friendly** ? `auto_update_in_editor` regenerates instantly when tweaking.
- **UV & Color Ready** ? Vertex UVs and colors are emitted for shading flexibility.

## Use Cases
- **Wave Tutorials** ? Show interference with either animated or static references.
- **Audio Visualizers** ? Map sound bands to wave layers for real-time motion.
- **Creative Spaces** ? Drop the static mesh into architectural installations.
- **Procedural Facades** ? Prototype animated or baked building fronts quickly.

## Technical Notes
- `SineWall.gd` drives a mesh-instance grid with shared `SphereMesh` primitives.
- `SineWallStatic.gd` emits an indexed triangle mesh via `SurfaceTool`.
- Both variants expose color gradients and wave-layer dictionaries for easy art direction.
