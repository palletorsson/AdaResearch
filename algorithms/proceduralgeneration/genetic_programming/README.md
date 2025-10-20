# Genetic Programming System

A comprehensive genetic programming system for evolving 3D forms through artificial evolution. This system uses genetic algorithms to generate, evaluate, and evolve complex 3D structures based on fitness criteria, making it perfect for procedural design, architectural exploration, and generative art.

## Overview

The `GeneticProgramming` class implements a complete evolutionary algorithm that can generate and evolve 3D forms through multiple generations. It supports various genome representations, fitness functions, and evolutionary operators to create diverse and optimized 3D structures.

## Features

### Core Evolution
- **Population-based Evolution**: Maintains a population of candidate solutions
- **Multiple Genome Types**: 5 different representations for 3D forms
- **Fitness Functions**: 5 different optimization goals
- **Genetic Operators**: Crossover, mutation, and selection mechanisms
- **Elitism**: Preserves best individuals across generations

### Genome Types
- **Primitives**: Combinations of basic shapes (spheres, boxes, cylinders, torus)
- **CSG Tree**: Constructive solid geometry operations (union, subtract, intersect)
- **Parametric**: Mathematical equations generating complex surfaces
- **Voxel**: 3D pixel-based sculptures with grid representation
- **L-System**: Recursive branching structures using grammar rules

### Fitness Functions
- **Volume Target**: Evolve toward specific volume
- **Height Target**: Reach specific height requirements
- **Symmetry**: Create bilaterally symmetrical forms
- **Sphericity**: Evolve sphere-like shapes
- **Custom**: Multi-objective optimization combining multiple criteria

### Visualization
- **Population Display**: Show all individuals in grid or random arrangement
- **Best Individual**: Focus on the highest-fitness solution
- **Fitness Labels**: Real-time fitness scores for each individual
- **Evolution Tracking**: Monitor fitness progress over generations

## Parameters

### Evolution Settings
- **Population Size**: Number of individuals per generation (default: 20)
- **Max Generations**: Maximum number of evolution cycles (default: 50)
- **Mutation Rate**: Probability of random changes (default: 0.3)
- **Crossover Rate**: Probability of combining parents (default: 0.7)
- **Elitism Count**: Number of best individuals preserved (default: 2)

### Genome Configuration
- **Genome Type**: Representation method (Primitives, CSG_Tree, Parametric, Voxel, L_System)
- **Genome Complexity**: Maximum number of genes/elements (default: 8)
- **Max Depth**: Maximum recursion depth for hierarchical structures (default: 4)

### Fitness Goals
- **Target Volume**: Desired volume for volume-based fitness (default: 10.0)
- **Target Height**: Desired height for height-based fitness (default: 5.0)
- **Symmetry Weight**: Importance of symmetry in custom fitness (default: 0.5)
- **Smoothness Weight**: Importance of smoothness in custom fitness (default: 0.3)
- **Complexity Weight**: Importance of complexity in custom fitness (default: 0.2)
- **Fitness Function**: Type of optimization goal (Volume, Height, Symmetry, Sphere, Custom)

### Visualization Options
- **Show Population**: Display all individuals (default: true)
- **Show Best Only**: Focus on best individual only (default: false)
- **Arrange in Grid**: Organize individuals in grid pattern (default: true)
- **Spacing**: Distance between individuals (default: 6.0)

### Evolution Control
- **Auto Evolve**: Automatically evolve generations (default: false)
- **Evolution Speed**: Speed of automatic evolution (default: 1.0)
- **Evolve One Generation**: Manual step-by-step evolution
- **Reset Evolution**: Restart with new random population

## Algorithm Details

### Genetic Programming Process
1. **Initialization**: Create random population of individuals
2. **Evaluation**: Calculate fitness for each individual
3. **Selection**: Choose parents for reproduction
4. **Crossover**: Combine genetic material from parents
5. **Mutation**: Apply random changes to offspring
6. **Replacement**: Create new generation
7. **Repeat**: Continue until termination criteria met

