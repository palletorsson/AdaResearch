# Minimum Spanning Tree Visualization

## 🌳 Connection Politics & Optimal Networks

A comprehensive implementation of Minimum Spanning Tree algorithms including Kruskal's algorithm with Union-Find, Prim's algorithm with priority queues, and interactive graph visualization. This implementation explores network connectivity, optimal resource allocation, and the politics of choosing which connections to prioritize in interconnected systems.

## 🎯 Algorithm Overview

Minimum Spanning Tree algorithms find the subset of edges in a weighted, connected graph that connects all vertices with the minimum total edge weight. MSTs are fundamental in network design, representing optimal ways to connect components with minimal cost.

### Key Concepts

1. **Spanning Tree**: A subgraph that connects all vertices with exactly V-1 edges
2. **Minimum Spanning Tree**: The spanning tree with minimum total edge weight
3. **Cut Property**: For any cut, the minimum weight edge crossing the cut is in some MST
4. **Cycle Property**: For any cycle, the maximum weight edge is not in any MST
5. **Union-Find**: Efficient data structure for tracking connected components
6. **Greedy Strategy**: Both algorithms use greedy approaches with different orderings

## 🔧 Technical Implementation

### Core Algorithm Features

- **Kruskal's Algorithm**: Edge-centric approach using Union-Find data structure
- **Prim's Algorithm**: Vertex-centric approach with key values and priority
- **Borůvka's Algorithm**: Component-based parallel approach (framework included)
- **3D Graph Visualization**: Interactive network with weighted edges and MST highlighting
- **Union-Find Operations**: Path compression and union by rank optimization
- **Step-by-Step Animation**: Real-time visualization of algorithm progress

### Kruskal's Algorithm

#### Core Strategy
Sort all edges by weight and greedily add edges that don't create cycles.

```
1. Sort all edges by weight in ascending order
2. Initialize Union-Find data structure
3. For each edge (u,v) in sorted order:
   a. If Find(u) ≠ Find(v):
      - Add edge to MST
      - Union(u, v)
   b. If MST has V-1 edges, stop
4. Return MST
```

#### Time Complexity
- **Sorting**: O(E log E) where E is number of edges
- **Union-Find**: O(E α(V)) where α is inverse Ackermann function
- **Total**: O(E log E) dominated by sorting
- **Space**: O(V) for Union-Find structure

### Prim's Algorithm

#### Core Strategy
Start from arbitrary vertex and greedily add minimum weight edges to grow the MST.

```
1. Initialize all key values to infinity
2. Set key[start] = 0
3. While MST is incomplete:
   a. Find minimum key vertex not in MST
   b. Add vertex to MST
   c. Update key values of adjacent vertices
4. Return MST
```

#### Time Complexity
- **With Binary Heap**: O(E log V)
- **With Fibonacci Heap**: O(E + V log V)
- **Dense Graphs**: O(V²) with array implementation
- **Space**: O(V) for key values and MST tracking

### Union-Find Data Structure

#### Path Compression
```gdscript
func find(x):
    if parent[x] != x:
        parent[x] = find(parent[x])  # Path compression
    return parent[x]
```

#### Union by Rank
```gdscript
func union(x, y):
    root_x = find(x)
    root_y = find(y)
    
    if rank[root_x] < rank[root_y]:
        parent[root_x] = root_y
    elif rank[root_x] > rank[root_y]:
        parent[root_y] = root_x
    else:
        parent[root_y] = root_x
        rank[root_x] += 1
```

## 🎮 Interactive Controls

### Basic Controls
- **SPACE**: Start/Stop MST computation
- **R**: Reset graph and generate new random structure
- **1-3**: Switch between algorithms (Kruskal, Prim, Borůvka)
- **W**: Toggle edge weight display
- **S**: Toggle step-by-step vs. complete execution

### Configuration Parameters
- **Graph Size**: Number of vertices (4-20)
- **Edge Density**: Probability of edge existence (0.3-0.8)
- **Weight Range**: Minimum and maximum edge weights
- **Weight Type**: Euclidean distance vs. random weights
- **Starting Vertex**: Initial vertex for Prim's algorithm

## 📊 Visualization Features

### 3D Graph Representation
- **Vertices**: Blue spheres with customizable positioning
- **Edges**: Gray lines with weight labels
- **MST Edges**: Green highlighted edges in the spanning tree
- **Current Edge**: Yellow highlighting during algorithm execution
- **Rejected Edges**: Red highlighting for cycle-creating edges

### Algorithm State Display
- **Union-Find Visualization**: Component connectivity for Kruskal's
- **Key Values**: Priority display for Prim's algorithm
- **Progress Tracking**: Real-time step counting and completion status
- **Cost Analysis**: Running total of MST weight and efficiency metrics

