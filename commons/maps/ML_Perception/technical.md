# ML Perception — Technical

The map stages the perceptron as a single large interactive unit. Three inputs arrive as coloured arrows; each has an adjustable weight; their weighted sum crosses a threshold; the output is a binary decision.

```gdscript
class_name Perceptron extends Node3D

@export var weights: Array = [0.5, -0.3, 0.2]
@export var threshold: float = 0.0

func predict(inputs: Array) -> int:
    var sum: float = 0.0
    for i in range(weights.size()):
        sum += weights[i] * inputs[i]
    return 1 if sum > threshold else 0
```

## Learning Rule

The perceptron learning rule updates weights when a training example is misclassified. For input x with true label y and prediction ŷ, the update is w_i ← w_i + η(y − ŷ)x_i where η is the learning rate. This is equivalent to stochastic gradient descent on a hinge-like loss.

```gdscript
func train_step(x: Array, y: int, lr: float = 0.1) -> void:
    var pred := predict(x)
    var err := y - pred
    if err != 0:
        for i in range(weights.size()):
            weights[i] += lr * err * x[i]
        threshold -= lr * err
```

The perceptron convergence theorem guarantees that if the data is linearly separable, this rule converges to a separating hyperplane in a finite number of steps. The bound is O(R²/γ²) where R is the maximum input magnitude and γ is the margin of the optimal separator. If the data is not linearly separable, the rule oscillates and never settles — a famous limitation that Minsky and Papert's 1969 book made visible.

## Convolution Station

The second station extends the perceptron into vision. A small pixel grid sits at the top; a convolution window slides across it, computing a weighted sum at each position; the resulting activation map is drawn below.

```gdscript
func convolve(image: Array, kernel: Array) -> Array:
    var h := image.size()
    var w := image[0].size()
    var kh := kernel.size()
    var kw := kernel[0].size()
    var out: Array = []
    for y in range(h - kh + 1):
        var row: Array = []
        for x in range(w - kw + 1):
            var sum := 0.0
            for dy in range(kh):
                for dx in range(kw):
                    sum += image[y + dy][x + dx] * kernel[dy][dx]
            row.append(sum)
        out.append(row)
    return out
```

A filter library lets the learner swap in edge-detection, blur, and sharpening kernels and see the effect on the activation map. Edge detection uses a Sobel kernel; blur uses a Gaussian kernel; sharpening uses a Laplacian-of-Gaussian approximation.

## Complexity

The single-perceptron forward pass is O(N) for N inputs. Convolution of an H×W image with a K×K kernel is O(H·W·K²). Modern CNN implementations use FFT-based convolution or im2col-based matrix multiplication for large kernels; the map's small grid runs at interactive rates on naive convolution.

Within the sequence, Perception makes the atomic mechanism transparent. ML_Sequence_Memory will next add recurrence.

## Pooling and Downsampling

CNNs interleave convolution layers with pooling layers. Max pooling takes the maximum value in each local window; average pooling takes the mean. Pooling reduces spatial resolution and increases the receptive field of subsequent layers.

```gdscript
func max_pool_2x2(image: Array) -> Array:
    var h := image.size()
    var w := image[0].size()
    var out: Array = []
    for y in range(0, h, 2):
        var row: Array = []
        for x in range(0, w, 2):
            var mx: float = -INF
            for dy in range(2):
                for dx in range(2):
                    if y + dy < h and x + dx < w:
                        mx = max(mx, image[y + dy][x + dx])
            row.append(mx)
        out.append(row)
    return out
```

Modern architectures have mostly replaced pooling with strided convolutions, which achieve similar downsampling as a learnable operation rather than a fixed one.

## Receptive Fields

A neuron's receptive field is the region of input it is influenced by. Stacking convolutions expands the receptive field: two stacked 3×3 convolutions cover a 5×5 input region; three stacked cover 7×7. Dilated (atrous) convolutions skip input positions and achieve large receptive fields with few parameters.

## Minsky and Papert

Minsky and Papert's 1969 book *Perceptrons* proved that single-layer perceptrons cannot compute XOR. The proof was taken (incorrectly) as a general argument against neural network research, and funding for connectionist work dried up for a decade. The multilayer perceptron with backpropagation, developed in the 1980s, resolves the limitation — XOR is trivial for a two-layer network — but the history is worth knowing.

The map's single-perceptron station stages Minsky and Papert's argument: place four XOR training examples and the perceptron fails to learn them regardless of how many training steps it runs.
