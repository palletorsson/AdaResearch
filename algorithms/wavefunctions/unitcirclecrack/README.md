# Unit Circle

An animated 3D unit circle that teaches the **trigonometric functions** `sin` and `cos`, their relationship to **circular motion**, and the concept of **projecting circular position onto perpendicular axes**. A point orbits the circle while its X and Y projections are drawn in real time, making the connection between rotation and sine/cosine waves visually immediate.

## How It Works

A torus mesh represents the unit circle in the XY plane. A glowing sphere orbits at constant angular velocity (`angle += delta * 0.8`), with its position calculated as `(cos(angle), sin(angle), 0)` -- the fundamental definition of the unit circle.

Two projection lines connect the orbiting point to its shadows on the axes:
- A **red line** from `(x, 0, 0)` to `(x, y, 0)` shows the Y-component (sine)
- A **green line** from `(0, y, 0)` to `(x, y, 0)` shows the X-component (cosine)

A **cyan radius line** connects the origin to the point, visualising the unit vector.

The axes use pride flag colours (trans pink and blue for the X axis, lesbian orange and purple for the Y axis) as a QFEP design choice. The orbiting point cycles through rainbow hues over time. The entire scene rotates slowly around Z to give a dynamic 3D perspective.

Lines are constructed as thin cylinders that are rescaled and reoriented each frame using `look_at_from_position()`.

## Parameters

This artifact uses no exported parameters. All values are hardcoded:

| Internal | Value | Description |
|----------|-------|-------------|
| Angular speed | 0.8 rad/s | Speed of point around the circle |
| Circle radius | 1.0 | Unit circle |
| Axis length | 2.0 | Length of each axis arm |
| Point radius | 0.08 | Size of the orbiting sphere |
| Line radius | 0.02 | Thickness of projection lines |
| Rotation speed | 0.1 rad/s | Slow Z-axis rotation of the scene |
| Pulse amplitude | 0.1 | Circle breathing effect |

## Features

- Real-time unit circle animation with `cos`/`sin` point positioning
- Visual projection of X and Y components onto axes
- Radius vector from origin to point
- Rainbow colour cycling on the orbiting point
- Pulsing circle scale for visual interest
- Pride-coloured axes
- Slow scene rotation for 3D depth perception

## Files

| File | Description |
|------|-------------|
| `UnitCircle.gd` | Animated unit circle with sine/cosine projection lines and rainbow colouring |
