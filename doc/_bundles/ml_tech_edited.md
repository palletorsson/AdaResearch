<<<ADA_BUNDLE>>>
sequence: machinelearning
file: technical.md
maps: 9
skipped_passing: 0
created: 2026-04-24T00:05:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: ML_Evolution>>>
# ML Evolution — Technical

The map runs a small genetic algorithm on a population of candidate agents. Each agent has a body plan (limb count, joint positions, weighted behaviours) encoded as a genome — a flat array of floats. The arena is a short obstacle course. Each agent runs the course once, and the distance it travels from spawn is its fitness.

The evolution loop is classical. After each generation, the top-performing agents are selected. Pairs are drawn from the selected set, and each pair produces offspring by crossover (mixing parameter values) plus mutation (adding small Gaussian noise to each parameter). The offspring replace the bottom performers, and the next generation runs.

```gdscript
class_name EvolutionController extends Node

@export var population_size: int = 32
@export var mutation_rate: float = 0.1
@export var selection_pressure: float = 0.3

var genomes: Array = []
var generation: int = 0

func _ready() -> void:
    for i in range(population_size):
        genomes.append(random_genome())

func next_generation(fitnesses: Array) -> void:
    var sorted: Array = zip(genomes, fitnesses)
    sorted.sort_custom(func(a, b): return a[1] > b[1])
    var survivors: int = int(population_size * selection_pressure)
    var new_pop: Array = []
    for i in range(survivors):
        new_pop.append(sorted[i][0])
    while new_pop.size() < population_size:
        var parent_a: Array = sorted[randi() % survivors][0]
        var parent_b: Array = sorted[randi() % survivors][0]
        var child: Array = crossover(parent_a, parent_b)
        mutate(child)
        new_pop.append(child)
    genomes = new_pop
    generation += 1

func mutate(g: Array) -> void:
    for i in range(g.size()):
        if randf() < mutation_rate:
            g[i] += randfn(0.0, 0.1)  # Gaussian
```

## Fitness Evaluation

Each generation requires running the entire population through the obstacle course, which is O(P·T) where P is population size and T is simulation steps per trial. For population 32 and 120 trial steps, that is ~3840 physics ticks per generation. At 60 Hz, a generation takes about one second of wall-clock time.

Fitness shaping matters. A naive fitness — distance travelled — rewards agents that fall forward, not agents that walk. Shaped fitnesses reward time-upright, step-count, and distance separately, then combine them with weights. The map exposes the weights as sliders so the learner can see different fitness landscapes produce different evolved behaviours.

## Exploration vs Exploitation

Selection pressure controls the exploration-exploitation tradeoff. Low pressure keeps diverse genomes alive, favouring exploration; high pressure culls aggressively, favouring exploitation of whatever worked last generation. Extreme pressure collapses the population onto a local optimum and prevents the algorithm from escaping. The map's default (0.3) balances the two.

Mutation rate is the other control. High mutation disrupts good solutions as much as bad ones; low mutation prevents the population from escaping local optima. Adaptive mutation — lowering the rate as fitness improves — is a common refinement the map does not implement but notes on a side panel.

Within the sequence, Evolution introduces optimisation without gradient. ML_Gradient_Landscape will replace the blind search with calculus-driven descent and ask what is gained by doing so.

<<<MAP: ML_Gradient_Landscape>>>
# ML Gradient Landscape — Technical

The map displays a terrain whose height at each point is a loss value — a hypothetical model's error at those parameter values. A marker is dropped onto the terrain, and gradient descent moves the marker downhill one step per frame.

```gdscript
class_name GradientDescentRig extends Node3D

@export var learning_rate: float = 0.05
@export var momentum: float = 0.9

var position_2d: Vector2
var velocity: Vector2

func step() -> void:
    var grad: Vector2 = compute_gradient(position_2d)
    velocity = momentum * velocity - learning_rate * grad
    position_2d += velocity
    update_marker_height()

func compute_gradient(p: Vector2) -> Vector2:
    var h: float = 0.001
    var dx := (loss(Vector2(p.x + h, p.y)) - loss(Vector2(p.x - h, p.y))) / (2 * h)
    var dy := (loss(Vector2(p.x, p.y + h)) - loss(Vector2(p.x, p.y - h))) / (2 * h)
    return Vector2(dx, dy)

func loss(p: Vector2) -> float:
    # Example: Himmelblau function (four minima)
    return pow(p.x * p.x + p.y - 11, 2) + pow(p.x + p.y * p.y - 7, 2)
```

