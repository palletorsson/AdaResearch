# Galton Board

A physics-driven Galton Board simulation that demonstrates the **Central Limit Theorem** (CLT). Balls drop through a triangular array of pegs, bouncing left or right with equal probability at each row. After passing through all peg rows, balls accumulate in bins at the bottom, forming a distribution that converges toward a Gaussian (bell curve) as the number of trials increases.

This artifact teaches that many independent binary choices -- each individually random -- combine to produce predictable, structured outcomes. Order emerges from repetition.

## How It Works

1. **Peg Array**: A triangular grid of pegs is arranged so that row `n` has `n + 1` pegs. Each row is spaced using equilateral triangle geometry (`sqrt(3)/2` vertical spacing). When a ball hits a peg, it deflects left or right with roughly equal probability.

2. **Ball Physics**: Balls are Godot `RigidBody3D` objects with continuous collision detection. A ball pool pre-allocates up to `max_active_balls` instances, recycling them after they land in a bin. Balls enter through a funnel at the top with a slight random horizontal jitter.

3. **Bin Counting**: `Area3D` sensors at the bottom of each bin detect when a ball enters. Each ball is counted exactly once using instance ID tracking. The bin count array drives the histogram bar heights.

4. **Bell Curve Overlay**: Once at least 5 balls have been dropped, the artifact computes the empirical mean and standard deviation from the bin counts, then draws a theoretical Gaussian curve using `ImmediateMesh`. The overlay lets the viewer compare the actual histogram with the predicted distribution.

5. **Statistics Display**: A live readout shows the sample size `n`, empirical mean, empirical standard deviation, and the theoretical values from the binomial distribution `B(peg_rows, 0.5)`.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `board_width` | float | 0.5 | Total width of the board frame |
| `board_height` | float | 0.55 | Height of the peg section |
| `board_depth` | float | 0.06 | Depth (front-to-back) of the board enclosure |
| `peg_rows` | int | 8 | Number of peg rows (bins = peg_rows + 1) |
| `peg_radius` | float | 0.007 | Radius of each peg cylinder |
| `peg_spacing` | float | 0.048 | Horizontal distance between adjacent pegs |
| `ball_radius` | float | 0.009 | Radius of each ball |
| `ball_mass` | float | 0.04 | Mass of each ball |
| `ball_bounce` | float | 0.3 | Bounciness (restitution) of balls |
| `balls_per_second` | float | 2.0 | Drop rate when auto-drop is enabled |
| `max_active_balls` | int | 50 | Size of the ball pool |
| `bin_height` | float | 0.18 | Height of bin dividers |
| `num_bins` | int | 9 | Number of collection bins (auto-set to peg_rows + 1) |
| `color_peg` | Color | (0.7, 0.75, 0.85) | Peg color |
| `color_ball` | Color | (1.0, 0.8, 0.2) | Ball color |
| `color_bin_bar` | Color | (0.3, 0.7, 1.0) | Histogram bar color |
| `color_bell_curve` | Color | (1.0, 0.4, 0.2, 0.8) | Gaussian overlay color |
| `auto_drop` | bool | true | Whether balls drop automatically |

## Features

- Physics-based simulation using Godot's rigid body system with proper collision layers
- Ball pool with automatic recycling to maintain performance
- Real-time histogram bars that grow proportionally to bin counts
- Gaussian bell curve overlay computed from empirical mean and variance
- Live statistics comparing observed vs. theoretical binomial parameters
- VR-ready control panel with DROP, AUTO, RESET, and SPEED buttons
- Keyboard controls: Space (toggle auto), R (reset), D (drop one)
- Speed cycling through 2, 5, 10, and 20 balls per second
- Glass front panel and back panel with collision walls to contain balls
- Funnel at the top guides balls to the center entry point

## Files

| File | Description |
|------|-------------|
| `galton_board.gd` | Main script -- physics, pegs, bins, statistics, VR controls |
| `galton_board.tscn` | Scene file |
