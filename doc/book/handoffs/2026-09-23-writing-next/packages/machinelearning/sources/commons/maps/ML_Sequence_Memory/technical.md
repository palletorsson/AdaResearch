# ML Sequence Memory — Technical

The map stages recurrence — the practice of feeding a network's hidden state back into its own input at the next step — as a corridor whose narrow passages enforce sequential processing.

A vanilla RNN has one set of weights applied at every time step. The hidden state h_t depends on the current input x_t and the previous hidden state h_{t-1} through a shared transformation.

```gdscript
class_name VanillaRNN extends Node

var W_xh: Array  # input to hidden
var W_hh: Array  # hidden to hidden
var W_hy: Array  # hidden to output
var h: Array    # current hidden state

func step(x: Array) -> Array:
    var h_new: Array = vec_add(matmul(W_xh, x), matmul(W_hh, h))
    h_new = h_new.map(func(v): return tanh(v))
    h = h_new
    var y: Array = matmul(W_hy, h)
    return y
```

## Vanishing Gradient

Training RNNs by backpropagation through time unrolls the recurrence into a deep feedforward network (one layer per time step) and applies standard backprop. The gradient at step t-T depends on the product of T Jacobians, each of which has spectral radius typically less than 1. The product decays exponentially, so gradients from distant past steps become negligibly small.

The map's diagnostic panel traces the influence of each input token on the final output. The trace decays as inputs recede into the past; by ten steps back, the influence is nearly zero.

## LSTM

The LSTM cell introduces gated memory. Three gates — forget, input, output — and a cell state c_t let the network preserve information across many time steps without gradient decay.

```gdscript
func lstm_step(x: Array) -> Array:
    var f: Array = sigmoid(vec_add(matmul(W_f, concat(x, h)), b_f))
    var i: Array = sigmoid(vec_add(matmul(W_i, concat(x, h)), b_i))
    var o: Array = sigmoid(vec_add(matmul(W_o, concat(x, h)), b_o))
    var g: Array = tanh(vec_add(matmul(W_g, concat(x, h)), b_g))
    c = vec_add(mul_elementwise(f, c), mul_elementwise(i, g))
    h = mul_elementwise(o, tanh(c))
    return h
```

The forget gate controls how much of the previous cell state is retained; the input gate controls how much new information enters; the output gate controls how much of the cell state is exposed as the hidden state. The architecture was introduced by Hochreiter and Schmidhuber in 1997 and remains competitive for sequence tasks where attention-based models have excessive data requirements.

## Complexity

Per-step cost is O(N²) for N hidden units (one matrix multiply per weight matrix). Training over T steps is O(T·N²) forward and O(T·N²) backward. LSTM adds a constant factor (~4× for the four gates) but the asymptotic cost is unchanged.

Within the sequence, Sequence_Memory introduces the temporal dimension. ML_Generative will next build generation on top of it.

## GRU as Simplification

The Gated Recurrent Unit (GRU) is a simpler alternative to LSTM, with two gates (update and reset) instead of three, and a single state vector instead of separate cell and hidden states. It often matches LSTM performance with fewer parameters.

```gdscript
func gru_step(x: Array) -> Array:
    var z: Array = sigmoid(vec_add(matmul(W_z, concat(x, h)), b_z))  # update gate
    var r: Array = sigmoid(vec_add(matmul(W_r, concat(x, h)), b_r))  # reset gate
    var h_tilde: Array = tanh(vec_add(matmul(W_h, concat(x, mul_elementwise(r, h))), b_h))
    h = vec_add(mul_elementwise(vec_sub(ones(h.size()), z), h), mul_elementwise(z, h_tilde))
    return h
```

## Attention

Transformer architectures replaced RNNs for most sequence tasks. Attention lets each position in the output attend to all positions in the input simultaneously, removing the sequential bottleneck that RNNs enforce. The scaled dot-product attention is the core operation.

```gdscript
func scaled_dot_product_attention(Q: Array, K: Array, V: Array) -> Array:
    var d_k: int = K[0].size()
    var scores: Array = matmul(Q, transpose(K))
    for i in range(scores.size()):
        for j in range(scores[i].size()):
            scores[i][j] /= sqrt(d_k)
    var weights: Array = softmax(scores)
    return matmul(weights, V)
```

Transformers are dramatically more parallelisable than RNNs because they process all positions at once. The cost is quadratic in sequence length — attention over L positions is O(L²) — which has motivated a literature on efficient attention variants.

## Teacher Forcing

Training RNNs on autoregressive tasks (generating a sequence one token at a time) uses teacher forcing: during training, the model receives the ground-truth previous token rather than its own previous prediction. This stabilises training but produces exposure bias at inference time, when the model must condition on its own mistakes.
