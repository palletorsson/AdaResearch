# Karger's Algorithm: Minimum Cut

## Overview
Karger's algorithm is a randomized algorithm for finding the minimum cut in an undirected graph. It uses edge contraction to gradually reduce the graph until only two vertices remain, with the edges between them representing a cut.

## Algorithm Details

### Core Concept
- **Edge Contraction**: Merge two vertices into one, removing the edge between them
- **Random Selection**: Randomly choose edges to contract
- **Cut Preservation**: The minimum cut is preserved with high probability
- **Multiple Iterations**: Run the algorithm multiple times to increase success probability

### Algorithm Steps
1. **Initialize**: Start with the original graph
2. **Contraction Loop**: While more than 2 vertices remain:
   - Select a random edge uniformly
   - Contract the edge (merge its endpoints)
   - Remove self-loops
3. **Cut Calculation**: The remaining edges form a cut
4. **Multiple Runs**: Repeat to find the minimum cut

### Time Complexity
- **Time**: O(V²) per iteration, O(V² log V) for high success probability
- **Space**: O(V + E) for the graph representation

## Visual Features

### Interactive Elements
- **3D Graph Visualization**: Vertices arranged in circular pattern
- **Edge Contraction Animation**: Visual merging of vertices
- **Cut Highlighting**: Edges forming the cut are highlighted
- **Iteration Tracking**: Shows progress through multiple runs
- **Probability Display**: Shows success probability

### Algorithm State Display
- **Current Iteration**: Shows which run is being executed
- **Contraction Steps**: Visual representation of edge contractions
- **Cut Size**: Real-time display of current cut size
- **Best Cut**: Highlighting of the best cut found so far

## Controls
- **Space**: Start/stop algorithm execution
- **Escape**: Reset algorithm to initial state

## Educational Value

### Learning Objectives
- Understand randomized algorithms and their applications
- Learn about edge contraction and graph reduction
- Visualize the concept of minimum cuts
- Explore probability in algorithm design

### Key Insights
- **Contraction Property**: Contracting edges preserves minimum cuts
- **Success Probability**: Probability of finding minimum cut is 2/(V(V-1))
- **Multiple Runs**: Running multiple times increases success probability
- **Cut Identification**: Final edges represent the cut

### Real-world Applications
- **Network Reliability**: Finding weak points in networks
- **Image Segmentation**: Separating objects in images
- **Community Detection**: Finding communities in social networks
- **Circuit Design**: Identifying critical connections

## Technical Implementation

### Key Data Structures
```gdscript
var contracted_vertices: Dictionary = {}  # Vertex components
var original_edges: Array = []           # Original graph edges
var current_cut: Array = []              # Current cut edges
var best_cut: Array = []                 # Best cut found so far
```

### Algorithm Core
```gdscript
# Main contraction loop
while remaining_vertices.size() > 2:
    # Select random edge
    random_edge = select_random_edge(available_edges)
    
    # Contract edge
    contract_edge(random_edge)
    
    # Remove self-loops
    remove_self_loops()

# Calculate cut size
cut_size = count_cut_edges(remaining_vertices)
```

## Visual Design

### Vertex Representation
- **Normal (Blue)**: Regular vertices
- **Contracted (Red)**: Vertices that have been merged
- **Component Size**: Labels show number of original vertices merged

### Edge Visualization
- **Gray**: Regular edges
- **Yellow**: Edges being contracted
- **Purple**: Edges in the best cut found

### Information Display
- **Iteration Counter**: Shows current run number
- **Cut Size**: Displays size of current cut
- **Success Probability**: Shows theoretical success rate
- **Best Cut**: Highlights the minimum cut found

## Configuration Options

### Graph Parameters
- **Graph Size**: Number of vertices (default: 8)
- **Edge Density**: Probability of edge creation (default: 0.4)
- **Number of Iterations**: How many times to run the algorithm (default: 10)

### Visualization Settings
- **Step by Step**: Pause between contraction steps
- **Animation Delay**: Time between steps in seconds
- **Show Contraction Steps**: Visualize edge contractions
- **Show Best Cut**: Highlight the minimum cut found

### Interactive Features
- **Graph Editing**: Modify the graph structure
- **Edge Editing**: Add/remove edges
- **Real-time Updates**: Update cuts as graph changes

## Algorithm Analysis

### Success Probability
- **Single Run**: 2/(V(V-1)) probability of finding minimum cut
- **Multiple Runs**: 1 - (1 - 2/(V(V-1)))^k for k runs
- **High Probability**: O(V² log V) runs for high success rate

### Time Complexity
- **Per Iteration**: O(V²) for edge selection and contraction
- **Total**: O(V² log V) for high success probability
- **Space**: O(V + E) for graph representation

## Comparison with Other Algorithms

### vs. Deterministic Algorithms
- **Advantage**: Simpler implementation
- **Disadvantage**: Probabilistic correctness
- **Use Case**: When approximate solutions are acceptable

### vs. Max-Flow Min-Cut
- **Advantage**: Works on undirected graphs
- **Disadvantage**: Less efficient for single cut
- **Use Case**: When multiple cuts are needed

## Common Pitfalls

### Low Success Probability
- **Problem**: Single run rarely finds minimum cut
- **Solution**: Run multiple iterations
- **Visualization**: Show success probability

### Self-Loop Handling
- **Problem**: Contraction can create self-loops
- **Solution**: Remove self-loops after contraction
- **Implementation**: Check for edges between same component

## Advanced Applications

### Karger-Stein Algorithm
- **Optimization**: Recursive contraction for better performance
- **Time Complexity**: O(V² log V) with higher success probability
- **Implementation**: More complex but more efficient

### Parallel Implementation
- **Multiple Threads**: Run iterations in parallel
- **Speedup**: Linear speedup with number of cores
- **Synchronization**: Careful handling of shared data

## Related Algorithms
- **Stoer-Wagner**: Deterministic minimum cut algorithm
- **Max-Flow Min-Cut**: Flow-based approach
- **Gomory-Hu**: All-pairs minimum cuts
- **Randomized Algorithms**: Monte Carlo methods

## Performance Characteristics

### Success Rate Analysis
- **V=4**: 33% success rate per run
- **V=8**: 3.6% success rate per run
- **V=16**: 0.8% success rate per run
- **Multiple Runs**: 10 runs give ~90% success for V=8

### Memory Usage
- **Vertex Components**: O(V) for tracking contractions
- **Edge Storage**: O(E) for original edges
- **Cut Storage**: O(E) for cut edges
- **Total**: O(V + E) - linear in graph size

---

*"Karger's algorithm finds the minimum cut through the elegant dance of random contraction."*

*Discovering the hidden structure of networks through probabilistic reduction*
