# Logic Display

3D display screen showing logic equations via SubViewport rendering.

## Files

- `category_logic_display.gd`: main display controller
- `category_logic_display_ui.gd`: UI layout for equations
- `CategoryLogicDisplay.tscn` / UI `.tscn`: scene files

## Behavior

- Renders equations like "point + point → line" onto 3D mesh.
- Uses SubViewport for 2D UI projected onto 3D surface.
- `display_equation()` method updates content dynamically.
