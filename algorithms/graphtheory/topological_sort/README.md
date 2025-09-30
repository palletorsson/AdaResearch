# Topological Sort: Dependency Ordering in DAGs

## Overview
Topological sort is an algorithm for ordering the vertices of a directed acyclic graph (DAG) such that for every directed edge (u, v), vertex u comes before vertex v in the ordering. This is essential for dependency resolution and task scheduling.

## Algorithm Details

### Core Concept
- **Directed Acyclic Graph (DAG)**: A directed graph with no cycles
- **Topological Ordering**: A linear ordering of vertices respecting dependencies
- **In-degree**: Number of incoming edges to a vertex
- **Queue-based Processing**: Process vertices with no dependencies first

### Algorithm Steps
1. **Calculate In-degrees**: Count incoming edges for each vertex
2. **Initialize Queue**: Add all vertices with in-degree 0 to queue
3. **Process Queue**: While queue is not empty:
   - Remove vertex from queue
   - Add to sorted order
   - Decrease in-degree of all neighbors
   - Add neighbors with in-degree 0 to queue
4. **Result**: Sorted order represents valid topological ordering

### Time Complexity
- **Time**: O(V + E) where V is vertices and E is edges
- **Space**: O(V) for the queue and in-degree tracking

## Visual Features

### Interactive Elements
- **Hierarchical Layout**: Vertices arranged by dependency level
- **Level Indicators**: Colored planes showing dependency levels
- **Real-time Queue**: Visual representation of processing queue
- **In-degree Display**: Shows current in-degree for each vertex
- **Dependency Highlighting**: Edges highlighted as dependencies are resolved

### Algorithm State Display
- **Current Vertex**: Highlighted during processing
- **Queue State**: Real-time display of vertices ready to process
- **Sorted Order**: Growing list of processed vertices
- **In-degree Updates**: Live updates as dependencies are resolved

## Controls
- **Space**: Start/stop algorithm execution
- **Escape**: Reset algorithm to initial state

## Educational Value

### Learning Objectives
- Understand dependency resolution in complex systems
- Learn about directed acyclic graphs and their properties
- Visualize the queue-based processing approach
- See how in-degrees change during algorithm execution

### Key Insights
- **DAG Property**: Only acyclic graphs have valid topological orderings
- **Dependency Chain**: Processing one vertex can make others ready
- **Level Structure**: Vertices naturally group by dependency depth
- **Queue Efficiency**: Ensures optimal processing order

### Real-world Applications
- **Task Scheduling**: Ordering tasks with dependencies
- **Build Systems**: Compiling source code in correct order
- **Course Prerequisites**: Determining course sequence
- **Package Management**: Resolving software dependencies
- **Project Management**: Critical path analysis

## Technical Implementation

### Key Data Structures
```gdscript
var in_degrees: Dictionary = {}  # In-degree count for each vertex
var queue: Array = []            # Vertices ready to process
var sorted_order: Array = []     # Final topological ordering
var adjacency_list: Dictionary = {}  # Graph structure
```

### Algorithm Core
```gdscript
# Initialize queue with vertices having no dependencies
for vertex in vertices:
    if in_degrees[vertex] == 0:
        queue.append(vertex)

# Process queue until empty
while not queue.is_empty():
    current = queue.pop_front()
    sorted_order.append(current)
    
    # Update neighbors
    for neighbor in adjacency_list[current]:
        in_degrees[neighbor] -= 1
        if in_degrees[neighbor] == 0:
            queue.append(neighbor)
```

## Visual Design

### Hierarchical Layout
- **Level-based Positioning**: Vertices arranged by dependency depth
- **Color-coded Levels**: Each level gets a distinct color
- **Level Indicators**: Semi-transparent planes showing level boundaries
- **In-degree Labels**: Real-time display of dependency counts

### Color Scheme
- **Ready (Green)**: Vertices with no dependencies (in-degree 0)
- **Processing (Yellow)**: Currently being processed
- **Processed (Red)**: Already added to sorted order
- **Level Colors**: Different colors for each dependency level

## Configuration Options

### Graph Parameters
- **Graph Size**: Number of vertices (default: 8)
- **Edge Density**: Probability of edge creation (default: 0.3)
- **Auto Start**: Begin algorithm automatically on load

### Visualization Settings
- **Step by Step**: Pause between algorithm steps
- **Animation Delay**: Time between steps in seconds
- **Show In-degrees**: Display dependency counts
- **Show Queue State**: Visualize processing queue
- **Show Levels**: Display dependency level indicators

### Interactive Features
- **Graph Editing**: Modify the graph structure
- **Edge Editing**: Add/remove dependencies
- **Real-time Updates**: Update sorting as graph changes

## Algorithm Variations

### Kahn's Algorithm (Implemented)
- **Queue-based**: Uses a queue to process vertices
- **In-degree Tracking**: Maintains in-degree counts
- **Level Processing**: Natural level-by-level processing

### DFS-based Approach
- **Post-order DFS**: Process vertices after visiting all descendants
- **Stack-based**: Uses recursion stack for ordering
- **Reverse Order**: Produces ordering in reverse

## Performance Characteristics

### Time Complexity Analysis
- **In-degree Calculation**: O(E) - visit each edge once
- **Queue Processing**: O(V) - each vertex processed once
- **Neighbor Updates**: O(E) - each edge processed once
- **Total**: O(V + E) - linear in graph size

### Space Complexity
- **In-degree Array**: O(V) for dependency counts
- **Queue**: O(V) for processing queue
- **Adjacency List**: O(V + E) for graph structure
- **Total**: O(V + E) - linear in graph size

## Common Pitfalls

### Cycle Detection
- **Problem**: Algorithm fails if graph contains cycles
- **Solution**: Check if sorted order contains all vertices
- **Visualization**: Highlight remaining unprocessed vertices

### Multiple Valid Orderings
- **Problem**: DAGs can have multiple valid topological orderings
- **Solution**: Algorithm produces one valid ordering
- **Educational**: Show that multiple orderings are possible

## Related Algorithms
- **DFS**: Foundation for alternative topological sort
- **Strongly Connected Components**: For cycle detection
- **Critical Path Method**: For project scheduling
- **Dependency Resolution**: For package management

## Advanced Applications

### Build Systems
- **Make**: Traditional build tool using topological sort
- **CMake**: Modern build system with dependency resolution
- **Package Managers**: npm, pip, cargo dependency resolution

### Project Management
- **Critical Path**: Finding longest dependency chain
- **Resource Allocation**: Scheduling with constraints
- **Risk Analysis**: Identifying critical dependencies

---

*"Topological sort reveals the hidden order in complex dependency networks."*

*Discovering the elegant sequence that makes complex systems work*
