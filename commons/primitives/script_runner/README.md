# Script Runner

A live code display artifact for map lessons. It renders code on a panel and executes scripted line actions over time.

## What It Does

- Displays syntax-highlighted code line by line.
- Highlights the active line.
- Executes actions (`eval`, grid actions, point actions).
- Shows evaluated result text and optional 3D markers.
- Exposes a VR-touchable play/pause button.

## Map Usage

Use registry config syntax in `interactables`:

```json
"script_runner#point:90:1"
```

Supported script keys:

- `point`
- `vector_math`
- `array`
- `pattern`
- `loop`

Scripts are defined in `scripts.json`.

## VR Interaction Notes

- Play button uses `Area3D` touch + mouse input.
- Presses are debounced with `button_press_cooldown` (default `0.25s`) to prevent double toggles from hand collider overlap.
- Button icon uses ASCII-safe states: `>` (idle), `||` (running).

## Scene Defaults

`script_runner.tscn` defaults to:

- `script_name = "point"`
- strong highlight alpha for readability in VR

## Extending

1. Add a new script block in `scripts.json`.
2. Add config mapping in `commons/artifacts/registry/script_runner.json`.
3. Add key in `_check_config_metadata()` if using metadata toggle path.
