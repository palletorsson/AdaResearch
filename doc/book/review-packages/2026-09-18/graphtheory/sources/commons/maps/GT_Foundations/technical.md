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

## Data Structures and Memory

The adjacency list is the most common graph representation in practice. It stores, for each vertex, a collection of its neighbours. Space is O(V + E), which is efficient for sparse graphs — graphs where E is much smaller than V². Dense graphs (E close to V²) are often better represented by an adjacency matrix: a V by V boolean or weight matrix whose entry at (i,j) records the edge from i to j. Adjacency matrices use O(V²) space but offer O(1) edge-existence queries.

The map's `graphspace` artifact uses adjacency lists. The tradeoff — O(V + E) space versus O(V²) space — matters because the map's graphs are small (dozens of vertices) and sparse (a handful of edges per vertex). An adjacency matrix would waste memory on mostly-empty rows.

## Operations and Their Costs

Adding a vertex to an adjacency list is O(1) — a dictionary insertion. Adding an edge is O(1) — two dictionary insertions, one for each direction in an undirected graph. Removing a vertex is O(degree), because every incident edge must be removed from the neighbour's list. Removing an edge is O(1) if the neighbour sets are hash-backed.

Iterating over all edges is O(V + E) because every vertex must be visited and every edge enumerated once per direction. In an undirected graph, naive iteration visits each edge twice — once from each endpoint — so edge-iterating code typically applies an i < j filter to visit each edge once.

Checking edge existence is O(1) with hash-set-backed adjacency. Without the hash, edge existence is O(degree), which is fast enough for small graphs and can become a bottleneck on dense ones.

Within the sequence, Foundations trains the learner's intuition for these tradeoffs without formalising them. GT_Layout's force-directed layout revisits the adjacency list when each vertex needs to iterate its neighbours during the attraction pass, and the iteration pattern becomes a performance bottleneck at scale.

## A Small Example in Code

```gdscript
var g := GraphSpace.new()
g.add_vertex(1)
g.add_vertex(2)
g.add_vertex(3)
g.add_edge(1, 2)
g.add_edge(2, 3)
g.add_edge(3, 1)
print(g.count_odd_degree_vertices())  # 0 — all degrees are 2
print(g.eulerian_walk_possible())     # true
```

Three vertices in a triangle form the simplest Eulerian graph: every vertex has even degree, so every edge can be traversed exactly once in a single walk. Adding a fourth vertex connected to only two of the triangle's vertices introduces two odd-degree vertices, which is still Eulerian but now requires starting and ending at those odd-degree vertices.

## Parsing a Graph From Input

```gdscript
class_name GraphParser

static func parse_edge_list(text: String) -> GraphSpace:
    var g := GraphSpace.new()
    for line in text.split("\n"):
        line = line.strip_edges()
        if line.is_empty() or line.begins_with("#"): continue
        var parts := line.split_whitespace()
        if parts.size() >= 2:
            var u: int = int(parts[0])
            var v: int = int(parts[1])
            g.add_edge(u, v)
    return g
```