### Genome Representations

#### Primitives Genome
- **Structure**: Array of basic geometric shapes
- **Parameters**: Position, rotation, scale for each shape
- **Mutation**: Random changes to parameters
- **Crossover**: Combine shapes from different parents

#### CSG Tree Genome
- **Structure**: Tree of constructive solid geometry operations
- **Operations**: Union, subtract, intersect with primitives
- **Parameters**: Operation type, primitive type, transformations
- **Mutation**: Change operations, add/remove nodes

#### Parametric Genome
- **Structure**: Mathematical equations for surface generation
- **Parameters**: Frequency, amplitude, phase for each axis
- **Mutation**: Modify equation parameters
- **Crossover**: Combine equation components

#### Voxel Genome
- **Structure**: 3D grid of filled/empty voxels
- **Parameters**: Grid size, voxel positions
- **Mutation**: Add/remove voxels, change density
- **Crossover**: Combine voxel patterns

#### L-System Genome
- **Structure**: Grammar rules for recursive generation
- **Parameters**: Axiom, production rules, angles, lengths
- **Mutation**: Modify rules, change parameters
- **Crossover**: Combine rule sets

### Fitness Calculation

#### Volume Fitness
```gdscript
fitness = 100.0 / (1.0 + abs(actual_volume - target_volume))
```

#### Height Fitness
```gdscript
fitness = 100.0 / (1.0 + abs(actual_height - target_height))
```

#### Symmetry Fitness
- Calculates bilateral symmetry across X-axis
- Compares mirrored positions of elements
- Higher score for more symmetrical forms

#### Sphericity Fitness
- Measures how sphere-like the form is
- Calculates variance from center point
- Lower variance = higher sphericity

#### Custom Fitness
- Combines multiple objectives
- Weighted sum of different criteria
- Configurable importance weights

### Genetic Operators

#### Selection
- **Tournament Selection**: Randomly select individuals, choose best
- **Tournament Size**: Number of contestants (default: 3)
- **Pressure**: Higher tournament size = more selection pressure

#### Crossover
- **Single-point Crossover**: Split genomes at random point
- **Uniform Crossover**: Randomly choose from each parent
- **Crossover Rate**: Probability of crossover vs. cloning

#### Mutation
- **Parameter Mutation**: Random changes to existing parameters
- **Structural Mutation**: Add/remove genes or operations
- **Mutation Rate**: Probability of mutation per gene
- **Mutation Strength**: Magnitude of parameter changes

## Usage

### Basic Setup
```gdscript
# Create a GeneticProgramming instance
var gp = GeneticProgramming.new()
add_child(gp)

# Configure basic parameters
gp.population_size = 30
gp.genome_type = 0  # Primitives
gp.fitness_function = 0  # Volume
gp.target_volume = 15.0

# Start evolution
gp.initialize_population()
```

### Different Genome Types
```gdscript
# Primitives - basic shapes
gp.genome_type = 0
gp.genome_complexity = 10

# CSG Tree - constructive solid geometry
gp.genome_type = 1
gp.max_depth = 3

# Parametric - mathematical surfaces
gp.genome_type = 2
gp.genome_complexity = 1

# Voxel - 3D pixel art
gp.genome_type = 3
gp.genome_complexity = 1

# L-System - recursive branching
gp.genome_type = 4
gp.max_depth = 4
```

### Different Fitness Functions
```gdscript
# Volume target
gp.fitness_function = 0
gp.target_volume = 20.0

# Height target
gp.fitness_function = 1
gp.target_height = 8.0

# Symmetry
gp.fitness_function = 2

# Sphericity
gp.fitness_function = 3

# Custom multi-objective
gp.fitness_function = 4
gp.symmetry_weight = 0.6
gp.complexity_weight = 0.4
```

### Evolution Control
```gdscript
# Manual evolution
gp.evolve_one_generation = true

# Automatic evolution
gp.auto_evolve = true
gp.evolution_speed = 2.0

# Reset population
gp.reset_evolution = true
```

