# Markov Chains Tree Generation

A procedural generation algorithm that creates organic tree structures using Markov chains to control growth patterns and branching behavior. This algorithm uses state transitions to simulate natural tree growth with realistic branching, curvature, and termination patterns.

## Overview

The `MarkovChainsTree` class generates 3D tree structures by using Markov chains to control the growth process. Each branch follows a state machine that determines its next growth action, creating natural-looking trees with realistic branching patterns, curvature, and growth termination.

## Features

### Markov Chain State System
- **8 Growth States**: GROW_STRAIGHT, GROW_UP, BRANCH_LEFT, BRANCH_RIGHT, BRANCH_BOTH, CURVE_LEFT, CURVE_RIGHT, TERMINATE
- **Transition Matrix**: Configurable probability matrix for state transitions
- **Context-Aware Rules**: Growth rules that modify probabilities based on tree state
- **Realistic Patterns**: Natural-looking growth patterns and branching

### Tree Growth Control
- **Height Limits**: Configurable maximum tree height
- **Thickness Decay**: Realistic branch thickness reduction
- **Depth Control**: Maximum branch depth to prevent infinite growth
- **Vertical Bias**: Natural upward growth tendency
- **Branch Probability**: Configurable branching likelihood

### Visual Features
- **Tapered Cylinders**: Realistic branch geometry with thickness variation
- **Material System**: Separate bark and leaf materials
- **Leaf Generation**: Optional leaf placement at branch terminals
- **Growth Animation**: Real-time animated tree growth
- **Customizable Colors**: Configurable bark and leaf colors

## Parameters

### Tree Settings
- **Tree Height**: Maximum height of the generated tree (default: 10.0)
- **Max Iterations**: Maximum number of growth iterations (default: 100)
- **Branch Segments**: Number of segments for branch subdivision (default: 8)
- **Initial Thickness**: Starting thickness of the trunk (default: 0.3)
- **Thickness Decay**: Thickness reduction factor for branches (default: 0.75)

### Markov Chain
- **Randomness**: Amount of random variation in growth (default: 0.3)
- **Branch Probability**: Likelihood of creating branches (0.0-1.0, default: 0.4)
- **Terminate Probability**: Likelihood of branch termination (0.0-1.0, default: 0.1)
- **Vertical Bias**: Tendency to grow upward (0.0-1.0, default: 0.6)

### Growth Animation
- **Animate Growth**: Enable real-time growth animation (default: false)
- **Growth Speed**: Speed of animated growth (default: 2.0)

### Visual
- **Bark Color**: Color of tree branches (default: Color(0.4, 0.25, 0.15))
- **Leaf Color**: Color of leaves (default: Color(0.2, 0.6, 0.2))
- **Add Leaves**: Whether to generate leaves at terminals (default: true)

## Algorithm Details

### Markov Chain States
1. **GROW_STRAIGHT**: Continue growing in current direction
2. **GROW_UP**: Grow upward with slight variation
3. **BRANCH_LEFT**: Create left branch
4. **BRANCH_RIGHT**: Create right branch
5. **BRANCH_BOTH**: Create both left and right branches
6. **CURVE_LEFT**: Curve left with slight angle
7. **CURVE_RIGHT**: Curve right with slight angle
8. **TERMINATE**: Stop growing and add leaf

### State Transition Matrix
The algorithm uses a probability matrix that defines the likelihood of transitioning from one state to another. Each state has different transition probabilities based on natural growth patterns.

### Growth Rules
- **Height Limit**: Branches terminate when reaching maximum height
- **Thickness Limit**: Very thin branches terminate
- **Depth Limit**: Prevent infinite branching at high depths
- **Vertical Bias**: Encourage upward growth in lower parts of tree
- **Branch Reduction**: Reduce branching probability at greater depths

### Branch Creation
- **Direction Calculation**: New branch directions based on parent and state
- **Length Calculation**: Segment length based on tree height and segments
- **Thickness Calculation**: Thickness based on parent and decay factor
- **Position Calculation**: New position based on direction and length

## Usage

### Basic Usage
```gdscript
# Create a MarkovChainsTree instance
var tree = MarkovChainsTree.new()
add_child(tree)

# Configure basic parameters
tree.tree_height = 15.0
tree.max_iterations = 150
tree.branch_segments = 10
tree.initial_thickness = 0.4

# Generate tree
tree.grow_tree()
```

### Animation Control
```gdscript
# Enable animated growth
tree.animate_growth = true
tree.growth_speed = 3.0

# The tree will grow automatically over time
```

### Customization
```gdscript
# Adjust growth patterns
tree.randomness = 0.5
tree.branch_probability = 0.6
tree.vertical_bias = 0.8

# Customize appearance
tree.bark_color = Color(0.3, 0.2, 0.1)
tree.leaf_color = Color(0.1, 0.7, 0.2)
tree.add_leaves = true

# Regenerate with new settings
tree.regenerate = true
```

