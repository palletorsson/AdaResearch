**Graph Theory Basics**
Nodes, Edges, Networks, Connectivity

**Graphs model relationships: nodes (vertices) connected by edges.**

**Components:**
- **Nodes** (vertices) - entities
- **Edges** - connections between nodes
- **Directed** vs **Undirected** (one-way vs two-way)
- **Weighted** edges (connection strength)

---

## Basic Operations

**Code:**

class Graph:
    var nodes: Array = []
    var edges: Dictionary = {}  # node -> 

    func add_node(node):
        nodes.append(node)
        edges = []

    func add_edge(from_node, to_node):
        edges.append(to_node)
        # If undirected:
        edges.append(from_node)

    func get_neighbors(node) -> Array:
        return edges

# Traversal (BFS)
func breadth_first_search(graph: Graph, start_node):
    var queue = 
    var visited = {}

    while not queue.is_empty():
        var current = queue.pop_front()
        if current in visited:
            continue

        visited = true
        print(