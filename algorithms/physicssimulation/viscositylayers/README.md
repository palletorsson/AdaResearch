# Viscosity Layers

A physics simulation artifact that drops identical balls through three transparent columns filled with different fluids -- air, water, and honey -- to visually compare drag forces and terminal velocity. VR-interactive with push-button controls.

## Concept Taught

**Fluid viscosity and drag** -- how the same object falls at dramatically different speeds depending on the medium it travels through. The simulation applies quadratic drag (`F_drag = -c * v * |v|`) with different drag coefficients for each fluid, teaching the relationship between viscosity, drag force, and terminal velocity. As noted in the QFEP framing: resistance is information -- the medium tells you what it is made of.

## How It Works

1. Three transparent box columns are created side by side, each tinted to represent air (near-invisible), water (blue), and honey (amber).
2. Identical red emissive balls are placed at the top of each column when the DROP button is pressed.
3. Each frame in `_physics_process`, the simulation calculates:
   - Gravitational force: `F = -g * m` (downward)
   - Quadratic drag: `F = -c * v * |v|` (opposing velocity)
   - Net acceleration applied to update velocity and position
4. Drag coefficients differ per fluid: air = 0.02, water = 0.35, honey = 2.5.
5. Real-time speed readouts beside each column show the current velocity, making the difference in terminal velocity visible as numbers.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `column_height` | float | 1.2 | Height of each fluid column |
| `column_width` | float | 0.25 | Width of each column |
| `ball_radius` | float | 0.03 | Radius of the falling balls |
| `gravity_strength` | float | 9.8 | Gravitational acceleration |
| `ball_mass` | float | 1.0 | Mass of each ball |

## Features

- Three side-by-side fluid columns with labeled names (AIR, WATER, HONEY)
- Quadratic drag model with per-fluid drag coefficients
- Real-time velocity readout labels beside each column
- VR push-button controls for DROP and RESET
- Keyboard fallback: Space to drop, R to reset
- Metallic base plate and billboard labels for clear visibility
- Floor collision stops balls at the bottom

## Files

| File | Description |
|------|-------------|
| `ViscosityLayers.gd` | Complete simulation with columns, balls, drag physics, labels, and VR controls |
