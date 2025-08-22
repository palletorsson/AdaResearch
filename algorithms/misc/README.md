# Algorithm Flowchart 2D Visualization

An interactive 2D flowchart visualization built in Godot that displays the learning progression through various algorithm categories.

## Features

- **Interactive Nodes**: Click on any algorithm node to see detailed information
- **Color-Coded Categories**: Different colors for each type of algorithm
  - 🔵 **Foundation**: Arrays, basic tutorials (light blue)
  - 🟠 **Audio**: Wave processing algorithms (orange)
  - 🟢 **Randomness**: Random processes and noise (green)
  - 🔴 **Visual/Meshes**: Mesh generation and visual algorithms (pink)
  - 🟦 **Physics**: Physics simulation and soft bodies (cyan)
  - 🟣 **Advanced**: Machine learning, swarm intelligence (purple)
- **Connection Arrows**: Show learning progression and dependencies
- **Scrollable Canvas**: Navigate through the large flowchart
- **Responsive UI**: Header with instructions and legend

## How to Use

### Running the Flowchart
1. Open `algorithms/misc/flowchart_demo.tscn` in Godot
2. Run the scene to see the interactive flowchart

### Navigation Controls
- **Mouse**: Scroll to pan around the flowchart
- **SPACE**: Center the view
- **R**: Reset scroll position to top-left
- **Click Nodes**: View algorithm information

### Understanding the Layout
- **Entry Points**: Start with lighter colored nodes (tutorials)
- **Progression**: Follow the arrows to see recommended learning paths
- **Branches**: Different tracks for different interests (audio, visual, physics, etc.)
- **Advanced Topics**: Purple nodes represent complex algorithms requiring prerequisites

## Customization

### Adding New Algorithms
Edit the `flowchart_data` dictionary in `algorithm_flowchart_2d.gd`:

```gdscript
"new_algorithm": {
    "pos": Vector2(x, y),           # Grid position
    "text": "Display Name",         # Text shown on button
    "type": "category",            # Color category
    "connections": ["next_algo"]   # Array of connected algorithms
}
```

### Modifying Colors
Update the `CATEGORY_COLORS` dictionary:

```gdscript
const CATEGORY_COLORS = {
    "your_category": Color(r, g, b, a)
}
```

### Adjusting Layout
- `BOX_SIZE`: Change node dimensions
- `BOX_MARGIN`: Adjust spacing between nodes
- Grid positions in `flowchart_data` control layout

## File Structure

- `algorithm_flowchart_2d.gd` - Main script with flowchart logic
- `algorithm_flowchart_2d.tscn` - UI scene with header and legend
- `flowchart_demo.tscn` - Simple demo scene for testing
- `README.md` - This documentation

## Integration

The flowchart can be integrated into larger applications by:
1. Instantiating the `AlgorithmFlowChart2D` scene
2. Connecting to the `node_pressed` signals for custom behavior
3. Modifying the data structure to reflect your specific algorithm catalog

This visualization provides an intuitive way to explore algorithm learning paths and understand the relationships between different computational concepts.