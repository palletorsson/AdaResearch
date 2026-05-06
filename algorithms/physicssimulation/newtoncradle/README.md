# Newton's Cradle

A classic Newton's Cradle simulation that teaches **conservation of momentum, conservation of energy, elastic collisions, and pendulum physics**. Five metallic balls hang from strings attached to a frame. Pull one or more balls back and release them; momentum transfers through the chain and the opposite end swings out, demonstrating that what enters must exit.

## How It Works

1. **Pendulum physics** -- Each ball is modeled as a simple pendulum with angle `theta` and angular velocity `omega`. The angular acceleration is `alpha = -(g/L) * sin(theta)`, integrated with Euler's method each physics frame. A very slight damping factor (0.998) simulates minimal energy loss.

2. **Collision detection** -- Adjacent balls are checked for contact by comparing their angular separation against the angular size of one ball diameter (`2r / L`). When a left ball's angular velocity exceeds its right neighbor's and they are close enough, an **elastic collision** is simulated by swapping their angular velocities (valid for equal masses).

3. **Visual update** -- Each ball's world position is computed from its pivot point and current angle using `sin(theta)` and `cos(theta)`. Strings are oriented to connect each pivot to its ball using `look_at` with a 90-degree rotation.

4. **Energy display** -- A billboard label continuously shows kinetic energy (KE), potential energy (PE), and total energy. KE = 0.5 * m * v^2 where v = omega * L. PE = m * g * h where h = L * (1 - cos(theta)). The total should remain approximately constant, demonstrating energy conservation.

5. **VR controls** -- Push buttons offer presets: 1 BALL (pull left), 2 BALLS (pull two left), BOTH (pull left and right), and RESET (all balls at rest).

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `ball_count` | int | 5 | Number of pendulum balls |
| `ball_radius` | float | 0.12 | Radius of each ball |
| `string_length` | float | 0.6 | Length of each pendulum string |
| `ball_mass` | float | 1.0 | Mass of each ball (used in energy display) |
| `gravity` | float | 9.8 | Gravitational acceleration |
| `damping` | float | 0.998 | Per-frame angular velocity multiplier |
| `frame_color` | Color | dark gray | Color of the top bar and posts |
| `ball_color` | Color | silver | Ball albedo (metallic 0.8, roughness 0.15) |
| `string_color` | Color | gray, semi-transparent | String color |

## Features

- Accurate pendulum physics with `-(g/L) * sin(theta)` angular acceleration.
- Elastic collision via velocity swapping for equal-mass balls.
- Real-time KE, PE, and total energy readout demonstrating conservation laws.
- Metallic ball materials with subtle emission for visual polish.
- Semi-transparent strings that orient from pivot to ball each frame.
- Frame construction with top bar, side posts, and base plate.
- VR push-button presets for different initial conditions.
- Keyboard controls: 1 for single ball, 2 for two balls, 3 for both sides, R to reset.
- `reset()` method returns all balls to the rest position.

## Files

| File | Purpose |
|------|---------|
| `NewtonCradle.gd` | Main script -- pendulum physics, collision, energy tracking, VR controls |
