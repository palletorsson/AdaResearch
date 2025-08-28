# Pattern Generation Algorithms

This directory contains 3D visualizations of pattern generation algorithms that create complex, organic patterns through mathematical and computational processes. These algorithms are inspired by natural phenomena and are used in computer graphics, procedural generation, and scientific visualization.

## Algorithms

### 1. Reaction-Diffusion (`reactiondiffusion/`)
- **Description**: Simulates the interaction between chemicals that can react and diffuse
- **Inventor**: Alan Turing (1952)
- **Mathematical Basis**: Gray-Scott reaction-diffusion equations
- **Features**:
  - Real-time chemical pattern simulation
  - Multiple pattern types (Spots, Stripes, Waves, Mazes)
  - Adjustable feed rate, kill rate, and diffusion coefficients
  - 3D height field visualization
  - Interactive parameter adjustment
- **Use Cases**: Biological pattern formation, texture generation, organic design

## Technical Details

### Reaction-Diffusion System

#### Chemical Equations
The system uses the Gray-Scott model with two chemicals A and B:

```
∂A/∂t = DA∇²A - AB² + f(1-A)
∂B/∂t = DB∇²B + AB² - (k+f)B
```

Where:
- **A, B**: Chemical concentrations
- **DA, DB**: Diffusion coefficients
- **f**: Feed rate
- **k**: Kill rate
- **∇²**: Laplacian operator

#### Pattern Types
- **Spots**: Random perturbations create spot patterns
- **Stripes**: Sinusoidal perturbations create stripe patterns
- **Waves**: Combined sine-cosine perturbations create wave patterns
- **Mazes**: Complex perturbations create maze-like patterns

#### Numerical Implementation
- **Grid-based**: 2D grid with configurable resolution
- **Finite Difference**: 5-point stencil for Laplacian computation
- **Explicit Euler**: Time integration with configurable step size
- **Boundary Handling**: Neumann boundary conditions

### Visualization Features
- **3D Height Field**: Chemical concentration mapped to height
- **Color Coding**: Red channel for chemical A, Green channel for chemical B
- **Real-time Updates**: Continuous simulation with adjustable speed
- **Interactive Controls**: Parameter adjustment during simulation
- **Export Capabilities**: Pattern saving functionality

## Usage

Each algorithm scene can be:
1. **Opened independently** in Godot 4
2. **Integrated into procedural generation projects** for texture creation
3. **Used for educational purposes** to understand pattern formation
4. **Extended** with additional pattern types or visualization methods

## Controls

### Simulation Parameters
- **Feed Rate**: Controls the rate at which chemical A is added (0.01 - 0.1)
- **Kill Rate**: Controls the rate at which chemical B is removed (0.01 - 0.1)
- **Diffusion A**: Diffusion coefficient for chemical A (0.1 - 2.0)
- **Diffusion B**: Diffusion coefficient for chemical B (0.1 - 2.0)

### Pattern Control
- **Pattern Type**: Choose initial perturbation pattern
- **Start/Stop**: Control simulation execution
- **Reset**: Return to initial conditions
- **Export**: Save current pattern state

## File Structure

```
patterngeneration/
├── reactiondiffusion/
│   ├── reactiondiffusion.tscn
│   ├── ReactionDiffusion.gd
│   └── ReactionDiffusionVisualizer.gd
└── README.md
```

## Dependencies

- **Godot 4.4+**: Required for all scenes
- **Standard 3D nodes**: CSGBox3D, Camera3D, DirectionalLight3D
- **Math functions**: Built-in mathematical functions for Laplacian computation
- **Array operations**: Dynamic array manipulation for grid updates

## Mathematical Concepts

### Diffusion
The Laplacian operator ∇² represents diffusion:
```
∇²f = ∂²f/∂x² + ∂²f/∂y²
```

### Reaction Terms
- **AB²**: Cubic reaction term representing chemical interaction
- **f(1-A)**: Feed term that maintains chemical A supply
- **(k+f)B**: Removal term that eliminates chemical B

### Pattern Formation
Patterns emerge when:
- **Turing condition**: DA ≠ DB (different diffusion rates)
- **Instability**: Reaction terms overcome diffusion
- **Nonlinearity**: AB² term creates complex dynamics

## Future Enhancements

- [ ] Add more reaction-diffusion models (Brusselator, Oregonator)
- [ ] Implement 3D reaction-diffusion systems
- [ ] Add pattern analysis tools (Fourier analysis, pattern classification)
- [ ] Create pattern combination and blending tools
- [ ] Add texture export capabilities
- [ ] Implement GPU-accelerated computation

## Applications

### Computer Graphics
- **Procedural Textures**: Organic, natural-looking surfaces
- **Terrain Generation**: Biological terrain features
- **Animation**: Evolving pattern sequences
- **Material Design**: Organic material properties

### Scientific Visualization
- **Biological Systems**: Animal coat patterns, cellular structures
- **Chemical Reactions**: Reaction front propagation
- **Geological Patterns**: Mineral formation, crystal growth
- **Ecological Systems**: Population dynamics, species distribution

### Design & Art
- **Generative Art**: Algorithmic pattern creation
- **Architecture**: Organic building facades
- **Fashion**: Dynamic textile patterns
- **Interactive Installations**: Responsive pattern systems

## References

- Turing, A. M. "The chemical basis of morphogenesis." Philosophical Transactions of the Royal Society of London. Series B, Biological Sciences 237.641 (1952): 37-72.
- Gray, P., and Scott, S. K. "Autocatalytic reactions in the isothermal, continuous stirred tank reactor: isolas and other forms of multistability." Chemical Engineering Science 38.1 (1983): 29-43.
- Pearson, J. E. "Complex patterns in a simple system." Science 261.5118 (1993): 189-192.
- Various reaction-diffusion and pattern formation references
