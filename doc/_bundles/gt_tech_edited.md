<<<ADA_BUNDLE>>>
sequence: graphtheory
file: technical.md
maps: 8
skipped_passing: 0
created: 2026-04-23T23:50:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: GT_Foundations>>>
# GT Foundations — Technical

The map stages Euler's 1736 Königsberg bridges problem and then collapses it to an abstract graph. The `KonigsbergBridge` artifact renders the four land masses as nodes, the seven bridges as edges, and exposes a traversal mode that tries every walk the learner proposes. Every traversal that attempts to use each edge exactly once fails, and the side panel reports the failure with the vertex-degree statistic that Euler used to prove it.

A graph in this map is a pair (V, E) where V is a set of vertices and E is a set of unordered pairs drawn from V. The degree of a vertex is the count of edges incident to it. Euler's theorem is that an Eulerian walk (a walk that uses every edge exactly once) exists if and only if at most two vertices have odd degree.

```gdscript
# Simplified from KonigsbergBridge.gd
func count_odd_degree_vertices() -> int:
    var count := 0
    for v in vertices:
        if edges.count_incident(v) % 2 == 1:
            count += 1
    return count

func eulerian_walk_possible() -> bool:
    return count_odd_degree_vertices() <= 2
```

The Königsberg model fails because all four vertices have odd degree (three, three, three, five). The map lets the learner add or remove a bridge and recompute the test, so the condition's effect becomes interactive.

The `graphspace` artifact provides the general framework. It lets the learner place vertices by clicking and add edges by dragging between them. The underlying data structure is an adjacency list: a dictionary mapping each vertex to the set of vertices it is adjacent to. Space is O(V + E); edge lookups are O(1) with hash-set backing.

```gdscript
class_name GraphSpace extends Node3D

var adj: Dictionary = {}  # vertex_id -> Set[vertex_id]

func add_edge(u: int, v: int) -> void:
    adj.get_or_add(u, {})[v] = null
    adj.get_or_add(v, {})[u] = null
```

Within the sequence, Foundations sets the vocabulary the remaining maps extend. The graph structure introduced here — adjacency list, degree, connectivity — is the substrate GT_Layout, GT_Pathfinding, and every later map operates on. The Königsberg failure is the sequence's originating problem, and the general graph machinery is the answer the rest of the curriculum builds from.

Complexity-wise, the map operates on small graphs (dozens of vertices) where every algorithm is effectively free. The sequence's later maps will introduce graphs where asymptotic behaviour matters; this map stays in the regime where the learner's intuition is reliable.

<<<MAP: GT_Layout>>>
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

<<<MAP: GT_Pathfinding>>>
# GT Pathfinding — Technical

The map is a maze whose corridors are graph edges and whose junctions are graph vertices. The learner walks the maze to find the exit, and their walk implicitly executes a pathfinding algorithm. Three explicit algorithm modes — DFS, BFS, and A* — can be toggled at stations along the way, and each mode highlights the maze in a different characteristic pattern.

The `pathfinding3d` artifact exposes A* directly. A* searches the graph with a priority queue ordered by f(n) = g(n) + h(n), where g is the known cost from start to n and h is a heuristic estimate of the cost from n to goal.

```gdscript
func astar(start: Vector3i, goal: Vector3i) -> Array[Vector3i]:
    var open := PriorityQueue.new()
    open.push(start, 0.0)
    var came_from := {}
    var g_score := {start: 0.0}

    while not open.is_empty():
        var current: Vector3i = open.pop()
        if current == goal:
            return reconstruct(came_from, current)
        for nbr in neighbors(current):
            var tentative := g_score[current] + cost(current, nbr)
            if tentative < g_score.get(nbr, INF):
                g_score[nbr] = tentative
                came_from[nbr] = current
                var f := tentative + heuristic_weight * heuristic(nbr, goal)
                open.push(nbr, f)
    return []
```

