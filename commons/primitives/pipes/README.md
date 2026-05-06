# Pipes

Pipe network system with JSON-based layout definitions.

## Files

- `pipe_layout.gd`: high-level pipe network controller
- `turtle_pipe_base.gd`: turtle-graphics cursor for segment creation
- `PipeLayout.tscn`: scene wrapper

## Subfolders

- `layouts/`: JSON layout definitions (drain_network.json, example_network.json)

## Behavior

- Loads pipe network topology from JSON files.
- TurtlePipeBase provides cursor tracking for building pipe segments.
- Anchor points define connection locations.
