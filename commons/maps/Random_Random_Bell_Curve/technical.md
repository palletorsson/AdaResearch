# Random_Random_Bell_Curve - Technical Documentation

## Core Concept in Code

### Bell Curve Visualization

```gdscript
extends Node3D

@export var sample_count := 1000
@export var bar_width := 0.1
@export var bin_count := 50
@export var height_scale := 0.01

var rng := RandomNumberGenerator.new()
var bars := []

func _ready():
    rng.randomize()
    generate_histogram()

func generate_histogram():
    var histogram = count_samples()
    create_bars(histogram)

func count_samples() -> Array:
    var counts = []
    counts.resize(bin_count)
    counts.fill(0)

    for i in range(sample_count):
        var value = rng.randfn(0.0, 1.0)
        # Map value from approximately -4σ to +4σ into bins
        var normalized = (value + 4.0) / 8.0
        var bin = int(normalized * bin_count)
        bin = clamp(bin, 0, bin_count - 1)
        counts[bin] += 1

    return counts

func create_bars(histogram: Array):
    for i in range(bin_count):
        var bar = create_bar(i, histogram[i])
        bars.append(bar)
        add_child(bar)

func create_bar(index: int, count: int) -> MeshInstance3D:
    var bar = MeshInstance3D.new()
    var box = BoxMesh.new()

    var height = count * height_scale
    box.size = Vector3(bar_width, height, bar_width)

    bar.mesh = box
    bar.position = Vector3(
        (index - bin_count / 2.0) * bar_width * 1.1,
        height / 2.0,
        0
    )

    return bar
```

### Live Updating Bell Curve

```gdscript
# Animated version that accumulates samples over time
extends Node3D

var histogram := []
var total_samples := 0
var rng := RandomNumberGenerator.new()

func _ready():
    histogram.resize(50)
    histogram.fill(0)
    rng.randomize()

func _process(delta):
    # Add new samples each frame
    for i in range(10):
        add_sample()
    update_visualization()

func add_sample():
    var value = rng.randfn(0.0, 1.0)
    var bin = int((value + 4.0) / 8.0 * histogram.size())
    bin = clamp(bin, 0, histogram.size() - 1)
    histogram[bin] += 1
    total_samples += 1

func update_visualization():
    for i in range(histogram.size()):
        var height = float(histogram[i]) / total_samples * 10.0
        bars[i].scale.y = max(height, 0.01)
        bars[i].position.y = height / 2.0
```

## Implementation Details

### Probability Density Function

The mathematical bell curve (PDF) vs histogram:

```gdscript
# Theoretical Gaussian PDF
func gaussian_pdf(x: float, mean: float, std: float) -> float:
    var coefficient = 1.0 / (std * sqrt(2.0 * PI))
    var exponent = -0.5 * pow((x - mean) / std, 2)
    return coefficient * exp(exponent)

# Draw the theoretical curve alongside histogram
func draw_theoretical_curve():
    var points := PackedVector2Array()
    for i in range(100):
        var x = (i / 100.0 - 0.5) * 8.0  # -4 to +4 sigma
        var y = gaussian_pdf(x, 0.0, 1.0)
        points.append(Vector2(x, y))
    return points
```

### Comparing to Actual Distribution

```gdscript
# Chi-squared test for Gaussian fit
func chi_squared_test(histogram: Array, expected_samples: int) -> float:
    var chi_sq := 0.0
    var bin_width = 8.0 / histogram.size()

    for i in range(histogram.size()):
        var x = (i + 0.5) * bin_width - 4.0
        var expected = expected_samples * gaussian_pdf(x, 0.0, 1.0) * bin_width
        if expected > 0:
            chi_sq += pow(histogram[i] - expected, 2) / expected

    return chi_sq
```

## Map-Specific Configuration

### Structure Analysis
- 13×16 grid with mostly void (height 0)
- Rising walkway from (7,5) at height 1 through (7,6-7) at height 2
- Creates floating platform effect

### Large Boundary Field
`bf:-8.5:-8.5:8.5:8.5:1:2` - The large negative-to-positive range (-8.5 to 8.5) may represent the sigma range of the bell curve: approximately ±4σ captures 99.99% of samples.

### Marker System
`m:-4:7:-4:0.1` - Marker at position -4 with parameters, possibly indicating the -4σ boundary.

## Key Takeaways

1. **Histograms converge to bell curve** - More samples → smoother approximation
2. **Central clustering is mathematical necessity** - CLT guarantees this
3. **Tails are real but rare** - 3σ events happen, 6σ events are extraordinary
4. **PDF vs samples** - Continuous theory vs discrete reality

## Related Systems
- `RandomNumberGenerator.randfn()` - Gaussian sampling
- Histogram nodes for visualization
- Statistical analysis tools
