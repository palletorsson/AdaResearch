# Game Time Display

Shows the elapsed session time as a 3D label in HH:MM:SS format. Counts from the moment the application started.

## How It Works

Each frame, the script reads `Time.get_ticks_msec()` and converts milliseconds into hours, minutes, and seconds. The result is formatted as a zero-padded time string (e.g., "00:05:32") and written to a Label3D.

## Features

- Session elapsed time updated every frame
- Zero-padded HH:MM:SS format
- No configuration needed -- starts counting automatically

## Files

- `game_time_display.gd` -- Script that converts engine ticks to formatted time
- `game_time_display.tscn` -- Scene with a Label3D for rendering the time
