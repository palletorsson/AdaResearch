# Graph Theory Algorithms Collection

## Overview
Explore the mathematical world of networks, connections, and relationships through immersive VR visualizations. From social networks to transportation systems, discover how graph algorithms solve complex connectivity problems.

## Contents

### 🌐 **Core Graph Algorithms**
- **[Pathfinding](pathfinding/)** - Shortest path algorithms (Dijkstra, A*, BFS/DFS)
- **[Minimum Spanning Tree](minimumspanningtree/)** - Kruskal's and Prim's algorithms for optimal connectivity
- **[Network Flow](networkflow/)** - Maximum flow and minimum cut algorithms

## 🎯 **Learning Objectives**
- Master fundamental graph traversal and search algorithms
- Understand network optimization and flow problems
- Visualize complex network structures in 3D space
- Explore real-world applications of graph theory
- Experience the elegance of graph-based problem solving

## 📊 **Graph Fundamentals**

### **Graph Representations**
```gdscript
# Adjacency List Representation
class Graph:
    var vertices: Dictionary = {}
    
    func add_edge(from: String, to: String, weight: float = 1.0):
        if not vertices.has(from):
            vertices[from] = []
        if not vertices.has(to):
            vertices[to] = []
        
        vertices[from].append({"to": to, "weight": weight})
        # For undirected graphs:
        # vertices[to].append({"to": from, "weight": weight})

# Adjacency Matrix Representation
class MatrixGraph:
    var matrix: Array[Array]
    var vertex_names: Array[String]
    
    func set_edge(from_idx: int, to_idx: int, weight: float):
        matrix[from_idx][to_idx] = weight
```

### **Graph Types**
- **Directed vs Undirected**: Edge directionality
- **Weighted vs Unweighted**: Edge costs or distances
- **Cyclic vs Acyclic**: Presence of cycles
- **Connected vs Disconnected**: Vertex reachability
- **Planar vs Non-planar**: Drawable without edge crossings

## 🛣️ **Pathfinding Algorithms**

### **Single-Source Shortest Path**
- **Dijkstra's Algorithm**: Non-negative weights, O((V+E) log V)
- **Bellman-Ford**: Handles negative weights, detects negative cycles
- **A* Search**: Heuristic-guided pathfinding for optimal routes
- **Breadth-First Search**: Unweighted graphs, shortest hop count

### **All-Pairs Shortest Path**
- **Floyd-Warshall**: O(V³) algorithm for all vertex pairs
- **Johnson's Algorithm**: Sparse graphs with negative weights
- **Matrix Multiplication**: Theoretical approach using linear algebra

```gdscript
# Dijkstra's Algorithm Implementation
func dijkstra(graph: Graph, start: String) -> Dictionary:
    var distances = {}
    var previous = {}
    var unvisited = PriorityQueue.new()
    
    # Initialize distances
    for vertex in graph.vertices:
        distances[vertex] = INF
        previous[vertex] = null
        unvisited.insert(vertex, INF)
    
    distances[start] = 0
    unvisited.decrease_key(start, 0)
    
    while not unvisited.is_empty():
        var current = unvisited.extract_min()
        
        for edge in graph.vertices[current]:
            var neighbor = edge.to
            var alt_distance = distances[current] + edge.weight
            
            if alt_distance < distances[neighbor]:
                distances[neighbor] = alt_distance
                previous[neighbor] = current
                unvisited.decrease_key(neighbor, alt_distance)
    
    return {"distances": distances, "previous": previous}
```

## 🌳 **Spanning Trees**

### **Minimum Spanning Tree (MST)**
- **Kruskal's Algorithm**: Edge-based approach using union-find
- **Prim's Algorithm**: Vertex-based approach with priority queue
- **Borůvka's Algorithm**: Parallel-friendly MST construction

### **Applications**
- **Network Design**: Minimum cost connectivity
- **Clustering**: Finding natural groupings in data
- **Image Segmentation**: Computer vision applications
- **Phylogenetic Trees**: Evolutionary relationship modeling

## 💧 **Network Flow**

