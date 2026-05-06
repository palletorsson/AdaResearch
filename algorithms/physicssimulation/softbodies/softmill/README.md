# Soft Mill

A physics simulation artifact that creates a rotating arm designed to interact with soft bodies. The arm spins continuously around its center, acting as a windmill-like pusher that collides with and deforms nearby soft body objects.

## Concept Taught

**Rotational kinematics and center-of-mass rotation** -- the arm is deliberately centered at the origin so that rotation occurs around the geometric center rather than an endpoint. This teaches the distinction between pivoting at an edge versus spinning from the center, and how collision layers separate pushers from the objects they push.

## How It Works

1. A `StaticBody3D` creates a box-shaped arm mesh centered at `Vector3.ZERO`, ensuring the rotation pivot sits at the arm's midpoint.
2. A visible golden pivot sphere marks the center of rotation with emissive material for visual clarity.
3. The arm's `CollisionShape3D` is also centered, and collision layers are configured so the arm pushes objects (layer 2) without detecting collisions itself (mask 0).
4. In `_physics_process`, the arm rotates continuously around the Z-axis at a configurable speed in degrees per second.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `arm_length` | float | 3.0 | Total length of the rotating arm |
| `arm_thickness` | float | 0.2 | Cross-section thickness of the arm |
| `rotation_speed` | float | 30.0 | Rotation speed in degrees per second |
| `push_force` | float | 10.0 | Force applied to soft bodies on contact |
| `show_pivot` | bool | true | Show the golden pivot sphere at the center |

## Features

- Center-pivot rotation with visible pivot sphere
- Metallic pink arm with configurable material properties
- Separate collision layer setup for one-directional pushing
- Smooth continuous rotation in `_physics_process`

## Files

| File | Description |
|------|-------------|
| `rotating_arm.gd` | StaticBody3D script for the centered rotating arm with pivot visualization |
