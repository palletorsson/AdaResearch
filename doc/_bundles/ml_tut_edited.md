<<<ADA_BUNDLE>>>
sequence: machinelearning
file: tutorial.md
maps: 9
skipped_passing: 0
created: 2026-04-24T03:45:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: ML_Evolution>>>
# ML Evolution

A genetic algorithm. Population, selection, mutation.

Define a creature genome.

```gdscript
class_name Genome

var genes: Array = []  # array of floats in [-1, 1]

func random_genome(size: int) -> void:
    genes.clear()
    for _i in size:
        genes.append(randf_range(-1.0, 1.0))
```

An array of real-valued parameters. Each gene influences one behaviour weight.

Build a creature from a genome.

```gdscript
func spawn_creature(genome: Genome) -> CharacterBody3D:
    var creature := CREATURE_SCENE.instantiate()
    creature.set_weights(genome.genes)
    add_child(creature)
    return creature
```

The creature reads the weights and uses them to drive its motion.

Evaluate fitness.

```gdscript
func evaluate_fitness(genome: Genome) -> float:
    var creature := spawn_creature(genome)
    var start := creature.global_position
    await get_tree().create_timer(10.0).timeout
    var distance: float = start.distance_to(creature.global_position)
    creature.queue_free()
    return distance
```

Run the creature for 10 seconds; measure distance travelled. Fitness is the distance.

Tournament selection.

```gdscript
func tournament_select(population: Array, k: int = 3) -> Genome:
    var contestants: Array = []
    for _i in k:
        contestants.append(population[randi() % population.size()])
    contestants.sort_custom(func(a, b): return a.fitness > b.fitness)
    return contestants[0]
```

Pick k random genomes; return the best. Larger k means stronger selection pressure.

Crossover.

```gdscript
func crossover(parent_a: Genome, parent_b: Genome) -> Genome:
    var child := Genome.new()
    for i in parent_a.genes.size():
        child.genes.append(parent_a.genes[i] if randf() < 0.5 else parent_b.genes[i])
    return child
```

Uniform crossover. Each gene comes from one parent at random.

Mutation.

```gdscript
func mutate(genome: Genome, rate: float = 0.1, strength: float = 0.2) -> void:
    for i in genome.genes.size():
        if randf() < rate:
            genome.genes[i] += randfn(0.0, strength)
            genome.genes[i] = clamp(genome.genes[i], -1.0, 1.0)
```

Each gene has a chance of Gaussian perturbation. Rate and strength are tunable.

Run the generation loop.

```gdscript
func run_generation(population: Array, size: int) -> Array:
    for g in population:
        g.fitness = await evaluate_fitness(g)
    var next_gen: Array = []
    population.sort_custom(func(a, b): return a.fitness > b.fitness)
    # Elitism: top 20% carry over
    for i in size / 5:
        next_gen.append(population[i])
    while next_gen.size() < size:
        var parent_a := tournament_select(population)
        var parent_b := tournament_select(population)
        var child := crossover(parent_a, parent_b)
        mutate(child)
        next_gen.append(child)
    return next_gen
```

Elitism preserves the best; the rest are produced by crossover and mutation. Elitism prevents regression.

You can now build a genetic algorithm with genomes, fitness evaluation, tournament selection, crossover, and mutation. ML_Gradient_Landscape extends into calculus-driven optimisation.

<<<MAP: ML_Gradient_Landscape>>>
# ML Gradient Landscape

Gradient descent. Compute the slope; step downhill.

Define a loss function.

```gdscript
func loss(p: Vector2) -> float:
    return (p.x * p.x + p.y - 11) ** 2 + (p.x + p.y * p.y - 7) ** 2  # Himmelblau
```

Himmelblau's function. Four global minima at comparable values.

Compute the gradient numerically.

```gdscript
func gradient(p: Vector2, h: float = 0.001) -> Vector2:
    var dx: float = (loss(Vector2(p.x + h, p.y)) - loss(Vector2(p.x - h, p.y))) / (2 * h)
    var dy: float = (loss(Vector2(p.x, p.y + h)) - loss(Vector2(p.x, p.y - h))) / (2 * h)
    return Vector2(dx, dy)
```

Central-difference approximation. Two function evaluations per axis.

Vanilla gradient descent step.