The heuristic_weight parameter is the map's central control. At 0.0, A* degenerates to Dijkstra — it explores everything uniformly, guaranteed to find the optimal path. At 1.0, A* is standard: it uses the heuristic to focus the search without sacrificing optimality (provided the heuristic is admissible). Above 1.0, A* becomes greedy — it trusts the heuristic completely, potentially missing shorter paths but running faster.

DFS and BFS are simpler. DFS uses a stack and goes deep before wide; its backtrack is visible when the algorithm hits a dead end. BFS uses a queue and explores in concentric waves; its wavefront is visible as the distance-from-start increments. The three modes produce visibly different search patterns on the same maze, and the map lets the learner compare them side by side.

Movement models extend the problem. Ground-walking treats walls as impassable. Flying ignores walls entirely. Climbing treats vertical surfaces as passable. Each mode changes the neighbour function, and the change rewrites what counts as reachable.

Within the sequence, Pathfinding makes the learner's body the search algorithm and uses the body's experience as the ground truth against which the formal algorithms are compared. GT_Network_Analysis will next shift from traversal to measurement.

<<<MAP: GT_Network_Analysis>>>
# GT Network Analysis — Technical

The map computes several centrality measures on a shared graph and displays them side by side. Degree centrality counts direct edges. Betweenness centrality counts the number of shortest paths that pass through a vertex. Eigenvector centrality rewards vertices connected to other well-connected vertices.

```gdscript
# Degree centrality: O(V)
func degree_centrality() -> Dictionary:
    var c := {}
    for v in vertices:
        c[v] = adj[v].size()
    return c

# Betweenness: O(V * (V + E)) using Brandes' algorithm
func betweenness_centrality() -> Dictionary:
    var b := {}
    for v in vertices:
        b[v] = 0.0
    for s in vertices:
        var stack := []
        var preds := {}
        var sigma := {s: 1}
        var dist := {s: 0}
        var queue := [s]
        # ... shortest-path BFS omitted for brevity ...
        # Accumulate contributions on the reverse-stack pass
    return b
```

Betweenness is the expensive measure. Brandes' algorithm computes it in O(V·(V+E)) time for unweighted graphs, which is tractable for graphs up to a few thousand vertices. Naive implementations that enumerate all shortest paths are O(V³) and become impractical much sooner. The map uses Brandes because the interactive parameter-tuning the map rewards requires recomputing betweenness frequently.

Eigenvector centrality is computed by power iteration on the adjacency matrix: repeatedly multiply a vector by the adjacency matrix and normalise until the result stabilises. For a graph with N vertices and E edges, each iteration is O(E), and convergence takes O(log(1/ε)/log(λ₁/λ₂)) iterations where λ₁ and λ₂ are the dominant and second eigenvalues. In practice, twenty iterations is usually enough.

The `networkflow3d` artifact adds flow analysis. Pipes replace edges with capacity-bounded throughput; a source-to-sink flow is computed using Ford-Fulkerson or push-relabel. The algorithms differ in their approach: Ford-Fulkerson augments along paths iteratively; push-relabel operates locally by pushing flow to neighbours and relabelling vertices when pushes block.

Within the sequence, Network_Analysis is the measurement chapter. The previous map staged traversal; this map stages quantification. GT_Connectivity will next introduce directed edges and the asymmetric reachability they produce.

<<<MAP: GT_Connectivity>>>
# GT Connectivity — Technical

The map introduces directed graphs. An edge from A to B does not imply an edge from B to A, and reachability becomes asymmetric. Three rooms in the map correspond to three strongly connected components: maximal subgraphs in which every vertex can reach every other via directed edges.

Tarjan's algorithm finds strongly connected components in O(V + E) time using a single DFS pass with a stack. Kosaraju's algorithm achieves the same bound with two DFS passes on the graph and its transpose.

