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
