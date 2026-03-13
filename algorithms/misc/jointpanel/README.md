# Joint Panel -- Hinged Floor Panels

A grid of floor panels that open outward from the center on hinges, inspired by the mechanical panel systems in the Portal game series. The artifact demonstrates **hinge-based rotation with pivot offsets**, **directional animation logic**, and **CSG-based environmental construction**.

## Concept Taught

**Rigid body rotation around offset pivot points.** When rotating an object around a hinge that is not at its center, the object must first be translated so the hinge point is at the origin, rotated, then translated back. This artifact teaches this translate-rotate-translate pattern for each panel in the grid, computing hinge positions and rotation axes based on each panel's position relative to the grid center. It also demonstrates how grid-based spatial reasoning determines outward-opening directions.

## How It Works

1. A **pit** is created below the panel grid as a large CSG box, providing a void for panels to open into.
2. A **frame** is built around the panel area using a CSG box with a CSG subtraction to carve out the opening.
3. A grid of `grid_size_x` by `grid_size_z` **panels** (thin CSG boxes) is created with configurable gaps between them.
4. When the space bar is pressed, panels animate between closed (0 degrees) and open (`max_open_angle` degrees).
5. Each panel's opening direction is computed based on its position relative to the grid center:
   - The panel determines whether it is left/right of center X and above/below center Z.
   - The dominant axis (whichever is farther from center) determines the rotation axis and hinge edge.
   - Panels at the grid center default to a chosen direction.
6. The rotation is applied using the **pivot offset pattern**: translate by negative hinge offset, rotate around the chosen axis, translate back by hinge offset.
7. Opening and closing are animated smoothly at `open_speed` per frame.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `grid_size_x` | int | 3 | Number of panels in the X direction |
| `grid_size_z` | int | 3 | Number of panels in the Z direction |
| `panel_size` | float | 1.0 | Width and depth of each panel |
| `gap_size` | float | 0.02 | Spacing between panels |
| `open_speed` | float | 2.0 | Animation speed multiplier |
| `max_open_angle` | float | 85.0 | Maximum panel opening angle in degrees |
| `panel_material` | Material | -- | Custom panel material (defaults to light gray) |
| `frame_material` | Material | -- | Custom frame material (defaults to dark gray) |
| `pit_material` | Material | -- | Custom pit material (defaults to near-black) |

## Features

- Grid-based panel layout with configurable dimensions and spacing
- Outward-opening hinge logic based on panel position relative to center
- Smooth open/close animation with speed control
- Pivot-offset rotation pattern for realistic hinge behavior
- CSG pit with frame and subtraction-carved opening
- Space bar toggle for open/close animation
- Configurable materials for panels, frame, and pit
- Center-aware direction computation for natural outward spread

## Files

- `joint_panel.gd` -- Panel grid generator with hinge animation system
- `joint_panel.tscn` -- Scene file