```gdscript
# Tarjan's SCC — simplified
func tarjan_scc() -> Array:
    var index := 0
    var stack := []
    var on_stack := {}
    var indices := {}
    var lowlink := {}
    var sccs := []

    var dfs := func(v):
        indices[v] = index
        lowlink[v] = index
        index += 1
        stack.push_back(v)
        on_stack[v] = true
        for w in adj_out[v]:
            if not indices.has(w):
                dfs.call(w)
                lowlink[v] = min(lowlink[v], lowlink[w])
            elif on_stack.get(w, false):
                lowlink[v] = min(lowlink[v], indices[w])
        if lowlink[v] == indices[v]:
            var comp := []
            while true:
                var w = stack.pop_back()
                on_stack[w] = false
                comp.append(w)
                if w == v: break
            sccs.append(comp)

    for v in vertices:
        if not indices.has(v):
            dfs.call(v)
    return sccs
```

The key insight is the lowlink value: it tracks the earliest reachable index from v through the DFS subtree plus at most one back-edge. When a vertex's lowlink equals its own index, the vertex is the root of an SCC, and the elements of the stack above it (up to and including the vertex itself) form the component.

The map's three rooms correspond to the three SCCs of a constructed example graph. Within each room the learner can move freely; between rooms the doors are one-way, reflecting the directed inter-component edges. Walking between rooms traces the structure of the directed graph at body scale.

Once components are identified, they collapse to a directed acyclic graph (DAG) in which each component is a single node. The DAG can be topologically sorted with a second pass — Kahn's algorithm or a reverse-DFS — in O(V + E) time.

Within the sequence, Connectivity is where direction becomes load-bearing. The edge-list data structure that worked for undirected graphs is replaced by a pair of adjacency lists (out-neighbours and in-neighbours), and the algorithms are rewritten to respect the asymmetry. GT_Spanning_Trees will next ask how to cover a graph most cheaply.

<<<MAP: GT_Spanning_Trees>>>
# GT Spanning Trees — Technical

A minimum spanning tree (MST) is a subset of edges that connects every vertex and minimises total edge weight. The map implements both Kruskal's and Prim's algorithms and shows their step-by-step progress.

Kruskal's algorithm sorts all edges by weight, then adds them greedily, skipping any edge that would form a cycle with the edges already chosen. Cycle detection uses a disjoint-set (union-find) data structure:

```gdscript
class UnionFind:
    var parent: Dictionary = {}
    var rank: Dictionary = {}

    func find(x):
        if parent[x] != x:
            parent[x] = find(parent[x])  # path compression
        return parent[x]

    func union(x, y) -> bool:
        var rx = find(x)
        var ry = find(y)
        if rx == ry: return false  # would form cycle
        if rank[rx] < rank[ry]:
            parent[rx] = ry
        elif rank[rx] > rank[ry]:
            parent[ry] = rx
        else:
            parent[ry] = rx
            rank[rx] += 1
        return true

func kruskal() -> Array:
    var tree := []
    var uf := UnionFind.new()
    for v in vertices: uf.parent[v] = v
    edges.sort_custom(func(a, b): return a.weight < b.weight)
    for e in edges:
        if uf.union(e.a, e.b):
            tree.append(e)
            if tree.size() == vertices.size() - 1: break
    return tree
```

Union-find with path compression and union-by-rank supports find and union in effectively O(α(V)) amortised time, where α is the inverse Ackermann function (practically constant). The sort dominates: O(E log E) total.

Prim's algorithm grows the tree from a root vertex by repeatedly adding the lightest edge that connects a new vertex to the existing tree. A priority queue maintains the candidate edges, giving O((V + E) log V) with a binary heap or O(E + V log V) with a Fibonacci heap.

The two algorithms produce the same tree when edge weights are distinct. The map animates them side by side so the learner can see the different orders in which the same edges are selected.

The scattered platforms in the map at varying heights make edge weights physical — longer connections cost more, shorter ones cost less. Building the MST by hand produces the same tree the algorithms find automatically, which confirms that the problem has a structural optimum rather than an algorithmic one.

Within the sequence, Spanning_Trees is the optimisation-on-structure chapter. GT_Flow will next optimise throughput rather than structure.

<<<MAP: GT_Flow>>>
# GT Flow — Technical

A flow network is a directed graph with a source vertex s, a sink vertex t, and a capacity c(u,v) on every edge. The max-flow problem finds the maximum amount of flow that can be pushed from s to t without exceeding any edge's capacity.

