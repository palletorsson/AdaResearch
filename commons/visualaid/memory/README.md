# Memory Display

Shows the application's current static memory usage in megabytes. Useful for profiling and detecting memory leaks during development.

## How It Works

Each frame, the script calls `OS.get_static_memory_usage()` to get the byte count, converts it to megabytes, and writes the result to a Label3D. The value is formatted to two decimal places (e.g., "128.45 MB").

## Features

- Real-time memory usage updated every frame
- Displays static memory in MB with two-decimal precision
- Single OS call per frame for minimal overhead

## Files

- `memory_display.gd` -- Script that polls `OS.get_static_memory_usage()` and formats the output
- `memory_display.tscn` -- Scene with a Label3D for rendering memory text
