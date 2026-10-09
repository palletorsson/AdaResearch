# GT Network Analysis

Which node matters most? Degree, betweenness, eigenvector.

Compute degree centrality.

```gdscript
func degree_centrality(g: Graph) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices:
        c[v] = float(g.degree(v)) / (g.vertices.size() - 1)
    return c
```

Normalised by the maximum possible degree. Values in [0, 1].

Compute betweenness via Brandes.

```gdscript
func betweenness_centrality(g: Graph) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices: c[v] = 0.0
    for s in g.vertices:
        var dist: Dictionary = {s: 0}
        var sigma: Dictionary = {s: 1}
        var pred: Dictionary = {}
        var queue: Array = [s]
        var stack: Array = []
        while not queue.is_empty():
            var u = queue.pop_front()
            stack.push_back(u)
            for w in g.neighbours(u):
                if not w in dist:
                    dist[w] = dist[u] + 1
                    queue.push_back(w)
                if dist[w] == dist[u] + 1:
                    sigma[w] = sigma.get(w, 0) + sigma[u]
                    pred.get_or_add(w, [])
                    pred[w].append(u)
        var delta: Dictionary = {}
        for v in g.vertices: delta[v] = 0.0
        while not stack.is_empty():
            var w = stack.pop_back()
            for u in pred.get(w, []):
                delta[u] += sigma[u] / float(sigma[w]) * (1 + delta[w])
            if w != s:
                c[w] += delta[w]
    return c
```

Brandes' algorithm computes betweenness in O(V·(V+E)). Counts shortest paths passing through each vertex.

Compute eigenvector centrality via power iteration.

```gdscript
func eigenvector_centrality(g: Graph, iterations: int = 50) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices: c[v] = 1.0
    for _i in iterations:
        var next: Dictionary = {}
        for v in g.vertices:
            next[v] = 0.0
            for u in g.neighbours(v):
                next[v] += c[u]
        var norm: float = 0.0
        for v in g.vertices: norm += next[v] * next[v]
        norm = sqrt(norm)
        if norm > 0:
            for v in g.vertices: next[v] /= norm
        c = next
    return c
```

Power iteration on the adjacency matrix. Converges to the dominant eigenvector.

Compute closeness centrality.

```gdscript
func closeness_centrality(g: Graph) -> Dictionary:
    var c: Dictionary = {}
    for v in g.vertices:
        var total: int = 0
        var distances: Dictionary = bfs_distances(v, g.adjacency_list())
        for other in distances:
            total += distances[other]
        c[v] = 1.0 / total if total > 0 else 0.0
    return c
```

Reciprocal of average shortest-path distance. High closeness means short average reach.

Colour vertices by centrality.

```gdscript
func colour_by_centrality(centrality: Dictionary) -> void:
    var max_c: float = centrality.values().max()
    for child in get_children():
        if child.has_meta("vertex_id"):
            var v = child.get_meta("vertex_id")
            var t: float = centrality[v] / max_c if max_c > 0 else 0.0
            var mat: StandardMaterial3D = child.material_override
            mat.albedo_color = Color.BLUE.lerp(Color.RED, t)
```

Blue for low centrality, red for high. Visual ranking of importance.

You can now compute degree, betweenness, eigenvector, and closeness centralities, and colour the graph by any of them. GT_Connectivity extends into directed graphs.

Detect a central node.

```gdscript
func most_central(centrality: Dictionary):
    var best = null
    var best_score: float = -INF
    for v in centrality:
        if centrality[v] > best_score:
            best_score = centrality[v]
            best = v
    return best
```

Return the vertex with highest centrality. Useful as a graph's designated hub.


<!-- study-spine:evidence_network -->

## Return: A relation needs a record

Remove one recorded relation; compare incoming and outgoing counts before moving the layout. Begin with the supplied study in the museum and compare the two states from the same place. Name what remained fixed before inspecting the code.

This application reuses graph, line, array. The small edit belongs to the learner; the display, main player and physical controls are supplied. Its adapter is `commons/artifacts/spine_studies/station.gd` (`network`), which calls the study’s own setters. Change one parameter, predict the visible consequence, then test another value. Reconstructing every mesh is not a prerequisite for this encounter.

[Study and making notes](/book-review/doc/book/iterations/2026-10-02-relations-sentences-and-witnesses/index.html). The display stays fixed while its data, words or images change. RESET returns the original comparison.

<!-- study-edit:evidence_network -->

### One source change: A relation needs a record

In RECORDS, remove this final entry. Predict whose incoming and outgoing counts fall by one. FILTER to payment, then change LAYOUT: a different position must not create a different count. These are fictional source records, not historical evidence. The curved-line renderer is supplied.

```gdscript
[3,7,"payment","04-16","P04: Office pays Maintenance 1 unit."]
```

Source: `commons/artifacts/spine_studies/evidence_network.gd`. Use the prepared scene to run and compare.

<!-- study-reference:evidence_network -->

### Reference and scope

Lombardi assembled narrative structures from researched relations. Our invented institutional records make provenance inspectable without pretending to reconstruct his historical investigations.

[Whitney Museum: Mark Lombardi](https://whitney.org/artists/7340).
