import sys
sys.stdout.reconfigure(encoding='utf-8')
from pathlib import Path

adds = {}

adds['ML_Evolution'] = """

## Crossover Variants

Several crossover strategies produce different exploration profiles. One-point crossover splits each parent at a random index and recombines the pieces. Uniform crossover picks each gene independently from one parent or the other. Arithmetic crossover takes a weighted average of the two parents. The map uses uniform crossover by default because it produces the most diverse offspring, which matters when the population is small.

```gdscript
func crossover_uniform(a: Array, b: Array) -> Array:
    var child: Array = []
    for i in range(a.size()):
        child.append(a[i] if randf() < 0.5 else b[i])
    return child

func crossover_arithmetic(a: Array, b: Array) -> Array:
    var alpha: float = randf()
    var child: Array = []
    for i in range(a.size()):
        child.append(alpha * a[i] + (1.0 - alpha) * b[i])
    return child
```

## Comparison With Gradient Descent

The evolutionary approach has two advantages over gradient descent. First, it handles non-differentiable fitness functions; the fitness only needs to be computable, not smooth. Second, it explores the landscape in parallel through the population, which reduces the risk of getting stuck in a single local minimum. The disadvantage is sample efficiency: evolution needs many fitness evaluations, while gradient descent needs one forward pass per step. Modern hybrid approaches (neuroevolution, evolutionary strategies) combine the two.

## Seeding the Population

Random genomes work for small search spaces but fail for large ones: the initial population is so bad that no recombination produces anything useful, and the algorithm never finds a gradient of fitness to climb. The map's obstacle course is calibrated so that random genomes produce some variation in fitness — a few agents happen to move forward, most fall over — and the variation is enough to drive the first generation's selection.
"""

adds['ML_Gradient_Landscape'] = """

## Adaptive Methods

Modern optimisers adapt per-parameter learning rates based on gradient history. Adagrad scales each parameter's learning rate by the inverse square root of accumulated squared gradients, which dampens updates for parameters that have already moved a lot. RMSProp adds an exponential moving average. Adam combines both with a bias correction.

```gdscript
class_name Adam

var m: Array  # first moment estimate
var v: Array  # second moment estimate
var t: int = 0
@export var beta1: float = 0.9
@export var beta2: float = 0.999
@export var eps: float = 1e-8

func update(params: Array, grads: Array, lr: float) -> Array:
    t += 1
    var new_params: Array = []
    for i in range(params.size()):
        m[i] = beta1 * m[i] + (1.0 - beta1) * grads[i]
        v[i] = beta2 * v[i] + (1.0 - beta2) * grads[i] * grads[i]
        var m_hat = m[i] / (1.0 - pow(beta1, t))
        var v_hat = v[i] / (1.0 - pow(beta2, t))
        new_params.append(params[i] - lr * m_hat / (sqrt(v_hat) + eps))
    return new_params
```

## Second-Order Methods

Newton's method uses the Hessian (the matrix of second derivatives) to take better steps. The update is Δθ = −H⁻¹·∇, which jumps directly to the minimum for quadratic functions. The Hessian costs O(N²) to store and O(N³) to invert, so second-order methods are impractical for large networks. Quasi-Newton methods (BFGS, L-BFGS) approximate the inverse Hessian incrementally and are practical for medium-scale problems.

## Stochastic Gradient Descent

Real neural networks train with stochastic gradients — gradients computed on a randomly-sampled mini-batch rather than on the full dataset. The noise in the stochastic gradient can help escape local minima (the noise perturbs the trajectory enough to jump out of shallow basins), but it also prevents the optimiser from ever settling at a precise minimum. The tradeoff is the subject of an active literature.
"""