## Learning Rate and Momentum

The learning rate decides step size. Too small, and the marker creeps across the terrain; too large, and it overshoots valleys and oscillates. The stable range is bounded by the Lipschitz constant of the gradient — the maximum rate at which the gradient itself changes — but this is rarely known in practice. The map exposes the learning rate as a slider so the learner can feel the stability boundary.

Momentum accumulates velocity across steps. A momentum term of 0.9 means each step carries 90% of the previous step's velocity plus the current gradient contribution. Momentum helps the marker escape shallow local minima (it keeps moving even when the gradient is briefly weak) and dampens oscillation in narrow valleys.

## Loss Surfaces

The map cycles through several classic loss functions. Himmelblau's function has four minima at comparable values — useful for showing that different starting points reach different optima. The Rastrigin function has many local minima overlaid on a single global minimum — useful for showing how gradient descent gets trapped. The Rosenbrock function has a narrow curved valley — useful for showing how momentum accelerates convergence.

## In Practice

Real neural networks operate in loss landscapes with millions of dimensions. The map's two-dimensional terrain is a pedagogical metaphor, not a realistic model. Saddle points dominate high-dimensional landscapes, and the 3D terrain's legible valleys and ridges do not generalise. A side panel notes this explicitly so the learner knows the metaphor's limits.

Within the sequence, Gradient_Landscape is where optimisation becomes cheap and directed. ML_Classification will next put the machinery to work on a concrete task.

<<<MAP: ML_Classification>>>
# ML Classification — Technical

The map runs three classifiers on the same labelled dataset: k-means, SVM, and a small neural network. Each classifier draws a decision boundary, and the boundaries are displayed side by side.

K-means is unsupervised. It drops k centroids, assigns each data point to the nearest centroid, then updates each centroid to the mean of its assigned points, and repeats until the assignments stop changing.

```gdscript
func kmeans(points: Array, k: int, max_iter: int = 50) -> Array:
    var centroids: Array = points.slice(0, k).duplicate()
    for iter in range(max_iter):
        var clusters: Array = []
        for i in range(k):
            clusters.append([])
        for p in points:
            var best: int = 0
            var best_d: float = INF
            for i in range(k):
                var d = p.distance_to(centroids[i])
                if d < best_d:
                    best_d = d; best = i
            clusters[best].append(p)
        var changed: bool = false
        for i in range(k):
            if clusters[i].is_empty(): continue
            var mean: Vector2 = Vector2.ZERO
            for q in clusters[i]:
                mean += q
            mean /= clusters[i].size()
            if mean != centroids[i]:
                centroids[i] = mean
                changed = true
        if not changed: break
    return centroids
```

## SVM

A linear SVM finds the separating hyperplane with the widest margin between classes. The primal formulation is a quadratic program; the dual formulation reveals that only support vectors — points on the margin boundary — affect the solution. For non-linearly-separable data, the kernel trick maps points into a higher-dimensional space where linear separation is possible, without computing the mapping explicitly.

The SVM artifact uses a precomputed solution, since QP solvers are outside Godot's built-in toolkit. The visualisation shows the decision boundary, the margin, and the support vectors — the handful of points that determine everything.

## Neural Classifier

The third station runs a small feedforward network: two hidden layers of eight units each with ReLU activation, trained by stochastic gradient descent. The network bends the decision boundary into a curve that follows the local density of the data.

```gdscript
func predict(x: Vector2) -> float:
    var h1: Array = layer_forward(x, W1, b1)
    h1 = relu(h1)
    var h2: Array = layer_forward(h1, W2, b2)
    h2 = relu(h2)
    var out: float = layer_forward(h2, W3, b3)[0]
    return sigmoid(out)

func relu(v: Array) -> Array:
    var r: Array = []
    for x in v:
        r.append(max(0.0, x))
    return r
```

## Comparison

The three boundaries on the same data: k-means gives a Voronoi partition, SVM gives a linear margin, the neural network gives a curved boundary that follows density. Each is a different hypothesis class, and the hypothesis class — not the training procedure — is what determines which patterns the classifier can express.

