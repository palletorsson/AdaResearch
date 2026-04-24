# Fractal CrossSequence

Compare fractal methods with noise, CA, L-systems.

Compare fractal dimension vs noise output.

```gdscript
func measure_box_dimension(image: Image, threshold: float) -> float:
    var sizes: Array = [2, 4, 8, 16, 32]
    var counts: Array = []
    for s in sizes:
        counts.append(count_boxes(image, s, threshold))
    return estimate_slope(sizes, counts)
```

Box-counting fractal dimension. Fit a line in log-log space; the slope is the dimension.

Count non-empty boxes.

```gdscript
func count_boxes(image: Image, box_size: int, threshold: float) -> int:
    var count: int = 0
    for y in range(0, image.get_height(), box_size):
        for x in range(0, image.get_width(), box_size):
            var has_content: bool = false
            for dy in box_size:
                for dx in box_size:
                    if image.get_pixel(x + dx, y + dy).v > threshold:
                        has_content = true
                        break
                if has_content: break
            if has_content: count += 1
    return count
```

Grid overlay. Any box with above-threshold pixels counts.

Fit a log-log slope.

```gdscript
func estimate_slope(sizes: Array, counts: Array) -> float:
    var log_sizes: Array = []
    var log_counts: Array = []
    for i in sizes.size():
        log_sizes.append(log(sizes[i]))
        log_counts.append(log(counts[i]))
    return linear_regression_slope(log_sizes, log_counts)
```

Linear fit of log(count) vs log(1/size). Slope is the fractal dimension.

Match matched pairs.

```gdscript
const MATCHED_PAIRS := [
    ["Koch_snowflake", "Noise_octaves_4"],
    ["Sierpinski", "CA_rule_30"],
    ["LSystem_tree", "Noise_turbulence"],
]
```

Hand-curated pairs of fractal-ish patterns from different sequences. The learner can see the visual affinity.

Render side by side.

```gdscript
func render_matched_gallery() -> void:
    for i in MATCHED_PAIRS.size():
        var left_tex := load_texture(MATCHED_PAIRS[i][0])
        var right_tex := load_texture(MATCHED_PAIRS[i][1])
        spawn_comparison_panel(left_tex, right_tex, Vector3(i * 3, 0, 0))
```

Each pair on its own panel. Walking the gallery walks the correspondences.

Compute structural similarity.

```gdscript
func structural_correlation(img_a: Image, img_b: Image) -> float:
    var a_mean: float = image_mean(img_a)
    var b_mean: float = image_mean(img_b)
    var covariance: float = 0.0
    var count: int = 0
    for y in img_a.get_height():
        for x in img_a.get_width():
            covariance += (img_a.get_pixel(x, y).v - a_mean) * (img_b.get_pixel(x, y).v - b_mean)
            count += 1
    return covariance / count
```

Simple covariance. Higher is more similar. Useful for automated comparison.

You can now measure box-counting dimension, fit log-log slopes, render matched-pair galleries, and compute image similarity. The sequence concludes with Chamber_Fractals.

Convert iteration to pixel coordinates.

```gdscript
func complex_to_pixel(c: Vector2, bounds: Rect2, resolution: Vector2i) -> Vector2i:
    return Vector2i(
        int((c.x - bounds.position.x) / bounds.size.x * resolution.x),
        int((c.y - bounds.position.y) / bounds.size.y * resolution.y)
    )
```

Maps math-space to image-space. Inverse of pixel-to-complex used in rendering.
