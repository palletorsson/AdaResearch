# Firework Launcher

A particle-system firework display that teaches **particle emission, lifetime management, forces on many bodies, and emergent visual patterns**. A rocket launches upward, reaches a target height, and explodes into dozens of particles that fall under gravity with drag and fading. The artifact includes VR controls for preset selection, manual firing, and burst force adjustment.

## How It Works

1. **Rocket phase** -- A small emissive sphere launches upward with slight horizontal randomness. Light gravity slows its ascent. An optional trail is drawn as a line strip using `ImmediateMesh`. When the rocket reaches its target height, it triggers an explosion.

2. **Explosion** -- The rocket is replaced by `particle_count_per_burst` (default 60) individual particles. Two spread patterns are supported:
   - **Sphere** -- random normalized directions for an omnidirectional burst.
   - **Ring** -- particles distributed around a horizontal circle with slight vertical spread.

   Each particle gets a random speed within 50--100% of `burst_force` and a color picked cyclically from the active preset palette with slight lightness variation.

3. **Particle physics** -- Every frame, particles experience:
   - Gravity pulling downward (`gravity_strength`).
   - Velocity drag (`drag` multiplier, default 0.98).
   - Lifetime countdown; as life expires, the particle fades (alpha), dims (emission), and shrinks.
   - Dead particles (life <= 0) are cleaned up and their meshes freed.

4. **Auto-launch** -- By default, a new firework launches every 2.5 seconds, cycling through presets.

5. **VR controls** -- A control panel with push buttons for four presets (Classic, Ocean, Garden, Ring), a manual FIRE button, and a horizontal slider for burst force.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `particle_count_per_burst` | int | 60 | Particles created per explosion |
| `burst_force` | float | 3.0 | Maximum outward speed (clamped 1--8) |
| `gravity_strength` | float | 2.0 | Downward acceleration |
| `drag` | float | 0.98 | Per-frame velocity damping |
| `particle_lifetime` | float | 3.0 | Seconds before a particle dies |
| `launch_speed` | float | 4.0 | Initial upward velocity of the rocket |
| `launch_height` | float | 1.5 | Target altitude for explosion |
| `trail_enabled` | bool | true | Draw rocket ascent trails |

## Features

- Four color presets: Classic (red/orange/yellow), Ocean (blue/cyan), Garden (green/pink/purple), Ring (orange/red with ring pattern).
- Two spread patterns: sphere (omni) and ring (horizontal circle).
- Trail rendering via `ImmediateMesh` line strips with fading alpha.
- Real-time particle count and rocket count displayed in a billboard label.
- VR push-button preset selection and manual fire.
- Horizontal slider for adjusting burst force in VR.
- Keyboard controls: SPACE to fire, 1--4 for presets, A to toggle auto-launch.
- `reset()` method cleans up all active particles and rockets.

## Files

| File | Purpose |
|------|---------|
| `FireworkLauncher.gd` | Main script -- rocket launch, explosion, particle physics, VR controls |
