# Torus Cylinder

A minimal animated scene pairing a spinning torus with a vertically oscillating cylinder. The artifact teaches **basic 3D transformations in motion** -- continuous rotation around an axis and sinusoidal translation -- as the two simplest building blocks of procedural animation.

## Concept Taught

**Rotation and periodic translation** are the two most fundamental animated transformations. The torus demonstrates constant angular velocity around the Y-axis (`rotation.y += delta * speed`), while the cylinder demonstrates simple harmonic motion along the Y-axis (`sin(time * speed) * range`). Together they show how a static scene becomes dynamic through per-frame transform updates.

## How It Works

1. The scene expects two child `MeshInstance3D` nodes: `TorusMesh` and `CylinderMesh`, plus a `WorldEnvironment` node.
2. Each frame, the torus's Y-rotation is incremented by `delta * 0.5` radians, producing smooth continuous spin.
3. The cylinder's Y-position is set to `sin(time * 1.5) * 3.0`, making it bob up and down with a period of roughly 4 seconds and an amplitude of 3 units.
4. `time_elapsed` accumulates delta to drive the sine function.

## Parameters

This script has no `@export` parameters. Constants are hard-coded:

| Constant | Value | Description |
|----------|-------|-------------|
| Torus rotation speed | `0.5` rad/s | How fast the torus spins |
| Cylinder oscillation speed | `1.5` | Frequency multiplier for the sine wave |
| Cylinder oscillation range | `3.0` | Peak amplitude of the vertical bob |

## Features

- Continuous Y-axis rotation on the torus mesh.
- Sinusoidal vertical oscillation on the cylinder mesh.
- Minimal code demonstrating the core `_process(delta)` animation pattern.
- Scene-tree-based setup using `@onready` node references.

## Files

- `toruscylinder.gd` -- Main script: torus rotation and cylinder oscillation.
- `toruscylinder.tscn` -- Scene file containing TorusMesh, CylinderMesh, and WorldEnvironment nodes.
