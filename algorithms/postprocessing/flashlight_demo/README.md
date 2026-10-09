# Flashlight Demo

## Purpose
Configures a grabbable flashlight and applies color to beam/lens presentation.

## Key Files
- `res://algorithms/postprocessing/flashlight_demo/flashlight_demo.tscn`
- `res://algorithms/postprocessing/flashlight_demo/flashlight_color.gd`

## VR Notes
- Uses XR pickable/grab-point behavior through scene composition.
- Color script targets `SpotLight3D` and lens mesh at runtime.

## Used In
- `res://commons/maps/Color_Flashlight/map_data.json`

## Standing museum installation

`flashlight_demo:180:0:1#plinth:0#mount:standing` places the root at floor level. The optional mount raises the board centre to 2 m and handles to 1.1 m, enables board collision, sets lamp energy to 2.5, and aims white aside initially. Legacy placements retain their existing mounting.

The visitor can pick up and aim lamps; there is no hue picker or on/off UI. `ground` selects authored receiving variants and is separate from the mount. Lights use RGB rendering, not wavelength spectra. See `commons/maps/Color_Flashlight/final.md` and `field_notes.md` for the current lesson and its desktop verification.
