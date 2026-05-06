# Torso Estimation Visualizer

Visual demonstration of 3-point torso estimation, showing how head and two hand positions can infer torso orientation. Three tracking spheres orbit while a torso wireframe responds in real time.

## How It Works

Animated head and hand markers follow independent oscillation paths. A blending algorithm combines head forward direction with hand midpoint direction (weighted by `head_weight`) to estimate the torso's facing angle. The torso capsule, shoulder markers, forward arrow, and connection lines all update each physics frame based on the estimated orientation.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `shoulder_width` | float | 0.36 |
| `neck_offset` | float | 0.15 |
| `head_weight` | float | 0.7 |

## Features

- Procedurally built geometry (spheres, capsule, cylinders) with emissive materials
- Real-time 3-point torso estimation algorithm matching the production TorsoEstimator
- Animated head yaw and independent hand swing arcs
- Color-coded markers: blue head, orange hands, yellow shoulders, green forward arrow
- Translucent connection lines between head-to-hands and shoulder span
- Supports `apply_grid_config()` for grid system integration

## Files

- `torso_estimation_vis.gd` -- Procedural visualization with torso estimation algorithm
- `torso_estimation_vis.tscn` -- Scene file