adds['ML_Classification'] = """

## The Kernel Trick

SVMs can fit non-linear boundaries by mapping inputs into a higher-dimensional feature space where a linear separator exists. The kernel trick computes the inner product in that feature space without computing the mapping explicitly, using a kernel function K(x, y) that equals the inner product of the mapped points.

```gdscript
func kernel_rbf(x: Vector2, y: Vector2, gamma: float = 0.5) -> float:
    return exp(-gamma * x.distance_squared_to(y))

func kernel_polynomial(x: Vector2, y: Vector2, degree: int = 3) -> float:
    var dot = x.x * y.x + x.y * y.y
    return pow(dot + 1.0, degree)
```

The RBF kernel (radial basis function) is the default choice for non-linear SVM because it corresponds to an infinite-dimensional feature space where any data is separable. The polynomial kernel is cheaper but less expressive.

## Regularisation

Overfitting happens when the classifier memorises the training data and fails to generalise. L2 regularisation adds a penalty proportional to the squared magnitude of the weights, encouraging small weights. L1 regularisation adds a penalty proportional to absolute weight magnitude, encouraging sparse weights (many weights exactly zero). Dropout, used in neural networks, randomly zeros a fraction of the activations during training, which prevents co-adaptation of units.

## Evaluation

Training accuracy alone is not a reliable signal of classifier quality. The standard practice is to hold out a test set that the classifier never sees during training, and report accuracy on the test set. Cross-validation — training on K-1 folds and testing on the remaining fold, rotating through all K folds — gives a more robust estimate for small datasets.

Class imbalance complicates evaluation. A 99%/1% class split admits a trivial classifier that always predicts the majority class and achieves 99% accuracy while being useless. Precision, recall, and F1 score give a better picture by separately tracking false positives and false negatives.
"""

adds['ML_Neural_Networks'] = """

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
"""

adds['ML_Perception'] = """

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
"""

adds['ML_Sequence_Memory'] = """

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
"""

adds['ML_Generative'] = """

## Diffusion Models

Diffusion models have displaced GANs for high-quality image generation. The model learns to reverse a gradual noising process: given a noisy image, predict the clean image (or, equivalently, predict the noise that was added). At inference, start from pure noise and iteratively denoise.

```gdscript
func diffusion_forward(x_0: Array, t: int, noise_schedule: Array) -> Array:
    # Add noise scaled by the schedule at step t
    var alpha_t: float = noise_schedule[t]
    var noise: Array = sample_gaussian(x_0.size())
    var x_t: Array = []
    for i in range(x_0.size()):
        x_t.append(sqrt(alpha_t) * x_0[i] + sqrt(1.0 - alpha_t) * noise[i])
    return x_t

func diffusion_reverse(x_t: Array, t: int, model) -> Array:
    # Predict the noise, then subtract it to recover x_{t-1}
    var predicted_noise: Array = model.forward([x_t, t])
    var x_t_minus_1: Array = []
    for i in range(x_t.size()):
        x_t_minus_1.append(x_t[i] - predicted_noise[i] * step_size(t))
    return x_t_minus_1
```

Diffusion avoids GAN's mode collapse and VAE's blurriness, at the cost of slow inference (hundreds of denoising steps per sample). Guided diffusion and classifier-free guidance let the generation be conditioned on text or other signals.

## Autoregressive Generation

Language models generate text autoregressively — one token at a time, conditioning on previous tokens. Temperature scales the logits before softmax, controlling the randomness of the sampling. Top-k sampling restricts each step to the k most-probable tokens. Nucleus (top-p) sampling restricts to the smallest set of tokens whose cumulative probability exceeds p.

```gdscript
func sample_token(logits: Array, temperature: float = 1.0, top_k: int = 40) -> int:
    var scaled: Array = []
    for l in logits:
        scaled.append(l / temperature)
    var sorted_indices := argsort_desc(scaled)
    var top := sorted_indices.slice(0, top_k)
    var probs: Array = softmax_subset(scaled, top)
    return sample_categorical(top, probs)
```

## Evaluation

Generative models are hard to evaluate. Inception Score and Frechet Inception Distance measure output quality against a reference distribution. Human evaluation remains the gold standard for images and text. For structured outputs, task-specific metrics (BLEU for translation, perplexity for language modelling) are common but each has known failure modes.
"""