### Interactive Features
- **Graph Editing**: Add/remove vertices and edges dynamically
- **Weight Modification**: Adjust edge weights and see MST updates
- **Algorithm Comparison**: Switch between methods on same graph
- **Step Control**: Manual progression through algorithm steps

## 🏳️‍🌈 Connection Politics Framework

### Network Connectivity Justice
MST algorithms embody fundamental questions about optimal connectivity and resource allocation:

- **Who gets connected first?** Algorithm choice affects connection ordering
- **What defines "optimal"?** Weight minimization vs. other criteria
- **How do we measure connection value?** Euclidean distance vs. social/economic cost
- **What about redundancy?** MSTs eliminate backup connections

### Algorithmic Justice Questions
1. **Connection Equity**: Does optimal connectivity serve all participants fairly?
2. **Cost Distribution**: How should connection costs be allocated across networks?
3. **Central vs. Distributed**: Prim's centralized growth vs. Kruskal's distributed edge selection
4. **Efficiency vs. Resilience**: MSTs optimize cost but eliminate redundant paths

## 🔬 Educational Applications

### Graph Theory Fundamentals
- **Spanning Trees**: Understanding tree properties in graphs
- **Greedy Algorithms**: Optimal substructure and greedy choice property
- **Data Structures**: Union-Find operations and amortized analysis
- **Algorithm Design**: Different approaches to same optimization problem

### Real-World Applications
- **Network Design**: Telecommunication and computer networks
- **Infrastructure Planning**: Roads, pipelines, electrical grids
- **Clustering**: Single-linkage clustering in machine learning
- **Circuit Design**: Minimizing wire length in VLSI design

## 📈 Performance Characteristics

### Algorithm Comparison

#### Kruskal's Algorithm
- **Best For**: Sparse graphs (E << V²)
- **Advantages**: Simple implementation, works well with sorted edge lists
- **Disadvantages**: Requires global edge sorting
- **Memory**: O(E) for edge storage plus O(V) for Union-Find

#### Prim's Algorithm
- **Best For**: Dense graphs (E ≈ V²)
- **Advantages**: No need to sort all edges, grows connected component
- **Disadvantages**: Requires priority queue operations
- **Memory**: O(V) for key values and MST tracking

#### Time Complexity Summary
| Algorithm | Best Case | Average Case | Worst Case | Space |
|-----------|-----------|--------------|------------|-------|
| Kruskal's | O(E log E) | O(E log E) | O(E log E) | O(V) |
| Prim's (Binary Heap) | O(E log V) | O(E log V) | O(E log V) | O(V) |
| Prim's (Fibonacci Heap) | O(E + V log V) | O(E + V log V) | O(E + V log V) | O(V) |

### Graph Density Impact
- **Sparse Graphs** (E = O(V)): Kruskal's more efficient
- **Dense Graphs** (E = O(V²)): Prim's more efficient
- **Complete Graphs** (E = V(V-1)/2): Prim's strongly preferred

## 🎓 Learning Objectives

### Primary Goals
1. **Master greedy algorithm design** and optimality proofs
2. **Understand Union-Find** data structure and amortized analysis
3. **Compare algorithmic approaches** to same optimization problem
4. **Analyze time/space tradeoffs** in different graph densities

### Advanced Topics
- **Minimum Bottleneck Spanning Tree**: Minimizing maximum edge weight
- **Degree-Constrained MST**: Additional constraints on vertex degrees
- **Online MST**: Dynamic algorithms for changing graphs
- **Approximation Algorithms**: Near-optimal solutions for MST variants

## 🔍 Experimental Scenarios

### Recommended Explorations

1. **Algorithm Performance Comparison**
   - Test Kruskal's vs. Prim's on graphs of varying density
   - Measure actual runtime vs. theoretical complexity
   - Analyze when each algorithm performs better

2. **Graph Structure Impact**
   - Compare MSTs on random vs. structured graphs
   - Study effect of edge weight distribution
   - Analyze MST uniqueness and alternative solutions

3. **Union-Find Optimization**
   - Compare path compression vs. naive find operations
   - Study union by rank vs. union by size
   - Measure amortized performance in practice

4. **Weight Distribution Analysis**
   - Compare Euclidean weights vs. random weights
   - Study MST properties under different weight distributions
   - Analyze correlation between graph layout and MST structure

## 🚀 Advanced Features

### Dynamic Graph Updates
- **Edge Addition**: Real-time MST updates when adding edges
- **Edge Removal**: Efficient MST reconstruction after edge deletion
- **Weight Changes**: Dynamic recomputation for modified edge weights
- **Vertex Operations**: Handling vertex addition and removal