Ford-Fulkerson repeatedly finds an augmenting path (a source-to-sink path with positive residual capacity) and pushes flow along it. With BFS-based augmentation (Edmonds-Karp), the running time is O(V·E²). Push-relabel algorithms are asymptotically faster — O(V²·E) or O(V³) in the standard variants — and often faster in practice because they operate locally.

```gdscript
# Edmonds-Karp — BFS augmentation
func max_flow(source, sink) -> float:
    var flow: Dictionary = {}  # edge -> amount
    var residual := build_residual()
    var total := 0.0
    while true:
        var path := bfs_augmenting_path(residual, source, sink)
        if path.is_empty(): break
        var bottleneck := INF
        for e in path:
            bottleneck = min(bottleneck, residual[e])
        for e in path:
            residual[e] -= bottleneck
            residual[reverse(e)] = residual.get(reverse(e), 0) + bottleneck
            flow[e] = flow.get(e, 0) + bottleneck
        total += bottleneck
    return total
```

The key data structure is the residual graph. For every edge (u,v) with capacity c and current flow f, the residual graph contains (u,v) with capacity c − f and (v,u) with capacity f. The reverse edges allow the algorithm to undo previously routed flow when a better routing becomes available.

The max-flow min-cut theorem says that the maximum flow equals the minimum s-t cut — the smallest total edge capacity whose removal disconnects s from t. The map displays the cut visibly as a line across the network, and the cut's capacity matches the flow on every frame.

The funnel geometry in the map makes the bottleneck physical. The narrowing exit means the flow is capped by the exit's capacity regardless of the internal network, and the learner can feel the constraint as a physical architecture rather than as a numerical bound.

Within the sequence, Flow is the throughput chapter. The next and final map, GT_Matching, closes the sequence by turning the flow machinery toward a different kind of optimisation.

<<<MAP: GT_Matching>>>
# GT Matching — Technical

A matching is a subset of edges in which every vertex is incident to at most one edge. A perfect matching covers every vertex. A maximum matching is one with the most possible edges.

Bipartite matching is the easier case. The Hungarian algorithm solves the weighted bipartite matching problem in O(V³) using augmenting paths in a residual graph derived from the bipartite structure. The unweighted case — maximum bipartite matching — reduces to max-flow by adding a source connected to one side and a sink connected to the other, and can be solved in O(V·E) with Hopcroft-Karp.

```gdscript
# Hopcroft-Karp bipartite matching
func bipartite_matching(left, right, edges_lr) -> Dictionary:
    var matching := {}  # right_vertex -> left_vertex
    var improved := true
    while improved:
        improved = false
        var layers := bfs_layers(matching, left, right, edges_lr)
        if layers.is_empty(): break
        for u in left:
            if not matching.values().has(u):
                if dfs_augment(u, layers, matching, edges_lr):
                    improved = true
    return matching
```

General matching (matching in arbitrary graphs) is harder because of odd cycles. Edmonds' blossom algorithm handles this by contracting odd-length augmenting cycles into single pseudo-nodes (blossoms), finding augmenting paths through the contracted graph, and expanding the contractions back out once the matching is extended. The algorithm runs in O(V³) in the classical formulation; Micali-Vazirani improves this to O(V·√E).

The blossom contraction is the algorithm's distinctive move. When a BFS for augmenting paths discovers an odd cycle, the cycle is contracted into a super-vertex, the search continues from the super-vertex, and any augmenting path found through the super-vertex is expanded by lifting it back through the contraction when the matching is updated.

The map's two symmetric halves stage the bipartite case visually. Each side holds a set of vertices; edges run between the sides; the Hungarian algorithm finds the maximum matching and draws it as a set of thick edges. A toggle switches to general-graph mode, where odd cycles become possible and the blossom algorithm takes over.

Within the sequence, Matching is the capstone. It closes Graph Theory and the whole spine. The map argues that fair, exclusive, complete allocation is a graph problem, and the algorithms the sequence has built are enough to solve it.
