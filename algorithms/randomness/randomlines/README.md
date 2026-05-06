# Random Lines

Self-contained random line segment generator using ImmediateMesh. Supports three spatial distributions (uniform, Gaussian, clustered) and three color modes (solid, golden-ratio rainbow, length gradient) to demonstrate how probability distributions shape geometric configurations.

## Concept Taught

**Random geometric sampling and probability distributions.** Line segments are constructed by sampling two independent random points. Switching between uniform, Gaussian, and clustered distributions shows how the underlying probability distribution dramatically changes the visual density and structure of the result. The length-gradient color mode reveals the statistical distribution of segment lengths.

## How It Works

1. `_ready()` creates an `ImmediateMesh` and generates `num_lines` line segments.
2. Each line's endpoints are sampled according to the selected `distribution`:
   - **Uniform (0):** endpoints uniformly distributed within `area_size`.
   - **Gaussian (1):** endpoints drawn from a centered normal distribution (sigma = area_size/4), clamped to bounds.
   - **Clustered (2):** `cluster_count` random centers are chosen, then endpoints are sampled near a randomly picked center with spread controlled by `cluster_spread`.
3. Colors are assigned per `color_mode`:
   - **Single (0):** all lines use `base_color`.
   - **Rainbow (1):** golden-ratio hue spacing for perceptually distinct colors.
   - **Length gradient (2):** short lines are green (`short_color`), long lines are red (`long_color`).
4. When `animate` is enabled, endpoints drift with random velocities and bounce off the bounding box walls.
5. An optional wireframe bounding box shows the sampling volume.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `num_lines` | int | 40 | Number of line segments |
| `area_size` | Vector3 | (2, 2, 2) | Bounding volume for endpoint sampling |
| `distribution` | int | 0 | 0=uniform, 1=Gaussian, 2=clustered |
| `cluster_count` | int | 3 | Number of cluster centers (distribution=2) |
| `cluster_spread` | float | 0.4 | Gaussian spread around cluster centers |
| `color_mode` | int | 2 | 0=single, 1=rainbow, 2=length gradient |
| `base_color` | Color | light blue | Color for single-color mode |
| `short_color` | Color | green | Short-line color in gradient mode |
| `long_color` | Color | red | Long-line color in gradient mode |
| `animate` | bool | false | Enable drifting endpoint animation |
| `drift_speed` | float | 0.15 | Endpoint drift velocity |
| `show_bounding_box` | bool | true | Draw wireframe bounding box |

## Files

| File | Description |
|------|-------------|
| `randomlines.gd` | Main script: ImmediateMesh line generation, distributions, animation |
| `randomlines.tscn` | Minimal scene wrapping the script |