### Visualization Enhancements
- **Animation Speed Control**: Variable-speed algorithm execution
- **Multiple MST Display**: Show alternative MSTs when they exist
- **Component Highlighting**: Visual indication of Union-Find components
- **Statistics Dashboard**: Real-time algorithm performance metrics

### Algorithm Extensions
- **Parallel MST**: Simulation of parallel Borůvka's algorithm
- **Minimum Forest**: MST computation for disconnected graphs
- **Constrained MST**: Additional constraints on spanning tree structure
- **Metric MST**: Specialized algorithms for geometric graphs

## 🎯 Critical Questions for Reflection

1. **How do different starting points affect algorithm behavior and fairness?**
2. **What are the social implications of optimizing connection costs?**
3. **When might the "minimum" spanning tree not be the most desirable?**
4. **How do MST algorithms embody particular values about network organization?**

## 📚 Further Reading

### Foundational Papers
- Kruskal, J. B. (1956). On the Shortest Spanning Subtree of a Graph
- Prim, R. C. (1957). Shortest Connection Networks and Some Generalizations
- Borůvka, O. (1926). O jistém problému minimálním (Czech, "About a Certain Minimal Problem")

### Algorithm Literature
- Cormen, T. H., et al. (2009). Introduction to Algorithms (Chapter 23)
- Kleinberg, J., & Tardos, E. (2005). Algorithm Design (Chapter 4)
- Tarjan, R. E. (1975). Efficiency of a Good But Not Linear Set Union Algorithm

### Critical Algorithm Studies
- Winner, L. (1980). Do Artifacts Have Politics?
- Star, S. L. (1999). The Ethnography of Infrastructure
- Bowker, G. C., & Star, S. L. (2000). Sorting Things Out: Classification and Its Consequences

## 🔧 Technical Implementation Details

### Kruskal's Algorithm Implementation
```gdscript
func kruskals_mst():
    var mst = []
    var sorted_edges = edges.duplicate()
    sorted_edges.sort_custom(func(a, b): return a.weight < b.weight)
    
    initialize_union_find()
    
    for edge in sorted_edges:
        if find(edge.from) != find(edge.to):
            mst.append(edge)
            union(edge.from, edge.to)
            
            if mst.size() == vertices.size() - 1:
                break
    
    return mst
```

### Prim's Algorithm Implementation
```gdscript
func prims_mst():
    var mst = []
    var in_mst = Array()
    var key = Array()
    
    # Initialize
    in_mst.resize(vertices.size())
    key.resize(vertices.size())
    in_mst.fill(false)
    key.fill(INF)
    key[0] = 0
    
    for _ in range(vertices.size()):
        var u = extract_min_key(key, in_mst)
        in_mst[u] = true
        
        for v in adjacency_list[u]:
            var weight = get_edge_weight(u, v)
            if not in_mst[v] and weight < key[v]:
                key[v] = weight
                parent[v] = u
    
    return mst
```

### Union-Find with Optimizations
```gdscript
func find_with_path_compression(x):
    if parent[x] != x:
        parent[x] = find_with_path_compression(parent[x])
    return parent[x]

func union_by_rank(x, y):
    var root_x = find_with_path_compression(x)
    var root_y = find_with_path_compression(y)
    
    if root_x == root_y:
        return false
    
    if rank[root_x] < rank[root_y]:
        parent[root_x] = root_y
    elif rank[root_x] > rank[root_y]:
        parent[root_y] = root_x
    else:
        parent[root_y] = root_x
        rank[root_x] += 1
    
    return true
```

## 📊 Performance Metrics

### MST Quality Measures
- **Total Weight**: Sum of all MST edge weights
- **Average Edge Weight**: Mean weight of edges in MST
- **Weight Efficiency**: Ratio of MST weight to total graph weight
- **Diameter**: Longest path in MST between any two vertices

### Algorithm Performance
- **Execution Time**: Actual runtime for different graph sizes
- **Memory Usage**: Space complexity analysis
- **Cache Performance**: Memory access patterns and locality
- **Scalability**: Performance degradation with increasing problem size

### Graph Properties
- **Connectivity**: Number of components before/after MST
- **Density Impact**: Algorithm performance vs. edge density
- **Weight Distribution**: Effect of edge weight characteristics
- **Structural Analysis**: MST properties like depth and branching factor

---

**Status**: ✅ Complete - Production Ready  
**Complexity**: Advanced Graph Theory  
**Prerequisites**: Graph Theory, Data Structures, Algorithm Analysis  
**Estimated Learning Time**: 5-7 hours for basic concepts, 15+ hours for mastery 