# Cellular Automata Showcase - Separated Examples

This directory contains individual Cellular Automata (CA) simulations that have been separated from the original monolithic showcase for easier testing and development.

## Structure

### Base Class
- `base_ca.gd` - Common base class with shared functionality for all CA implementations

### Individual CA Examples

#### 1. Recrystallization CA (`recrystallization_ca.gd` + `.tscn`)
- **Description**: Metal recrystallization simulation showing crystal nucleation and growth
- **Features**: Random nucleation sites, probabilistic crystal growth
- **Visualization**: White cubes represent growing crystals

#### 2. Dendrite Growth CA (`dendrite_growth_ca.gd` + `.tscn`)
- **Description**: Crystal dendrite formation with branching patterns
- **Features**: Central growth point, probabilistic branching in 6 directions
- **Visualization**: Blue cubes show dendritic crystal structures

#### 3. Percolation CA (`percolation_ca.gd` + `.tscn`)
- **Description**: Fluid percolation through porous medium
- **Features**: Random porous structure, fluid flow from top to bottom
- **Visualization**: White = occupied sites, Blue = flowing fluid

#### 4. Crack Propagation CA (`crack_propagation_ca.gd` + `.tscn`)
- **Description**: Material crack propagation from stress concentrators
- **Features**: Multiple stress points, probabilistic crack growth
- **Visualization**: Blue = stress points, White = crack paths

#### 5. Avalanche CA (`avalanche_ca.gd` + `.tscn`)
- **Description**: Sand pile avalanche model (Bak-Tang-Wiesenfeld)
- **Features**: Critical slope threshold, avalanche redistribution
- **Visualization**: White cubes show sand pile height

#### 6. Ecosystem CA (`ecosystem_ca.gd` + `.tscn`)
- **Description**: Predator-prey ecosystem dynamics
- **Features**: Birth/death rates, hunting behavior, population dynamics
- **Visualization**: White = prey, Blue = predators

#### 7. Disease Spread CA (`disease_spread_ca.gd` + `.tscn`)
- **Description**: Epidemic spread model (SIR - Susceptible, Infected, Recovered)
- **Features**: Infection/recovery rates, neighbor-based transmission
- **Visualization**: Blue = infected, White = recovered

#### 8. Self-Organization CA (`self_organization_ca.gd` + `.tscn`)
- **Description**: Self-organizing patterns and emergence
- **Features**: Local interaction rules, color-coded states
- **Visualization**: Multi-colored cubes showing different states

### Menu System
- `ca_menu.gd` + `.tscn` - Main menu for selecting which CA to run

## How to Use

### Running Individual Examples
1. Open any `.tscn` file directly in Godot
2. Run the scene (F5 or Play button)
3. The CA simulation will start automatically

### Using the Menu System
1. Open `ca_menu.tscn`
2. Run the scene
3. Click on any CA name to load that simulation
4. Use "Back to Main Menu" to return to the selection screen

### Integration with Main Project
To integrate these CA examples into your main project:

1. **Add to Main Menu**: Add a button that loads `ca_menu.tscn`
2. **Direct Loading**: Load specific CA scenes directly from your main scene loader
3. **Customization**: Modify parameters in each CA script to adjust behavior

## Customization

### Modifying Parameters
Each CA script has constants at the top that control behavior:
- Growth rates
- Probabilities
- Grid sizes
- Update intervals

### Adding New CA Types
1. Create a new script extending `BaseCA`
2. Implement required methods: `initialize_grid()`, `update_simulation()`, `update_visualization()`
3. Create a corresponding `.tscn` file
4. Add to the menu system if desired

### Performance Optimization
- Adjust `GRID_SIZE` in `base_ca.gd` for different performance levels
- Modify sampling steps in visualization methods
- Use `step` variable to render every Nth cell

## Technical Details

### Base Class Features
- Common 3D/2D grid creation
- Neighbor detection utilities
- Mesh visualization helpers
- Material management
- Simulation control (start/stop)

### Visualization System
- Uses `ArrayMesh` for efficient rendering
- Separate materials for different cell states
- Configurable sampling for performance
- Color-coded states where appropriate

### Grid Systems
- 3D grids for most simulations
- 2D grids for avalanche model
- Efficient neighbor detection
- Grid duplication utilities

## Performance Notes

- **Grid Size**: Default 64³ for 3D, 64² for 2D
- **Sampling**: Most visualizations sample every 3rd-4th cell
- **Materials**: Shared materials to reduce draw calls
- **Updates**: 60 FPS simulation updates

## Troubleshooting

### Common Issues
1. **Performance**: Reduce `GRID_SIZE` or increase sampling step
2. **Visualization**: Check that materials are properly assigned
3. **Simulation**: Ensure `is_running` is true in base class

### Debug Information
Each CA provides debug methods:
- Population counts
- State statistics
- Simulation progress

Use these to verify correct behavior and performance.
