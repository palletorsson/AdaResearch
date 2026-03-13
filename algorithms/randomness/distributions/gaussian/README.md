# Gaussian Distribution

A collection of four artifacts that visualize the Gaussian (normal) distribution through different lenses: a dot texture that accumulates into a bell curve, a circle that blurs from sharp to soft via CPU-based convolution, a paint splatter that grows outward from a safe zone using Gaussian sampling, and a GPU-accelerated shader blur that smoothly dissolves a circle in real time.

## Concept Taught

**The Gaussian distribution -- the most important distribution in probability and statistics.** The Gaussian (or normal) distribution appears everywhere: measurement error, natural variation, thermal noise, the central limit theorem. These four artifacts explore it from different angles. The texture artifact shows the bell curve forming through accumulation -- thousands of random samples cluster densely at the mean and thin out at the tails. The blur artifacts demonstrate Gaussian convolution -- the mathematical operation that underpins image processing, signal filtering, and the heat equation. The paint splatter shows the Gaussian as a spatial distribution, with the safe zone making the donut-shaped sampling region visible. Together, they teach that the Gaussian is simultaneously a probability density, a convolution kernel, and a description of how information (or heat, or uncertainty) spreads.

## How It Works

### RandomGaussianTexture
1. A blank image (640x240) is created with a yellow background.
2. A timer fires every 0.01 seconds. Each tick, a random X position is sampled from a Gaussian distribution using the Box-Muller transform: `z = sqrt(-2 * ln(u1)) * cos(2*pi*u2)`, then scaled by `mean + stddev * z`.
3. The Y position is randomized uniformly across the image height.
4. A small circular dot (radius 8, very low alpha 0.004) is drawn at that position by blending with existing pixels.
5. Over thousands of dots, the density forms a visible bell curve -- dense at the center, sparse at the edges.

### GaussianBlurCircle
1. A 640x640 image is created with a sharp black circle (radius 200) on a white background.
2. Each frame, the blur radius increases smoothly from 0 to `max_blur_radius` over `blur_duration` seconds, with easing.
3. A separable Gaussian blur is applied: first a horizontal pass, then a vertical pass.
4. The 1D Gaussian kernel is generated analytically: `exp(-i^2 / 2*sigma^2)`, then normalized.
5. The circle gradually dissolves from crisp edges into a soft gradient -- the same visual effect as heat diffusion.

### GaussianPaintSplatter
1. A white canvas (640x640) is created. A timer fires every 0.05 seconds.
2. Each tick, X and Y positions are sampled from independent Gaussian distributions centered on the canvas.
3. Points falling within the `safe_zone_radius` are rejected, creating a donut-shaped splatter pattern.
4. Each dot uses a random color from a five-color palette.
5. Periodically, edge detection scans 360 radial directions to find the boundary between splattered and white regions, then draws an outline mesh from those edge points.
6. An optional visual frame (backplate + border) surrounds the canvas.

### GaussianBlurShader
1. A 512x512 image with a sharp black circle is created as a texture.
2. A custom spatial shader (`gaussian_blur_shader_3d.gdshader`) is loaded and applied.
3. Each frame, the `blur_amount` shader parameter increases from 0 to `max_blur_radius` with exponential easing.
4. The GPU performs the blur in real time -- no CPU image manipulation needed.
5. An optional visual frame surrounds the mesh.

## Parameters

### RandomGaussianTexture

| Constant/Property | Type | Default | Description |
|-------------------|------|---------|-------------|
| `DEFAULT_WIDTH` | int | 640 | Image width |
| `DEFAULT_HEIGHT` | int | 240 | Image height |
| `DOT_RADIUS` | int | 8 | Radius of each sample dot |
| `DOT_ALPHA` | float | 0.004 | Transparency of each dot |
| `stddev` | float | 60.0 | Standard deviation of the Gaussian |
| `update_interval` | float | 0.01 | Seconds between dot placements |
| `vertical_spread` | int | 100 | Vertical randomness range |

### GaussianBlurCircle

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `blur_duration` | float | 10.0 | Seconds from sharp to fully blurred |
| `max_blur_radius` | float | 20.0 | Maximum blur kernel radius |

### GaussianPaintSplatter

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `splatter_width` / `splatter_height` | int | 640 | Canvas dimensions |
| `stddev` | float | 80.0 | Standard deviation for splatter distribution |
| `splatter_update_interval` | float | 0.05 | Seconds between splatter dots |
| `safe_zone_radius` | float | 80.0 | Inner radius where no splatter occurs |
| `dot_radius` | int | 5 | Radius of splatter dots |
| `dot_alpha` | float | 0.6 | Dot transparency |
| `edge_toggle` | bool | true | Show/hide the edge outline |
| `edge_detection_frequency` | int | 50 | Detect edges every N updates |
| `color_palette` | Array[Color] | 5 colors | Red, green, blue, yellow, magenta |

### GaussianBlurShader

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `blur_duration` | float | 10.0 | Animation duration in seconds |
| `max_blur_radius` | float | 40.0 | Maximum shader blur radius |
| `auto_start` | bool | true | Start animation on ready |
| `show_visual_frame` | bool | true | Display decorative frame |

## Features

- Box-Muller transform generates true Gaussian random numbers from uniform samples
- Separable Gaussian blur (horizontal + vertical passes) for efficient CPU convolution
- GPU-accelerated shader blur for real-time performance
- Accumulation-based bell curve visualization builds intuition for probability density
- Paint splatter with safe zone demonstrates Gaussian spatial distribution
- Radial edge detection finds the boundary of splattered regions
- ImmediateMesh outline draws the detected edge as a closed line strip
- Visual frame system auto-detects mesh orientation and adds a decorative border
- Public API on all artifacts: `start()`, `pause()`, `resume()`, `reset()`, plus parameter setters

## Files

| File | Purpose |
|------|---------|
| `random_gaussian_texture.gd` | Accumulating dot texture that forms a bell curve via Box-Muller sampling |
| `gaussian_blur_circle.gd` | CPU-based separable Gaussian blur animating a circle from sharp to soft |
| `GaussianPaintSplatter.gd` | Gaussian-distributed paint splatter with safe zone, edge detection, and visual frame |
| `GaussianBlurShader.gd` | GPU-accelerated Gaussian blur via spatial shader with animated blur amount |
| `gaussian_blur_shader_3d.gdshader` | Spatial shader for GPU-based Gaussian blur |
| `gaussian_blur_shader.gdshader` | Alternative Gaussian blur shader |
| `RandomGaussianTexture.tscn` | Scene file for the dot texture artifact |
| `GaussianBlurCircle.tscn` | Scene file for the CPU blur circle artifact |
| `GaussianPaintSplatter.tscn` | Scene file for the paint splatter artifact |
| `GaussianBlurShader.tscn` | Scene file for the GPU blur shader artifact |