## Visual Characteristics

### Tree Structure
- **Hierarchical Branching**: Natural tree-like branching patterns
- **Tapered Branches**: Realistic thickness variation from trunk to tips
- **Organic Curves**: Natural curvature and variation in growth
- **Realistic Proportions**: Proper scaling and proportions

### Growth Patterns
- **Upward Tendency**: Natural upward growth with variation
- **Branching Logic**: Realistic branching at appropriate angles
- **Termination**: Natural branch termination with leaves
- **Variation**: Random variation for organic appearance

### Materials and Colors
- **Bark Material**: Rough, brown bark appearance
- **Leaf Material**: Green, slightly glossy leaf appearance
- **Tapered Geometry**: Cylindrical branches with varying thickness
- **Natural Colors**: Earth-tone bark and green leaves

## Performance Considerations

### Complexity Factors
- **Max Iterations**: Higher values create more complex trees
- **Branch Probability**: Higher values create more branches
- **Branch Segments**: More segments create smoother curves
- **Animation**: Real-time animation adds processing overhead

### Optimization Tips
- Use appropriate max_iterations for your needs
- Disable animation for static trees
- Adjust branch_probability to control complexity
- Consider LOD for distant trees

### Memory Usage
- Scales with number of branches generated
- Each branch stores position, direction, and thickness
- Mesh generation for each branch segment
- Leaf generation adds additional geometry

## Use Cases

### Procedural Generation
- **Forest Generation**: Create diverse tree populations
- **Landscape Design**: Generate natural tree arrangements
- **Game Environments**: Procedural forest and woodland areas
- **Architectural Visualization**: Natural tree placement

### Game Development
- **Environment Assets**: Procedural tree generation
- **Level Design**: Natural forest and woodland areas
- **Character Design**: Organic creature appendages
- **Weapon Design**: Natural staff and branch weapons

### Scientific Applications
- **Botanical Modeling**: Tree growth simulation
- **Ecosystem Studies**: Forest structure analysis
- **Climate Modeling**: Vegetation distribution
- **Research**: Tree growth pattern studies

## Technical Implementation

### Dependencies
- **Godot 4.x**: Requires Godot 4.0 or later
- **GDScript**: Written in Godot's scripting language
- **SurfaceTool**: Uses Godot's mesh generation tools
- **Math Functions**: Utilizes trigonometric functions

### Class Structure
- **Branch Class**: Internal class for branch data
- **State Enum**: Defines growth states
- **Transition Matrix**: Probability matrix for state transitions
- **Growth Rules**: Context-aware probability modifications

### File Structure
- `MarkovChainsTree.gd`: Main algorithm implementation
- `MarkovChainsTree.tscn`: Scene file with visualization
- `README.md`: This documentation file

## Algorithm Variations

### State Modifications
- **Custom States**: Add new growth states
- **Transition Weights**: Modify probability matrix
- **Context Rules**: Add new growth rules
- **Environmental Factors**: Consider external influences

### Growth Patterns
- **Species Variation**: Different trees for different species
- **Environmental Adaptation**: Growth based on conditions
- **Seasonal Changes**: Time-based growth patterns
- **Damage Response**: Growth after damage

### Visualization Options
- **Different Geometries**: Various branch shapes
- **Texture Mapping**: Detailed bark and leaf textures
- **Animation**: More complex growth animations
- **Particle Effects**: Growth particles and effects

## Future Enhancements

### Algorithm Improvements
- **L-System Integration**: Combine with L-systems
- **Environmental Factors**: Wind, light, soil conditions
- **Species Variation**: Different tree types
- **Seasonal Growth**: Time-based growth patterns

### Visual Enhancements
- **Advanced Materials**: PBR materials for bark and leaves
- **Texture Mapping**: Detailed bark and leaf textures
- **Particle Systems**: Falling leaves and growth effects
- **Animation**: More complex growth animations

### Performance Optimizations
- **LOD System**: Level-of-detail for distant trees
- **Instancing**: Efficient rendering of multiple trees
- **Caching**: Cache generated meshes
- **GPU Acceleration**: Use compute shaders

## Troubleshooting

### Common Issues
- **Empty Trees**: Check max_iterations and branch_probability
- **Performance Issues**: Reduce max_iterations or disable animation
- **Unrealistic Growth**: Adjust transition matrix and growth rules
- **Memory Issues**: Reduce branch_segments or max_iterations

### Debug Tips
- Print branch count and iteration progress
- Visualize state transitions
- Check growth rule applications
- Monitor performance metrics

## License

This algorithm is part of the AdaResearch project and follows the same licensing terms as the main project.