Within the sequence, Classification makes optimisation output something visible. ML_Neural_Networks will next stack these decisions into layers.

<<<MAP: ML_Neural_Networks>>>
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

<<<MAP: ML_Perception>>>
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

<<<MAP: ML_Sequence_Memory>>>
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

<<<MAP: ML_Generative>>>
# ML Generative — Technical

The map runs a generative adversarial network (GAN). A generator takes random noise as input and produces images; a discriminator judges whether an image is real or fake. Both are trained alternately until the generator's outputs fool the discriminator.

```gdscript
class_name GAN extends Node

var generator: FeedforwardNet
var discriminator: FeedforwardNet

func train_step(real_batch: Array) -> void:
    # Train discriminator
    var noise: Array = sample_noise(real_batch.size())
    var fake_batch: Array = noise.map(func(z): return generator.forward(z))
    var d_loss_real := -log_mean(real_batch.map(func(x): return discriminator.forward(x)))
    var d_loss_fake := -log_mean(fake_batch.map(func(x): return 1.0 - discriminator.forward(x)))
    discriminator.step(d_loss_real + d_loss_fake)

    # Train generator
    noise = sample_noise(real_batch.size())
    var g_loss := -log_mean(noise.map(func(z): return discriminator.forward(generator.forward(z))))
    generator.step(g_loss)
```

## Training Dynamics

GAN training is notoriously unstable. If the discriminator becomes too good too fast, the generator's gradient vanishes (the discriminator assigns probability near 0 to all fakes, so there's nothing to learn from). If the generator becomes too good, the discriminator has no signal. Balanced training requires careful hyperparameter tuning.

Mode collapse is another failure mode. The generator discovers a small subset of outputs that reliably fool the discriminator and refuses to produce anything else. The discriminator cannot counter this because the fakes it sees are all from the collapsed mode.

## VAE Alternative

Variational autoencoders (VAEs) offer a different approach. The encoder maps inputs to a distribution over a latent space; the decoder maps latent samples back to input space. The loss combines reconstruction error with a Kullback-Leibler divergence that keeps the latent distribution close to a standard normal.

```gdscript
func vae_loss(x: Array, mu: Array, log_var: Array, x_reconstructed: Array) -> float:
    var recon: float = mse(x, x_reconstructed)
    var kl := 0.0
    for i in range(mu.size()):
        kl += 0.5 * (exp(log_var[i]) + mu[i] * mu[i] - 1.0 - log_var[i])
    return recon + kl
```

VAEs avoid GAN's instability but tend to produce blurrier samples because the reconstruction loss penalises per-pixel error rather than distribution-level similarity. Modern hybrids (VAE-GAN, diffusion models) combine both approaches.

## Complexity

A forward pass through either generator or discriminator is O(L·N²) for L layers of width N. A training step computes one forward and one backward pass through each network, so the per-step cost is roughly 4× a single network's forward cost.

Within the sequence, Generative is the creative turn. ML_Synthesis will next gather every thread the sequence has developed.

<<<MAP: ML_Synthesis>>>
# ML Synthesis — Technical

The map stages three islands, each running a different ML paradigm: reinforcement learning on the first, a small generative language pipeline on the second, a classifier on the third. A central beacon tracks the overall loss across all three systems at once.

Reinforcement learning learns a policy from reward signals rather than from labelled examples. The walker creature on the first island has a policy that maps states to actions; an environment provides reward signals for successful steps. Q-learning is the canonical algorithm.

```gdscript
class_name QLearner extends Node

var q_table: Dictionary = {}  # (state, action) -> value
@export var alpha: float = 0.1  # learning rate
@export var gamma: float = 0.99  # discount factor
@export var epsilon: float = 0.1  # exploration rate

func choose_action(state) -> int:
    if randf() < epsilon:
        return randi() % n_actions
    var best: int = 0
    var best_q: float = -INF
    for a in range(n_actions):
        var q = q_table.get([state, a], 0.0)
        if q > best_q:
            best_q = q; best = a
    return best

func update(s, a, reward, s_next) -> void:
    var max_q_next: float = -INF
    for a_next in range(n_actions):
        max_q_next = max(max_q_next, q_table.get([s_next, a_next], 0.0))
    var old_q: float = q_table.get([s, a], 0.0)
    q_table[[s, a]] = old_q + alpha * (reward + gamma * max_q_next - old_q)
```