### **Maximum Flow Problems**
- **Ford-Fulkerson Method**: Augmenting path approach
- **Edmonds-Karp Algorithm**: BFS-based implementation
- **Dinic's Algorithm**: Blocking flow method
- **Push-Relabel**: Preflow-based maximum flow

### **Flow Applications**
- **Transportation**: Optimal cargo routing
- **Communication**: Bandwidth allocation
- **Matching**: Bipartite graph matching problems
- **Cut Problems**: Finding bottlenecks in networks

## 🚀 **VR Experience**

### **Interactive Graph Exploration**
- **3D Graph Visualization**: Navigate through complex network structures
- **Node Manipulation**: Add, remove, and connect vertices with hand controllers
- **Algorithm Animation**: Watch pathfinding and spanning tree algorithms execute
- **Flow Visualization**: See network flow as animated particles

### **Immersive Learning**
- **Scale Adaptation**: From small graphs to massive networks
- **Multi-perspective Views**: Observe graphs from different dimensional projections
- **Real-time Modification**: Change weights and connections during algorithm execution
- **Comparative Analysis**: Run multiple algorithms simultaneously

## 🌐 **Network Analysis**

### **Graph Metrics**
- **Centrality Measures**: Identifying important vertices
  - Degree Centrality: Number of connections
  - Betweenness Centrality: Bridge importance
  - Closeness Centrality: Average distance to all vertices
  - Eigenvector Centrality: Influence based on connections
- **Clustering Coefficient**: Local connectivity density
- **Small World Properties**: Six degrees of separation phenomena

### **Community Detection**
- **Modularity Optimization**: Finding natural communities
- **Hierarchical Clustering**: Multi-level community structure
- **Label Propagation**: Community assignment through neighbor influence
- **Spectral Clustering**: Eigenvalue-based partitioning

## 🔗 **Related Categories**
- [Data Structures](../datastructures/) - Graph representation and storage
- [Machine Learning](../machinelearning/) - Graph neural networks and clustering
- [Optimization](../optimization/) - Network optimization problems
- [Emergent Systems](../emergentsystems/) - Network dynamics and emergence

## 🌍 **Real-World Applications**

### **Social Networks**
- **Influence Analysis**: Understanding information spread
- **Community Detection**: Finding groups and clusters
- **Recommendation Systems**: Friend and content suggestions
- **Viral Marketing**: Optimal information dissemination

### **Transportation & Logistics**
- **Route Planning**: GPS navigation and traffic optimization
- **Supply Chain**: Optimal distribution networks
- **Public Transit**: Efficient transportation systems
- **Delivery Optimization**: Package routing and scheduling

### **Communication Networks**
- **Internet Routing**: Packet forwarding protocols
- **Network Reliability**: Fault tolerance and redundancy
- **Bandwidth Allocation**: Resource optimization
- **Wireless Networks**: Interference and coverage optimization

### **Biological Networks**
- **Protein Interactions**: Understanding cellular processes
- **Neural Networks**: Brain connectivity analysis
- **Metabolic Pathways**: Biochemical reaction networks
- **Evolutionary Trees**: Species relationship mapping

## 📊 **Algorithm Complexity**

| Algorithm | Time Complexity | Space Complexity | Use Case |
|-----------|-----------------|------------------|----------|
| BFS/DFS | O(V + E) | O(V) | Traversal, connectivity |
| Dijkstra | O((V + E) log V) | O(V) | Single-source shortest path |
| Kruskal | O(E log E) | O(V) | Minimum spanning tree |
| Ford-Fulkerson | O(E × max_flow) | O(V) | Maximum flow |

## 🎨 **Visualization Techniques**
- **Force-Directed Layout**: Physics-based graph positioning
- **Hierarchical Layout**: Tree-like structure visualization
- **Circular Layout**: Symmetric arrangement for analysis
- **Geographic Layout**: Location-based positioning
- **Multi-dimensional Scaling**: Dimension reduction for large graphs

---
*"Graph theory is ultimately the study of relationship." - Robin Wilson*

*Discovering the hidden connections that shape our networked world*