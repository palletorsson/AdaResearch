# Index Visualizer

A floating label that tracks the player's position on the grid and displays the corresponding array index in real time, connecting physical movement to array addressing.

## How It Works

Each frame, the script finds the player node (via the "player" group) and rounds the player's world position to the nearest integer grid coordinates. It then displays the resulting index as `[row, col]` on a billboard Label3D hovering above the player's head. This gives an always-visible readout of where the player stands in the map's underlying data structure, reinforcing the concept that every position in a grid world maps to an index in a 2D array.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `tracked_node_name` | String | "XRPlayer" |
| `font_size` | int | 48 |
| `text_color` | Color | Yellow |

## Features

- Billboard label always faces the camera
- Automatic player detection via scene group
- Real-time update every frame
- No depth test so the label is always visible

## Files

- `IndexVisualizer.gd` -- Main script
- `IndexVisualizer.tscn` -- Scene file
