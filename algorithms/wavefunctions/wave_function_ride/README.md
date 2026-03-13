# Wave Function Ride

A VR ride artifact that teaches **elliptical orbit kinematics** and **parametric motion** by letting the player grab a stick that follows an oval track through space. The stick moves along a mathematically defined ellipse, transporting the player via XR origin manipulation -- a physical demonstration of how `cos` and `sin` define elliptical paths.

## How It Works

The ride stick extends `XRToolsPickable` (a VR-grabbable rigid body). On scene start, it calculates its orbital centre from its initial position and a starting angle, then generates a visible oval track using `ImmediateMesh` line segments.

The elliptical path is defined as:
- `x = cos(angle) * radius_x`
- `z = sin(angle) * radius_z`

where `angle` advances by `speed * delta` each physics frame.

When the player picks up the stick, the ride activates:
1. The stick's collision is disabled to prevent physics conflicts.
2. A `PlayerBody` reference is found and its physics are disabled (seat mode).
3. Each frame, the system computes the **delta movement** between the current and previous track positions.
4. The stick is teleported to the new track position.
5. The same delta is applied to the XR origin, transporting the player smoothly along the track without physics jitter.

A **magic carpet** (invisible `AnimatableBody3D` with a cylinder collider) hovers 1.2 m below the stick, providing a floor for the player's feet so they do not fall through during the ride. A vertical hanger cylinder visually connects the stick to the overhead track.

When dropped, collision is restored, player body physics are re-enabled, and the ride pauses.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `speed` | float | 0.5 | Angular velocity in radians per second |
| `radius_x` | float | 15.0 | Semi-major axis of the ellipse |
| `radius_z` | float | 8.0 | Semi-minor axis of the ellipse |
| `track_height_offset` | float | 2.0 | Height of the visible track above the stick |
| `start_delay` | float | 5.0 | Wait time before movement begins |
| `draw_track` | bool | true | Render the oval track line |

## Features

- Elliptical parametric motion with configurable radii
- XR origin transport for smooth VR player movement
- Delta-based movement to avoid accumulated position drift
- Magic carpet floor collider for player foot support
- Visible track rendered as an ImmediateMesh oval
- Hanger rod connecting stick to overhead track
- Player body physics suppression during ride (seat mode)
- Collision layer toggling on pick-up and drop
- `@tool` support for editor preview
- Frozen kinematic rigid body configuration

## Files

| File | Description |
|------|-------------|
| `RideStick.gd` | VR-grabbable ride stick with elliptical motion, XR transport, and magic carpet |
| `RideStick.tscn` | Scene file for the ride stick pickable |
| `WaveRideScene.tscn` | Full ride scene assembly |
