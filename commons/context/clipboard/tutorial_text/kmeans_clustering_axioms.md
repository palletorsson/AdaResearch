**K-Means Clustering**
Partitioning Data, Centroid Iteration

**K-means groups data into K clusters by minimizing distance to centroids.**

**Algorithm:**
1. Initialize K centroids randomly
2. Assign each point to nearest centroid
3. Recalculate centroids (mean of assigned points)
4. Repeat 2-3 until convergence

---

## Code

**Implementation:**

```
func kmeans(points: Array, k: int, max_iterations: int = 100):
    # Initialize centroids randomly
    var centroids = []
    for i in range(k):
        centroids.append(points[randi() % points.size()])

    for iteration in range(max_iterations):
        # Assign points to nearest centroid
        var clusters = {}
        for i in range(k):
            clusters = []

        for point in points:
            var nearest = find_nearest_centroid(point, centroids)
            clusters.append(point)

        # Recalculate centroids
        var new_centroids = []
        for i in range(k):
            if clusters.is_empty():
                new_centroids.append(centroids)  # Keep old if empty
            else:
                new_centroids.append(calculate_mean(clusters))

        # Check convergence
        if centroids_equal(centroids, new_centroids):
            break

        centroids = new_centroids

    return centroids

func find_nearest_centroid(point, centroids):
    var min_dist = INF
    var nearest = 0
    for i in range(centroids.size()):
        var dist = point.distance_to(centroids)
        if dist < min_dist:
            min_dist = dist
            nearest = i
    return nearest
```

**Result:** Points grouped into K clusters.

---

## Properties

- **K must be chosen** (algorithm doesn