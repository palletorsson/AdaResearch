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

## Weakly vs Strongly Connected

A directed graph is strongly connected if every vertex can reach every other vertex. It is weakly connected if the underlying undirected graph (ignoring directions) is connected but the directed version is not. Most real directed graphs are weakly connected but not strongly connected.

The map's three-room architecture corresponds to a graph that is weakly connected globally (you can reach any room from any other if you ignore directions) but contains three strongly connected components internally (within each room, you can reach any vertex from any other).

## Condensation

Collapsing each SCC to a single vertex produces the condensation graph. The condensation is always a DAG — acyclic — because any cycle in the condensation would contradict the maximality of the components it spans.

```gdscript
func condense(sccs: Array) -> Dictionary:
    var scc_id := {}
    for i in range(sccs.size()):
        for v in sccs[i]:
            scc_id[v] = i
    var condensation := {}
    for e in edges:
        var a := scc_id[e.u]
        var b := scc_id[e.v]
        if a != b:
            condensation.get_or_add(a, {})[b] = null
    return condensation
```

Topological sort on the condensation gives a linear ordering of the components such that every directed edge runs from an earlier component to a later one.

## Articulation Points and Bridges

Tarjan's algorithm also finds articulation points (vertices whose removal disconnects the graph) and bridges (edges whose removal disconnects the graph). These are related to SCCs but live in undirected graphs and use the same DFS-with-lowlink machinery.

```gdscript
func find_bridges(graph) -> Array:
    var bridges := []
    var index := 0
    var indices := {}
    var lowlink := {}
    var dfs := func(u, parent):
        indices[u] = index
        lowlink[u] = index
        index += 1
        for v in graph[u]:
            if not indices.has(v):
                dfs.call(v, u)
                lowlink[u] = min(lowlink[u], lowlink[v])
                if lowlink[v] > indices[u]:
                    bridges.append([u, v])
            elif v != parent:
                lowlink[u] = min(lowlink[u], indices[v])
    for u in graph:
        if not indices.has(u):
            dfs.call(u, null)
    return bridges
```

Within the sequence, Connectivity is where direction becomes load-bearing. GT_Spanning_Trees will next ask how to cover a graph most cheaply.