```gdscript
func gd_step(p: Vector2, lr: float = 0.05) -> Vector2:
    return p - gradient(p) * lr
```

Move opposite to the gradient, scaled by the learning rate.

Momentum gradient descent.

```gdscript
var velocity: Vector2 = Vector2.ZERO

func momentum_step(p: Vector2, lr: float = 0.05, momentum: float = 0.9) -> Vector2:
    velocity = velocity * momentum - gradient(p) * lr
    return p + velocity
```

Accumulate velocity across steps. Escapes shallow local minima.

Adam optimiser.

```gdscript
var m: Vector2 = Vector2.ZERO  # first moment
var v: Vector2 = Vector2.ZERO  # second moment
var t: int = 0
@export var beta1: float = 0.9
@export var beta2: float = 0.999
@export var eps: float = 1e-8

func adam_step(p: Vector2, lr: float = 0.05) -> Vector2:
    t += 1
    var g := gradient(p)
    m = m * beta1 + g * (1 - beta1)
    v = Vector2(v.x * beta2 + g.x * g.x * (1 - beta2), v.y * beta2 + g.y * g.y * (1 - beta2))
    var m_hat: Vector2 = m / (1 - pow(beta1, t))
    var v_hat: Vector2 = v / (1 - pow(beta2, t))
    return p - Vector2(lr * m_hat.x / (sqrt(v_hat.x) + eps), lr * m_hat.y / (sqrt(v_hat.y) + eps))
```

Per-parameter adaptive learning rates. Adam is the default optimiser in modern deep learning.

Render the loss surface.

```gdscript
func render_surface(bounds: Vector2, resolution: int = 64) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for y in resolution:
        for x in resolution:
            var p := Vector2(x, y) / resolution * bounds - bounds / 2
            var height: float = loss(p)
            st.add_vertex(Vector3(p.x, height, p.y))
    # ... triangulation
    return st.commit()
```

A grid of vertices at computed heights. The mesh shows the terrain gradient descent walks.

Animate the descent.

```gdscript
func animate_descent(p_start: Vector2, steps: int) -> void:
    var p := p_start
    for _i in steps:
        p = adam_step(p)
        mark_position(p)
        await get_tree().create_timer(0.1).timeout
```

Each step drops a marker. The trail shows the optimiser's trajectory.

You can now compute gradients numerically, step via vanilla/momentum/Adam, render a loss surface, and animate the descent. ML_Classification extends into decision boundaries.

<<<MAP: ML_Classification>>>
# ML Classification

Separate classes in feature space. K-means, SVM, neural network.

Label a dataset.

```gdscript
class_name LabeledDataset

var points: Array = []   # Vector2
var labels: Array = []   # int (class indices)

func add_point(p: Vector2, label: int) -> void:
    points.append(p)
    labels.append(label)
```

A labelled point cloud. Two classes for the simplest case.

K-means clustering.

```gdscript
func kmeans(points: Array, k: int, max_iter: int = 50) -> Array:
    var centroids: Array = []
    for _i in k:
        centroids.append(points[randi() % points.size()])
    for _iter in max_iter:
        var clusters: Array = []
        for _i in k: clusters.append([])
        for p in points:
            var best: int = 0
            var best_dist: float = INF
            for i in k:
                var d: float = p.distance_to(centroids[i])
                if d < best_dist:
                    best_dist = d; best = i
            clusters[best].append(p)
        var changed: bool = false
        for i in k:
            if clusters[i].is_empty(): continue
            var mean := Vector2.ZERO
            for p in clusters[i]: mean += p
            mean /= clusters[i].size()
            if not mean.is_equal_approx(centroids[i]):
                centroids[i] = mean; changed = true
        if not changed: break
    return centroids
```

Iterate: assign points to nearest centroid, update centroid to cluster mean, repeat. Converges when assignments stabilise.

Linear SVM decision boundary.

```gdscript
class_name SimpleSVM

var weights: Vector2 = Vector2.ZERO
var bias: float = 0.0

func predict(p: Vector2) -> int:
    return 1 if weights.dot(p) + bias > 0 else -1

func train(dataset: LabeledDataset, lr: float = 0.01, epochs: int = 100) -> void:
    for _e in epochs:
        for i in dataset.points.size():
            var p: Vector2 = dataset.points[i]
            var y: int = dataset.labels[i]
            if y * (weights.dot(p) + bias) < 1:
                weights += lr * (y * p - 0.01 * weights)
                bias += lr * y
            else:
                weights -= lr * 0.01 * weights
```

