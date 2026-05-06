# Spectrum Visualizer

## Purpose
Visualizes visible-spectrum progression and magenta-gap transition between linear and circular layouts.

## Key Files
- `res://algorithms/color/spectrum_visualizer/SpectrumVisualizer.tscn`
- `res://algorithms/color/spectrum_visualizer/SpectrumVisualizer.gd`

## VR Notes
- Animates each frame and updates many mesh instances.
- Keep dot count conservative on standalone VR hardware.

## Used In
- `res://commons/maps/Color_Pillar/map_data.json`
