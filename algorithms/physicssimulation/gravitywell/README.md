# Gravity Well

A rubber-sheet gravity visualization that teaches **general relativity's curvature metaphor, gradient-driven motion, and orbital mechanics**. A deformable grid mesh warps around a movable mass point, and colored particles roll along the curved surface toward the depression -- the classic "bowling ball on a trampoline" demonstration of how mass tells space how to curve.

## How It Works

1. **Grid mesh** -- A square grid of configurable resolution is built using `SurfaceTool`. Each vertex's Y coordinate is computed by a Gaussian well function centered on the mass position: `y = -depth * strength * exp(-dist^2 / radius^2)`. Vertex colors shift from the base sheet color to deep blue as depth increases, giving an immediate visual reading of curvature.

2. **Mass marker** -- A glowing sphere sits at the bottom of the well, visually anchoring the gravitational source. Its position updates whenever the mass is moved.

3. **Particle dynamics** -- Six particles (each a unique hue) are placed on the sheet with tangential initial velocities for orbiting. Each frame:
   - The surface gradient is computed numerically via central finite differences.
   - The gradient acts as acceleration (ball rolls downhill).
   - Velocity is damped slightly (0.995) to prevent unbounded energy growth.
   - Particles bounce off grid edges with energy loss.
   - Each particle's Y coordinate is set to the surface height at its XZ position, keeping it on the sheet.

4. **VR controls** -- A control panel offers a SCATTER button (randomize particle positions), a CENTER button (reset mass to origin), and a MASS slider that adjusts `mass_strength` from 0.1 to 3.0, which triggers a full mesh rebuild.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `grid_size` | float | 1.0 | Side length of the square grid |
| `grid_resolution` | int | 24 | Number of subdivisions per side |
| `well_depth` | float | 0.3 | Maximum depression depth |
| `well_radius` | float | 0.25 | Gaussian falloff radius |
| `mass_strength` | float | 1.0 | Multiplier on well depth (clamped 0.1--3.0) |
| `particle_count` | int | 6 | Number of rolling particles |
| `sheet_color` | Color | blue, semi-transparent | Base grid color |
| `mass_color` | Color | yellow | Mass marker color |
| `particle_color` | Color | red | Fallback particle color (overridden by hue) |

## Features

- Gaussian well deformation with real-time mesh rebuilding when mass strength changes.
- Depth-based vertex coloring for intuitive curvature visualization.
- Numerical gradient computation for physics-driven particle motion.
- Tangential initial velocities produce natural orbiting behavior.
- Edge-bounce with energy loss keeps particles on the sheet.
- Double-sided transparent material so the sheet is visible from below.
- VR push buttons for scatter and center, plus a mass strength slider.
- Keyboard controls: SPACE to scatter, R to reset, UP/DOWN to adjust mass.
- `reset()` method returns to default state.

## Files

| File | Purpose |
|------|---------|
| `GravityWell.gd` | Main script -- grid generation, well physics, particle dynamics, VR controls |
