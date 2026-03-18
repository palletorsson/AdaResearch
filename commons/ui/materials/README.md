# UI Materials

Shared StandardMaterial3D resources for the Ada design system. Every VR component references these instead of creating inline materials, ensuring visual consistency across the project.

## How It Works

Each `.tres` file defines a `StandardMaterial3D` with specific albedo, metallic, roughness, and emission values. Accent colors include emission so they read clearly at arm's length in VR. Materials are preloaded via `ada_ui_materials.gd` and referenced by constant name (e.g., `UI.PANEL_WHITE`, `UI.ACCENT_BLUE`).

## Files

### Panel Surfaces
- `panel_white.tres` -- Near-white background for light panels.
- `panel_light.tres` -- Light gray panel surface.
- `panel_medium.tres` -- Mid gray for borders and separators.
- `panel_dark.tres` -- Dark panel and bezel background.

### Accent Colors
- `accent_blue.tres` -- Info and links. Blue with soft emission.
- `accent_cyan.tres` -- Displays and data readouts.
- `accent_green.tres` -- Active and positive states.
- `accent_orange.tres` -- Primary accent (TE orange).
- `accent_red.tres` -- Stop and danger indicators.
- `accent_yellow.tres` -- Warnings and highlights.

### Metals
- `metal_dark.tres` -- Knob bases and structural elements.
- `metal_chrome.tres` -- Shiny chrome for decorative metal.
- `metal_warm.tres` -- Brushed warm metal.

### Screen and Display
- `screen_bg.tres` -- Near-black CRT/LCD display background.
- `screen_bezel.tres` -- Display frame surround.

### Interactive Elements
- `handle_glow.tres` -- Bright emission for grabbable handles.
- `track_groove.tres` -- Slider and fader track background.
- `track_fill.tres` -- Active fill color on slider tracks.
