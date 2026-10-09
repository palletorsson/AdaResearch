# ML Sequence Memory

Recurrent network. The hidden state carries the past forward.

Build a simple RNN cell.

```gdscript
class_name RNNCell

var W_xh: Array
var W_hh: Array
var W_hy: Array
var h: Array

func step(x: Array) -> Array:
    var pre_activation: Array = []
    for i in h.size():
        var sum: float = 0.0
        for j in x.size(): sum += W_xh[i][j] * x[j]
        for j in h.size(): sum += W_hh[i][j] * h[j]
        pre_activation.append(sum)
    var h_new: Array = []
    for v in pre_activation: h_new.append(tanh(v))
    h = h_new
    var y: Array = []
    for i in W_hy.size():
        var sum: float = 0.0
        for j in h.size(): sum += W_hy[i][j] * h[j]
        y.append(sum)
    return y
```

Three weight matrices: input-to-hidden, hidden-to-hidden, hidden-to-output. The state h carries forward.

Build an LSTM cell.

```gdscript
class_name LSTMCell

var W_f: Array; var b_f: Array  # forget gate
var W_i: Array; var b_i: Array  # input gate
var W_o: Array; var b_o: Array  # output gate
var W_g: Array; var b_g: Array  # candidate
var h: Array
var c: Array

func step(x: Array) -> Array:
    var combined := concat(x, h)
    var f := sigmoid_vector(add_bias(matmul_vec(W_f, combined), b_f))
    var i := sigmoid_vector(add_bias(matmul_vec(W_i, combined), b_i))
    var o := sigmoid_vector(add_bias(matmul_vec(W_o, combined), b_o))
    var g := tanh_vector(add_bias(matmul_vec(W_g, combined), b_g))
    c = add_element(multiply_element(f, c), multiply_element(i, g))
    h = multiply_element(o, tanh_vector(c))
    return h
```

Three gates control the cell state. Forget drops information; input adds; output reads.

Concatenate vectors.

```gdscript
func concat(a: Array, b: Array) -> Array:
    var result: Array = []
    for x in a: result.append(x)
    for x in b: result.append(x)
    return result
```

Side-by-side. Used wherever two inputs must be combined into one.

Process a sequence.

```gdscript
func process_sequence(sequence: Array) -> Array:
    var outputs: Array = []
    for x in sequence:
        outputs.append(step(x))
    return outputs
```

One step per input. The outputs together form the network's response.

Detect vanishing gradient.

```gdscript
func measure_gradient_over_time(sequence: Array) -> Array:
    var gradients: Array = []
    for t in sequence.size():
        var g: float = gradient_at_timestep(t, sequence)
        gradients.append(g)
    return gradients
```

Trace how much influence each earlier input has on the final output. Decays exponentially in vanilla RNNs; much slower in LSTMs.

Teacher forcing.

```gdscript
func train_with_teacher_forcing(inputs: Array, targets: Array) -> void:
    for t in inputs.size():
        step(inputs[t])
        var target: Array = targets[t]
        # Use target rather than prediction as next input
```

During training, the model always sees the true previous token. Stabilises training; creates an inference-time discrepancy.

You can now build RNN and LSTM cells, process sequences, measure gradient decay, and train with teacher forcing. ML_Generative extends into models that produce new data.
