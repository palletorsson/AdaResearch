# Tarjan's Algorithm: Strongly Connected Components

## Overview
Tarjan's algorithm is a linear-time algorithm for finding strongly connected components (SCCs) in a directed graph. A strongly connected component is a maximal set of vertices where every vertex is reachable from every other vertex in the component.

## Algorithm Details

### Core Concept
- **Strongly Connected Component (SCC)**: A subset of vertices where there's a path from any vertex to any other vertex in the subset
- **Discovery Time**: When a vertex is first visited during DFS
- **Low Link**: The smallest discovery time reachable from a vertex through its descendants

### Algorithm Steps
1. **DFS Traversal**: Perform depth-first search on the graph
2. **Stack Management**: Keep track of vertices currently being processed
3. **Low Link Calculation**: Update low link values based on back edges
4. **SCC Detection**: When low_link[v] == discovery_time[v], we found an SCC root
5. **Component Extraction**: Pop vertices from stack until we reach the root

### Time Complexity
- **Time**: O(V + E) where V is vertices and E is edges
- **Space**: O(V) for the stack and auxiliary arrays

## Visual Features

### Interactive Elements
- **3D Graph Visualization**: Vertices arranged in a circular pattern with height variation
- **Color-coded SCCs**: Each strongly connected component gets a unique color
- **Edge Type Highlighting**: Different colors for tree edges, back edges, and cross edges
- **Real-time Animation**: Step-by-step algorithm execution with configurable delays

### Algorithm State Display
- **Current Vertex**: Highlighted in bright yellow during processing
- **Discovery Times**: Shown as labels on vertices
- **Low Link Values**: Displayed during algorithm execution
- **Stack State**: Visual representation of the algorithm's internal stack

## Controls
- **Space**: Start/stop algorithm execution
- **Escape**: Reset algorithm to initial state

## Educational Value

### Learning Objectives
- Understand the concept of strongly connected components
- Learn how DFS can be used for graph decomposition
- Visualize the relationship between discovery time and low link values
- See how back edges create cycles and affect SCC formation

### Real-world Applications
- **Compiler Design**: Finding cycles in dependency graphs
- **Social Networks**: Identifying tightly connected groups
- **Web Analysis**: Finding strongly connected web pages
- **Circuit Analysis**: Detecting feedback loops in electronic circuits

## Technical Implementation

### Key Data Structures
```gdscript
var discovery_time: Dictionary = {}  # When each vertex was discovered
var low_link: Dictionary = {}        # Lowest discovery time reachable
var on_stack: Dictionary = {}        # Whether vertex is in current SCC stack
var stack: Array = []                # Stack for tracking current path
```

### Algorithm Core
```gdscript
func tarjan_dfs(vertex: String):
    discovery_time[vertex] = time_counter
    low_link[vertex] = time_counter
    time_counter += 1
    stack.append(vertex)
    on_stack[vertex] = true
    
    for neighbor in adjacency_list[vertex]:
        if discovery_time[neighbor] == -1:
            tarjan_dfs(neighbor)
            low_link[vertex] = min(low_link[vertex], low_link[neighbor])
        elif on_stack[neighbor]:
            low_link[vertex] = min(low_link[vertex], discovery_time[neighbor])
    
    if low_link[vertex] == discovery_time[vertex]:
        # Found SCC root - extract component
        var scc = []
        var w = ""
        do:
            w = stack.pop_back()
            on_stack[w] = false
            scc.append(w)
        while w != vertex
        sccs.append(scc)
```

## Configuration Options

### Graph Parameters
- **Graph Size**: Number of vertices (default: 12)
- **Edge Density**: Probability of edge creation (default: 0.3)
- **Auto Start**: Begin algorithm automatically on load

### Visualization Settings
- **Step by Step**: Pause between algorithm steps
- **Animation Delay**: Time between steps in seconds
- **Show Discovery Time**: Display discovery time labels
- **Show Low Link**: Display low link values
- **SCC Colors**: Use different colors for each component

### Interactive Features
- **Graph Editing**: Modify the graph structure
- **Edge Editing**: Add/remove edges during execution
- **Real-time Updates**: Update SCCs as graph changes

## Related Algorithms
- **Kosaraju's Algorithm**: Alternative SCC algorithm using two DFS passes
- **Union-Find**: For undirected graph connectivity
- **DFS**: Foundation for many graph algorithms
- **Topological Sort**: Related to DAG structure

---

*"In graph theory, strongly connected components reveal the hidden structure of relationships."*

*Discovering the fundamental building blocks of complex networks*