Hinge-loss SGD. Simple but effective for linearly separable data.

Neural classifier forward pass.

```gdscript
class_name SimpleNN

var W1: Array  # input-to-hidden
var b1: Array
var W2: Array  # hidden-to-output
var b2: Array

func forward(x: Vector2) -> float:
    var h1: Array = [
        max(0.0, W1[0][0] * x.x + W1[0][1] * x.y + b1[0]),
        max(0.0, W1[1][0] * x.x + W1[1][1] * x.y + b1[1]),
        max(0.0, W1[2][0] * x.x + W1[2][1] * x.y + b1[2]),
        max(0.0, W1[3][0] * x.x + W1[3][1] * x.y + b1[3]),
    ]
    return 1.0 / (1.0 + exp(-(W2[0] * h1[0] + W2[1] * h1[1] + W2[2] * h1[2] + W2[3] * h1[3] + b2)))
```

Two inputs, four hidden units with ReLU, one sigmoid output. A canonical small network.

Render a decision boundary.

```gdscript
func render_boundary(predict_func: Callable, bounds: Rect2, resolution: int = 100) -> ImageTexture:
    var image := Image.create(resolution, resolution, false, Image.FORMAT_RGBA8)
    for py in resolution:
        for px in resolution:
            var p := Vector2(px, py) / resolution * bounds.size + bounds.position
            var label = predict_func.call(p)
            image.set_pixel(px, py, Color.RED if label == 1 else Color.BLUE)
    return ImageTexture.create_from_image(image)
```

Sample the classifier on a grid. Paint each sample according to the predicted label.

Visualise the dataset.

```gdscript
func render_points(dataset: LabeledDataset) -> void:
    for i in dataset.points.size():
        var marker := SphereMesh.new()
        var mi := MeshInstance3D.new()
        mi.mesh = marker
        mi.position = Vector3(dataset.points[i].x, 0.1, dataset.points[i].y)
        var mat := StandardMaterial3D.new()
        mat.albedo_color = Color.RED if dataset.labels[i] == 1 else Color.BLUE
        mi.material_override = mat
        add_child(mi)
```

Each data point becomes a coloured sphere. The classifier's boundary can be overlaid.

You can now build a labelled dataset, cluster with k-means, train an SVM with hinge-loss SGD, forward-pass a small neural network, and render decision boundaries. ML_Neural_Networks extends into multi-layer architecture.

<<<MAP: ML_Neural_Networks>>>
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

<<<MAP: ML_Perception>>>
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

<<<MAP: ML_Sequence_Memory>>>
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

<<<MAP: ML_Generative>>>
# ML Generative

Generate new data from a learned distribution. GAN, VAE, diffusion.

Build a GAN generator.

```gdscript
class_name Generator extends FeedforwardNet

func generate(noise: Array) -> Array:
    return forward(noise)
```

Takes random noise; produces a sample. The network's weights encode the learned distribution.

Build a GAN discriminator.

```gdscript
class_name Discriminator extends FeedforwardNet

func is_real(sample: Array) -> float:
    var output := forward(sample)
    return output[0]  # scalar probability
```

Outputs the probability the input is real (rather than generated).

Train the GAN.

```gdscript
func train_step(real_batch: Array, generator: Generator, discriminator: Discriminator, lr: float = 0.001) -> void:
    var fake_batch: Array = []
    for _i in real_batch.size():
        var z: Array = sample_noise(32)
        fake_batch.append(generator.generate(z))
    discriminator.backward_real_batch(real_batch, lr)
    discriminator.backward_fake_batch(fake_batch, lr)
    var fake_batch_new: Array = []
    for _i in real_batch.size():
        var z: Array = sample_noise(32)
        fake_batch_new.append(generator.generate(z))
    generator.backward_fool_discriminator(fake_batch_new, discriminator, lr)
```

Alternating training. First the discriminator learns to distinguish; then the generator learns to fool.

Sample noise.

```gdscript
func sample_noise(size: int) -> Array:
    var noise: Array = []
    for _i in size:
        noise.append(randfn(0.0, 1.0))
    return noise
```

Standard Gaussian. Each generator input is an independent noise vector.

