# Player Position Display

Shows the XR player's world-space coordinates as a 3D label. Automatically locates the XROrigin3D node in the scene tree.

## How It Works

On ready, the script attempts to resolve the XR origin via the exported `xr_origin_path`. If that fails, it recursively searches the scene tree for any node named or typed `XROrigin3D`. Once found, it updates the label every frame with the origin's global position formatted as `(x, y, z)` to two decimal places. If the origin is not yet available, it retries the search every 60 frames.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `xr_origin_path` | NodePath | `../../XROrigin3D` |

## Features

- Automatic XROrigin3D discovery with recursive scene tree search
- Fallback retry every 60 frames if player not yet spawned
- Coordinates formatted to two decimal places
- Shows "Waiting for Player..." until the origin is found

## Files

- `player_position.gd` -- Script that tracks and displays the XR origin's global position
- `player_position.tscn` -- Scene with a Label3D for rendering coordinates
