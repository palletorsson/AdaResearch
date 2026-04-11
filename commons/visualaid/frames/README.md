# Frames Display

Displays the current frames-per-second (FPS) count as a 3D label. Updates every frame using `Engine.get_frames_per_second()`.

## How It Works

The script reads the engine's FPS value each frame in `_process` and writes it to a Label3D child node. The text format is a whole number followed by "FPS" (e.g., "60 FPS").

## Features

- Real-time FPS counter updated every frame
- Minimal overhead -- single engine call per frame
- Formatted as integer with "FPS" suffix

## Files

- `frames_display.gd` -- Script that polls `Engine.get_frames_per_second()` and updates the label
- `frames_display.tscn` -- Scene with a Label3D node for rendering the FPS text
