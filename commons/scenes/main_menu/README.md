# Main Menu

3D VR main menu system with New Game, Load Game, Browse, Settings, and Quit buttons. Displays the QFEP formula and "Threshold Protocol" narrative text on startup.

## How It Works

The menu uses VR pointer-based interaction through `MenuButton3D` components that activate via a timed hover mechanic (1.5 seconds of sustained gaze). The Browse button opens a `MapBrowser3D` panel for directly selecting sequences or individual maps. Settings swap in a 2D-in-3D viewport with game mode and infoboard toggles. The menu connects to `AdaVRStaging` via signals to trigger scene transitions.

## Files

- `MainMenu3D.gd` -- Main menu controller with button connections, save detection, and about text
- `MainMenu3D.tscn` -- 3D menu layout with buttons and about display
- `main_menu_level.tscn` -- Standalone scene wrapping the menu for direct testing
