# Oscillation Driver Algorithms

Wave function and oscillation-based visualization algorithms demonstrating mathematical patterns, chaos theory, and harmonic motion.

## Scenes

### Core Oscillators

| Scene | Description |
|-------|-------------|
| `OscillationDriver.tscn` | Base oscillation visualization |
| `OscillationCurve.tscn` | Parametric curve generator |
| `UnitCircleTrig.tscn` | Unit circle trigonometry demo |
| `TrigWalkingPath.tscn` | Walking path using trig functions |

### Pendulum Systems

| Scene | Description |
|-------|-------------|
| `DoublePendulum.tscn` | Single double pendulum with chaos visualization |
| `PendulumGrid3x3.tscn` | **3x3 grid of pendulums painting on shared canvas** |
| `PendulumWave.tscn` | Wave of pendulums showing phase relationships |
| `PendulumCircle.tscn` | Circular pendulum arrangement |

### Spirals & Curves

| Scene | Description |
|-------|-------------|
| `CircleSpiral.tscn` | Expanding spiral pattern |
| `DoubleHelix.tscn` | DNA-style double helix |
| `Lissajous3D.tscn` | 3D Lissajous figure from phase-shifted oscillations |

---

## DoublePendulum

A **double pendulum** demonstrates **chaos theory** - sensitive dependence on initial conditions. Small changes in starting angles lead to dramatically different trajectories.

### Physics

The system uses Lagrangian mechanics to compute angular accelerations:
- `theta1`, `theta2` - angles of upper and lower pendulum arms
- `omega1`, `omega2` - angular velocities
- `l1`, `l2` - arm lengths
- `m1`, `m2` - bob masses

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `theta1_start` | 90° | Initial angle of upper arm |
| `theta2_start` | 90° | Initial angle of lower arm |
| `m1`, `m2` | 10.0 | Bob masses |
| `l1`, `l2` | 1.5 | Arm lengths |
| `damping` | 0.0 | Energy loss per frame |

### Drawing

The second bob has a `RayCast3D` that detects a `DrawingCanvas` and calls `draw_at_world_position()` to paint with color-cycling hue.

---

## PendulumGrid3x3

Creates **9 smaller double pendulums** arranged in a 3x3 grid, all painting on a shared large canvas behind them.

### Features

- **Scaled pendulums** - 35% of original size
- **Varied initial conditions** - Slight angle differences for chaotic diversity
- **Shared canvas** - 5.4m × 5.4m canvas captures all pendulum traces
- **Individual trails** - Each pendulum draws its own chaotic path

### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `grid_size` | 3 | Grid dimensions (3 = 3x3) |
| `cell_size` | 1.8m | Size of each grid cell |
| `pendulum_scale` | 0.35 | Scale factor for pendulums |
| `base_theta1/2` | 90° | Base starting angles |
| `angle_variation` | 8° | Variation added per pendulum |

### Grid Layout

Looking from camera:
```
[0,0] [1,0] [2,0]
[0,1] [1,1] [2,1]
[0,2] [1,2] [2,2]
```

Each pendulum has slightly different initial angles, causing them to diverge chaotically over time while painting unique patterns.

---

## Usage

1. Open any `.tscn` scene in Godot
2. Run the scene (F6)
3. Watch the oscillations and generated patterns
4. Adjust `@export` parameters in the Inspector for variations
