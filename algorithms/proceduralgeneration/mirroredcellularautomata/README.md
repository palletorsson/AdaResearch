# Mirrored Cellular Automata

## Overview
This implementation creates symmetric cellular automata patterns using mirroring techniques. The algorithm generates complex, evolving patterns that maintain bilateral symmetry, creating visually striking and mathematically interesting structures reminiscent of biological growth patterns and crystalline formations.

## Algorithm Description
Mirrored cellular automata extend traditional cellular automata by enforcing symmetry constraints during evolution. Each cell's state is determined not only by its local neighborhood but also by maintaining mirror symmetry across one or more axes, creating patterns that are both dynamic and aesthetically pleasing.

### Key Features
1. **Symmetry Enforcement**: Maintains bilateral or radial symmetry during evolution
2. **Dynamic Rule Sets**: Configurable cellular automata rules (Conway's Life, custom rules)
3. **Mirror Constraints**: Real-time symmetry preservation across vertical/horizontal axes
4. **Pattern Evolution**: Complex emergent behaviors within symmetric constraints
5. **Visual Rendering**: Real-time visualization of evolving symmetric patterns

### Algorithm Flow
1. **Initialization**: Create initial symmetric seed pattern
2. **Rule Application**: Apply cellular automata rules to each cell
3. **Symmetry Enforcement**: Mirror changes across symmetry axes
4. **Conflict Resolution**: Handle conflicts between rule application and symmetry
5. **Pattern Update**: Update display with new symmetric pattern
6. **Iteration**: Repeat for continuous evolution

## Files Structure
- `mirrored_cellular_automata.gd`: Main algorithm with symmetry enforcement
- `mirrored_cellular_automata.tscn`: Visualization scene
- `main.tscn`: Alternative scene setup

## Parameters
- **Grid Size**: Configurable resolution for cellular grid
- **Symmetry Type**: Horizontal, vertical, or radial mirroring
- **Rule Set**: Conway's Life, custom birth/survival rules
- **Update Speed**: Evolution rate control
- **Color Scheme**: Visual representation options

## Theoretical Foundation
Based on:
- **Cellular Automata Theory**: Discrete mathematical models of complex systems
- **Symmetry Groups**: Mathematical symmetry transformations
- **Emergent Complexity**: Simple rules creating complex behaviors
- **Pattern Formation**: Natural symmetry in biological and physical systems

## Applications
- Generative art and visual design
- Symmetric pattern generation
- Architectural design inspiration
- Textile and wallpaper patterns
- Mathematical visualization
- Procedural content generation

## Usage
Run the simulation to observe symmetric patterns evolving over time. Experiment with different initial conditions and symmetry types to discover unique pattern families that maintain their symmetric properties while exhibiting complex dynamics.