### Visualization Options
```gdscript
# Show all individuals
gp.show_population = true
gp.arrange_in_grid = true
gp.spacing = 8.0

# Show only best
gp.show_best_only = true

# Custom arrangement
gp.arrange_in_grid = false
```

## Advanced Configuration

### Custom Fitness Functions
```gdscript
# Override calculate_fitness method
func calculate_fitness(genome: Genome) -> float:
    var fitness = 0.0
    
    # Your custom fitness calculation
    var volume = estimate_volume(genome)
    var symmetry = calculate_symmetry(genome)
    var complexity = float(genome.genes.size()) / genome_complexity
    
    fitness = volume * 0.4 + symmetry * 100.0 * 0.3 + complexity * 100.0 * 0.3
    
    return fitness
```

### Custom Genome Types
```gdscript
# Add new genome type
func create_custom_genome(genome: Genome):
    # Your custom genome creation logic
    pass

# Override create_random_genome
func create_random_genome() -> Genome:
    var genome = Genome.new()
    
    match genome_type:
        5: # Custom type
            create_custom_genome(genome)
        # ... existing types
    
    return genome
```

### Custom Mutation
```gdscript
# Override Gene.mutate method
func mutate(mutation_strength: float):
    match gene_type:
        "custom":
            # Your custom mutation logic
            if randf() < mutation_strength:
                parameters.custom_param += randf_range(-0.1, 0.1)
        # ... existing types
```

## Performance Considerations

### Complexity Factors
- **Population Size**: Larger populations require more computation
- **Genome Complexity**: More genes = more evaluation time
- **Fitness Function**: Complex calculations slow down evolution
- **Visualization**: Real-time rendering can impact performance

### Optimization Tips
- Use appropriate population size for your needs
- Choose simpler genome types for faster evolution
- Disable real-time visualization for faster evolution
- Use custom fitness functions for specific goals

### Memory Usage
- Scales with population size and genome complexity
- Each individual stores complete genetic information
- Visualization meshes consume GPU memory
- Fitness history grows over generations

## Applications

### Procedural Design
- **Architectural Forms**: Evolve building shapes and structures
- **Product Design**: Generate ergonomic and aesthetic forms
- **Artistic Sculptures**: Create abstract and organic art pieces
- **Game Assets**: Procedurally generate 3D models

### Research Applications
- **Form Optimization**: Study shape optimization problems
- **Evolutionary Art**: Explore aesthetic evolution
- **Design Space Exploration**: Discover new form possibilities
- **Algorithm Development**: Test new evolutionary techniques

### Educational Use
- **Evolution Concepts**: Demonstrate natural selection
- **Optimization Theory**: Show search and optimization
- **3D Modeling**: Learn about 3D form generation
- **Programming**: Understand genetic algorithms

## Troubleshooting

### Common Issues
- **No Evolution**: Check mutation and crossover rates
- **Poor Fitness**: Verify fitness function and targets
- **Slow Performance**: Reduce population size or complexity
- **Memory Issues**: Limit genome complexity or population size

### Debug Tips
- Print fitness values to monitor progress
- Visualize intermediate generations
- Check parameter ranges and constraints
- Monitor population diversity

## Future Enhancements

### Algorithm Improvements
- **Multi-objective Optimization**: NSGA-II, SPEA2 algorithms
- **Adaptive Parameters**: Self-adjusting mutation rates
- **Parallel Evolution**: Multi-threaded evaluation
- **Interactive Evolution**: Human-guided selection

### Visualization Enhancements
- **3D Interaction**: VR/AR support for form exploration
- **Animation**: Animated evolution process
- **Comparison Views**: Side-by-side generation comparison
- **Export Options**: Save evolved forms as 3D models

### Integration Features
- **External Fitness**: Connect to external evaluation systems
- **Import/Export**: Load and save evolved populations
- **API Integration**: Connect to other procedural systems
- **Cloud Evolution**: Distributed evolution across multiple machines

## License

This algorithm is part of the AdaResearch project and follows the same licensing terms as the main project.