Build a VAE encoder.

```gdscript
func vae_encode(x: Array) -> Dictionary:
    var h := encoder_forward(x)
    return {
        "mu": extract_mu(h),
        "log_var": extract_log_var(h),
    }
```

The encoder produces mean and log-variance of a Gaussian. Sampling from this distribution gives the latent code.

Reparameterise for gradient flow.

```gdscript
func reparameterize(mu: Array, log_var: Array) -> Array:
    var z: Array = []
    for i in mu.size():
        var std: float = exp(0.5 * log_var[i])
        var eps: float = randfn(0.0, 1.0)
        z.append(mu[i] + eps * std)
    return z
```

Reparameterisation moves the randomness outside the network. Gradient flows through mu and log_var.

Compute VAE loss.

```gdscript
func vae_loss(x: Array, reconstructed: Array, mu: Array, log_var: Array) -> float:
    var recon_loss: float = 0.0
    for i in x.size():
        recon_loss += (x[i] - reconstructed[i]) ** 2
    var kl_loss: float = 0.0
    for i in mu.size():
        kl_loss += 0.5 * (exp(log_var[i]) + mu[i] * mu[i] - 1.0 - log_var[i])
    return recon_loss + kl_loss
```

Reconstruction plus KL divergence. Balances fidelity against latent-space regularity.

Run a single diffusion step.

```gdscript
func diffusion_forward(x_0: Array, t: float, beta: float = 0.01) -> Array:
    var alpha: float = 1.0 - beta * t
    var noise: Array = sample_noise(x_0.size())
    var x_t: Array = []
    for i in x_0.size():
        x_t.append(sqrt(alpha) * x_0[i] + sqrt(1.0 - alpha) * noise[i])
    return x_t
```

Add progressively more noise. The reverse process is a learned neural network.

You can now build GAN generators and discriminators, train with alternating optimisation, encode and decode with VAEs using reparameterisation, compute VAE loss, and run one diffusion step. ML_Synthesis extends into a multi-paradigm synthesis map.

<<<MAP: ML_Synthesis>>>
# ML Synthesis

Reinforcement learning, generation, classification. Three islands.

Build a Q-table.

```gdscript
class_name QLearner

var q_table: Dictionary = {}  # state -> array of Q values per action

func get_q(state, action: int) -> float:
    return q_table.get(state, Array([0, 0, 0, 0]))[action]

func set_q(state, action: int, value: float) -> void:
    if not state in q_table:
        q_table[state] = [0.0, 0.0, 0.0, 0.0]
    q_table[state][action] = value
```

One row per state, one column per action. Values track expected future reward.

Epsilon-greedy action selection.

```gdscript
@export var epsilon: float = 0.1

func choose_action(state) -> int:
    if randf() < epsilon:
        return randi() % 4
    var q_values: Array = q_table.get(state, [0, 0, 0, 0])
    var best: int = 0
    for i in range(1, 4):
        if q_values[i] > q_values[best]:
            best = i
    return best
```

With probability epsilon explore; otherwise exploit the best known action.

Q-learning update.

```gdscript
@export var alpha: float = 0.1  # learning rate
@export var gamma: float = 0.99  # discount factor

func update(state, action: int, reward: float, next_state) -> void:
    var max_next_q: float = -INF
    for a in 4:
        max_next_q = max(max_next_q, get_q(next_state, a))
    var old_q: float = get_q(state, action)
    var new_q: float = old_q + alpha * (reward + gamma * max_next_q - old_q)
    set_q(state, action, new_q)
```

Temporal-difference update. Blends current reward with discounted future expectations.

Run an episode.

```gdscript
func run_episode(env) -> float:
    var state = env.reset()
    var total_reward: float = 0.0
    while not env.is_done():
        var action := choose_action(state)
        var result: Dictionary = env.step(action)
        update(state, action, result.reward, result.next_state)
        state = result.next_state
        total_reward += result.reward
    return total_reward
```

One episode from start to terminal state. The total reward measures how well the policy performed.

Policy gradient (REINFORCE).

```gdscript
func reinforce_update(trajectory: Array, learning_rate: float = 0.01) -> void:
    var returns: Array = compute_returns(trajectory, gamma)
    for i in trajectory.size():
        var state = trajectory[i].state
        var action: int = trajectory[i].action
        var G: float = returns[i]
        var grad: Array = policy_gradient(state, action)
        update_policy(grad, learning_rate * G)
```

