extends Node

var text = '''[center][font_size=28][b]K-Means Clustering[/b][/font_size][/center]
[center][i]Partitioning Data, Centroid Iteration[/i][/center]

**K-means groups data into K clusters by minimizing distance to centroids.**

**Algorithm:**
1. Initialize K centroids randomly
2. Assign each point to nearest centroid
3. Recalculate centroids (mean of assigned points)
4. Repeat 2-3 until convergence

[hr]

[b]Code[/b]

[color=yellow][b]Implementation:[/b][/color]
[code]
func kmeans(points: Array, k: int, max_iterations: int = 100):
    # Initialize centroids randomly
    var centroids = []
    for i in range(k):
        centroids.append(points[randi() % points.size()])

    for iteration in range(max_iterations):
        # Assign points to nearest centroid
        var clusters = {}
        for i in range(k):
            clusters[i] = []

        for point in points:
            var nearest = find_nearest_centroid(point, centroids)
            clusters[nearest].append(point)

        # Recalculate centroids
        var new_centroids = []
        for i in range(k):
            if clusters[i].is_empty():
                new_centroids.append(centroids[i])  # Keep old if empty
            else:
                new_centroids.append(calculate_mean(clusters[i]))

        # Check convergence
        if centroids_equal(centroids, new_centroids):
            break

        centroids = new_centroids

    return centroids

func find_nearest_centroid(point, centroids):
    var min_dist = INF
    var nearest = 0
    for i in range(centroids.size()):
        var dist = point.distance_to(centroids[i])
        if dist < min_dist:
            min_dist = dist
            nearest = i
    return nearest
[/code]

**Result:** Points grouped into K clusters.

[hr]

[b]Properties[/b]

- **K must be chosen** (algorithm doesn't determine number of clusters)
- **Sensitive to initialization** (different starts → different results)
- **Assumes spherical clusters** (fails on non-convex shapes)
- **Local optimum** (not guaranteed global best)

[hr]

[b]Queer K-Means[/b]

**K-means forces discrete categories** - every point MUST belong to exactly one cluster.

**This is categorical violence:**
- **K predetermined** (number of identities fixed in advance)
- **Hard assignment** (no in-between, no multiple memberships)
- **Centroid normativity** (cluster defined by center, not diversity)
- **Distance metric** (similarity defined by single measure)

**Queer resistance:**
- **Fuzzy clustering** (soft memberships, belong to multiple clusters)
- **Unknown K** (discover number of categories, don't impose)
- **Non-spherical** (embrace complex cluster shapes)
- **Multiple metrics** (similarity is contextual, not singular)

**K-means assumes identity is discrete, singular, pre-countable.** **Queerness refuses.**

[hr]

[color=cyan][b]Summary:[/b][/color]
K-means: partition points into K clusters via centroid iteration. Initialize centroids, assign to nearest, recalculate means, repeat. Properties: K predetermined, initialization-sensitive, assumes spherical, local optimum. Queer K-means: forces discrete categories, hard assignment (no multiplicity), centroid normativity, single distance metric. Queer resistance: fuzzy membership, unknown K, non-spherical, multiple similarity measures.

'''
