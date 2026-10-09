# ML Neural Networks — Technical

The map arranges a neural network as a walkable corridor of chambers. Each chamber is a layer; each narrow passage between chambers is the weighted-sum operation that reduces dimensionality.

A feedforward network is a composition of linear transformations interleaved with nonlinear activations. For input x, weights W_i, biases b_i, and activation φ, the forward pass is a chain of operations that can be written compactly as a sequence of matrix multiplications.

```gdscript
class_name FeedforwardNet extends Node

var layers: Array = []  # each is {W: Array, b: Array, activation: String}

func forward(x: Array) -> Array:
    var h: Array = x
    for layer in layers:
        h = matmul(layer.W, h)
        h = vec_add(h, layer.b)
        h = activate(h, layer.activation)
    return h

func activate(v: Array, name: String) -> Array:
    match name:
        "relu": return v.map(func(x): return max(0.0, x))
        "sigmoid": return v.map(func(x): return 1.0 / (1.0 + exp(-x)))
        "tanh": return v.map(func(x): return tanh(x))
        _: return v
```

## Backpropagation

Training uses backpropagation: compute the loss at the output, then propagate error gradients backward through the network using the chain rule. Each layer's weight gradient is a function of the forward-pass activations it produced and the error signal it received from the next layer.

```gdscript
func backward(x: Array, target: Array) -> Array:
    var activations: Array = [x]
    var h: Array = x
    for layer in layers:
        h = activate(vec_add(matmul(layer.W, h), layer.b), layer.activation)
        activations.append(h)
    var grad: Array = vec_sub(activations[-1], target)  # dL/dh_last
    var weight_grads: Array = []
    for i in range(layers.size() - 1, -1, -1):
        var h_in: Array = activations[i]
        var h_out: Array = activations[i + 1]
        grad = mul_elementwise(grad, activation_derivative(h_out, layers[i].activation))
        weight_grads.push_front(outer_product(grad, h_in))
        grad = matmul(transpose(layers[i].W), grad)
    return weight_grads
```

## Complexity

For a network with L layers of width N, forward pass is O(L·N²). Backward pass is also O(L·N²) — same asymptotic cost, roughly 2× the constant factor. Training a batch of B examples costs O(B·L·N²) per step.

Modern networks use GPU-accelerated matrix multiplication to reduce wall-clock cost. Godot's built-in arrays are unsuitable for serious training; the map's network is small enough to train on CPU at interactive rates, but a production application would use a dedicated tensor library.

## Depth and Expressivity

The universal approximation theorem says a two-layer network with enough hidden units can approximate any continuous function. Deeper networks are more parameter-efficient: they can express the same functions with exponentially fewer parameters for some problem classes. The map lets the learner toggle between 2-layer and 5-layer architectures and see the same classification task trained on each.

Within the sequence, Neural_Networks is where depth earns its keep. ML_Perception will next zoom in on the single neuron.

## Activation Functions

ReLU (rectified linear unit) is the default in modern networks: fast to compute, fast gradient, no saturation for positive inputs. The negative side returns zero, which can cause dead units whose gradient is always zero and whose weights never update. Leaky ReLU and parametric ReLU fix this by allowing a small negative slope.

```gdscript
func leaky_relu(x: float, alpha: float = 0.01) -> float:
    return x if x > 0.0 else alpha * x

func gelu(x: float) -> float:
    # Gaussian Error Linear Unit — used in Transformers
    return 0.5 * x * (1.0 + tanh(sqrt(2.0 / PI) * (x + 0.044715 * x * x * x)))
```

Sigmoid and tanh saturate at their extremes, causing vanishing gradients in deep networks. They remain standard for output layers (sigmoid for binary classification, softmax for multi-class) but are rare in hidden layers of modern networks.

## Weight Initialisation

Naive weight initialisation — random uniform or random normal — produces vanishing or exploding gradients in deep networks. Xavier initialisation scales weights by 1/sqrt(fan_in) to keep variance constant across layers. He initialisation uses 2/sqrt(fan_in) for ReLU networks to compensate for ReLU zeroing half the activations.

```gdscript
func he_init(fan_in: int, fan_out: int) -> Array:
    var std: float = sqrt(2.0 / fan_in)
    var W: Array = []
    for i in range(fan_out):
        var row: Array = []
        for j in range(fan_in):
            row.append(randfn(0.0, std))
        W.append(row)
    return W
```

## Batch Normalisation

BatchNorm normalises activations to zero mean and unit variance within a batch, then applies learnable scale and shift parameters. It accelerates training, enables higher learning rates, and has a mild regularisation effect. The cost is additional parameters and a more complex forward pass, but the benefits usually outweigh the cost for networks deeper than five layers.

Within the sequence, the architectural choices above — activation, initialisation, normalisation — are the implementation details that separate a textbook network from one that actually trains reliably.