Gradient ascent on expected return. Unlike Q-learning, learns a stochastic policy directly.

Sample from a trained language model.

```gdscript
func sample_from_lm(prompt: String, max_tokens: int, temperature: float = 0.7) -> String:
    var output: String = prompt
    for _i in max_tokens:
        var logits: Array = lm_forward(tokenize(output))
        var scaled: Array = []
        for l in logits: scaled.append(l / temperature)
        var probs: Array = softmax(scaled)
        var token_idx: int = sample_categorical(probs)
        output += detokenize([token_idx])
    return output
```

Autoregressive generation. Temperature controls randomness; higher is more diverse.

Retrain a classifier on new data.

```gdscript
func online_retrain(classifier, new_examples: Array) -> void:
    for _epoch in 5:
        for example in new_examples:
            classifier.backward(example.features, example.label)
```

Fine-tune on incoming data. Useful for classifiers that must adapt to distribution shift.

You can now build a Q-learner with epsilon-greedy and temporal-difference updates, run policy gradient, sample from a language model with temperature, and retrain a classifier online. Chamber_ML closes with an adversarial optimiser.

<<<MAP: Chamber_ML>>>
# Chamber ML

The gradient_hunter learns your patterns. Move unpredictably.

Build the hunter.

```gdscript
class_name GradientHunter extends CharacterBody3D

var sample_buffer: Array = []  # ring buffer of (position, velocity)
@export var buffer_size: int = 32
```

The hunter remembers the last 32 observations. A small sliding window.

Record a sample.

```gdscript
func observe(learner: Node3D, delta: float) -> void:
    var current_pos: Vector3 = learner.global_position
    var current_vel: Vector3 = (current_pos - last_learner_pos) / delta
    sample_buffer.append({"pos": current_pos, "vel": current_vel})
    if sample_buffer.size() > buffer_size:
        sample_buffer.pop_front()
    last_learner_pos = current_pos
```

Each frame, record position and velocity. Older samples fall out of the buffer.

Fit a linear predictor.

```gdscript
func fit_predictor() -> float:
    if sample_buffer.size() < 2: return 0.0
    var num: float = 0.0
    var den: float = 0.0
    for i in range(sample_buffer.size() - 1):
        var delta: Vector3 = sample_buffer[i + 1].pos - sample_buffer[i].pos
        var vel: Vector3 = sample_buffer[i].vel
        num += delta.dot(vel)
        den += vel.length_squared()
    return num / den if den > 0.0001 else 0.0
```

Least-squares fit. Coefficient gives the best-fit relationship between velocity and position change.

Predict the next position.

```gdscript
func predict_next(learner: Node3D, coefficient: float) -> Vector3:
    return learner.global_position + learner.velocity * coefficient
```

Current position plus velocity times coefficient. The predictor's output moves as the learner moves.

Track loss over time.

```gdscript
var loss_history: Array = []

func update_loss(predicted: Vector3, actual: Vector3) -> void:
    var loss: float = predicted.distance_squared_to(actual)
    loss_history.append(loss)
    if loss_history.size() > 100: loss_history.pop_front()
```

Squared error between prediction and truth. Lower means the hunter is learning.

Pursue the predicted position.

```gdscript
func _physics_process(delta: float) -> void:
    var coefficient := fit_predictor()
    var predicted: Vector3 = predict_next(learner, coefficient)
    var direction: Vector3 = (predicted - global_position).normalized()
    velocity = direction * max_speed
    move_and_slide()
```

Move toward the predicted position rather than the current one. Anticipates the learner's movement.

Detect befriending via time in chamber.

```gdscript
var time_in_chamber: float = 0.0
@export var befriend_threshold: float = 45.0

func _process(delta: float) -> void:
    time_in_chamber += delta
    if time_in_chamber > befriend_threshold and not befriended:
        befriend()
        emit_signal("befriended")
```

After 45 seconds of engagement, the hunter befriends. Unlike other chambers, befriending here isn't about defeating the predictor — it's about enduring long enough.

You can now build the gradient_hunter, observe the learner, fit a predictor, pursue the predicted position, and track loss over time. The Machine Learning sequence closes with the chamber's argument that learning is relational rather than solitary.
