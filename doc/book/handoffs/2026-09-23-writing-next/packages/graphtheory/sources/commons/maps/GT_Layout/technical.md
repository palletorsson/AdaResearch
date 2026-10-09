# GT Layout — Technical

The map lays out a graph by running a force-directed simulation. Every vertex repels every other vertex according to an inverse-square Coulomb-like force; every edge pulls its two endpoints together with a Hookean spring force. The graph settles when the two contributions balance.

```gdscript
# Simplified force step from GraphLayoutRig.gd
func _physics_process(dt: float) -> void:
    # Repulsion: O(V^2)
    for u in vertices:
        for v in vertices:
            if u == v: continue
            var d := v.position - u.position
            var r := d.length() + 0.01  # avoid divide-by-zero
            var f := repulsion_k / (r * r)
            u.velocity -= d.normalized() * f * dt

    # Attraction: O(E)
    for e in edges:
        var d := e.b.position - e.a.position
        var f := spring_k * (d.length() - e.rest_length)
        e.a.velocity += d.normalized() * f * dt
        e.b.velocity -= d.normalized() * f * dt

    # Integrate and dampen
    for v in vertices:
        v.position += v.velocity * dt
        v.velocity *= damping
```

The repulsion pass is O(V²) and dominates the cost. For graphs with more than a few hundred vertices, a Barnes-Hut approximation reduces this to O(V log V) by clustering distant repulsion contributions. The map's graphs are small enough that the naive O(V²) path is adequate, and the naive path is what the code above shows.

The equilibrium is not unique. Different initial positions produce different settled configurations, all of which satisfy the force balance. A re-seed button randomises positions and re-runs, so the learner can run the same graph repeatedly and see that the final layout is a function of the initial conditions.

The repulsion_k and spring_k parameters have a product that determines the graph's characteristic spacing. Raising repulsion_k spreads the graph wider; raising spring_k pulls connected vertices tighter. A small damping factor (0.8–0.95) is needed to avoid oscillation, and the map exposes all three parameters as sliders.

Within the sequence, Layout converts the abstract graph from GT_Foundations into a spatial display. The force vocabulary is borrowed from the Forces sequence, and the borrowing is deliberate — the map argues that graph layout is an applied physics problem, not a pure geometry problem. The next map, GT_Pathfinding, will treat the laid-out graph as a searchable space and put the learner's body into the search.

## Convergence and Parameter Tuning

The force-directed simulation does not always converge. If repulsion is too strong relative to attraction, the graph expands without bound; if attraction dominates, vertices collapse to a single point. The damping factor controls the rate at which kinetic energy leaves the system, and without damping the simulation oscillates indefinitely.

A practical stability condition is that the product of spring_k and damping exceeds a threshold that depends on the graph's topology. The map chooses default parameters that work for graphs up to a few hundred vertices. Beyond that, repulsion dominates and the layout drifts — the Barnes-Hut approximation is the standard remedy.

## Stress and Embedding Quality

Layout quality is usually measured by stress: the sum over pairs (u, v) of the squared difference between the graph-theoretic distance (edge count) and the spatial distance (Euclidean). A good layout has low stress, meaning the spatial distances approximate the graph distances.

```gdscript
func compute_stress() -> float:
    var stress := 0.0
    for u in vertices:
        var dists := bfs_distances(u)
        for v in vertices:
            if u == v: continue
            var gd: float = dists[v]
            var sd: float = (v.position - u.position).length()
            stress += (gd - sd) * (gd - sd)
    return stress
```

Stress-minimising layouts can be computed directly via majorisation, but force-directed algorithms are simpler and produce similar results for most graphs. The map uses force-directed because the algorithm's per-frame iterative nature is visually legible — the layout is seen to settle rather than appearing fully formed.

Within the sequence, Layout's physics borrowing prefigures the stress metric: springs pulled to rest length implicitly minimise graph-distance error. GT_Pathfinding will next treat the laid-out graph as a navigable space the learner can walk through.

## One More Note on Initial Positions

Initial positions matter for convergence. Randomly distributed positions avoid the degenerate case where all vertices start at the origin and repulsion has no direction to work with. The map seeds initial positions in a unit sphere around the centre of the arena.
