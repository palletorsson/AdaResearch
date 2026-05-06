# Slingshot Launcher

A player catapult platform that teaches **impulse, projectile motion, Newton's third law, and trajectory prediction**. Step onto the platform, watch it charge, and get launched into the air along a configurable parabolic arc. The artifact also fires colored demo balls so the physics is visible even without a player, and it displays a real-time trajectory preview curve.

## How It Works

1. **Platform detection** -- An `Area3D` with a cylinder collision shape sits atop the catapult arm. When a body in the "player" group enters, the launcher transitions from IDLE to CHARGING.

2. **Charge phase** -- `_charge_progress` increases linearly over `charge_time` seconds. The platform and a surrounding torus charge ring interpolate from `platform_color` (blue) to `charged_color` (orange), with emission intensity ramping up quadratically. When charge reaches 100%, the launcher fires.

3. **Launch** -- The launch velocity is computed as `Vector3(0, sin(angle), -cos(angle)) * launch_force`. The script attempts to apply this to the player via `set_velocity()`, `linear_velocity`, `apply_impulse()`, or a tween fallback. Simultaneously, three colored `RigidBody3D` demo balls are spawned with slight horizontal spread to visualize the projectile arc. Each ball self-destructs after 8 seconds.

4. **Trajectory preview** -- An `ImmediateMesh` line strip traces the predicted parabolic path using the kinematic equations `y = y0 + vy*t - 0.5*g*t^2` and `z = -vx*t`. The preview updates whenever the power or angle sliders change.

5. **Launch arrow** -- A cone-and-cylinder arrow mounted on the arm pivot shows the launch direction. It re-orients whenever the angle changes.

6. **VR controls** -- A side-mounted control panel provides:
   - A LAUNCH button for manual firing.
   - A POWER slider controlling `launch_force` (5--40).
   - An ANGLE slider controlling `launch_angle_deg` (15--85 degrees).

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `launch_force` | float | 18.0 | Launch speed magnitude (clamped 5--40) |
| `launch_angle_deg` | float | 60.0 | Launch elevation angle (clamped 15--85) |
| `charge_time` | float | 2.0 | Seconds to fully charge |
| `platform_radius` | float | 0.5 | Radius of the standing platform |
| `platform_height` | float | 0.08 | Thickness of the platform disc |
| `arm_length` | float | 1.2 | Length of the catapult arm |
| `base_color` | Color | dark gray | Base block color |
| `platform_color` | Color | blue | Uncharged platform color |
| `charged_color` | Color | orange | Fully charged color |
| `arm_color` | Color | light gray | Catapult arm color |

## Features

- State machine: IDLE, CHARGING, READY, LAUNCHING.
- Automatic charge-on-step with visual feedback (color lerp + emission ramp).
- Parabolic trajectory preview via kinematic equations.
- Directional launch arrow that updates with angle changes.
- Demo ball spawning with RigidBody3D physics for visible projectile motion.
- Multiple player detection strategies (group, name, method).
- VR push button and dual slider controls for power and angle.
- Keyboard controls: SPACE to fire, UP/DOWN to adjust force.
- `reset()` method returns to idle state.

## Files

| File | Purpose |
|------|---------|
| `SlingshotLauncher.gd` | Main script -- charge mechanics, launch physics, trajectory preview, VR controls |
