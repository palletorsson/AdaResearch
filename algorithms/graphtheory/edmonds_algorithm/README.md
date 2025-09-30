# Edmonds' Algorithm: Maximum Matching

## Overview
Edmonds' algorithm is a sophisticated algorithm for finding the maximum matching in a general (not necessarily bipartite) graph. It uses the concept of blossoms to handle odd cycles and find augmenting paths efficiently.

## Algorithm Details

### Core Concept
- **Matching**: A set of edges with no shared vertices
- **Augmenting Path**: A path that alternates between matched and unmatched edges
- **Blossom**: An odd cycle that can be contracted to simplify the graph
- **Forest Structure**: A tree-like structure to track potential augmenting paths

### Algorithm Steps
1. **Initialize**: Start with empty matching
2. **Find Unmatched Vertex**: Look for vertices not in current matching
3. **Build Forest**: Create alternating tree from unmatched vertex
4. **Find Augmenting Path**: Look for path to another unmatched vertex
5. **Handle Blossoms**: Contract odd cycles when found
6. **Augment Matching**: Flip edges along augmenting path
7. **Repeat**: Continue until no more augmenting paths exist

### Time Complexity
- **Time**: O(V²E) where V is vertices and E is edges
- **Space**: O(V + E) for the graph and auxiliary data structures

## Visual Features

### Interactive Elements
- **3D Graph Visualization**: Vertices arranged in circular pattern
- **Matching Highlighting**: Matched edges shown in red
- **Forest Visualization**: Tree structure shown in cyan
- **Blossom Indicators**: Circular markers around contracted cycles
- **Augmenting Path Animation**: Step-by-step path discovery

### Algorithm State Display
- **Matching Size**: Real-time count of matched edges
- **Current Operation**: Shows current algorithm step
- **Forest Structure**: Visual representation of alternating tree
- **Blossom Detection**: Highlights when odd cycles are found

## Controls
- **Space**: Start/stop algorithm execution
- **Escape**: Reset algorithm to initial state

## Educational Value

### Learning Objectives
- Understand maximum matching in general graphs
- Learn about augmenting paths and their properties
- Visualize the blossom contraction process
- Explore the forest-based path finding approach

### Key Insights
- **Augmenting Path Property**: Flipping edges along augmenting path increases matching size
- **Blossom Contraction**: Odd cycles can be contracted without losing optimality
- **Forest Structure**: Alternating trees help find augmenting paths
- **Termination**: Algorithm terminates when no augmenting paths exist

### Real-world Applications
- **Assignment Problems**: Matching workers to tasks
- **Resource Allocation**: Optimal pairing of resources
- **Network Design**: Maximum capacity matching
- **Scheduling**: Optimal task assignment

## Technical Implementation

### Key Data Structures
```gdscript
var matching: Dictionary = {}  # vertex -> matched_vertex
var forest: Dictionary = {}    # vertex -> parent in forest
var labels: Dictionary = {}    # vertex -> label (even/odd/unlabeled)
var blossoms: Array = []       # List of blossom cycles
```

### Algorithm Core
```gdscript
# Main algorithm loop
while true:
    unmatched_vertex = find_unmatched_vertex()
    if unmatched_vertex == null:
        break
    
    initialize_forest(unmatched_vertex)
    augmenting_path = find_augmenting_path()
    if augmenting_path.size() > 0:
        augment_matching(augmenting_path)
    else:
        break
```

## Visual Design

### Vertex Representation
- **Blue**: Unmatched vertices
- **Green**: Matched vertices
- **Red**: Vertices in current augmenting path

### Edge Visualization
- **Gray**: Regular edges
- **Red**: Edges in current matching
- **Yellow**: Edges in augmenting path
- **Cyan**: Edges in forest structure

### Blossom Visualization
- **Purple Circles**: Mark contracted odd cycles
- **Transparent**: Show underlying structure
- **Dynamic**: Appear and disappear as needed

## Configuration Options

### Graph Parameters
- **Graph Size**: Number of vertices (default: 10)
- **Edge Density**: Probability of edge creation (default: 0.3)
- **Auto Start**: Begin algorithm automatically on load

### Visualization Settings
- **Step by Step**: Pause between algorithm steps
- **Animation Delay**: Time between steps in seconds
- **Show Augmenting Paths**: Visualize path discovery
- **Show Blossoms**: Display contracted cycles
- **Show Forest Structure**: Show alternating tree

### Interactive Features
- **Graph Editing**: Modify the graph structure
- **Edge Editing**: Add/remove edges
- **Real-time Updates**: Update matching as graph changes

## Algorithm Variations

### Blossom Algorithm (Implemented)
- **Blossom Contraction**: Handles odd cycles by contracting them
- **Forest Building**: Uses alternating trees to find paths
- **Path Augmentation**: Flips edges to increase matching

### Bipartite Matching
- **Simpler Case**: When graph is bipartite
- **Faster Algorithm**: O(VE) time complexity
- **No Blossoms**: Odd cycles don't exist

## Performance Characteristics

### Time Complexity Analysis
- **Forest Building**: O(V) per iteration
- **Path Finding**: O(E) per iteration
- **Blossom Contraction**: O(V) per contraction
- **Total**: O(V²E) - quadratic in vertices, linear in edges

### Space Complexity
- **Matching Array**: O(V) for vertex assignments
- **Forest Structure**: O(V) for parent pointers
- **Blossom Storage**: O(V) for contracted cycles
- **Total**: O(V + E) - linear in graph size

## Comparison with Other Algorithms

### vs. Bipartite Matching
- **Advantage**: Works on general graphs
- **Disadvantage**: More complex implementation
- **Use Case**: When graph structure is unknown

### vs. Greedy Matching
- **Advantage**: Guarantees maximum matching
- **Disadvantage**: Higher time complexity
- **Use Case**: When optimality is required

## Common Pitfalls

### Blossom Detection
- **Problem**: Incorrectly identifying odd cycles
- **Solution**: Careful cycle detection in forest
- **Visualization**: Highlight cycle detection process

### Path Reconstruction
- **Problem**: Incorrectly building augmenting paths
- **Solution**: Proper parent tracking in forest
- **Debugging**: Show path construction step-by-step

## Advanced Applications

### Weighted Matching
- **Extension**: Find maximum weight matching
- **Algorithm**: Hungarian algorithm for bipartite graphs
- **Complexity**: O(V³) for weighted case

### Perfect Matching
- **Requirement**: Every vertex must be matched
- **Condition**: Graph must have perfect matching
- **Detection**: Check if maximum matching size equals V/2

## Related Algorithms
- **Hungarian Algorithm**: For weighted bipartite matching
- **Hopcroft-Karp**: For bipartite matching
- **Maximum Flow**: Can be reduced to matching problems
- **Stable Marriage**: For preference-based matching

## Performance Optimization

### Blossom Handling
- **Efficient Contraction**: Minimize graph modifications
- **Path Compression**: Optimize forest traversal
- **Memory Management**: Reuse contracted structures

### Path Finding
- **BFS Optimization**: Use breadth-first search
- **Early Termination**: Stop when augmenting path found
- **Cycle Detection**: Efficient odd cycle identification

---

*"Edmonds' algorithm finds perfect pairings through the elegant dance of blossoms and augmenting paths."*

*Discovering maximum matching through the art of contraction and augmentation*
