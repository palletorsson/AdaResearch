# Control Pendulum

A grabbable VR pendulum that outputs oscillation parameters (position, angular velocity, amplitude) for controlling other artifacts. Teaches simple harmonic motion and how physical interaction maps to continuous control signals.

## How It Works

A rigid rod hangs from a pivot with a grabbable sphere at the bob end (using XR Tools). When the bob is released, simple pendulum physics take over: angular acceleration is computed from gravity and the current angle, with configurable damping. When grabbed, the pendulum tracks the hand position and converts the release velocity into angular momentum. The artifact emits `oscillation_updated` signals containing the current Y offset, angular velocity, and normalized amplitude, which downstream artifacts can use as control inputs.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `pendulum_length` | float | `0.6` |
| `bob_radius` | float | `0.06` |
| `gravity` | float | `9.8` |
| `damping` | float | `0.995` |

## Features

- VR-grabbable bob using XR Tools `grab_sphere_point` scene
- Simple pendulum physics with gravity, damping, and angle clamping
- Velocity tracking during grab for natural release impulse
- Signal output (`oscillation_updated`) for driving other artifacts
- Live label showing swing angle and speed
- Manual API: `grab()`, `release()`, `push()`, `set_angle_from_position()`

## Files

- `control_pendulum.gd` -- Main script
- `control_pendulum.tscn` -- Scene file
