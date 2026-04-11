# Friction Ramp

Demonstrates the physics of static and kinetic friction on an inclined plane, showing how a block slides or sticks based on the balance between gravitational pull (mg*sin(theta)) and friction force (mu*mg*cos(theta)).

## How It Works

The artifact computes whether the block slides by comparing tan(theta) against the friction coefficient mu. When tan(theta) exceeds mu, the block accelerates down the slope at a = g*(sin(theta) - mu*cos(theta)). Force arrows are drawn each frame using ImmediateMesh: yellow for gravity, green for the normal force, orange for friction, and pink for the net force along the slope. VR sliders let users adjust the friction coefficient and ramp angle in real time, immediately updating the sliding condition and force diagram.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `ramp_length` | float | `0.5` |
| `ramp_width` | float | `0.2` |
| `ramp_angle_deg` | float | `30.0` |
| `friction_mu` | float | `0.5` |
| `block_size` | Vector3 | `(0.04, 0.03, 0.04)` |

## Features

- Real-time sliding/static state detection with color-coded block
- Four force arrows: gravity, normal, friction, and net force
- VR control panel with friction coefficient slider, angle slider, and reset button
- Block resets automatically when it reaches the bottom of the ramp
- Live display of theta, mu, force magnitudes, acceleration, and velocity

## Files

- `friction_ramp.gd` -- Main script
- `friction_ramp.tscn` -- Scene file
