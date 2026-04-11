# Draw Calls Display

Shows the total number of draw calls in the current frame. Useful for identifying rendering bottlenecks and optimizing scene complexity.

## How It Works

Each frame, the script queries `Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)` and writes the integer result to a Label3D node.

## Features

- Real-time draw call counter updated every frame
- Uses Godot's built-in performance monitor
- Displayed as a plain integer for quick readability

## Files

- `draw_calls_display.gd` -- Script that reads the draw call performance monitor
- `draw_calls_display.tscn` -- Scene with a Label3D for rendering the count
