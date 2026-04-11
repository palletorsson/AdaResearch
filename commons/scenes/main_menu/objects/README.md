# Main Menu Objects

Settings UI objects used within the main menu, rendered as 2D controls inside a 3D viewport.

## How It Works

The settings panel is embedded in a `Viewport2Din3D` node so it can appear as a 3D surface in VR. The content script provides a game mode dropdown (Story/Test/Explorer/TestPlus) and an infoboard visibility toggle, writing changes directly to GameManager and MapProgressionManager.

## Files

- `settings_ui.gd` -- Outer 3D wrapper that initializes the embedded viewport
- `settings_ui.tscn` -- Scene with Viewport2Din3D containing the settings content
- `settings_ui_content.gd` -- ScrollContainer with game mode dropdown and infoboard toggle
- `settings_ui_content.tscn` -- 2D layout for the settings controls
