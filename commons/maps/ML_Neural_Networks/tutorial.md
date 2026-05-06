# ML Neural Networks

Layers stacked. Each transforms its input.

Build a feedforward network.

```gdscript
class_name FeedforwardNet

var layers: Array = []  # array of layer dicts with W, b, activation

func add_layer(input_size: int, output_size: int, activation: String) -> void:
    var W: Array = init_he(input_size, output_size)
    var b: Array = []
    for _i in output_size: b.append(0.0)
    layers.append({"W": W, "b": b, "activation": activation})
```

Each layer stores a weight matrix and a bias vector. The activation is a string key.

He initialisation.

```gdscript
func init_he(fan_in: int, fan_out: int) -> Array:
    var std: float = sqrt(2.0 / fan_in)
    var W: Array = []
    for _i in fan_out:
        var row: Array = []
        for _j in fan_in:
            row.append(randfn(0.0, std))
        W.append(row)
    return W
```

Scale inversely with fan_in. Prevents vanishing gradients in deep networks with ReLU.

Matrix-vector product.

```gdscript
func matmul(W: Array, x: Array) -> Array:
    var result: Array = []
    for i in W.size():
        var sum: float = 0.0
        for j in x.size():
            sum += W[i][j] * x[j]
        result.append(sum)
    return result
```

Simple nested loop. For production use, GPU-accelerated libraries.

Activation functions.

```gdscript
func activate(v: Array, name: String) -> Array:
    var r: Array = []
    for x in v:
        match name:
            "relu": r.append(max(0.0, x))
            "sigmoid": r.append(1.0 / (1.0 + exp(-x)))
            "tanh": r.append(tanh(x))
            _: r.append(x)
    return r
```

ReLU, sigmoid, tanh are standard. Each has different gradient characteristics.

Forward pass.

```gdscript
func forward(x: Array) -> Array:
    var h: Array = x
    for layer in layers:
        h = matmul(layer.W, h)
        for i in h.size(): h[i] += layer.b[i]
        h = activate(h, layer.activation)
    return h
```

Chain matrix-vector product and activation through each layer. Final output is the network's prediction.

Compute mean-squared error.

```gdscript
func mse_loss(predictions: Array, targets: Array) -> float:
    var sum: float = 0.0
    for i in predictions.size():
        var err: float = predictions[i] - targets[i]
        sum += err * err
    return sum / predictions.size()
```

Standard regression loss. Lower is better.

Backward pass sketch.

```gdscript
func backward(x: Array, target: Array, lr: float) -> void:
    var activations: Array = [x]
    var h: Array = x
    for layer in layers:
        h = matmul(layer.W, h)
        for i in h.size(): h[i] += layer.b[i]
        h = activate(h, layer.activation)
        activations.append(h)
    var delta: Array = []
    for i in h.size(): delta.append(h[i] - target[i])
    for i in range(layers.size() - 1, -1, -1):
        var prev_h: Array = activations[i]
        for out_idx in delta.size():
            for in_idx in prev_h.size():
                layers[i].W[out_idx][in_idx] -= lr * delta[out_idx] * prev_h[in_idx]
            layers[i].b[out_idx] -= lr * delta[out_idx]
        if i > 0:
            var new_delta: Array = []
            for in_idx in prev_h.size():
                var sum: float = 0.0
                for out_idx in delta.size():
                    sum += delta[out_idx] * layers[i].W[out_idx][in_idx]
                new_delta.append(sum)
            delta = new_delta
```

Chain rule through layers. Simplified — assumes MSE and linear output.

You can now build a feedforward network with He initialisation, compute forward passes through arbitrary layers and activations, measure loss, and run a backward pass for training. ML_Perception extends into the single neuron.
