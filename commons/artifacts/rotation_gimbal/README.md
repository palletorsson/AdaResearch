# Rotation Gimbal

A gimbal lock demonstrator with three nested rotation rings (X, Y, Z) and VR sliders for each Euler angle. Teaches why Euler angles lose a degree of freedom when the pitch axis reaches 90 degrees, and why quaternions are preferred for 3D rotation.

## How It Works

Three concentric torus rings are nested in the classic Euler angle hierarchy: X (pitch, outermost, red), Y (yaw, middle, green), and Z (roll, innermost, blue). Each ring's rotation is controlled by a VR slider mapped to 0-360 degrees. When the Y angle approaches 90 or 270 degrees, the X and Z rings align, collapsing two rotation axes into one. The artifact detects this condition and flashes a "GIMBAL LOCK!" warning while pulsing the affected rings. A live rotation matrix readout shows the combined Rx * Ry * Rz result, and an inner reference box with colored face markers tracks the final orientation.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `ring_radius_outer` | float | `0.28` |
| `ring_radius_mid` | float | `0.22` |
| `ring_radius_inner` | float | `0.16` |
| `ring_tube_radius` | float | `0.008` |
| `gimbal_lock_threshold` | float | `5.0` |

## Features

- Three nested torus rings with axis-colored materials and tick marks
- VR slider panel for independent X, Y, Z angle control
- Real-time gimbal lock detection with flashing warning label
- Live 3x3 rotation matrix display (Rx * Ry * Rz)
- Euler angle readout showing pitch, yaw, and roll in degrees
- Inner reference box with colored face markers and axis arrows
- Reset button to return all angles to zero
- Configurable via `apply_grid_config` (initial angles, lock threshold)

## Files

- `rotation_gimbal.gd` -- Main script
- `rotation_gimbal.tscn` -- Scene file
