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
