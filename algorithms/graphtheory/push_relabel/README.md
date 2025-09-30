# Push-Relabel Algorithm: Maximum Flow

## Overview
The Push-Relabel algorithm is a preflow-based approach to finding maximum flow in a network. Unlike augmenting path algorithms, it maintains a preflow (allowing excess flow at vertices) and uses push and relabel operations to gradually convert it into a valid flow.

## Algorithm Details

### Core Concept
- **Preflow**: A function that satisfies capacity constraints but allows excess flow at vertices
- **Height Labels**: Each vertex has a height that determines push eligibility
- **Excess Flow**: The amount of flow exceeding what can be pushed out
- **Push Operation**: Move flow from a vertex to a neighbor with lower height
- **Relabel Operation**: Increase height of a vertex to enable pushes

### Algorithm Steps
1. **Initialize Preflow**: Saturate all edges from source, set source height to |V|
2. **Push-Relabel Loop**: While active vertices exist:
   - Select an active vertex (with excess flow)
   - Try to push flow to neighbors with lower height
   - If no push possible, relabel the vertex
   - Remove vertices with no excess from active list
3. **Termination**: When no active vertices remain, excess at sink is maximum flow

### Time Complexity
- **Time**: O(V²E) in general, O(V³) for dense graphs
- **Space**: O(V + E) for the graph and auxiliary data structures

## Visual Features

### Interactive Elements
- **3D Network Visualization**: Nodes arranged in circular pattern
- **Real-time Flow Display**: Edges change color based on flow values
- **Height Labels**: Show current height of each vertex
- **Excess Flow Display**: Real-time excess flow values
- **Push Operation Highlighting**: Visual emphasis during flow pushes

### Algorithm State Display
- **Active Nodes**: Vertices with excess flow highlighted in yellow
- **Current Operation**: Shows whether pushing or relabeling
- **Flow Values**: Real-time display of flow through each edge
- **Height Updates**: Live updates as vertices are relabeled

## Controls
- **Space**: Start/stop algorithm execution
- **Escape**: Reset algorithm to initial state

## Educational Value

### Learning Objectives
- Understand preflow-based maximum flow algorithms
- Learn about height labels and their role in correctness
- Visualize push and relabel operations
- Compare with augmenting path approaches

### Key Insights
- **Height Invariant**: Maintains height[u] ≤ height[v] + 1 for all edges
- **Push Eligibility**: Can only push to neighbors with lower height
- **Relabel Necessity**: Increases height when no pushes are possible
- **Termination Guarantee**: Algorithm always terminates with maximum flow

### Real-world Applications
- **Network Routing**: Finding maximum bandwidth paths
- **Transportation**: Optimizing cargo flow through networks
- **Communication**: Bandwidth allocation in networks
- **Resource Allocation**: Maximizing flow of resources

## Technical Implementation

### Key Data Structures
```gdscript
var height: Dictionary = {}      # Height labels for each vertex
var excess: Dictionary = {}      # Excess flow at each vertex
var active_nodes: Array = []     # Vertices with excess flow
var flow_matrix: Array = []      # Flow values for each edge
var capacity_matrix: Array = []  # Capacity constraints
```

### Algorithm Core
```gdscript
# Initialize preflow
height[source] = |V|
for each edge (source, v):
    flow[source][v] = capacity[source][v]
    excess[v] = capacity[source][v]
    excess[source] -= capacity[source][v]

# Main loop
while active_nodes not empty:
    u = active_nodes[0]
    if can_push(u):
        push_flow(u)
    else:
        relabel(u)
    if excess[u] == 0:
        remove u from active_nodes
```

## Visual Design

### Node Representation
- **Source (Green)**: Starting point of flow
- **Sink (Red)**: Destination of flow
- **Active (Yellow)**: Vertices with excess flow
- **Normal (Blue)**: Regular vertices

### Edge Visualization
- **Gray**: No flow
- **Red**: Carrying flow
- **Orange**: Currently being used for push operation

### Information Display
- **Height Labels**: Show current height of each vertex
- **Excess Labels**: Display excess flow amounts
- **Capacity Labels**: Show edge capacity constraints
- **Flow Values**: Real-time flow through edges

## Configuration Options

### Graph Parameters
- **Graph Size**: Number of nodes (default: 6)
- **Edge Density**: Probability of edge creation (default: 0.5)
- **Auto Start**: Begin algorithm automatically on load

### Visualization Settings
- **Step by Step**: Pause between algorithm steps
- **Animation Delay**: Time between steps in seconds
- **Show Excess Flow**: Display excess flow values
- **Show Height Labels**: Display vertex heights
- **Show Flow Values**: Display flow through edges

### Interactive Features
- **Graph Editing**: Modify the network structure
- **Capacity Editing**: Change edge capacities
- **Real-time Updates**: Update flow as network changes

## Algorithm Variations

### Generic Push-Relabel
- **FIFO Selection**: Process active nodes in first-in-first-out order
- **Highest Label**: Always select vertex with highest label
- **Excess Scaling**: Use scaling technique for better performance

### Optimizations
- **Gap Relabeling**: Remove vertices with height > gap
- **Global Relabeling**: Periodically recompute all heights
- **Discharge**: Process vertex until no excess remains

## Performance Characteristics

### Time Complexity Analysis
- **Push Operations**: O(V²E) total pushes
- **Relabel Operations**: O(V²) total relabels
- **Height Updates**: O(V) per relabel
- **Total**: O(V²E) - quadratic in vertices, linear in edges

### Space Complexity
- **Height Array**: O(V) for vertex heights
- **Excess Array**: O(V) for excess flow
- **Flow Matrix**: O(V²) for flow values
- **Total**: O(V²) - quadratic in vertices

## Comparison with Other Algorithms

### vs. Ford-Fulkerson
- **Advantage**: Better worst-case performance
- **Disadvantage**: More complex implementation
- **Use Case**: Dense graphs, worst-case scenarios

### vs. Edmonds-Karp
- **Advantage**: O(V²E) vs O(VE²) complexity
- **Disadvantage**: Higher constant factors
- **Use Case**: When worst-case performance matters

## Common Pitfalls

### Height Invariant Violation
- **Problem**: Heights can become inconsistent
- **Solution**: Ensure height[u] ≤ height[v] + 1
- **Visualization**: Highlight height violations

### Infinite Loops
- **Problem**: Algorithm may not terminate
- **Solution**: Proper height management
- **Detection**: Monitor for repeated states

## Advanced Applications

### Bipartite Matching
- **Reduction**: Convert to maximum flow problem
- **Source/Sink**: Add source to left, sink to right
- **Capacity**: All edges have capacity 1

### Minimum Cut
- **Max-Flow Min-Cut**: Cut capacity equals max flow
- **Cut Identification**: Vertices reachable from source
- **Applications**: Network reliability, image segmentation

## Related Algorithms
- **Ford-Fulkerson**: Augmenting path approach
- **Edmonds-Karp**: BFS-based Ford-Fulkerson
- **Dinic's Algorithm**: Blocking flow method
- **Min-Cost Max-Flow**: Flow with cost optimization

---

*"Push-Relabel transforms the flow problem into an elegant dance of heights and excess."*

*Discovering maximum flow through the art of pushing and relabeling*
