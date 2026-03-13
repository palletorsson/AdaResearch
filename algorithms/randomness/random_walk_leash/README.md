# Random Walk Leash

A VR-interactive artifact where the learner physically holds a glowing orb on a leash while it tugs in random directions. The orb performs a 3D random walk, and the learner feels the stochastic impulses through their VR controller. A trailing path and live statistics make the mathematical properties of random walks visible and tangible.

## Concept Taught

A random walk is one of the most fundamental concepts in probability theory and stochastic processes. This artifact embodies the random walk literally -- instead of watching a dot move on a screen, the learner holds the walking object and feels each random impulse through their hand. The statistics panel shows that net displacement grows proportionally to the square root of the number of steps (drift ~ sqrt(N)), the defining property of a random walk. This connects to Brownian motion, diffusion, stock price models, and polymer physics.

## How It Works

1. **Pedestal** -- A cylindrical `StaticBody3D` with a torus cradle on top provides a rest point for the orb when not held.
2. **Orb (VR grabbable)** -- An `XRToolsPickable` rigid body with a glowing sphere mesh, inner glow core, and highlight ring. The orb has low gravity (0.3 scale), linear damping (1.5), and angular damping (2.0) to keep motion responsive but not chaotic.
3. **Random impulses** -- Every `impulse_interval` seconds (default 0.3s), a random 3D unit vector (optionally biased upward by `walk_bias`) is generated and applied as an impulse of strength `impulse_strength` (default 0.04). The orb pulses brighter on each tug via a tween on emission energy.
4. **Leash constraint** -- When the orb is held, a soft constraint pulls it back if it drifts beyond `leash_length` from its spawn point, simulating a physical tether.
5. **Leash visual** -- An `ImmediateMesh` line connects the pedestal top to the orb's current position, rendered with a translucent emissive material.
6. **Trail** -- Up to 200 recent orb positions are recorded and rendered as a `PRIMITIVE_LINE_STRIP`, creating a visible trace of the random walk path.
7. **Statistics display** -- A `Label3D` shows:
   - Total number of tugs (steps)
   - Net drift (displacement magnitude)
   - RMS displacement (drift / sqrt(N))
   - The theoretical relationship: drift ~ sqrt(N)
8. **VR controls** -- A push button labeled "RESET" returns the orb to its starting position and clears all statistics.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `orb_radius` | float | 0.05 | Radius of the glowing orb |
| `orb_mass` | float | 0.15 | Mass of the orb rigid body |
| `orb_color` | Color | (0.3, 0.8, 1.0) | Color of the orb and its emission |
| `orb_emission_energy` | float | 1.5 | Base emission energy |
| `leash_length` | float | 0.4 | Maximum distance from spawn before pull-back |
| `leash_segments` | int | 8 | (Reserved) Number of leash line segments |
| `leash_color` | Color | (0.6, 0.7, 0.9, 0.7) | Color of the leash line |
| `impulse_interval` | float | 0.3 | Seconds between random tugs |
| `impulse_strength` | float | 0.04 | Force magnitude per tug |
| `walk_bias` | float | 0.0 | Upward bias on impulse direction (0 = unbiased) |
| `pedestal_height` | float | 0.9 | Height of the display pedestal |
| `pedestal_color` | Color | (0.1, 0.1, 0.12) | Pedestal material color |

## Features

- VR-grabbable orb with XRTools pickable integration
- Embodied random walk -- feel stochastic impulses through the controller
- Glowing orb with inner core and emission pulse on each tug
- Leash constraint prevents the orb from flying away
- Visual trail of the random walk path (up to 200 points)
- Live statistics: tug count, net drift, RMS displacement
- Theoretical annotation: drift ~ sqrt(N)
- Reset button to restart the experiment
- Works in both VR and desktop modes

## Files

| File | Description |
|------|-------------|
| `random_walk_leash.gd` | Main script -- orb creation, random impulses, trail, statistics, VR controls |
| `random_walk_leash.tscn` | Scene file |
