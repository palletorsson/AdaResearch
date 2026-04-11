# Score Display

An interactive score counter that can be incremented, set, and reset from external scripts. Emits a signal on every change and plays a brief flash animation when points are added.

## How It Works

The display manages an internal `_score` integer and renders it to a Label3D. Other scripts call `add_score()`, `set_score()`, or `reset_score()` to modify the value. Each change emits the `score_changed` signal with the new total. The `add_score()` method also triggers a white-to-color tween flash on the label.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `initial_score` | int | `0` |
| `title_text` | String | `"SCORE"` |
| `score_color` | Color | `Color(0.2, 1.0, 0.4)` (green) |

## Features

- `score_changed` signal emitted on every update
- `add_score(amount)`, `set_score(value)`, `reset_score()` API
- Flash animation on score increment (white to score_color tween)
- Configurable title label and display color

## Files

- `score_display.gd` -- Score logic with signals, API methods, and flash animation
- `score_display.tscn` -- Scene with value and title Label3D nodes
