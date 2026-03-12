# Control Board

A procedurally generated mission-control console with interactive VR elements -- CRT monitors, VU meters, fader banks, push buttons, toggle switches, rotary knobs, a speaker grille, and LED indicator strips. Teaches the concept of control systems and signal monitoring through a tactile, retro-industrial interface.

## How It Works

The board is built entirely from procedural meshes laid out on the XY plane (X = horizontal, Y = vertical, Z = depth toward viewer). Three CRT screens display flickering green phosphor emissions. Two VU meters have animated needles driven by simulated signal values. Six horizontal sliders (fader bank) control channel levels and drive the VU needle positions. A grid of colored push buttons toggles LED states. Eight toggle switches, four rotary knobs with pointer indicators, and a speaker with a semi-transparent grille complete the console. All animations (screen flicker, needle sweep, LED blink) run continuously in `_process`.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `panel_width` | float | `2.4` |
| `panel_height` | float | `1.4` |
| `panel_depth` | float | `0.06` |

## Features

- Three animated CRT screens with phosphor flicker and emission glow
- Two VU meters with swinging needles driven by fader input or simulated signal
- Six-channel fader bank using VR slider interactables
- Six color-coded push buttons (ALARM, ACK, TEST, RESET, LOCK, AUX)
- Eight toggle switches and four labeled rotary knobs (FREQ, GAIN, BIAS, TRIM)
- LED indicator strip with green, red, and amber states
- Speaker housing with cone and semi-transparent grille
- Full signal cleanup on exit tree

## Files

- `control_board.gd` -- Main script
- `control_board.tscn` -- Scene file
