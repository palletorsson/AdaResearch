# Monte Carlo Dartboard

A visual Monte Carlo simulation that estimates pi using uniformly generated positions on a square board with an inscribed circle. Inside samples are green; outside samples are red. The estimate is `4 * inside / total`. Individual updates can move farther from pi; increasing the budget does not guarantee monotonic improvement.

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

## Optional sample-budget study (P3)

The existing placement in `Randomness_Examples_of_Randomness` selects `lesson:sample_budget`. Unconfigured instances retain the earlier controls. One unit-scale native dial selects 100, 500, 2000 or 8000 samples. Six adjacent rectangular buttons provide THROW, +100, FILL, REPLAY, NEXT SEED and 8 SEEDS. Changing the budget clears and rewinds the same seed. The installed study begins at seed 1847 with 100 samples in a 500-sample budget.

`sample_run.gd` owns a local RNG and all sampled positions; `sample_console.gd` reuses the glitch console's native dial/button construction. Comparison creates separate generators and preserves the active stream. A reset rewinds both counts and RNG. Every sample counts; only the newest 300 marks remain visible. Points are generated, not hand-aimed shots. Engine/build-specific replay is tested; future-engine bitwise identity is not promised.

The [illustrated report](../../../doc/book/iterations/2026-10-09-samples-and-disagreement/index.html) includes a [complete runnable core companion](../../../doc/book/iterations/2026-10-09-samples-and-disagreement/sampler.md). The main hall tutorial is a separate PointBody reconstruction. Core and deliberate-fault checks: `python -X utf8 tools/test_sample_budget.py`. Native museum: `python -X utf8 tools/run_encounter_probe.py Randomness_Examples_of_Randomness --sequence randomness --render --output-tag uncertainty-budget --probe tools/probes/sample_budget_room.gd`. The unique output tag prevents concurrent same-hall probes overwriting receipts.

Validation: 24 core checks; 24 printed-core checks plus eight printed-example assertions; two rejected mutations; 25 native room checks. Desktop pointer and simulated XRTools hold/release pass; physical headset, Quest performance and independent learning remain untested.
