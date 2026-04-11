# Branching Growth Algorithm

A real-time space colonization algorithm that grows organic, tree-like branching structures in 3D. This artifact teaches how biological growth patterns emerge from simple rules -- branches extend toward randomly distributed attractor points, creating complex forms reminiscent of coral, trees, and vascular networks.

## How It Works

The algorithm uses the **space colonization** method for procedural branching:

1. **Attractors** are scattered throughout a spherical volume using uniform sphere sampling (cube-root radius distribution for even volume coverage).
2. A single **seed branch** is placed at the origin, pointing upward.
3. Each frame, active branches find the closest unreached attractor within `attraction_distance`.
4. A new branch segment grows toward that attractor, with random jitter and wave-based offsets for organic irregularity.
5. When a branch gets within `min_branch_distance` of an attractor, the attractor is consumed and the branch deactivates.
6. Growth continues until all attractors are reached or `max_branches` is hit.

The result is rendered as an `ImmediateMesh` line primitive with per-vertex coloring. Colors cycle through pride flag palettes (rainbow, trans, lesbian, bi, pan, ace, nonbinary) every 10 seconds, with sparkle effects on young branches and a heartbeat-like brightness pulse.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `max_branches` | int | 100 | Maximum number of branch segments |
| `attraction_distance` | float | 4.0 | How far a branch can "see" an attractor |
| `min_branch_distance` | float | 0.25 | Distance at which an attractor is consumed |
| `growth_distance` | float | 0.2 | Length of each new branch segment |
| `jitter` | float | 0.15 | Random directional noise per step |
| `attractor_count` | int | 80 | Number of attractor points generated |
| `branch_material` | Material | null | Override material (defaults to unshaded vertex-color) |
| `branch_radius` | float | 0.03 | Radius for optional cylinder rendering |
| `growth_per_frame` | int | 8 | Branch steps processed per frame |
| `enable_pride_colors` | bool | true | Toggle pride flag color cycling |
| `enable_sparkles` | bool | true | Toggle sparkle effect on new branches |
| `pulse_strength` | float | 0.3 | Intensity of heartbeat brightness pulse |
| `rainbow_speed` | float | 2.0 | Speed of color cycling |

## Features

- **Space colonization algorithm** -- the standard technique for simulating biological branching growth
- **VR-optimized** -- frame-limited growth, ImmediateMesh line rendering, optional cylinder mode capped at 50 instances
- **Interactive controls** -- keyboard shortcuts for restart (R), pause/resume (P), stats (S), cycle colors (C), toggle sparkles (T), toggle pride colors (Q)
- **VR interaction API** -- `set_vr_start_point()`, `add_attractor_at_position()`, `generate_attractors_around_point()` for controller-driven growth
- **UI panel** (BranchingUI.gd) -- sliders for branch count and attractor count, checkboxes for rainbow/sparkle toggles, live stats display
- **Pride flag palettes** -- seven flag color sets with smooth hue cycling and per-branch random color assignment

## Files

- `branching_growth_algorithm.gd` -- Core space colonization algorithm, Branch/Attractor classes, mesh rendering, VR API
- `BranchingUI.gd` -- Control panel UI for adjusting parameters and viewing live growth statistics
- `BranchingGrowthAlgorithm.tscn` -- Scene file wiring the algorithm node with UI
