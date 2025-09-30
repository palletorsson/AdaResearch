# Kosaraju's Algorithm: Strongly Connected Components

## Overview
Kosaraju's algorithm is a two-pass depth-first search algorithm for finding strongly connected components (SCCs) in a directed graph. It uses the key insight that the transpose of a graph has the same strongly connected components as the original graph.

## Algorithm Details

### Core Concept
- **Strongly Connected Component (SCC)**: A maximal set of vertices where every vertex is reachable from every other vertex
- **Graph Transpose**: A graph with all edges reversed (G^T)
- **Two-Pass Approach**: First pass finds finish times, second pass processes transpose graph

### Algorithm Steps
1. **First DFS Pass**: Perform DFS on original graph, record finish times
2. **Create Transpose**: Reverse all edges to create G^T
3. **Second DFS Pass**: Process vertices in reverse finish time order on G^T
4. **SCC Formation**: Each DFS tree in second pass forms one SCC

### Time Complexity
- **Time**: O(V + E) where V is vertices and E is edges
- **Space**: O(V) for the transpose graph and finish time array

## Visual Features

### Interactive Elements
- **3D Graph Visualization**: Vertices arranged in circular pattern with height variation
- **Two-Phase Animation**: Clear separation between first and second DFS passes
- **Transpose Visualization**: Shows reversed edges during second phase
- **Color-coded SCCs**: Each strongly connected component gets a unique color
- **Finish Time Display**: Shows the order vertices finish in first pass

### Algorithm State Display
- **Current Phase**: Indicates whether in first or second DFS pass
- **Current Vertex**: Highlighted during processing
- **Finish Times**: Visual representation of first pass completion order
- **SCC Formation**: Real-time visualization of component discovery

## Controls
- **Space**: Start/stop algorithm execution
- **Escape**: Reset algorithm to initial state

## Educational Value

### Learning Objectives
- Understand the two-pass approach to SCC detection
- Learn about graph transpose and its properties
- Visualize the relationship between finish times and SCC formation
- Compare with single-pass algorithms like Tarjan's

### Key Insights
- **Finish Time Property**: Vertices that finish later in first pass are more likely to be SCC roots
- **Transpose Property**: G and G^T have identical strongly connected components
- **DFS Tree Property**: Each DFS tree in second pass forms exactly one SCC

### Real-world Applications
- **Compiler Design**: Finding cycles in dependency graphs
- **Social Networks**: Identifying tightly connected communities
- **Web Analysis**: Finding strongly connected web pages
- **Circuit Analysis**: Detecting feedback loops

## Technical Implementation

### Key Data Structures
```gdscript
var adjacency_list: Dictionary = {}           # Original graph
var transpose_adjacency_list: Dictionary = {} # Transpose graph
var finish_times: Array = []                  # Order of first pass completion
var visited: Dictionary = {}                  # Visited state for each pass
```

### Algorithm Core
```gdscript
# First pass: Get finish times
func dfs_first_pass(vertex: String):
    visited[vertex] = true
    for neighbor in adjacency_list[vertex]:
        if not visited[neighbor]:
            dfs_first_pass(neighbor)
    finish_times.push_front(vertex)  # Add in reverse order

# Second pass: Process transpose
func dfs_second_pass(vertex: String):
    visited[vertex] = true
    for neighbor in transpose_adjacency_list[vertex]:
        if not visited[neighbor]:
            dfs_second_pass(neighbor)
    # Add to current SCC
```

## Comparison with Tarjan's Algorithm

### Kosaraju's Advantages
- **Conceptual Simplicity**: Easier to understand the two-pass approach
- **Clear Separation**: Distinct phases make debugging easier
- **Transpose Insight**: Teaches important graph theory concept

### Tarjan's Advantages
- **Single Pass**: More efficient in practice
- **Lower Space**: No need to store transpose graph
- **Real-time**: Can find SCCs as they're discovered

## Configuration Options

### Graph Parameters
- **Graph Size**: Number of vertices (default: 10)
- **Edge Density**: Probability of edge creation (default: 0.4)
- **Auto Start**: Begin algorithm automatically on load

### Visualization Settings
- **Step by Step**: Pause between algorithm steps
- **Animation Delay**: Time between steps in seconds
- **Show Finish Times**: Display first pass completion order
- **Show Transpose**: Visualize reversed edges in second phase
- **SCC Colors**: Use different colors for each component

### Interactive Features
- **Graph Editing**: Modify the graph structure
- **Edge Editing**: Add/remove edges during execution
- **Real-time Updates**: Update SCCs as graph changes

## Phase Visualization

### Phase 1: First DFS Pass
- **Purpose**: Determine finish times for all vertices
- **Visual**: Original graph edges, finish time labels
- **Color**: Current vertex in yellow, finished in gray

### Phase 2: Second DFS Pass
- **Purpose**: Process transpose graph in reverse finish order
- **Visual**: Transpose edges (orange), SCC formation
- **Color**: Each SCC gets unique color as it's discovered

## Related Algorithms
- **Tarjan's Algorithm**: Single-pass SCC algorithm
- **DFS**: Foundation for both passes
- **Topological Sort**: Related to finish time ordering
- **Union-Find**: For undirected graph connectivity

## Performance Characteristics

### Time Complexity Analysis
- **First Pass**: O(V + E) - standard DFS
- **Transpose Creation**: O(E) - reverse all edges
- **Second Pass**: O(V + E) - DFS on transpose
- **Total**: O(V + E) - linear in graph size

### Space Complexity
- **Adjacency Lists**: O(V + E) for both original and transpose
- **Finish Times**: O(V) for vertex ordering
- **Visited Array**: O(V) for DFS state
- **Total**: O(V + E) - linear in graph size

---

*"Kosaraju's algorithm reveals the hidden symmetry in graph structure through the power of transposition."*

*Discovering strongly connected components through the elegant dance of two passes*
