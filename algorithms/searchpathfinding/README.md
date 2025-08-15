# Search & Pathfinding Algorithms

This directory contains 3D visualizations of search algorithms and pathfinding techniques used in artificial intelligence, robotics, game development, and navigation systems. These algorithms demonstrate different approaches to finding optimal paths through complex environments.

## Algorithms

### 1. A* Pathfinding (`astar/`)
- **Description**: An informed search algorithm for finding the shortest path between nodes in a graph
- **Inventors**: Peter Hart, Nils Nilsson, Bertram Raphael (1968)
- **Algorithm Type**: Informed search with heuristic guidance
- **Features**:
  - Multiple heuristic functions (Manhattan, Euclidean, Chebyshev, Octile)
  - Real-time path visualization with step-by-step execution
  - Interactive grid generation with configurable obstacle density
  - Diagonal movement support
  - Visual representation of open set, closed set, and explored nodes
- **Use Cases**: Game AI, robotics navigation, GPS routing, network optimization

## Technical Details

### A* Algorithm

#### Core Components
- **Open Set**: Nodes to be evaluated (priority queue based on f_score)
- **Closed Set**: Already evaluated nodes
- **Came From**: Tracks the optimal path to each node
- **G Score**: Cost from start to current node
- **F Score**: G score + heuristic estimate to goal

#### Algorithm Steps
1. **Initialize**: Add start node to open set with g_score = 0
2. **Loop**: While open set is not empty:
   - Select node with lowest f_score
   - If goal reached, reconstruct path
   - Move current node to closed set
   - Evaluate all neighbors
   - Update scores and add to open set if better path found

#### Heuristic Functions
- **Manhattan**: |dx| + |dy| (L1 norm)
- **Euclidean**: √(dx² + dy²) (L2 norm)
- **Chebyshev**: max(|dx|, |dy|) (L∞ norm)
- **Octile**: max(|dx|, |dy|) + (√2 - 1) × min(|dx|, |dy|)

### Visualization Features
- **3D Grid Representation**: Cubes represent grid cells with height-based information
- **Color Coding**:
  - **Green**: Start position
  - **Red**: Goal position
  - **Blue**: Walkable cells
  - **Dark Red**: Obstacles
  - **Cyan**: Open set nodes
  - **Light Yellow**: Explored nodes
  - **Yellow**: Final path
- **Real-time Updates**: Dynamic visualization during algorithm execution
- **Step-by-step Mode**: Controlled execution for educational purposes

## Usage

Each algorithm scene can be:
1. **Opened independently** in Godot 4
2. **Integrated into game projects** for AI pathfinding
3. **Used for educational purposes** to understand search algorithms
4. **Extended** with additional algorithms or visualization methods

## Controls

### Grid Configuration
- **Grid Size**: Adjust grid dimensions (5x5 to 20x20)
- **Obstacle Density**: Control percentage of blocked cells (0% - 80%)
- **Diagonal Movement**: Enable/disable diagonal pathfinding

### Algorithm Parameters
- **Heuristic Type**: Choose distance calculation method
- **Generate Grid**: Create new random grid layout
- **Find Path**: Execute A* algorithm
- **Clear Path**: Remove current path visualization
- **Step by Step**: Toggle controlled execution mode

## File Structure

```
searchpathfinding/
├── astar/
│   ├── astar.tscn
│   ├── AStar.gd
│   └── AStarVisualizer.gd
└── README.md
```

## Dependencies

- **Godot 4.4+**: Required for all scenes
- **Standard 3D nodes**: CSGBox3D, Camera3D, DirectionalLight3D
- **Math functions**: Built-in mathematical functions for distance calculations
- **Array operations**: Dynamic array manipulation for grid management

## Mathematical Concepts

### Graph Theory
- **Nodes**: Grid positions (x, y coordinates)
- **Edges**: Connections between adjacent nodes
- **Weight**: Cost of moving between nodes (uniform in basic implementation)

### Search Algorithms
- **Uninformed Search**: Breadth-first, depth-first, uniform-cost
- **Informed Search**: A*, greedy best-first, IDA*
- **Optimality**: A* guarantees shortest path with admissible heuristic

### Heuristic Properties
- **Admissible**: Never overestimates true cost to goal
- **Consistent**: Satisfies triangle inequality
- **Dominance**: One heuristic dominates another if always better

## Performance Characteristics

### Time Complexity
- **Worst Case**: O(b^d) where b is branching factor, d is path depth
- **Best Case**: O(d) when heuristic is perfect
- **Average Case**: O(b^(ε×d)) where ε is heuristic error

### Space Complexity
- **Open Set**: O(b^d) nodes stored
- **Closed Set**: O(b^d) nodes stored
- **Total**: O(b^d) memory usage

### Optimization Factors
- **Heuristic Quality**: Better heuristics reduce explored nodes
- **Grid Structure**: Sparse obstacles improve performance
- **Movement Constraints**: Diagonal movement increases branching factor

## Future Enhancements

- [ ] Add more search algorithms (Dijkstra, BFS, DFS)
- [ ] Implement weighted grids with variable movement costs
- [ ] Add dynamic obstacle avoidance
- [ ] Create multi-agent pathfinding scenarios
- [ ] Implement hierarchical pathfinding for large grids
- [ ] Add path smoothing and optimization tools

## Applications

### Game Development
- **AI Navigation**: NPC movement and pathfinding
- **Level Design**: Automated path validation
- **Procedural Generation**: Dynamic obstacle placement
- **Real-time Strategy**: Unit movement and formation

### Robotics & Autonomous Systems
- **Mobile Robots**: Navigation in dynamic environments
- **Drone Pathfinding**: 3D space navigation
- **Autonomous Vehicles**: Road network routing
- **Warehouse Automation**: AGV path planning

### Geographic Information Systems
- **GPS Navigation**: Route optimization
- **Urban Planning**: Transportation network analysis
- **Emergency Response**: Fastest route calculation
- **Logistics**: Delivery route optimization

### Network Optimization
- **Internet Routing**: Packet path optimization
- **Telecommunications**: Network topology design
- **Supply Chain**: Distribution network optimization
- **Social Networks**: Connection path analysis

## References

- Hart, P. E., Nilsson, N. J., & Raphael, B. "A formal basis for the heuristic determination of minimum cost paths." IEEE transactions on Systems Science and Cybernetics 4.2 (1968): 100-107.
- Russell, S., & Norvig, P. "Artificial Intelligence: A Modern Approach." Prentice Hall (2009).
- LaValle, S. M. "Planning Algorithms." Cambridge University Press (2006).
- Various pathfinding and search algorithm references

