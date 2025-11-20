extends Node

var text = '''[center][font_size=28][b]Graph Theory Basics[/b][/font_size][/center]
[center][i]Nodes, Edges, Networks, Connectivity[/i][/center]

**Graphs model relationships: nodes (vertices) connected by edges.**

**Components:**
- **Nodes** (vertices) - entities
- **Edges** - connections between nodes
- **Directed** vs **Undirected** (one-way vs two-way)
- **Weighted** edges (connection strength)

[hr]

[b]Basic Operations[/b]

[color=yellow][b]Code:[/b][/color]
[code]
class Graph:
    var nodes: Array = []
    var edges: Dictionary = {}  # node -> [connected_nodes]

    func add_node(node):
        nodes.append(node)
        edges[node] = []

    func add_edge(from_node, to_node):
        edges[from_node].append(to_node)
        # If undirected:
        edges[to_node].append(from_node)

    func get_neighbors(node) -> Array:
        return edges[node]

# Traversal (BFS)
func breadth_first_search(graph: Graph, start_node):
    var queue = [start_node]
    var visited = {}

    while not queue.is_empty():
        var current = queue.pop_front()
        if current in visited:
            continue

        visited[current] = true
        print("Visiting:", current)

        for neighbor in graph.get_neighbors(current):
            if neighbor not in visited:
                queue.append(neighbor)
[/code]

[hr]

[b]Key Algorithms[/b]

- **BFS/DFS** - traversal
- **Dijkstra** - shortest path
- **MST** (Prim, Kruskal) - minimum spanning tree
- **PageRank** - node importance (Google)

[hr]

[b]Queer Graphs[/b]

**Graphs model relationships** - not hierarchies, but networks.

**Queer networks:**
- **Non-hierarchical** (no root, no top)
- **Multiple connections** (not tree structure - can have cycles)
- **Chosen family** (edges = relationships, not bloodlines)
- **Degrees of separation** (queer communities as connected graphs)

**Graph theory formalizes network thinking** - relations, not categories.

[hr]

[color=cyan][b]Summary:[/b][/color]
Graphs: nodes + edges. Directed/undirected, weighted. Traversal (BFS/DFS), shortest path (Dijkstra), PageRank. Queer graphs: non-hierarchical networks, chosen family as edges, community connectivity, relations not categories.

'''
