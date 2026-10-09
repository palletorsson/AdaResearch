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
