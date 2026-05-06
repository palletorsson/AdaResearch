# Monte Carlo Dartboard

A visual Monte Carlo simulation that estimates the value of pi by throwing random darts at a square board with an inscribed circle. Darts that land inside the circle are colored green; those outside are colored red. The ratio of inside darts to total darts converges to pi/4, so multiplying by 4 gives an increasingly accurate estimate of pi.

This artifact teaches **Monte Carlo estimation** -- the idea that random sampling, repeated enough times, converges to a true mathematical value. Computation emerges from accumulation.

## How It Works

1. **Board Setup**: A square board of configurable size is placed vertically at eye height. A circle is inscribed within it, drawn as a 64-segment `ImmediateMesh` line loop with a faint filled disc behind it. The board uses a coordinate system from (0,0) to (1,1).

2. **Dart Throwing**: Each dart generates two uniform random numbers `rx, ry` in [0,1]. The point is tested against the inscribed circle centered at (0.5, 0.5) with radius 0.5: if `(rx-0.5)^2 + (ry-0.5)^2 <= 0.25`, the dart is inside.

3. **Pi Estimation**: The estimate is computed as `pi_approx = 4 * (inside_count / total_count)`. This works because the area ratio of the inscribed circle to the square equals pi/4.

4. **Visual Feedback**: Each dart is rendered as a small emissive sphere on the board face. Green for inside, red for outside. Older darts are recycled when the visual count exceeds 300 to maintain performance.

5. **Accuracy Display**: The pi estimate is shown in large text alongside the actual value of pi, the absolute error, and the error percentage. The text color shifts from orange to gold to green as accuracy improves.

6. **Formula Display**: The mathematical relationship `pi/4 = area(circle) / area(square)` is shown below the board for educational context.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `board_size` | float | 0.6 | Width and height of the square board |
| `board_thickness` | float | 0.03 | Thickness of the board |
| `board_height` | float | 1.3 | Height of the board center off ground |
| `dart_radius` | float | 0.005 | Radius of each dart marker sphere |
| `dart_length` | float | 0.08 | (Reserved) length of dart geometry |
| `max_darts` | int | 500 | Maximum number of darts to throw |
| `auto_throw` | bool | true | Whether darts are thrown automatically |
| `darts_per_second` | float | 3.0 | Throw rate when auto-throw is enabled |
| `color_board` | Color | (0.15, 0.15, 0.18) | Board background color |
| `color_circle` | Color | (0.1, 0.15, 0.35) | Inscribed circle fill color |
| `color_inside` | Color | (0.2, 0.9, 0.3) | Green -- dart inside circle |
| `color_outside` | Color | (0.9, 0.25, 0.2) | Red -- dart outside circle |
| `color_pi` | Color | (1.0, 0.85, 0.2) | Gold color for pi display |

## Features

- Real-time Monte Carlo pi estimation with live accuracy tracking
- Color-coded dart markers (green = inside circle, red = outside)
- Inscribed circle drawn as a line loop with faint filled disc
- Large pi estimate display with color-coded accuracy feedback
- Formula explanation shown below the board
- Wooden frame around the board with corner coordinate labels
- VR push-button controls for THROW, AUTO, and RESET
- Keyboard controls: Space (toggle auto), D (throw one), R (reset)
- Automatic dart recycling at 300 visible darts

## Files

| File | Description |
|------|-------------|
| `monte_carlo_dartboard.gd` | Main script -- board, dart physics, pi estimation, VR controls |
| `monte_carlo_dartboard.tscn` | Scene file |
