# ML Perception

One neuron. Weighted sum, threshold, output.

Build a perceptron.

```gdscript
class_name Perceptron

var weights: Array = []
var bias: float = 0.0

func initialize(input_size: int) -> void:
    weights.clear()
    for _i in input_size:
        weights.append(randf_range(-0.5, 0.5))
    bias = randf_range(-0.5, 0.5)
```

Random weights in [-0.5, 0.5]. The bias is a constant offset.

Compute the output.

```gdscript
func predict(inputs: Array) -> int:
    var sum: float = bias
    for i in inputs.size():
        sum += weights[i] * inputs[i]
    return 1 if sum > 0 else 0
```

Binary output: positive threshold produces 1, otherwise 0.

Update on a misclassified example.

```gdscript
func train_step(inputs: Array, label: int, lr: float = 0.1) -> void:
    var predicted := predict(inputs)
    var error: int = label - predicted
    if error != 0:
        for i in weights.size():
            weights[i] += lr * error * inputs[i]
        bias += lr * error
```

The perceptron learning rule. Correct classifications don't update; errors nudge the weights.

Run several epochs.

```gdscript
func train(dataset: Array, epochs: int = 50, lr: float = 0.1) -> bool:
    for _e in epochs:
        var errors: int = 0
        for entry in dataset:
            var predicted := predict(entry.inputs)
            if predicted != entry.label:
                train_step(entry.inputs, entry.label, lr)
                errors += 1
        if errors == 0: return true
    return false
```

Converges when all examples are classified correctly. Fails on linearly inseparable data (XOR).

Apply a convolution kernel.

```gdscript
func convolve(image: Array, kernel: Array) -> Array:
    var h := image.size()
    var w := image[0].size()
    var kh := kernel.size()
    var kw := kernel[0].size()
    var out: Array = []
    for y in h - kh + 1:
        out.append([])
        for x in w - kw + 1:
            var sum: float = 0.0
            for dy in kh:
                for dx in kw:
                    sum += image[y + dy][x + dx] * kernel[dy][dx]
            out[y].append(sum)
    return out
```

Slide the kernel across the image. Each output pixel is a weighted sum of a local window.

Edge-detection kernel.

```gdscript
const SOBEL_X := [
    [-1, 0, 1],
    [-2, 0, 2],
    [-1, 0, 1],
]

const SOBEL_Y := [
    [-1, -2, -1],
    [0, 0, 0],
    [1, 2, 1],
]
```

Sobel filters detect horizontal and vertical edges. Combining the two gives edge magnitude.

Compute edge magnitude.

```gdscript
func edge_magnitude(image: Array) -> Array:
    var gx := convolve(image, SOBEL_X)
    var gy := convolve(image, SOBEL_Y)
    var mag: Array = []
    for y in gx.size():
        mag.append([])
        for x in gx[0].size():
            mag[y].append(sqrt(gx[y][x] * gx[y][x] + gy[y][x] * gy[y][x]))
    return mag
```

Pythagorean combination. The result is a single edge-strength image.

You can now build a perceptron with training, convolve an image with a kernel, and detect edges with Sobel filters. ML_Sequence_Memory extends into recurrent networks.
