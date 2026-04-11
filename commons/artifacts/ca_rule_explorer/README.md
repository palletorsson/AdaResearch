# CA Rule Explorer

Visualizes Wolfram's elementary one-dimensional cellular automata (rules 0--255) on a horizontal board. Teaches how simple local rules produce complex emergent behavior ranging from uniform patterns to chaotic dynamics to Turing-complete computation.

## How It Works

Each generation applies a 3-neighbor lookup against an 8-bit rule number to determine the next row state. Rows scroll downward on a MultiMesh board so the user sees the full evolution history. The artifact highlights famous rules such as Rule 30 (chaotic), Rule 90 (Sierpinski triangle), and Rule 110 (Turing complete). VR sliders control the active rule and simulation speed, while preset buttons jump to notable rules.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `board_size` | float | `1.0` |
| `cells_x` | int | `64` |
| `rows_visible` | int | `50` |
| `rule` | int | `110` |
| `generations_per_second` | float | `10.0` |
| `auto_run` | bool | `true` |
| `alive_color` | Color | `(0.2, 0.9, 0.4)` |
| `dead_color` | Color | `(0.05, 0.08, 0.05)` |
| `board_color` | Color | `(0.1, 0.12, 0.1)` |

## Features

- Real-time 1D cellular automaton simulation with 256 possible rules
- VR control panel with rule slider, speed slider, preset buttons, and reset
- Famous-rule annotations (Chaotic, Sierpinski, Turing Complete, Traffic, etc.)
- Keyboard shortcuts for desktop testing (arrow keys, number keys, space to pause)
- Public API for external control: `set_rule()`, `toggle_pause()`, `step()`

## Files

- `ca_rule_explorer.gd` -- Main script
- `ca_rule_explorer.tscn` -- Scene file
