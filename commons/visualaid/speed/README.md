# Speed Display

Shows the current engine time scale as a 3D label. Useful for debugging slow-motion or fast-forward effects.

## How It Works

Each frame, the script reads `Engine.time_scale` and formats it to two decimal places with an "x" suffix (e.g., "1.00x"). This reflects any runtime changes to the engine's time scale.

## Features

- Real-time time scale readout updated every frame
- Formatted as a multiplier (e.g., "0.50x" for half speed)
- Instantly reflects changes to `Engine.time_scale`

## Files

- `speed_display.gd` -- Script that reads `Engine.time_scale` and updates the label
- `speed_display.tscn` -- Scene with a Label3D for rendering the speed value
