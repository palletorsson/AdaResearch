# 2D-in-3D Settings UI

A settings panel rendered as a 2D UI inside a 3D viewport, used in VR scenes for adjusting player preferences.

## How It Works

The settings UI uses XR Tools' `Viewport2Din3D` to embed a 2D Control scene (a ScrollContainer with toggles and dropdowns) onto a 3D surface. The outer `settings_ui.gd` connects to the inner content's signals, forwarding events like player height changes back to the 3D scene.

## Files

- `settings_ui.gd` -- Outer 3D node that bridges the embedded viewport's signals to the scene
- `settings_ui.tscn` -- Scene with Viewport2Din3D containing the 2D settings panel
- `settings_ui_content.gd` -- VBoxContainer content that relays player height change signals
- `settings_ui_content.tscn` -- 2D layout with settings controls
