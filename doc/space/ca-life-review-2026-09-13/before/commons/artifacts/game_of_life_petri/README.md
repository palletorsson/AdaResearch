# Game of Life Petri

Implements Conway's Game of Life as a cellular automaton running inside a petri dish, demonstrating how complex emergent behavior arises from three simple rules: birth (dead cell with exactly 3 neighbors becomes alive), survival (live cell with 2 or 3 neighbors persists), and death (all other cases).

## How It Works

A 2D boolean grid is updated each generation by counting the eight neighbors of every cell and applying the B3/S23 rule set. The grid wraps toroidally so patterns can flow across edges. Cells are rendered as a single MultiMesh of tiny colored quads, making the 64x64 grid (4,096 instances) efficient in a single draw call. Built-in pattern presets include glider, pulsar, and Gosper's glider gun. A speed slider controls generations per second from 1 to 30 Hz.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `dish_size` | float | `0.8` |
| `grid_size` | int | `64` |
| `generations_per_second` | float | `8.0` |
| `auto_run` | bool | `true` |
| `alive_color` | Color | `(0.2, 1.0, 0.4)` |
| `dead_color` | Color | `(0.02, 0.05, 0.02)` |
| `dish_color` | Color | `(0.15, 0.15, 0.18)` |

## Features

- Five pattern presets: glider, pulsar, glider gun, random fill, and clear
- VR control panel with speed slider and pattern buttons
- Toroidal wrapping at grid edges
- Live generation counter and population display
- Keyboard shortcuts for patterns (G, P, U) and controls (Space, R, C)

## Files

- `game_of_life_petri.gd` -- Main script
- `game_of_life_petri.tscn` -- Scene file
