# Frame Counter Display

`frame_counter_display.tscn` is a lightweight visual aid that displays `Engine.get_process_frames()`.

## Files

- `frame_counter_display.tscn`
- `frame_counter_display.gd`

## Behavior

- Updates one `Label3D` every frame with current process frame count.
- Intended for debug/performance awareness in map corners.

## Notes

Current scene uses static body + CSG mesh shell for panel visuals.
If this display is promoted from debug aid to core artifact, consider replacing CSG with static meshes.
