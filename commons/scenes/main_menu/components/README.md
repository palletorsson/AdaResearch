# Main Menu Components

Reusable 3D UI components for the VR main menu system.

## How It Works

`MenuButton3D` is a hover-to-click button that uses XR Tools pointer events. When a VR pointer enters the button, a progress ring fills over 1.5 seconds; completion triggers the click with haptic feedback. `MapBrowser3D` loads all sequence definitions from JSON files and presents paginated lists of sequences or individual maps. `MenuFollower` makes a node smoothly track the VR camera position so the menu stays in view. `MenuParticles` provides ambient sparkle particles for atmosphere.

## Files

- `MapBrowser3D.gd` -- Paginated browser for sequences and maps with toggle between modes
- `MapBrowser3D.tscn` -- Browser layout with title, items container, navigation buttons, and page label
- `MenuButton3D.gd` -- VR hover-to-click button with shader material, progress indicator, and haptics
- `MenuButton3D.tscn` -- Button scene with interaction cube, label, collision shape, and progress ring
- `MenuFollower.gd` -- Smooth camera-following node that keeps the menu in front of the player
- `MenuParticles.gd` -- Simple particle emitter for ambient menu atmosphere
- `MenuParticles.tscn` -- GPU particle system scene