## Policy Gradient

Q-learning works for small state spaces but scales badly. Policy gradient methods parameterise the policy directly and optimise expected reward by gradient ascent.

```gdscript
func reinforce_update(trajectory: Array, lr: float = 0.01) -> void:
    var returns: Array = compute_returns(trajectory)
    for i in range(trajectory.size()):
        var state = trajectory[i].state
        var action = trajectory[i].action
        var G: float = returns[i]
        var grad = log_policy_gradient(state, action)
        update_policy_parameters(grad, lr * G)
```

The REINFORCE algorithm has high variance. Actor-critic methods reduce variance by using a learned value function as a baseline.

## Generative Station

The second island runs a small character-level language model — a two-layer LSTM trained on a short corpus. Given a seed prompt, it samples continuations character by character.

## Classifier Station

The third island runs the classifier from ML_Classification redeployed as a live demo. Incoming data points are classified in real time, and the learner can paint new training examples onto the space and retrain.

## Complexity

Each island's runtime cost is dominated by its own forward pass. Running three simultaneously requires careful frame budgeting. The map runs each at a reduced update frequency (every third frame) so all three fit within a single frame's time budget.

Within the sequence, Synthesis unifies the arc. Evolution, gradient descent, classification, neural composition, perception, memory, and generation all converge into the single practice of searching a loss surface the model cannot fully see.

<<<MAP: Chamber_ML>>>
# Chamber ML — Technical

The chamber hosts a gradient_hunter creature that learns the learner's movement patterns in real time. The hunter samples the learner's position each frame and updates a predictor of the next position.

```gdscript
class_name GradientHunter extends CharacterBody3D

var samples: Array = []  # ring buffer of (position, velocity) pairs
var predictor: LinearPredictor

func _physics_process(dt: float) -> void:
    var target_pos: Vector3 = get_tree().get_first_node_in_group("player").global_position
    var target_vel: Vector3 = target_pos - last_target_pos
    samples.append([target_pos, target_vel])
    if samples.size() > 64:
        samples.pop_front()
    predictor.update(samples)
    var predicted: Vector3 = predictor.predict(target_pos, target_vel)
    move_toward(predicted, dt)
    last_target_pos = target_pos
```

## Linear Predictor

The hunter uses a linear predictor: the next position is approximated as current position plus current velocity scaled by a learned coefficient. Ordinary least squares fits the coefficient to the recent samples.

```gdscript
class_name LinearPredictor

var coefficient: float = 1.0

func update(samples: Array) -> void:
    var num := 0.0
    var den := 0.0
    for i in range(samples.size() - 1):
        var delta = samples[i + 1][0] - samples[i][0]
        var vel = samples[i][1]
        num += delta.dot(vel)
        den += vel.dot(vel)
    if den > 0.0001:
        coefficient = num / den

func predict(pos: Vector3, vel: Vector3) -> Vector3:
    return pos + vel * coefficient
```

## Loss Tracking

A science screen plots the hunter's loss — the squared distance between predicted and actual position — over time. The loss drops as the predictor improves. A secondary plot shows the predicted position as a ghost ahead of the learner so the hunter's current model is visible.

## Counter-Strategy

The only defence is unpredictability. Smooth, rhythmic movement gives the predictor clean gradient to fit; noisy, unpredictable movement withholds the gradient. The hunter's loss rises when the learner moves erratically and falls when they settle into a pattern.

```gdscript
# On the learner side, measuring own predictability
func motion_predictability() -> float:
    var recent_velocities: Array = get_recent_velocities()
    var mean = recent_velocities.reduce(func(a, b): return a + b) / recent_velocities.size()
    var variance := 0.0
    for v in recent_velocities:
        variance += (v - mean).length_squared()
    return 1.0 / (1.0 + variance)  # higher = more predictable
```

## Complexity

Each frame requires an O(N) pass over the N-sample buffer for the least-squares fit. With N=64, this is 64 multiply-adds per frame — trivial. Richer predictors (Kalman filters, neural nets) would cost more but are overkill for the chamber's pedagogical aims.

Within the sequence, Chamber_ML closes Machine Learning by converting optimisation from a solitary practice into a mutual encounter. The hunter is the optimiser; the learner is the training distribution.
