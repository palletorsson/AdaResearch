# Spectrum Forest

## Purpose
Builds a dense hanging-line field colored by hue position across space.

## Key Files
- `res://algorithms/color/spectrumforest/spectrum_forest.tscn`
- `res://algorithms/color/spectrumforest/spectrum_forest.gd`

## VR Notes
- Generates one `ImmediateMesh` surface; line count is the primary cost lever.
- Intended as static geometry after generation.

## Used In
- `res://commons/maps/Color_Grid_Pallet/map_data.json`