adds['ML_Synthesis'] = """

## Multi-Armed Bandits

Bandit problems are a simpler setting than full RL. The agent chooses among K actions, each with an unknown reward distribution; the goal is to maximise cumulative reward. Epsilon-greedy explores randomly with probability epsilon and exploits the current best with probability 1-epsilon. Upper Confidence Bound (UCB) chooses the action whose upper confidence interval on reward is highest.

```gdscript
func ucb_choose(mean_rewards: Array, counts: Array, t: int) -> int:
    var best: int = 0
    var best_score: float = -INF
    for i in range(mean_rewards.size()):
        if counts[i] == 0:
            return i
        var bonus: float = sqrt(2.0 * log(t) / counts[i])
        var score: float = mean_rewards[i] + bonus
        if score > best_score:
            best_score = score; best = i
    return best
```

Bandits generalise to contextual bandits (the reward depends on a context vector) and then to full RL (actions change the state). The progression is conceptually clean and the map's third island shows it.

## Transfer Learning

Transfer learning reuses features learned on one task for another. A vision model pretrained on ImageNet can be fine-tuned on a small specialised dataset and vastly outperform a model trained from scratch. The reuse is conceptually simple: freeze the early layers, replace the output head, train the output head (and optionally unfreeze some upper layers).

```gdscript
func transfer_model(base_model, new_task_head) -> FeedforwardNet:
    var model := FeedforwardNet.new()
    for layer in base_model.layers.slice(0, -1):
        model.layers.append(layer)
        model.layers[-1].trainable = false
    model.layers.append(new_task_head)
    return model
```

Transfer learning is one reason large pretrained models have become dominant. The cost of pretraining is borne once; downstream tasks benefit without repeating the cost.

## Deployment

Training is only one part of the lifecycle. Deployment raises concerns the training process does not: latency, memory, robustness to distribution shift, ability to retrain on new data. Production systems are often smaller than their training-time models (via distillation, quantisation, or pruning) because deployment cost matters more than training cost.
"""

adds['Chamber_ML'] = """

## Kalman Filter Alternative

A Kalman filter is the principled approach to online prediction. It maintains a belief state as a Gaussian distribution over positions and velocities, updates the belief from each observation, and produces a maximum-a-posteriori prediction of the next state.

```gdscript
class_name KalmanFilter

var mean: Vector3
var covariance: Array  # 3x3 matrix
var process_noise: float = 0.1
var observation_noise: float = 0.2

func predict(dt: float) -> Vector3:
    # Propagate mean forward
    mean = mean + velocity * dt
    # Inflate covariance by process noise
    for i in range(3):
        covariance[i][i] += process_noise * dt
    return mean

func update(observation: Vector3) -> void:
    var innovation: Vector3 = observation - mean
    var kalman_gain = covariance_inverse_plus_noise()
    mean = mean + kalman_gain * innovation
    covariance = reduce_covariance_by_observation()
```

The Kalman filter is optimal for linear-Gaussian systems. The hunter in the map uses a simpler linear predictor because the chamber's pedagogical aim is to make the learning curve legible, not to produce the fastest tracker.

## Online Learning

The chamber stages a contrasting example to batch learning. Batch learning trains once on a fixed dataset and deploys. Online learning updates continuously as new data arrives. The hunter is a continuous online learner, and its learning curve is visible frame by frame.

Online learning has theoretical guarantees: under mild conditions, the regret (difference between online loss and best-possible batch loss) grows sublinearly in the number of samples. The hunter's loss trajectory shown on the science screen is roughly this regret over time.

## Adversarial Noise

A learner can deliberately inject noise into their trajectory to degrade the hunter's prediction accuracy. The noise does not need to be uniformly random — adversarial noise specifically targets the hunter's current model and produces maximum prediction error for minimum actual deviation.

```gdscript
func adversarial_noise(current_model_state, budget: float) -> Vector3:
    # Direction that maximally surprises the current predictor
    var gradient = predict_gradient(current_model_state)
    return -gradient.normalized() * budget
```

Adversarial noise is a practical defence for the learner but requires knowing the predictor's current state — information the science screen partially provides.
"""

for m, add in adds.items():
    p = Path(f'commons/maps/{m}/technical.md')
    t = p.read_text(encoding='utf-8')
    p.write_text(t.rstrip() + add, encoding='utf-8')

print('done', len(adds))
